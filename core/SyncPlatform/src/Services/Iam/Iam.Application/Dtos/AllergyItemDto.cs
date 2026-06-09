namespace Iam.Application.DTOs;

public sealed record AllergyItemDto(
    string AllergenName,
    string? Severity,
    string? Notes);
