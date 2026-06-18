using Marketplace.Domain.Enums;

namespace Marketplace.Application.DTOs;

public class ReviewDto
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public AuthorSnapshotDto AuthorSnapshot { get; set; } = new();

    public ReviewTargetType TargetType { get; set; }

    public Guid TargetId { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }

    public IReadOnlyList<string>? ImageUrls { get; set; }

    public Guid? OrderId { get; set; }

    public bool IsVerifiedPurchase { get; set; }

    public string? PartnerReply { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
}

public class CreateReviewDto
{
    public ReviewTargetType TargetType { get; set; }

    public Guid TargetId { get; set; }

    public int Rating { get; set; }

    public string? Comment { get; set; }

    public List<string>? ImageUrls { get; set; }

    public Guid? OrderId { get; set; }
}

public class PartnerReplyDto
{
    public string Reply { get; set; } = string.Empty;
}

public class ReviewListRequest
{
    public ReviewTargetType TargetType { get; set; }

    public Guid TargetId { get; set; }

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}
