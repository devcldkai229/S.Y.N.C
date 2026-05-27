using Iam.Domain.Repositories;
using Iam.Application.Abstractions;
using Iam.Infrastructure.Options;
using Iam.Infrastructure.Persistence;
using Iam.Infrastructure.Persistence.Repositories;
using Iam.Infrastructure.Persistence.Seed;
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

        services.Configure<IamSeedOptions>(configuration.GetSection(IamSeedOptions.SectionName));
        services.AddScoped<IIamDatabaseSeeder, IamDatabaseSeeder>();

        return services;
    }
}
