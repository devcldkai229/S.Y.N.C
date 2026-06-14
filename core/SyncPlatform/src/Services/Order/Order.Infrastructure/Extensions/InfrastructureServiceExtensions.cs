using Amazon.LocationService;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Order.Application.Clients;
using Order.Application.Ports;
using Order.Application.Services;
using Order.Infrastructure.Clients;
using Order.Infrastructure.Delivery;
using Order.Infrastructure.Options;
using Order.Infrastructure.Persistence;
using Order.Infrastructure.Redis;
using Order.Infrastructure.Services;
using StackExchange.Redis;

namespace Order.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddOrderInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("OrderDatabase")
            ?? throw new InvalidOperationException("Connection string 'OrderDatabase' is not configured.");

        services.AddDbContext<OrderDbContext>(options =>
            options
                .UseNpgsql(connectionString, npgsql =>
                {
                    npgsql.MigrationsHistoryTable("__ef_migrations_history", "order");
                    npgsql.EnableRetryOnFailure(maxRetryCount: 5);
                })
                .UseLazyLoadingProxies()
                .UseSnakeCaseNamingConvention());

        services.Configure<OrderSettings>(configuration.GetSection(OrderSettings.SectionName));
        services.Configure<AhamoveSettings>(configuration.GetSection(AhamoveSettings.SectionName));
        services.Configure<AwsLocationOptions>(configuration.GetSection(AwsLocationOptions.SectionName));

        services.AddSingleton<IAmazonLocationService>(sp =>
        {
            var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<AwsLocationOptions>>().Value;
            return AwsPlaceIndexClient.CreateClient(options);
        });

        services.AddScoped<IOrderService, OrderService>();
        services.AddScoped<ICheckoutSessionService, CheckoutSessionService>();
        services.AddScoped<ICommissionService, CommissionService>();
        services.AddScoped<IDeliveryTrackingService, DeliveryTrackingService>();
        services.AddHostedService<DeliveryLocationPollerService>();
        services.AddHostedService<SandboxDeliverySimulatorService>();
        services.AddScoped<IInternalOrderVerificationService, InternalOrderVerificationService>();
        services.AddMemoryCache();
        services.AddHttpClient<AhamoveTokenService>();
        services.AddHttpClient<AhamoveAdapter>();
        services.AddSingleton<AhamoveTokenService>();
        services.AddScoped<IDeliveryProvider, AhamoveAdapter>();

        var redisConnection = configuration.GetConnectionString("Redis")
            ?? configuration["Redis:Configuration"]
            ?? "localhost:6379";
        services.AddSingleton<IConnectionMultiplexer>(_ => ConnectionMultiplexer.Connect(redisConnection));
        services.AddSingleton<ITrackingLocationStore, RedisTrackingLocationStore>();
        services.AddSingleton<ICartStore, RedisCartStore>();
        services.AddSingleton<IDeliveryAddressStore, RedisDeliveryAddressStore>();
        services.AddSingleton<IPlaceSearchCache, RedisPlaceSearchCache>();
        services.AddSingleton<IPlaceIndexClient, AwsPlaceIndexClient>();

        services.AddHttpClient<IMarketplaceClient, MarketplaceClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["MarketplaceService:BaseUrl"] ?? "http://localhost:5119");
            client.Timeout = TimeSpan.FromSeconds(10);
            var apiKey = config["MarketplaceService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IPaymentClient, PaymentClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["PaymentService:BaseUrl"] ?? "http://localhost:5084");
            client.Timeout = TimeSpan.FromSeconds(10);
            var apiKey = config["PaymentService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<INotificationClient, NotificationClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["NotificationService:BaseUrl"] ?? "http://localhost:5106");
            client.Timeout = TimeSpan.FromSeconds(5);
            var apiKey = config["NotificationService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<INutritionEventClient, NutritionEventClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["NutritionService:BaseUrl"] ?? "http://localhost:5122");
            client.Timeout = TimeSpan.FromSeconds(5);
            var apiKey = config["InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        return services;
    }
}
