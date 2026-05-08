package com.company.aifinancetracker.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public class FinancialSummary {

    private BigDecimal totalIncome;
    private BigDecimal totalExpense;
    private BigDecimal balance;
    private LocalDate startDate;
    private LocalDate endDate;

    public FinancialSummary() {
    }

    public FinancialSummary(BigDecimal totalIncome, BigDecimal totalExpense, BigDecimal balance, LocalDate startDate, LocalDate endDate) {
        this.totalIncome = totalIncome;
        this.totalExpense = totalExpense;
        this.balance = balance;
        this.startDate = startDate;
        this.endDate = endDate;
    }

    public BigDecimal getTotalIncome() {
        return totalIncome;
    }

    public void setTotalIncome(BigDecimal totalIncome) {
        this.totalIncome = totalIncome;
    }

    public BigDecimal getTotalExpense() {
        return totalExpense;
    }

    public void setTotalExpense(BigDecimal totalExpense) {
        this.totalExpense = totalExpense;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }
}
