namespace Iam.Application.DTOs;

public sealed record GrantXpRequest(
    Guid UserId,
    int Xp,
    int Coins,
    string? EventName = null);
