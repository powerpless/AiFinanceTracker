1. Клонирование репозитория
   Склонируйте проект на локальный компьютер:
   https://github.com/powerpless/AiFinanceTracker.git 


2. Настройка базы данных PostgreSQL
   Создайте базу данных под любым названием

3. Настройка приложения

Открой файл src/main/resources/application.properties.

Задай параметры подключения к PostgreSQL:
main.datasource.url=jdbc:postgresql://localhost:5432/db name
main.datasource.username=your username
main.datasource.password=your password
main.datasource.driver-class-name=org.postgresql.Driver

main.liquibase.change-log=com/company/aifinancetracker/liquibase/changelog.xml

4. Запускайте