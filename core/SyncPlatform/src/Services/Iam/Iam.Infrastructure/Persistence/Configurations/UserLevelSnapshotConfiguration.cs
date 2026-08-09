using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserLevelSnapshotConfiguration : IEntityTypeConfiguration<UserLevelSnapshot>
{
    public void Configure(EntityTypeBuilder<UserLevelSnapshot> builder)
    {
        builder.ToTable("user_level_snapshots");

        builder.HasKey(b => b.Id);
        builder.Property(b => b.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(b => b.DeletedAt == null);

        builder.Property(b => b.LevelScore).HasPrecision(5, 2);
        builder.Property(b => b.ConsistencyScore).HasPrecision(5, 2);
        builder.Property(b => b.ProgressionScore).HasPrecision(5, 2);
        builder.Property(b => b.RecoveryCapacityScore).HasPrecision(5, 2);
        builder.Property(b => b.VolumeLoadWeekly).HasPrecision(12, 2);
        builder.Property(b => b.Tier).HasMaxLength(32);

        builder.Property(b => b.CreatedAt).HasDefaultValueSql("now()");

        builder.HasIndex(b => new { b.UserId, b.ComputedAt });
    }
}
