namespace Social.Application.DTOs;

public class LikePostResultDto
{
    public Guid InteractionId { get; set; }
    public Guid PostId { get; set; }
    public int LikeCount { get; set; }
}
