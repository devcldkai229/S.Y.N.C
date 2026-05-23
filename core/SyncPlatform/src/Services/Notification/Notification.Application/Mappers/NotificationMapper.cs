using Notification.Domain.Models;
using Notification.Application.DTOs;

namespace Notification.Application.Mappers;

public static class NotificationMapper
{
    public static NotificationMessageDto ToDto(this NotificationMessage entity)
    {
        return new NotificationMessageDto
        {
            Id = entity.Id,
            UserId = entity.UserId,
            Type = entity.Type,
            Channel = entity.Channel,
            Priority = entity.Priority,
            Title = entity.Title,
            Body = entity.Body,
            ImageUrl = entity.ImageUrl,
            DeepLink = entity.DeepLink,
            DataPayloadJson = entity.DataPayloadJson,
            AiContextSnapshotJson = entity.AiContextSnapshotJson,
            ScheduledFor = entity.ScheduledFor,
            SentAt = entity.SentAt,
            DeliveredAt = entity.DeliveredAt,
            ReadAt = entity.ReadAt,
            Status = entity.Status,
            ErrorMessage = entity.ErrorMessage,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static NotificationTemplateDto ToDto(this NotificationTemplate entity)
    {
        return new NotificationTemplateDto
        {
            Id = entity.Id,
            TemplateCode = entity.TemplateCode,
            Name = entity.Name,
            DefaultTitle = entity.DefaultTitle,
            DefaultBody = entity.DefaultBody,
            VariablesJson = entity.VariablesJson,
            Channel = entity.Channel,
            IsActive = entity.IsActive,
            CreatedAt = entity.CreatedAt,
            UpdatedAt = entity.UpdatedAt
        };
    }

    public static void UpdateEntity(this NotificationTemplate entity, CreateNotificationTemplateDto dto)
    {
        entity.TemplateCode = dto.TemplateCode;
        entity.Name = dto.Name;
        entity.DefaultTitle = dto.DefaultTitle;
        entity.DefaultBody = dto.DefaultBody;
        entity.VariablesJson = dto.VariablesJson;
        entity.Channel = dto.Channel;
        entity.IsActive = dto.IsActive;
    }

    public static void UpdateEntity(this NotificationTemplate entity, UpdateNotificationTemplateDto dto)
    {
        entity.Name = dto.Name;
        entity.DefaultTitle = dto.DefaultTitle;
        entity.DefaultBody = dto.DefaultBody;
        entity.VariablesJson = dto.VariablesJson;
        entity.Channel = dto.Channel;
        entity.IsActive = dto.IsActive;
    }
}
