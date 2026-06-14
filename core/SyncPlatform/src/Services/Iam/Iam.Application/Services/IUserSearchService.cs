using Iam.Application.Common;
using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IUserSearchService
{
    Task<(IReadOnlyList<UserSearchItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        UserSearchRequest request,
        CancellationToken cancellationToken = default);
}
