# AI Finance Tracker — материалы для дипломной работы

Документ собирает ключевые технические факты по проекту: архитектуру, использованные технологии, алгоритмы, модели данных, API. Может использоваться как базовый материал для глав «Обзор технологий», «Архитектура системы», «Реализация» дипломной работы.

---

## 1. Обзор проекта

**AI Finance Tracker** — мобильное приложение для учёта личных финансов с AI-помощником. Пользователь записывает доходы и расходы, а система выдаёт персональные рекомендации (прогнозы по категориям, обнаружение аномальных трат, советы по экономии).

Система построена по трёхзвенной архитектуре:

```
┌────────────────────┐       HTTPS / JSON       ┌──────────────────────┐    HTTP/JSON    ┌──────────────────┐
│  Flutter-клиент    │ ───────────────────────► │  Spring Boot + Jmix  │ ──────────────► │  ML-сервис       │
│  (Android / iOS)   │ ◄─────────────────────── │  (REST + JWT)        │ ◄────────────── │  (FastAPI)       │
└────────────────────┘   access / refresh JWT   └──────────────────────┘   ML inference  └──────────────────┘
                                                          │
                                                          ▼
                                                  ┌───────────────┐
                                                  │  PostgreSQL   │
                                                  │  (HSQLDB dev) │
                                                  └───────────────┘
```

**Роли модулей:**

| Модуль | Технологии | Назначение |
|---|---|---|
| Mobile client | Flutter 3, Dart, Riverpod, go_router, Dio | UI, локальное состояние, безопасное хранение токенов |
| Backend | Java 17, Spring Boot 3, Jmix 2.7, EclipseLink JPA, PostgreSQL, JWT | бизнес-логика, авторизация, REST API, оркестрация ML |
| ML service | Python 3, FastAPI, scikit-learn, NumPy, Pandas | прогнозы расходов, поиск аномалий, what-if симуляция |

---

## 2. Бэкенд: Spring Boot + Jmix

### 2.1 Технологический стек

| Компонент | Версия | Роль |
|---|---|---|
| Java | 17 | основной язык |
| Spring Boot | 3.x (через `spring-boot-starter-web`) | DI-контейнер, HTTP, валидация |
| **Jmix** | 2.7.1 | мета-модель сущностей, безопасность, ORM-обёртка, FlowUI-админка |
| EclipseLink | через `jmix-eclipselink-starter` | JPA-провайдер |
| PostgreSQL JDBC | 42.6.0 | продакшн-БД |
| HSQLDB | runtime | встроенная БД для разработки и тестов |
| jjwt | 0.12.3 | генерация и валидация JWT |
| springdoc-openapi | 2.8.6 | автогенерация Swagger UI |

### 2.2 Доменная модель

В `src/main/java/com/company/aifinancetracker/entity` определены:

- **User** — учётная запись пользователя (username, hash пароля, имя, фамилия)
- **Category** — категория транзакций; `CategoryType ∈ {EXPENSE, INCOME}`
- **Transaction** — запись о доходе или расходе; ссылка на категорию и пользователя, сумма, дата, заметка
- **Budget** — лимит расходов на категорию / общий лимит на период
- **Recommendation** — AI-совет; `RecommendationType ∈ {TREND_FORECAST, ANOMALY, BUDGET_LIMIT, SAVINGS_TIP}`, `RecommendationStatus ∈ {ACTIVE, DISMISSED, EXPIRED}`, поля `title`, `message`, `metadata` (JSON), `relatedCategoryId`, `validUntil`

Jmix управляет жизненным циклом сущностей через `DataManager` (CRUD и `FluentLoader`-запросы) и автоматически прикручивает row-level security и аудит.

### 2.3 Сервисный слой

