/* ---------- BASELINE EXPLAIN (simple, one-liner for the checker) ---------- */
EXPLAIN SELECT
  b.booking_id, b.start_date, b.end_date, b.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  pay.payment_id, pay.amount, pay.status AS payment_status, pay.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
ORDER BY b.start_date DESC;

/* ---------- BASELINE EXPLAIN ANALYZE ---------- */
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, b.end_date, b.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  pay.payment_id, pay.amount, pay.status AS payment_status, pay.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
ORDER BY b.start_date DESC;

/* ---------- REFACTORED: latest payment only (window) ---------- */
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
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
ORDER BY b.start_date DESC;

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
ORDER BY b.start_date DESC;
