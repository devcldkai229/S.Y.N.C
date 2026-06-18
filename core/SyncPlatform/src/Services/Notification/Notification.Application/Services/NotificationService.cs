using Notification.Application.Common;
using Notification.Application.DTOs;
using Notification.Application.Exceptions;
using Notification.Application.Mappers;
using Notification.Domain.Enums;
using Notification.Domain.Models;
using Notification.Domain.Repositories;

namespace Notification.Application.Services;

public class NotificationService : INotificationService
{
    private readonly INotificationMessageRepository _messageRepository;
    private readonly INotificationTemplateRepository _templateRepository;
    private readonly INotificationRealtimePublisher _realtimePublisher;

    public NotificationService(
        INotificationMessageRepository messageRepository,
        INotificationTemplateRepository templateRepository,
        INotificationRealtimePublisher realtimePublisher)
    {
        _messageRepository = messageRepository;
        _templateRepository = templateRepository;
        _realtimePublisher = realtimePublisher;
    }

    public async Task<(IReadOnlyList<NotificationMessageDto> Items, PaginationMetadata Pagination)> GetPagedByUserIdAsync(
        Guid userId,
        NotificationSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, request.PageNumber);
        var pageSize = Math.Clamp(request.PageSize, 1, 100);

        var (entities, totalRecords) = await _messageRepository.GetPagedByUserIdAsync(
            userId,
            pageNumber,
            pageSize,
            request.Status,
            cancellationToken);

        var dtos = entities.Select(e => e.ToDto()).ToList();
        var pagination = new PaginationMetadata(pageNumber, pageSize, totalRecords);