| Сервис | Ответственность |
|---|---|
| `AuthService` / `JwtService` | регистрация, логин, refresh, выдача access/refresh-токенов |
| `TransactionService` | CRUD транзакций с проверкой принадлежности пользователю |
| `ExpenseService` / `IncomeService` | специализированные запросы по типу транзакций |
| `BalanceService` | агрегации по балансу (доходы − расходы за период) |
| `AnalyticsService` | подготовка временных рядов (`MonthlySpend`, `TransactionPoint`) для ML |
| `MLServiceClient` | HTTP-клиент к FastAPI-сервису (RestTemplate) |
| `RecommendationGenerator` | конвертация ответов ML в сущности `Recommendation` с понятными для пользователя текстами |
| `RecommendationScheduler` | фоновая задача (Spring `@Scheduled`) — периодическое обновление советов для всех пользователей |
| `CategoryManagementService` | глобальные категории + пользовательские; инициализация дефолтных при создании пользователя |

### 2.4 REST API

Все эндпоинты `/api/**` защищены JWT (`Authorization: Bearer …`).

| Контроллер | Эндпоинты |
|---|---|
| `AuthController` | `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/refresh`, `POST /api/auth/logout` |
| `TransactionController` | `GET/POST/PUT/DELETE /api/transactions` |
| `ExpenseController` / `IncomeController` | отфильтрованные срезы транзакций |
| `CategoryController` | список категорий пользователя |
| `BudgetController` | CRUD бюджетов |
| `DashboardController` | сводка по периоду (баланс, топ-категории) |
| `RecommendationController` | `GET /api/recommendations` (список активных), `POST /api/recommendations/refresh` (запуск пересчёта), `POST /api/recommendations/{id}/dismiss` |

Документация автоматически публикуется через springdoc по `/swagger-ui.html`.

### 2.5 Безопасность

`AiFinanceTrackerSecurityConfiguration`:

1. **Stateless JWT для `/api/**`**:
   - `SessionCreationPolicy.STATELESS`
   - кастомный фильтр валидирует подпись HS256, читает `userId` из claim, кладёт `Authentication` в `SecurityContext`
2. **Form-login для FlowUI-админки** — стандартный Jmix-механизм, отдельная цепочка
3. **Refresh-ротация**: refresh-токен одноразовый, при logout инвалидируется на стороне клиента (stateless), на сервере — без сохранения; пара access (15 мин) + refresh (30 дней)
4. **BCrypt** для хранения паролей (через `PasswordEncoder` Spring Security)
5. **Ответ 401 в стандартном `ErrorResponse`** для неавторизованных `/api/**`-запросов (введено в коммите AIFT-6)

---

## 3. ML-сервис: FastAPI + scikit-learn

Расположение: `ml-service/`. Сервис **stateless** — не имеет своей БД, принимает данные в теле POST-запроса и возвращает результат.

### 3.1 Эндпоинты

| Метод | URL | Действие |
|---|---|---|
| `GET` | `/health` | health-check |
| `POST` | `/predict/spending` | прогноз расходов по категориям |
| `POST` | `/detect/anomalies` | поиск аномальных транзакций |
| `POST` | `/simulate/whatif` | what-if симуляция экономии при сокращении расходов |

### 3.2 Алгоритмы

#### 3.2.1 Прогнозирование расходов — линейная регрессия

Для каждой категории `c` пользователь имеет историю помесячных трат:
```
X_c = [(month_0, amount_0), (month_1, amount_1), ..., (month_{n-1}, amount_{n-1})]
```

Модель: `sklearn.linear_model.LinearRegression`, признак — порядковый номер месяца, целевая — сумма.

```
y = β₀ + β₁·x + ε
```

Параметры β₀, β₁ оцениваются методом наименьших квадратов. Прогноз на горизонт `h`:

```
ŷ = β₀ + β₁·(n + h − 1)
```

Прогноз ограничен снизу нулём (`max(predicted, 0)`).

**Метрика уверенности — коэффициент детерминации R²:**

