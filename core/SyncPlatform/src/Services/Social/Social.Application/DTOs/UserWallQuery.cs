namespace Social.Application.DTOs;

public class UserWallQuery
{
    /// <summary>Opaque compound cursor (or legacy ISO-8601).</summary>
    public string? Cursor { get; set; }
    public int Limit { get; set; } = 20;
    public bool OnlyMedia { get; set; }
}
