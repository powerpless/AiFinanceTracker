package com.company.aifinancetracker.dto;

import java.math.BigDecimal;
import java.util.List;

public class DashboardSummary {

    private BigDecimal currentBalance;
    private BigDecimal monthIncome;
    private BigDecimal monthExpense;
    private BigDecimal monthBalance;
    private List<CategorySummary> topExpenseCategories;
    private List<CategorySummary> topIncomeCategories;
    private Integer transactionCount;

    public BigDecimal getCurrentBalance() {
        return currentBalance;
    }

    public void setCurrentBalance(BigDecimal currentBalance) {
        this.currentBalance = currentBalance;
    }

    public BigDecimal getMonthIncome() {
        return monthIncome;
    }

    public void setMonthIncome(BigDecimal monthIncome) {
        this.monthIncome = monthIncome;
    }

    public BigDecimal getMonthExpense() {
        return monthExpense;
    }

    public void setMonthExpense(BigDecimal monthExpense) {
        this.monthExpense = monthExpense;
    }

    public BigDecimal getMonthBalance() {
        return monthBalance;
    }

    public void setMonthBalance(BigDecimal monthBalance) {
        this.monthBalance = monthBalance;
    }

    public List<CategorySummary> getTopExpenseCategories() {
        return topExpenseCategories;
    }

    public void setTopExpenseCategories(List<CategorySummary> topExpenseCategories) {
        this.topExpenseCategories = topExpenseCategories;
    }

    public List<CategorySummary> getTopIncomeCategories() {
        return topIncomeCategories;
    }

    public void setTopIncomeCategories(List<CategorySummary> topIncomeCategories) {
        this.topIncomeCategories = topIncomeCategories;
    }

    public Integer getTransactionCount() {
        return transactionCount;
    }

    public void setTransactionCount(Integer transactionCount) {
        this.transactionCount = transactionCount;
    }
}