```
R² = 1 − SS_res / SS_tot
SS_res = Σ (y_i − ŷ_i)²
SS_tot = Σ (y_i − ȳ)²
```

R² нормирован в `[0, 1]` и возвращается как `confidence`.

**Классификация тренда** по относительному наклону `β₁ / ȳ`:

| Условие | Тренд |
|---|---|
| `β₁ / ȳ > 0.05` | `increasing` |
| `β₁ / ȳ < −0.05` | `decreasing` |
| иначе | `flat` |

**Fallback-стратегии** (защита от вырожденных случаев):

| Количество точек | Метод | Confidence |
|---|---|---|
| 0 | `empty` | 0.0 |
| 1 | mean (= единственная точка) | 0.3 |
| 2 | mean от двух точек | 0.5 |
| ≥3 | linear regression | R² |

См. `ml-service/app/ml.py:_predict_category` и `ml-service/app/ml.py:forecast_spending`.

#### 3.2.2 Обнаружение аномалий — z-score

Транзакции группируются по `category_id`. Для каждой группы (если `n ≥ 3` и `std > 10⁻⁶`):

```
z_i = (amount_i − μ_c) / σ_c
```

где `μ_c`, `σ_c` — выборочные среднее и стандартное отклонение по категории.

Транзакция помечается как аномальная, если `|z| ≥ z_threshold` (по умолчанию задаётся клиентом).

**Уровни severity:**

| `|z|` | Severity |
|---|---|
| ≥ 3.5 | critical |
| ≥ 2.5 | high |
| ≥ z_threshold | medium |

Каждая аномалия сопровождается человекочитаемой причиной:

> «Сумма 12 500.00 выше среднего по категории (3 800.00) в 3.3x раз»

См. `ml-service/app/ml.py:detect_anomalies`.

#### 3.2.3 What-if симуляция

Пользователь задаёт список **«срезов»** — на сколько процентов он готов сократить расходы по конкретным категориям:

```
cuts = [{ category_id: "...", cut_percent: 20 }, ...]
```

Для каждого месяца горизонта `m ∈ [1..H]`:

```
baseline_m   = Σ_c forecast_c(m)
withCuts_m   = Σ_c forecast_c(m) · (1 − cut_c)
savings_m    = baseline_m − withCuts_m
```

где `cut_c = 0` для категорий без среза.

Итоговая экономия:

```
total_savings    = Σ_m savings_m
savings_percent  = (total_savings / total_baseline) × 100
```

См. `ml-service/app/ml.py:simulate_what_if`.

### 3.3 Контракт данных

Pydantic-схемы (`ml-service/app/schemas.py`):

- `MonthlySpend { category_id, category_name, month: date, amount: float }`
- `TransactionPoint { transaction_id, category_id, category_name, amount, occurred_at }`
- `ForecastRequest { history: List[MonthlySpend], horizon_months: int }`
- `ForecastResponse { horizon_months, total_predicted, predictions: List[CategoryPrediction] }`
- `AnomalyRequest { transactions, z_threshold: float }`
- `AnomalyResponse { anomalies: List[AnomalyItem], inspected_count }`
- `WhatIfRequest { history, cuts, horizon_months }`
- `WhatIfResponse { horizon_months, total_baseline, total_with_cuts, total_savings, savings_percent, monthly, affected_categories }`

### 3.4 Интеграция с Java-бэкендом

`AnalyticsService` агрегирует транзакции пользователя по месяцам и категориям → формирует `ForecastRequest` / `AnomalyRequest` → `MLServiceClient` отправляет POST в FastAPI → `RecommendationGenerator` конвертирует ответ в сущности `Recommendation` с понятными текстами и сохраняет через `DataManager`.

`RecommendationScheduler` запускает этот цикл периодически (`@Scheduled`). Пользователь может также инициировать пересчёт вручную через `POST /api/recommendations/refresh`.

---

## 4. Мобильный клиент: Flutter

