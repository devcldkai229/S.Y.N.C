using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class AchievementConfiguration : IEntityTypeConfiguration<Achievement>
{
    public void Configure(EntityTypeBuilder<Achievement> builder)
    {
        builder.ToTable("achievements");

        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(a => a.Code).IsRequired().HasMaxLength(64);
        builder.HasIndex(a => a.Code).IsUnique();

        builder.Property(a => a.Name).IsRequired().HasMaxLength(256);
        builder.Property(a => a.Description).IsRequired().HasMaxLength(1024);
        builder.Property(a => a.IconUrl).IsRequired().HasMaxLength(1024);

        // JSON unlocking criteria — evaluated by the gamification engine
        builder.Property(a => a.RequirementJson).HasColumnType("jsonb");

        builder.Property(a => a.CreatedAt).HasDefaultValueSql("now()");
    }
}
