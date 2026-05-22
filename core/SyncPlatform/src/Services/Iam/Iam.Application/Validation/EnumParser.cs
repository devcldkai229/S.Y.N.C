namespace Iam.Application.Validation;

internal static class EnumParser
{
    public static bool TryParseEnum<TEnum>(string? value, out TEnum result, out string error)
        where TEnum : struct, Enum
    {
        result = default;
        error = string.Empty;

        if (string.IsNullOrWhiteSpace(value))
        {
            error = $"Value is required for {typeof(TEnum).Name}.";
            return false;
        }

        if (Enum.TryParse<TEnum>(value, ignoreCase: true, out result))
            return true;

        error = $"'{value}' is not a valid {typeof(TEnum).Name}.";
        return false;
    }
}
