package com.company.aifinancetracker.service;

import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
public class UserContextService {

    private final DataManager dataManager;

    public UserContextService(DataManager dataManager) {
        this.dataManager = dataManager;
    }

    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }

        String username = authentication.getName();
        List<User> users = dataManager.load(User.class)
                .query("select e from User e where e.username = :username")
                .parameter("username", username)
                .list();

        return users.isEmpty() ? null : users.get(0);
    }

    public UUID getCurrentUserId() {
        User user = getCurrentUser();
        return user != null ? user.getId() : null;
    }

    public boolean isCurrentUser(UUID userId) {
        UUID currentUserId = getCurrentUserId();
        return currentUserId != null && currentUserId.equals(userId);
    }

    public void validateUserAccess(UUID userId) {
        if (!isCurrentUser(userId)) {
            throw new SecurityException("Access denied: You can only access your own data");
        }
    }
}
