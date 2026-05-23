using System.Text.Json.Serialization;
using Iam.Application.Common;
using Iam.Application.Extensions;
using Iam.Infrastructure.Extensions;
using Libs.Auth.Extensions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.OpenApi;
using Iam.API.Auth;
using Iam.API.Endpoints;
using Iam.API.Middleware;
using Iam.Application.Abstractions;
using Iam.Application.Extensions;
using Iam.Infrastructure.Extensions;
using Iam.API.Exceptions;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

// Layer shared configuration (Jwt, baseline Logging, AllowedHosts) from configs/appsettings.Shared*.json
builder.Configuration.AddSharedConfiguration(builder.Environment);

// ── Services ─────────────────────────────────────────────────────────────────

builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo { Title = "IAM API", Version = "v1" });
    options.UseInlineDefinitionsForEnums();
    options.AddJwtBearerSecurityScheme();
});

builder.Services.AddExceptionHandler<Iam.API.Exceptions.GlobalExceptionHandler>();

builder.Services.AddIamApplication(builder.Configuration);
builder.Services.AddIamInfrastructure(builder.Configuration);
builder.Services.AddScoped<ICurrentUserAccessor, HeaderCurrentUserAccessor>();

builder.Services.AddAuthentication(DevAuthenticationHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, DevAuthenticationHandler>(
        DevAuthenticationHandler.SchemeName,
        _ => { });

builder.Services.AddAuthorization();

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(new JsonStringEnumConverter());
    });

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
                    kvp => kvp.Value!.Errors.Select(x => x.ErrorMessage).ToArray());

            var response = ApiResponse<object>.FailureResponse("Validation failed.", errors);
            return new BadRequestObjectResult(response);
        };
    });

// ── Pipeline ─────────────────────────────────────────────────────────────────

var app = builder.Build();

app.UseExceptionHandler(_ => { });
app.UseMiddleware<ExceptionHandlingMiddleware>();

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

app.MapSyncHealthChecks();
app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapMeEndpoints();

app.MapControllers();

app.Run();