        return (dtos, pagination);
    }

    public async Task<int> GetUnreadCountByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _messageRepository.GetUnreadCountByUserIdAsync(userId, cancellationToken);
    }

    public async Task MarkAsReadAsync(
    Guid userId,
    Guid messageId,
    CancellationToken cancellationToken = default)
    {
        var message = await _messageRepository.GetByIdAsync(messageId, cancellationToken);

        if (message == null || message.UserId != userId)
        {
            throw new NotFoundException(nameof(NotificationMessage), messageId);
        }

        if (message.Status == NotificationStatus.Read)
        {
            return;
        }

        if (message.Status != NotificationStatus.Sent &&
            message.Status != NotificationStatus.Delivered)
        {
            throw new BadRequestException(
                $"Notification message with status '{message.Status}' cannot be marked as read.");
        }

        var now = DateTimeOffset.UtcNow;

        message.Status = NotificationStatus.Read;
        message.ReadAt = now;
        message.UpdatedAt = now;

        await _messageRepository.UpdateAsync(messageId, message, cancellationToken);
    }

    public async Task MarkAllAsReadAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        await _messageRepository.MarkAllAsReadByUserIdAsync(userId, cancellationToken);
    }

    public async Task DeleteNotificationAsync(Guid userId, Guid messageId, CancellationToken cancellationToken = default)
    {
        var message = await _messageRepository.GetByIdAsync(messageId, cancellationToken);
        if (message == null || message.UserId != userId)
        {
            throw new NotFoundException(nameof(NotificationMessage), messageId);
        }

        await _messageRepository.DeleteAsync(messageId, cancellationToken);
    }

    public async Task<NotificationMessageDto> SendNotificationAsync(SendNotificationDto dto, CancellationToken cancellationToken = default)
    {
        var isScheduled = dto.ScheduledFor.HasValue && dto.ScheduledFor.Value > DateTimeOffset.UtcNow;

        var message = new NotificationMessage
        {
            UserId = dto.UserId,
            Type = dto.Type,
            Channel = dto.Channel,
            Priority = dto.Priority,
            Title = dto.Title,
            Body = dto.Body,
            ImageUrl = dto.ImageUrl,
            DeepLink = dto.DeepLink,
            DataPayloadJson = dto.DataPayloadJson,
            AiContextSnapshotJson = dto.AiContextSnapshotJson,
            ScheduledFor = dto.ScheduledFor,
            Status = isScheduled ? NotificationStatus.Pending : NotificationStatus.Sent,
            SentAt = isScheduled ? null : DateTimeOffset.UtcNow
        };

        await _messageRepository.CreateAsync(message, cancellationToken);
        var created = message.ToDto();
        if (!isScheduled)
            await _realtimePublisher.PublishToUserAsync(created.UserId, created, cancellationToken);

        return created;
    }

    public async Task<NotificationMessageDto> SendTemplatedNotificationAsync(SendTemplatedNotificationDto dto, CancellationToken cancellationToken = default)
    {
        var template = await _templateRepository.GetByCodeAsync(dto.TemplateCode, cancellationToken);
        if (template == null)
        {
            throw new NotFoundException($"NotificationTemplate with code '{dto.TemplateCode}' was not found.");
        }

        if (!template.IsActive)
        {
            throw new BadRequestException($"NotificationTemplate with code '{dto.TemplateCode}' is inactive.");
        }

        // Format body and title using template variables
        var title = FormatTemplateString(template.DefaultTitle, dto.Variables);
        var body = FormatTemplateString(template.DefaultBody, dto.Variables);

        var isScheduled = dto.ScheduledFor.HasValue && dto.ScheduledFor.Value > DateTimeOffset.UtcNow;

        // Auto determine NotificationType from template code or context. For templates, we can map to a default type
        var notificationType = DetermineNotificationType(dto.TemplateCode);

        var message = new NotificationMessage
        {
            UserId = dto.UserId,
            Type = notificationType,
            Channel = template.Channel,
            Priority = dto.Priority,
            Title = title,
            Body = body,
            DeepLink = dto.DeepLink,
            AiContextSnapshotJson = dto.AiContextSnapshotJson,
            ScheduledFor = dto.ScheduledFor,
            Status = isScheduled ? NotificationStatus.Pending : NotificationStatus.Sent,
            SentAt = isScheduled ? null : DateTimeOffset.UtcNow
        };

        await _messageRepository.CreateAsync(message, cancellationToken);
        var created = message.ToDto();
        if (!isScheduled)
            await _realtimePublisher.PublishToUserAsync(created.UserId, created, cancellationToken);

        return created;
    }

    public async Task CancelScheduledNotificationAsync(
    Guid messageId,
    CancellationToken cancellationToken = default)
    {
        var message = await _messageRepository.GetByIdAsync(messageId, cancellationToken);

        if (message == null)
        {
            throw new NotFoundException(nameof(NotificationMessage), messageId);
        }

        if (message.Status != NotificationStatus.Pending)
        {
            throw new BadRequestException(
                $"Notification message with status '{message.Status}' cannot be cancelled.");
        }

        var now = DateTimeOffset.UtcNow;

        message.Status = NotificationStatus.Cancelled;
        message.UpdatedAt = now;

        await _messageRepository.UpdateAsync(messageId, message, cancellationToken);
    }

    private string FormatTemplateString(string template, Dictionary<string, string> variables)
    {
        if (string.IsNullOrEmpty(template)) return string.Empty;
        var result = template;
        foreach (var (key, value) in variables)
        {
            result = result.Replace($"{{{key}}}", value);
        }
        return result;
    }

    private NotificationType DetermineNotificationType(string templateCode)
    {
        var codeUpper = templateCode.ToUpperInvariant();
        if (codeUpper.Contains("REMINDER")) return NotificationType.WorkoutReminder;
        if (codeUpper.Contains("MEAL") || codeUpper.Contains("ORDER")) return NotificationType.MealAutoOrder;
        if (codeUpper.Contains("INTERVENTION") || codeUpper.Contains("AI")) return NotificationType.AiIntervention;
        if (codeUpper.Contains("MOTIVATIONAL")) return NotificationType.Motivational;
        if (codeUpper.Contains("ALERT") || codeUpper.Contains("SYSTEM")) return NotificationType.SystemAlert;
        if (codeUpper.Contains("REWARD") || codeUpper.Contains("MINT")) return NotificationType.RewardMinted;
        return NotificationType.Promotion;
    }
}
