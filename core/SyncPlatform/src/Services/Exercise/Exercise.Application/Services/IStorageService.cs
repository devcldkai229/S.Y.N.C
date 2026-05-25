using System.IO;
using System.Threading;
using System.Threading.Tasks;

namespace Exercise.Application.Services;

public interface IStorageService
{
    /// <summary>
    /// Uploads a file stream to object storage and returns the public URL.
    /// </summary>
    Task<string> UploadFileAsync(Stream fileStream, string fileName, string contentType, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a file from object storage given its public URL or path.
    /// </summary>
    Task DeleteFileAsync(string fileUrl, CancellationToken cancellationToken = default);
}
