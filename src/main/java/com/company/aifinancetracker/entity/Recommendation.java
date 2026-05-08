package com.company.aifinancetracker.entity;

import io.jmix.core.DeletePolicy;
import io.jmix.core.annotation.DeletedBy;
import io.jmix.core.annotation.DeletedDate;
import io.jmix.core.entity.annotation.JmixGeneratedValue;
import io.jmix.core.entity.annotation.OnDelete;
import io.jmix.core.metamodel.annotation.JmixEntity;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotNull;
import org.springframework.data.annotation.CreatedBy;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedBy;
import org.springframework.data.annotation.LastModifiedDate;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@JmixEntity
@Table(name = "RECOMMENDATION")
@Entity
public class Recommendation {

    @JmixGeneratedValue
    @Column(name = "ID", nullable = false)
    @Id
    private UUID id;

    @NotNull
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "USER_ID", nullable = false)
    @OnDelete(DeletePolicy.DENY)
    private User user;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "TYPE_", nullable = false, length = 32)
    private RecommendationType type;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(name = "STATUS_", nullable = false, length = 16)
    private RecommendationStatus status;

    @NotNull
    @Column(name = "TITLE", nullable = false, length = 255)
    private String title;

    @NotNull
    @Column(name = "MESSAGE", nullable = false, length = 1024)
    private String message;

    @Column(name = "SAVINGS_ESTIMATE", precision = 19, scale = 2)
    private BigDecimal savingsEstimate;

    @Column(name = "RELATED_CATEGORY_ID")
    private UUID relatedCategoryId;

    @Column(name = "METADATA_", length = 2048)
    private String metadata;

    @NotNull
    @Column(name = "GENERATED_DATE", nullable = false)
    private OffsetDateTime generatedDate;

    @Column(name = "VALID_UNTIL")
    private OffsetDateTime validUntil;

    @Column(name = "VERSION", nullable = false)
    @Version
    private Integer version;

    @CreatedBy
    @Column(name = "CREATED_BY")
    private String createdBy;

    @CreatedDate
    @Column(name = "CREATED_DATE")
    private OffsetDateTime createdDate;

    @LastModifiedBy
    @Column(name = "LAST_MODIFIED_BY")
    private String lastModifiedBy;

    @LastModifiedDate
    @Column(name = "LAST_MODIFIED_DATE")
    private OffsetDateTime lastModifiedDate;

    @DeletedBy
    @Column(name = "DELETED_BY")
    private String deletedBy;

    @DeletedDate
    @Column(name = "DELETED_DATE")
    private OffsetDateTime deletedDate;

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

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

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public OffsetDateTime getCreatedDate() { return createdDate; }
    public void setCreatedDate(OffsetDateTime createdDate) { this.createdDate = createdDate; }

    public String getLastModifiedBy() { return lastModifiedBy; }
    public void setLastModifiedBy(String lastModifiedBy) { this.lastModifiedBy = lastModifiedBy; }

    public OffsetDateTime getLastModifiedDate() { return lastModifiedDate; }
    public void setLastModifiedDate(OffsetDateTime lastModifiedDate) { this.lastModifiedDate = lastModifiedDate; }

    public String getDeletedBy() { return deletedBy; }
    public void setDeletedBy(String deletedBy) { this.deletedBy = deletedBy; }

    public OffsetDateTime getDeletedDate() { return deletedDate; }
    public void setDeletedDate(OffsetDateTime deletedDate) { this.deletedDate = deletedDate; }
}
