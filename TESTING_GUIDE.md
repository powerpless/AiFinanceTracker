# 🚀 Полная документация API для тестирования AiFinanceTracker

## 🔐 1. Аутентификация

### Регистрация нового пользователя
```http
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "username": "testuser",
  "password": "Test123456",
  "confirmPassword": "Test123456",
  "firstName": "Тест",
  "lastName": "Тестов"
}
```

**Ответ:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "username": "testuser"
}
```

---

### Вход в систему
```http
POST http://localhost:8080/api/auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "Test123456"
}
```

**Ответ:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "username": "testuser"
}
```

**⚠️ ВАЖНО: Сохрани token! Используй его во всех последующих запросах в заголовке:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

## 📁 2. Категории

### Получить все категории пользователя
```http
GET http://localhost:8080/api/categories
Authorization: Bearer YOUR_TOKEN
```

**Ответ:**
```json
[
  {
    "id": "uuid-1",
    "name": "Заработная плата",
    "type": "INCOME",
    "systemCategory": true
  },
  {
    "id": "uuid-2",
    "name": "Продукты",
    "type": "EXPENSE",
    "systemCategory": true
  }
]
```

---

### Получить категории доходов
```http
GET http://localhost:8080/api/categories/by-type/INCOME
Authorization: Bearer YOUR_TOKEN
```

**Категории доходов по умолчанию:**
1. Заработная плата
2. Стипендия
3. Бизнес
4. Проценты от вкладов
5. Иные доходы

---

### Получить категории расходов
```http
GET http://localhost:8080/api/categories/by-type/EXPENSE
Authorization: Bearer YOUR_TOKEN
```

**Категории расходов по умолчанию:**
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

---

### Создать свою категорию дохода
```http
POST http://localhost:8080/api/categories
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "Фриланс",
  "type": "INCOME"
}
```

---

### Создать свою категорию расхода
```http
POST http://localhost:8080/api/categories
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "Кафе и рестораны",
  "type": "EXPENSE"
}
```

---

### Обновить категорию
```http
PUT http://localhost:8080/api/categories/{categoryId}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "Подработка",
  "type": "INCOME"
}
```

---

### Удалить категорию (только пользовательские!)
```http
DELETE http://localhost:8080/api/categories/{categoryId}
Authorization: Bearer YOUR_TOKEN
```

**⚠️ Примечание:** Нельзя удалить системные категории (systemCategory = true)

---

## 💰 3. Доходы

### Получить все доходы пользователя
```http
GET http://localhost:8080/api/incomes
Authorization: Bearer YOUR_TOKEN
```

**Ответ:**
```json
[
  {
    "id": "uuid",
    "category": {
      "id": "uuid",
      "name": "Заработная плата",
      "type": "INCOME",
      "systemCategory": true
    },
    "amount": 75000.00,
    "operationDate": "2024-12-01T09:00:00Z",
    "description": "Зарплата декабрь",
    "createdDate": "2024-12-01T09:05:00Z",
    "lastModifiedDate": "2024-12-01T09:05:00Z"
  }
]
```

---

### Получить доходы за период
```http
GET http://localhost:8080/api/incomes/period?startDate=2024-01-01T00:00:00Z&endDate=2024-12-31T23:59:59Z
Authorization: Bearer YOUR_TOKEN
```

---

### Получить доход по ID
```http
GET http://localhost:8080/api/incomes/{incomeId}
Authorization: Bearer YOUR_TOKEN
```

---

### Создать доход
```http
POST http://localhost:8080/api/incomes
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ_ДОХОДА",
  "amount": 50000.00,
  "operationDate": "2024-12-15T10:00:00Z",
  "description": "Зарплата за декабрь"
}
```

**Примеры для тестирования:**

#### Пример 1: Зарплата
```json
{
  "categoryId": "ID_категории_Заработная_плата",
  "amount": 75000.00,
  "operationDate": "2024-12-01T09:00:00Z",
  "description": "Зарплата декабрь"
}
```

#### Пример 2: Бизнес доход
```json
{
  "categoryId": "ID_категории_Бизнес",
  "amount": 120000.00,
  "operationDate": "2024-12-10T14:30:00Z",
  "description": "Оплата от клиента"
}
```

#### Пример 3: Прочие доходы
```json
{
  "categoryId": "ID_категории_Иные_доходы",
  "amount": 15000.00,
  "operationDate": "2024-12-20T11:00:00Z",
  "description": "Продажа старой техники"
}
```

