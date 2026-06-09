using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.ToTable("user_devices");

        builder.HasKey(d => d.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(d => d.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(d => d.DeviceId).IsRequired().HasMaxLength(256);
        builder.Property(d => d.Platform).HasConversion<string>().HasMaxLength(32);
        builder.Property(d => d.PushToken).HasMaxLength(512);
        builder.Property(d => d.AppVersion).IsRequired().HasMaxLength(32);

        builder.Property(d => d.RefreshTokenHash).HasMaxLength(512);
        builder.Property(d => d.IsRevoked).HasDefaultValue(false);

        // One physical device can only be registered once per user
        builder.HasIndex(d => new { d.UserId, d.DeviceId }).IsUnique();
        // Lookup by DeviceId is common during refresh; help the planner
        builder.HasIndex(d => d.DeviceId);

        builder.Property(d => d.CreatedAt).HasDefaultValueSql("now()");
    }
}
