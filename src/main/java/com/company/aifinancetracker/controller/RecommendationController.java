package com.company.aifinancetracker.controller;

import com.company.aifinancetracker.dto.RecommendationResponse;
import com.company.aifinancetracker.dto.WhatIfRequest;
import com.company.aifinancetracker.dto.ml.MlDtos;
import com.company.aifinancetracker.service.MLServiceClient;
import com.company.aifinancetracker.service.RecommendationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/recommendations")
public class RecommendationController {

    private final RecommendationService recommendationService;
    private final MLServiceClient mlServiceClient;

    public RecommendationController(
            RecommendationService recommendationService,
            MLServiceClient mlServiceClient
    ) {
        this.recommendationService = recommendationService;
        this.mlServiceClient = mlServiceClient;
    }

    @GetMapping
    public ResponseEntity<List<RecommendationResponse>> getActive() {
        return ResponseEntity.ok(recommendationService.getActiveForCurrentUser());
    }

    @PostMapping("/refresh")
    public ResponseEntity<List<RecommendationResponse>> refresh() {
        return ResponseEntity.ok(recommendationService.refreshForCurrentUser());
    }

    @PostMapping("/{id}/dismiss")
    public ResponseEntity<Map<String, String>> dismiss(@PathVariable UUID id) {
        recommendationService.dismiss(id);
        return ResponseEntity.ok(Map.of("message", "Recommendation dismissed"));
    }

    @PostMapping("/whatif")
    public ResponseEntity<MlDtos.WhatIfResponse> whatIf(@Valid @RequestBody WhatIfRequest request) {
        return ResponseEntity.ok(recommendationService.simulateWhatIf(request));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> mlHealth() {
        boolean healthy = mlServiceClient.isHealthy();
        return ResponseEntity.status(healthy ? HttpStatus.OK : HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of("mlService", healthy ? "up" : "down"));
    }
}
