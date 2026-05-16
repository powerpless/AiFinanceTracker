package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.ml.MlDtos;
import com.company.aifinancetracker.entity.Recommendation;
import com.company.aifinancetracker.entity.RecommendationStatus;
import com.company.aifinancetracker.entity.RecommendationType;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Component
public class RecommendationGenerator {

    private static final double TREND_CONFIDENCE_THRESHOLD = 0.5;
    private static final double DEFAULT_SUGGESTED_CUT_PERCENT = 10.0;
    private static final int SAVINGS_HORIZON_MONTHS = 3;
    private static final int VALID_DAYS = 7;

    private final DataManager dataManager;

    public RecommendationGenerator(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    public List<Recommendation> fromForecast(User user, MlDtos.ForecastResponse forecast) {
        List<Recommendation> result = new ArrayList<>();
        if (forecast == null || forecast.predictions() == null) return result;

        for (MlDtos.CategoryPrediction p : forecast.predictions()) {
            if (!"increasing".equals(p.trend())) continue;
            if (p.confidence() < TREND_CONFIDENCE_THRESHOLD) continue;

            Recommendation r = newRecommendation(user, RecommendationType.TREND_FORECAST);
            r.setTitle(String.format("Растут расходы: %s", p.categoryName()));
            r.setMessage(String.format(
                    "По данным за прошлые месяцы прогноз расходов на категорию «%s» в следующем месяце — %.2f {currency}. " +
                    "Тренд возрастающий. Стоит проверить, что вызывает рост.",
                    p.categoryName(), p.predictedAmount()
            ));
            r.setRelatedCategoryId(parseUuid(p.categoryId()));
            r.setMetadata(String.format(Locale.ROOT,
                    "{\"predicted\":%.2f,\"confidence\":%.3f,\"method\":\"%s\",\"trend\":\"%s\"}",
                    p.predictedAmount(), p.confidence(), p.method(), p.trend()
            ));
            result.add(r);
        }
        return result;
    }

    public List<Recommendation> fromAnomalies(User user, MlDtos.AnomalyResponse anomalies) {
        List<Recommendation> result = new ArrayList<>();
        if (anomalies == null || anomalies.anomalies() == null) return result;

        for (MlDtos.AnomalyItem a : anomalies.anomalies()) {
            String severityLabel = switch (a.severity()) {
                case "critical" -> "критическая";
                case "high" -> "значимая";
                default -> "заметная";
            };

            Recommendation r = newRecommendation(user, RecommendationType.ANOMALY);
            r.setTitle(String.format("Аномальная трата: %s", a.categoryName()));
            r.setMessage(String.format(
                    "%s Это %s аномалия.",
                    a.reason(), severityLabel
            ));
            r.setRelatedCategoryId(parseUuid(a.categoryId()));
            r.setMetadata(String.format(Locale.ROOT,
                    "{\"transactionId\":\"%s\",\"zScore\":%.3f,\"mean\":%.2f,\"std\":%.2f,\"severity\":\"%s\"}",
                    a.transactionId(), a.zScore(), a.categoryMean(), a.categoryStd(), a.severity()
            ));
            result.add(r);
        }
        return result;
    }

    public List<Recommendation> fromWhatIfSuggestions(
            User user,
            MlDtos.ForecastResponse forecast,
            java.util.function.BiFunction<UUID, Double, MlDtos.WhatIfResponse> simulator
    ) {
        List<Recommendation> result = new ArrayList<>();
        if (forecast == null || forecast.predictions() == null) return result;

        List<MlDtos.CategoryPrediction> topGrowing = forecast.predictions().stream()
                .filter(p -> "increasing".equals(p.trend()))
                .filter(p -> p.confidence() >= TREND_CONFIDENCE_THRESHOLD)
                .sorted(Comparator.comparingDouble(MlDtos.CategoryPrediction::predictedAmount).reversed())
                .limit(2)
                .toList();

        for (MlDtos.CategoryPrediction p : topGrowing) {
            UUID categoryId = parseUuid(p.categoryId());
            if (categoryId == null) continue;

            MlDtos.WhatIfResponse sim = simulator.apply(categoryId, DEFAULT_SUGGESTED_CUT_PERCENT);
            if (sim == null || sim.totalSavings() <= 0) continue;

            BigDecimal savings = BigDecimal.valueOf(sim.totalSavings()).setScale(2, RoundingMode.HALF_UP);

            Recommendation r = newRecommendation(user, RecommendationType.SAVINGS_TIP);
            r.setTitle(String.format("Сэкономьте на категории «%s»", p.categoryName()));
            r.setMessage(String.format(
                    "Если урезать расходы на «%s» на %.0f%%, за %d месяца(ев) сэкономите ≈%s {currency}.",
                    p.categoryName(), DEFAULT_SUGGESTED_CUT_PERCENT, SAVINGS_HORIZON_MONTHS,
                    savings.toPlainString()
            ));
            r.setRelatedCategoryId(categoryId);
            r.setSavingsEstimate(savings);
            r.setMetadata(String.format(Locale.ROOT,
                    "{\"cutPercent\":%.1f,\"horizonMonths\":%d,\"baseline\":%.2f,\"withCuts\":%.2f}",
                    DEFAULT_SUGGESTED_CUT_PERCENT, SAVINGS_HORIZON_MONTHS,
                    sim.totalBaseline(), sim.totalWithCuts()
            ));
            result.add(r);
        }
        return result;
    }

    private Recommendation newRecommendation(User user, RecommendationType type) {
        Recommendation r = dataManager.create(Recommendation.class);
        r.setUser(user);
        r.setType(type);
        r.setStatus(RecommendationStatus.ACTIVE);
        OffsetDateTime now = OffsetDateTime.now(ZoneOffset.UTC);
        r.setGeneratedDate(now);
        r.setValidUntil(now.plusDays(VALID_DAYS));
        return r;
    }

    private UUID parseUuid(String value) {
        try {
            return value == null ? null : UUID.fromString(value);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
