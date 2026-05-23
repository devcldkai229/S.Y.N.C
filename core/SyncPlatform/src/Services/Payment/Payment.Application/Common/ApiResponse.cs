namespace Payment.Application.Common;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public object? Errors { get; set; }

    public static ApiResponse<T> SuccessResponse(T data, string message = "Operation completed successfully.")
        => new() { Success = true, Message = message, Data = data, Errors = null };

    public static ApiResponse<T> FailureResponse(string message, object? errors = null)
        => new() { Success = false, Message = message, Data = default, Errors = errors };
}
