using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;
using Roadmap.Application.Common;
using Roadmap.Application.Extensions;
using Roadmap.Infrastructure.Extensions;
using Roadmap.Infrastructure.Persistence;
using System.Text.Json.Serialization;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

// Layer shared configuration (Jwt, baseline Logging, AllowedHosts) from configs/appsettings.Shared*.json
builder.Configuration.AddSharedConfiguration(builder.Environment);

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

// JWT authentication + authorization policies + ICurrentUserContext (shared lib)
builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
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

app.UseSyncJwtAuthentication();

var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);
await app.Services.InitializeRoadmapDatabaseAsync();

app.MapSyncHealthChecks();
app.MapControllers();

app.Run();
