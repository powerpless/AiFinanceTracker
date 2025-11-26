package com.company.aifinancetracker.entity;

import io.jmix.core.metamodel.datatype.EnumClass;

import org.springframework.lang.Nullable;


public enum TransactionType implements EnumClass<String> {

    INCOME("A"),
    EXPENSE("B");

    private final String id;

    TransactionType(String id) {
        this.id = id;
    }

    public String getId() {
        return id;
    }

    @Nullable
    public static TransactionType fromId(String id) {
        for (TransactionType at : TransactionType.values()) {
            if (at.getId().equals(id)) {
                return at;
            }
        }
        return null;
    }
}