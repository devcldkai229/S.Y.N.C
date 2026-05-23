using Notification.Application.Common;
using Notification.Application.Exceptions;
using Microsoft.AspNetCore.Diagnostics;

namespace Notification.API.Exceptions;

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
        var (statusCode, message, errors) = exception switch
        {
            NotFoundException notFoundEx => (StatusCodes.Status404NotFound, notFoundEx.Message, (object?)null),
            BadRequestException badRequestEx => (StatusCodes.Status400BadRequest, badRequestEx.Message, (object?)null),
            ConflictException conflictEx => (StatusCodes.Status409Conflict, conflictEx.Message, (object?)null),
            ForbiddenException forbiddenEx => (StatusCodes.Status403Forbidden, forbiddenEx.Message, (object?)null),
            UnauthorizedAccessException unauthEx => (StatusCodes.Status401Unauthorized, unauthEx.Message, (object?)null),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.", (object?)null)
        };

        if (statusCode == StatusCodes.Status500InternalServerError)
        {
            _logger.LogError(exception, "Unhandled exception occurred: {Message}", exception.Message);
        }

        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/json";

        var response = ApiResponse<object>.FailureResponse(message, errors);
        
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }
}
