# Инструкция по настройке системы безопасности

## Шаг 1: Генерация скриптов Liquibase

После клонирования проекта необходимо сгенерировать скрипты миграции для новых сущностей безопасности:

```bash
./gradlew generateLiquibaseChangelog
```

Или в Windows:
```bash
gradlew.bat generateLiquibaseChangelog
```

Это создаст скрипты для:
- Таблицы VERIFICATION_CODE (коды подтверждения)
- Поля EMAIL_VERIFIED в таблице USER_

## Шаг 2: Настройка Email

Откройте `src/main/resources/application.properties` и настройте параметры почты:

### Для Gmail:

1. Включите двухфакторную аутентификацию в вашем Google аккаунте
2. Перейдите в https://myaccount.google.com/apppasswords
3. Создайте App Password для приложения
4. Используйте этот пароль в конфигурации:

```properties
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=your-email@gmail.com
spring.mail.password=your-16-character-app-password
```

### Для других почтовых сервисов:

#### Yandex
```properties
spring.mail.host=smtp.yandex.ru
spring.mail.port=465
spring.mail.properties.mail.smtp.ssl.enable=true
```

#### Mail.ru
```properties
spring.mail.host=smtp.mail.ru
spring.mail.port=465
spring.mail.properties.mail.smtp.ssl.enable=true
```

## Шаг 3: Генерация JWT Secret (для Production)

По умолчанию в проекте используется тестовый ключ. Для production сгенерируйте новый:

### Linux/Mac:
```bash
openssl rand -base64 64
```

### Windows PowerShell:
```powershell
$bytes = New-Object byte[] 64
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
[Convert]::ToBase64String($bytes)
```

Замените значение `jwt.secret` в `application.properties` на сгенерированный ключ.

## Шаг 4: Запуск приложения

```bash
./gradlew bootRun
```

Или в Windows:
```bash
gradlew.bat bootRun
```

## Шаг 5: Тестирование API

### 1. Регистрация пользователя

```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "TestPass123",
    "firstName": "Test",
    "lastName": "User"
  }'
```

Ответ:
```json
{
  "message": "Registration successful. Please check your email for verification code."
}
```

После этого на указанный email придет код подтверждения.

### 2. Подтверждение регистрации

```bash
curl -X POST http://localhost:8080/api/auth/verify-registration \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "code": "123456"
  }'
```

Ответ:
```json
{
  "message": "Email verified successfully. You can now login."
}
```

### 3. Вход в систему

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "TestPass123"
  }'
```

Ответ:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer"
}
```

### 4. Доступ к защищенным endpoints

```bash
curl -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Шаг 6: Настройка HTTPS (Production)

### 1. Генерация самоподписанного сертификата (для тестирования):

```bash
keytool -genkeypair -alias tomcat -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore src/main/resources/keystore.p12 \
  -validity 3650 \
  -dname "CN=localhost, OU=Development, O=YourCompany, L=YourCity, ST=YourState, C=RU"
```

### 2. Раскомментируйте настройки HTTPS в application.properties:

```properties
server.ssl.enabled=true
server.ssl.key-store=classpath:keystore.p12
server.ssl.key-store-password=your-password
server.ssl.key-store-type=PKCS12
server.ssl.key-alias=tomcat
server.port=8443
```

### 3. Для production используйте сертификат от Let's Encrypt или коммерческого CA

## Шаг 7: Использование переменных окружения (Production)

Не храните секреты в application.properties. Используйте переменные окружения:

### Linux/Mac:
```bash
export JWT_SECRET="your-generated-secret"
export MAIL_USERNAME="your-email@gmail.com"
export MAIL_PASSWORD="your-app-password"
export DB_PASSWORD="your-db-password"
```

### Windows:
```cmd
set JWT_SECRET=your-generated-secret
set MAIL_USERNAME=your-email@gmail.com
set MAIL_PASSWORD=your-app-password
set DB_PASSWORD=your-db-password
```

В application.properties используйте:
```properties
jwt.secret=${JWT_SECRET}
spring.mail.username=${MAIL_USERNAME}
spring.mail.password=${MAIL_PASSWORD}
main.datasource.password=${DB_PASSWORD}
```

## Проверка безопасности

### 1. Проверка JWT аутентификации
Попробуйте получить доступ к защищенному endpoint без токена:
```bash
curl -X GET http://localhost:8080/api/transactions
```
Должен вернуться ответ 401 Unauthorized или 403 Forbidden.

### 2. Проверка изоляции данных
Создайте двух пользователей и попробуйте получить данные одного пользователя под токеном другого.

### 3. Проверка валидации
Попробуйте зарегистрироваться с неправильным форматом данных:
```bash
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ab",
    "email": "invalid-email",
    "password": "weak"
  }'
```
Должны вернуться ошибки валидации.

### 4. Проверка одноразовых кодов
- Попробуйте использовать код дважды
- Попробуйте использовать истекший код (через 15 минут)
- Попробуйте ввести неправильный код 6 раз

## Мониторинг и логирование

Просмотр логов безопасности:
```bash
tail -f logs/spring.log | grep -i "security\|authentication\|jwt"
```

## Troubleshooting

### Email не отправляется
- Проверьте настройки SMTP
- Убедитесь, что используете App Password для Gmail
- Проверьте файрвол и доступ к портам 587/465

### JWT токен не валидируется
- Проверьте, что jwt.secret одинаковый для генерации и проверки
- Убедитесь, что токен передается в заголовке Authorization
- Проверьте срок действия токена

### Ошибки базы данных
- Убедитесь, что выполнили generateLiquibaseChangelog
- Проверьте, что база данных запущена
- Проверьте права доступа пользователя БД

## Дополнительные ресурсы

- [JWT.io](https://jwt.io/) - для декодирования и проверки JWT токенов
- [Spring Security Documentation](https://docs.spring.io/spring-security/reference/)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) - топ уязвимостей веб-приложений
