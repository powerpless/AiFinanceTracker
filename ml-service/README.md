# AiFinanceTracker ML Service

Stateless FastAPI inference service used by the Jmix backend to generate spending advice.

## Stack
- FastAPI + Uvicorn
- scikit-learn (linear regression)
- pandas / numpy (anomaly detection)
- Pydantic v2 schemas

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | Liveness probe |
| POST | `/predict/spending` | Forecast next month spend per category (linear regression on monthly history) |
| POST | `/detect/anomalies` | Flag transactions whose amount deviates from per-category mean (z-score) |
| POST | `/simulate/whatif` | Project savings if user cuts spending in chosen categories by N% |

OpenAPI UI: `http://localhost:8000/docs` once running.

## Run with Docker (recommended)

From the repo root:

```bash
docker compose up -d --build ml-service
curl http://localhost:8000/health
```

## Run locally (Python 3.10+)

```bash
cd ml-service
python -m venv .venv
.venv\Scripts\activate            # Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

> Local Python must be 3.10+ — `numpy>=2` and `pandas>=2.2` no longer support 3.8.
> If your system Python is older, use the Docker workflow above.

## Run tests

```bash
cd ml-service
pip install pytest
pytest
```

## Design notes
- The service has **no database, no auth, no user concept**. It receives aggregated data and returns predictions.
- Java backend is responsible for: authentication, authorization, data aggregation, persisting `Recommendation` entities.
- All amounts are passed as plain floats; the Java side handles `BigDecimal` rounding before/after the call.
