package com.company.aifinancetracker.exception;

public class EntityNotFoundException extends RuntimeException {

    public EntityNotFoundException(String message) {
        super(message);
    }

    public EntityNotFoundException(String entityName, Object id) {
        super(String.format("%s with id %s not found", entityName, id));
    }
}
