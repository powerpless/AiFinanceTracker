package com.company.aifinancetracker.entity;

import io.jmix.core.metamodel.datatype.EnumClass;
import org.springframework.lang.Nullable;

public enum RecommendationType implements EnumClass<String> {

    TREND_FORECAST("TREND_FORECAST"),
    ANOMALY("ANOMALY"),
    SAVINGS_TIP("SAVINGS_TIP");

    private final String id;

    RecommendationType(String id) {
        this.id = id;
    }

    @Override
    public String getId() {
        return id;
    }

    @Nullable
    public static RecommendationType fromId(String id) {
        for (RecommendationType t : RecommendationType.values()) {
            if (t.getId().equals(id)) {
                return t;
            }
        }
        return null;
    }
}
