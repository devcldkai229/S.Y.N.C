using Microsoft.EntityFrameworkCore;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence;

public class OrderDbContext : DbContext
{
    public OrderDbContext(DbContextOptions<OrderDbContext> options) : base(options) { }

    public DbSet<Domain.Models.Order> Orders => Set<Domain.Models.Order>();

    public DbSet<OrderItem> OrderItems => Set<OrderItem>();

    public DbSet<DeliveryTracking> DeliveryTrackings => Set<DeliveryTracking>();

    public DbSet<CommissionRecord> CommissionRecords => Set<CommissionRecord>();

    public DbSet<OrderStatusHistory> OrderStatusHistories => Set<OrderStatusHistory>();

    public DbSet<OrderIdempotencyKey> OrderIdempotencyKeys => Set<OrderIdempotencyKey>();

    public DbSet<DeliveryWebhookEvent> DeliveryWebhookEvents => Set<DeliveryWebhookEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("order");
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(OrderDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}
