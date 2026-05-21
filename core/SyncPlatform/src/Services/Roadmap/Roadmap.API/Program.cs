using Microsoft.AspNetCore.Mvc;
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

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.UseInlineDefinitionsForEnums();
});

builder.Services.AddExceptionHandler<Roadmap.API.Exceptions.GlobalExceptionHandler>();
builder.Services.AddRoadmapApplication();
builder.Services.AddRoadmapInfrastructure(builder.Configuration);

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

if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

var mongoDb = app.Services.GetRequiredService<IMongoDatabase>();
await MongoDbIndexInitializer.InitializeAsync(mongoDb);

app.MapControllers();

app.Run();
