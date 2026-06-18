namespace Social.Application.DTOs;

public sealed record ShareCodeBackfillResult(
    int Updated,
    int Remaining,
    string Message);