Расположение: `mobile/lib/`. Язык — Dart, фреймворк — Flutter 3 (Material 3, тёмная тема).

### 4.1 Технологический стек

| Пакет | Назначение |
|---|---|
| `flutter_riverpod` | управление состоянием, dependency injection |
| `go_router` | декларативная маршрутизация |
| `dio` | HTTP-клиент с интерсепторами для JWT |
| `flutter_secure_storage` | хранение access/refresh токенов в KeyStore / Keychain |
| `intl` | форматирование чисел, дат, локализация |

### 4.2 Структура проекта

```
mobile/lib/
├── main.dart                          # точка входа, ProviderScope + MaterialApp.router
├── theme/
│   └── app_theme.dart                 # дизайн-токены: AppColors, AppRadius, AppSpacing, AppShadows
├── core/
│   ├── api/                           # ApiClient (Dio + интерсепторы), ApiException
│   ├── router/                        # go_router конфиг + StatefulShellRoute
│   └── storage/                       # TokenStorage (secure storage)
├── widgets/                           # переиспользуемые виджеты
│   ├── glow_card.dart                 # карточка с лиловой подсветкой (3 варианта)
│   ├── app_bottom_nav.dart            # glass-bar с FAB
│   ├── app_shell.dart                 # каркас навигации
│   └── charts/                        # SparklineChart, DonutChart
├── shared/                            # форматтеры, общие хелперы
└── features/                          # feature-first организация
    ├── auth/                          # login, register, AuthController
    ├── home/                          # главный экран с категориями
    ├── dashboard/                     # графики и саммари
    ├── transactions/                  # форма с numpad
    ├── recommendations/               # AI-советы
    ├── categories/                    # модели категорий
    └── settings/                      # настройки и профиль
```

### 4.3 Архитектурные принципы

**Feature-first**: каждая фича — отдельная папка с подпапками `data/` (модели + API-клиент), `presentation/` (экраны и виджеты), плюс файл `*_providers.dart` (Riverpod-провайдеры).

**Слои Riverpod**:

```
Notifier / NotifierProvider           ← хранят состояние (AuthController, CurrencyController)
FutureProvider / Provider             ← derived state, асинхронные запросы (transactionsProvider,
                                        recommendationsProvider, dashboardSummaryProvider)
ConsumerWidget / ConsumerStatefulWidget  ← UI, подписывается через ref.watch
```

Состояние **immutable**: классы `AuthState`, `Recommendation`, `Transaction` — value-объекты, изменения происходят через `copyWith` и присваивание `state = …`.

**Маршрутизация**: `StatefulShellRoute.indexedStack` с 4 ветками (`/`, `/dashboard`, `/recommendations`, `/settings`) — переключение вкладок не теряет навигационный стек внутри ветки. Экраны вне таб-бара (`/login`, `/register`, `/transactions/new`) используют root navigator.

### 4.4 Безопасность на клиенте

- Access и refresh токены лежат в `FlutterSecureStorage` (Android Keystore / iOS Keychain) — недоступны через простой `SharedPreferences`-дамп
- `ApiClient` (Dio) на каждый запрос прикрепляет `Authorization: Bearer <access>`. При получении 401 интерсептор:
  1. Пытается обновить access через `/api/auth/refresh`
  2. При успехе — повторяет исходный запрос
  3. При неудаче — чистит хранилище и инкрементирует `forcedLogoutSignalProvider` (ValueNotifier), `AuthController` подписан и переводит статус в `unauthenticated` → роутер уводит на `/login`

### 4.5 Дизайн-система

Полностью централизована в `mobile/lib/theme/app_theme.dart`. Принципы:

1. **Никаких хардкод-hex** в коде экранов — только `AppColors.accent`, `AppColors.mint` и т.п.
2. **Размеры скруглений**: `AppRadius.{xs, sm, md, lg, card, hero, sheet, pill}`
3. **Отступы**: `AppSpacing.{xs, sm, md, base, lg, screen, xl}`
4. **Тени**: `AppShadows.{hero, card, fab, bottomBar}`

