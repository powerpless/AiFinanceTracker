package com.company.aifinancetracker.app;

import com.company.aifinancetracker.entity.Category;
import com.company.aifinancetracker.entity.CategoryType;
import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import io.jmix.core.security.Authenticated;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;

@Component
public class DefaultIncomeCategoriesInitializer {

    private static final Logger log = LoggerFactory.getLogger(DefaultIncomeCategoriesInitializer.class);

    private final DataManager dataManager;

    private static final List<String> DEFAULT_INCOME_CATEGORIES = Arrays.asList(
            "Заработная плата",
            "Стипендия",
            "Бизнес",
            "Проценты от вкладов",
            "Иные доходы"
    );

    public DefaultIncomeCategoriesInitializer(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    @EventListener
    @Authenticated
    @Transactional
    public void onApplicationEvent(ContextRefreshedEvent event) {
        List<User> users = dataManager.load(User.class).all().list();

        for (User user : users) {
            initializeDefaultCategoriesForUser(user);
        }
    }

    @Authenticated
    @Transactional
    public void initializeDefaultCategoriesForUser(User user) {
        for (String categoryName : DEFAULT_INCOME_CATEGORIES) {
            List<Category> existingCategories = dataManager.load(Category.class)
                    .query("select e from Category e where e.user.id = :userId and e.name = :name")
                    .parameter("userId", user.getId())
                    .parameter("name", categoryName)
                    .list();

            if (existingCategories.isEmpty()) {
                Category category = dataManager.create(Category.class);
                category.setUser(user);
                category.setName(categoryName);
                category.setType(CategoryType.INCOME);
                category.setSystemCategory(true);

                dataManager.save(category);
                log.info("Created default income category '{}' for user '{}'", categoryName, user.getUsername());
            }
        }
    }
}
