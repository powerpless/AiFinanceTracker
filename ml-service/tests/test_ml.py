from datetime import date

from app.ml import detect_anomalies, forecast_spending, simulate_what_if
from app.schemas import CategoryCut, MonthlySpend, TransactionPoint


def _make_history():
    return [
        MonthlySpend(month="2026-01", category_id="c1", category_name="Продукты", amount=10000),
        MonthlySpend(month="2026-02", category_id="c1", category_name="Продукты", amount=11000),
        MonthlySpend(month="2026-03", category_id="c1", category_name="Продукты", amount=12000),
        MonthlySpend(month="2026-04", category_id="c1", category_name="Продукты", amount=13000),
        MonthlySpend(month="2026-01", category_id="c2", category_name="Развлечения", amount=5000),
        MonthlySpend(month="2026-02", category_id="c2", category_name="Развлечения", amount=4800),
        MonthlySpend(month="2026-03", category_id="c2", category_name="Развлечения", amount=5200),
        MonthlySpend(month="2026-04", category_id="c2", category_name="Развлечения", amount=5000),
    ]


def test_forecast_detects_increasing_trend():
    response = forecast_spending(_make_history(), horizon_months=1)
    food = next(p for p in response.predictions if p.category_id == "c1")
    fun = next(p for p in response.predictions if p.category_id == "c2")

    assert food.trend == "increasing"
    assert food.predicted_amount > 13000
    assert food.method == "linear_regression"
    assert food.confidence > 0.9

    assert fun.trend == "flat"
    assert 4500 < fun.predicted_amount < 5500


def test_forecast_handles_short_series():
    history = [
        MonthlySpend(month="2026-04", category_id="c1", category_name="Прочее", amount=5000),
    ]
    response = forecast_spending(history, horizon_months=1)
    assert response.predictions[0].method == "single_point_mean"
    assert response.predictions[0].predicted_amount == 5000


def test_anomaly_flags_outlier():
    transactions = [
        TransactionPoint(transaction_id=f"t{i}", category_id="c1", category_name="Продукты",
                         amount=1000, operation_date=date(2026, 4, i + 1))
        for i in range(10)
    ]
    transactions.append(
        TransactionPoint(transaction_id="t-outlier", category_id="c1", category_name="Продукты",
                         amount=8000, operation_date=date(2026, 4, 15))
    )

    response = detect_anomalies(transactions, z_threshold=2.0)
    assert len(response.anomalies) == 1
    assert response.anomalies[0].transaction_id == "t-outlier"
    assert response.anomalies[0].severity in ("high", "critical")


def test_what_if_calculates_savings():
    history = _make_history()
    cuts = [CategoryCut(category_id="c1", cut_percent=10.0)]

    response = simulate_what_if(history, cuts, horizon_months=3)
    assert response.total_savings > 0
    assert response.savings_percent > 0
    assert "c1" in response.affected_categories
    assert len(response.monthly) == 3
    for month in response.monthly:
        assert month.with_cuts < month.baseline
