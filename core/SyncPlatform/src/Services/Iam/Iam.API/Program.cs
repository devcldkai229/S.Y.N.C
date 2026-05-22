using Iam.API.Auth;
using Iam.API.Endpoints;
using Iam.API.Middleware;
using Iam.Application.Abstractions;
using Iam.Application.Extensions;
using Iam.Infrastructure.Extensions;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddOpenApi();
builder.Services.AddHttpContextAccessor();
builder.Services.AddIamApplication();
builder.Services.AddIamInfrastructure(builder.Configuration);
builder.Services.AddScoped<ICurrentUserAccessor, HeaderCurrentUserAccessor>();

builder.Services.AddAuthentication(DevAuthenticationHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, DevAuthenticationHandler>(
        DevAuthenticationHandler.SchemeName,
        _ => { });

builder.Services.AddAuthorization();

var app = builder.Build();

app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();

app.MapMeEndpoints();

app.Run();
