using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence.Configurations;

public class DeliveryTrackingConfiguration : IEntityTypeConfiguration<DeliveryTracking>
{
    public void Configure(EntityTypeBuilder<DeliveryTracking> builder)
    {
        builder.ToTable("delivery_trackings");

        builder.HasKey(t => t.Id);
        builder.Property(t => t.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(t => t.DeletedAt == null);

        builder.HasIndex(t => t.OrderId);

        builder.HasOne(t => t.Order)
            .WithMany()
            .HasForeignKey(t => t.OrderId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Property(t => t.Provider).IsRequired().HasMaxLength(64);
        builder.Property(t => t.ExternalDeliveryId).HasMaxLength(128);
        builder.Property(t => t.ShipperName).HasMaxLength(256);
        builder.Property(t => t.ShipperPhone).HasMaxLength(32);
        builder.Property(t => t.ShipperPlateNumber).HasMaxLength(32);
        builder.Property(t => t.LastKnownLat).HasPrecision(10, 7);
        builder.Property(t => t.LastKnownLng).HasPrecision(10, 7);

        builder.Property(t => t.CreatedAt).HasDefaultValueSql("now()");
    }
}
