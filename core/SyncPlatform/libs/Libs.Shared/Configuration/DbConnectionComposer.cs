using Microsoft.Extensions.Configuration;

namespace Libs.Shared.Configuration;

/// <summary>
/// Ghép ConnectionStrings từ các phần rời (host/port/user/password/name) đưa vào
/// qua env/SSM/Secrets Manager. Chỉ chạy trên hạ tầng cloud (ECS) — nơi password
/// nằm ở Secrets Manager còn host/port/user ở SSM Parameter Store, nên KHÔNG thể
/// nhồi cả chuỗi vào một secret. Local dev vẫn dùng ConnectionStrings có sẵn trong
/// appsettings (khi thiếu phần Host thì bỏ qua, không ghi đè).
/// </summary>
public static class DbConnectionComposer
{
    /// <summary>
    /// Ghép chuỗi Npgsql cho khoá <paramref name="connectionKey"/> từ
    /// Db:Postgres:{Host,Port,User,Password,Name}. Không làm gì nếu thiếu Host.
    /// </summary>
    public static IConfigurationManager AddComposedPostgresConnection(
        this IConfigurationManager config, string connectionKey)
    {
        var host = config["Db:Postgres:Host"];
        if (string.IsNullOrWhiteSpace(host))
            return config; // local: dùng ConnectionStrings sẵn có

        var port = config["Db:Postgres:Port"];
        if (string.IsNullOrWhiteSpace(port)) port = "5432";
        var user = config["Db:Postgres:User"];
        var pass = config["Db:Postgres:Password"];
        var name = config["Db:Postgres:Name"];

        var conn = $"Host={host};Port={port};Database={name};Username={user};Password={pass};Maximum Pool Size=8;Timeout=15";
        return AddConnectionString(config, connectionKey, conn);
    }

    /// <summary>
    /// Ghép URI MongoDB cho khoá <paramref name="connectionKey"/> từ
    /// Db:Mongo:{Host,User,Password,Name}. Không làm gì nếu thiếu Host.
    /// </summary>
    public static IConfigurationManager AddComposedMongoConnection(
        this IConfigurationManager config, string connectionKey)
    {
        var host = config["Db:Mongo:Host"];
        if (string.IsNullOrWhiteSpace(host))
            return config;

        var user = Uri.EscapeDataString(config["Db:Mongo:User"] ?? "");
        var pass = Uri.EscapeDataString(config["Db:Mongo:Password"] ?? "");
        var name = config["Db:Mongo:Name"];

        var conn = $"mongodb://{user}:{pass}@{host}:27017/{name}?authSource=admin";
        return AddConnectionString(config, connectionKey, conn);
    }

    private static IConfigurationManager AddConnectionString(
        IConfigurationManager config, string connectionKey, string value)
    {
        ((IConfigurationBuilder)config).AddInMemoryCollection(
            new Dictionary<string, string?> { [$"ConnectionStrings:{connectionKey}"] = value });
        return config;
    }
}
