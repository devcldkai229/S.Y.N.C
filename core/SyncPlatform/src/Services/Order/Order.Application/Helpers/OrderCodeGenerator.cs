namespace Order.Application.Helpers;

public static class OrderCodeGenerator
{
    public static string Generate() =>
        $"ORD-{DateTimeOffset.UtcNow:yyyyMMdd}-{Random.Shared.Next(100000, 999999)}";
}
