using Microsoft.Extensions.DependencyInjection;
using Social.Application.Services;

namespace Social.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddSocialApplication(this IServiceCollection services)
    {
        services.AddScoped<IPostService, PostService>();
        services.AddScoped<IPostShareCodeBackfillService, PostShareCodeBackfillService>();
        services.AddScoped<IInteractionService, InteractionService>();
        services.AddScoped<ICommentService, CommentService>();
        services.AddScoped<ICommunityChallengeService, CommunityChallengeService>();
        return services;
    }
}
