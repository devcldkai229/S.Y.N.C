namespace Iam.Application.Dtos;

public sealed record AllergyItemDto(
    string AllergenName,
    string? Severity,
    string? Notes);
