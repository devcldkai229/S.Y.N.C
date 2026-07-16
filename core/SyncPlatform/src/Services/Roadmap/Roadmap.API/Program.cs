using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Libs.Storage.Extensions;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;
using Roadmap.API.Hubs;
using Roadmap.API.Middleware;
using Roadmap.API.Services;
using Roadmap.Application.Common;
using Roadmap.Application.Extensions;
using Roadmap.Application.Services;
using Roadmap.Infrastructure.Extensions;
using Roadmap.Infrastructure.Persistence;
using Roadmap.Infrastructure.Persistence.Seed;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);


builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Roadmap API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<Roadmap.API.Exceptions.GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddRoadmapApplication();
builder.Services.AddRoadmapInfrastructure(builder.Configuration);
builder.Services.AddS3ObjectStorage(builder.Configuration);
builder.Services.AddSingleton<IWorkoutMediaStorage, S3WorkoutMediaStorage>();

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true)
            .AllowCredentials());
});

builder.Services.AddSignalR();
builder.Services.AddSingleton<IRoadmapRealtimePublisher, SignalRRoadmapRealtimePublisher>();

// JWT authentication + authorization policies + ICurrentUserContext (shared lib)
builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
builder.Services.PostConfigure<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme, options =>
{
    var previous = options.Events.OnMessageReceived;
    options.Events.OnMessageReceived = context =>
    {
        var accessToken = context.Request.Query["access_token"];
        var path = context.HttpContext.Request.Path;
        if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments(RoadmapHub.HubPath))
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
                    kvp => kvp.Value!.Errors.Select(x => x.ErrorMessage).ToArray()
                );

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
await RoadmapSeedData.RoadmapMongoSeeder.SeedAsync(mongoDb, app.Configuration);

app.MapSyncHealthChecks();
app.MapHub<RoadmapHub>(RoadmapHub.HubPath);
app.MapControllers();

app.Run();
