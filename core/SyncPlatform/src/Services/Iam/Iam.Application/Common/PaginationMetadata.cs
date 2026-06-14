namespace Iam.Application.Common;

public class PaginationMetadata
{
    public int PageNumber { get; set; }
    public int PageSize { get; set; }
    public int TotalRecords { get; set; }
    public int TotalPages => PageSize > 0 ? (int)Math.Ceiling(TotalRecords / (double)PageSize) : 0;
    public bool HasNextPage => PageNumber < TotalPages;
    public bool HasPreviousPage => PageNumber > 1;
}
