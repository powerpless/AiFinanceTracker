# Документация по безопасности системы FinTracker

## Обзор реализованных требований безопасности

Система FinTracker реализует комплексный подход к защите персональных и финансовых данных пользователей в соответствии с техническим заданием.

## 1. JWT-аутентификация и авторизация

### Реализация
- **JwtService** (`src/main/java/.../service/JwtService.java`) - сервис для генерации и валидации JWT токенов
- **JwtAuthenticationFilter** (`src/main/java/.../security/JwtAuthenticationFilter.java`) - фильтр для проверки JWT токенов в каждом запросе
- **AiFinanceTrackerSecurityConfiguration** - конфигурация Spring Security с JWT

### Особенности
- Access Token (срок действия: 24 часа)
- Refresh Token (срок действия: 7 дней)
- Токены передаются только в HTTP-заголовке `Authorization: Bearer <token>`
- Автоматическая проверка подлинности и срока действия токена при каждом запросе
- Stateless архитектура (без серверных сессий)

### Конфигурация
```properties
jwt.secret=<сгенерированный ключ>
jwt.expiration=86400000 # 24 часа
jwt.refresh-token.expiration=604800000 # 7 дней
```

## 2. Безопасное хранение паролей

### Реализация
- **PasswordEncoderConfig** - конфигурация BCrypt с силой хеширования 12
- Все пароли хешируются с использованием BCrypt перед сохранением в БД
- Каждый пароль имеет уникальную соль (salt)

### Особенности
- Используется криптографически стойкий алгоритм BCrypt
- Сила хеширования: 12 раундов (оптимальный баланс безопасности и производительности)
- Автоматическая генерация соли для каждого пароля
- Пароли никогда не хранятся в открытом виде

## 3. Механизм одноразовых кодов подтверждения

### Реализация
- **VerificationCode** - сущность для хранения кодов подтверждения
- **VerificationCodeService** - сервис для генерации и валидации кодов
- **EmailService** - сервис для отправки кодов по email

### Типы кодов подтверждения
- `REGISTRATION` - подтверждение регистрации
- `PASSWORD_RESET` - сброс пароля
- `PASSWORD_CHANGE` - смена пароля
- `EMAIL_CHANGE` - смена email

### Особенности безопасности
- 6-значный код генерируется криптографически безопасным генератором случайных чисел
- Срок действия кода: 15 минут
- Максимум 5 попыток ввода кода
- Код можно использовать только один раз
- При генерации нового кода все предыдущие автоматически аннулируются
- Коды хранятся в базе данных с отметками о времени создания и использования

## 4. Email-уведомления

### Реализация
- Spring Mail с поддержкой SMTP
- Шаблоны писем на русском языке
- Безопасная передача данных через TLS/STARTTLS

