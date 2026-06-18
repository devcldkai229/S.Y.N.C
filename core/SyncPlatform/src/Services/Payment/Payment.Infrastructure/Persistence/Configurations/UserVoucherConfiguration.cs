using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Payment.Domain.Models;

namespace Payment.Infrastructure.Persistence.Configurations;

public class UserVoucherConfiguration : IEntityTypeConfiguration<UserVoucher>
{
    public void Configure(EntityTypeBuilder<UserVoucher> builder)
    {
        builder.ToTable("user_vouchers");
        builder.HasIndex(x => new { x.UserId, x.PromotionCampaignId });
        builder.HasQueryFilter(uv => uv.DeletedAt == null);
        builder.HasOne(x => x.PromotionCampaign)
            .WithMany()
            .HasForeignKey(x => x.PromotionCampaignId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.Navigation(x => x.PromotionCampaign).IsRequired(false);
    }
}
