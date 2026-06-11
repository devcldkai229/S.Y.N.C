using System.Text.Json.Serialization;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using Payment.API.Exceptions;
using Payment.API.Middleware;
using Payment.Application.Common;
using Payment.Application.Extensions;
using Payment.Infrastructure.Extensions;
using Payment.Infrastructure.Persistence;
using Payment.Infrastructure.Persistence.Seed;

var builder = WebApplication.CreateBuilder(args);

// Layer shared configuration (Jwt, baseline Logging, AllowedHosts) from configs/appsettings.Shared*.json
builder.Configuration.AddSharedConfiguration(builder.Environment);

// ── Services ─────────────────────────────────────────────────────────────────

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "Payment API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
builder.Services.AddProblemDetails();

builder.Services.AddPaymentApplication(builder.Configuration);
builder.Services.AddPaymentInfrastructure(builder.Configuration);

// JWT authentication + authorization policies + ICurrentUserContext (shared lib)
builder.Services.AddSyncJwtAuthentication(builder.Configuration, builder.Environment);
builder.Services.AddSyncHealthChecks();

builder.Services.AddControllers()
    .AddJsonOptions(opt =>
    {
        opt.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    })
    .ConfigureApiBehaviorOptions(opt =>
    {
        opt.InvalidModelStateResponseFactory = ctx =>
        {
            var errors = ctx.ModelState
                .Where(e => e.Value?.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value!.Errors.Select(x => x.ErrorMessage).ToArray());
            return new BadRequestObjectResult(
                ApiResponse<object>.FailureResponse("Validation failed.", errors));
        };
    });

// ── Pipeline ─────────────────────────────────────────────────────────────────

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<PaymentDbContext>();
    await PaymentSeedData.PaymentDbSeeder.SeedAsync(db);
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

app.Run();
