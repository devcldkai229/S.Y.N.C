using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Payment.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddVietQrPaymentMethodAndWalletCoins : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE payment.wallets
                SET reward_coin_balance = ROUND(available_balance / 100, 4)
                WHERE reward_coin_balance = 0 AND available_balance > 0;
                """);

            migrationBuilder.Sql("""
                UPDATE payment.wallets
                SET reward_coin_balance = 10000
                WHERE reward_coin_balance = 0;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
