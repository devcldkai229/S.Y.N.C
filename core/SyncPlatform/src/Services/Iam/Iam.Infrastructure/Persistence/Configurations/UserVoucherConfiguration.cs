using Iam.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Iam.Infrastructure.Persistence.Configurations;

public class UserVoucherConfiguration : IEntityTypeConfiguration<UserVoucher>
{
    public void Configure(EntityTypeBuilder<UserVoucher> builder)
    {
        builder.ToTable("user_vouchers");

        builder.HasKey(v => v.Id);

        builder.HasQueryFilter(x => x.DeletedAt == null);
        builder.Property(v => v.Id).HasDefaultValueSql("gen_random_uuid()");

        builder.Property(v => v.VoucherCode).IsRequired().HasMaxLength(64);
        builder.Property(v => v.Name).IsRequired().HasMaxLength(256);
        builder.Property(v => v.PromotionType).IsRequired().HasMaxLength(64);
        builder.Property(v => v.Status).HasConversion<string>().HasMaxLength(32);
        builder.Property(v => v.Value).HasPrecision(18, 2);

        // Voucher code is unique globally so it can be looked up quickly
        builder.HasIndex(v => v.VoucherCode).IsUnique();

        builder.Property(v => v.CreatedAt).HasDefaultValueSql("now()");
    }
}
