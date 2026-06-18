using Marketplace.Domain.Common;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Helpers;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using MongoDB.Driver;
using MongoDB.Driver.GeoJsonObjectModel;

namespace Marketplace.Infrastructure.Persistence.Repositories;

public class PartnerRepository : GenericRepository<Partner>, IPartnerRepository
{
    public PartnerRepository(IMongoDatabase database) : base(database, "Partners")
    {
    }

    public async Task<Partner?> GetByOwnerUserIdAsync(Guid ownerUserId, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.OwnerUserId == ownerUserId).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<Partner?> GetBySlugAsync(string slug, CancellationToken cancellationToken = default)
    {
        return await Collection.Find(x => x.Slug == slug).FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<PartnerWithDistance> Items, int TotalRecords)> SearchPagedAsync(
        PartnerSearchCriteria criteria,
        CancellationToken cancellationToken = default)
    {
        var builder = Builders<Partner>.Filter;
        var filters = new List<FilterDefinition<Partner>>
        {
            builder.Eq(x => x.Status, criteria.Status),
        };

        if (criteria.Type.HasValue)
            filters.Add(builder.Eq(x => x.Type, criteria.Type.Value));

        if (!string.IsNullOrWhiteSpace(criteria.Query))
        {
            var pattern = new MongoDB.Bson.BsonRegularExpression(criteria.Query.Trim(), "i");
            filters.Add(builder.Or(
                builder.Regex(x => x.Name, pattern),
                builder.Regex(x => x.Description!, pattern),
                builder.Regex(x => x.Address!, pattern)));
        }

        var baseFilter = builder.And(filters);

        if (criteria.Latitude is not null && criteria.Longitude is not null && criteria.RadiusKm is > 0)
        {
            return await SearchNearbyAsync(criteria, baseFilter, cancellationToken);
        }

        var total = (int)await Collection.CountDocumentsAsync(baseFilter, cancellationToken: cancellationToken);
        var partners = await Collection.Find(baseFilter)
            .SortByDescending(x => x.RatingAverage)
            .ThenByDescending(x => x.RatingCount)
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Limit(criteria.PageSize)
            .ToListAsync(cancellationToken);

        return (partners.Select(p => new PartnerWithDistance { Partner = p }).ToList(), total);
    }

    public async Task UpdateStatusAsync(Guid id, PartnerStatus status, CancellationToken cancellationToken = default)
    {
        var update = Builders<Partner>.Update
            .Set(x => x.Status, status)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);
        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }

    public async Task UpdateRatingAsync(
        Guid id,
        decimal ratingAverage,
        int ratingCount,
        CancellationToken cancellationToken = default)
    {
        var update = Builders<Partner>.Update
            .Set(x => x.RatingAverage, ratingAverage)
            .Set(x => x.RatingCount, ratingCount)
            .Set(x => x.UpdatedAt, DateTimeOffset.UtcNow);
        await Collection.UpdateOneAsync(x => x.Id == id, update, cancellationToken: cancellationToken);
    }

    private async Task<(IReadOnlyList<PartnerWithDistance> Items, int TotalRecords)> SearchNearbyAsync(
        PartnerSearchCriteria criteria,
        FilterDefinition<Partner> baseFilter,
        CancellationToken cancellationToken)
    {
        var point = new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
            new GeoJson2DGeographicCoordinates(criteria.Longitude!.Value, criteria.Latitude!.Value));

        var maxDistanceMeters = criteria.RadiusKm!.Value * 1000;
        var geoFilter = Builders<Partner>.Filter.NearSphere(
            x => x.Location,
            point,
            maxDistance: maxDistanceMeters);

        var filter = Builders<Partner>.Filter.And(baseFilter, geoFilter);
        var allNearby = await Collection.Find(filter).ToListAsync(cancellationToken);

        var withDistance = allNearby
            .Select(partner =>
            {
                var coords = GeoLocationMapping.FromGeoJsonPoint(partner.Location);
                double? distanceKm = null;
                if (coords != null)
                {
                    distanceKm = HaversineKm(
                        criteria.Latitude!.Value,
                        criteria.Longitude!.Value,
                        coords.Value.Latitude,
                        coords.Value.Longitude);
                }

                return new PartnerWithDistance { Partner = partner, DistanceKm = distanceKm };
            })
            .Where(x => x != null)
            .Cast<PartnerWithDistance>()
            .OrderBy(x => x.DistanceKm ?? double.MaxValue)
            .ThenByDescending(x => x.Partner.RatingAverage)
            .ToList();

        var total = withDistance.Count;
        var page = withDistance
            .Skip((criteria.PageNumber - 1) * criteria.PageSize)
            .Take(criteria.PageSize)
            .ToList();

        return (page, total);
    }

    private static double HaversineKm(double lat1, double lon1, double lat2, double lon2)
    {
        const double earthRadiusKm = 6371.0;
        var dLat = DegreesToRadians(lat2 - lat1);
        var dLon = DegreesToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
                + Math.Cos(DegreesToRadians(lat1)) * Math.Cos(DegreesToRadians(lat2))
                * Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return Math.Round(earthRadiusKm * c, 2);
    }

    private static double DegreesToRadians(double degrees) => degrees * Math.PI / 180.0;
}
