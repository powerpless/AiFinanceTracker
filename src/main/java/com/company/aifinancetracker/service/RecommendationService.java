package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.RecommendationResponse;
import com.company.aifinancetracker.dto.WhatIfRequest;
import com.company.aifinancetracker.dto.ml.MlDtos;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.Recommendation;
import com.company.aifinancetracker.entity.RecommendationStatus;
import com.company.aifinancetracker.entity.Transaction;
import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.exception.AccessDeniedException;
import com.company.aifinancetracker.exception.EntityNotFoundException;
import io.jmix.core.DataManager;
import io.jmix.core.security.Authenticated;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class RecommendationService {

    private static final Logger log = LoggerFactory.getLogger(RecommendationService.class);
    private static final int HISTORY_MONTHS = 6;
    private static final double DEFAULT_Z_THRESHOLD = 1.7;
    private static final int DEFAULT_SAVINGS_HORIZON = 3;
    private static final DateTimeFormatter MONTH_KEY_FMT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final DataManager dataManager;
    private final UserContextService userContextService;
    private final MLServiceClient mlClient;
    private final RecommendationGenerator generator;

    public RecommendationService(
            DataManager dataManager,
            UserContextService userContextService,
            MLServiceClient mlClient,
            RecommendationGenerator generator
    ) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
        this.mlClient = mlClient;
        this.generator = generator;
    }

    @Transactional(readOnly = true)
    public List<RecommendationResponse> getActiveForCurrentUser() {
        User user = requireCurrentUser();
        List<Recommendation> all = dataManager.load(Recommendation.class)
                .query("select e from Recommendation e " +
                        "where e.user.id = :userId " +
                        "order by e.generatedDate desc")
                .parameter("userId", user.getId())
                .list();
        return all.stream()
                .filter(r -> RecommendationStatus.ACTIVE.equals(r.getStatus()))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public List<RecommendationResponse> refreshForCurrentUser() {
        User user = requireCurrentUser();
        return refreshForUser(user);
    }

    @Authenticated
    @Transactional
    public List<RecommendationResponse> refreshForUser(User user) {
        log.info("Refreshing recommendations for user {}", user.getUsername());

        List<Transaction> expenses = loadExpenseHistory(user);
        if (expenses.isEmpty()) {
            log.info("User {} has no expense history; skipping ML refresh", user.getUsername());
            expirePreviousRecommendations(user);
            return List.of();
        }

        List<MlDtos.MonthlySpend> monthlyHistory = aggregateMonthly(expenses);
        List<MlDtos.TransactionPoint> txPoints = expenses.stream()
                .map(this::toTransactionPoint)
                .toList();

        MlDtos.ForecastResponse forecast = mlClient.forecast(
                new MlDtos.ForecastRequest(monthlyHistory, 1)
        );
        MlDtos.AnomalyResponse anomalies = mlClient.detectAnomalies(
                new MlDtos.AnomalyRequest(txPoints, DEFAULT_Z_THRESHOLD)
        );
        log.info("ML response: forecast.predictions={}, anomalies={} (inspected={})",
                forecast.predictions() == null ? 0 : forecast.predictions().size(),
                anomalies.anomalies() == null ? 0 : anomalies.anomalies().size(),
                anomalies.inspectedCount());
        if (anomalies.anomalies() != null) {
            for (MlDtos.AnomalyItem a : anomalies.anomalies()) {
                log.info("  anomaly: txId={}, amount={}, z={}, severity={}",
                        a.transactionId(), a.amount(), a.zScore(), a.severity());
            }
        }

        expirePreviousRecommendations(user);

        List<Recommendation> generated = new ArrayList<>();
        generated.addAll(generator.fromForecast(user, forecast));
        generated.addAll(generator.fromAnomalies(user, anomalies));
        generated.addAll(generator.fromWhatIfSuggestions(user, forecast,
                (categoryId, cutPercent) -> {
                    MlDtos.WhatIfRequest req = new MlDtos.WhatIfRequest(
                            monthlyHistory,
                            List.of(new MlDtos.CategoryCut(categoryId.toString(), cutPercent)),
                            DEFAULT_SAVINGS_HORIZON
                    );
                    return mlClient.simulateWhatIf(req);
                }));

        for (Recommendation r : generated) {
            dataManager.save(r);
        }
        log.info("Generated {} recommendations for user {}", generated.size(), user.getUsername());

        return generated.stream().map(this::mapToResponse).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public MlDtos.WhatIfResponse simulateWhatIf(WhatIfRequest request) {
        User user = requireCurrentUser();
        List<Transaction> expenses = loadExpenseHistory(user);
        if (expenses.isEmpty()) {
            return new MlDtos.WhatIfResponse(
                    request.getHorizonMonths(), 0.0, 0.0, 0.0, 0.0, List.of(), List.of()
            );
        }

        List<MlDtos.MonthlySpend> monthlyHistory = aggregateMonthly(expenses);

        List<MlDtos.CategoryCut> cuts = request.getCuts().stream()
                .map(c -> new MlDtos.CategoryCut(
                        c.getCategoryId().toString(),
                        c.getCutPercent().doubleValue()))
                .toList();

        return mlClient.simulateWhatIf(new MlDtos.WhatIfRequest(monthlyHistory, cuts, request.getHorizonMonths()));
    }

    @Transactional
    public void dismiss(UUID recommendationId) {
        User user = requireCurrentUser();
        Recommendation r = dataManager.load(Recommendation.class)
                .id(recommendationId)
                .optional()
                .orElseThrow(() -> new EntityNotFoundException("Recommendation", recommendationId));

        if (!r.getUser().getId().equals(user.getId())) {
            throw new AccessDeniedException("Access denied: Recommendation belongs to another user");
        }

        r.setStatus(RecommendationStatus.DISMISSED);
        dataManager.save(r);
    }

    private void expirePreviousRecommendations(User user) {
        List<Recommendation> all = dataManager.load(Recommendation.class)
                .query("select e from Recommendation e where e.user.id = :userId")
                .parameter("userId", user.getId())
                .list();
        for (Recommendation r : all) {
            if (RecommendationStatus.ACTIVE.equals(r.getStatus())) {
                r.setStatus(RecommendationStatus.EXPIRED);
                dataManager.save(r);
            }
        }
    }

    private List<Transaction> loadExpenseHistory(User user) {
        LocalDate startMonth = LocalDate.now().withDayOfMonth(1).minusMonths(HISTORY_MONTHS - 1L);
        OffsetDateTime startDate = startMonth.atStartOfDay().atOffset(ZoneOffset.UTC);

        List<Transaction> all = dataManager.load(Transaction.class)
                .query("select e from Transaction_ e " +
                        "where e.user.id = :userId " +
                        "  and e.operationDate >= :startDate")
                .parameter("userId", user.getId())
                .parameter("startDate", startDate)
                .list();

        return all.stream()
                .filter(t -> t.getCategory() != null
                        && CategoryType.EXPENSE.equals(t.getCategory().getType()))
                .toList();
    }

    private List<MlDtos.MonthlySpend> aggregateMonthly(List<Transaction> transactions) {
        Map<String, MlDtos.MonthlySpend> bucket = new HashMap<>();

        for (Transaction t : transactions) {
            Category c = t.getCategory();
            if (c == null) continue;
            String month = YearMonth.from(t.getOperationDate()).format(MONTH_KEY_FMT);
            String key = month + "|" + c.getId();
            BigDecimal amount = t.getAmount() == null ? BigDecimal.ZERO : t.getAmount();

            MlDtos.MonthlySpend existing = bucket.get(key);
            double newAmount = (existing == null ? 0.0 : existing.amount()) + amount.doubleValue();
            bucket.put(key, new MlDtos.MonthlySpend(
                    month, c.getId().toString(), c.getName(), newAmount
            ));
        }

        return new ArrayList<>(bucket.values());
    }

    private MlDtos.TransactionPoint toTransactionPoint(Transaction t) {
        return new MlDtos.TransactionPoint(
                t.getId().toString(),
                t.getCategory().getId().toString(),
                t.getCategory().getName(),
                t.getAmount() == null ? 0.0 : t.getAmount().doubleValue(),
                t.getOperationDate().toLocalDate()
        );
    }

    private RecommendationResponse mapToResponse(Recommendation r) {
        RecommendationResponse resp = new RecommendationResponse();
        resp.setId(r.getId());
        resp.setType(r.getType());
        resp.setStatus(r.getStatus());
        resp.setTitle(r.getTitle());
        resp.setMessage(r.getMessage());
        resp.setSavingsEstimate(r.getSavingsEstimate());
        resp.setRelatedCategoryId(r.getRelatedCategoryId());
        resp.setMetadata(r.getMetadata());
        resp.setGeneratedDate(r.getGeneratedDate());
        resp.setValidUntil(r.getValidUntil());
        return resp;
    }

    private User requireCurrentUser() {
        User user = userContextService.getCurrentUser();
        if (user == null) {
            throw new SecurityException("User not authenticated");
        }
        return user;
    }
}
