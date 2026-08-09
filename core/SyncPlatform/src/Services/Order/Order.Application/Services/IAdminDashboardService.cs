using Order.Application.DTOs;

namespace Order.Application.Services;

public interface IAdminDashboardService
{
    Task<OrderDashboardOverviewDto> GetOverviewAsync(DashboardQueryDto query, CancellationToken cancellationToken = default);
}
