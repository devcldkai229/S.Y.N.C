using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(u => u.Email).IsRequired().HasMaxLength(256);
        builder.HasIndex(u => u.Email).IsUnique();

        builder.Property(u => u.EmailVerificationToken).HasMaxLength(64);
        builder.HasIndex(u => u.EmailVerificationToken)
               .IsUnique()
               .HasFilter("email_verification_token IS NOT NULL");

        builder.Property(u => u.PhoneNumber).HasMaxLength(32);
        builder.HasIndex(u => u.PhoneNumber).IsUnique().HasFilter("phone_number IS NOT NULL");

        builder.Property(u => u.PasswordHash).IsRequired().HasMaxLength(512);
        builder.Property(u => u.FullName).IsRequired().HasMaxLength(256);
        builder.Property(u => u.AvatarUrl).HasMaxLength(1024);
        builder.Property(u => u.PreferredLanguage).IsRequired().HasMaxLength(8).HasDefaultValue("vi");
        builder.Property(u => u.TimeZone).IsRequired().HasMaxLength(64).HasDefaultValue("Asia/Ho_Chi_Minh");

        builder.Property(u => u.Role).HasConversion<string>().HasMaxLength(32);
        builder.Property(u => u.Status).HasConversion<string>().HasMaxLength(32);
        builder.Property(u => u.SubscriptionTier).HasConversion<string>().HasMaxLength(32);

        builder.Property(u => u.CreatedAt).HasDefaultValueSql("now()");

        // Global soft-delete query filter
        builder.HasQueryFilter(u => u.DeletedAt == null);

        // 1-1 relationships
        builder.HasOne(u => u.BiometricProfile)
               .WithOne(b => b.User)
               .HasForeignKey<BiometricProfile>(b => b.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(u => u.UserPreference)
               .WithOne(p => p.User)
               .HasForeignKey<UserPreference>(p => p.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(u => u.AIContextProfile)
               .WithOne(a => a.User)
               .HasForeignKey<AIContextProfile>(a => a.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(u => u.GamificationProfile)
               .WithOne(g => g.User)
               .HasForeignKey<GamificationProfile>(g => g.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        // 1-N relationships
        builder.HasMany(u => u.Devices)
               .WithOne(d => d.User)
               .HasForeignKey(d => d.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(u => u.Assets)
               .WithOne(a => a.User)
               .HasForeignKey(a => a.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(u => u.Achievements)
               .WithOne(a => a.User)
               .HasForeignKey(a => a.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(u => u.Vouchers)
               .WithOne(v => v.User)
               .HasForeignKey(v => v.UserId)
               .OnDelete(DeleteBehavior.Cascade);
    }
}
