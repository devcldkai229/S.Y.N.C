using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IPromotionCampaignService
{
    Task<IEnumerable<PromotionCampaignDto>> GetActiveCampaignsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<PromotionCampaignDto>> GetAllCampaignsAsync(bool includeInactive = true, bool includeDeleted = true, CancellationToken cancellationToken = default);
    Task<PromotionCampaignDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PromotionCampaignDto> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<PromotionCampaignDto> CreateAsync(CreatePromotionCampaignDto dto, CancellationToken cancellationToken = default);
    Task<PromotionCampaignDto> UpdateAsync(Guid id, UpdatePromotionCampaignDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, bool softDelete = true, CancellationToken cancellationToken = default);
}