#### Пример 4: Стипендия
```json
{
  "categoryId": "ID_категории_Стипендия",
  "amount": 8000.00,
  "operationDate": "2024-12-25T10:00:00Z",
  "description": "Стипендия за декабрь"
}
```

---

### Обновить доход
```http
PUT http://localhost:8080/api/incomes/{incomeId}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ",
  "amount": 55000.00,
  "operationDate": "2024-12-15T10:00:00Z",
  "description": "Зарплата декабрь (скорректировано)"
}
```

---

### Удалить доход
```http
DELETE http://localhost:8080/api/incomes/{incomeId}
Authorization: Bearer YOUR_TOKEN
```

---

## 💸 4. Расходы

### Получить все расходы пользователя
```http
GET http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
```

---

### Получить расходы за период
```http
GET http://localhost:8080/api/expenses/period?startDate=2024-12-01T00:00:00Z&endDate=2024-12-31T23:59:59Z
Authorization: Bearer YOUR_TOKEN
```

---

### Получить расход по ID
```http
GET http://localhost:8080/api/expenses/{expenseId}
Authorization: Bearer YOUR_TOKEN
```

---

### Создать расход
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ_РАСХОДА",
  "amount": 8500.00,
  "operationDate": "2024-12-28T18:30:00Z",
  "description": "Продукты в Пятёрочке"
}
```

**Примеры для тестирования:**

#### Пример 1: Продукты
```json
{
  "categoryId": "ID_категории_Продукты",
  "amount": 12000.00,
  "operationDate": "2024-12-05T19:00:00Z",
  "description": "Продукты на неделю"
}
```

#### Пример 2: Транспорт
```json
{
  "categoryId": "ID_категории_Транспорт",
  "amount": 3500.00,
  "operationDate": "2024-12-10T08:00:00Z",
  "description": "Пополнение транспортной карты"
}
```

#### Пример 3: Аренда жилья
```json
{
  "categoryId": "ID_категории_Жильё",
  "amount": 25000.00,
  "operationDate": "2024-12-01T10:00:00Z",
  "description": "Аренда квартиры"
}
```

#### Пример 4: Коммунальные услуги
```json
{
  "categoryId": "ID_категории_Коммунальные_услуги",
  "amount": 4500.00,
  "operationDate": "2024-12-15T12:00:00Z",
  "description": "Свет, вода, интернет"
}
```

#### Пример 5: Развлечения
```json
{
  "categoryId": "ID_категории_Развлечения",
  "amount": 2500.00,
  "operationDate": "2024-12-20T20:00:00Z",
  "description": "Кино с друзьями"
}
```

#### Пример 6: Здоровье
```json
{
  "categoryId": "ID_категории_Здоровье",
  "amount": 3200.00,
  "operationDate": "2024-12-12T11:30:00Z",
  "description": "Лекарства в аптеке"
}
```

#### Пример 7: Одежда
```json
{
  "categoryId": "ID_категории_Одежда",
  "amount": 6800.00,
  "operationDate": "2024-12-18T16:00:00Z",
  "description": "Зимняя куртка"
}
```

#### Пример 8: Образование
```json
{
  "categoryId": "ID_категории_Образование",
  "amount": 5000.00,
  "operationDate": "2024-12-03T14:00:00Z",
  "description": "Курсы английского языка"
}
```

#### Пример 9: Подарки
```json
{
  "categoryId": "ID_категории_Подарки",
  "amount": 3500.00,
  "operationDate": "2024-12-24T15:00:00Z",
  "description": "Новогодние подарки"
}
```

#### Пример 10: Прочие расходы
```json
{
  "categoryId": "ID_категории_Прочие_расходы",
  "amount": 1500.00,
  "operationDate": "2024-12-22T11:00:00Z",
  "description": "Ремонт телефона"
}
```

---

### Обновить расход
```http
PUT http://localhost:8080/api/expenses/{expenseId}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ",
  "amount": 9000.00,
  "operationDate": "2024-12-28T18:30:00Z",
  "description": "Продукты (обновлено)"
}
```

---

### Удалить расход
```http
DELETE http://localhost:8080/api/expenses/{expenseId}
Authorization: Bearer YOUR_TOKEN
```

---

## 📊 5. Все транзакции (доходы + расходы)

### Получить все транзакции
```http
GET http://localhost:8080/api/transactions
Authorization: Bearer YOUR_TOKEN
```

---

### Получить транзакции за период
```http
GET http://localhost:8080/api/transactions/period?startDate=2024-12-01T00:00:00Z&endDate=2024-12-31T23:59:59Z
Authorization: Bearer YOUR_TOKEN
```

---

### Получить транзакцию по ID
```http
GET http://localhost:8080/api/transactions/{transactionId}
Authorization: Bearer YOUR_TOKEN
```

---

### Создать транзакцию
```http
POST http://localhost:8080/api/transactions
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_ЛЮБОЙ_КАТЕГОРИИ",
  "amount": 10000.00,
  "operationDate": "2024-12-25T12:00:00Z",
  "description": "Любая операция"
}
```

---

### Обновить транзакцию
```http
PUT http://localhost:8080/api/transactions/{transactionId}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ",
  "amount": 11000.00,
  "operationDate": "2024-12-25T12:00:00Z",
  "description": "Обновлённая операция"
}
```

---

### Удалить транзакцию
```http
DELETE http://localhost:8080/api/transactions/{transactionId}
Authorization: Bearer YOUR_TOKEN
```

---

## 📈 6. Дашборд и Аналитика

### Получить сводку текущего месяца
```http
GET http://localhost:8080/api/dashboard/summary
Authorization: Bearer YOUR_TOKEN
```

**Ответ:**
```json
{
  "currentBalance": 210000.00,
  "monthIncome": 75000.00,
  "monthExpense": 45000.00,
  "monthBalance": 30000.00,
  "topExpenseCategories": [
    {
      "categoryId": "uuid",
      "categoryName": "Жильё",
      "categoryType": "EXPENSE",
      "totalAmount": 25000.00,
      "transactionCount": 1,
      "percentage": 55.56
    },
    {
      "categoryId": "uuid",
      "categoryName": "Продукты",
      "categoryType": "EXPENSE",
      "totalAmount": 12000.00,
      "transactionCount": 1,
      "percentage": 26.67
    }
  ],
  "topIncomeCategories": [
    {
      "categoryId": "uuid",
      "categoryName": "Заработная плата",
      "categoryType": "INCOME",
      "totalAmount": 75000.00,
      "transactionCount": 1,
      "percentage": 100.00
    }
  ],
  "transactionCount": 15
}
```

**Что показывает:**
- `currentBalance` - весь баланс за всё время
- `monthIncome` - доходы за текущий месяц
- `monthExpense` - расходы за текущий месяц
- `monthBalance` - баланс текущего месяца (доходы - расходы)
- `topExpenseCategories` - топ-5 категорий расходов текущего месяца
- `topIncomeCategories` - топ-5 категорий доходов текущего месяца
- `transactionCount` - всего транзакций за всё время

---

### Получить сводку за период
```http
GET http://localhost:8080/api/dashboard/summary/period?startDate=2024-12-01&endDate=2024-12-31
Authorization: Bearer YOUR_TOKEN
```

**Формат даты:** `YYYY-MM-DD` (без времени!)

**Ответ:**
```json
{
  "totalIncome": 210000.00,
  "totalExpense": 95000.00,
  "balance": 115000.00,
  "startDate": "2024-12-01",
  "endDate": "2024-12-31"
}
```

---

### Получить расходы по категориям за период
```http
GET http://localhost:8080/api/dashboard/expenses-by-category?startDate=2024-12-01&endDate=2024-12-31
Authorization: Bearer YOUR_TOKEN
```

**Ответ:**
```json
[
  {
    "categoryId": "uuid",
    "categoryName": "Жильё",
    "categoryType": "EXPENSE",
    "totalAmount": 25000.00,
    "transactionCount": 1,
    "percentage": 26.32
  },
  {
    "categoryId": "uuid",
    "categoryName": "Продукты",
    "categoryType": "EXPENSE",
    "totalAmount": 12000.00,
    "transactionCount": 1,
    "percentage": 12.63
  },
  {
    "categoryId": "uuid",
    "categoryName": "Транспорт",
    "categoryType": "EXPENSE",
    "totalAmount": 3500.00,
    "transactionCount": 1,
    "percentage": 3.68
  }
]
```

---

### Получить доходы по категориям за период
```http
GET http://localhost:8080/api/dashboard/incomes-by-category?startDate=2024-12-01&endDate=2024-12-31
Authorization: Bearer YOUR_TOKEN
```

---

## 💼 7. Бюджеты

### Получить бюджеты текущего месяца
```http
GET http://localhost:8080/api/budgets
Authorization: Bearer YOUR_TOKEN
```

---

### Получить бюджеты конкретного месяца
```http
GET http://localhost:8080/api/budgets?month=12&year=2024
Authorization: Bearer YOUR_TOKEN
```

**Параметры:**
- `month` - месяц от 1 до 12
- `year` - год (>= 2000)

---

### Получить бюджет по ID
```http
GET http://localhost:8080/api/budgets/{budgetId}
Authorization: Bearer YOUR_TOKEN
```

---

### Создать бюджет (⚠️ только для категорий EXPENSE!)
```http
POST http://localhost:8080/api/budgets
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ВСТАВЬ_ID_КАТЕГОРИИ_РАСХОДА",
  "limitAmount": 15000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

