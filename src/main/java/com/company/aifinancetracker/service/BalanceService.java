package com.company.aifinancetracker.service;

import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;

@Service
public class BalanceService {

    private static final OffsetDateTime BEGINNING_OF_TIME =
            OffsetDateTime.of(2000, 1, 1, 0, 0, 0, 0, ZoneOffset.UTC);

    private final DataManager dataManager;

    public BalanceService(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    @Transactional(readOnly = true)
    public BigDecimal calculateBalance(User user) {
        return calculateBalance(user, null);
    }

    @Transactional(readOnly = true)
    public BigDecimal calculateBalance(User user, UUID excludeTransactionId) {
        List<Transaction> all = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate")
                .parameter("userId", user.getId())
                .parameter("startDate", BEGINNING_OF_TIME)
                .list();

        BigDecimal income = BigDecimal.ZERO;
        BigDecimal expense = BigDecimal.ZERO;
        for (Transaction t : all) {
            if (excludeTransactionId != null && excludeTransactionId.equals(t.getId())) continue;
            if (t.getCategory() == null || t.getCategory().getType() == null) continue;
            BigDecimal amount = t.getAmount() != null ? t.getAmount() : BigDecimal.ZERO;
            if (CategoryType.INCOME.equals(t.getCategory().getType())) {
                income = income.add(amount);
            } else if (CategoryType.EXPENSE.equals(t.getCategory().getType())) {
                expense = expense.add(amount);
            }
        }
        return income.subtract(expense);
    }

    public void assertCanCreateExpense(User user, BigDecimal amount) {
        BigDecimal balance = calculateBalance(user);
        if (balance.compareTo(amount) < 0) {
            throw new IllegalArgumentException(String.format(
                    "Insufficient funds: current balance is %s, expense amount is %s. Add income first.",
                    balance, amount
            ));
        }
    }

    public void assertCanUpdateExpense(User user, UUID transactionId, BigDecimal newAmount) {
        BigDecimal balanceWithoutThis = calculateBalance(user, transactionId);
        if (balanceWithoutThis.compareTo(newAmount) < 0) {
            throw new IllegalArgumentException(String.format(
                    "Insufficient funds: balance excluding this transaction is %s, new expense amount is %s.",
                    balanceWithoutThis, newAmount
            ));
        }
    }
}
