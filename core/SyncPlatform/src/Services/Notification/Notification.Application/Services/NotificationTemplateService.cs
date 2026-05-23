using Notification.Application.DTOs;
using Notification.Application.Exceptions;
using Notification.Application.Mappers;
using Notification.Domain.Models;
using Notification.Domain.Repositories;

namespace Notification.Application.Services;

public class NotificationTemplateService : INotificationTemplateService
{
    private readonly INotificationTemplateRepository _repository;

    public NotificationTemplateService(INotificationTemplateRepository repository)
    {
        _repository = repository;
    }

    public async Task<IReadOnlyList<NotificationTemplateDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var entities = await _repository.GetAllAsync(cancellationToken);
        return entities.Select(e => e.ToDto()).ToList();
    }

    public async Task<NotificationTemplateDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
        {
            throw new NotFoundException(nameof(NotificationTemplate), id);
        }
        return entity.ToDto();
    }

    public async Task<NotificationTemplateDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByCodeAsync(code, cancellationToken);
        if (entity == null)
        {
            throw new NotFoundException(nameof(NotificationTemplate), code);
        }
        return entity.ToDto();
    }

    public async Task<NotificationTemplateDto> CreateAsync(CreateNotificationTemplateDto dto, CancellationToken cancellationToken = default)
    {
        var existing = await _repository.GetByCodeAsync(dto.TemplateCode, cancellationToken);
        if (existing != null)
        {
            throw new ConflictException($"Notification template code '{dto.TemplateCode}' already exists.");
        }

        var entity = new NotificationTemplate();
        entity.UpdateEntity(dto);

        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task UpdateAsync(Guid id, UpdateNotificationTemplateDto dto, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
        {
            throw new NotFoundException(nameof(NotificationTemplate), id);
        }

        entity.UpdateEntity(dto);
        await _repository.UpdateAsync(id, entity, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var exists = await _repository.ExistsAsync(id, cancellationToken);
        if (!exists)
        {
            throw new NotFoundException(nameof(NotificationTemplate), id);
        }

        await _repository.DeleteAsync(id, cancellationToken);
    }

    public async Task ToggleStatusAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken);
        if (entity == null)
        {
            throw new NotFoundException(nameof(NotificationTemplate), id);
        }

        entity.IsActive = !entity.IsActive;
        await _repository.UpdateAsync(id, entity, cancellationToken);
    }
}
