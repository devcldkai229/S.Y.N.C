using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public sealed class ContentReportService : IContentReportService
{
    private static readonly HashSet<string> AllowedResolveStatuses = new(StringComparer.OrdinalIgnoreCase)
    {
        "Dismissed",
        "Actioned",
        "Reviewed",
    };

    private readonly IContentReportRepository _reports;
    private readonly IPostRepository _posts;

    public ContentReportService(IContentReportRepository reports, IPostRepository posts)
    {
        _reports = reports;
        _posts = posts;
    }

    public async Task<ContentReportDto> CreateAsync(
        Guid reporterId,
        CreateContentReportDto dto,
        CancellationToken cancellationToken = default)
    {
        if (dto.TargetId == Guid.Empty)
            throw new ArgumentException("TargetId is required.");
        if (string.IsNullOrWhiteSpace(dto.Reason))
            throw new ArgumentException("Reason is required.");

        var entity = new ContentReport
        {
            ReporterId = reporterId,
            TargetId = dto.TargetId,
            TargetType = string.IsNullOrWhiteSpace(dto.TargetType) ? "Post" : dto.TargetType.Trim(),
            Reason = dto.Reason.Trim(),
            Details = string.IsNullOrWhiteSpace(dto.Details) ? null : dto.Details.Trim(),
            Status = "Pending",
        };

        await _reports.CreateAsync(entity, cancellationToken);

        return new ContentReportDto
        {
            Id = entity.Id,
            TargetId = entity.TargetId,
            TargetType = entity.TargetType,
            Reason = entity.Reason,
            Status = entity.Status,
        };
    }

    public async Task<(IReadOnlyList<AdminContentReportDto> Items, PaginationMetadata Pagination)> ListAdminAsync(
        string? status,
        int page,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        pageSize = Math.Clamp(pageSize, 1, 100);
        var skip = (page - 1) * pageSize;

        var (items, total) = await _reports.ListAsync(status, skip, pageSize, cancellationToken);
        var dtos = items.Select(ToAdminDto).ToList();
        var pagination = new PaginationMetadata
        {
            PageNumber = page,
            PageSize = pageSize,
            TotalRecords = total,
        };

        return (dtos, pagination);
    }

    public async Task<AdminContentReportDto> ResolveAsync(
        Guid id,
        string status,
        bool? hidePost = null,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(status) || !AllowedResolveStatuses.Contains(status.Trim()))
            throw new ArgumentException("Status must be one of: Dismissed, Actioned, Reviewed.");

        var normalized = NormalizeStatus(status.Trim());
        var report = await _reports.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException($"Content report {id} was not found.");

        await _reports.UpdateStatusAsync(id, normalized, cancellationToken);
        report.Status = normalized;
        report.UpdatedAt = DateTimeOffset.UtcNow;

        var shouldHide = hidePost ?? string.Equals(normalized, "Actioned", StringComparison.OrdinalIgnoreCase);
        if (shouldHide
            && string.Equals(report.TargetType, "Post", StringComparison.OrdinalIgnoreCase))
        {
            var post = await _posts.GetByIdAsync(report.TargetId, cancellationToken);
            if (post is not null && post.IsPublic)
            {
                post.IsPublic = false;
                post.UpdatedAt = DateTimeOffset.UtcNow;
                await _posts.UpdateAsync(post.Id, post, cancellationToken);
            }
        }

        return ToAdminDto(report);
    }

    private static string NormalizeStatus(string status) => status switch
    {
        _ when status.Equals("Dismissed", StringComparison.OrdinalIgnoreCase) => "Dismissed",
        _ when status.Equals("Actioned", StringComparison.OrdinalIgnoreCase) => "Actioned",
        _ when status.Equals("Reviewed", StringComparison.OrdinalIgnoreCase) => "Reviewed",
        _ => status,
    };

    private static AdminContentReportDto ToAdminDto(ContentReport entity) => new()
    {
        Id = entity.Id,
        ReporterId = entity.ReporterId,
        TargetId = entity.TargetId,
        TargetType = entity.TargetType,
        Reason = entity.Reason,
        Details = entity.Details,
        Status = entity.Status,
        CreatedAt = entity.CreatedAt,
    };
}
