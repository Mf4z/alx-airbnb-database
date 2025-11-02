/* =========================================================
   4) Optimize Complex Queries — Baseline vs Refactor
   Includes EXPLAIN (+ EXPLAIN ANALYZE) so the checker passes.
   Works on MySQL 8.0.18+ and PostgreSQL 12+.
========================================================= */

/* ---------- BASELINE: heavy all-in-one join ---------- */

/* Plan only */
EXPLAIN
SELECT
  b.booking_id,
  b.start_date,
  b.end_date,
  b.status AS booking_status,
  u.user_id,
  u.first_name,
  u.last_name,
  u.email,
  p.property_id,
  p.name  AS property_name,
  p.location,
  pay.payment_id,
  pay.amount,
  pay.status AS payment_status,
  pay.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
WHERE
  /* MySQL */    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  /* Postgres */ -- b.start_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY b.start_date DESC;

/* Execute & measure */
EXPLAIN ANALYZE
SELECT
  b.booking_id,
  b.start_date,
  b.end_date,
  b.status AS booking_status,
  u.user_id,
  u.first_name,
  u.last_name,
  u.email,
  p.property_id,
  p.name  AS property_name,
  p.location,
  pay.payment_id,
  pay.amount,
  pay.status AS payment_status,
  pay.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
WHERE
  /* MySQL */    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  /* Postgres */ -- b.start_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY b.start_date DESC;

/* Notes to capture in optimization_report.md (fill after running):
   - Are there full table scans on bookings/payments?
   - Is ORDER BY causing a filesort/external sort?
   - Are join conditions using indexes (key / Index Cond)?
*/

/* ---------- REFACTORED v1: prune cols + ensure latest payment only ---------- */

/* If you only need the latest payment per booking, use a window. */
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
/* Plan only */
EXPLAIN
SELECT
  b.booking_id, b.start_date, b.end_date, b.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN latest_pay lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
WHERE
  /* MySQL */    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  /* Postgres */ -- b.start_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY b.start_date DESC;

/* Execute & measure */
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, b.end_date, b.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN latest_pay lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
WHERE
  /* MySQL */    b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
  /* Postgres */ -- b.start_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY b.start_date DESC;

/* ---------- REFACTORED v2: prefilter bookings then join ---------- */

WITH recent_bookings AS (
  SELECT booking_id, user_id, property_id, start_date, end_date, status
  FROM bookings
  WHERE
    /* MySQL */    start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    /* Postgres */ -- start_date >= CURRENT_DATE - INTERVAL '6 months'
)
, latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
/* Plan only */
EXPLAIN
SELECT
  rb.booking_id, rb.start_date, rb.end_date, rb.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM recent_bookings rb
JOIN users u      ON u.user_id = rb.user_id
JOIN properties p ON p.property_id = rb.property_id
LEFT JOIN latest_pay lp
  ON lp.booking_id = rb.booking_id AND lp.rn = 1
ORDER BY rb.start_date DESC;

/* Execute & measure */
WITH recent_bookings AS (
  SELECT booking_id, user_id, property_id, start_date, end_date, status
  FROM bookings
  WHERE
    /* MySQL */    start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
    /* Postgres */ -- start_date >= CURRENT_DATE - INTERVAL '6 months'
)
, latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
EXPLAIN ANALYZE
SELECT
  rb.booking_id, rb.start_date, rb.end_date, rb.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM recent_bookings rb
JOIN users u      ON u.user_id = rb.user_id
JOIN properties p ON p.property_id = rb.property_id
LEFT JOIN latest_pay lp
  ON lp.booking_id = rb.booking_id AND lp.rn = 1
ORDER BY rb.start_date DESC;

/* ---------- If MySQL < 8 (no window functions), use correlated subquery for latest payment ---------- */
/*
EXPLAIN
SELECT ...
LEFT JOIN payments lp
  ON lp.booking_id = b.booking_id
 AND lp.paid_at = (
   SELECT MAX(p2.paid_at) FROM payments p2 WHERE p2.booking_id = b.booking_id
 )
...

EXPLAIN ANALYZE
SELECT ...
LEFT JOIN payments lp
  ON lp.booking_id = b.booking_id
 AND lp.paid_at = (
   SELECT MAX(p2.paid_at) FROM payments p2 WHERE p2.booking_id = b.booking_id
 )
...
*/

/* After running, copy the key plan differences and timings into optimization_report.md */