**Цветовая палитра** (OKLCH → sRGB, пре-вычислено):

| Назначение | Цвет | Hex |
|---|---|---|
| Фон | bg | `#070709` |
| Поднятая поверхность | bgRaised | `#0C0C0E` |
| Акцент (лиловый) | accent | `#AEA1D9` |
| Доход / позитив | mint | `#82D9B4` |
| Расход / аномалия | coral | `#F19E97` |
| Основной текст | text | `#F8F8FC` |
| Второстепенный | textMid | `#ABA9B2` |
| Дим | textDim | `#6F6D75` |

`buildDarkTheme()` собирает `ThemeData` с Material 3 (`useMaterial3: true`), полным `ColorScheme`, перенастроенными темами для `Card`, `FilledButton`, `Switch`, `InputDecoration`, `BottomSheet`, `Dialog`, `SnackBar` и др. — везде используются токены.

**Шрифтовая шкала** с табулярными цифрами (`FontFeature.tabularFigures()`) — суммы выравниваются по разрядам в списках.

### 4.6 Кастомные графики

В `mobile/lib/widgets/charts/`:

- **SparklineChart** — мини-график тренда баланса. `CustomPainter` рисует полилинию + gradient-fill + светящаяся точка на конце.
- **DonutChart** — кольцевая диаграмма топ-категорий. Сегменты с хайрлайн-зазорами (`gap = 0.015 rad`), центральная метка и значение.
- **MiniTrendPainter** (в `recommendations_screen.dart`) — внутри карточки прогноза: линия тренда + пунктир будущего интервала. Расчёт пунктира — через `math.sqrt` для дистанции и параметризацию единичным вектором.

Графики получают **числовые ряды**, посчитанные клиентом из загруженных транзакций (`_buildBalanceTrend`, `_buildDailyExpense`, `_balanceDeltaPercent` в `dashboard_page.dart`).

### 4.7 Микро-анимации

- **Stagger-fade** для карточек рекомендаций: `_FadeSlideIn` — `FadeTransition` + `SlideTransition`, шаг 55 ms между элементами, длительность 320 ms, кривая `easeOut` / `easeOutCubic`. Перезапускается при смене фильтра через `key: ValueKey(_filter)` на `Column`.
- **Пульсирующая точка** (статус ML-сервиса): `AnimationController` с `repeat(reverse: true)`, `0.6 → 1.0` opacity.
- **Вращающаяся иконка** при обновлении: `AnimationController` с `repeat()`, 360°.
- **Ambient glow** на auth-экранах: два `RadialGradient`-круга через `Positioned` в `Stack`.

---

## 5. Поток данных: пример «AI-рекомендации»

```
[Mobile: RecommendationsScreen]
        │ ref.watch(recommendationsProvider)
        ▼
[Riverpod FutureProvider]
        │ GET /api/recommendations
        ▼
[Backend: RecommendationController]
        │ recommendationService.findActive(userId)
        ▼
[DataManager.load(Recommendation).query("e.user = :u AND e.status = ACTIVE")]
        │
        ▼
[PostgreSQL] → возврат списка

──────────── Обновление (refresh) ────────────

[Mobile: tap refresh]
        │ POST /api/recommendations/refresh
        ▼
[Backend: RecommendationService.refreshForUser(user)]
        │
        ├─► [AnalyticsService.buildMonthlyHistory(user)]   ─► List<MonthlySpend>
        │
        ├─► [MLServiceClient.forecast(...)]                ─► HTTP POST /predict/spending
        │                                                      │
        │                                                      ▼
        │                                            [FastAPI: LinearRegression на категории]
        │                                                      │
        │   ◄──────────────── ForecastResponse ◄──────────────┘
        │
        ├─► [AnalyticsService.buildTransactionPoints(user)] ─► List<TransactionPoint>
        │
        ├─► [MLServiceClient.detectAnomalies(...)]          ─► HTTP POST /detect/anomalies
        │                                                      │
        │                                                      ▼
        │                                            [FastAPI: z-score по категориям]
        │                                                      │
        │   ◄──────────────── AnomalyResponse ◄───────────────┘
        │
        ├─► [RecommendationGenerator.fromForecast(...)]     ─► List<Recommendation>
        ├─► [RecommendationGenerator.fromAnomalies(...)]    ─► List<Recommendation>
        │
        ▼
[DataManager.save(...)]  → PostgreSQL
        │
        ▼
[Mobile: ref.invalidate(recommendationsProvider)]
        │
        ▼
[UI: список перерисовывается, новые карточки анимированно появляются]
```

