using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;
using Microsoft.Extensions.Logging;
using MongoDB.Driver;

namespace Marketplace.SeedTool.Services;

public sealed class MarketplaceUpserter
{
    private readonly IPartnerRepository _partners;
    private readonly IFoodMenuItemRepository _menuItems;
    private readonly IMongoCollection<FoodMenuItem> _menuCollection;
    private readonly ILogger<MarketplaceUpserter> _logger;

    public MarketplaceUpserter(
        IPartnerRepository partners,
        IFoodMenuItemRepository menuItems,
        IMongoDatabase database,
        ILogger<MarketplaceUpserter> logger)
    {
        _partners = partners;
        _menuItems = menuItems;
        _menuCollection = database.GetCollection<FoodMenuItem>("FoodMenuItems");
        _logger = logger;
    }

    public async Task<FoodMenuItem?> GetByPartnerAndSlugAsync(
        Guid partnerId,
        string slug,
        CancellationToken cancellationToken = default)
    {
        return await _menuCollection
            .Find(x => x.PartnerId == partnerId && x.Slug == slug)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task<UpsertResult<Partner>> UpsertPartnerAsync(
        Partner partner,
        CancellationToken cancellationToken = default)
    {
        var existing = await _partners.GetBySlugAsync(partner.Slug, cancellationToken);
        if (existing is null)
        {
            await _partners.CreateAsync(partner, cancellationToken);
            _logger.LogInformation("Created partner {Slug}", partner.Slug);
            return UpsertResult<Partner>.Created(partner);
        }

        partner.Id = existing.Id;
        partner.CreatedAt = existing.CreatedAt;
        partner.OwnerUserId = existing.OwnerUserId;
        partner.UpdatedAt = DateTimeOffset.UtcNow;
        await _partners.UpdateAsync(existing.Id, partner, cancellationToken);
        _logger.LogInformation("Updated partner {Slug}", partner.Slug);
        return UpsertResult<Partner>.Updated(partner);
    }

    public async Task<UpsertResult<FoodMenuItem>> UpsertFoodMenuItemAsync(
        FoodMenuItem item,
        CancellationToken cancellationToken = default)
    {
        var existing = await _menuCollection
            .Find(x => x.PartnerId == item.PartnerId && x.Slug == item.Slug)
            .FirstOrDefaultAsync(cancellationToken);

        if (existing is null)
        {
            await _menuItems.CreateAsync(item, cancellationToken);
            _logger.LogDebug("Created dish {Slug} for partner {PartnerId}", item.Slug, item.PartnerId);
            return UpsertResult<FoodMenuItem>.Created(item);
        }

        item.Id = existing.Id;
        item.CreatedAt = existing.CreatedAt;
        item.RatingAverage = existing.RatingAverage;
        item.RatingCount = existing.RatingCount;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        await _menuItems.UpdateAsync(existing.Id, item, cancellationToken);
        _logger.LogDebug("Updated dish {Slug} for partner {PartnerId}", item.Slug, item.PartnerId);
        return UpsertResult<FoodMenuItem>.Updated(item);
    }

    public sealed record UpsertResult<T>(T Entity, UpsertAction Action)
    {
        public static UpsertResult<T> Created(T entity) => new(entity, UpsertAction.Created);

        public static UpsertResult<T> Updated(T entity) => new(entity, UpsertAction.Updated);
    }

    public enum UpsertAction
    {
        Created,
        Updated,
    }
}
