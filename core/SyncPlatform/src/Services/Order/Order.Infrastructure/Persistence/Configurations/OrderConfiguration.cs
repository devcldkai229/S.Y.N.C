using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Order.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Domain.Models.Order>
{
    public void Configure(EntityTypeBuilder<Domain.Models.Order> builder)
    {
        builder.ToTable("orders");

        builder.HasKey(o => o.Id);
        builder.Property(o => o.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(o => o.DeletedAt == null);

        builder.Property(o => o.OrderCode).IsRequired().HasMaxLength(64);
        builder.HasIndex(o => o.OrderCode).IsUnique();
        builder.HasIndex(o => o.UserId);
        builder.HasIndex(o => o.PartnerId);
        builder.HasIndex(o => new { o.PartnerId, o.Status });

        builder.Property(o => o.Currency).IsRequired().HasMaxLength(8);
        builder.Property(o => o.SubtotalAmount).HasPrecision(18, 4);
        builder.Property(o => o.DeliveryFee).HasPrecision(18, 4);
        builder.Property(o => o.DiscountAmount).HasPrecision(18, 4);
        builder.Property(o => o.TotalAmount).HasPrecision(18, 4);

        builder.Property(o => o.DeliveryAddress).HasMaxLength(1024);
        builder.Property(o => o.DeliveryLat).HasPrecision(10, 7);
        builder.Property(o => o.DeliveryLng).HasPrecision(10, 7);
        builder.Property(o => o.RecipientName).HasMaxLength(256);
        builder.Property(o => o.RecipientPhone).HasMaxLength(32);
        builder.Property(o => o.Notes).HasMaxLength(1024);
        builder.Property(o => o.CancellationReason).HasMaxLength(1024);
        builder.Property(o => o.AIReasoningSnapshotJson).HasColumnType("jsonb");

        builder.HasMany(o => o.Items)
            .WithOne(i => i.Order)
            .HasForeignKey(i => i.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Property(o => o.CreatedAt).HasDefaultValueSql("now()");
    }
}
