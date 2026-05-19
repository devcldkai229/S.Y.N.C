using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class WalletConfiguration : IEntityTypeConfiguration<Wallet>
{
    public void Configure(EntityTypeBuilder<Wallet> builder)
    {
        builder.ToTable("wallets");

        builder.HasKey(w => w.Id);
        builder.Property(w => w.Id).HasDefaultValueSql("gen_random_uuid()");

        // Each user owns exactly one wallet
        builder.HasIndex(w => w.UserId).IsUnique();

        builder.Property(w => w.Currency).IsRequired().HasMaxLength(8).HasDefaultValue("VND");

        builder.Property(w => w.AvailableBalance).HasPrecision(18, 4);
        builder.Property(w => w.LockedBalance).HasPrecision(18, 4);
        builder.Property(w => w.RewardCoinBalance).HasPrecision(18, 4);
        builder.Property(w => w.DailyAutoSpendingLimit).HasPrecision(18, 4);
        builder.Property(w => w.MonthlyAutoSpendingLimit).HasPrecision(18, 4);
        builder.Property(w => w.RemainingDailyAutoLimit).HasPrecision(18, 4);
        builder.Property(w => w.RemainingMonthlyAutoLimit).HasPrecision(18, 4);

        // 0–1 float risk score from the fraud engine
        builder.Property(w => w.RiskScore).HasColumnType("numeric(5,4)");

        builder.Property(w => w.CreatedAt).HasDefaultValueSql("now()");
        builder.HasQueryFilter(w => w.DeletedAt == null);
    }
}
