using Iam.Application.Abstractions;
using Iam.Application.Options;
using Iam.Application.Services;
using Iam.Domain.Repositories;
using Iam.Infrastructure.Clients;
using Iam.Infrastructure.Persistence;
using Iam.Infrastructure.Persistence.Repositories;
using Iam.Infrastructure.Workers;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Iam.Infrastructure.Extensions;

public static class InfrastructureServiceExtensions
{
    public static IServiceCollection AddIamInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("IamDatabase")
            ?? throw new InvalidOperationException("Connection string 'IamDatabase' is not configured.");

        services.AddDbContext<IamDbContext>(options =>
            options
                .UseNpgsql(connectionString, npgsql =>
                {
                    npgsql.MigrationsHistoryTable("__ef_migrations_history", "iam");
                    npgsql.EnableRetryOnFailure(maxRetryCount: 5);
                })
                .UseLazyLoadingProxies()
                .UseSnakeCaseNamingConvention());

        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IUserDeviceRepository, UserDeviceRepository>();
        services.AddScoped<IBiometricProfileRepository, BiometricProfileRepository>();
        services.AddScoped<IBiometricHistoryRepository, BiometricHistoryRepository>();
        services.AddScoped<ITargetAdjustmentLogRepository, TargetAdjustmentLogRepository>();
        services.AddScoped<IUserLevelSnapshotRepository, UserLevelSnapshotRepository>();
        services.AddScoped<IUserMeRepository, UserMeRepository>();
        services.AddScoped<IInternalSmartPushRepository, InternalSmartPushRepository>();
        services.AddScoped<IAdminDashboardReadRepository, AdminDashboardReadRepository>();

        AddEmailSender(services, configuration);

        services.AddHttpClient<INotificationClient, NotificationClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            var baseUrl = config["NotificationService:BaseUrl"] ?? "http://localhost:5106";
            client.BaseAddress = new Uri(baseUrl);
            client.Timeout = TimeSpan.FromSeconds(5);

            var apiKey = config["NotificationService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IAccountDeletionCascadeClient, AccountDeletionCascadeClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.Timeout = TimeSpan.FromSeconds(10);

            var apiKey = config["InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHttpClient<IRoadmapBodyMetricsClient, RoadmapBodyMetricsClient>((sp, client) =>
        {
            var config = sp.GetRequiredService<IConfiguration>();
            client.Timeout = TimeSpan.FromSeconds(5);

            var apiKey = config["InternalApiKey"] ?? config["RoadmapService:InternalApiKey"];
            if (!string.IsNullOrEmpty(apiKey))
                client.DefaultRequestHeaders.Add("X-Internal-Api-Key", apiKey);
        });

        services.AddHostedService<AccountHardDeleteHostedService>();

        return services;
    }

    private static void AddEmailSender(IServiceCollection services, IConfiguration configuration)
    {
        var email = configuration.GetSection(EmailSettings.SectionName).Get<EmailSettings>() ?? new EmailSettings();

        if (email.Brevo.Enabled
            && !string.IsNullOrWhiteSpace(email.Brevo.Host)
            && !string.IsNullOrWhiteSpace(email.Brevo.FromEmail))
        {
            services.AddSingleton<IEmailSender, BrevoSmtpEmailSender>();
            return;
        }

        services.AddSingleton<IEmailSender, ConsoleEmailSender>();
    }
}