### Конфигурация
```properties
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=your-email@gmail.com
spring.mail.password=your-app-password
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

### Безопасность
- Письма не содержат конфиденциальной информации (только код подтверждения)
- Используется только защищенное SMTP-соединение
- Пользователь информируется о причине получения кода

## 5. Валидация входящих данных

### Реализация
- Jakarta Bean Validation на уровне DTO
- Серверная валидация всех входных данных
- Обработка ошибок валидации с детальными сообщениями

### Правила валидации

#### Регистрация
- Username: 3-50 символов, только буквы, цифры и подчеркивание
- Email: валидный формат email
- Password: минимум 8 символов, должен содержать заглавную букву, строчную букву и цифру
- FirstName/LastName: обязательные поля, максимум 100 символов

#### Коды подтверждения
- Email: валидный формат
- Code: строго 6 цифр

## 6. HTTPS и защищенная передача данных

### Конфигурация для production
```properties
# Раскомментируйте для включения HTTPS
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.p12
server.ssl.key-store-password=your-keystore-password
server.ssl.key-store-type=PKCS12
server.ssl.key-alias=tomcat
server.port=8443
server.require-ssl=true
```

### Генерация SSL-сертификата (для production)
```bash
keytool -genkeypair -alias tomcat -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore keystore.p12 -validity 3650
```

### Особенности
- Все данные передаются по защищенному каналу
- JWT токены передаются только в HTTPS-заголовках
- Защита от перехвата и подмены данных

## 7. Изоляция данных пользователей (Row-level Security)

### Реализация
- **UserContextService** - сервис для получения текущего пользователя
- **TransactionController** - пример защищенного контроллера с проверкой доступа

### Механизмы защиты
- Каждый запрос проверяет принадлежность данных текущему пользователю
- Автоматическая фильтрация данных по user_id
- Запрет доступа к чужим данным (HTTP 403 Forbidden)
- Все операции CRUD проверяют права доступа

### Пример проверки доступа
```java
User currentUser = userContextService.getCurrentUser();
if (!transaction.getUser().getId().equals(currentUser.getId())) {
    return ResponseEntity.status(HttpStatus.FORBIDDEN)
        .body(Map.of("error", "Access denied"));
}
```

## API Endpoints

### Публичные endpoints (не требуют аутентификации)
- `POST /api/auth/register` - регистрация нового пользователя
- `POST /api/auth/verify-registration` - подтверждение регистрации
- `POST /api/auth/login` - вход в систему
- `POST /api/auth/request-password-reset` - запрос сброса пароля
- `POST /api/auth/reset-password` - сброс пароля

### Защищенные endpoints (требуют JWT токен)
- `GET /api/transactions` - получить транзакции пользователя
- `GET /api/transactions/{id}` - получить конкретную транзакцию
- `POST /api/transactions` - создать новую транзакцию
- `PUT /api/transactions/{id}` - обновить транзакцию
- `DELETE /api/transactions/{id}` - удалить транзакцию

## Примеры использования API

### Регистрация
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "email": "john@example.com",
    "password": "SecurePass123",
    "firstName": "John",
    "lastName": "Doe"
  }'
```

### Подтверждение регистрации
```bash
curl -X POST http://localhost:8080/api/auth/verify-registration \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "code": "123456"
  }'
```

### Вход
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "john_doe",
    "password": "SecurePass123"
  }'
```

### Получение транзакций (с JWT токеном)
```bash
curl -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer <your-access-token>"
```

## Настройка для запуска

### 1. Настройка базы данных
Создайте БД PostgreSQL и настройте подключение в `application.properties`

### 2. Генерация скриптов Liquibase
После создания/изменения сущностей выполните:
```bash
./gradlew generateLiquibaseChangelog
```

### 3. Настройка Email
Настройте SMTP-сервер в `application.properties`:
- Для Gmail: используйте App Password (не основной пароль)
- Включите двухфакторную аутентификацию в Google
- Сгенерируйте App Password в настройках безопасности Google

### 4. Настройка JWT Secret
Для production замените JWT secret на собственный:
```bash
# Генерация нового secret (64 байта в base64)
openssl rand -base64 64
```

## Рекомендации по безопасности для production

1. **Измените JWT secret** на уникальный сгенерированный ключ
2. **Включите HTTPS** и используйте валидный SSL-сертификат
3. **Настройте CORS** для ограничения доступа с определенных доменов
4. **Используйте переменные окружения** для хранения секретов (не храните их в application.properties)
5. **Настройте rate limiting** для защиты от брутфорса
6. **Включите логирование** всех попыток аутентификации
7. **Регулярно обновляйте** зависимости для устранения уязвимостей
8. **Настройте мониторинг** подозрительной активности
9. **Используйте файрвол** на уровне сервера
10. **Регулярно делайте backup** базы данных

## Дополнительные улучшения безопасности (опционально)

- Двухфакторная аутентификация (2FA)
- Логирование всех действий пользователей (audit log)
- IP whitelist/blacklist
- Captcha для защиты от ботов
- Автоматическая блокировка аккаунта при множественных неудачных попытках входа
- Session management и возможность завершения всех активных сессий
- Шифрование чувствительных данных в БД
