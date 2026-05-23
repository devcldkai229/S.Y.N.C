using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MongoDB.Driver;
using Notification.Infrastructure.Extensions;
using Notification.Infrastructure.Persistence;
using Notification.Application.Extensions;
using Notification.Application.Common;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Bson;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Notification.API.Exceptions;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

// Layer shared configuration (Jwt, baseline Logging, AllowedHosts) from configs/appsettings.Shared*.json
builder.Configuration.AddSharedConfiguration(builder.Environment);

// ── Services ─────────────────────────────────────────────────────────────────

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Notification API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddNotificationInfrastructure(builder.Configuration);

// JWT authentication + authorization policies + ICurrentUserContext (shared lib)
builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
builder.Services.AddSyncHealthChecks();

    options.UseInlineDefinitionsForEnums();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddNotificationApplication();
builder.Services.AddNotificationInfrastructure(builder.Configuration);

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

app.UseExceptionHandler(_ => { });

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

app.UseSyncJwtAuthentication();

// Initialize MongoDB indexes once at startup — idempotent, safe on every deploy
var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);

app.MapSyncHealthChecks();
app.MapControllers();

app.Run();
