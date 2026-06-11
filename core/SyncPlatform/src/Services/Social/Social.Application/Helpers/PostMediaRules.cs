using Social.Application.Configuration;
using Social.Application.Exceptions;

namespace Social.Application.Helpers;

public static class PostMediaRules
{
    public const int MaxImages = 5;
    public const int MaxVideos = 1;

    public static bool IsImageContentType(string? contentType) =>
        !string.IsNullOrWhiteSpace(contentType) &&
        contentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase);

    public static bool IsVideoContentType(string? contentType) =>
        !string.IsNullOrWhiteSpace(contentType) &&
        contentType.StartsWith("video/", StringComparison.OrdinalIgnoreCase);

    public static bool IsImageUrl(string url)
    {
        var ext = Path.GetExtension(url).ToLowerInvariant();
        return ext is ".jpg" or ".jpeg" or ".png" or ".gif" or ".webp";
    }

    public static bool IsVideoUrl(string url)
    {
        var ext = Path.GetExtension(url).ToLowerInvariant();
        return ext is ".mp4" or ".webm" or ".mov" or ".quicktime";
    }

    public static (int ImageCount, int VideoCount) CountByContentTypes(IEnumerable<string?> contentTypes)
    {
        var images = 0;
        var videos = 0;
        foreach (var ct in contentTypes)
        {
            if (IsImageContentType(ct)) images++;
            else if (IsVideoContentType(ct)) videos++;
        }
        return (images, videos);
    }

    public static (int ImageCount, int VideoCount) CountByUrls(IEnumerable<string> urls)
    {
        var images = 0;
        var videos = 0;
        foreach (var url in urls)
        {
            if (IsImageUrl(url)) images++;
            else if (IsVideoUrl(url)) videos++;
        }
        return (images, videos);
    }

    public static void ValidateCounts(int imageCount, int videoCount)
    {
        if (imageCount > MaxImages)
            throw new BadRequestException($"A post can have at most {MaxImages} images.");

        if (videoCount > MaxVideos)
            throw new BadRequestException($"A post can have at most {MaxVideos} video.");

        if (imageCount + videoCount == 0)
            throw new BadRequestException("At least one image or video is required when media is provided.");
    }

    public static void ValidateContentTypeAllowed(string? contentType, MinioOptions options)
    {
        if (string.IsNullOrWhiteSpace(contentType))
            return;

        if (IsImageContentType(contentType) &&
            options.AllowedImageContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase))
            return;

        if (IsVideoContentType(contentType) &&
            options.AllowedVideoContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase))
            return;

        throw new BadRequestException($"Content type '{contentType}' is not allowed.");
    }
}
