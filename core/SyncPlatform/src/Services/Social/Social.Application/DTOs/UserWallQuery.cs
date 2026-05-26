namespace Social.Application.DTOs;

public class UserWallQuery
{
    public DateTimeOffset? Cursor { get; set; }
    public int Limit { get; set; } = 20;
    public bool OnlyMedia { get; set; }
}
