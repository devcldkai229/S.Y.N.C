using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence.Configurations;

public class OrderIdempotencyKeyConfiguration : IEntityTypeConfiguration<OrderIdempotencyKey>
{
    public void Configure(EntityTypeBuilder<OrderIdempotencyKey> builder)
    {
        builder.ToTable("order_idempotency_keys");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.ClientRequestKey).IsRequired().HasMaxLength(128);
        builder.HasIndex(x => new { x.UserId, x.ClientRequestKey }).IsUnique();
        builder.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
    }
}
