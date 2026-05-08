package com.company.aifinancetracker.exception;

import java.math.BigDecimal;

public class BudgetExceededException extends RuntimeException {

    private final BigDecimal limit;
    private final BigDecimal current;

    public BudgetExceededException(String message, BigDecimal limit, BigDecimal current) {
        super(message);
        this.limit = limit;
        this.current = current;
    }

    public BigDecimal getLimit() {
        return limit;
    }

    public BigDecimal getCurrent() {
        return current;
    }
}
