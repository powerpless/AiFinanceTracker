package com.company.aifinancetracker.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    private static final String BEARER_SCHEME = "bearerAuth";

    @Bean
    public OpenAPI aiFinanceTrackerOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("AiFinanceTracker API")
                        .version("0.0.4")
                        .description("REST API for the AiFinanceTracker thesis project: " +
                                "auth, income/expense tracking, budgets, dashboard analytics, " +
                                "and ML recommendations (forecast, anomaly, what-if).")
                        .license(new License().name("Educational use")))
                .components(new Components()
                        .addSecuritySchemes(BEARER_SCHEME, new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Paste the access_token returned by /api/auth/login")))
                .addSecurityItem(new SecurityRequirement().addList(BEARER_SCHEME));
    }
}