**Примеры для тестирования:**

#### Пример 1: Бюджет на продукты
```json
{
  "categoryId": "ID_категории_Продукты",
  "limitAmount": 20000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

#### Пример 2: Бюджет на транспорт
```json
{
  "categoryId": "ID_категории_Транспорт",
  "limitAmount": 5000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

#### Пример 3: Бюджет на развлечения
```json
{
  "categoryId": "ID_категории_Развлечения",
  "limitAmount": 8000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

#### Пример 4: Бюджет на здоровье
```json
{
  "categoryId": "ID_категории_Здоровье",
  "limitAmount": 10000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

**Ответ при создании:**
```json
{
  "id": "uuid",
  "category": {
    "id": "uuid",
    "name": "Продукты",
    "type": "EXPENSE",
    "systemCategory": true
  },
  "limitAmount": 20000.00,
  "currentAmount": 12000.00,
  "remainingAmount": 8000.00,
  "percentageUsed": 60.00,
  "exceeded": false,
  "month": 12,
  "year": 2024,
  "alertEnabled": true,
  "createdDate": "2024-12-31T10:00:00Z",
  "lastModifiedDate": "2024-12-31T10:00:00Z"
}
```

**Поля в ответе:**
- `limitAmount` - установленный лимит
- `currentAmount` - сколько уже потрачено (рассчитывается автоматически)
- `remainingAmount` - сколько осталось
- `percentageUsed` - процент использования бюджета
- `exceeded` - true если бюджет превышен

---

### Обновить бюджет
```http
PUT http://localhost:8080/api/budgets/{budgetId}
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ТОТ_ЖЕ_ID_КАТЕГОРИИ",
  "limitAmount": 25000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": false
}
```

**⚠️ Можно обновить:** только `limitAmount` и `alertEnabled`

---

### Удалить бюджет
```http
DELETE http://localhost:8080/api/budgets/{budgetId}
Authorization: Bearer YOUR_TOKEN
```

---

### Получить превышенные бюджеты (алерты)
```http
GET http://localhost:8080/api/budgets/alerts
Authorization: Bearer YOUR_TOKEN
```

**Возвращает бюджеты текущего месяца, которые:**
- Превышены (`currentAmount > limitAmount`)
- Использованы более чем на 80% (`percentageUsed >= 80`)

**Пример ответа:**
```json
[
  {
    "id": "uuid",
    "category": {
      "id": "uuid",
      "name": "Продукты",
      "type": "EXPENSE",
      "systemCategory": true
    },
    "limitAmount": 15000.00,
    "currentAmount": 18000.00,
    "remainingAmount": -3000.00,
    "percentageUsed": 120.00,
    "exceeded": true,
    "month": 12,
    "year": 2024,
    "alertEnabled": true
  }
]
```

---

## 🎯 Полный сценарий тестирования для диплома

### Шаг 1: Регистрация пользователя
```http
POST http://localhost:8080/api/auth/register
Content-Type: application/json

{
  "username": "diploma2024",
  "password": "Diploma123",
  "confirmPassword": "Diploma123",
  "firstName": "Студент",
  "lastName": "Дипломник"
}
```

**✅ Сохрани токен из ответа!**

---

### Шаг 2: Получить все категории
```http
GET http://localhost:8080/api/categories
Authorization: Bearer YOUR_TOKEN
```

**✅ Сохрани несколько categoryId (доходы и расходы)!**

---

### Шаг 3: Создать доходы (3-5 штук)

#### Доход 1: Зарплата
```http
POST http://localhost:8080/api/incomes
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Заработная_плата",
  "amount": 75000.00,
  "operationDate": "2024-12-01T09:00:00Z",
  "description": "Зарплата декабрь"
}
```

#### Доход 2: Бизнес
```http
POST http://localhost:8080/api/incomes
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Бизнес",
  "amount": 120000.00,
  "operationDate": "2024-12-10T14:30:00Z",
  "description": "Оплата от клиента"
}
```

#### Доход 3: Прочее
```http
POST http://localhost:8080/api/incomes
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Иные_доходы",
  "amount": 15000.00,
  "operationDate": "2024-12-20T11:00:00Z",
  "description": "Продажа старой техники"
}
```

---

### Шаг 4: Создать расходы (7-10 штук)

#### Расход 1: Аренда
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Жильё",
  "amount": 25000.00,
  "operationDate": "2024-12-01T10:00:00Z",
  "description": "Аренда квартиры"
}
```

#### Расход 2: Продукты
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Продукты",
  "amount": 12000.00,
  "operationDate": "2024-12-05T19:00:00Z",
  "description": "Продукты на неделю"
}
```

#### Расход 3: Транспорт
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Транспорт",
  "amount": 3500.00,
  "operationDate": "2024-12-10T08:00:00Z",
  "description": "Пополнение транспортной карты"
}
```

#### Расход 4: Коммунальные
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Коммунальные_услуги",
  "amount": 4500.00,
  "operationDate": "2024-12-15T12:00:00Z",
  "description": "Свет, вода, интернет"
}
```

