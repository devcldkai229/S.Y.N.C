using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Domain.Enums;
using Iam.Domain.Repositories;
using Libs.Storage.Services;

namespace Iam.Application.Services;

public class UserSearchService : IUserSearchService
{
    private const int MaxPageSize = 50;

    private readonly IUserRepository _users;
    private readonly IMediaUrlResolver _media;

    public UserSearchService(IUserRepository users, IMediaUrlResolver media)
    {
        _users = users;
        _media = media;
    }

    public async Task<(IReadOnlyList<UserSearchItemDto> Items, PaginationMetadata Pagination)> SearchAsync(
        UserSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var query = request.Query?.Trim() ?? string.Empty;
        if (query.Length < 2)
        {
            return ([], new PaginationMetadata { PageNumber = 1, PageSize = 20, TotalRecords = 0 });
        }

        var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
        var pageSize = request.PageSize < 1 ? 20 : Math.Min(request.PageSize, MaxPageSize);

        var (users, total) = await _users.SearchByFullNameAsync(
            query,
            UserStatus.Active,
            pageNumber,
            pageSize,
            cancellationToken);

        var items = users
            .Select(u => new UserSearchItemDto
            {
                Id = u.Id,
                FullName = u.FullName,
                AvatarUrl = _media.ResolveForDisplay(u.AvatarUrl),
            })
            .ToList();

        return (items, new PaginationMetadata
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = total,
        });
    }
}
