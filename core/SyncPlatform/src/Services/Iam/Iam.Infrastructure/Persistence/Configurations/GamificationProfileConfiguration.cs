using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class GamificationProfileConfiguration : IEntityTypeConfiguration<GamificationProfile>
{
    public void Configure(EntityTypeBuilder<GamificationProfile> builder)
    {
        builder.ToTable("gamification_profiles");

        builder.HasKey(g => g.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(g => g.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(g => g.SyncCoins).HasPrecision(18, 4);

        builder.Property(g => g.CreatedAt).HasDefaultValueSql("now()");
    }
}
