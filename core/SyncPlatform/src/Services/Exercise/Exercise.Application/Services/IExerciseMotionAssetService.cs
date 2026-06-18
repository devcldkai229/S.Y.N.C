using System;
using System.Collections.Generic;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using Exercise.Application.DTOs;
using Libs.Shared.Enums;

namespace Exercise.Application.Services;

public interface IExerciseMotionAssetService
{
    Task<IReadOnlyList<ExerciseMotionAssetDto>> GetByExerciseIdAsync(Guid exerciseId, CancellationToken cancellationToken = default);
    Task<ExerciseMotionAssetDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<ExerciseMotionAssetDto> CreateAsync(CreateExerciseMotionAssetDto dto, CancellationToken cancellationToken = default);
    Task UpdateAsync(Guid id, UpdateExerciseMotionAssetDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    Task<ExerciseMotionAssetDto> UpdateWithUploadAsync(
        CreateExerciseMotionAssetUploadDto dto,
        CancellationToken cancellationToken = default);
}
