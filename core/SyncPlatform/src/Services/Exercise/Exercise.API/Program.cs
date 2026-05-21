using Exercise.Application.Common;
using Exercise.Application.Extensions;
using Exercise.Infrastructure.Extensions;
using Exercise.Infrastructure.Persistence;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using MongoDB.Driver;
using System.Text.Json.Serialization;
using static Exercise.Infrastructure.Persistence.Seed.ExerciseSeedData;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.UseInlineDefinitionsForEnums();
});

builder.Services.AddExceptionHandler<Exercise.API.Exceptions.GlobalExceptionHandler>();
builder.Services.AddExerciseApplication();
builder.Services.AddExerciseInfrastructure(builder.Configuration);

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

using var scope = app.Services.CreateScope();

var database = scope.ServiceProvider.GetRequiredService<IMongoDatabase>();

await ExerciseMongoSeeder.SeedAsync(database);

app.UseExceptionHandler(_ => { });

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Initialize MongoDB indexes once at startup — idempotent, safe on every deploy
var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);

app.MapControllers();

app.Run();