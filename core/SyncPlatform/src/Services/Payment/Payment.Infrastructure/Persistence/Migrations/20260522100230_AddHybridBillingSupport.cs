using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Payment.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddHybridBillingSupport : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "external_subscription_id",
                schema: "payment",
                table: "user_subscriptions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "managed_by",
                schema: "payment",
                table: "user_subscriptions",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<long>(
                name: "order_code",
                schema: "payment",
                table: "transactions",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<int>(
                name: "provider",
                schema: "payment",
                table: "transactions",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "raw_provider_payload",
                schema: "payment",
                table: "transactions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "google_play_product_id",
                schema: "payment",
                table: "subscription_plans",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "external_subscription_id",
                schema: "payment",
                table: "user_subscriptions");

            migrationBuilder.DropColumn(
                name: "managed_by",
                schema: "payment",
                table: "user_subscriptions");

            migrationBuilder.DropColumn(
                name: "order_code",
                schema: "payment",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "provider",
                schema: "payment",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "raw_provider_payload",
                schema: "payment",
                table: "transactions");

            migrationBuilder.DropColumn(
                name: "google_play_product_id",
                schema: "payment",
                table: "subscription_plans");
        }
    }
}
