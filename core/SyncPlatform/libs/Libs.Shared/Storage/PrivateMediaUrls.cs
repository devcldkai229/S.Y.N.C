namespace Libs.Shared.Storage;

/// <summary>Builds stable gateway URLs for objects in <see cref="StorageBuckets.PrivateAssets"/> (IAM, Roadmap).</summary>
public static class PrivateMediaUrls
{
    public static string Object(string publicBaseUrl, string objectKey) =>
        $"{publicBaseUrl.TrimEnd('/')}/{StorageBuckets.PrivateAssets}/{objectKey.TrimStart('/')}";
}
