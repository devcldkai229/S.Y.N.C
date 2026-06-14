namespace Marketplace.SeedTool.Services;

public interface IStorageService
{
    Task<bool> ObjectExistsAsync(string objectKey, CancellationToken cancellationToken = default);

    Task<string> UploadFileAsync(
        Stream fileStream,
        string objectKey,
        string contentType,
        CancellationToken cancellationToken = default);

    string ResolveObjectUrl(string objectKey);
}
