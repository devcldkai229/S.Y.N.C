using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace Social.Application.Services;

public interface IStorageService
{
    /// <summary>
    /// Uploads a file stream to object storage and returns the public URL.
    /// </summary>
    Task<string> UploadFileAsync(
        Stream fileStream,
        long? objectSize,
        string fileName,
        string contentType,
        CancellationToken cancellationToken = default);
}

