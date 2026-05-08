package com.company.aifinancetracker.service;

import com.company.aifinancetracker.entity.User;
import io.jmix.core.DataManager;
import io.jmix.core.security.Authenticated;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class RecommendationScheduler {

    private static final Logger log = LoggerFactory.getLogger(RecommendationScheduler.class);

    private final DataManager dataManager;
    private final RecommendationService recommendationService;
    private final MLServiceClient mlClient;
    private final boolean schedulerEnabled;

    public RecommendationScheduler(
            DataManager dataManager,
            RecommendationService recommendationService,
            MLServiceClient mlClient,
            @Value("${ml.scheduler.enabled:true}") boolean schedulerEnabled
    ) {
        this.dataManager = dataManager;
        this.recommendationService = recommendationService;
        this.mlClient = mlClient;
        this.schedulerEnabled = schedulerEnabled;
    }

    @Authenticated
    @Scheduled(cron = "${ml.scheduler.cron:0 0 3 * * *}")
    public void refreshAllUsers() {
        if (!schedulerEnabled) {
            log.debug("ML scheduler disabled via config");
            return;
        }

        if (!mlClient.isHealthy()) {
            log.warn("ML service is not healthy; skipping scheduled refresh");
            return;
        }

        List<User> users = dataManager.load(User.class)
                .query("select e from User e where e.active = true")
                .list();

        log.info("Starting scheduled recommendation refresh for {} users", users.size());

        int success = 0;
        int failures = 0;
        for (User user : users) {
            try {
                recommendationService.refreshForUser(user);
                success++;
            } catch (Exception e) {
                failures++;
                log.error("Failed to refresh recommendations for user {}: {}",
                        user.getUsername(), e.getMessage());
            }
        }

        log.info("Scheduled refresh complete: {} succeeded, {} failed", success, failures);
    }
}
