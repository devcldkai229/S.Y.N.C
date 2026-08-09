using Social.Domain.Models;

namespace Social.Domain.Repositories;

public interface IContentReportRepository
{
    Task CreateAsync(ContentReport report, CancellationToken cancellationToken = default);

    Task<(IReadOnlyList<ContentReport> Items, int Total)> ListAsync(
        string? status,
        int skip,
        int take,
        CancellationToken cancellationToken = default);

    Task<ContentReport?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    Task UpdateStatusAsync(Guid id, string status, CancellationToken cancellationToken = default);
}
