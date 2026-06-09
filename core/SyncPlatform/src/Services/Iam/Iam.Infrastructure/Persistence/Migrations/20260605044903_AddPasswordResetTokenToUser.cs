using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordResetTokenToUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "password_reset_token",
                schema: "iam",
                table: "users",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "password_reset_token_expires_at",
                schema: "iam",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "password_reset_token",
                schema: "iam",
                table: "users");

            migrationBuilder.DropColumn(
                name: "password_reset_token_expires_at",
                schema: "iam",
                table: "users");
        }
    }
}
