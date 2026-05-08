package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.dto.TransactionRequest;
import com.company.aifinancetracker.dto.TransactionResponse;
import com.company.aifinancetracker.service.TransactionService;
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
@RequestMapping("/api/transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @GetMapping
    public ResponseEntity<List<TransactionResponse>> getUserTransactions() {
        List<TransactionResponse> transactions = transactionService.getUserTransactions();
        return ResponseEntity.ok(transactions);
    }

    @GetMapping("/period")
    public ResponseEntity<List<TransactionResponse>> getTransactionsByPeriod(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) OffsetDateTime endDate
    ) {
        List<TransactionResponse> transactions = transactionService.getUserTransactionsByPeriod(startDate, endDate);
        return ResponseEntity.ok(transactions);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TransactionResponse> getTransaction(@PathVariable UUID id) {
        TransactionResponse transaction = transactionService.getTransactionById(id);
        return ResponseEntity.ok(transaction);
    }

    @PostMapping
    public ResponseEntity<TransactionResponse> createTransaction(@Valid @RequestBody TransactionRequest request) {
        TransactionResponse transaction = transactionService.createTransaction(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(transaction);
    }

    @PutMapping("/{id}")
    public ResponseEntity<TransactionResponse> updateTransaction(
            @PathVariable UUID id,
            @Valid @RequestBody TransactionRequest request
    ) {
        TransactionResponse transaction = transactionService.updateTransaction(id, request);
        return ResponseEntity.ok(transaction);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, String>> deleteTransaction(@PathVariable UUID id) {
        transactionService.deleteTransaction(id);
        return ResponseEntity.ok(Map.of("message", "Transaction deleted successfully"));
    }
}
