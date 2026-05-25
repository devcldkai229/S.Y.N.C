using Microsoft.Extensions.DependencyInjection;
using Roadmap.Application.Services;

namespace Roadmap.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddRoadmapApplication(this IServiceCollection services)
    {
        services.AddScoped<IUserCustomWorkoutService, UserCustomWorkoutService>();
        services.AddScoped<IRoadmapSessionService, RoadmapSessionService>();
        services.AddScoped<IWorkoutExecutionService, WorkoutExecutionService>();
        services.AddScoped<IExerciseSetLogService, ExerciseSetLogService>();
        services.AddScoped<IPersonalizedRoadmapService, PersonalizedRoadmapService>();
        services.AddScoped<IRecoveryProfileService, RecoveryProfileService>();
        services.AddScoped<IScheduledWorkoutService, ScheduledWorkoutService>();
        services.AddScoped<IWorkoutExecutionLogService, WorkoutExecutionLogService>();


        return services;
    }
}
