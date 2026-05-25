using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using Net.payOS;
using Payment.Application.Options;
using Payment.Application.Services;
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

        return services;
    }
}
