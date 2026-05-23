using Iam.Application.Common;
using Iam.Application.Exceptions;
using Microsoft.AspNetCore.Diagnostics;

namespace Iam.API.Exceptions;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (statusCode, message, errors) = MapException(exception);

        if (statusCode == StatusCodes.Status500InternalServerError)
            _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/json";

        var response = ApiResponse<object>.FailureResponse(message, errors);
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }

    private static (int StatusCode, string Message, object? Errors) MapException(Exception exception) =>
        exception switch
        {
            NotFoundException ex =>
                (StatusCodes.Status404NotFound, ex.Message, null),

            BadRequestException ex =>
                (StatusCodes.Status400BadRequest, ex.Message, null),

            AppValidationException ex =>
                (StatusCodes.Status400BadRequest, ex.Message, ex.Errors),

            ConflictException ex =>
                (StatusCodes.Status409Conflict, ex.Message, null),

            UnauthorizedException ex =>
                (StatusCodes.Status401Unauthorized, ex.Message, null),

            ForbiddenException ex =>
                (StatusCodes.Status403Forbidden, ex.Message, null),

            UnauthorizedAccessException ex =>
                (StatusCodes.Status401Unauthorized, ex.Message, null),

            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.", null)
        };
}
