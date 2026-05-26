namespace Social.Application.DTOs;

public class CommentDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public Guid PostId { get; set; }
    public Guid UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public AuthorSnapshotDto? AuthorSnapshot { get; set; }
}

public class CreateCommentDto
{
    public string Content { get; set; } = string.Empty;

    public AuthorSnapshotDto? AuthorSnapshot { get; set; }
}

public class CommentListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
