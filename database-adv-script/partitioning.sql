
---

# `partitioning.sql`
```sql
/* 5. Partitioning the large bookings table by start_date (by year) */

/* MySQL 8 — RANGE partitioning by YEAR(start_date).
   If table exists, you'd CREATE a new partitioned table and swap, or ALTER if feasible. */

-- Example: create a partitioned clone (adjust columns as needed)
CREATE TABLE bookings_part LIKE bookings;

ALTER TABLE bookings_part
PARTITION BY RANGE (YEAR(start_date)) (
  PARTITION p2019 VALUES LESS THAN (2020),
  PARTITION p2020 VALUES LESS THAN (2021),
  PARTITION p2021 VALUES LESS THAN (2022),
  PARTITION p2022 VALUES LESS THAN (2023),
  PARTITION p2023 VALUES LESS THAN (2024),
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION pmax  VALUES LESS THAN MAXVALUE
);

-- Migrate data:
INSERT INTO bookings_part SELECT * FROM bookings;

-- Optionally swap:
-- RENAME TABLE bookings TO bookings_old, bookings_part TO bookings;

-- Indexes on partitioned table (recreate as needed):
CREATE INDEX idx_bp_user      ON bookings_part(user_id);
CREATE INDEX idx_bp_property  ON bookings_part(property_id);
CREATE INDEX idx_bp_start     ON bookings_part(start_date);
CREATE INDEX idx_bp_status    ON bookings_part(status);

/* Postgres example — declarative partitioning by RANGE on start_date */
-- CREATE TABLE bookings_part (
--   LIKE bookings INCLUDING ALL
-- ) PARTITION BY RANGE (start_date);
-- CREATE TABLE bookings_2019 PARTITION OF bookings_part FOR VALUES FROM ('2019-01-01') TO ('2020-01-01');
-- ...
-- CREATE TABLE bookings_2025 PARTITION OF bookings_part FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
-- INSERT INTO bookings_part SELECT * FROM bookings;
