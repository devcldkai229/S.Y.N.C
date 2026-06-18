using Microsoft.EntityFrameworkCore;
using Order.Application.DTOs;
using Order.Application.Services;
using Order.Domain.Enums;
using Order.Infrastructure.Persistence;

namespace Order.Infrastructure.Services;

public class InternalOrderVerificationService : IInternalOrderVerificationService
{
    private readonly OrderDbContext _dbContext;

    public InternalOrderVerificationService(OrderDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<OrderVerificationResultDto> VerifyPurchaseAsync(
        Guid userId,
        string targetType,
        Guid targetId,
        Guid? orderId,
        CancellationToken cancellationToken = default)
    {
        var query = _dbContext.Orders
            .AsNoTracking()
            .Include(o => o.Items)
            .Where(o => o.UserId == userId && o.Status == OrderStatus.Completed);

        if (orderId.HasValue)
            query = query.Where(o => o.Id == orderId.Value);

        query = targetType.ToLowerInvariant() switch
        {
            "partner" => query.Where(o => o.PartnerId == targetId),
            "foodmenuitem" => query.Where(o => o.Items.Any(i => i.FoodMenuItemId == targetId)),
            _ => query.Where(_ => false),
        };

        var match = await query
            .OrderByDescending(o => o.CompletedAt)
            .Select(o => new { o.Id })
            .FirstOrDefaultAsync(cancellationToken);

        return new OrderVerificationResultDto
        {
            IsVerified = match != null,
            OrderId = match?.Id,
        };
    }
}
