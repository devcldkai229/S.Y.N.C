using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Iam.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAuthFieldsToUserAndUserDevice : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "email_verification_token",
                schema: "iam",
                table: "users",
                type: "character varying(64)",
                maxLength: 64,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "is_revoked",
                schema: "iam",
                table: "user_devices",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "refresh_token_expiry_time",
                schema: "iam",
                table: "user_devices",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "refresh_token_hash",
                schema: "iam",
                table: "user_devices",
                type: "character varying(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_users_email_verification_token",
                schema: "iam",
                table: "users",
                column: "email_verification_token",
                unique: true,
                filter: "email_verification_token IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "ix_user_devices_device_id",
                schema: "iam",
                table: "user_devices",
                column: "device_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_users_email_verification_token",
                schema: "iam",
                table: "users");

            migrationBuilder.DropIndex(
                name: "ix_user_devices_device_id",
                schema: "iam",
                table: "user_devices");

            migrationBuilder.DropColumn(
                name: "email_verification_token",
                schema: "iam",
                table: "users");

            migrationBuilder.DropColumn(
                name: "is_revoked",
                schema: "iam",
                table: "user_devices");

            migrationBuilder.DropColumn(
                name: "refresh_token_expiry_time",
                schema: "iam",
                table: "user_devices");

            migrationBuilder.DropColumn(
                name: "refresh_token_hash",
                schema: "iam",
                table: "user_devices");
        }
    }
}
