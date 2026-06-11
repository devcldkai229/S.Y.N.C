using Social.Domain.Enums;

namespace Social.Application.DTOs;

public class CommunityChallengeDto
{
    public Guid Id { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? UpdatedAt { get; set; }
    public Guid CreatorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset RegistrationDeadline { get; set; }
    public DateTimeOffset StartDate { get; set; }
    public DateTimeOffset EndDate { get; set; }
    public ChallengeGoalType? GoalType { get; set; }
    public decimal? TargetValue { get; set; }
    public decimal? PointRewards { get; set; }
    public IReadOnlyList<string> Gifts { get; set; } = [];
    public int ParticipantCount { get; set; }
    public string? Address { get; set; }
    public GeoLocationDto? Location { get; set; }
    public ChallengeStatus Status { get; set; }
}

public class NearbyCommunityChallengeDto : CommunityChallengeDto
{
    public double DistanceKm { get; set; }
}

public class AdminCreateCommunityChallengeDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset RegistrationDeadline { get; set; }
    public DateTimeOffset StartDate { get; set; }
    public DateTimeOffset EndDate { get; set; }
    public ChallengeGoalType GoalType { get; set; }
    public decimal TargetValue { get; set; }
    public decimal? PointRewards { get; set; }
    public List<string>? Gifts { get; set; }
    public string? Address { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

public class AdminUpdateCommunityChallengeDto
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTimeOffset RegistrationDeadline { get; set; }
    public DateTimeOffset StartDate { get; set; }
    public DateTimeOffset EndDate { get; set; }
    public ChallengeGoalType GoalType { get; set; }
    public decimal TargetValue { get; set; }
    public decimal? PointRewards { get; set; }
    public List<string>? Gifts { get; set; }
    public string? Address { get; set; }
    public decimal? Latitude { get; set; }
    public decimal? Longitude { get; set; }
}

public class ChallengeAdminListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public ChallengeStatus? Status { get; set; }
    public ChallengeGoalType? GoalType { get; set; }
    public DateTimeOffset? StartDateFrom { get; set; }
    public DateTimeOffset? StartDateTo { get; set; }
    public DateTimeOffset? EndDateFrom { get; set; }
    public DateTimeOffset? EndDateTo { get; set; }
}

public class ChallengePublicListQuery
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public ChallengeGoalType? GoalType { get; set; }
    public DateTimeOffset? StartDateFrom { get; set; }
    public DateTimeOffset? StartDateTo { get; set; }
    public DateTimeOffset? EndDateFrom { get; set; }
    public DateTimeOffset? EndDateTo { get; set; }
}

public class NearbyChallengeQuery
{
    public double UserLat { get; set; }
    public double UserLng { get; set; }
    public double RadiusKm { get; set; } = 10;
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public enum ChallengeRouteTravelMode
{
    Car,
    Motorbike,
    Walking,
}

public class ChallengeRouteQuery
{
    public double UserLat { get; set; }
    public double UserLng { get; set; }

    /// <summary>When set, only one AWS CalculateRoute call is made for this mode.</summary>
    public ChallengeRouteTravelMode? TravelMode { get; set; }
}

public class TravelModeEstimateDto
{
    public int EstimatedMinutes { get; set; }

    public double DistanceKm { get; set; }

    /// <summary>UTC arrival time based on AWS route duration (DepartNow + traffic when available).</summary>
    public DateTimeOffset EstimatedArrivalAt { get; set; }
}

public class TravelModeRouteDto : TravelModeEstimateDto
{
    public IReadOnlyList<GeoLocationDto> Polyline { get; set; } = [];

    /// <summary>
    /// Meters from the last road-snapped polyline point to the challenge GPS coordinate.
    /// Non-zero when the venue is off-road (park interior, building footprint, etc.).
    /// </summary>
    public double OffRoadGapMeters { get; set; }
}

public class ChallengeRouteDto
{
    /// <summary>Large vehicle route (Car / ô tô).</summary>
    public TravelModeRouteDto Car { get; set; } = new();

    /// <summary>Small vehicle route (Motorcycle / Scooter / xe máy).</summary>
    public TravelModeRouteDto Motorbike { get; set; } = new();

    public TravelModeRouteDto Walking { get; set; } = new();
}
