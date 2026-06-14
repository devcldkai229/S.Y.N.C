namespace Order.Infrastructure.Delivery;

internal static class AhamovePhone
{
    public static string Normalize(string? phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
            return string.Empty;

        var digits = new string(phone.Where(char.IsDigit).ToArray());
        if (digits.StartsWith("84", StringComparison.Ordinal))
            return digits;

        if (digits.StartsWith('0') && digits.Length >= 10)
            return "84" + digits[1..];

        return digits.Length >= 9 ? "84" + digits : digits;
    }

    public static string ToLocalDisplay(string normalized84)
    {
        if (normalized84.StartsWith("84", StringComparison.Ordinal) && normalized84.Length >= 11)
            return "0" + normalized84[2..];

        return normalized84;
    }
}