#### Расход 5: Развлечения
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Развлечения",
  "amount": 2500.00,
  "operationDate": "2024-12-20T20:00:00Z",
  "description": "Кино с друзьями"
}
```

#### Расход 6: Здоровье
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Здоровье",
  "amount": 3200.00,
  "operationDate": "2024-12-12T11:30:00Z",
  "description": "Лекарства"
}
```

#### Расход 7: Одежда
```http
POST http://localhost:8080/api/expenses
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Одежда",
  "amount": 6800.00,
  "operationDate": "2024-12-18T16:00:00Z",
  "description": "Зимняя куртка"
}
```

---

### Шаг 5: Создать бюджеты (3-4 штук)

#### Бюджет 1: На продукты
```http
POST http://localhost:8080/api/budgets
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Продукты",
  "limitAmount": 20000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

#### Бюджет 2: На транспорт
```http
POST http://localhost:8080/api/budgets
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Транспорт",
  "limitAmount": 5000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

#### Бюджет 3: На развлечения
```http
POST http://localhost:8080/api/budgets
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "categoryId": "ID_Развлечения",
  "limitAmount": 8000.00,
  "month": 12,
  "year": 2024,
  "alertEnabled": true
}
```

---

### Шаг 6: Проверить дашборд
```http
GET http://localhost:8080/api/dashboard/summary
Authorization: Bearer YOUR_TOKEN
```

