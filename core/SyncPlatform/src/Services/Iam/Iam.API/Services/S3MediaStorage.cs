using Libs.Storage.Services;

namespace Iam.API.Services;

public interface IMediaStorage
{
    Task<string> UploadAsync(Stream stream, long size, string objectName, string contentType, CancellationToken cancellationToken);
}

public sealed class S3MediaStorage : IMediaStorage
{
    private readonly S3ObjectStorage _storage;

    public S3MediaStorage(S3ObjectStorage storage)
    {
        _storage = storage;
    }

    public Task<string> UploadAsync(
        Stream stream,
        long size,
        string objectName,
        string contentType,
        CancellationToken cancellationToken) =>
        _storage.UploadAsync(stream, size, objectName, contentType, cancellationToken);
}
