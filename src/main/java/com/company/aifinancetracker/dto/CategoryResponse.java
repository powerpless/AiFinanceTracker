package com.company.aifinancetracker.dto;

import com.company.aifinancetracker.entity.CategoryType;

import java.util.UUID;

public class CategoryResponse {

    private UUID id;
    private String name;
    private CategoryType type;
    private Boolean systemCategory;

    public CategoryResponse() {
    }

    public CategoryResponse(UUID id, String name, CategoryType type, Boolean systemCategory) {
        this.id = id;
        this.name = name;
        this.type = type;
        this.systemCategory = systemCategory;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public CategoryType getType() {
        return type;
    }

    public void setType(CategoryType type) {
        this.type = type;
    }

    public Boolean getSystemCategory() {
        return systemCategory;
    }

    public void setSystemCategory(Boolean systemCategory) {
        this.systemCategory = systemCategory;
    }
}
