using Iam.Application.DTOs;

namespace Iam.Application.Services;

public interface IAdminDashboardService
{
    Task<IamDashboardOverviewDto> GetOverviewAsync(DashboardQueryDto query, CancellationToken cancellationToken = default);
}
