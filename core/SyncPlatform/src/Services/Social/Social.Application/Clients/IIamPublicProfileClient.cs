namespace Social.Application.Clients;

public interface IIamPublicProfileClient
{
    Task<IamPublicProfile?> GetAsync(Guid userId, CancellationToken cancellationToken = default);
}

public sealed class IamPublicProfile
{
    public Guid UserId { get; init; }
    public string FullName { get; init; } = string.Empty;
    public string? AvatarUrl { get; init; }
}
