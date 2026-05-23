namespace Roadmap.Application.Common;

public class PagedApiResponse<T> : ApiResponse<T>
{
    public PaginationMetadata Pagination { get; set; } = new();

    public static PagedApiResponse<T> SuccessPagedResponse(T data, PaginationMetadata pagination, string message = "Data retrieved successfully.")
    {
        return new PagedApiResponse<T>
        {
            Success = true,
            Message = message,
            Data = data,
            Pagination = pagination,
            Errors = null
        };
    }
}
