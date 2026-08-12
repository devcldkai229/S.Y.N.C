using Microsoft.AspNetCore.Diagnostics;
using MongoDB.Driver;
using Roadmap.Application.Common;
using Roadmap.Application.Exceptions;

namespace Roadmap.API.Exceptions;

public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;

    private const string DuplicateKeyUserMessage =
        "Dữ liệu roadmap đang được đồng bộ. Vui lòng thử lại sau.";

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger)
    {
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext httpContext,
        Exception exception,
        CancellationToken cancellationToken)
    {
        var (statusCode, message) = MapException(exception);

        if (statusCode == StatusCodes.Status500InternalServerError)
            _logger.LogError(exception, "Unhandled exception: {Message}", exception.Message);

        httpContext.Response.StatusCode = statusCode;
        httpContext.Response.ContentType = "application/json";

        var response = ApiResponse<object>.FailureResponse(message);
        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }

    private static (int StatusCode, string Message) MapException(Exception exception) =>
        exception switch
        {
            NotFoundException notFoundEx =>
                (StatusCodes.Status404NotFound, notFoundEx.Message),

            BadRequestException badEx =>
                (StatusCodes.Status400BadRequest, badEx.Message),

            ConflictException conflictEx =>
                (StatusCodes.Status409Conflict, conflictEx.Message),

            UnauthorizedAccessException unauthEx =>
                (StatusCodes.Status401Unauthorized, unauthEx.Message),

            MongoWriteException writeEx when IsDuplicateKey(writeEx) =>
                (StatusCodes.Status409Conflict, DuplicateKeyUserMessage),

            MongoBulkWriteException bulkEx when IsDuplicateKeyBulkWrite(bulkEx) =>
                (StatusCodes.Status409Conflict, DuplicateKeyUserMessage),

            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred.")
        };

    private static bool IsDuplicateKey(MongoWriteException ex) =>
        ex.WriteError?.Category == ServerErrorCategory.DuplicateKey;

    private static bool IsDuplicateKeyBulkWrite(MongoBulkWriteException ex) =>
        ex.WriteErrors.Count > 0 &&
        ex.WriteErrors.All(e => e.Category == ServerErrorCategory.DuplicateKey);
}
