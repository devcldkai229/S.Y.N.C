using Payment.Application.DTOs;

namespace Payment.Application.Services;

public interface IAdminDashboardService
{
    Task<PaymentDashboardOverviewDto> GetOverviewAsync(DashboardQueryDto query, CancellationToken cancellationToken = default);
}
