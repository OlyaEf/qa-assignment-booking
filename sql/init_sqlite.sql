/* ==============================================
   SQLite init script for the QA assignment
   - Creates USERS and ORDERS tables
   - Seeds demo data covering all SQL tasks
   - Leaves DB ready for queries in queries.sql
   NOTE: Comments are in English by request.
   ============================================== */

-- Always enable foreign keys in SQLite (per connection)
PRAGMA foreign_keys = ON;

-- Clean start (idempotent)
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

-- USERS table
CREATE TABLE users (
  id         INTEGER PRIMARY KEY,
  name       TEXT NOT NULL,
  email      TEXT NOT NULL UNIQUE,         -- UNIQUE is case-sensitive in SQLite (BINARY collation)
  age        INTEGER,                      -- may be NULL (we'll catch this in data-quality queries)
  status     TEXT NOT NULL CHECK (status IN ('active','inactive')),
  created_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP)
);

-- ORDERS table (child) with ON DELETE CASCADE
CREATE TABLE orders (
  id         INTEGER PRIMARY KEY,
  user_id    INTEGER NOT NULL,
  total      NUMERIC NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Seed USERS
INSERT INTO users (id, name, email, age, status) VALUES
  (1, 'Анна',            'anna@example.com',        27, 'active'),
  (2, 'Олег',            'oleg@example.com',        24, 'active'),
  (3, 'Ирина',           'irina@example.com',       35, 'inactive'),
  (4, 'Павел',           'pavel@example.com',      NULL,'active'),    -- active with NULL age (data bug)
  (5, 'Даша',            'dasha@example.com',       51, 'active'),
  (6, 'Ivan',            'IVAN@example.com',        42, 'inactive'),
  (7, 'Ivan Petrov',     'ivan@example.com',        42, 'active'),
  (8, 'Анна Петрова',    'ANNA@example.com',        31, 'active'),    -- case-variant duplicate of id=1 (logical dup)
  (9, 'Ник',             'nick@example.com',       130, 'inactive'),  -- unrealistic high age (data bug)
  (10,'Test Negative',   'neg@example.com',         -1, 'inactive');  -- negative age (data bug)

-- Seed ORDERS (for cascade delete check)
INSERT INTO orders (id, user_id, total) VALUES
  (100, 1, 100.50),
  (101, 5,  30.00),
  (102, 8,  75.25);

-- Quick sanity checks (optional)
SELECT COUNT(*) AS users_total  FROM users;
SELECT COUNT(*) AS orders_total FROM orders;

-- Hints for reviewers (optional, not required to run):
-- .read sql/queries.sql
-- or paste queries below after running this init script

/* ==========================================================
   OPTIONAL: quick inline demos (uncomment to try and observe)
   ========================================================== */

-- -- Q4 demo: verify ON DELETE CASCADE inside a transaction
-- BEGIN;
--   SELECT id, name FROM users WHERE id = 8;                         -- expect: a row
--   SELECT COUNT(*) AS orders_before FROM orders WHERE user_id = 8;  -- expect: > 0
--   DELETE FROM users WHERE id = 8;
--   SELECT COUNT(*) AS orders_after  FROM orders WHERE user_id = 8;  -- expect: 0
-- ROLLBACK;

-- -- Q5 demo: case-insensitive duplicate emails (logical dups)
-- SELECT LOWER(email) AS email_norm, COUNT(*) AS cnt
-- FROM users
-- GROUP BY LOWER(email)
-- HAVING COUNT(*) > 1;

-- -- Q5 demo: invalid ages / NULL age for active users
-- SELECT id, name, age, status
-- FROM users
-- WHERE (status = 'active' AND age IS NULL)
--    OR age < 0
--    OR age > 120;
