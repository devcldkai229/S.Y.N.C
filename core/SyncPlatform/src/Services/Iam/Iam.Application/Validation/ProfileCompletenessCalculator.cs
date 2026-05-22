using Iam.Domain.Models;

namespace Iam.Application.Validation;

internal static class ProfileCompletenessCalculator
{
    public static (int Percent, List<string> MissingHints) Calculate(User user)
    {
        var checks = new List<(bool Done, string Hint)>
        {
            (!string.IsNullOrWhiteSpace(user.FullName), "Add your full name."),
            (!string.IsNullOrWhiteSpace(user.AvatarUrl), "Upload a profile avatar."),
            (!string.IsNullOrWhiteSpace(user.PreferredLanguage), "Set your preferred language."),
            (!string.IsNullOrWhiteSpace(user.TimeZone), "Set your time zone.")
        };

        if (user.BiometricProfile is { } bio)
        {
            checks.Add((bio.HeightCm > 0, "Enter your height."));
            checks.Add((bio.CurrentWeightKg > 0, "Enter your current weight."));
            checks.Add((bio.TargetWeightKg > 0, "Set your target weight."));
            checks.Add((bio.DateOfBirth != default, "Add your date of birth."));
            checks.Add((bio.Injuries is { Count: > 0 } || bio.Medications is { Count: > 0 }, "Declare injuries or medications (or confirm none in settings)."));
        }
        else
        {
            checks.Add((false, "Complete your fitness profile."));
        }

        if (user.UserPreference is not null)
        {
            checks.Add((true, string.Empty));
        }
        else
        {
            checks.Add((false, "Configure AI account preferences."));
        }

        var done = checks.Count(c => c.Done);
        var percent = checks.Count == 0 ? 0 : (int)Math.Round(done * 100.0 / checks.Count);
        var hints = checks.Where(c => !c.Done && !string.IsNullOrEmpty(c.Hint)).Select(c => c.Hint).Distinct().ToList();

        return (percent, hints);
    }
}
