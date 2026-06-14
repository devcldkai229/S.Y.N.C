namespace Iam.Application.DTOs;

public class UserSearchRequest
{
    public string Query { get; set; } = string.Empty;

    public int PageNumber { get; set; } = 1;

    public int PageSize { get; set; } = 20;
}

public class UserSearchItemDto
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }
}
