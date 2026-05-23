using Notification.Domain.Enums;

namespace Notification.Application.DTOs;

public class CreateNotificationTemplateDto
{
    public string TemplateCode { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string DefaultTitle { get; set; } = string.Empty;
    public string DefaultBody { get; set; } = string.Empty;
    public string? VariablesJson { get; set; }
    public NotificationChannel Channel { get; set; }
    public bool IsActive { get; set; } = true;
}
