namespace Social.Application.Common;

/// <summary>
/// Standard API envelope for cursor-paginated feeds (data + nextCursor).
/// </summary>
public class CursorApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public string? NextCursor { get; set; }
    public object? Errors { get; set; }

    public static CursorApiResponse<T> SuccessResponse(
        T data,
        string? nextCursor,
        string message = "Operation completed successfully.")
    {
        return new CursorApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            NextCursor = nextCursor,
            Errors = null,
        };
    }

    public static CursorApiResponse<T> FailureResponse(string message, object? errors = null)
    {
        return new CursorApiResponse<T>
        {
            Success = false,
            Message = message,
            Data = default,
            NextCursor = null,
            Errors = errors,
        };
    }
}
