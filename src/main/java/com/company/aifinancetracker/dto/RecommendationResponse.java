package com.company.aifinancetracker.dto;

import com.company.aifinancetracker.entity.RecommendationStatus;
import com.company.aifinancetracker.entity.RecommendationType;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class RecommendationResponse {

    private UUID id;
    private RecommendationType type;
    private RecommendationStatus status;
    private String title;
    private String message;
    private BigDecimal savingsEstimate;
    private UUID relatedCategoryId;
    private String metadata;
    private OffsetDateTime generatedDate;
    private OffsetDateTime validUntil;

    public RecommendationResponse() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public RecommendationType getType() { return type; }
    public void setType(RecommendationType type) { this.type = type; }

    public RecommendationStatus getStatus() { return status; }
    public void setStatus(RecommendationStatus status) { this.status = status; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }

    public BigDecimal getSavingsEstimate() { return savingsEstimate; }
    public void setSavingsEstimate(BigDecimal savingsEstimate) { this.savingsEstimate = savingsEstimate; }

    public UUID getRelatedCategoryId() { return relatedCategoryId; }
    public void setRelatedCategoryId(UUID relatedCategoryId) { this.relatedCategoryId = relatedCategoryId; }

    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }

    public OffsetDateTime getGeneratedDate() { return generatedDate; }
    public void setGeneratedDate(OffsetDateTime generatedDate) { this.generatedDate = generatedDate; }

    public OffsetDateTime getValidUntil() { return validUntil; }
    public void setValidUntil(OffsetDateTime validUntil) { this.validUntil = validUntil; }
}
