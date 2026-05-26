using System.Security.Claims;
using System.Text;
using Libs.Auth.Constants;
using Libs.Auth.Context;
using Libs.Auth.Options;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;

namespace Libs.Auth.Extensions;

public static class JwtAuthenticationExtensions
{
    /// <summary>
    /// Registers the Sync JWT bearer authentication pipeline with defense-in-depth defaults:
    /// validation parameters identical across all services, default authorization policies,
    /// HttpContextAccessor + ICurrentUserContext, and JSON 401/403 responses.
    /// </summary>
    /// <param name="services">DI container.</param>
    /// <param name="configuration">App configuration (expects a "Jwt" section).</param>
    /// <param name="environment">Host environment (used to relax HTTPS in Development).</param>
    /// <param name="requireAuthenticationByDefault">
    /// When true, all controller endpoints require a valid JWT unless marked [AllowAnonymous].
    /// Set false for the API Gateway (YARP routes declare their own policies).
    /// </param>
    public static IServiceCollection AddSyncJwtAuthentication(
        this IServiceCollection services,
        IConfiguration configuration,
        IHostEnvironment environment,
        bool requireAuthenticationByDefault = true)
    {
        var settings = configuration.GetSection(JwtAuthSettings.SectionName).Get<JwtAuthSettings>()
            ?? throw new InvalidOperationException(
                $"'{JwtAuthSettings.SectionName}' configuration section is missing.");

        if (string.IsNullOrWhiteSpace(settings.SecretKey) || settings.SecretKey.Length < 32)
            throw new InvalidOperationException(
                "Jwt:SecretKey must be configured and at least 32 characters long.");

        if (string.IsNullOrWhiteSpace(settings.Issuer) || string.IsNullOrWhiteSpace(settings.Audience))
            throw new InvalidOperationException("Jwt:Issuer and Jwt:Audience must be configured.");

        services.Configure<JwtAuthSettings>(configuration.GetSection(JwtAuthSettings.SectionName));

        services.AddAuthentication(o =>
        {
            o.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
            o.DefaultChallengeScheme    = JwtBearerDefaults.AuthenticationScheme;
        })
        .AddJwtBearer(o =>
        {
            o.RequireHttpsMetadata = !environment.IsDevelopment();
            o.SaveToken            = true;
            o.MapInboundClaims     = false; // keep JWT claim names verbatim (sub, email, role, ...)

            o.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer           = true,
                ValidateAudience         = true,
                ValidateLifetime         = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer              = settings.Issuer,
                ValidAudience            = settings.Audience,
                IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(settings.SecretKey)),
                ClockSkew                = TimeSpan.FromSeconds(30),
                NameClaimType            = ClaimTypes.NameIdentifier,
                RoleClaimType            = ClaimTypes.Role
            };

            o.Events = new JwtBearerEvents
            {
                OnChallenge = async ctx =>
                {
                    if (ctx.Response.HasStarted) return;
                    ctx.HandleResponse();
                    ctx.Response.StatusCode  = StatusCodes.Status401Unauthorized;
                    ctx.Response.ContentType = "application/json";
                    await ctx.Response.WriteAsync(
                        "{\"success\":false,\"message\":\"Authentication required. Provide a valid Bearer token.\",\"data\":null}");
                },
                OnForbidden = async ctx =>
                {
                    if (ctx.Response.HasStarted) return;
                    ctx.Response.StatusCode  = StatusCodes.Status403Forbidden;
                    ctx.Response.ContentType = "application/json";
                    await ctx.Response.WriteAsync(
                        "{\"success\":false,\"message\":\"You do not have permission to access this resource.\",\"data\":null}");
                }
            };
        });

        services.AddAuthorization(options =>
        {
            if (requireAuthenticationByDefault)
            {
                options.FallbackPolicy = new Microsoft.AspNetCore.Authorization.AuthorizationPolicyBuilder()
                    .RequireAuthenticatedUser()
                    .Build();
            }

            options.AddPolicy(AuthPolicies.AuthenticatedUser, p =>
                p.RequireAuthenticatedUser());

            options.AddPolicy(AuthPolicies.AdminOnly, p =>
                p.RequireAuthenticatedUser().RequireRole("SystemAdmin"));
        });

        services.AddHttpContextAccessor();
        services.AddScoped<ICurrentUserContext, CurrentUserContext>();

        return services;
    }

    /// <summary>Adds <c>UseAuthentication()</c> + <c>UseAuthorization()</c> in the correct order.</summary>
    public static IApplicationBuilder UseSyncJwtAuthentication(this IApplicationBuilder app)
    {
        app.UseAuthentication();
        app.UseAuthorization();
        return app;
    }
}
