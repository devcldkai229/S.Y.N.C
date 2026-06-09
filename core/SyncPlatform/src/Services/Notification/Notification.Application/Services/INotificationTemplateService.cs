using Notification.Application.DTOs;

namespace Notification.Application.Services;

public interface INotificationTemplateService
{
    Task<IReadOnlyList<NotificationTemplateDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<NotificationTemplateDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<NotificationTemplateDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<NotificationTemplateDto> CreateAsync(CreateNotificationTemplateDto dto, CancellationToken cancellationToken = default);
    Task UpdateAsync(Guid id, UpdateNotificationTemplateDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    Task ToggleStatusAsync(Guid id, CancellationToken cancellationToken = default);
}