**Покажет:**
- Текущий баланс за всё время
- Доходы и расходы за декабрь
- Топ-5 категорий расходов
- Топ-5 категорий доходов

---

### Шаг 7: Проверить аналитику за период
```http
GET http://localhost:8080/api/dashboard/summary/period?startDate=2024-12-01&endDate=2024-12-31
Authorization: Bearer YOUR_TOKEN
```

---

### Шаг 8: Проверить расходы по категориям
```http
GET http://localhost:8080/api/dashboard/expenses-by-category?startDate=2024-12-01&endDate=2024-12-31
Authorization: Bearer YOUR_TOKEN
```

---

### Шаг 9: Проверить бюджеты
```http
GET http://localhost:8080/api/budgets?month=12&year=2024
Authorization: Bearer YOUR_TOKEN
```

---

### Шаг 10: Проверить алерты по бюджетам
```http
GET http://localhost:8080/api/budgets/alerts
Authorization: Bearer YOUR_TOKEN
```

---

## ❌ Обработка ошибок

### 404 - Не найдено
```json
{
  "error": "NOT_FOUND",
  "message": "Transaction with id abc-123 not found",
  "timestamp": "2024-12-31T12:00:00Z"
}
```

### 403 - Доступ запрещён
```json
{
  "error": "ACCESS_DENIED",
  "message": "Access denied: Income belongs to another user",
  "timestamp": "2024-12-31T12:00:00Z"
}
```

