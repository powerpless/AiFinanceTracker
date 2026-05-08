from datetime import date
from typing import List, Optional
from pydantic import BaseModel, Field


class MonthlySpend(BaseModel):
    month: str = Field(..., description="ISO yyyy-MM, e.g. '2026-04'")
    category_id: str
    category_name: str
    amount: float = Field(..., ge=0)


class TransactionPoint(BaseModel):
    transaction_id: str
    category_id: str
    category_name: str
    amount: float = Field(..., ge=0)
    operation_date: date


class CategoryCut(BaseModel):
    category_id: str
    cut_percent: float = Field(..., ge=0, le=100)


class ForecastRequest(BaseModel):
    history: List[MonthlySpend]
    horizon_months: int = Field(1, ge=1, le=12)


class CategoryPrediction(BaseModel):
    category_id: str
    category_name: str
    predicted_amount: float
    trend: str
    confidence: float
    method: str


class ForecastResponse(BaseModel):
    horizon_months: int
    total_predicted: float
    predictions: List[CategoryPrediction]


class AnomalyRequest(BaseModel):
    transactions: List[TransactionPoint]
    z_threshold: float = Field(2.0, ge=1.0, le=5.0)


class AnomalyItem(BaseModel):
    transaction_id: str
    category_id: str
    category_name: str
    amount: float
    z_score: float
    category_mean: float
    category_std: float
    severity: str
    reason: str


class AnomalyResponse(BaseModel):
    anomalies: List[AnomalyItem]
    inspected_count: int


class WhatIfRequest(BaseModel):
    history: List[MonthlySpend]
    cuts: List[CategoryCut]
    horizon_months: int = Field(3, ge=1, le=24)


class WhatIfMonth(BaseModel):
    month_offset: int
    baseline: float
    with_cuts: float
    savings: float


class WhatIfResponse(BaseModel):
    horizon_months: int
    total_baseline: float
    total_with_cuts: float
    total_savings: float
    savings_percent: float
    monthly: List[WhatIfMonth]
    affected_categories: List[str]
