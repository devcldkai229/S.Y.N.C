namespace Iam.Domain.Models;

/// <summary>
/// One row in JSONB allergies — meal agent filters ingredients against this list.
/// </summary>
public sealed record AllergyItem(
    string AllergenName,
    string? Severity,
    string? Notes);
