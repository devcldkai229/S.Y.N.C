namespace Libs.Storage.Services;

/// <summary>
/// Resolves stored media references (S3 keys, gateway paths) to client-display URLs.
/// Public buckets return stable HTTPS URLs; private buckets return short-lived presigned URLs.
/// </summary>
public interface IMediaUrlResolver
{
    /// <summary>Returns a URL suitable for &lt;img src&gt; / Image.network.</summary>
    string? ResolveForDisplay(string? storedValue);

    /// <summary>Extracts an S3 object key (or external/randomavatar value) for DB storage.</summary>
    string? NormalizeForStorage(string? urlOrKey);

    /// <summary>URL returned immediately after upload (presigned for private buckets).</summary>
    string ResolveAfterUpload(string objectKey);
}
