using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Notification.API.Hubs;
using Notification.API.Services;
using Notification.Application.Services;
using Microsoft.OpenApi;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;
using Notification.API.Exceptions;
using Notification.API.Middleware;
using Notification.Application.Common;
using Notification.Application.Extensions;
using Notification.Infrastructure.Extensions;
using Notification.Infrastructure.Persistence;
using Notification.Infrastructure.Persistence.Seed;
using Notification.API.BackgroundWorkers;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddSharedConfiguration(builder.Environment);

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Notification API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddNotificationApplication();
builder.Services.AddNotificationInfrastructure(builder.Configuration);
builder.Services.AddHostedService<SmartPushPlannerWorker>();
builder.Services.AddHostedService<ScheduledNotificationDispatcherWorker>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true)
            .AllowCredentials());
});

builder.Services.AddSignalR();
builder.Services.AddSingleton<INotificationRealtimePublisher, SignalRNotificationRealtimePublisher>();

builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);

builder.Services.PostConfigure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
{
    var previous = options.Events.OnMessageReceived;
    options.Events.OnMessageReceived = context =>
    {
        var accessToken = context.Request.Query["access_token"];
        var path = context.HttpContext.Request.Path;
        if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments(NotificationHub.HubPath))
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
app.UseCors();
app.UseSyncJwtAuthentication();

var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);
await NotificationSeedData.NotificationMongoSeeder.SeedAsync(mongoDb);

app.MapSyncHealthChecks();
app.MapHub<NotificationHub>(NotificationHub.HubPath);
app.MapControllers();

app.Run();
