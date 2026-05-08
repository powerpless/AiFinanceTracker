package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.dto.CategorySummary;
import com.company.aifinancetracker.dto.DashboardSummary;
import com.company.aifinancetracker.dto.FinancialSummary;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.service.AnalyticsService;
import com.company.aifinancetracker.service.UserContextService;
import io.jmix.core.DataManager;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    private final AnalyticsService analyticsService;
    private final UserContextService userContextService;
    private final DataManager dataManager;

    public DashboardController(AnalyticsService analyticsService, UserContextService userContextService, DataManager dataManager) {
        this.analyticsService = analyticsService;
        this.userContextService = userContextService;
        this.dataManager = dataManager;
    }

    @GetMapping("/summary")
    public ResponseEntity<DashboardSummary> getDashboardSummary() {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        LocalDate now = LocalDate.now();
        LocalDate startOfMonth = now.withDayOfMonth(1);
        LocalDate endOfMonth = now.withDayOfMonth(now.lengthOfMonth());

        // Get current month summary
        FinancialSummary monthSummary = analyticsService.getSummary(startOfMonth, endOfMonth);

        // Get all-time balance
        OffsetDateTime beginningOfTime = OffsetDateTime.of(2000, 1, 1, 0, 0, 0, 0, ZoneOffset.UTC);
        List<Transaction> allTransactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", beginningOfTime)
                .list();

        BigDecimal totalIncome = BigDecimal.ZERO;
        BigDecimal totalExpense = BigDecimal.ZERO;

        for (Transaction t : allTransactions) {
            // Load category if not loaded
            if (t.getCategory() != null) {
                if (t.getCategory().getType() != null) {
                    if (t.getCategory().getType().getId().equals("INCOME")) {
                        totalIncome = totalIncome.add(t.getAmount());
                    } else if (t.getCategory().getType().getId().equals("EXPENSE")) {
                        totalExpense = totalExpense.add(t.getAmount());
                    }
                }
            }
        }

        BigDecimal currentBalance = totalIncome.subtract(totalExpense);

        // Get top categories
        List<CategorySummary> topExpenses = analyticsService.getTopExpenseCategories(startOfMonth, endOfMonth, 5);
        List<CategorySummary> topIncomes = analyticsService.getTopIncomeCategories(startOfMonth, endOfMonth, 5);

        // Count transactions
        int transactionCount = allTransactions.size();

        DashboardSummary dashboard = new DashboardSummary();
        dashboard.setCurrentBalance(currentBalance);
        dashboard.setMonthIncome(monthSummary.getTotalIncome());
        dashboard.setMonthExpense(monthSummary.getTotalExpense());
        dashboard.setMonthBalance(monthSummary.getBalance());
        dashboard.setTopExpenseCategories(topExpenses);
        dashboard.setTopIncomeCategories(topIncomes);
        dashboard.setTransactionCount(transactionCount);

        return ResponseEntity.ok(dashboard);
    }

    @GetMapping("/summary/period")
    public ResponseEntity<FinancialSummary> getSummaryByPeriod(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        FinancialSummary summary = analyticsService.getSummary(startDate, endDate);
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/expenses-by-category")
    public ResponseEntity<List<CategorySummary>> getExpensesByCategory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        List<CategorySummary> summaries = analyticsService.getExpensesByCategory(startDate, endDate);
        return ResponseEntity.ok(summaries);
    }

    @GetMapping("/incomes-by-category")
    public ResponseEntity<List<CategorySummary>> getIncomesByCategory(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        List<CategorySummary> summaries = analyticsService.getIncomesByCategory(startDate, endDate);
        return ResponseEntity.ok(summaries);
    }
}
