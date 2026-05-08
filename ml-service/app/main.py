from fastapi import FastAPI

from .ml import detect_anomalies, forecast_spending, simulate_what_if
from .schemas import (
    AnomalyRequest,
    AnomalyResponse,
    ForecastRequest,
    ForecastResponse,
    WhatIfRequest,
    WhatIfResponse,
)

app = FastAPI(
    title="AiFinanceTracker ML Service",
    description="Stateless ML inference service for spending forecasts, anomaly detection, and what-if simulations.",
    version="0.1.0",
)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/predict/spending", response_model=ForecastResponse)
def predict_spending(request: ForecastRequest) -> ForecastResponse:
    return forecast_spending(request.history, request.horizon_months)


@app.post("/detect/anomalies", response_model=AnomalyResponse)
def detect(request: AnomalyRequest) -> AnomalyResponse:
    return detect_anomalies(request.transactions, request.z_threshold)


@app.post("/simulate/whatif", response_model=WhatIfResponse)
def simulate(request: WhatIfRequest) -> WhatIfResponse:
    return simulate_what_if(request.history, request.cuts, request.horizon_months)
