namespace Social.Application.DTOs;

public sealed class CreateContentReportDto
{
    public Guid TargetId { get; set; }
    public string TargetType { get; set; } = "Post";
    public string Reason { get; set; } = string.Empty;
    public string? Details { get; set; }
}

public sealed class ContentReportDto
{
    public Guid Id { get; set; }
    public Guid TargetId { get; set; }
    public string TargetType { get; set; } = "Post";
    public string Reason { get; set; } = string.Empty;
    public string Status { get; set; } = "Pending";
}

public sealed class AdminContentReportDto
{
    public Guid Id { get; set; }
    public Guid ReporterId { get; set; }
    public Guid TargetId { get; set; }
    public string TargetType { get; set; } = "Post";
    public string Reason { get; set; } = string.Empty;
    public string? Details { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class ResolveContentReportDto
{
    /// <summary>Dismissed | Actioned | Reviewed</summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>When Actioned on a Post, defaults to hiding the post unless explicitly false.</summary>
    public bool? HidePost { get; set; }
}
