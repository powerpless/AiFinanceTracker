package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.CategorySummary;
import com.company.aifinancetracker.dto.FinancialSummary;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import io.jmix.core.FetchPlan;
import io.jmix.core.FetchPlans;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class AnalyticsService {

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final FetchPlans fetchPlans;

    public AnalyticsService(DataManager dataManager, UserContextService userContextService, FetchPlans fetchPlans) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.fetchPlans = fetchPlans;
    }

    @Transactional(readOnly = true)
    public FinancialSummary getSummary(LocalDate startDate, LocalDate endDate) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        OffsetDateTime startDateTime = startDate.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endDateTime = endDate.atTime(23, 59, 59).atOffset(ZoneOffset.UTC);

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> transactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", startDateTime)
                .parameter("endDate", endDateTime)
                .fetchPlan(fetchPlan)
                .list();

        BigDecimal totalIncome = transactions.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.INCOME))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalExpense = transactions.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.EXPENSE))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal balance = totalIncome.subtract(totalExpense);

        return new FinancialSummary(totalIncome, totalExpense, balance, startDate, endDate);
    }

    @Transactional(readOnly = true)
    public List<CategorySummary> getExpensesByCategory(LocalDate startDate, LocalDate endDate) {
        return getCategorySummaries(startDate, endDate, CategoryType.EXPENSE);
    }

    @Transactional(readOnly = true)
    public List<CategorySummary> getIncomesByCategory(LocalDate startDate, LocalDate endDate) {
        return getCategorySummaries(startDate, endDate, CategoryType.INCOME);
    }

    @Transactional(readOnly = true)
    public List<CategorySummary> getTopExpenseCategories(LocalDate startDate, LocalDate endDate, int limit) {
        List<CategorySummary> expensesByCategory = getExpensesByCategory(startDate, endDate);
        return expensesByCategory.stream()
                .sorted(Comparator.comparing(CategorySummary::getTotalAmount).reversed())
                .limit(limit)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CategorySummary> getTopIncomeCategories(LocalDate startDate, LocalDate endDate, int limit) {
        List<CategorySummary> incomesByCategory = getIncomesByCategory(startDate, endDate);
        return incomesByCategory.stream()
                .sorted(Comparator.comparing(CategorySummary::getTotalAmount).reversed())
                .limit(limit)
                .collect(Collectors.toList());
    }

    private List<CategorySummary> getCategorySummaries(LocalDate startDate, LocalDate endDate, CategoryType categoryType) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        OffsetDateTime startDateTime = startDate.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endDateTime = endDate.atTime(23, 59, 59).atOffset(ZoneOffset.UTC);

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> transactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", startDateTime)
                .parameter("endDate", endDateTime)
                .fetchPlan(fetchPlan)
                .list();

        // Filter by category type
        List<Transaction> filteredTransactions = transactions.stream()
                .filter(t -> t.getCategory().getType().equals(categoryType))
                .collect(Collectors.toList());

        // Calculate total for percentage
        BigDecimal total = filteredTransactions.stream()
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        // Group by category
        Map<UUID, List<Transaction>> groupedByCategory = filteredTransactions.stream()
                .collect(Collectors.groupingBy(t -> t.getCategory().getId()));

        List<CategorySummary> summaries = new ArrayList<>();

        for (Map.Entry<UUID, List<Transaction>> entry : groupedByCategory.entrySet()) {
            UUID categoryId = entry.getKey();
            List<Transaction> categoryTransactions = entry.getValue();

            Category category = categoryTransactions.get(0).getCategory();
            BigDecimal totalAmount = categoryTransactions.stream()
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            CategorySummary summary = new CategorySummary(
                    categoryId,
                    category.getName(),
                    category.getType(),
                    totalAmount,
                    (long) categoryTransactions.size()
            );

            // Calculate percentage
            if (total.compareTo(BigDecimal.ZERO) > 0) {
                BigDecimal percentage = totalAmount
                        .multiply(BigDecimal.valueOf(100))
                        .divide(total, 2, RoundingMode.HALF_UP);
                summary.setPercentage(percentage);
            } else {
                summary.setPercentage(BigDecimal.ZERO);
            }

            summaries.add(summary);
        }

        // Sort by total amount descending
        summaries.sort(Comparator.comparing(CategorySummary::getTotalAmount).reversed());

        return summaries;
    }

    private FetchPlan createTransactionFetchPlan() {
        return fetchPlans.builder(Transaction.class)
                .addAll(
                        "id",
                        "amount",
                        "operationDate"
                )
                .add("category", builder -> builder
                        .addAll("id", "name", "type")
                )
                .build();
    }
}
