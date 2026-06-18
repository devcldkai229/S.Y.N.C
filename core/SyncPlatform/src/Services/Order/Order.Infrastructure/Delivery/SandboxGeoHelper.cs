namespace Order.Infrastructure.Delivery;

internal static class SandboxGeoHelper
{
    /// <summary>Move toward target by a fraction of remaining distance (capped ~40 m/tick).</summary>
    public static (double Lat, double Lng) StepToward(
        double fromLat,
        double fromLng,
        double toLat,
        double toLng,
        double stepFraction = 0.12)
    {
        var dLat = toLat - fromLat;
        var dLng = toLng - fromLng;
        var dist = Math.Sqrt(dLat * dLat + dLng * dLng);
        if (dist < 1e-8)
            return (toLat, toLng);

        var step = Math.Min(stepFraction * dist, 0.00038);
        var ratio = step / dist;
        return (fromLat + dLat * ratio, fromLng + dLng * ratio);
    }

    public static double DistanceMeters(double lat1, double lng1, double lat2, double lng2)
    {
        const double r = 6371000;
        var dLat = (lat2 - lat1) * Math.PI / 180;
        var dLng = (lng2 - lng1) * Math.PI / 180;
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2)
            + Math.Cos(lat1 * Math.PI / 180) * Math.Cos(lat2 * Math.PI / 180)
            * Math.Sin(dLng / 2) * Math.Sin(dLng / 2);
        return r * 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    }

    public static (double Lat, double Lng) SpawnNearPickup(double pickupLat, double pickupLng) =>
        (pickupLat - 0.0045, pickupLng - 0.0035);
}
