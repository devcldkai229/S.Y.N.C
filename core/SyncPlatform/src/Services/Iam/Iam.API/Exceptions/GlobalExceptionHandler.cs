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
        var (statusCode, message) = exception switch
        {
            NotFoundException notFoundEx => (StatusCodes.Status404NotFound, notFoundEx.Message),
            BadRequestException badEx => (StatusCodes.Status400BadRequest, badEx.Message),
            ConflictException conflictEx => (StatusCodes.Status409Conflict, conflictEx.Message),
            UnauthorizedException unauthEx => (StatusCodes.Status401Unauthorized, unauthEx.Message),
            ForbiddenException forbiddenEx => (StatusCodes.Status403Forbidden, forbiddenEx.Message),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.")
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
            _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/json";

        var response = ApiResponse<object>.FailureResponse(message);
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }
}
