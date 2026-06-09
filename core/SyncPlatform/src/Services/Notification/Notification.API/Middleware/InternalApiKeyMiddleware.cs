using System.Net;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Notification.Application.Common;

namespace Notification.API.Middleware;

public class InternalApiKeyMiddleware
{
    private readonly RequestDelegate _next;
    private readonly string _expectedApiKey;
    private readonly ILogger<InternalApiKeyMiddleware> _logger;

    public InternalApiKeyMiddleware(RequestDelegate next, IConfiguration configuration, ILogger<InternalApiKeyMiddleware> logger)
    {
        _next = next;
        _logger = logger;
        _expectedApiKey = configuration["InternalApiKey"] ?? string.Empty;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path.StartsWithSegments("/api/internal"))
        {
            if (string.IsNullOrEmpty(_expectedApiKey))
            {
                _logger.LogWarning("Internal API Key is not configured.");
                await WriteUnauthorizedAsync(context, "Internal API Key is not configured.");
                return;
            }

            if (!context.Request.Headers.TryGetValue("X-Internal-Api-Key", out var key))
            {
                await WriteUnauthorizedAsync(context, "API Key is missing.");
                return;
            }

            if (!string.Equals(_expectedApiKey, key.ToString()))
            {
                await WriteUnauthorizedAsync(context, "Unauthorized access.");
                return;
            }
        }

        await _next(context);
    }

    private static async Task WriteUnauthorizedAsync(HttpContext context, string message)
    {
        context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
        context.Response.ContentType = "application/json";
        var json = JsonSerializer.Serialize(
            ApiResponse<object>.FailureResponse(message),
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });
        await context.Response.WriteAsync(json);
    }
}
