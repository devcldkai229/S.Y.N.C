using Microsoft.Extensions.DependencyInjection;
using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace Libs.Auth.Extensions;

public static class SwaggerJwtExtensions
{
    /// <summary>
    /// Adds the Bearer security definition that powers the "Authorize" button in Swagger UI.
    /// Call inside <c>AddSwaggerGen(options => options.AddJwtBearerSecurityScheme())</c>.
    /// </summary>
    public static SwaggerGenOptions AddJwtBearerSecurityScheme(this SwaggerGenOptions options)
    {
        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            Name         = "Authorization",
            Type         = SecuritySchemeType.Http,
            Scheme       = "bearer",
            BearerFormat = "JWT",
            In           = ParameterLocation.Header,
            Description  = "Enter the JWT access token (without the 'Bearer ' prefix)."
        });
        return options;
    }
}
