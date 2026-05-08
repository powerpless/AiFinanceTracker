package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.dto.ExpenseRequest;
import com.company.aifinancetracker.dto.ExpenseResponse;
import com.company.aifinancetracker.service.ExpenseService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/expenses")
public class ExpenseController {

    private final ExpenseService expenseService;

    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @GetMapping
    public ResponseEntity<List<ExpenseResponse>> getAllExpenses() {
        List<ExpenseResponse> expenses = expenseService.getUserExpenses();
        return ResponseEntity.ok(expenses);
    }

    @GetMapping("/period")
    public ResponseEntity<List<ExpenseResponse>> getExpensesByPeriod(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime endDate
    ) {
        List<ExpenseResponse> expenses = expenseService.getUserExpensesByPeriod(startDate, endDate);
        return ResponseEntity.ok(expenses);
    }

    @GetMapping("/{id}")
    public ResponseEntity<ExpenseResponse> getExpenseById(@PathVariable UUID id) {
        ExpenseResponse expense = expenseService.getExpenseById(id);
        return ResponseEntity.ok(expense);
    }

    @PostMapping
    public ResponseEntity<ExpenseResponse> createExpense(@Valid @RequestBody ExpenseRequest request) {
        ExpenseResponse expense = expenseService.createExpense(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(expense);
    }

    @PutMapping("/{id}")
    public ResponseEntity<ExpenseResponse> updateExpense(
            @PathVariable UUID id,
            @Valid @RequestBody ExpenseRequest request
    ) {
        ExpenseResponse expense = expenseService.updateExpense(id, request);
        return ResponseEntity.ok(expense);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteExpense(@PathVariable UUID id) {
        expenseService.deleteExpense(id);
        return ResponseEntity.ok(Map.of("message", "Expense deleted successfully"));
    }
}
