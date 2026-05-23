using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class TransactionConfiguration : IEntityTypeConfiguration<Transaction>
{
    public void Configure(EntityTypeBuilder<Transaction> builder)
    {
        builder.ToTable("transactions");

        builder.HasKey(t => t.Id);
        builder.Property(t => t.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(t => t.TransactionType).HasConversion<string>().HasMaxLength(64);
        builder.Property(t => t.Status).HasConversion<string>().HasMaxLength(32);
        builder.Property(t => t.PaymentMethod).HasConversion<string>().HasMaxLength(32);
        builder.Property(t => t.SpendingAuthorizationType).HasConversion<string>().HasMaxLength(32);

        builder.Property(t => t.Amount).HasPrecision(18, 4);
        builder.Property(t => t.Currency).IsRequired().HasMaxLength(8).HasDefaultValue("VND");

        builder.Property(t => t.ExternalReferenceId).HasMaxLength(256);
        builder.Property(t => t.RelatedEntityType).HasMaxLength(64);
        builder.Property(t => t.Description).HasMaxLength(1024);
        builder.Property(t => t.FailedReason).HasMaxLength(1024);

        // AI reasoning context snapshot — stored as jsonb for auditability
        builder.Property(t => t.AIReasoningSnapshotJson).HasColumnType("jsonb");

        builder.Property(t => t.Provider).HasConversion<string>().HasMaxLength(32);
        builder.Property(t => t.RawProviderPayload).HasColumnType("jsonb");

        // Indexes for common query patterns
        builder.HasIndex(t => t.UserId);
        builder.HasIndex(t => t.WalletId);
        builder.HasIndex(t => t.Status);
        builder.HasIndex(t => t.CreatedAt);

        // PayOS webhook lookup path: SELECT WHERE provider = 'PayOS' AND order_code = ?
        builder.HasIndex(t => new { t.Provider, t.OrderCode });

        builder.Property(t => t.CreatedAt).HasDefaultValueSql("now()");
    }
}
