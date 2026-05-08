package com.company.aifinancetracker.entity;

import io.jmix.core.metamodel.datatype.EnumClass;
import org.springframework.lang.Nullable;

public enum RecommendationStatus implements EnumClass<String> {

    ACTIVE("ACTIVE"),
    DISMISSED("DISMISSED"),
    EXPIRED("EXPIRED");

    private final String id;

    RecommendationStatus(String id) {
        this.id = id;
    }

    @Override
    public String getId() {
        return id;
    }

    @Nullable
    public static RecommendationStatus fromId(String id) {
        for (RecommendationStatus s : RecommendationStatus.values()) {
            if (s.getId().equals(id)) {
                return s;
            }
        }
        return null;
    }
}
