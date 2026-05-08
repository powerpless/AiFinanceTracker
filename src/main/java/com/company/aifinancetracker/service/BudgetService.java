package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.BudgetRequest;
import com.company.aifinancetracker.dto.BudgetResponse;
import com.company.aifinancetracker.dto.CategoryResponse;
import com.company.aifinancetracker.entity.*;
import com.company.aifinancetracker.exception.AccessDeniedException;
import com.company.aifinancetracker.exception.EntityNotFoundException;
import com.company.aifinancetracker.exception.InvalidCategoryTypeException;
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
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class BudgetService {

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final FetchPlans fetchPlans;

    public BudgetService(DataManager dataManager, UserContextService userContextService, FetchPlans fetchPlans) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.fetchPlans = fetchPlans;
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> getUserBudgets(Integer month, Integer year) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createBudgetFetchPlan();

        List<Budget> budgets = dataManager.load(Budget.class)
                .query("select e from Budget e where e.user.id = :userId and e.month = :month and e.year = :year")
                .parameter("userId", currentUser.getId())
                .parameter("month", month)
                .parameter("year", year)
                .fetchPlan(fetchPlan)
                .list();

        return budgets.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public BudgetResponse getBudgetById(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createBudgetFetchPlan();

        Budget budget = dataManager.load(Budget.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Budget", id));

        if (!budget.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Budget belongs to another user");
        }

        return mapToResponse(budget);
    }

    @Transactional
    public BudgetResponse createBudget(BudgetRequest request) {
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
            throw new InvalidCategoryTypeException("Budget can only be created for EXPENSE categories");
        }

        // Check if budget already exists for this category/month/year
        List<Budget> existingBudgets = dataManager.load(Budget.class)
                .query("select e from Budget e where e.user.id = :userId and e.category.id = :categoryId and e.month = :month and e.year = :year")
                .parameter("userId", currentUser.getId())
                .parameter("categoryId", request.getCategoryId())
                .parameter("month", request.getMonth())
                .parameter("year", request.getYear())
                .list();

        if (!existingBudgets.isEmpty()) {
            throw new IllegalArgumentException("Budget already exists for this category and period");
        }

        Budget budget = dataManager.create(Budget.class);
        budget.setUser(currentUser);
        budget.setCategory(category);
        budget.setLimitAmount(request.getLimitAmount());
        budget.setMonth(request.getMonth());
        budget.setYear(request.getYear());
        budget.setAlertEnabled(request.getAlertEnabled());
        budget.setCurrentAmount(BigDecimal.ZERO);

        // Calculate current amount from existing transactions
        updateBudgetCurrentAmount(budget);

        budget = dataManager.save(budget);

        FetchPlan fetchPlan = createBudgetFetchPlan();
        budget = dataManager.load(Budget.class)
                .id(budget.getId())
                .fetchPlan(fetchPlan)
                .one();

        return mapToResponse(budget);
    }

    @Transactional
    public BudgetResponse updateBudget(UUID id, BudgetRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createBudgetFetchPlan();

        Budget budget = dataManager.load(Budget.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Budget", id));

        if (!budget.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Budget belongs to another user");
        }

        budget.setLimitAmount(request.getLimitAmount());
        budget.setAlertEnabled(request.getAlertEnabled());

        budget = dataManager.save(budget);

        return mapToResponse(budget);
    }

    @Transactional
    public void deleteBudget(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Budget budget = dataManager.load(Budget.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Budget", id));

        if (!budget.getUser().getId().equals(currentUser.getId())) {
            throw new AccessDeniedException("Access denied: Budget belongs to another user");
        }

        dataManager.remove(budget);
    }

    @Transactional
    public void updateBudgetOnExpense(Transaction expense) {
        if (expense.getCategory().getType().equals(CategoryType.EXPENSE)) {
            LocalDate expenseDate = expense.getOperationDate().toLocalDate();
            int month = expenseDate.getMonthValue();
            int year = expenseDate.getYear();

            List<Budget> budgets = dataManager.load(Budget.class)
                    .query("select e from Budget e where e.user.id = :userId and e.category.id = :categoryId and e.month = :month and e.year = :year")
                    .parameter("userId", expense.getUser().getId())
                    .parameter("categoryId", expense.getCategory().getId())
                    .parameter("month", month)
                    .parameter("year", year)
                    .list();

            for (Budget budget : budgets) {
                updateBudgetCurrentAmount(budget);
                dataManager.save(budget);
            }
        }
    }

    private void updateBudgetCurrentAmount(Budget budget) {
        LocalDate startDate = LocalDate.of(budget.getYear(), budget.getMonth(), 1);
        LocalDate endDate = startDate.withDayOfMonth(startDate.lengthOfMonth());

        OffsetDateTime startDateTime = startDate.atStartOfDay().atOffset(ZoneOffset.UTC);
        OffsetDateTime endDateTime = endDate.atTime(23, 59, 59).atOffset(ZoneOffset.UTC);

        List<Transaction> transactions = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.category.id = :categoryId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", budget.getUser().getId())
                .parameter("categoryId", budget.getCategory().getId())
                .parameter("startDate", startDateTime)
                .parameter("endDate", endDateTime)
                .list();

        BigDecimal totalAmount = transactions.stream()
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        budget.setCurrentAmount(totalAmount);
    }

    private FetchPlan createBudgetFetchPlan() {
        return fetchPlans.builder(Budget.class)
                .addAll(
                        "id",
                        "limitAmount",
                        "currentAmount",
                        "month",
                        "year",
                        "alertEnabled",
                        "createdDate",
                        "lastModifiedDate"
                )
                .add("category", builder -> builder
                        .addAll("id", "name", "type", "systemCategory")
                )
                .build();
    }

    private BudgetResponse mapToResponse(Budget budget) {
        BudgetResponse response = new BudgetResponse();
        response.setId(budget.getId());
        response.setLimitAmount(budget.getLimitAmount());
        response.setCurrentAmount(budget.getCurrentAmount());
        response.setMonth(budget.getMonth());
        response.setYear(budget.getYear());
        response.setAlertEnabled(budget.getAlertEnabled());
        response.setCreatedDate(budget.getCreatedDate());
        response.setLastModifiedDate(budget.getLastModifiedDate());

        // Calculate remaining and percentage
        BigDecimal remaining = budget.getLimitAmount().subtract(budget.getCurrentAmount());
        response.setRemainingAmount(remaining);

        if (budget.getLimitAmount().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal percentage = budget.getCurrentAmount()
                    .multiply(BigDecimal.valueOf(100))
                    .divide(budget.getLimitAmount(), 2, RoundingMode.HALF_UP);
            response.setPercentageUsed(percentage);
        } else {
            response.setPercentageUsed(BigDecimal.ZERO);
        }

        response.setExceeded(budget.getCurrentAmount().compareTo(budget.getLimitAmount()) > 0);

        if (budget.getCategory() != null) {
            CategoryResponse categoryResponse = new CategoryResponse(
                    budget.getCategory().getId(),
                    budget.getCategory().getName(),
                    budget.getCategory().getType(),
                    budget.getCategory().getSystemCategory()
            );
            response.setCategory(categoryResponse);
        }

        return response;
    }
}
