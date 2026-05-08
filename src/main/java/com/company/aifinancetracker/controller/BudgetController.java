package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.dto.BudgetRequest;
import com.company.aifinancetracker.dto.BudgetResponse;
import com.company.aifinancetracker.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/budgets")
public class BudgetController {

    private final BudgetService budgetService;

    public BudgetController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @GetMapping
    public ResponseEntity<List<BudgetResponse>> getBudgets(
            @RequestParam(required = false) Integer month,
            @RequestParam(required = false) Integer year
    ) {
        LocalDate now = LocalDate.now();
        int targetMonth = month != null ? month : now.getMonthValue();
        int targetYear = year != null ? year : now.getYear();

        List<BudgetResponse> budgets = budgetService.getUserBudgets(targetMonth, targetYear);
        return ResponseEntity.ok(budgets);
    }

    @GetMapping("/{id}")
    public ResponseEntity<BudgetResponse> getBudgetById(@PathVariable UUID id) {
        BudgetResponse budget = budgetService.getBudgetById(id);
        return ResponseEntity.ok(budget);
    }

    @PostMapping
    public ResponseEntity<BudgetResponse> createBudget(@Valid @RequestBody BudgetRequest request) {
        BudgetResponse budget = budgetService.createBudget(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(budget);
    }

    @PutMapping("/{id}")
    public ResponseEntity<BudgetResponse> updateBudget(
            @PathVariable UUID id,
            @Valid @RequestBody BudgetRequest request
    ) {
        BudgetResponse budget = budgetService.updateBudget(id, request);
        return ResponseEntity.ok(budget);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteBudget(@PathVariable UUID id) {
        budgetService.deleteBudget(id);
        return ResponseEntity.ok(Map.of("message", "Budget deleted successfully"));
    }

    @GetMapping("/alerts")
    public ResponseEntity<List<BudgetResponse>> getBudgetAlerts() {
        LocalDate now = LocalDate.now();
        List<BudgetResponse> budgets = budgetService.getUserBudgets(now.getMonthValue(), now.getYear());

        // Filter budgets that are exceeded or above 80%
        List<BudgetResponse> alerts = budgets.stream()
                .filter(b -> b.getExceeded() || b.getPercentageUsed().compareTo(java.math.BigDecimal.valueOf(80)) >= 0)
                .toList();

        return ResponseEntity.ok(alerts);
    }
}
