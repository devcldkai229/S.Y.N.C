using Iam.Application.Abstractions;
using Iam.Domain.Repositories;
using Iam.Infrastructure.Clients;
using Iam.Infrastructure.Persistence;
using Iam.Infrastructure.Persistence.Repositories;
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
        services.AddScoped<IUserMeRepository, UserMeRepository>();
        services.AddScoped<IInternalSmartPushRepository, InternalSmartPushRepository>();

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

        return services;
    }
}
