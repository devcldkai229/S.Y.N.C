using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class UserSubscriptionConfiguration : IEntityTypeConfiguration<UserSubscription>
{
    public void Configure(EntityTypeBuilder<UserSubscription> builder)
    {
        builder.ToTable("user_subscriptions");

        builder.HasKey(s => s.Id);
        builder.Property(s => s.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(s => s.Status).HasConversion<string>().HasMaxLength(32);
        builder.Property(s => s.CancellationReason).HasMaxLength(512);

        // A user should only have one active subscription at a time (enforced at app level,
        // partial index here guards against duplicates)
        builder.HasIndex(s => new { s.UserId, s.Status });

        builder.Property(s => s.CreatedAt).HasDefaultValueSql("now()");
        builder.HasQueryFilter(s => s.DeletedAt == null);
    }
}
