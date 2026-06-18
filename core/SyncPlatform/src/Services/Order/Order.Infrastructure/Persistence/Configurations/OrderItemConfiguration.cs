using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence.Configurations;

public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable("order_items");

        builder.HasKey(i => i.Id);
        builder.Property(i => i.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(i => i.DeletedAt == null);

        builder.Property(i => i.NameSnapshot).IsRequired().HasMaxLength(512);
        builder.Property(i => i.ImageUrlSnapshot).HasMaxLength(1024);
        builder.Property(i => i.UnitPrice).HasPrecision(18, 4);
        builder.Property(i => i.Subtotal).HasPrecision(18, 4);
        builder.Property(i => i.Notes).HasMaxLength(512);

        builder.Property(i => i.CreatedAt).HasDefaultValueSql("now()");
    }
}
