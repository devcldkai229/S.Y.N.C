using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class SubscriptionPlanConfiguration : IEntityTypeConfiguration<SubscriptionPlan>
{
    public void Configure(EntityTypeBuilder<SubscriptionPlan> builder)
    {
        builder.ToTable("subscription_plans");

        builder.HasKey(p => p.Id);
        builder.Property(p => p.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(p => p.Name).IsRequired().HasMaxLength(128);
        builder.HasIndex(p => p.Name).IsUnique();

        builder.Property(p => p.Description).HasMaxLength(512);
        builder.Property(p => p.Currency).IsRequired().HasMaxLength(8).HasDefaultValue("VND");

        builder.Property(p => p.MonthlyPrice).HasPrecision(18, 2);
        builder.Property(p => p.YearlyPrice).HasPrecision(18, 2);

        // JSON array of feature identifiers shown in UI
        builder.Property(p => p.FeaturesJson).HasColumnType("jsonb");

        builder.Property(p => p.CreatedAt).HasDefaultValueSql("now()");
        builder.HasQueryFilter(p => p.DeletedAt == null);
    }
}
