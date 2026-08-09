using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAiUsageQuotaToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "ai_usage_count",
                schema: "iam",
                table: "users",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "ai_usage_period_key",
                schema: "iam",
                table: "users",
                type: "character varying(7)",
                maxLength: 7,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ai_usage_count",
                schema: "iam",
                table: "users");

            migrationBuilder.DropColumn(
                name: "ai_usage_period_key",
                schema: "iam",
                table: "users");
        }
    }
}
