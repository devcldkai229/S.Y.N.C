using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Payment.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPayosTransactionIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // text → jsonb needs an explicit USING clause in PostgreSQL.
            migrationBuilder.Sql(@"
                ALTER TABLE payment.transactions
                    ALTER COLUMN raw_provider_payload TYPE jsonb
                        USING raw_provider_payload::jsonb;
            ");

            // EF generated AlterColumn from integer → varchar but PostgreSQL requires an explicit
            // USING clause for incompatible type conversions. Existing rows store the int form of
            // the PaymentProvider enum (0 = unknown, 1 = InternalWallet, 2 = GooglePlay, 3 = PayOS).
            migrationBuilder.Sql(@"
                ALTER TABLE payment.transactions
                    ALTER COLUMN provider DROP DEFAULT,
                    ALTER COLUMN provider TYPE character varying(32)
                        USING CASE provider
                            WHEN 1 THEN 'InternalWallet'
                            WHEN 2 THEN 'GooglePlay'
                            WHEN 3 THEN 'PayOS'
                            ELSE 'InternalWallet'
                        END;
            ");

            migrationBuilder.CreateIndex(
                name: "ix_transactions_provider_order_code",
                schema: "payment",
                table: "transactions",
                columns: new[] { "provider", "order_code" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_transactions_provider_order_code",
                schema: "payment",
                table: "transactions");

            migrationBuilder.Sql(@"
                ALTER TABLE payment.transactions
                    ALTER COLUMN raw_provider_payload TYPE text
                        USING raw_provider_payload::text;
            ");

            migrationBuilder.Sql(@"
                ALTER TABLE payment.transactions
                    ALTER COLUMN provider TYPE integer
                        USING CASE provider
                            WHEN 'InternalWallet' THEN 1
                            WHEN 'GooglePlay' THEN 2
                            WHEN 'PayOS' THEN 3
                            ELSE 0
                        END;
            ");
        }
    }
}
