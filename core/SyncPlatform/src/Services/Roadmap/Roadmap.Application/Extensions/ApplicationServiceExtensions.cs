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

        return services;
    }
}
