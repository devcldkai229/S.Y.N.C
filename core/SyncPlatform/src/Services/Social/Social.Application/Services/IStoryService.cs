using Social.Application.DTOs;

namespace Social.Application.Services;

public interface IStoryService
{
    Task<StoryDto> CreateAsync(
        Guid authorId,
        CreateStoryDto dto,
        Stream? mediaStream,
        long? mediaSize,
        string? fileName,
        string? contentType,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoryDto>> GetActiveByUserAsync(
        Guid authorId,
        Guid? viewerId,
        CancellationToken cancellationToken = default);

    Task<IReadOnlyList<StoryFeedGroupDto>> GetFeedAsync(
        Guid viewerId,
        CancellationToken cancellationToken = default);

    Task<StoryViewResultDto> ViewAsync(
        Guid viewerId,
        Guid storyId,
        CancellationToken cancellationToken = default);

    Task<StoryLikeResultDto> LikeAsync(
        Guid userId,
        Guid storyId,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        Guid authorId,
        Guid storyId,
        CancellationToken cancellationToken = default);
}
