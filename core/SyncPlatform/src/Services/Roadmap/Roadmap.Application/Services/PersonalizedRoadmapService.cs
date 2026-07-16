using Libs.Shared.Enums;
using Roadmap.Application.Common;

using Roadmap.Application.DTOs;
using Roadmap.Application.Exceptions;
using Roadmap.Application.Mappers;
using Roadmap.Domain.Models;
using Roadmap.Domain.Repositories;

namespace Roadmap.Application.Services;

public class PersonalizedRoadmapService : IPersonalizedRoadmapService
{
    private readonly IPersonalizedRoadmapRepository _repository;
    private readonly IRoadmapSessionRepository _sessionRepository;
    private readonly IScheduledWorkoutRepository _scheduledWorkoutRepository;
    private readonly IRoadmapRealtimePublisher _realtimePublisher;

    public PersonalizedRoadmapService(
        IPersonalizedRoadmapRepository repository,
        IRoadmapSessionRepository sessionRepository,
        IScheduledWorkoutRepository scheduledWorkoutRepository,
        IRoadmapRealtimePublisher realtimePublisher)
    {
        _repository = repository;
        _sessionRepository = sessionRepository;
        _scheduledWorkoutRepository = scheduledWorkoutRepository;
        _realtimePublisher = realtimePublisher;
    }

    public async Task<PersonalizedRoadmapDto> CreateAsync(CreatePersonalizedRoadmapDto dto, CancellationToken cancellationToken = default)
    {
        if (dto.UserId == Guid.Empty)
            throw new BadRequestException("UserId is required.");

        if (string.IsNullOrWhiteSpace(dto.RoadmapName))
            throw new BadRequestException("RoadmapName is required.");

        var entity = dto.ToEntity();
        await _repository.CreateAsync(entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<PersonalizedRoadmapDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(PersonalizedRoadmap), id);

        return entity.ToDto();
    }

    public async Task<(IReadOnlyList<PersonalizedRoadmapDto> Items, PaginationMetadata Metadata)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var (entities, totalCount) = await _repository.GetPagedAsync(
            pageNumber,
            pageSize,
            userId.HasValue ? x => x.UserId == userId.Value : null,
            cancellationToken);

        var dtos = entities.Select(e => e.ToDto()).ToList();
        var metadata = new PaginationMetadata(pageNumber, pageSize, totalCount);
        return (dtos, metadata);
    }

    public async Task<PersonalizedRoadmapDto> UpdateAsync(Guid id, UpdatePersonalizedRoadmapDto dto, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(dto.RoadmapName))
            throw new BadRequestException("RoadmapName is required.");

        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(PersonalizedRoadmap), id);

        entity.UpdateEntity(dto);
        await _repository.UpdateAsync(id, entity, cancellationToken);
        return entity.ToDto();
    }

    public async Task<PersonalizedRoadmapDto?> GetActiveByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var roadmaps = await _repository.GetByUserIdAsync(userId, cancellationToken);
        var active = roadmaps.FirstOrDefault(r => r.RoadmapStatus == RoadmapStatus.Active)
            ?? roadmaps.FirstOrDefault();
        return active?.ToDto();
    }

    public async Task<PersonalizedRoadmapDto> PatchForAiAsync(
        Guid id,
        InternalPatchPersonalizedRoadmapDto dto,
        CancellationToken cancellationToken = default)
    {
        var entity = await _repository.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(PersonalizedRoadmap), id);

        if (dto.RoadmapName is not null) entity.RoadmapName = dto.RoadmapName;
        if (dto.FitnessGoal is not null) entity.FitnessGoal = dto.FitnessGoal;
        if (dto.CurrentPhase is not null) entity.CurrentPhase = dto.CurrentPhase;
        if (dto.CurrentWeightKg is not null) entity.CurrentWeightKg = dto.CurrentWeightKg.Value;
        if (dto.TargetWeightKg is not null) entity.TargetWeightKg = dto.TargetWeightKg.Value;
        if (dto.InitialFatPercentage is not null) entity.InitialFatPercentage = dto.InitialFatPercentage.Value;
        if (dto.TargetFatPercentage is not null) entity.TargetFatPercentage = dto.TargetFatPercentage.Value;
        if (dto.AdaptiveAiEnabled is not null) entity.AdaptiveAiEnabled = dto.AdaptiveAiEnabled.Value;
        if (dto.AllowAiReschedule is not null) entity.AllowAiReschedule = dto.AllowAiReschedule.Value;
        if (dto.AllowAiIntensityAdjustment is not null) entity.AllowAiIntensityAdjustment = dto.AllowAiIntensityAdjustment.Value;
        if (dto.AllowAiRecoveryDeload is not null) entity.AllowAiRecoveryDeload = dto.AllowAiRecoveryDeload.Value;
        if (dto.RoadmapStatus is not null) entity.RoadmapStatus = dto.RoadmapStatus.Value;

        await _repository.UpdateAsync(id, entity, cancellationToken);

        await _realtimePublisher.PublishRoadmapUpdatedAsync(
            entity.UserId,
            "roadmap_changed",
            entity.Id,
            cancellationToken: cancellationToken);

        return entity.ToDto();
    }



    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        if (!await _repository.ExistsAsync(id, cancellationToken))
            throw new NotFoundException(nameof(PersonalizedRoadmap), id);

        // Cascade: delete all sessions for this roadmap + their calendar entries
        var sessions = await _sessionRepository.GetByRoadmapIdAsync(id, cancellationToken);
        foreach (var session in sessions)
        {
            var sw = await _scheduledWorkoutRepository.GetBySessionIdAsync(session.Id, cancellationToken);
            if (sw is not null)
                await _scheduledWorkoutRepository.DeleteAsync(sw.Id, cancellationToken);
        }
        await _sessionRepository.DeleteByRoadmapIdAsync(id, cancellationToken);

        await _repository.DeleteAsync(id, cancellationToken);
    }
}
