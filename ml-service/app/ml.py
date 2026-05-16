from collections import defaultdict
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression

from .schemas import (
    AnomalyItem,
    AnomalyResponse,
    CategoryCut,
    CategoryPrediction,
    ForecastResponse,
    MonthlySpend,
    TransactionPoint,
    WhatIfMonth,
    WhatIfResponse,
)


def _group_by_category(history: List[MonthlySpend]) -> Dict[str, List[MonthlySpend]]:
    grouped: Dict[str, List[MonthlySpend]] = defaultdict(list)
    for point in history:
        grouped[point.category_id].append(point)
    for category_id in grouped:
        grouped[category_id].sort(key=lambda p: p.month)
    return grouped


def _classify_trend(slope: float, mean_amount: float) -> str:
    if mean_amount <= 0:
        return "flat"
    relative = slope / mean_amount
    if relative > 0.05:
        return "increasing"
    if relative < -0.05:
        return "decreasing"
    return "flat"


def _predict_category(points: List[MonthlySpend], horizon_months: int) -> Tuple[float, str, float, str]:
    amounts = np.array([p.amount for p in points], dtype=float)
    n = len(amounts)

    if n == 0:
        return 0.0, "flat", 0.0, "empty"
    if n == 1:
        return float(amounts[0]), "flat", 0.3, "single_point_mean"
    if n == 2:
        mean_amount = float(np.mean(amounts))
        return mean_amount, _classify_trend(amounts[1] - amounts[0], mean_amount), 0.5, "two_point_mean"

    x = np.arange(n).reshape(-1, 1)
    y = amounts
    model = LinearRegression()
    model.fit(x, y)

    next_x = np.array([[n + horizon_months - 1]])
    predicted = float(model.predict(next_x)[0])
    predicted = max(predicted, 0.0)

    y_pred = model.predict(x)
    ss_res = float(np.sum((y - y_pred) ** 2))
    ss_tot = float(np.sum((y - np.mean(y)) ** 2))
    r2 = 1.0 - (ss_res / ss_tot) if ss_tot > 1e-9 else 0.0
    confidence = max(0.0, min(1.0, r2))

    slope = float(model.coef_[0])
    trend = _classify_trend(slope, float(np.mean(amounts)))
    return predicted, trend, confidence, "linear_regression"


def forecast_spending(history: List[MonthlySpend], horizon_months: int) -> ForecastResponse:
    grouped = _group_by_category(history)
    predictions: List[CategoryPrediction] = []
    total = 0.0

    for category_id, points in grouped.items():
        predicted, trend, confidence, method = _predict_category(points, horizon_months)
        total += predicted
        predictions.append(
            CategoryPrediction(
                category_id=category_id,
                category_name=points[0].category_name,
                predicted_amount=round(predicted, 2),
                trend=trend,
                confidence=round(confidence, 3),
                method=method,
            )
        )

    predictions.sort(key=lambda p: p.predicted_amount, reverse=True)
    return ForecastResponse(
        horizon_months=horizon_months,
        total_predicted=round(total, 2),
        predictions=predictions,
    )


def _severity(abs_z: float) -> str:
    if abs_z >= 3.5:
        return "critical"
    if abs_z >= 2.5:
        return "high"
    return "medium"


def detect_anomalies(transactions: List[TransactionPoint], z_threshold: float) -> AnomalyResponse:
    if not transactions:
        return AnomalyResponse(anomalies=[], inspected_count=0)

    df = pd.DataFrame([t.model_dump() for t in transactions])
    anomalies: List[AnomalyItem] = []

    for category_id, group in df.groupby("category_id"):
        amounts = group["amount"].astype(float).to_numpy()
        if len(amounts) < 3:
            continue

        mean = float(np.mean(amounts))
        std = float(np.std(amounts, ddof=0))
        if std < 1e-6:
            continue

        z_scores = (amounts - mean) / std
        for row_index, z in zip(group.index, z_scores):
            if abs(z) < z_threshold:
                continue
            row = df.loc[row_index]
            direction = "выше" if z > 0 else "ниже"
            ratio = float(row["amount"]) / mean if mean > 0 else 0.0
            anomalies.append(
                AnomalyItem(
                    transaction_id=str(row["transaction_id"]),
                    category_id=str(row["category_id"]),
                    category_name=str(row["category_name"]),
                    amount=float(row["amount"]),
                    z_score=round(float(z), 3),
                    category_mean=round(mean, 2),
                    category_std=round(std, 2),
                    severity=_severity(abs(float(z))),
                    reason=(
                        f"Сумма {row['amount']:.2f} {direction} среднего {mean:.2f} "
                        f"в {ratio:.1f} раза."
                    ),
                )
            )

    anomalies.sort(key=lambda a: abs(a.z_score), reverse=True)
    return AnomalyResponse(anomalies=anomalies, inspected_count=len(transactions))


def simulate_what_if(
    history: List[MonthlySpend],
    cuts: List[CategoryCut],
    horizon_months: int,
) -> WhatIfResponse:
    grouped = _group_by_category(history)
    cut_map = {c.category_id: c.cut_percent / 100.0 for c in cuts}
    affected = [cid for cid in cut_map if cid in grouped]

    monthly: List[WhatIfMonth] = []
    total_baseline = 0.0
    total_with_cuts = 0.0

    for offset in range(1, horizon_months + 1):
        baseline_month = 0.0
        with_cuts_month = 0.0
        for category_id, points in grouped.items():
            predicted, _, _, _ = _predict_category(points, offset)
            baseline_month += predicted
            cut_factor = cut_map.get(category_id, 0.0)
            with_cuts_month += predicted * (1.0 - cut_factor)

        savings = baseline_month - with_cuts_month
        monthly.append(
            WhatIfMonth(
                month_offset=offset,
                baseline=round(baseline_month, 2),
                with_cuts=round(with_cuts_month, 2),
                savings=round(savings, 2),
            )
        )
        total_baseline += baseline_month
        total_with_cuts += with_cuts_month

    total_savings = total_baseline - total_with_cuts
    savings_percent = (total_savings / total_baseline * 100.0) if total_baseline > 0 else 0.0

    return WhatIfResponse(
        horizon_months=horizon_months,
        total_baseline=round(total_baseline, 2),
        total_with_cuts=round(total_with_cuts, 2),
        total_savings=round(total_savings, 2),
        savings_percent=round(savings_percent, 2),
        monthly=monthly,
        affected_categories=affected,
    )
