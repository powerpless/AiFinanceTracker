package com.company.aifinancetracker.dto;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class TransactionResponse {

    private UUID id;
    private CategoryResponse category;
    private BigDecimal amount;
    private OffsetDateTime operationDate;
    private String description;
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

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public OffsetDateTime getOperationDate() {
        return operationDate;
    }

    public void setOperationDate(OffsetDateTime operationDate) {
        this.operationDate = operationDate;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
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
