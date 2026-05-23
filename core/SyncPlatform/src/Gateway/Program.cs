using System.Security.Claims;
using System.Text;
using System.Threading.RateLimiting;
using Gateway.API.Options;
using Gateway.API.Transforms;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// Layer shared configuration (Jwt, baseline Logging, AllowedHosts) from configs/appsettings.Shared*.json
builder.Configuration.AddSharedConfiguration(builder.Environment);
// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.UseInlineDefinitionsForEnums();
});

var configuration = builder.Configuration;

// ════════════════════════════════════════════════════════════════════════════
// 1. JWT AUTHENTICATION — gateway validates the token ONCE.
//    Downstream services receive the proven identity via X-User-* headers
//    (added by UserClaimsTransformProvider) and do NOT need their own JWT middleware.
// ════════════════════════════════════════════════════════════════════════════

var jwtSettings = configuration.GetSection(GatewayJwtSettings.SectionName).Get<GatewayJwtSettings>()
    ?? throw new InvalidOperationException("'Jwt' configuration section is missing in Gateway.");

if (string.IsNullOrWhiteSpace(jwtSettings.SecretKey) || jwtSettings.SecretKey.Length < 32)
    throw new InvalidOperationException("Jwt:SecretKey must be configured and at least 32 characters long.");

builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme    = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(options =>
    {
        options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        options.SaveToken = false; // token not needed server-side after validation

        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer           = true,
            ValidateAudience         = true,
            ValidateLifetime         = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer              = jwtSettings.Issuer,
            ValidAudience            = jwtSettings.Audience,
            IssuerSigningKey         = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSettings.SecretKey)),
            ClockSkew                = TimeSpan.FromSeconds(30),
            NameClaimType            = ClaimTypes.NameIdentifier,
            RoleClaimType            = ClaimTypes.Role
        };
// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

        // Return 401 JSON (not a redirect to login)
        options.Events = new JwtBearerEvents
        {
            OnChallenge = async ctx =>
            {
                ctx.HandleResponse();
                ctx.Response.StatusCode  = StatusCodes.Status401Unauthorized;
                ctx.Response.ContentType = "application/json";
                await ctx.Response.WriteAsync(
                    "{\"success\":false,\"message\":\"Authentication required. Provide a valid Bearer token.\",\"data\":null}");
            },
            OnForbidden = async ctx =>
            {
                ctx.Response.StatusCode  = StatusCodes.Status403Forbidden;
                ctx.Response.ContentType = "application/json";
                await ctx.Response.WriteAsync(
                    "{\"success\":false,\"message\":\"You do not have permission to access this resource.\",\"data\":null}");
            }
        };
    });

// ════════════════════════════════════════════════════════════════════════════
// 2. AUTHORIZATION POLICIES
// ════════════════════════════════════════════════════════════════════════════

builder.Services.AddAuthorization(options =>
{
    // Applied to every protected YARP route via AuthorizationPolicy = "AuthenticatedUser"
    options.AddPolicy("AuthenticatedUser", policy =>
        policy.RequireAuthenticatedUser());

    // Example role-based policies (extend as needed)
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireAuthenticatedUser().RequireRole("SystemAdmin"));
});

// ════════════════════════════════════════════════════════════════════════════
// 3. RATE LIMITING  (built-in System.Threading.RateLimiting, no extra NuGet)
//    • Anonymous / public endpoints: 30 req/min per remote IP
//    • Authenticated endpoints:      120 req/min per User ID
// ════════════════════════════════════════════════════════════════════════════

builder.Services.AddRateLimiter(rl =>
{
    // Global partitioned limiter — applies before YARP proxies the request
    rl.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(ctx =>
    {
        var user = ctx.User;
        if (user.Identity?.IsAuthenticated == true)
        {
            var userId = user.FindFirstValue(ClaimTypes.NameIdentifier) ?? "authenticated-unknown";
            return RateLimitPartition.GetFixedWindowLimiter(
                partitionKey: $"user:{userId}",
                factory: _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit          = 120,
                    Window               = TimeSpan.FromMinutes(1),
                    QueueLimit           = 10,
                    QueueProcessingOrder = QueueProcessingOrder.OldestFirst
                });
        }

        var ip = ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown-ip";
        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: $"anon:{ip}",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit          = 30,
                Window               = TimeSpan.FromMinutes(1),
                QueueLimit           = 5,
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst
            });
    });

    rl.OnRejected = async (ctx, token) =>
    {
        ctx.HttpContext.Response.StatusCode  = StatusCodes.Status429TooManyRequests;
        ctx.HttpContext.Response.ContentType = "application/json";
        ctx.HttpContext.Response.Headers["Retry-After"] = "60";
        await ctx.HttpContext.Response.WriteAsync(
            "{\"success\":false,\"message\":\"Too many requests. Please slow down and retry after 60 seconds.\",\"data\":null}",
            token);
    };
});

// ════════════════════════════════════════════════════════════════════════════
// 4. CORS
// ════════════════════════════════════════════════════════════════════════════

builder.Services.AddCors(options =>
{
    var allowedOrigins = configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

    options.AddDefaultPolicy(policy =>
    {
        if (allowedOrigins.Length == 0 || allowedOrigins.Contains("*"))
        {
            policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader();
        }
        else
        {
            policy
                .WithOrigins(allowedOrigins)
                .AllowAnyMethod()
                .AllowAnyHeader()
                .AllowCredentials()
                .WithExposedHeaders("X-Request-Id", "Retry-After");
        }
    });
});

// ════════════════════════════════════════════════════════════════════════════
// 5. HEALTH CHECKS
// ════════════════════════════════════════════════════════════════════════════

builder.Services.AddHealthChecks();

// ════════════════════════════════════════════════════════════════════════════
// 6. YARP REVERSE PROXY
//    Routes and clusters are defined in appsettings.json (ReverseProxy section).
//    UserClaimsTransformProvider is registered globally — runs on every route.
// ════════════════════════════════════════════════════════════════════════════

builder.Services
    .AddReverseProxy()
    .LoadFromConfig(configuration.GetSection("ReverseProxy"))
    .AddTransforms<UserClaimsTransformProvider>();

// ════════════════════════════════════════════════════════════════════════════
// APPLICATION PIPELINE
// ════════════════════════════════════════════════════════════════════════════

var app = builder.Build();

// 1. CORS must come first so preflight requests get headers before auth rejects them
app.UseCors();

// 2. Rate limiting — applied early so bots are rejected before auth overhead
app.UseRateLimiter();

// 3. Auth middleware (populates HttpContext.User from Bearer token)
app.UseAuthentication();
app.UseAuthorization();

// 4. Health probe — unauthenticated, excluded from rate limiting by its own endpoint group
app.MapHealthChecks("/health").AllowAnonymous();

// 5. YARP — must be last; it proxies to downstream services
//    Route-level AuthorizationPolicy is enforced by UseAuthorization() above
app.MapReverseProxy();

app.Run();
