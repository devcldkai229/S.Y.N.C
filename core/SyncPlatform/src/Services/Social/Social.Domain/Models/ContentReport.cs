namespace Social.Domain.Models;

public class ContentReport : BaseMongoEntity
{
    public Guid ReporterId { get; set; }

    public Guid TargetId { get; set; }

    /// <summary>Post | User | Comment | AiContent</summary>
    public string TargetType { get; set; } = "Post";

    public string Reason { get; set; } = string.Empty;

    public string? Details { get; set; }

    /// <summary>Pending | Reviewed | Actioned | Dismissed</summary>
    public string Status { get; set; } = "Pending";
}
