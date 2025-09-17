-- run these in the console bound to identifier.sqlite
PRAGMA foreign_keys = ON;  -- enable FK checks (per connection)

-- Q1 — активные, старше 25
       SELECT id, name, age, status
         FROM users
        WHERE status = 'active' AND age > 25;


-- Q2 — количество неактивные
       SELECT COUNT(*) AS cnt_inactive
         FROM users
        WHERE status = 'inactive';


-- Q3 — name/email, сортировка по age ↓ (NULL в конец)
       SELECT name, email, age
         FROM users
        ORDER BY (age IS NULL), age DESC;


-- Q4 — проверка каскадного удаления
        -- Should yield 0 after deleting the temp user
        BEGIN;
        PRAGMA foreign_keys = ON;

        INSERT INTO users (id,name,email,age,status)
        VALUES (9001,'Test User','test9001@example.com',30,'active');
        INSERT INTO orders (id,user_id,total)
        VALUES (99001,9001,42.00);

        DELETE FROM users WHERE id = 9001;

        SELECT COUNT(*) AS orphan_orders
        FROM orders
        WHERE user_id = 9001;  -- Expect: 0

        ROLLBACK;

-- Q5 — Баг A — Дубликаты email без учёта регистра
        -- Case-insensitive duplicates
        SELECT LOWER(email) AS email_lower, COUNT(*) AS cnt
          FROM users
         GROUP BY email_lower
        HAVING cnt > 1;

            -- Пользователь вводит e-mail в произвольном регистре; фронт/бэк не нормализует.
            -- SQLite по умолчанию делает UNIQUE регистрозависимым, поэтому «логические» дубликаты пролезают.

            -- Чем опасно:
            -- Дубли аккаунтов → проблемы с аутентификацией/восстановлением пароля.
            -- Ошибки в аналитике (DAU/MAU, ретеншн).
            -- Сбой «уникальности» на бизнес-уровне (рассылки, промокоды, лимиты).

-- Q6 — Баг B — Проблемные возраста (NULL у active, <0, >120)
        SELECT id, name, age, status
          FROM users
         WHERE age IS NULL AND status = 'active'
            OR age < 0
            OR age > 120;

            -- Возраст необязателен на форме → активные без возраста.
            -- Ошибка парсинга/миграции (пустая строка → NULL или -1).
            -- Ручные правки/импорт из внешних систем.

            -- Чем опасно:
            -- Некорректные сегментации (скидки «до 25», возрастные ограничения).
            -- Ломается аналитика (средний возраст, когорты).
            -- Бизнес-логика, завязанная на возраст (например, юридические ограничения), даёт сбои.

