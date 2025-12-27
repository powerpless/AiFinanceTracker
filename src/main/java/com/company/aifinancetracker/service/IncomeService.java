package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.CategoryResponse;
import com.company.aifinancetracker.dto.IncomeRequest;
import com.company.aifinancetracker.dto.IncomeResponse;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
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
public class IncomeService {

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final FetchPlans fetchPlans;

    public IncomeService(DataManager dataManager, UserContextService userContextService, FetchPlans fetchPlans) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.fetchPlans = fetchPlans;
    }

    
    @Transactional(readOnly = true)
    public List<IncomeResponse> getUserIncomes() {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> incomes = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId")
                .parameter("userId", currentUser.getId())
                .fetchPlan(fetchPlan)
                .list();

        return incomes.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.INCOME))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    
    @Transactional(readOnly = true)
    public List<IncomeResponse> getUserIncomesByPeriod(OffsetDateTime startDate, OffsetDateTime endDate) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("Start date must be before end date");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        List<Transaction> incomes = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e where e.user.id = :userId and e.operationDate >= :startDate and e.operationDate <= :endDate")
                .parameter("userId", currentUser.getId())
                .parameter("startDate", startDate)
                .parameter("endDate", endDate)
                .fetchPlan(fetchPlan)
                .list();

        return incomes.stream()
                .filter(t -> t.getCategory().getType().equals(CategoryType.INCOME))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    
    @Transactional(readOnly = true)
    public IncomeResponse getIncomeById(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction income = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Income not found"));

        if (!income.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Income belongs to another user");
        }

        if (!income.getCategory().getType().equals(CategoryType.INCOME)) {
            throw new IllegalArgumentException("This transaction is not an income");
        }

        return mapToResponse(income);
    }

    
    @Transactional
    public IncomeResponse createIncome(IncomeRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        // Валидация категории
        Category category = dataManager.load(Category.class)
                .id(request.getCategoryId())
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Category not found"));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Category belongs to another user");
        }

        if (!category.getType().equals(CategoryType.INCOME)) {
            throw new IllegalArgumentException("Category must be of type INCOME");
        }

        Transaction income = dataManager.create(Transaction.class);
        income.setUser(currentUser);
        income.setCategory(category);
        income.setAmount(request.getAmount());
        income.setOperationDate(request.getOperationDate());
        income.setDescription(request.getDescription());

        income = dataManager.save(income);

        FetchPlan fetchPlan = createTransactionFetchPlan();
        income = dataManager.load(Transaction.class)
                .id(income.getId())
                .fetchPlan(fetchPlan)
                .one();

        return mapToResponse(income);
    }

    
    @Transactional
    public IncomeResponse updateIncome(UUID id, IncomeRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        FetchPlan fetchPlan = createTransactionFetchPlan();

        Transaction income = dataManager.load(Transaction.class)
                .id(id)
                .fetchPlan(fetchPlan)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Income not found"));

        if (!income.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Income belongs to another user");
        }

        if (!income.getCategory().getType().equals(CategoryType.INCOME)) {
            throw new IllegalArgumentException("This transaction is not an income");
        }

        // Валидация новой категории
        Category category = dataManager.load(Category.class)
                .id(request.getCategoryId())
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Category not found"));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Category belongs to another user");
        }

        if (!category.getType().equals(CategoryType.INCOME)) {
            throw new IllegalArgumentException("Category must be of type INCOME");
        }

        income.setCategory(category);
        income.setAmount(request.getAmount());
        income.setOperationDate(request.getOperationDate());
        income.setDescription(request.getDescription());

        income = dataManager.save(income);

        return mapToResponse(income);
    }

    
    @Transactional
    public void deleteIncome(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Transaction income = dataManager.load(Transaction.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Income not found"));

        if (!income.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Income belongs to another user");
        }

        dataManager.remove(income);
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

    private IncomeResponse mapToResponse(Transaction transaction) {
        IncomeResponse response = new IncomeResponse();
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
