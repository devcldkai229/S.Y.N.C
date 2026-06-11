using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Order.Domain.Models;

namespace Order.Infrastructure.Persistence.Configurations;

public class DeliveryWebhookEventConfiguration : IEntityTypeConfiguration<DeliveryWebhookEvent>
{
    public void Configure(EntityTypeBuilder<DeliveryWebhookEvent> builder)
    {
        builder.ToTable("delivery_webhook_events");
        builder.HasKey(x => x.Id);
        builder.Property(x => x.Id).HasDefaultValueSql("gen_random_uuid()");
        builder.Property(x => x.Provider).IsRequired().HasMaxLength(64);
        builder.Property(x => x.ExternalEventId).IsRequired().HasMaxLength(256);
        builder.Property(x => x.EventType).IsRequired().HasMaxLength(128);
        builder.Property(x => x.PayloadJson).HasColumnType("jsonb");
        builder.HasIndex(x => new { x.Provider, x.ExternalEventId }).IsUnique();
        builder.Property(x => x.CreatedAt).HasDefaultValueSql("now()");
    }
}
