using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class BiometricHistoryConfiguration : IEntityTypeConfiguration<BiometricHistory>
{
    public void Configure(EntityTypeBuilder<BiometricHistory> builder)
    {
        builder.ToTable("biometric_history");

        builder.HasKey(b => b.Id);
        builder.Property(b => b.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.HasQueryFilter(b => b.DeletedAt == null);

        builder.Property(b => b.WeightKg).HasPrecision(5, 2);
        builder.Property(b => b.BodyFatPercentage).HasPrecision(5, 2);
        builder.Property(b => b.MuscleMassKg).HasPrecision(5, 2);
        builder.Property(b => b.Source).HasMaxLength(32);
        builder.Property(b => b.Note).HasMaxLength(500);

        builder.Property(b => b.CreatedAt).HasDefaultValueSql("now()");

        // Engine đọc chuỗi theo user + khoảng thời gian
        builder.HasIndex(b => new { b.UserId, b.RecordedAtUtc });
    }
}
