using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class TargetAdjustmentLogConfiguration : IEntityTypeConfiguration<TargetAdjustmentLog>
{
    public void Configure(EntityTypeBuilder<TargetAdjustmentLog> builder)
    {
        builder.ToTable("target_adjustment_logs");

        builder.HasKey(b => b.Id);
        builder.Property(b => b.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(b => b.DeletedAt == null);

        builder.Property(b => b.Trigger).HasMaxLength(32);
        builder.Property(b => b.ConfidenceLevel).HasMaxLength(32);
        builder.Property(b => b.ReasonCode).HasMaxLength(64);
        builder.Property(b => b.ReasonText).HasMaxLength(2000);
        builder.Property(b => b.AppliedMode).HasMaxLength(16);

        builder.Property(b => b.CreatedAt).HasDefaultValueSql("now()");

        builder.HasIndex(b => new { b.UserId, b.CreatedAt });
    }
}
