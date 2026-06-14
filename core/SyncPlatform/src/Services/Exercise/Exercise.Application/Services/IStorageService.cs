namespace Exercise.Application.Services;

public interface IStorageService
{
    /// <summary>Uploads to S3 and returns the object key.</summary>
    Task<string> UploadFileAsync(
        Stream fileStream,
        string objectKey,
        string contentType,
        CancellationToken cancellationToken = default);

    Task DeleteFileByKeyAsync(string objectKey, CancellationToken cancellationToken = default);

    /// <summary>Resolves a public URL or presigned GET URL for an object key.</summary>
    string ResolveObjectUrl(string objectKey);

    /// <summary>Opens an object stream for proxy download.</summary>
    Task<(Stream Stream, string ContentType)?> TryOpenObjectAsync(
        string objectKey,
        CancellationToken cancellationToken = default);

    /// <summary>Legacy: delete by stored URL or key.</summary>
    Task DeleteFileAsync(string fileUrlOrKey, CancellationToken cancellationToken = default);
}
