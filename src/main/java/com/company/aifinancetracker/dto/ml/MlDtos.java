package com.company.aifinancetracker.dto.ml;

import java.time.LocalDate;
import java.util.List;

public final class MlDtos {

    private MlDtos() {}

    public record MonthlySpend(
            String month,
            String categoryId,
            String categoryName,
            double amount
    ) {}

    public record TransactionPoint(
            String transactionId,
            String categoryId,
            String categoryName,
            double amount,
            LocalDate operationDate
    ) {}

    public record CategoryCut(
            String categoryId,
            double cutPercent
    ) {}

    public record ForecastRequest(
            List<MonthlySpend> history,
            int horizonMonths
    ) {}

    public record CategoryPrediction(
            String categoryId,
            String categoryName,
            double predictedAmount,
            String trend,
            double confidence,
            String method
    ) {}

    public record ForecastResponse(
            int horizonMonths,
            double totalPredicted,
            List<CategoryPrediction> predictions
    ) {}

    public record AnomalyRequest(
            List<TransactionPoint> transactions,
            double zThreshold
    ) {}

    public record AnomalyItem(
            String transactionId,
            String categoryId,
            String categoryName,
            double amount,
            double zScore,
            double categoryMean,
            double categoryStd,
            String severity,
            String reason
    ) {}

    public record AnomalyResponse(
            List<AnomalyItem> anomalies,
            int inspectedCount
    ) {}

    public record WhatIfRequest(
            List<MonthlySpend> history,
            List<CategoryCut> cuts,
            int horizonMonths
    ) {}

    public record WhatIfMonth(
            int monthOffset,
            double baseline,
            double withCuts,
            double savings
    ) {}

    public record WhatIfResponse(
            int horizonMonths,
            double totalBaseline,
            double totalWithCuts,
            double totalSavings,
            double savingsPercent,
            List<WhatIfMonth> monthly,
            List<String> affectedCategories
    ) {}
}