---

## 6. Главы для дипломной работы — что куда брать

| Глава | Источник в этом документе / в репозитории |
|---|---|
| **Обзор технологий** | §1 архитектурная схема, §2.1 / §3 / §4.1 стеки |
| **Архитектура системы** | §1, §5 поток данных |
| **Модель данных** | §2.2; исходники в `src/main/java/com/company/aifinancetracker/entity/` |
| **REST API** | §2.4; полный список — `API_ENDPOINTS.md`, Swagger UI |
| **Безопасность** | §2.5, §4.4; исходники: `AiFinanceTrackerSecurityConfiguration.java`, `JwtService.java`, `mobile/lib/core/api/api_client.dart` |
| **Машинное обучение** | §3 — все три алгоритма с формулами; исходники: `ml-service/app/ml.py` |
| **Мобильное приложение** | §4; исходники: `mobile/lib/` |
| **UI / дизайн-система** | §4.5; исходники: `mobile/lib/theme/app_theme.dart` |
| **Алгоритмы визуализации** | §4.6 |

### Готовые формулы для теоретической главы

**Линейная регрессия (МНК):**

```
β₁ = Σ(xᵢ − x̄)(yᵢ − ȳ) / Σ(xᵢ − x̄)²
β₀ = ȳ − β₁·x̄
ŷ  = β₀ + β₁·x
R² = 1 − Σ(yᵢ − ŷᵢ)² / Σ(yᵢ − ȳ)²
```

**Z-score для аномалий:**

```
μ = (1/n) · Σ xᵢ
σ = √((1/n) · Σ (xᵢ − μ)²)
z = (x − μ) / σ
```

**Sharpe-подобная классификация тренда:**

```
relative_slope = β₁ / ȳ
trend = increasing if relative_slope > 0.05
        decreasing if relative_slope < −0.05
        flat       otherwise
```

---

## 7. Полезные ссылки внутри репозитория

- `README.md` — стартовый гайд
- `API_ENDPOINTS.md` — список всех REST-эндпоинтов
- `SECURITY.md`, `SETUP_SECURITY.md` — безопасность
- `TESTING_GUIDE.md` — тесты
- `ml-service/README.md` — отдельный README ML-сервиса
- `docker-compose.yml` — поднимает PostgreSQL + ML-сервис
- `build.gradle` — Java-зависимости
- `mobile/pubspec.yaml` — Dart-зависимости
- `ml-service/requirements.txt` — Python-зависимости

---

## 8. Версии зависимостей (для главы «Реализация»)

**Backend:**
- Spring Boot — через `spring-boot-starter-web` (Spring Framework 6.2)
- Jmix 2.7.1
- jjwt 0.12.3
- springdoc-openapi 2.8.6
- PostgreSQL JDBC 42.6.0

**ML-сервис** (см. `ml-service/requirements.txt`):
- FastAPI
- scikit-learn
- NumPy
- Pandas
- Pydantic
- Uvicorn

**Mobile** (см. `mobile/pubspec.yaml`):
- Flutter SDK 3.x
- flutter_riverpod
- go_router
- dio
- flutter_secure_storage
- intl
