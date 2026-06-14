using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Payment.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUserVouchersAndCampaignFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "description",
                schema: "payment",
                table: "promotion_campaigns",
                type: "character varying(1024)",
                maxLength: 1024,
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "max_discount_amount",
                schema: "payment",
                table: "promotion_campaigns",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "partner_id",
                schema: "payment",
                table: "promotion_campaigns",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "per_user_usage_limit",
                schema: "payment",
                table: "promotion_campaigns",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            migrationBuilder.CreateTable(
                name: "user_vouchers",
                schema: "payment",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    promotion_campaign_id = table.Column<Guid>(type: "uuid", nullable: false),
                    is_used = table.Column<bool>(type: "boolean", nullable: false),
                    used_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    used_on_order_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    deleted_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_user_vouchers", x => x.id);
                    table.ForeignKey(
                        name: "fk_user_vouchers_promotion_campaigns_promotion_campaign_id",
                        column: x => x.promotion_campaign_id,
                        principalSchema: "payment",
                        principalTable: "promotion_campaigns",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_user_vouchers_promotion_campaign_id",
                schema: "payment",
                table: "user_vouchers",
                column: "promotion_campaign_id");

            migrationBuilder.CreateIndex(
                name: "ix_user_vouchers_user_id_promotion_campaign_id",
                schema: "payment",
                table: "user_vouchers",
                columns: new[] { "user_id", "promotion_campaign_id" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "user_vouchers",
                schema: "payment");

            migrationBuilder.DropColumn(
                name: "description",
                schema: "payment",
                table: "promotion_campaigns");

            migrationBuilder.DropColumn(
                name: "max_discount_amount",
                schema: "payment",
                table: "promotion_campaigns");

            migrationBuilder.DropColumn(
                name: "partner_id",
                schema: "payment",
                table: "promotion_campaigns");

            migrationBuilder.DropColumn(
                name: "per_user_usage_limit",
                schema: "payment",
                table: "promotion_campaigns");
        }
    }
}
