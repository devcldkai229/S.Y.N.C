using Exercise.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Exercise.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddExerciseApplication(this IServiceCollection services)
    {
        services.AddScoped<IExerciseCatalogService, ExerciseCatalogService>();
        services.AddScoped<IExerciseMotionAssetService, ExerciseMotionAssetService>();
        services.AddScoped<IWorkoutTemplateService, WorkoutTemplateService>();

        return services;
    }
}
