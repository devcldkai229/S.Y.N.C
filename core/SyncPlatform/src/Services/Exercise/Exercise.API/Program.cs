using System.Text.Json.Serialization;
using Exercise.API.Exceptions;
using Exercise.Application.Common;
using Exercise.Application.Extensions;
using Exercise.Infrastructure.Extensions;
using Exercise.Infrastructure.Persistence;
using Exercise.Infrastructure.Persistence.Seed;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddSharedConfiguration(builder.Environment);

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Exercise API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddExerciseApplication();
builder.Services.AddExerciseInfrastructure(builder.Configuration);

//builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
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

//app.UseSyncJwtAuthentication();

var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await ExerciseSeedData.ExerciseMongoSeeder.SeedAsync(mongoDb);
await MongoDbIndexInitializer.InitializeAsync(mongoDb);

//app.MapSyncHealthChecks();
app.MapControllers();

app.Run();
