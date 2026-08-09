using Social.Domain.Models;

namespace Social.Application.Services;

public interface IAccountAnonymizationService
{
    Task AnonymizeUserContentAsync(Guid userId, CancellationToken cancellationToken = default);
}
