using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;
using Social.API.Exceptions;
using Social.API.Options;
using Social.Application.Common;
using Social.Application.Extensions;
using Social.Application.Services;
using Social.Infrastructure.Extensions;
using Social.Infrastructure.Persistence;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddSharedConfiguration(builder.Environment);

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Social API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddSocialApplication();
builder.Services.AddSocialInfrastructure(builder.Configuration);
builder.Services.Configure<SocialMaintenanceOptions>(
    builder.Configuration.GetSection(SocialMaintenanceOptions.SectionName));

builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
builder.Services.AddSyncHealthChecks();

builder.Services.AddCors(options =>
{
    options.AddPolicy("DevCors", policy =>
        policy.SetIsOriginAllowed(_ => true)
            .AllowAnyHeader()
            .AllowAnyMethod());
});

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

if (app.Environment.IsDevelopment())
{
    app.UseCors("DevCors");
}

app.UseSyncJwtAuthentication();

var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);

using (var s3Scope = app.Services.CreateScope())
{
    await s3Scope.ServiceProvider
        .GetRequiredService<Social.Infrastructure.Persistence.Seed.S3DevAssetSeeder>()
        .SeedPlaceholdersAsync();
}

await app.Services.InitializeSocialDatabaseAsync();

var maintenanceOptions = app.Configuration
    .GetSection(SocialMaintenanceOptions.SectionName)
    .Get<SocialMaintenanceOptions>();

if (maintenanceOptions?.BackfillShareCodesOnStartup == true)
{
    using var scope = app.Services.CreateScope();
    var backfill = scope.ServiceProvider.GetRequiredService<IPostShareCodeBackfillService>();
    await backfill.BackfillAllAsync();
}

app.MapSyncHealthChecks();
app.MapControllers();

app.Run();
