using Order.Application.Common;
using Order.Application.Exceptions;
using Microsoft.AspNetCore.Diagnostics;

namespace Order.API.Exceptions;

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
            NotFoundException notFoundEx => (StatusCodes.Status404NotFound, notFoundEx.Message, null),
            BadRequestException badRequestEx => (StatusCodes.Status400BadRequest, badRequestEx.Message, null),
            AppValidationException valEx => (StatusCodes.Status400BadRequest, valEx.Message, (object)valEx.Errors),
            ConflictException conflictEx => (StatusCodes.Status409Conflict, conflictEx.Message, null),
            UnauthorizedException unauthEx => (StatusCodes.Status401Unauthorized, unauthEx.Message, null),
            ForbiddenException forbiddenEx => (StatusCodes.Status403Forbidden, forbiddenEx.Message, null),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.", null)
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



