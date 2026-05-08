package com.company.aifinancetracker.service;

import com.company.aifinancetracker.dto.ml.MlDtos;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class MLServiceClient {

    private static final Logger log = LoggerFactory.getLogger(MLServiceClient.class);

    private final RestClient mlRestClient;

    public MLServiceClient(@Qualifier("mlRestClient") RestClient mlRestClient) {
        this.mlRestClient = mlRestClient;
    }

    public MlDtos.ForecastResponse forecast(MlDtos.ForecastRequest request) {
        return call("/predict/spending", request, MlDtos.ForecastResponse.class);
    }

    public MlDtos.AnomalyResponse detectAnomalies(MlDtos.AnomalyRequest request) {
        return call("/detect/anomalies", request, MlDtos.AnomalyResponse.class);
    }

    public MlDtos.WhatIfResponse simulateWhatIf(MlDtos.WhatIfRequest request) {
        return call("/simulate/whatif", request, MlDtos.WhatIfResponse.class);
    }

    public boolean isHealthy() {
        try {
            mlRestClient.get().uri("/health").retrieve().toBodilessEntity();
            return true;
        } catch (RestClientException e) {
            log.warn("ML service health check failed: {}", e.getMessage());
            return false;
        }
    }

    private <T> T call(String path, Object body, Class<T> responseType) {
        try {
            return mlRestClient.post()
                    .uri(path)
                    .body(body)
                    .retrieve()
                    .body(responseType);
        } catch (RestClientException e) {
            log.error("ML service call failed for path {}: {}", path, e.getMessage());
            throw new MLServiceException("ML service call failed: " + path, e);
        }
    }

    public static class MLServiceException extends RuntimeException {
        public MLServiceException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
