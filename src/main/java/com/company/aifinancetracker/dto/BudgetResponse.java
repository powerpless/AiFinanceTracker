package com.company.aifinancetracker.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class BudgetResponse {

    private UUID id;
    private CategoryResponse category;
    private BigDecimal limitAmount;
    private BigDecimal currentAmount;
    private Integer month;
    private Integer year;
    private Boolean alertEnabled;
    private BigDecimal remainingAmount;
    private BigDecimal percentageUsed;
    private Boolean exceeded;
    private OffsetDateTime createdDate;
    private OffsetDateTime lastModifiedDate;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public CategoryResponse getCategory() {
        return category;
    }

    public void setCategory(CategoryResponse category) {
        this.category = category;
    }

    public BigDecimal getLimitAmount() {
        return limitAmount;
    }

    public void setLimitAmount(BigDecimal limitAmount) {
        this.limitAmount = limitAmount;
    }

    public BigDecimal getCurrentAmount() {
        return currentAmount;
    }

    public void setCurrentAmount(BigDecimal currentAmount) {
        this.currentAmount = currentAmount;
    }

    public Integer getMonth() {
        return month;
    }

    public void setMonth(Integer month) {
        this.month = month;
    }

    public Integer getYear() {
        return year;
    }

    public void setYear(Integer year) {
        this.year = year;
    }

    public Boolean getAlertEnabled() {
        return alertEnabled;
    }

    public void setAlertEnabled(Boolean alertEnabled) {
        this.alertEnabled = alertEnabled;
    }

    public BigDecimal getRemainingAmount() {
        return remainingAmount;
    }

    public void setRemainingAmount(BigDecimal remainingAmount) {
        this.remainingAmount = remainingAmount;
    }

    public BigDecimal getPercentageUsed() {
        return percentageUsed;
    }

    public void setPercentageUsed(BigDecimal percentageUsed) {
        this.percentageUsed = percentageUsed;
    }

    public Boolean getExceeded() {
        return exceeded;
    }

    public void setExceeded(Boolean exceeded) {
        this.exceeded = exceeded;
    }

    public OffsetDateTime getCreatedDate() {
        return createdDate;
    }

    public void setCreatedDate(OffsetDateTime createdDate) {
        this.createdDate = createdDate;
    }

    public OffsetDateTime getLastModifiedDate() {
        return lastModifiedDate;
    }

    public void setLastModifiedDate(OffsetDateTime lastModifiedDate) {
        this.lastModifiedDate = lastModifiedDate;
    }
}
