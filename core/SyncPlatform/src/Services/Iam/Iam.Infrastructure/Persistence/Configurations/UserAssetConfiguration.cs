using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserAssetConfiguration : IEntityTypeConfiguration<UserAsset>
{
    public void Configure(EntityTypeBuilder<UserAsset> builder)
    {
        builder.ToTable("user_assets");

        builder.HasKey(a => a.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(a => a.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(a => a.UnityAssetId).IsRequired().HasMaxLength(256);
        builder.Property(a => a.AssetCategory).IsRequired().HasMaxLength(64);
        builder.Property(a => a.Rarity).IsRequired().HasMaxLength(32);
        builder.Property(a => a.SourceType).IsRequired().HasMaxLength(64);

        // Freeform metadata stored as jsonb (Unity asset extra properties, etc.)
        builder.Property(a => a.Metadata).HasColumnType("jsonb");

        builder.HasIndex(a => new { a.UserId, a.UnityAssetId }).IsUnique();

        builder.Property(a => a.CreatedAt).HasDefaultValueSql("now()");
    }
}
