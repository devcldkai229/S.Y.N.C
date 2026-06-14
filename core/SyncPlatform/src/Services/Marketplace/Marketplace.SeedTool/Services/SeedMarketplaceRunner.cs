using Marketplace.Domain.Repositories;
using Marketplace.SeedTool.Configuration;
using Marketplace.SeedTool.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Marketplace.SeedTool.Services;

public sealed class SeedMarketplaceRunner
{
    private readonly SeedReader _reader;
    private readonly MarketplaceMapper _mapper;
    private readonly ImagePipeline _images;
    private readonly MarketplaceUpserter _upserter;
    private readonly IPartnerRepository _partners;
    private readonly StorageOptions _storage;
    private readonly ILogger<SeedMarketplaceRunner> _logger;

    public SeedMarketplaceRunner(
        SeedReader reader,
        MarketplaceMapper mapper,
        ImagePipeline images,
        MarketplaceUpserter upserter,
        IPartnerRepository partners,
        IOptions<StorageOptions> storage,
        ILogger<SeedMarketplaceRunner> logger)
    {
        _reader = reader;
        _mapper = mapper;
        _images = images;
        _upserter = upserter;
        _partners = partners;
        _storage = storage.Value;
        _logger = logger;
    }

    public async Task<SeedReport> RunAsync(SeedRunOptions options, CancellationToken cancellationToken = default)
    {
        var report = new SeedReport();
        var seed = _reader.Read(options.SeedFilePath);
        var kitchens = options.Limit.HasValue
            ? seed.Kitchens.Take(options.Limit.Value).ToList()
            : seed.Kitchens;

        _logger.LogInformation("Seeding {Count} kitchen(s) from JSON", kitchens.Count);

        foreach (var kitchen in kitchens)
        {
            try
            {
                await SeedKitchenAsync(kitchen, report, cancellationToken);
            }
            catch (Exception ex)
            {
                report.PartnersFailed++;
                var message = $"Kitchen '{kitchen.Slug}': {ex.Message}";
                report.Errors.Add(message);
                _logger.LogError(ex, "Failed to seed kitchen {Slug}", kitchen.Slug);
            }
        }

        report.PrintSummary();
        return report;
    }

    private async Task SeedKitchenAsync(
        KitchenSeedDto kitchen,
        SeedReport report,
        CancellationToken cancellationToken)
    {
        _logger.LogInformation("Processing kitchen {Name} ({Slug})", kitchen.Name, kitchen.Slug);

        var existing = await _partners.GetBySlugAsync(kitchen.Slug, cancellationToken);
        var partner = _mapper.MapPartner(kitchen, existing?.OwnerUserId);
        if (existing is not null)
        {
            partner.Id = existing.Id;
            partner.CreatedAt = existing.CreatedAt;
        }

        var logoKey = MarketplaceMapper.PartnerLogoKey(kitchen.Slug, _storage.KeyPrefix);
        var coverKey = MarketplaceMapper.PartnerCoverKey(kitchen.Slug, _storage.KeyPrefix);

        var logoResult = await _images.EnsureImageAsync(
            logoKey,
            kitchen.LogoImageQuery,
            "square",
            existing?.LogoUrl,
            report,
            cancellationToken);

        var coverResult = await _images.EnsureImageAsync(
            coverKey,
            kitchen.CoverImageQuery,
            "landscape",
            existing?.CoverImageUrl,
            report,
            cancellationToken);

        partner.LogoUrl = logoResult.Status != ImagePipeline.ImageUploadStatus.Failed
            ? _images.ResolveStoredUrl(logoKey)
            : _images.ResolveStoredUrl(ImagePipeline.DefaultFoodKey);

        partner.CoverImageUrl = coverResult.Status != ImagePipeline.ImageUploadStatus.Failed
            ? _images.ResolveStoredUrl(coverKey)
            : _images.ResolveStoredUrl(ImagePipeline.DefaultFoodKey);

        var partnerUpsert = await _upserter.UpsertPartnerAsync(partner, cancellationToken);
        partner = partnerUpsert.Entity;

        if (partnerUpsert.Action == MarketplaceUpserter.UpsertAction.Created)
            report.PartnersCreated++;
        else
            report.PartnersUpdated++;

        foreach (var dish in kitchen.Menu)
        {
            try
            {
                await SeedDishAsync(kitchen.Slug, partner.Id, dish, report, cancellationToken);
            }
            catch (Exception ex)
            {
                report.DishesFailed++;
                var message = $"Dish '{kitchen.Slug}/{dish.Slug}': {ex.Message}";
                report.Errors.Add(message);
                _logger.LogError(ex, "Failed to seed dish {Slug}", dish.Slug);
            }
        }
    }

    private async Task SeedDishAsync(
        string kitchenSlug,
        Guid partnerId,
        DishSeedDto dish,
        SeedReport report,
        CancellationToken cancellationToken)
    {
        var item = _mapper.MapFoodMenuItem(dish, partnerId);
        var existingDish = await _upserter.GetByPartnerAndSlugAsync(partnerId, dish.Slug, cancellationToken);
        var s3Key = MarketplaceMapper.NormalizeS3Key(dish.S3Key, _storage.KeyPrefix, kitchenSlug, $"{dish.Slug}.webp");

        var imageResult = await _images.EnsureImageAsync(
            s3Key,
            dish.ImageQuery,
            "landscape",
            existingDish?.ImageUrls.FirstOrDefault(),
            report,
            cancellationToken);

        if (imageResult.Status == ImagePipeline.ImageUploadStatus.Failed)
            s3Key = ImagePipeline.DefaultFoodKey;

        item.ImageUrls = [_images.ResolveStoredUrl(s3Key)];

        var upsert = await _upserter.UpsertFoodMenuItemAsync(item, cancellationToken);
        if (upsert.Action == MarketplaceUpserter.UpsertAction.Created)
            report.DishesCreated++;
        else
            report.DishesUpdated++;
    }
}

public sealed class SeedRunOptions
{
    public int? Limit { get; init; }

    public string? SeedFilePath { get; init; }
}
