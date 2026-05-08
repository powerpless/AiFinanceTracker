package com.company.aifinancetracker.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public class WhatIfRequest {

    @NotEmpty(message = "At least one category cut is required")
    @Valid
    private List<CategoryCutInput> cuts;

    @Min(1) @Max(24)
    private int horizonMonths = 3;

    public List<CategoryCutInput> getCuts() { return cuts; }
    public void setCuts(List<CategoryCutInput> cuts) { this.cuts = cuts; }

    public int getHorizonMonths() { return horizonMonths; }
    public void setHorizonMonths(int horizonMonths) { this.horizonMonths = horizonMonths; }

    public static class CategoryCutInput {
        @NotNull
        private UUID categoryId;

        @NotNull
        @DecimalMin("0.0") @DecimalMax("100.0")
        private BigDecimal cutPercent;

        public UUID getCategoryId() { return categoryId; }
        public void setCategoryId(UUID categoryId) { this.categoryId = categoryId; }

        public BigDecimal getCutPercent() { return cutPercent; }
        public void setCutPercent(BigDecimal cutPercent) { this.cutPercent = cutPercent; }
    }
}
