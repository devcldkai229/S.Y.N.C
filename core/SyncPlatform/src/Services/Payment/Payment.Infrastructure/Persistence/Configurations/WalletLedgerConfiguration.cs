using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class WalletLedgerConfiguration : IEntityTypeConfiguration<WalletLedger>
{
    public void Configure(EntityTypeBuilder<WalletLedger> builder)
    {
        builder.ToTable("wallet_ledgers");

        builder.HasKey(l => l.Id);
        builder.Property(l => l.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(l => l.EntryType).HasConversion<string>().HasMaxLength(32);

        builder.Property(l => l.Amount).HasPrecision(18, 4);
        builder.Property(l => l.BalanceBefore).HasPrecision(18, 4);
        builder.Property(l => l.BalanceAfter).HasPrecision(18, 4);

        // Arbitrary key-value metadata from the processing pipeline
        builder.Property(l => l.MetadataJson).HasColumnType("jsonb");

        // Ledger entries are immutable — no soft delete, no update
        builder.Property(l => l.UpdatedAt).Metadata.SetBeforeSaveBehavior(Microsoft.EntityFrameworkCore.Metadata.PropertySaveBehavior.Ignore);
        builder.Property(l => l.UpdatedAt).Metadata.SetAfterSaveBehavior(Microsoft.EntityFrameworkCore.Metadata.PropertySaveBehavior.Ignore);

        builder.HasIndex(l => l.WalletId);
        builder.HasIndex(l => l.TransactionId);

        builder.Property(l => l.CreatedAt).HasDefaultValueSql("now()");
    }
}
