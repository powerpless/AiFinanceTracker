package com.company.aifinancetracker.app;

import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import io.jmix.core.security.Authenticated;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class AdminUserInitializer {

    private static final Logger log = LoggerFactory.getLogger(AdminUserInitializer.class);

    private final DataManager dataManager;
    private final PasswordEncoder passwordEncoder;

    public AdminUserInitializer(DataManager dataManager, PasswordEncoder passwordEncoder) {
        this.dataManager = dataManager;
        this.passwordEncoder = passwordEncoder;
    }

    @EventListener
    @Authenticated
    public void onApplicationEvent(ContextRefreshedEvent event) {
        List<User> adminUsers = dataManager.load(User.class)
                .query("select e from User e where e.username = :username")
                .parameter("username", "admin")
                .list();

        if (adminUsers.isEmpty()) {
            createAdminUser();
        } else {
            updateAdminPassword(adminUsers.get(0));
        }
    }

    private void createAdminUser() {
        log.info("Creating admin user...");
        User admin = dataManager.create(User.class);
        admin.setUsername("admin");
        admin.setPassword(passwordEncoder.encode("admin"));
        admin.setFirstName("Admin");
        admin.setLastName("User");
        admin.setActive(true);
        dataManager.save(admin);
        log.info("Admin user created successfully");
    }

    private void updateAdminPassword(User admin) {
        String currentPassword = admin.getPassword();

        if (currentPassword != null && currentPassword.startsWith("$2a$")) {
            log.info("Admin password is already encrypted with BCrypt");
            return;
        }

        log.info("Updating admin password to BCrypt...");
        admin.setPassword(passwordEncoder.encode("admin"));
        dataManager.save(admin);
        log.info("Admin password updated successfully");
    }
}
