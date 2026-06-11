using Marketplace.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace Marketplace.Application.Extensions;

public static class ApplicationServiceExtensions
{
    public static IServiceCollection AddMarketplaceApplication(this IServiceCollection services)
    {
        services.AddScoped<IPartnerService, PartnerService>();
        services.AddScoped<IFoodMenuItemService, FoodMenuItemService>();
        services.AddScoped<IAffiliateProductService, AffiliateProductService>();
        services.AddScoped<IReviewService, ReviewService>();
        services.AddScoped<IAffiliateClickService, AffiliateClickService>();

        return services;
    }
}
