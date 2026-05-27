using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSmartPushFieldsToUserPreference : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "allow_ai_generated_notification",
                schema: "iam",
                table: "user_preferences",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<TimeSpan>(
                name: "preferred_reminder_time",
                schema: "iam",
                table: "user_preferences",
                type: "interval",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "smart_push_enabled",
                schema: "iam",
                table: "user_preferences",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "allow_ai_generated_notification",
                schema: "iam",
                table: "user_preferences");

            migrationBuilder.DropColumn(
                name: "preferred_reminder_time",
                schema: "iam",
                table: "user_preferences");

            migrationBuilder.DropColumn(
                name: "smart_push_enabled",
                schema: "iam",
                table: "user_preferences");
        }
    }
}
