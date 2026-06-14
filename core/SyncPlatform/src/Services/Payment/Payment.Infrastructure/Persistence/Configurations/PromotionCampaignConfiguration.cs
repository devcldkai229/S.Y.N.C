using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class PromotionCampaignConfiguration : IEntityTypeConfiguration<PromotionCampaign>
{
    public void Configure(EntityTypeBuilder<PromotionCampaign> builder)
    {
        builder.ToTable("promotion_campaigns");

        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(p => p.Name).IsRequired().HasMaxLength(256);
        builder.Property(p => p.Description).HasMaxLength(1024);
        builder.Property(p => p.PromotionType).HasConversion<string>().HasMaxLength(32);
        builder.Property(p => p.MaxDiscountAmount).HasPrecision(18, 2);
        builder.Property(p => p.PerUserUsageLimit).HasDefaultValue(1);

        // Coupon code is optional but must be globally unique when present
        builder.Property(p => p.CouponCode).HasMaxLength(64);
        builder.HasIndex(p => p.CouponCode).IsUnique().HasFilter("coupon_code IS NOT NULL");

        builder.Property(p => p.Value).HasPrecision(18, 2);
        builder.Property(p => p.MinimumSpend).HasPrecision(18, 2);
        builder.Property(p => p.UsageCount).HasDefaultValue(0);

        // JSON array of product category strings this campaign applies to
        builder.Property(p => p.ApplicableProductTypesJson).HasColumnType("jsonb");

        builder.HasIndex(p => new { p.IsActive, p.StartsAt, p.EndsAt });

        builder.Property(p => p.CreatedAt).HasDefaultValueSql("now()");
        builder.HasQueryFilter(p => p.DeletedAt == null);
    }
}
