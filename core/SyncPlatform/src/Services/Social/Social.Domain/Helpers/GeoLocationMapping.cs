using MongoDB.Driver.GeoJsonObjectModel;

namespace Social.Domain.Helpers;

/// <summary>
/// Converts between API-friendly latitude/longitude and MongoDB GeoJSON points.
/// </summary>
public static class GeoLocationMapping
{
    public static GeoJsonPoint<GeoJson2DGeographicCoordinates>? ToGeoJsonPoint(
        double? latitude,
        double? longitude)
    {
        if (latitude is null || longitude is null)
            return null;

        return new GeoJsonPoint<GeoJson2DGeographicCoordinates>(
            new GeoJson2DGeographicCoordinates(longitude.Value, latitude.Value));
    }

    public static (double Latitude, double Longitude)? FromGeoJsonPoint(
        GeoJsonPoint<GeoJson2DGeographicCoordinates>? point)
    {
        if (point is null)
            return null;

        return (point.Coordinates.Latitude, point.Coordinates.Longitude);
    }
}
