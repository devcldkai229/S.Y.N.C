using Libs.Shared.Enums;

namespace Roadmap.Domain.Models;

public class ScheduledWorkout : BaseMongoEntity
{
    public Guid UserId { get; set; }

    public Guid SessionId { get; set; }

    public DateTimeOffset ScheduledStartTime { get; set; }

    public DateTimeOffset ScheduledEndTime { get; set; }

    public string RepeatPattern { get; set; } = string.Empty;

    public SessionStatus Status { get; set; }
}
