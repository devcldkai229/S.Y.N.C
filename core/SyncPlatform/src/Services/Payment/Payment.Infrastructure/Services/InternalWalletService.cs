using Microsoft.EntityFrameworkCore;
using Payment.Application.DTOs;
using Payment.Application.Exceptions;
using Payment.Application.Services;
using Payment.Domain.Enums;
using Payment.Domain.Models;
using Payment.Infrastructure.Persistence;

namespace Payment.Infrastructure.Services;

public class InternalWalletService : IInternalWalletService
{
    private readonly PaymentDbContext _db;

    public InternalWalletService(PaymentDbContext db) => _db = db;

    public async Task<ChargeMealOrderResponseDto> ChargeMealOrderAsync(
        ChargeMealOrderRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
            return new ChargeMealOrderResponseDto { Success = false, FailureReason = "Amount must be greater than zero." };

        var wallet = await GetOrCreateWalletAsync(request.UserId, request.Currency, cancellationToken);

        if (request.IsAiInitiated && request.Amount > wallet.RemainingDailyAutoLimit)
        {
            return new ChargeMealOrderResponseDto
            {
                Success = false,
                FailureReason = "Daily auto spending limit exceeded.",
            };
        }

        if (wallet.AvailableBalance < request.Amount)
        {
            return new ChargeMealOrderResponseDto
            {
                Success = false,
                FailureReason = "Insufficient wallet balance.",
            };
        }

        var discount = 0m;
        if (request.VoucherId.HasValue)
            discount = 0m;

        var chargeAmount = request.Amount - discount;
        var balanceBefore = wallet.AvailableBalance;
        wallet.AvailableBalance -= chargeAmount;
        if (request.IsAiInitiated)
            wallet.RemainingDailyAutoLimit = Math.Max(0, wallet.RemainingDailyAutoLimit - chargeAmount);
        wallet.UpdatedAt = DateTimeOffset.UtcNow;

        var transaction = new Transaction
        {
            WalletId = wallet.Id,
            UserId = request.UserId,
            TransactionType = TransactionType.MealPurchase,
            Status = TransactionStatus.Succeeded,
            PaymentMethod = PaymentMethod.Wallet,
            Amount = chargeAmount,
            Currency = request.Currency,
            RelatedEntityType = "Order",
            RelatedEntityId = request.OrderId,
            Description = $"Meal order {request.OrderId}",
            IsAiInitiated = request.IsAiInitiated,
            ProcessedAt = DateTimeOffset.UtcNow,
            OrderCode = Random.Shared.NextInt64(100000000, 999999999),
            Provider = PaymentProvider.InternalWallet,
            SpendingAuthorizationType = request.IsAiInitiated
                ? SpendingAuthorizationType.AiAutoApproved
                : SpendingAuthorizationType.ManualApproval,
        };

        _db.Transactions.Add(transaction);
        _db.WalletLedgers.Add(new WalletLedger
        {
            WalletId = wallet.Id,
            TransactionId = transaction.Id,
            EntryType = WalletTransactionType.Debit,
            Amount = chargeAmount,
            BalanceBefore = balanceBefore,
            BalanceAfter = wallet.AvailableBalance,
        });

        await _db.SaveChangesAsync(cancellationToken);

        return new ChargeMealOrderResponseDto
        {
            Success = true,
            TransactionId = transaction.Id,
            DiscountAmount = discount,
        };
    }

    public async Task<RefundMealOrderResponseDto> RefundMealOrderAsync(
        RefundMealOrderRequestDto request,
        CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
            return new RefundMealOrderResponseDto { Success = false, FailureReason = "Amount must be greater than zero." };

        var wallet = await GetOrCreateWalletAsync(request.UserId, request.Currency, cancellationToken);
        var balanceBefore = wallet.AvailableBalance;
        wallet.AvailableBalance += request.Amount;
        wallet.UpdatedAt = DateTimeOffset.UtcNow;

        var transaction = new Transaction
        {
            WalletId = wallet.Id,
            UserId = request.UserId,
            TransactionType = TransactionType.Refund,
            Status = TransactionStatus.Refunded,
            PaymentMethod = PaymentMethod.Wallet,
            Amount = request.Amount,
            Currency = request.Currency,
            RelatedEntityType = "Order",
            RelatedEntityId = request.OrderId,
            Description = $"Refund order {request.OrderId}",
            ProcessedAt = DateTimeOffset.UtcNow,
            OrderCode = Random.Shared.NextInt64(100000000, 999999999),
            Provider = PaymentProvider.InternalWallet,
        };

        _db.Transactions.Add(transaction);
        _db.WalletLedgers.Add(new WalletLedger
        {
            WalletId = wallet.Id,
            TransactionId = transaction.Id,
            EntryType = WalletTransactionType.Refund,
            Amount = request.Amount,
            BalanceBefore = balanceBefore,
            BalanceAfter = wallet.AvailableBalance,
        });

        await _db.SaveChangesAsync(cancellationToken);

        return new RefundMealOrderResponseDto
        {
            Success = true,
            RefundTransactionId = transaction.Id,
        };
    }

    private async Task<Wallet> GetOrCreateWalletAsync(
        Guid userId,
        string currency,
        CancellationToken cancellationToken)
    {
        var wallet = await _db.Wallets.FirstOrDefaultAsync(w => w.UserId == userId, cancellationToken);
        if (wallet != null)
            return wallet;

        wallet = new Wallet
        {
            UserId = userId,
            Currency = currency,
            AvailableBalance = 1_000_000m,
            DailyAutoSpendingLimit = 500_000m,
            MonthlyAutoSpendingLimit = 5_000_000m,
            RemainingDailyAutoLimit = 500_000m,
            RemainingMonthlyAutoLimit = 5_000_000m,
            LastResetDailyLimitAt = DateTimeOffset.UtcNow,
            LastResetMonthlyLimitAt = DateTimeOffset.UtcNow,
        };
        _db.Wallets.Add(wallet);
        await _db.SaveChangesAsync(cancellationToken);
        return wallet;
    }
}
