# Тестирование Income Management API

## 1. Регистрация пользователя

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "confirmPassword": "password123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

## 2. Вход (получение JWT токена)

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

**Сохраните accessToken из ответа!** Используйте его в заголовке `Authorization: Bearer <token>` для всех последующих запросов.

---

## 3. Получить все категории доходов

```bash
curl -X GET http://localhost:8080/api/categories/by-type/INCOME \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

Должны увидеть 5 базовых категорий:
- Заработная плата
- Стипендия
- Бизнес
- Проценты от вкладов
- Иные доходы

---

## 4. Создать свою категорию дохода

```bash
curl -X POST http://localhost:8080/api/categories \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Фриланс",
    "type": "INCOME"
  }'
```

**Сохраните ID категории из ответа!**

---

## 5. Создать доход

```bash
curl -X POST http://localhost:8080/api/incomes \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50000.00,
    "categoryId": "<CATEGORY_ID>",
    "operationDate": "2025-12-27T10:00:00+03:00",
    "description": "Зарплата за декабрь"
  }'
```

**Сохраните ID дохода из ответа!**

---

## 6. Получить все доходы

```bash
curl -X GET http://localhost:8080/api/incomes \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

## 7. Получить доходы за период

```bash
curl -X GET "http://localhost:8080/api/incomes/period?startDate=2025-12-01T00:00:00%2B03:00&endDate=2025-12-31T23:59:59%2B03:00" \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

## 8. Получить доход по ID

```bash
curl -X GET http://localhost:8080/api/incomes/<INCOME_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

## 9. Обновить доход

```bash
curl -X PUT http://localhost:8080/api/incomes/<INCOME_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 55000.00,
    "categoryId": "<CATEGORY_ID>",
    "operationDate": "2025-12-27T10:00:00+03:00",
    "description": "Зарплата за декабрь + премия"
  }'
```

---

## 10. Удалить доход

```bash
curl -X DELETE http://localhost:8080/api/incomes/<INCOME_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

---

## 11. Попытка изменить системную категорию (должна вернуть ошибку)

```bash
curl -X PUT http://localhost:8080/api/categories/<SYSTEM_CATEGORY_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Новое название",
    "type": "INCOME"
  }'
```

Должна вернуться ошибка: "System categories cannot be modified"

---

## 12. Попытка удалить системную категорию (должна вернуть ошибку)

```bash
curl -X DELETE http://localhost:8080/api/categories/<SYSTEM_CATEGORY_ID> \
  -H "Authorization: Bearer <YOUR_TOKEN>"
```

Должна вернуться ошибка: "System categories cannot be deleted"

---

## Проверка безопасности (row-level security)

### Создайте второго пользователя:

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "password": "password123",
    "confirmPassword": "password123",
    "firstName": "Test2",
    "lastName": "User2"
  }'

curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser2",
    "password": "password123"
  }'
```

### Попытайтесь получить доход первого пользователя токеном второго:

```bash
curl -X GET http://localhost:8080/api/incomes/<INCOME_ID_USER1> \
  -H "Authorization: Bearer <TOKEN_USER2>"
```

Должна вернуться ошибка: "Access denied: Income belongs to another user"

---

## Примечания:

- Замените `<YOUR_TOKEN>` на актуальный JWT токен
- Замените `<CATEGORY_ID>` на ID категории
- Замените `<INCOME_ID>` на ID дохода
- Все даты в формате ISO 8601 с timezone
- Системные категории (systemCategory: true) нельзя изменять или удалять
