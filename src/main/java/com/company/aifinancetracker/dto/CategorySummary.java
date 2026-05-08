package com.company.aifinancetracker.dto;

import com.company.aifinancetracker.entity.CategoryType;

import java.math.BigDecimal;
import java.util.UUID;

public class CategorySummary {

    private UUID categoryId;
    private String categoryName;
    private CategoryType categoryType;
    private BigDecimal totalAmount;
    private Long transactionCount;
    private BigDecimal percentage;

    public CategorySummary() {
    }

    public CategorySummary(UUID categoryId, String categoryName, CategoryType categoryType, BigDecimal totalAmount, Long transactionCount) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.categoryType = categoryType;
        this.totalAmount = totalAmount;
        this.transactionCount = transactionCount;
    }

    public UUID getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(UUID categoryId) {
        this.categoryId = categoryId;
    }

    public String getCategoryName() {
        return categoryName;
    }

    public void setCategoryName(String categoryName) {
        this.categoryName = categoryName;
    }

    public CategoryType getCategoryType() {
        return categoryType;
    }

    public void setCategoryType(CategoryType categoryType) {
        this.categoryType = categoryType;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public void setTotalAmount(BigDecimal totalAmount) {
        this.totalAmount = totalAmount;
    }

    public Long getTransactionCount() {
        return transactionCount;
    }

    public void setTransactionCount(Long transactionCount) {
        this.transactionCount = transactionCount;
    }

    public BigDecimal getPercentage() {
        return percentage;
    }

    public void setPercentage(BigDecimal percentage) {
        this.percentage = percentage;
    }
}
