using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Net.payOS;
using Payment.Application.Clients;
using Payment.Application.Options;
using Payment.Application.Services;
using Payment.Infrastructure.Clients;
using Payment.Infrastructure.Jobs;
using Payment.Infrastructure.Persistence;
using Payment.Infrastructure.Services;

namespace Payment.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddPaymentInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // ── EF Core (PostgreSQL) ─────────────────────────────────────────────
        var connectionString = configuration.GetConnectionString("PaymentDatabase")
            ?? throw new InvalidOperationException("Connection string 'PaymentDatabase' is not configured.");

        services.AddDbContext<PaymentDbContext>(options =>
            options
                .UseNpgsql(connectionString, npgsql =>
                {
                    npgsql.MigrationsHistoryTable("__ef_migrations_history", "payment");
                    npgsql.EnableRetryOnFailure(maxRetryCount: 5);
                })
                .UseLazyLoadingProxies()
                .UseSnakeCaseNamingConvention());

        // ── PayOS client (thread-safe, register as singleton) ────────────────
        services.AddSingleton<PayOS>(sp =>
        {
            var settings = sp.GetRequiredService<IOptions<PayosSettings>>().Value;

            if (string.IsNullOrWhiteSpace(settings.ClientId)
                || string.IsNullOrWhiteSpace(settings.ApiKey)
                || string.IsNullOrWhiteSpace(settings.ChecksumKey))
            {
                throw new InvalidOperationException(
                    "PayOS configuration is incomplete. Required: PayOS:ClientId, PayOS:ApiKey, PayOS:ChecksumKey.");
            }

            return new PayOS(settings.ClientId, settings.ApiKey, settings.ChecksumKey);
        });

        // ── Application services with infrastructure-bound implementations ──
        services.AddScoped<IPayosPaymentService, PayosPaymentService>();
        services.AddScoped<ISubscriptionPlanService, SubscriptionPlanService>();
        services.AddScoped<IUserSubscriptionService, UserSubscriptionService>();
        services.AddScoped<IPromotionCampaignService, PromotionCampaignService>();
        services.AddScoped<IInternalWalletService, InternalWalletService>();
        services.AddScoped<IVoucherService, VoucherService>();
        services.AddScoped<IOrderPaymentService, OrderPaymentService>();

        services.AddHttpClient("Momo");

        services.AddHttpClient<IOrderPaymentNotifyClient, OrderPaymentNotifyClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.BaseAddress = new Uri(config["OrderService:BaseUrl"] ?? "http://localhost:5123");
            client.Timeout = TimeSpan.FromSeconds(10);
            var apiKey = config["InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        // ── Background jobs ──────────────────────────────────────────────────
        services.AddHostedService<SubscriptionExpiryJob>();

        // ── IAM internal client (tier sync after activation/expiry) ─────────
        services.AddHttpClient<IIamSubscriptionClient, IamSubscriptionClient>((sp, client) =>
        {
            var config  = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["Services:IamBaseUrl"] ?? "http://localhost:5288";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout     = TimeSpan.FromSeconds(10);

            var apiKey = config["InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        return services;
    }
}
