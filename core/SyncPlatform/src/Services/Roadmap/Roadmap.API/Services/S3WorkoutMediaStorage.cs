using Libs.Storage.Services;

namespace Roadmap.API.Services;

public interface IWorkoutMediaStorage
{
    Task<string> UploadAsync(Stream stream, long size, string objectName, string contentType, CancellationToken cancellationToken);
}

public sealed class S3WorkoutMediaStorage : IWorkoutMediaStorage
{
    private readonly S3ObjectStorage _storage;

    public S3WorkoutMediaStorage(S3ObjectStorage storage)
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
