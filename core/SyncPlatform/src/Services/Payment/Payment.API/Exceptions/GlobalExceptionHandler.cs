using Microsoft.AspNetCore.Diagnostics;
using Payment.Application.Common;
using Payment.Application.Exceptions;

namespace Payment.API.Exceptions;

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
            NotFoundException nf            => (StatusCodes.Status404NotFound,    nf.Message),
            BadRequestException br          => (StatusCodes.Status400BadRequest,  br.Message),
            ConflictException cf            => (StatusCodes.Status409Conflict,    cf.Message),
            UnauthorizedException un        => (StatusCodes.Status401Unauthorized, un.Message),
            ForbiddenException fb           => (StatusCodes.Status403Forbidden,   fb.Message),
            PaymentGatewayException pg      => (StatusCodes.Status502BadGateway,  pg.Message),
            AppException ae                 => (StatusCodes.Status500InternalServerError, ae.Message),
            _                               => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.")
        };

        if (statusCode >= 500)
            _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        httpContext.Response.StatusCode  = statusCode;
        httpContext.Response.ContentType = "application/json";

        var response = ApiResponse<object>.FailureResponse(message);
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }
}
