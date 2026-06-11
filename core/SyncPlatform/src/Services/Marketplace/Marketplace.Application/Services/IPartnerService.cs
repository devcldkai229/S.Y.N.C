using Marketplace.Application.Common;
using Marketplace.Application.DTOs;
using Marketplace.Domain.Enums;

namespace Marketplace.Application.Services;

public interface IPartnerService
{
    Task<(IReadOnlyList<PartnerDto> Items, PaginationMetadata Pagination)> SearchAsync(
        PartnerSearchRequest request,
        CancellationToken cancellationToken = default);

    Task<PartnerDetailDto> GetDetailAsync(Guid id, CancellationToken cancellationToken = default);

    Task<PartnerDto> GetMyPartnerAsync(Guid ownerUserId, CancellationToken cancellationToken = default);

    Task<PartnerDto> RegisterAsync(Guid ownerUserId, RegisterPartnerDto dto, CancellationToken cancellationToken = default);

    Task<PartnerDto> UpdateAsync(Guid ownerUserId, Guid partnerId, UpdatePartnerDto dto, CancellationToken cancellationToken = default);

    Task<PartnerDto> UpdateStatusAsync(Guid partnerId, PartnerStatus status, CancellationToken cancellationToken = default);
}
