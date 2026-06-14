using Social.Application.Common;

namespace Social.Application.Clients;

public interface IIamUserSearchClient
{
    Task<(IReadOnlyList<IamUserSearchItem> Items, PaginationMetadata Pagination)> SearchAsync(
        string query,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}

public sealed class IamUserSearchItem
{
    public Guid Id { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string? AvatarUrl { get; init; }
}
