using Iam.Application.Common;
using Iam.Application.DTOs;
using Iam.Domain.Enums;

namespace Iam.Application.Validation;

internal static class ProfileValidators
{
    public static void ValidateBasicUpdate(UpdateBasicProfileRequest request)
    {
        var errors = new Dictionary<string, string[]>();

        if (request.FullName is { Length: > 256 })
            errors[nameof(request.FullName)] = ["Full name must be at most 256 characters."];

        if (request.AvatarUrl is { Length: > 1024 })
            errors[nameof(request.AvatarUrl)] = ["Avatar URL must be at most 1024 characters."];

        if (request.BackgroundImageUrl is { Length: > 1024 })
            errors[nameof(request.BackgroundImageUrl)] = ["Background image URL must be at most 1024 characters."];

        if (request.PreferredLanguage is { Length: > 8 })
            errors[nameof(request.PreferredLanguage)] = ["Preferred language must be at most 8 characters."];

        if (request.TimeZone is { Length: > 64 })
            errors[nameof(request.TimeZone)] = ["Time zone must be at most 64 characters."];

        if (errors.Count > 0)
            throw new AppValidationException(errors);
    }

    public static void ValidateFitnessUpdate(UpdateFitnessProfileRequest request, bool isCreate)
    {
        var errors = new Dictionary<string, string[]>();

        if (isCreate)
        {
            RequireEnum<Gender>(request.Gender, nameof(request.Gender), errors);
            RequireValue(request.DateOfBirth, nameof(request.DateOfBirth), errors);
            RequirePositive(request.HeightCm, nameof(request.HeightCm), errors);
            RequirePositive(request.CurrentWeightKg, nameof(request.CurrentWeightKg), errors);
            RequirePositive(request.TargetWeightKg, nameof(request.TargetWeightKg), errors);
            RequireEnum<FitnessGoal>(request.FitnessGoal, nameof(request.FitnessGoal), errors);
            RequireEnum<ActivityLevel>(request.ActivityLevel, nameof(request.ActivityLevel), errors);
            RequireEnum<FitnessExperienceLevel>(request.FitnessExperienceLevel, nameof(request.FitnessExperienceLevel), errors);
            RequireEnum<WorkoutLocationPreference>(request.WorkoutLocationPreference, nameof(request.WorkoutLocationPreference), errors);
        }
        else
        {
            if (request.Gender is not null && !EnumParser.TryParseEnum<Gender>(request.Gender, out _, out var genderError))
                errors[nameof(request.Gender)] = [genderError];

            if (request.FitnessGoal is not null && !EnumParser.TryParseEnum<FitnessGoal>(request.FitnessGoal, out _, out var goalError))
                errors[nameof(request.FitnessGoal)] = [goalError];

            if (request.ActivityLevel is not null && !EnumParser.TryParseEnum<ActivityLevel>(request.ActivityLevel, out _, out var activityError))
                errors[nameof(request.ActivityLevel)] = [activityError];

            if (request.FitnessExperienceLevel is not null && !EnumParser.TryParseEnum<FitnessExperienceLevel>(request.FitnessExperienceLevel, out _, out var levelError))
                errors[nameof(request.FitnessExperienceLevel)] = [levelError];

            if (request.WorkoutLocationPreference is not null && !EnumParser.TryParseEnum<WorkoutLocationPreference>(request.WorkoutLocationPreference, out _, out var locationError))
                errors[nameof(request.WorkoutLocationPreference)] = [locationError];
        }

        if (request.DateOfBirth is { } dob && dob > DateOnly.FromDateTime(DateTime.UtcNow))
            errors[nameof(request.DateOfBirth)] = ["Date of birth cannot be in the future."];

        if (request.HeightCm is <= 0)
            errors[nameof(request.HeightCm)] = ["Height must be greater than zero."];

        if (request.CurrentWeightKg is <= 0)
            errors[nameof(request.CurrentWeightKg)] = ["Current weight must be greater than zero."];

        if (request.TargetWeightKg is <= 0)
            errors[nameof(request.TargetWeightKg)] = ["Target weight must be greater than zero."];

        if (request.CurrentBodyFatPercentage is < 0 or > 100)
            errors[nameof(request.CurrentBodyFatPercentage)] = ["Body fat percentage must be between 0 and 100."];

        if (request.GoalBodyFatPercentage is < 0 or > 100)
            errors[nameof(request.GoalBodyFatPercentage)] = ["Goal body fat percentage must be between 0 and 100."];

        if (errors.Count > 0)
            throw new AppValidationException(errors);
    }

    public static void ValidateAccountPreferencesUpdate(UpdateAccountPreferencesRequest request)
    {
        var errors = new Dictionary<string, string[]>();

        if (request.AgentPersona is not null && !EnumParser.TryParseEnum<AgentPersona>(request.AgentPersona, out _, out var personaError))
            errors[nameof(request.AgentPersona)] = [personaError];

        if (request.MotivationStyle is not null && !EnumParser.TryParseEnum<MotivationStyle>(request.MotivationStyle, out _, out var styleError))
            errors[nameof(request.MotivationStyle)] = [styleError];

        if (request.Allergies is not null)
        {
            foreach (var allergy in request.Allergies)
            {
                if (string.IsNullOrWhiteSpace(allergy.AllergenName))
                {
                    errors[nameof(request.Allergies)] = ["Allergen name cannot be empty."];
                    break;
                }
            }
        }

        if (request.MaxAutoOrderLimitDaily is <= 0)
            errors[nameof(request.MaxAutoOrderLimitDaily)] = ["Daily auto-order limit must be greater than zero."];

        if (request.MaxAutoOrderLimitPerOrder is <= 0)
            errors[nameof(request.MaxAutoOrderLimitPerOrder)] = ["Per-order auto-order limit must be greater than zero."];

        if (request.MaxAutoOrderLimitDaily is > 0
            && request.MaxAutoOrderLimitPerOrder is > 0
            && request.MaxAutoOrderLimitPerOrder > request.MaxAutoOrderLimitDaily)
        {
            errors[nameof(request.MaxAutoOrderLimitPerOrder)] = ["Per-order limit cannot exceed the daily limit."];
        }

        if (errors.Count > 0)
            throw new AppValidationException(errors);
    }

    private static void RequireEnum<TEnum>(string? value, string fieldName, IDictionary<string, string[]> errors)
        where TEnum : struct, Enum
    {
        if (!EnumParser.TryParseEnum<TEnum>(value, out _, out var error))
            errors[fieldName] = [error];
    }

    private static void RequireValue<T>(T? value, string fieldName, IDictionary<string, string[]> errors)
    {
        if (value is null)
            errors[fieldName] = ["This field is required when creating a fitness profile."];
    }

    private static void RequirePositive(decimal? value, string fieldName, IDictionary<string, string[]> errors)
    {
        if (value is null or <= 0)
            errors[fieldName] = ["This field must be greater than zero when creating a fitness profile."];
    }
}
