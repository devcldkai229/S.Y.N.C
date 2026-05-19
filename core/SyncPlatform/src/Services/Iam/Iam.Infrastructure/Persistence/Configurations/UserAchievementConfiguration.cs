using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserAchievementConfiguration : IEntityTypeConfiguration<UserAchievement>
{
    public void Configure(EntityTypeBuilder<UserAchievement> builder)
    {
        builder.ToTable("user_achievements");

        builder.HasKey(ua => ua.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(ua => ua.Id).HasDefaultValueSql("gen_random_uuid()");

        // Composite unique constraint: a user can only unlock each achievement once
        builder.HasIndex(ua => new { ua.UserId, ua.AchievementId }).IsUnique();

        builder.HasOne(ua => ua.User)
               .WithMany(u => u.Achievements)
               .HasForeignKey(ua => ua.UserId)
               .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(ua => ua.Achievement)
               .WithMany(a => a.UserAchievements)
               .HasForeignKey(ua => ua.AchievementId)
               .OnDelete(DeleteBehavior.Restrict);

        builder.Property(ua => ua.CreatedAt).HasDefaultValueSql("now()");
    }
}
