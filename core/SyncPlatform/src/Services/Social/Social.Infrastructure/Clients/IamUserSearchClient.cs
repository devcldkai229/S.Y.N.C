using System.Net.Http.Json;
using Social.Application.Clients;
using Social.Application.Common;

namespace Social.Infrastructure.Clients;

public sealed class IamUserSearchClient : IIamUserSearchClient
{
    private readonly HttpClient _http;

    public IamUserSearchClient(HttpClient http) => _http = http;

    public async Task<(IReadOnlyList<IamUserSearchItem> Items, PaginationMetadata Pagination)> SearchAsync(
        string query,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        var response = await _http.GetFromJsonAsync<PagedApiEnvelope>(
            $"/api/v1/users/search?query={Uri.EscapeDataString(query)}&pageNumber={pageNumber}&pageSize={pageSize}",
            cancellationToken);

        if (response is null || !response.Success || response.Data is null)
            return ([], new PaginationMetadata { PageNumber = pageNumber, PageSize = pageSize, TotalRecords = 0 });

        var items = response.Data
            .Select(x => new IamUserSearchItem
            {
                Id = x.Id,
                FullName = x.FullName,
                AvatarUrl = x.AvatarUrl,
            })
            .ToList();

        return (items, response.Pagination ?? new PaginationMetadata
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = items.Count,
        });
    }

    private sealed class PagedApiEnvelope
    {
        public bool Success { get; set; }
        public List<IamUserSearchPayload>? Data { get; set; }
        public PaginationMetadata? Pagination { get; set; }
    }

    private sealed class IamUserSearchPayload
    {
        public Guid Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
    }
}
