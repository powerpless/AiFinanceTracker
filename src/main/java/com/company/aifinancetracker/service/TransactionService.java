package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.CategoryResponse;
import com.company.aifinancetracker.dto.TransactionRequest;
import com.company.aifinancetracker.dto.TransactionResponse;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.exception.AccessDeniedException;
import com.company.aifinancetracker.exception.EntityNotFoundException;
import io.jmix.core.DataManager;
import io.jmix.core.FetchPlan;
import io.jmix.core.FetchPlanBuilder;
import io.jmix.core.FetchPlans;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final FetchPlans fetchPlans;

    public TransactionService(DataManager dataManager, UserContextService userContextService, FetchPlans fetchPlans) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.fetchPlans = fetchPlans;
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> getUserTransactions() {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> transactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId")
                .parameter("userId", currentUser.getId())
                .fetchPlan(fetchPlan)
                .list();

        return transactions.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TransactionResponse> getUserTransactionsByPeriod(OffsetDateTime startDate, OffsetDateTime endDate) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> transactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", startDate)
                .parameter("endDate", endDate)
                .fetchPlan(fetchPlan)
                .list();

        return transactions.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public TransactionResponse getTransactionById(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction transaction = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Transaction", id));

        if (!transaction.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Transaction belongs to another user");
        }

        return mapToResponse(transaction);
    }

    @Transactional
    public TransactionResponse createTransaction(TransactionRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Category category = dataManager.load(Category.class)
                .id(request.getCategoryId())
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Category", request.getCategoryId()));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Category belongs to another user");
        }

        Transaction transaction = dataManager.create(Transaction.class);
        transaction.setUser(currentUser);
        transaction.setCategory(category);
        transaction.setAmount(request.getAmount());
        transaction.setOperationDate(request.getOperationDate());
        transaction.setDescription(request.getDescription());

        transaction = dataManager.save(transaction);

        FetchPlan fetchPlan = createTransactionFetchPlan();
        transaction = dataManager.load(Transaction.class)
                .id(transaction.getId())
                .fetchPlan(fetchPlan)
                .one();

        return mapToResponse(transaction);
    }

    @Transactional
    public TransactionResponse updateTransaction(UUID id, TransactionRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction transaction = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Transaction", id));

        if (!transaction.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Transaction belongs to another user");
        }

        Category category = dataManager.load(Category.class)
                .id(request.getCategoryId())
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Category", request.getCategoryId()));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Category belongs to another user");
        }

        transaction.setCategory(category);
        transaction.setAmount(request.getAmount());
        transaction.setOperationDate(request.getOperationDate());
        transaction.setDescription(request.getDescription());

        transaction = dataManager.save(transaction);

        return mapToResponse(transaction);
    }

    @Transactional
    public void deleteTransaction(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Transaction transaction = dataManager.load(Transaction.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Transaction", id));

        if (!transaction.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Transaction belongs to another user");
        }

        dataManager.remove(transaction);
    }

    private FetchPlan createTransactionFetchPlan() {
        return fetchPlans.builder(Transaction.class)
                .addAll(
                        "id",
                        "amount",
                        "operationDate",
                        "description",
                        "createdDate",
                        "lastModifiedDate"
                )
                .add("category", FetchPlanBuilder -> FetchPlanBuilder
                        .addAll("id", "name", "type", "systemCategory")
                )
                .build();
    }

    private TransactionResponse mapToResponse(Transaction transaction) {
        TransactionResponse response = new TransactionResponse();
        response.setId(transaction.getId());
        response.setAmount(transaction.getAmount());
        response.setOperationDate(transaction.getOperationDate());
        response.setDescription(transaction.getDescription());
        response.setCreatedDate(transaction.getCreatedDate());
        response.setLastModifiedDate(transaction.getLastModifiedDate());

        if (transaction.getCategory() != null) {
            CategoryResponse categoryResponse = new CategoryResponse(
                    transaction.getCategory().getId(),
                    transaction.getCategory().getName(),
                    transaction.getCategory().getType(),
                    transaction.getCategory().getSystemCategory()
            );
            response.setCategory(categoryResponse);
        }

        return response;
    }
}
