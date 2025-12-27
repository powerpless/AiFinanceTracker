package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.CategoryRequest;
import com.company.aifinancetracker.dto.CategoryResponse;
import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CategoryManagementService {

    private final DataManager dataManager;
    private final UserContextService userContextService;

    public CategoryManagementService(DataManager dataManager, UserContextService userContextService) {
        this.dataManager = dataManager;
        this.userContextService = userContextService;
    }

    
    @Transactional(readOnly = true)
    public List<CategoryResponse> getUserCategories(CategoryType type) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        List<Category> categories = dataManager.load(Category.class)
                .query("select e from Category e where e.user.id = :userId")
                .parameter("userId", currentUser.getId())
                .list();

        return categories.stream()
                .filter(c -> c.getType().equals(type))
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    
    @Transactional(readOnly = true)
    public List<CategoryResponse> getAllUserCategories() {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        List<Category> categories = dataManager.load(Category.class)
                .query("select e from Category e where e.user.id = :userId")
                .parameter("userId", currentUser.getId())
                .list();

        return categories.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    
    @Transactional(readOnly = true)
    public CategoryResponse getCategoryById(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Category category = dataManager.load(Category.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Category not found"));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Category belongs to another user");
        }

        return mapToResponse(category);
    }

    
    @Transactional
    public CategoryResponse createCategory(CategoryRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        // Проверка на дубликаты
        List<Category> existing = dataManager.load(Category.class)
                .query("select e from Category e where e.user.id = :userId and e.name = :name")
                .parameter("userId", currentUser.getId())
                .parameter("name", request.getName())
                .list();

        // Filter by type in Java
        existing = existing.stream()
                .filter(c -> c.getType().equals(request.getType()))
                .collect(Collectors.toList());

        if (!existing.isEmpty()) {
            throw new IllegalArgumentException("Category with this name already exists");
        }

        Category category = dataManager.create(Category.class);
        category.setName(request.getName());
        category.setType(request.getType());
        category.setUser(currentUser);
        category.setSystemCategory(false);

        category = dataManager.save(category);

        return mapToResponse(category);
    }

    
    @Transactional
    public CategoryResponse updateCategory(UUID id, CategoryRequest request) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Category category = dataManager.load(Category.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Category not found"));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Category belongs to another user");
        }

        if (Boolean.TRUE.equals(category.getSystemCategory())) {
            throw new IllegalArgumentException("System categories cannot be modified");
        }

        // Проверка на дубликаты при переименовании
        if (!category.getName().equals(request.getName())) {
            List<Category> existing = dataManager.load(Category.class)
                    .query("select e from Category e where e.user.id = :userId and e.name = :name and e.id <> :id")
                    .parameter("userId", currentUser.getId())
                    .parameter("name", request.getName())
                    .parameter("id", id)
                    .list();

            // Filter by type in Java
            existing = existing.stream()
                    .filter(c -> c.getType().equals(request.getType()))
                    .collect(Collectors.toList());

            if (!existing.isEmpty()) {
                throw new IllegalArgumentException("Category with this name already exists");
            }
        }

        category.setName(request.getName());
        category.setType(request.getType());

        category = dataManager.save(category);

        return mapToResponse(category);
    }

    
    @Transactional
    public void deleteCategory(UUID id) {
        User currentUser = userContextService.getCurrentUser();
        if (currentUser == null) {
            throw new SecurityException("User not authenticated");
        }

        Category category = dataManager.load(Category.class)
                .id(id)
                .optional()
                .orElseThrow(() -> new IllegalArgumentException("Category not found"));

        if (!category.getUser().getId().equals(currentUser.getId())) {
            throw new SecurityException("Access denied: Category belongs to another user");
        }

        if (Boolean.TRUE.equals(category.getSystemCategory())) {
            throw new IllegalArgumentException("System categories cannot be deleted");
        }

        dataManager.remove(category);
    }

    private CategoryResponse mapToResponse(Category category) {
        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getType(),
                category.getSystemCategory()
        );
    }
}
