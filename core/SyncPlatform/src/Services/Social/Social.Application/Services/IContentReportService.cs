using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IContentReportService
{
    Task<ContentReportDto> CreateAsync(
        Guid reporterId,
        CreateContentReportDto dto,
        CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<AdminContentReportDto> Items, PaginationMetadata Pagination)> ListAdminAsync(
        string? status,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    Task<AdminContentReportDto> ResolveAsync(
        Guid id,
        string status,
        bool? hidePost = null,
        CancellationToken cancellationToken = default);
}
