using Marketplace.Application.DTOs;
using Marketplace.Application.Exceptions;
using Marketplace.Domain.Enums;
using Marketplace.Domain.Models;
using Marketplace.Domain.Repositories;

namespace Marketplace.Application.Services;

public class AffiliateClickService : IAffiliateClickService
{
    private static readonly HashSet<string> ValidSources =
        new(StringComparer.OrdinalIgnoreCase) { "ai_recommendation", "browse", "search" };

    private readonly IAffiliateProductRepository _productRepository;
    private readonly IAffiliateClickEventRepository _clickRepository;

    public AffiliateClickService(
        IAffiliateProductRepository productRepository,
        IAffiliateClickEventRepository clickRepository)
    {
        _productRepository = productRepository;
        _clickRepository = clickRepository;
    }

    public async Task<AffiliateClickResponseDto> TrackClickAsync(
        Guid userId,
        Guid productId,
        AffiliateClickRequest request,
        CancellationToken cancellationToken = default)
    {
        var product = await _productRepository.GetByIdAsync(productId, cancellationToken);
        if (product == null || product.Availability == AvailabilityStatus.Hidden)
            throw new NotFoundException(nameof(AffiliateProduct), productId);

        var source = NormalizeSource(request.Source);
        var clickToken = Guid.NewGuid().ToString("N");

        var clickEvent = new AffiliateClickEvent
        {
            UserId = userId,
            AffiliateProductId = productId,
            PartnerId = product.PartnerId,
            ClickToken = clickToken,
            Source = source,
            ClickedAt = DateTimeOffset.UtcNow,
        };

        await _clickRepository.CreateAsync(clickEvent, cancellationToken);

        var separator = product.AffiliateUrl.Contains('?') ? "&" : "?";
        var redirectUrl = $"{product.AffiliateUrl}{separator}sync_click={clickToken}";

        return new AffiliateClickResponseDto
        {
            ClickToken = clickToken,
            RedirectUrl = redirectUrl,
        };
    }

    private static string NormalizeSource(string? source)
    {
        if (string.IsNullOrWhiteSpace(source))
            return "browse";

        var normalized = source.Trim().ToLowerInvariant();
        return ValidSources.Contains(normalized) ? normalized : "browse";
    }
}
