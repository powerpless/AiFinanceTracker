package com.company.aifinancetracker.exception;

import java.time.OffsetDateTime;
import java.util.Map;

public class ValidationErrorResponse {

    private String error;
    private Map<String, String> validationErrors;
    private OffsetDateTime timestamp;

    public ValidationErrorResponse(String error, Map<String, String> validationErrors) {
        this.error = error;
        this.validationErrors = validationErrors;
        this.timestamp = OffsetDateTime.now();
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public Map<String, String> getValidationErrors() {
        return validationErrors;
    }

    public void setValidationErrors(Map<String, String> validationErrors) {
        this.validationErrors = validationErrors;
    }

    public OffsetDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(OffsetDateTime timestamp) {
        this.timestamp = timestamp;
    }
}
