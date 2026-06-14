using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Domain.Enums;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class SocialUserSearchService : ISocialUserSearchService
{
    private const int MaxPageSize = 50;

    private readonly IIamUserSearchClient _iamUsers;
    private readonly IUserFollowRepository _follows;

    public SocialUserSearchService(IIamUserSearchClient iamUsers, IUserFollowRepository follows)
    {
        _iamUsers = iamUsers;
        _follows = follows;
    }

    public async Task<(IReadOnlyList<SocialUserSearchItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        Guid viewerUserId,
        SocialUserSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var query = request.Query?.Trim() ?? string.Empty;
        if (query.Length < 2)
        {
            return ([], new PaginationMetadata { PageNumber = 1, PageSize = 20, TotalRecords = 0 });
        }

        var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
        var pageSize = request.PageSize < 1 ? 20 : Math.Min(request.PageSize, MaxPageSize);

        var blockedPeerIds = await _follows.GetBlockedPeerIdsAsync(viewerUserId, cancellationToken);
        var blockedSet = blockedPeerIds.ToHashSet();

        var visible = new List<SocialUserSearchItemDto>();
        var iamPage = pageNumber;
        var hasMoreIam = true;
        const int maxIamPages = 5;

        while (visible.Count < pageSize && hasMoreIam && iamPage <= pageNumber + maxIamPages)
        {
            var (iamItems, iamPagination) = await _iamUsers.SearchAsync(
                query,
                iamPage,
                pageSize,
                cancellationToken);

            if (iamItems.Count == 0)
            {
                hasMoreIam = false;
                break;
            }

            foreach (var user in iamItems)
            {
                if (user.Id == viewerUserId || blockedSet.Contains(user.Id))
                    continue;

                var outgoing = await _follows.GetByPairAsync(viewerUserId, user.Id, cancellationToken);

                visible.Add(new SocialUserSearchItemDto
                {
                    Id = user.Id,
                    FullName = user.FullName,
                    AvatarUrl = user.AvatarUrl,
                    OutgoingStatus = outgoing?.Status,
                    CanFollow = outgoing is null,
                });

                if (visible.Count >= pageSize)
                    break;
            }

            hasMoreIam = iamPagination.HasNextPage;
            iamPage++;
        }

        var pagination = new PaginationMetadata
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = visible.Count,
        };

        if (hasMoreIam && visible.Count >= pageSize)
            pagination.TotalRecords = pageNumber * pageSize + 1;

        return (visible, pagination);
    }
}
