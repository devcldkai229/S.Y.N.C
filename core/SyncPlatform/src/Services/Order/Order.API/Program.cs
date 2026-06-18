using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using Order.API.Exceptions;
using Order.API.Hubs;
using Order.API.Middleware;
using Order.API.Services;
using Order.Application.Common;
using Order.Application.Extensions;
using Order.Application.Ports;
using Order.Infrastructure.Extensions;
using Order.Infrastructure.Persistence;
using Order.Infrastructure.Persistence.Seed;
using Microsoft.Extensions.Options;
using Order.Infrastructure.Options;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddSharedConfiguration(builder.Environment);

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Order API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddOrderApplication();
builder.Services.AddOrderInfrastructure(builder.Configuration);

var redisConnection = builder.Configuration.GetConnectionString("Redis")
    ?? builder.Configuration["Redis:Configuration"]
    ?? "localhost:6379";

builder.Services.AddSignalR()
    .AddStackExchangeRedis(redisConnection, options =>
    {
        options.Configuration.ChannelPrefix = StackExchange.Redis.RedisChannel.Pattern("sync-order");
    });

builder.Services.AddScoped<ITrackingRealtimePublisher, TrackingRealtimePublisher>();

builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);

builder.Services.PostConfigure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
{
    var previous = options.Events.OnMessageReceived;
    options.Events.OnMessageReceived = context =>
    {
        var accessToken = context.Request.Query["access_token"];
        var path = context.HttpContext.Request.Path;
        if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments(TrackingHub.HubPath))
            context.Token = accessToken;

        return previous is null ? Task.CompletedTask : previous(context);
    };
});

builder.Services.AddSyncHealthChecks();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    })
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState
                .Where(e => e.Value?.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value!.Errors.Select(x => x.ErrorMessage).ToArray());

            var response = ApiResponse<object>.FailureResponse("Validation failed.", errors);
            return new BadRequestObjectResult(response);
        };
    });

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<OrderDbContext>();
    await OrderSeedData.OrderDbSeeder.SeedAsync(db);
}

app.UseExceptionHandler();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseHttpsRedirection();
}

app.UseMiddleware<InternalApiKeyMiddleware>();
app.UseSyncJwtAuthentication();

app.MapSyncHealthChecks();
app.MapControllers();
app.MapHub<TrackingHub>(TrackingHub.HubPath);

var orderSettings = app.Services.GetRequiredService<IOptions<OrderSettings>>().Value;
var ahamoveSettings = app.Services.GetRequiredService<IOptions<AhamoveSettings>>().Value;
if (!string.IsNullOrWhiteSpace(orderSettings.AhamoveWebhookUrl))
{
    app.Logger.LogInformation(
        "Ahamove webhook URL (register in partner portal): {WebhookUrl}",
        orderSettings.AhamoveWebhookUrl);
    app.Logger.LogInformation(
        "Ahamove webhook auth — header: apikey, token: WebhookApiKey from config (empty = accept all in dev)");
}
else
{
    app.Logger.LogWarning(
        "Order:PublicBaseUrl is not set — Ahamove webhooks cannot reach this service. " +
        "Set PublicBaseUrl to your ngrok URL (e.g. https://xxx.ngrok-free.dev).");
}

app.Logger.LogInformation(
    "Ahamove mode — Enabled={Enabled}, UseSandboxSimulation={UseSandboxSimulation}, SimulateDeliveryProgress={SimulateDeliveryProgress}",
    ahamoveSettings.Enabled,
    ahamoveSettings.UseSandboxSimulation,
    orderSettings.SimulateDeliveryProgress);

app.Run();
