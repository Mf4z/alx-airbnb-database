
---

# `performance.sql`
```sql
/* 4. Optimize Complex Queries */

/* Initial (heavier) query: bookings + user + property + payment details */
-- Version 1 (baseline)
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
  p.name AS property_name,
  p.location,
  pay.payment_id,
  pay.amount,
  pay.status AS payment_status,
  pay.paid_at
FROM bookings b
JOIN users u       ON u.user_id = b.user_id
JOIN properties p  ON p.property_id = b.property_id
LEFT JOIN payments pay ON pay.booking_id = b.booking_id
WHERE b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)  /* MySQL */
-- For Postgres: WHERE b.start_date >= CURRENT_DATE - INTERVAL '6 months'
ORDER BY b.start_date DESC;

/* Refactored ideas:
   1) Restrict columns to only what's needed.
   2) Ensure indexes: bookings(start_date), bookings(user_id), bookings(property_id), payments(booking_id, paid_at).
   3) If only the latest payment matters, use a window or a MAX(paid_at) subquery.
*/

/* Version 2: limit to latest payment per booking */
-- MySQL 8 (window functions):
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
SELECT
  b.booking_id, b.start_date, b.end_date, b.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM bookings b
JOIN users u      ON u.user_id = b.user_id
JOIN properties p ON p.property_id = b.property_id
LEFT JOIN latest_pay lp ON lp.booking_id = b.booking_id AND lp.rn = 1
WHERE b.start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
ORDER BY b.start_date DESC;

/* Version 3: if payments table is huge, prefilter date range first (semi-join) */
WITH recent_bookings AS (
  SELECT booking_id, user_id, property_id, start_date, end_date, status
  FROM bookings
  WHERE start_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
)
SELECT
  rb.booking_id, rb.start_date, rb.end_date, rb.status AS booking_status,
  u.user_id, u.first_name, u.last_name, u.email,
  p.property_id, p.name AS property_name, p.location,
  lp.payment_id, lp.amount, lp.status AS payment_status, lp.paid_at
FROM recent_bookings rb
JOIN users u      ON u.user_id = rb.user_id
JOIN properties p ON p.property_id = rb.property_id
LEFT JOIN (
  SELECT x.*
  FROM (
    SELECT
      payment_id, booking_id, amount, status, paid_at,
      ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
    FROM payments
  ) x
  WHERE x.rn = 1
) lp ON lp.booking_id = rb.booking_id
ORDER BY rb.start_date DESC;
