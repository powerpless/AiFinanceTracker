package com.company.aifinancetracker.service;

import com.company.aifinancetracker.entity.Category;
import io.jmix.core.DataManager;
import org.springframework.stereotype.Service;

@Service
class CategoryService {
    private final DataManager dataManager;

    public CategoryService(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    public Category create(Category category) {
        return dataManager.save(category);
    }
}
