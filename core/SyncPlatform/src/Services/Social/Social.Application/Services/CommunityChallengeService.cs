using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Helpers;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class CommunityChallengeService : ICommunityChallengeService
{
    private readonly ICommunityChallengeRepository _challenges;
    private readonly IChallengeParticipantRepository _participants;
    private readonly IChallengeRouteCalculator _routeCalculator;
    private readonly ISocialNotificationClient _notifications;

    public CommunityChallengeService(
        ICommunityChallengeRepository challenges,
        IChallengeParticipantRepository participants,
        IChallengeRouteCalculator routeCalculator,
        ISocialNotificationClient notifications)
    {
        _challenges = challenges;
        _participants = participants;
        _routeCalculator = routeCalculator;
        _notifications = notifications;
    }

    public async Task<CommunityChallengeDto> CreateAdminAsync(
        Guid creatorId,
        AdminCreateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default)
    {
        ValidateChallengeFields(
            dto.Title,
            dto.RegistrationDeadline,
            dto.StartDate,
            dto.EndDate,
            dto.TargetValue);

        var challenge = new CommunityChallenge
        {
            CreatorId = creatorId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            RegistrationDeadline = dto.RegistrationDeadline,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            GoalType = dto.GoalType,
            TargetValue = dto.TargetValue,
            PointRewards = dto.PointRewards,
            Gifts = NormalizeGifts(dto.Gifts),
            Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim(),
            Location = GeoLocationMapping.ToGeoJsonPoint(
                dto.Latitude is null ? null : (double)dto.Latitude,
                dto.Longitude is null ? null : (double)dto.Longitude),
            ParticipantCount = 0,
            Status = ChallengeStatusResolver.Resolve(
                dto.RegistrationDeadline,
                dto.StartDate,
                dto.EndDate),
        };

        await _challenges.CreateAsync(challenge, cancellationToken);
        return challenge.ToDto();
    }

    public async Task<CommunityChallengeDto> UpdateAdminAsync(
        Guid challengeId,
        AdminUpdateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default)
    {
        ValidateChallengeFields(
            dto.Title,
            dto.RegistrationDeadline,
            dto.StartDate,
            dto.EndDate,
            dto.TargetValue);

        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);
        EnsureRegistrationOpen(challenge, "update");

        challenge.Title = dto.Title.Trim();
        challenge.Description = dto.Description.Trim();
        challenge.RegistrationDeadline = dto.RegistrationDeadline;
        challenge.StartDate = dto.StartDate;
        challenge.EndDate = dto.EndDate;
        challenge.GoalType = dto.GoalType;
        challenge.TargetValue = dto.TargetValue;
        challenge.PointRewards = dto.PointRewards;
        challenge.Gifts = NormalizeGifts(dto.Gifts);
        challenge.Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim();
        challenge.Location = GeoLocationMapping.ToGeoJsonPoint(
            dto.Latitude is null ? null : (double)dto.Latitude,
            dto.Longitude is null ? null : (double)dto.Longitude);

        ChallengeStatusResolver.SyncStatus(challenge);
        await _challenges.UpdateAsync(challengeId, challenge, cancellationToken);
        return challenge.ToDto();
    }

    public async Task DeleteAdminAsync(Guid challengeId, CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);
        EnsureRegistrationOpen(challenge, "delete");
        await _challenges.DeleteAsync(challengeId, cancellationToken);
    }

    public async Task<CommunityChallengeDto> ActivateAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);
        return challenge.ToDto();
    }

    public async Task<CommunityChallengeDto> CompleteAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);

        if (challenge.Status != ChallengeStatus.InProgress)
            throw new ConflictException("Only in-progress challenges can be completed.");

        var now = DateTimeOffset.UtcNow;
        if (challenge.EndDate > now)
            throw new BadRequestException("Challenge cannot be completed before its EndDate.");

        challenge.Status = ChallengeStatus.Completed;
        await _challenges.UpdateAsync(challengeId, challenge, cancellationToken);

        var participantIds = await _participants.GetActiveParticipantUserIdsAsync(challengeId, cancellationToken);
        if (participantIds.Count > 0)
        {
            _ = _notifications.NotifyChallengeCompletedAsync(
                challengeId,
                challenge.Title,
                participantIds,
                cancellationToken);
        }

        return challenge.ToDto();
    }

    public async Task<(IReadOnlyList<CommunityChallengeDto> Items, PaginationMetadata Pagination)> GetAdminPagedAsync(
        ChallengeAdminListQuery query,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _challenges.GetPagedAsync(
            pageNumber,
            pageSize,
            query.Status,
            query.GoalType,
            query.StartDateFrom,
            query.StartDateTo,
            query.EndDateFrom,
            query.EndDateTo,
            requiredStatus: null,
            cancellationToken);

        return (items.Select(x => x.ToDto()).ToList(), BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<CommunityChallengeDto> GetAdminByIdAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);
        return challenge.ToDto();
    }

    public async Task<(IReadOnlyList<CommunityChallengeDto> Items, PaginationMetadata Pagination)> GetActivePagedAsync(
        ChallengePublicListQuery query,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _challenges.GetPagedAsync(
            pageNumber,
            pageSize,
            status: null,
            query.GoalType,
            query.StartDateFrom,
            query.StartDateTo,
            query.EndDateFrom,
            query.EndDateTo,
            requiredStatus: ChallengeStatus.Active,
            cancellationToken);

        return (items.Select(x => x.ToDto()).ToList(), BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<CommunityChallengeDto> GetActiveByIdAsync(
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);

        if (challenge.Status != ChallengeStatus.Active)
            throw new NotFoundException($"Challenge {challengeId} was not found.");

        return challenge.ToDto();
    }

    public async Task<(IReadOnlyList<NearbyCommunityChallengeDto> Items, PaginationMetadata Pagination)> GetNearbyAsync(
        NearbyChallengeQuery query,
        CancellationToken cancellationToken = default)
    {
        if (query.RadiusKm <= 0)
            throw new BadRequestException("radiusKm must be greater than zero.");

        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _challenges.GetNearbyActiveAsync(
            query.UserLat,
            query.UserLng,
            query.RadiusKm,
            pageNumber,
            pageSize,
            cancellationToken);

        var dtos = items.Select(challenge =>
        {
            var dto = challenge.ToDto().ToNearbyDto();
            var location = GeoLocationMapping.FromGeoJsonPoint(challenge.Location);
            if (location is not null)
            {
                dto.DistanceKm = Math.Round(
                    GeoDistanceHelper.HaversineKm(
                        query.UserLat,
                        query.UserLng,
                        location.Value.Latitude,
                        location.Value.Longitude),
                    2);
            }

            return dto;
        })
        .OrderBy(d => d.DistanceKm)
        .ToList();

        return (dtos, BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<ChallengeRouteDto> GetRouteAsync(
        Guid challengeId,
        ChallengeRouteQuery query,
        CancellationToken cancellationToken = default)
    {
        var challenge = await GetSyncedChallengeAsync(challengeId, cancellationToken);

        if (challenge.Status is ChallengeStatus.Completed)
            throw new BadRequestException("Route is not available for completed challenges.");

        var location = GeoLocationMapping.FromGeoJsonPoint(challenge.Location)
            ?? throw new BadRequestException("This challenge does not have a location.");

        return await _routeCalculator.CalculateRouteAsync(
            query.UserLat,
            query.UserLng,
            location.Latitude,
            location.Longitude,
            query.TravelMode,
            cancellationToken);
    }

    private async Task<CommunityChallenge> GetSyncedChallengeAsync(
        Guid challengeId,
        CancellationToken cancellationToken)
    {
        var challenge = await _challenges.GetByIdAsync(challengeId, cancellationToken)
            ?? throw new NotFoundException($"Challenge {challengeId} was not found.");

        if (ChallengeStatusResolver.SyncStatus(challenge))
            await _challenges.RefreshStatusAsync(challenge.Id, challenge.Status, cancellationToken);

        return challenge;
    }

    private static void ValidateChallengeFields(
        string title,
        DateTimeOffset registrationDeadline,
        DateTimeOffset startDate,
        DateTimeOffset endDate,
        decimal targetValue)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new BadRequestException("Challenge title is required.");

        if (registrationDeadline >= startDate)
            throw new BadRequestException("RegistrationDeadline must be before StartDate.");

        if (endDate <= startDate)
            throw new BadRequestException("EndDate must be after StartDate.");

        if (targetValue <= 0)
            throw new BadRequestException("TargetValue must be greater than zero.");
    }

    private static void EnsureRegistrationOpen(CommunityChallenge challenge, string action)
    {
        if (challenge.Status != ChallengeStatus.Active)
            throw new ForbiddenException($"Only challenges open for registration can be {action}.");
    }

    private static string[]? NormalizeGifts(IEnumerable<string>? gifts) =>
        gifts?.Where(g => !string.IsNullOrWhiteSpace(g)).Select(g => g.Trim()).ToArray();

    private static PaginationMetadata BuildPagination(int pageNumber, int pageSize, int totalRecords) =>
        new()
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = totalRecords,
        };
}
