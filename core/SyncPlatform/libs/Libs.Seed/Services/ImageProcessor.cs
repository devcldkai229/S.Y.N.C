using SixLabors.Fonts;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Drawing.Processing;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;

namespace Libs.Seed.Services;

public static class ImageProcessor
{
    public static async Task<byte[]> ToWebpAsync(
        byte[] raw,
        string orientation,
        int? maxWidth = null,
        int? maxHeight = null,
        CancellationToken cancellationToken = default)
    {
        await using var input = new MemoryStream(raw);
        using var image = await Image.LoadAsync(input, cancellationToken);

        var (width, height) = orientation.ToLowerInvariant() switch
        {
            "square" => (maxWidth ?? 512, maxHeight ?? 512),
            "portrait" => (maxWidth ?? 600, maxHeight ?? 800),
            _ => (maxWidth ?? 1200, maxHeight ?? 800),
        };

        image.Mutate(x => x.Resize(new ResizeOptions
        {
            Mode = ResizeMode.Max,
            Size = new Size(width, height),
        }));

        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 82 }, cancellationToken);
        return output.ToArray();
    }

    public static async Task<byte[]> GeneratePlaceholderWebpAsync(
        string orientation,
        CancellationToken cancellationToken = default)
    {
        var size = orientation.Equals("landscape", StringComparison.OrdinalIgnoreCase)
            ? new Size(800, 500)
            : new Size(400, 400);

        using var image = new Image<Rgba32>(size.Width, size.Height, new Rgba32(236, 240, 241, 255));
        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 75 }, cancellationToken);
        return output.ToArray();
    }

    public static async Task<byte[]> GenerateAvatarWebpAsync(
        Guid userId,
        string fullName,
        CancellationToken cancellationToken = default)
    {
        const int size = 256;
        var bg = ColorFromUserId(userId);
        var bgPixel = bg.ToPixel<Rgba32>();
        var fg = PerceivedLuminance(bgPixel) > 0.55
            ? Color.ParseHex("#1a1a2e")
            : Color.ParseHex("#ffffff");
        var initials = ExtractInitials(fullName);

        using var image = new Image<Rgba32>(size, size, bg);
        image.Mutate(ctx =>
        {
            var font = SystemFonts.CreateFont("Arial", 96, FontStyle.Bold);
            var textOptions = new RichTextOptions(font)
            {
                Origin = new PointF(size / 2f, size / 2f),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };
            ctx.DrawText(textOptions, initials, fg);
        });

        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 85 }, cancellationToken);
        return output.ToArray();
    }

    public static async Task<byte[]> GenerateMedalWebpAsync(
        string label,
        CancellationToken cancellationToken = default)
    {
        const int size = 256;
        using var image = new Image<Rgba32>(size, size, Color.ParseHex("#f4c430"));
        image.Mutate(ctx =>
        {
            var font = SystemFonts.CreateFont("Arial", 48, FontStyle.Bold);
            var textOptions = new RichTextOptions(font)
            {
                Origin = new PointF(size / 2f, size / 2f),
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center,
            };
            ctx.DrawText(textOptions, label.Length > 2 ? label[..2] : label, Color.ParseHex("#5c3d00"));
        });

        await using var output = new MemoryStream();
        await image.SaveAsync(output, new WebpEncoder { Quality = 85 }, cancellationToken);
        return output.ToArray();
    }

    private static string ExtractInitials(string fullName)
    {
        var parts = fullName.Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length == 0)
            return "?";

        if (parts.Length == 1)
            return parts[0][..1].ToUpperInvariant();

        return $"{char.ToUpperInvariant(parts[0][0])}{char.ToUpperInvariant(parts[^1][0])}";
    }

    private static Color ColorFromUserId(Guid userId)
    {
        var bytes = userId.ToByteArray();
        return Color.FromRgb(bytes[0], bytes[1], bytes[2]);
    }

    private static double PerceivedLuminance(Rgba32 color)
        => (0.299 * color.R + 0.587 * color.G + 0.114 * color.B) / 255.0;
}
