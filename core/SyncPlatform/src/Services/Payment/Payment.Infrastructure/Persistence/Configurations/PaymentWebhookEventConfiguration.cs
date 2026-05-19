using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class PaymentWebhookEventConfiguration : IEntityTypeConfiguration<PaymentWebhookEvent>
{
    public void Configure(EntityTypeBuilder<PaymentWebhookEvent> builder)
    {
        builder.ToTable("payment_webhook_events");

        builder.HasKey(e => e.Id);
        builder.Property(e => e.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(e => e.Provider).IsRequired().HasMaxLength(64);
        builder.Property(e => e.EventType).IsRequired().HasMaxLength(128);
        builder.Property(e => e.ErrorMessage).HasMaxLength(1024);

        // Unique per provider — prevents processing the same webhook twice
        builder.Property(e => e.ExternalEventId).IsRequired().HasMaxLength(256);
        builder.HasIndex(e => new { e.Provider, e.ExternalEventId }).IsUnique();

        // Raw webhook payload for debugging and replay
        builder.Property(e => e.PayloadJson).HasColumnType("jsonb");

        // Index for the worker that polls unprocessed events
        builder.HasIndex(e => new { e.Processed, e.RetryCount });

        builder.Property(e => e.CreatedAt).HasDefaultValueSql("now()");
    }
}
