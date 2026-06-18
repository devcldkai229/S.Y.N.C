namespace Iam.Application.Common;

public class PagedApiResponse<T>
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
    public T? Data { get; set; }
    public PaginationMetadata? Pagination { get; set; }
    public object? Errors { get; set; }

    public static PagedApiResponse<T> SuccessPagedResponse(
        T data,
        PaginationMetadata pagination,
        string message = "Operation completed successfully.")
    {
        return new PagedApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            Pagination = pagination,
            Errors = null,
        };
    }
}
