package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.service.UserContextService;
import io.jmix.core.DataManager;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/transactions")
public class TransactionController {

    private final DataManager dataManager;
    private final UserContextService userContextService;

    public TransactionController(DataManager dataManager, UserContextService userContextService) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
    }

    @GetMapping
    public ResponseEntity<?> getUserTransactions() {
        try {
            User currentUser = userContextService.getCurrentUser();
            if (currentUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated"));
            }

            List<Transaction> transactions = dataManager.load(Transaction.class)
                    .query("select e from Transaction_ e where e.user.id = :userId")
                    .parameter("userId", currentUser.getId())
                    .list();

            return ResponseEntity.ok(transactions);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to fetch transactions");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTransaction(@PathVariable UUID id) {
        try {
            User currentUser = userContextService.getCurrentUser();
            if (currentUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated"));
            }

            Transaction transaction = dataManager.load(Transaction.class).id(id).optional().orElse(null);

            if (transaction == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Transaction not found"));
            }

            if (!transaction.getUser().getId().equals(currentUser.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied"));
            }

            return ResponseEntity.ok(transaction);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to fetch transaction");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping
    public ResponseEntity<?> createTransaction(@RequestBody Transaction transaction) {
        try {
            User currentUser = userContextService.getCurrentUser();
            if (currentUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated"));
            }

            transaction.setUser(currentUser);
            Transaction savedTransaction = dataManager.save(transaction);

            return ResponseEntity.status(HttpStatus.CREATED).body(savedTransaction);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to create transaction");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateTransaction(@PathVariable UUID id, @RequestBody Transaction updatedTransaction) {
        try {
            User currentUser = userContextService.getCurrentUser();
            if (currentUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated"));
            }

            Transaction existingTransaction = dataManager.load(Transaction.class).id(id).optional().orElse(null);

            if (existingTransaction == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Transaction not found"));
            }

            if (!existingTransaction.getUser().getId().equals(currentUser.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied"));
            }

            existingTransaction.setAmount(updatedTransaction.getAmount());
            existingTransaction.setDescription(updatedTransaction.getDescription());
            existingTransaction.setOperationDate(updatedTransaction.getOperationDate());
            existingTransaction.setCategory(updatedTransaction.getCategory());

            Transaction savedTransaction = dataManager.save(existingTransaction);

            return ResponseEntity.ok(savedTransaction);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to update transaction");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteTransaction(@PathVariable UUID id) {
        try {
            User currentUser = userContextService.getCurrentUser();
            if (currentUser == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of("error", "User not authenticated"));
            }

            Transaction transaction = dataManager.load(Transaction.class).id(id).optional().orElse(null);

            if (transaction == null) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", "Transaction not found"));
            }

            if (!transaction.getUser().getId().equals(currentUser.getId())) {
                return ResponseEntity.status(HttpStatus.FORBIDDEN).body(Map.of("error", "Access denied"));
            }

            dataManager.remove(transaction);

            return ResponseEntity.ok(Map.of("message", "Transaction deleted successfully"));
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Failed to delete transaction");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
}
