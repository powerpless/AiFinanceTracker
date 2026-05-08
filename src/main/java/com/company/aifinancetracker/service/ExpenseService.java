package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.CategoryResponse;
import com.company.aifinancetracker.dto.ExpenseRequest;
import com.company.aifinancetracker.dto.ExpenseResponse;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.exception.AccessDeniedException;
import com.company.aifinancetracker.exception.EntityNotFoundException;
import com.company.aifinancetracker.exception.InvalidCategoryTypeException;
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
public class ExpenseService {

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final FetchPlans fetchPlans;

    public ExpenseService(DataManager dataManager, UserContextService userContextService, FetchPlans fetchPlans) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.fetchPlans = fetchPlans;
    }

    @Transactional(readOnly = true)
    public List<ExpenseResponse> getUserExpenses() {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> expenses = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId")
                .parameter("userId", currentUser.getId())
                .fetchPlan(fetchPlan)
                .list();

        return expenses.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.EXPENSE))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<ExpenseResponse> getUserExpensesByPeriod(OffsetDateTime startDate, OffsetDateTime endDate) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> expenses = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", startDate)
                .parameter("endDate", endDate)
                .fetchPlan(fetchPlan)
                .list();

        return expenses.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.EXPENSE))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public ExpenseResponse getExpenseById(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction expense = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Expense", id));

        if (!expense.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Expense belongs to another user");
        }

        if (!expense.getCategory().getType().equals(CategoryType.EXPENSE)) {
            throw new InvalidCategoryTypeException("This transaction is not an expense");
        }

        return mapToResponse(expense);
    }

    @Transactional
    public ExpenseResponse createExpense(ExpenseRequest request) {
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

        if (!category.getType().equals(CategoryType.EXPENSE)) {
            throw new InvalidCategoryTypeException("Category must be of type EXPENSE");
        }

        Transaction expense = dataManager.create(Transaction.class);
        expense.setUser(currentUser);
        expense.setCategory(category);
        expense.setAmount(request.getAmount());
        expense.setOperationDate(request.getOperationDate());
        expense.setDescription(request.getDescription());

        expense = dataManager.save(expense);

        FetchPlan fetchPlan = createTransactionFetchPlan();
        expense = dataManager.load(Transaction.class)
                .id(expense.getId())
                .fetchPlan(fetchPlan)
                .one();

        return mapToResponse(expense);
    }

    @Transactional
    public ExpenseResponse updateExpense(UUID id, ExpenseRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction expense = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Expense", id));

        if (!expense.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Expense belongs to another user");
        }

        if (!expense.getCategory().getType().equals(CategoryType.EXPENSE)) {
            throw new InvalidCategoryTypeException("This transaction is not an expense");
        }

        Category category = dataManager.load(Category.class)
                .id(request.getCategoryId())
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Category", request.getCategoryId()));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Category belongs to another user");
        }

        if (!category.getType().equals(CategoryType.EXPENSE)) {
            throw new InvalidCategoryTypeException("Category must be of type EXPENSE");
        }

        expense.setCategory(category);
        expense.setAmount(request.getAmount());
        expense.setOperationDate(request.getOperationDate());
        expense.setDescription(request.getDescription());

        expense = dataManager.save(expense);

        return mapToResponse(expense);
    }

    @Transactional
    public void deleteExpense(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Transaction expense = dataManager.load(Transaction.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Expense", id));

        if (!expense.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Expense belongs to another user");
        }

        dataManager.remove(expense);
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

    private ExpenseResponse mapToResponse(Transaction transaction) {
        ExpenseResponse response = new ExpenseResponse();
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
