# API Endpoints Documentation

> **Интерактивная документация:** после запуска бэка откройте `http://localhost:8080/swagger-ui.html` — все endpoint'ы со схемами, прямо в браузере можно тыкать (нажмите Authorize и введите `Bearer <access_token>`).
>
> **Сырой OpenAPI 3 spec:** `http://localhost:8080/v3/api-docs` (JSON) — годится для генерации мобильных клиентов через OpenAPI Generator.

## Аутентификация

### POST /api/auth/register
Регистрация нового пользователя
```json
{
  "username": "user123",
  "password": "Password123",
  "confirmPassword": "Password123",
  "firstName": "Иван",
  "lastName": "Иванов"
}
```

### POST /api/auth/login
Вход в систему
```json
{
  "username": "user123",
  "password": "Password123"
}
```
**Ответ:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "Bearer"
}
```
- `access_token` — короткоживущий (24 часа), используется для всех `/api/**` запросов в header'е `Authorization: Bearer <token>`
- `refresh_token` — долгоживущий (7 дней), используется только для получения новой пары токенов через `/api/auth/refresh`

### POST /api/auth/refresh
Обновление пары токенов. Используется когда access-токен истёк или скоро истечёт.
```json
{
  "refreshToken": "eyJ..."
}
```
**Ответ:** новая пара `access_token` + `refresh_token` (старый refresh при этом остаётся валидным до своего срока — для server-side revocation нужно отдельное хранилище).

**Ошибки:**
- `401 UNAUTHORIZED` — refresh-токен невалиден/протух или это access-токен вместо refresh
- `400 VALIDATION_FAILED` — поле `refreshToken` пустое

### POST /api/auth/logout
Stateless logout. На стороне сервера ничего не происходит — клиент должен сам удалить access и refresh из локального хранилища. JWT всегда stateless; для honest revocation нужно отдельное хранилище отозванных токенов (out of scope для дипломной).

**Ответ:** `200 OK` с сообщением «Discard the tokens on the client side».

---

## Категории

### GET /api/categories
Получить все категории пользователя

### GET /api/categories/by-type/{type}
Получить категории по типу (INCOME или EXPENSE)

### POST /api/categories
Создать новую категорию
```json
{
  "name": "Фриланс",
  "type": "INCOME"
}
```

### PUT /api/categories/{id}
Обновить категорию

### DELETE /api/categories/{id}
Удалить категорию (только пользовательские, не системные)

---

## Доходы

### GET /api/incomes
Получить все доходы пользователя

### GET /api/incomes/period?startDate={date}&endDate={date}
Получить доходы за период
- Формат даты: ISO 8601 (например: 2024-01-01T00:00:00Z)

### GET /api/incomes/{id}
Получить доход по ID

### POST /api/incomes
Создать новый доход 
```json
{
  "categoryId": "uuid",
  "amount": 50000.00,
  "operationDate": "2024-01-15T10:00:00Z",
  "description": "Зарплата за январь"
}
```

### PUT /api/incomes/{id}
Обновить доход

### DELETE /api/incomes/{id}
Удалить доход

---

## Расходы

### GET /api/expenses
Получить все расходы пользователя

### GET /api/expenses/period?startDate={date}&endDate={date}
Получить расходы за период
- Формат даты: ISO 8601

### GET /api/expenses/{id}
Получить расход по ID

### POST /api/expenses
Создать новый расход
```json
{
  "categoryId": "uuid",
  "amount": 5000.00,
  "operationDate": "2024-01-15T14:30:00Z",
  "description": "Продукты в магазине"
}
```

### PUT /api/expenses/{id}
Обновить расход

### DELETE /api/expenses/{id}
Удалить расход

---

## Транзакции (все операции)

### GET /api/transactions
Получить все транзакции (доходы + расходы)

### GET /api/transactions/period?startDate={date}&endDate={date}
Получить транзакции за период

### GET /api/transactions/{id}
Получить транзакцию по ID

### POST /api/transactions
Создать новую транзакцию
```json
{
  "categoryId": "uuid",
  "amount": 10000.00,
  "operationDate": "2024-01-15T12:00:00Z",
  "description": "Описание операции"
}
```

### PUT /api/transactions/{id}
Обновить транзакцию

### DELETE /api/transactions/{id}
Удалить транзакцию

---

## Дашборд и Аналитика

### GET /api/dashboard/summary
Получить сводку по текущему месяцу
**Ответ:**
```json
{
  "currentBalance": 150000.00,
  "monthIncome": 60000.00,
  "monthExpense": 35000.00,
  "monthBalance": 25000.00,
  "topExpenseCategories": [...],
  "topIncomeCategories": [...],
  "transactionCount": 45
}
```

### GET /api/dashboard/summary/period?startDate={date}&endDate={date}
Получить финансовую сводку за период
**Ответ:**
```json
{
  "totalIncome": 120000.00,
  "totalExpense": 80000.00,
  "balance": 40000.00,
  "startDate": "2024-01-01",
  "endDate": "2024-01-31"
}
```

### GET /api/dashboard/expenses-by-category?startDate={date}&endDate={date}
Получить расходы по категориям за период
**Ответ:**
```json
[
  {
    "categoryId": "uuid",
    "categoryName": "Продукты",
    "categoryType": "EXPENSE",
    "totalAmount": 25000.00,
    "transactionCount": 15,
    "percentage": 35.71
  }
]
```

### GET /api/dashboard/incomes-by-category?startDate={date}&endDate={date}
Получить доходы по категориям за период

---

## Бюджеты

### GET /api/budgets?month={month}&year={year}
Получить бюджеты за месяц
- По умолчанию: текущий месяц и год
- month: 1-12
- year: >= 2000

**Ответ:**
```json
[
  {
    "id": "uuid",
    "category": {
      "id": "uuid",
      "name": "Продукты",
      "type": "EXPENSE"
    },
    "limitAmount": 30000.00,
    "currentAmount": 22000.00,
    "remainingAmount": 8000.00,
    "percentageUsed": 73.33,
    "exceeded": false,
    "month": 1,
    "year": 2024,
    "alertEnabled": true
  }
]
```

### GET /api/budgets/{id}
Получить бюджет по ID

### POST /api/budgets
Создать новый бюджет
```json
{
  "categoryId": "uuid",
  "limitAmount": 30000.00,
  "month": 1,
  "year": 2024,
  "alertEnabled": true
}
```

**Примечание:** Бюджеты можно создавать только для категорий типа EXPENSE

### PUT /api/budgets/{id}
Обновить бюджет (можно менять только limitAmount и alertEnabled)
```json
{
  "categoryId": "uuid",
  "limitAmount": 35000.00,
  "month": 1,
  "year": 2024,
  "alertEnabled": true
}
```

### DELETE /api/budgets/{id}
Удалить бюджет

### GET /api/budgets/alerts
Получить бюджеты с превышением или близкие к лимиту (>80%)
**Ответ:** Список бюджетов текущего месяца, которые превышены или использованы более чем на 80%

---

## ML Рекомендации

> Требует, чтобы был запущен ML-сервис на `http://localhost:8000` (см. `ml-service/README.md` — `docker compose up -d ml-service`).

### GET /api/recommendations
Получить активные рекомендации текущего пользователя.
**Ответ:**
```json
[
  {
    "id": "uuid",
    "type": "TREND_FORECAST",
    "status": "ACTIVE",
    "title": "Растут расходы: Продукты",
    "message": "По данным за прошлые месяцы прогноз расходов на категорию «Продукты» в следующем месяце — 13500.00 ₽. Тренд возрастающий (модель: линейная регрессия, R²=0.85)...",
    "savingsEstimate": null,
    "relatedCategoryId": "uuid",
    "metadata": "{\"predicted\":13500.00,\"confidence\":0.85,...}",
    "generatedDate": "2026-05-08T03:00:00Z",
    "validUntil": "2026-05-15T03:00:00Z"
  }
]
```

Типы рекомендаций (`type`):
- `TREND_FORECAST` — прогноз растущих расходов в категории (linear regression)
- `ANOMALY` — аномальная транзакция (z-score)
- `SAVINGS_TIP` — what-if совет «срежь X на 10% — сэкономишь Y₽»

### POST /api/recommendations/refresh
Принудительно пересчитать рекомендации для текущего пользователя.
Возвращает список свежих рекомендаций (предыдущие активные → EXPIRED).

### POST /api/recommendations/{id}/dismiss
Скрыть рекомендацию (статус → DISMISSED).

### POST /api/recommendations/whatif
Симулятор экономии без сохранения в БД. На входе — список категорий и процент урезания.
```json
{
  "cuts": [
    {"categoryId": "uuid-product-category", "cutPercent": 15.0},
    {"categoryId": "uuid-fun-category", "cutPercent": 25.0}
  ],
  "horizonMonths": 3
}
```
**Ответ:**
```json
{
  "horizonMonths": 3,
  "totalBaseline": 150000.00,
  "totalWithCuts": 132000.00,
  "totalSavings": 18000.00,
  "savingsPercent": 12.0,
  "monthly": [
    {"monthOffset": 1, "baseline": 50000.00, "withCuts": 44000.00, "savings": 6000.00},
    {"monthOffset": 2, "baseline": 50000.00, "withCuts": 44000.00, "savings": 6000.00},
    {"monthOffset": 3, "baseline": 50000.00, "withCuts": 44000.00, "savings": 6000.00}
  ],
  "affectedCategories": ["uuid-product-category", "uuid-fun-category"]
}
```

### GET /api/recommendations/health
Проверка доступности ML-сервиса. `200` если жив, `503` если нет.

---

## Обработка ошибок

Все endpoints используют централизованный GlobalExceptionHandler.

### Типы ошибок:

**404 NOT_FOUND**
```json
{
  "error": "NOT_FOUND",
  "message": "Transaction with id abc-123 not found",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

**403 ACCESS_DENIED**
```json
{
  "error": "ACCESS_DENIED",
  "message": "Access denied: Income belongs to another user",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

**401 UNAUTHORIZED**
```json
{
  "error": "UNAUTHORIZED",
  "message": "User not authenticated",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

**400 VALIDATION_FAILED**
```json
{
  "error": "VALIDATION_FAILED",
  "validationErrors": {
    "amount": "Amount must be greater than 0",
    "categoryId": "Category ID is required"
  },
  "timestamp": "2024-01-15T12:00:00Z"
}
```

**400 INVALID_CATEGORY_TYPE**
```json
{
  "error": "INVALID_CATEGORY_TYPE",
  "message": "Category must be of type EXPENSE",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

**400 INVALID_ARGUMENT**
```json
{
  "error": "INVALID_ARGUMENT",
  "message": "Start date must be before end date",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

---

## Категории по умолчанию

### Доходы (создаются автоматически):
1. Заработная плата
2. Стипендия
3. Бизнес
4. Проценты от вкладов
5. Иные доходы

### Расходы (создаются автоматически):
1. Продукты
2. Транспорт
3. Жильё
4. Коммунальные услуги
5. Здоровье
6. Развлечения
7. Одежда
8. Образование
9. Подарки
10. Прочие расходы

Все категории по умолчанию имеют `systemCategory = true` и не могут быть удалены.

---

## Примечания

1. Все даты используют формат ISO 8601 с временной зоной (OffsetDateTime)
2. Все суммы используют BigDecimal с точностью до 2 знаков после запятой
3. JWT токен должен передаваться в заголовке: `Authorization: Bearer <token>`
4. Все endpoints кроме `/api/auth/**` требуют аутентификации
5. Row-level security обеспечивает доступ пользователя только к своим данным
