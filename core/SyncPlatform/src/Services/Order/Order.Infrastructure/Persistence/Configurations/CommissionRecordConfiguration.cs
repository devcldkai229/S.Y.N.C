using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence.Configurations;

public class CommissionRecordConfiguration : IEntityTypeConfiguration<CommissionRecord>
{
    public void Configure(EntityTypeBuilder<CommissionRecord> builder)
    {
        builder.ToTable("commission_records");

        builder.HasKey(c => c.Id);
        builder.Property(c => c.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(c => c.DeletedAt == null);

        builder.HasIndex(c => c.OrderId);

        builder.Property(c => c.ClickToken).HasMaxLength(128);
        builder.Property(c => c.ExternalReferenceId).HasMaxLength(256);
        builder.Property(c => c.GrossAmount).HasPrecision(18, 4);
        builder.Property(c => c.CommissionRate).HasPrecision(8, 4);
        builder.Property(c => c.CommissionAmount).HasPrecision(18, 4);

        builder.Property(c => c.CreatedAt).HasDefaultValueSql("now()");
    }
}
