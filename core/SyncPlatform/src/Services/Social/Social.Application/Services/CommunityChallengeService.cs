using Social.Application.DTOs;
using Social.Application.Exceptions;
using Social.Application.Helpers;
using Social.Application.Mappers;
using Social.Domain.Enums;
using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Services;

public class CommunityChallengeService : ICommunityChallengeService
{
    private readonly ICommunityChallengeRepository _challenges;
    private readonly IPostRepository _posts;

    public CommunityChallengeService(
        ICommunityChallengeRepository challenges,
        IPostRepository posts)
    {
        _challenges = challenges;
        _posts = posts;
    }

    public async Task<CommunityChallengeDto> CreateAsync(
        Guid creatorId,
        CreateCommunityChallengeDto dto,
        CancellationToken cancellationToken = default)
    {
        ValidateCreate(dto);

        var status = ChallengeStatusResolver.Resolve(dto.StartDate, dto.EndDate);

        var challenge = new CommunityChallenge
        {
            CreatorId = creatorId,
            Title = dto.Title.Trim(),
            Description = dto.Description.Trim(),
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            GoalType = dto.GoalType,
            TargetValue = dto.TargetValue,
            ParticipantCount = 0,
            Status = status,
        };

        await _challenges.CreateAsync(challenge, cancellationToken);
        await PublishChallengeCreationPostAsync(creatorId, challenge, dto, cancellationToken);

        return challenge.ToDto();
    }

    public async Task<IReadOnlyList<CommunityChallengeDto>> GetActiveAsync(
        CancellationToken cancellationToken = default)
    {
        var items = await _challenges.GetActiveAsync(cancellationToken);
        return items.Select(x => x.ToDto()).ToList();
    }

    private static void ValidateCreate(CreateCommunityChallengeDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Title))
            throw new BadRequestException("Challenge title is required.");

        if (dto.EndDate <= dto.StartDate)
            throw new BadRequestException("EndDate must be after StartDate.");

        if (dto.TargetValue <= 0)
            throw new BadRequestException("TargetValue must be greater than zero.");

        if (string.IsNullOrWhiteSpace(dto.AuthorSnapshot.FullName))
            throw new BadRequestException("AuthorSnapshot.FullName is required for the feed announcement.");
    }

    private async Task PublishChallengeCreationPostAsync(
        Guid creatorId,
        CommunityChallenge challenge,
        CreateCommunityChallengeDto dto,
        CancellationToken cancellationToken)
    {
        var announcement = string.IsNullOrWhiteSpace(dto.FeedAnnouncement)
            ? BuildDefaultAnnouncement(challenge)
            : dto.FeedAnnouncement.Trim();

        var post = new Post
        {
            AuthorId = creatorId,
            AuthorSnapshot = new AuthorSnapshot
            {
                FullName = dto.AuthorSnapshot.FullName.Trim(),
                AvatarUrl = dto.AuthorSnapshot.AvatarUrl,
            },
            PostType = PostType.ChallengeCreation,
            Content = announcement,
            ReferenceId = challenge.Id,
            IsPublic = true,
            Metrics = new PostMetrics(),
        };

        await ShareCodeGenerator.AssignUniqueToPostAsync(_posts, post, cancellationToken);
        await _posts.CreateAsync(post, cancellationToken);
    }

    private static string BuildDefaultAnnouncement(CommunityChallenge challenge)
    {
        var goalLabel = challenge.GoalType switch
        {
            ChallengeGoalType.TotalDistance => "tổng quãng đường",
            ChallengeGoalType.TotalWorkouts => "số buổi tập",
            ChallengeGoalType.TotalCaloriesBurned => "calo tiêu hao",
            _ => "mục tiêu",
        };

        return (
            $"🎯 Thử thách cộng đồng mới: «{challenge.Title}». " +
            $"Cùng nhau đạt {goalLabel} {challenge.TargetValue} " +
            $"từ {challenge.StartDate:dd/MM/yyyy} đến {challenge.EndDate:dd/MM/yyyy}. " +
            "Tham gia ngay nhé!");
    }
}
