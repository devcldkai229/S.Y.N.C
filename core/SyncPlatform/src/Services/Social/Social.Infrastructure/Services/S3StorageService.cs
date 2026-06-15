using Libs.Storage.Services;
using Social.Application.Services;

namespace Social.Infrastructure.Services;

public class S3StorageService : IStorageService
{
    private readonly S3ObjectStorage _storage;

    public S3StorageService(S3ObjectStorage storage)
    {
        _storage = storage;
    }

    public async Task<string> UploadFileAsync(
        Stream fileStream,
        long? objectSize,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(fileStream);
        if (string.IsNullOrWhiteSpace(fileName))
            throw new ArgumentException("File name is required.", nameof(fileName));

        var size = objectSize ??
                     (fileStream.CanSeek
                         ? fileStream.Length
                         : throw new InvalidOperationException(
                             "Stream length is required for S3 upload but the provided stream is not seekable."));

        return await _storage.UploadAsync(fileStream, size, fileName, contentType, cancellationToken);
    }
}