### 401 - Не авторизован
```json
{
  "error": "UNAUTHORIZED",
  "message": "User not authenticated",
  "timestamp": "2024-12-31T12:00:00Z"
}
```

### 400 - Ошибка валидации
```json
{
  "error": "VALIDATION_FAILED",
  "validationErrors": {
    "amount": "Amount must be greater than 0",
    "categoryId": "Category ID is required"
  },
  "timestamp": "2024-12-31T12:00:00Z"
}
```

### 400 - Неверный тип категории
```json
{
  "error": "INVALID_CATEGORY_TYPE",
  "message": "Category must be of type EXPENSE",
  "timestamp": "2024-12-31T12:00:00Z"
}
```

### 400 - Неверный аргумент
```json
{
  "error": "INVALID_ARGUMENT",
  "message": "Start date must be before end date",
  "timestamp": "2024-12-31T12:00:00Z"
}
```

---

## 🔥 Полезные CURL команды

### Регистрация
```bash
curl -X POST http://localhost:8080/api/auth/register \
-H "Content-Type: application/json" \
-d '{"username":"testuser","password":"Test123456","confirmPassword":"Test123456","firstName":"Тест","lastName":"Тестов"}'
```

### Логин
```bash
curl -X POST http://localhost:8080/api/auth/login \
-H "Content-Type: application/json" \
-d '{"username":"testuser","password":"Test123456"}'
```

### Получить категории
```bash
curl -X GET http://localhost:8080/api/categories \
-H "Authorization: Bearer YOUR_TOKEN"
```

### Создать доход
```bash
curl -X POST http://localhost:8080/api/incomes \
-H "Authorization: Bearer YOUR_TOKEN" \
-H "Content-Type: application/json" \
-d '{"categoryId":"CATEGORY_ID","amount":50000.00,"operationDate":"2024-12-15T10:00:00Z","description":"Зарплата"}'
```

### Создать расход
```bash
curl -X POST http://localhost:8080/api/expenses \
-H "Authorization: Bearer YOUR_TOKEN" \
-H "Content-Type: application/json" \
-d '{"categoryId":"CATEGORY_ID","amount":8500.00,"operationDate":"2024-12-28T18:30:00Z","description":"Продукты"}'
```

### Создать бюджет
```bash
curl -X POST http://localhost:8080/api/budgets \
-H "Authorization: Bearer YOUR_TOKEN" \
-H "Content-Type: application/json" \
-d '{"categoryId":"CATEGORY_ID","limitAmount":20000.00,"month":12,"year":2024,"alertEnabled":true}'
```

### Получить дашборд
```bash
curl -X GET http://localhost:8080/api/dashboard/summary \
-H "Authorization: Bearer YOUR_TOKEN"
```

---

## 📝 Важные примечания

1. **Формат даты для транзакций:** `2024-12-31T23:59:59Z` (ISO 8601 с временем и Z)
2. **Формат даты для аналитики:** `2024-12-31` (только дата, без времени)
3. **Authorization:** Во всех запросах кроме `/api/auth/**` используй `Bearer TOKEN`
4. **Бюджеты:** Можно создавать только для категорий типа **EXPENSE**
5. **Системные категории:** Нельзя удалить категории с `systemCategory = true`
6. **currentAmount в бюджете:** Рассчитывается автоматически из транзакций за месяц
7. **percentageUsed:** Автоматически считается как `(currentAmount / limitAmount) * 100`
8. **exceeded:** Автоматически `true` если `currentAmount > limitAmount`

---

## 🎓 Удачи с дипломной работой! 🚀

**Проект полностью готов к демонстрации и защите!**

Основные возможности:
✅ Регистрация и авторизация (JWT)
✅ Управление категориями (доходы и расходы)
✅ Учёт доходов с фильтрацией по периоду
✅ Учёт расходов с фильтрацией по периоду
✅ Дашборд с аналитикой (баланс, топ категорий)
✅ Бюджетирование с автоматическим расчётом
✅ Алерты о превышении бюджета
✅ Централизованная обработка ошибок
✅ Row-level security (пользователь видит только свои данные)
✅ Валидация всех входных данных
