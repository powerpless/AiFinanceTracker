package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.entity.User;
import com.company.aifinancetracker.service.UserContextService;
import io.jmix.core.DataManager;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/debug")
public class DebugController {

    private final UserContextService userContextService;
    private final DataManager dataManager;

    public DebugController(UserContextService userContextService, DataManager dataManager) {
        this.userContextService = userContextService;
        this.dataManager = dataManager;
    }

    @GetMapping("/auth")
    public ResponseEntity<?> getAuthInfo() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        Map<String, Object> info = new HashMap<>();
        if (authentication == null) {
            info.put("error", "Authentication is null");
        } else {
            info.put("isAuthenticated", authentication.isAuthenticated());
            info.put("principal", authentication.getPrincipal().toString());
            info.put("name", authentication.getName());
            info.put("authorities", authentication.getAuthorities());
            info.put("details", authentication.getDetails());

            // Try to get current user
            User currentUser = userContextService.getCurrentUser();
            if (currentUser != null) {
                info.put("currentUser", Map.of(
                    "id", currentUser.getId(),
                    "username", currentUser.getUsername()
                ));
            } else {
                info.put("currentUser", "null");

                // Check if user exists in database
                String username = authentication.getName();
                List<User> users = dataManager.load(User.class)
                    .query("select e from User e where e.username = :username")
                    .parameter("username", username)
                    .list();

                info.put("usersFoundInDB", users.size());
                if (!users.isEmpty()) {
                    info.put("userInDB", Map.of(
                        "id", users.get(0).getId(),
                        "username", users.get(0).getUsername()
                    ));
                }
            }
        }

        return ResponseEntity.ok(info);
    }
}
