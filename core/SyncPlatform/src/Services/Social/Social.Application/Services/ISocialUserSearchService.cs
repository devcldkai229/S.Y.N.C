using Social.Application.Common;
using Social.Application.DTOs;

namespace Social.Application.Services;

public interface ISocialUserSearchService
{
    Task<(IReadOnlyList<SocialUserSearchItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        Guid viewerUserId,
        SocialUserSearchRequest request,
        CancellationToken cancellationToken = default);
}
