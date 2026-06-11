using Social.Application.Clients;
using Social.Application.Common;
using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Exceptions;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class ChallengeParticipationService : IChallengeParticipationService
{
    private readonly ICommunityChallengeRepository _challenges;
    private readonly IChallengeParticipantRepository _participants;
    private readonly IChallengeParticipationRepository _participation;
    private readonly ISocialNotificationClient _notifications;

    public ChallengeParticipationService(
        ICommunityChallengeRepository challenges,
        IChallengeParticipantRepository participants,
        IChallengeParticipationRepository participation,
        ISocialNotificationClient notifications)
    {
        _challenges = challenges;
        _participants = participants;
        _participation = participation;
        _notifications = notifications;
    }

    public async Task<ChallengeParticipantDto> JoinAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await _challenges.GetByIdAsync(challengeId, cancellationToken)
            ?? throw new NotFoundException($"Challenge {challengeId} was not found.");

        if (ChallengeStatusResolver.SyncStatus(challenge))
            await _challenges.RefreshStatusAsync(challenge.Id, challenge.Status, cancellationToken);

        if (challenge.Status != ChallengeStatus.Active)
            throw new ForbiddenException("Registration is closed. Only active (open registration) challenges can be joined.");

        if (challenge.EndDate < DateTimeOffset.UtcNow)
            throw new BadRequestException("This challenge has already ended.");

        try
        {
            var participant = await _participation.JoinAsync(challengeId, userId, cancellationToken);
            return participant.ToDto();
        }
        catch (DuplicateChallengeJoinException)
        {
            throw new ConflictException("You have already joined this challenge.");
        }
    }

    public async Task<ChallengeParticipantDto> LeaveAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        if (!await _challenges.ExistsAsync(challengeId, cancellationToken))
            throw new NotFoundException($"Challenge {challengeId} was not found.");

        try
        {
            var participant = await _participation.LeaveAsync(challengeId, userId, cancellationToken);
            return participant.ToDto();
        }
        catch (InvalidOperationException)
        {
            throw new NotFoundException("You are not an active participant of this challenge.");
        }
    }

    public async Task<ChallengeParticipantDto> StartProgressAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        if (!await _challenges.ExistsAsync(challengeId, cancellationToken))
            throw new NotFoundException($"Challenge {challengeId} was not found.");

        var updated = await _participants.UpdateStatusAsync(
            challengeId,
            userId,
            ParticipantStatus.Joined,
            ParticipantStatus.InProgress,
            cancellationToken: cancellationToken);

        if (!updated)
            throw new ConflictException("Progress can only be started from Joined status.");

        var participant = await _participants.GetByChallengeAndUserAsync(challengeId, userId, cancellationToken)
            ?? throw new NotFoundException("Participation record was not found.");

        return participant.ToDto();
    }

    public async Task<ChallengeParticipantDto> CompleteAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        var challenge = await _challenges.GetByIdAsync(challengeId, cancellationToken)
            ?? throw new NotFoundException($"Challenge {challengeId} was not found.");

        var now = DateTimeOffset.UtcNow;
        var updated = await _participants.UpdateStatusAsync(
            challengeId,
            userId,
            ParticipantStatus.InProgress,
            ParticipantStatus.Completed,
            completedAt: now,
            cancellationToken: cancellationToken);

        if (!updated)
            throw new ConflictException("Challenge can only be completed from InProgress status.");

        _ = _notifications.NotifyChallengeRewardEarnedAsync(
            userId,
            challengeId,
            challenge.Title,
            challenge.PointRewards,
            challenge.Gifts,
            cancellationToken);

        var participant = await _participants.GetByChallengeAndUserAsync(challengeId, userId, cancellationToken)
            ?? throw new NotFoundException("Participation record was not found.");

        return participant.ToDto();
    }

    public async Task<(IReadOnlyList<ChallengeParticipantDto> Items, PaginationMetadata Pagination)> GetParticipantsAsync(
        Guid challengeId,
        ChallengeParticipantListQuery query,
        CancellationToken cancellationToken = default)
    {
        if (!await _challenges.ExistsAsync(challengeId, cancellationToken))
            throw new NotFoundException($"Challenge {challengeId} was not found.");

        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (items, total) = await _participants.GetPagedByChallengeAsync(
            challengeId,
            pageNumber,
            pageSize,
            cancellationToken);

        var dtos = items.Select(x => x.ToDto()).ToList();
        return (dtos, BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<(IReadOnlyList<UserChallengeDto> Items, PaginationMetadata Pagination)> GetMyChallengesAsync(
        Guid userId,
        UserChallengeListQuery query,
        CancellationToken cancellationToken = default)
    {
        var pageNumber = Math.Max(1, query.PageNumber);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);

        var (participations, total) = await _participants.GetPagedByUserAsync(
            userId,
            pageNumber,
            pageSize,
            cancellationToken);

        var dtos = new List<UserChallengeDto>(participations.Count);
        foreach (var participation in participations)
        {
            var challenge = await _challenges.GetByIdAsync(participation.ChallengeId, cancellationToken);
            if (challenge is null)
                continue;

            dtos.Add(new UserChallengeDto
            {
                Challenge = challenge.ToDto(),
                ParticipantStatus = participation.Status,
                JoinedAt = participation.JoinedAt,
                CompletedAt = participation.CompletedAt,
                IsActive = participation.IsActive,
            });
        }

        return (dtos, BuildPagination(pageNumber, pageSize, total));
    }

    public async Task<ChallengeParticipationStatusDto> GetParticipationStatusAsync(
        Guid userId,
        Guid challengeId,
        CancellationToken cancellationToken = default)
    {
        if (!await _challenges.ExistsAsync(challengeId, cancellationToken))
            throw new NotFoundException($"Challenge {challengeId} was not found.");

        var participant = await _participants.GetByChallengeAndUserAsync(challengeId, userId, cancellationToken);

        if (participant is null || !participant.IsActive)
        {
            return new ChallengeParticipationStatusDto
            {
                HasJoined = false,
                Status = null,
            };
        }

        return new ChallengeParticipationStatusDto
        {
            HasJoined = true,
            Status = participant.Status,
        };
    }

    private static PaginationMetadata BuildPagination(int pageNumber, int pageSize, int totalRecords) =>
        new()
        {
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalRecords = totalRecords,
        };
}
