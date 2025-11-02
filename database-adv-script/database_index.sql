/* =========================================================
   Database Indexing + Measurement (Baseline -> After Index)
   Works on MySQL 8.0.18+ and PostgreSQL 12+.

   Tip: Run this whole file. It records EXPLAIN ANALYZE
   output before and after indexes are created.

   NOTE on dialect differences (do not execute these comments):
   - MySQL:   EXPLAIN ANALYZE <query>;
   - Postgres:EXPLAIN ANALYZE <query>;
   Both supported, but DDL differs when dropping indexes.
========================================================= */

/* -------- Baseline measurements (NO new indexes yet) -------- */

/* Baseline Q1: bookings JOIN users filtered by start_date & status */
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, b.status, u.email
FROM bookings b
JOIN users u ON u.user_id = b.user_id
WHERE b.start_date >= DATE '2025-01-01' AND b.status = 'confirmed'
ORDER BY b.start_date DESC
LIMIT 100;

/* Baseline Q2: properties LEFT JOIN reviews filtered by location, ordered by created_at */
EXPLAIN ANALYZE
SELECT
  p.property_id, p.name, r.review_id, r.rating, r.created_at
FROM properties p
LEFT JOIN reviews r ON r.property_id = p.property_id
WHERE p.location = 'Paris'
ORDER BY r.created_at DESC
LIMIT 100;

/* Baseline Q3: latest payment per booking via window (or use correlated subquery on older engines) */
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, lp.payment_id, lp.amount, lp.status, lp.paid_at
FROM bookings b
LEFT JOIN latest_pay lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
WHERE b.start_date >= DATE '2025-01-01'
ORDER BY b.start_date DESC
LIMIT 100;

/* -------- Create indexes for JOIN/WHERE/ORDER patterns -------- */

/* USERS */
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_last_first ON users(last_name, first_name);

/* PROPERTIES */
CREATE INDEX IF NOT EXISTS idx_properties_host ON properties(host_id);
CREATE INDEX IF NOT EXISTS idx_properties_location ON properties(location);

/* REVIEWS */
CREATE INDEX IF NOT EXISTS idx_reviews_property ON reviews(property_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created ON reviews(created_at);
/* Optional composite to support WHERE property_id + ORDER BY created_at */
CREATE INDEX IF NOT EXISTS idx_reviews_property_created ON reviews(property_id, created_at);

/* BOOKINGS */
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_property ON bookings(property_id);
CREATE INDEX IF NOT EXISTS idx_bookings_start ON bookings(start_date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
/* Optional composite to support property/date range queries */
CREATE INDEX IF NOT EXISTS idx_bookings_property_start ON bookings(property_id, start_date);

/* PAYMENTS */
CREATE INDEX IF NOT EXISTS idx_payments_booking ON payments(booking_id);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);
/* Optional composite: look up latest payment per booking efficiently */
CREATE INDEX IF NOT EXISTS idx_payments_booking_paid_at ON payments(booking_id, paid_at);

/* (Postgres) Gather fresh stats so plans reflect new indexes */
ANALYZE users;
ANALYZE properties;
ANALYZE reviews;
ANALYZE bookings;
ANALYZE payments;

/* (MySQL) Optional: ANALYZE TABLE to update stats */
-- ANALYZE TABLE users, properties, reviews, bookings, payments;

/* -------- After-index measurements (same queries) -------- */

/* After-Index Q1 */
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, b.status, u.email
FROM bookings b
JOIN users u ON u.user_id = b.user_id
WHERE b.start_date >= DATE '2025-01-01' AND b.status = 'confirmed'
ORDER BY b.start_date DESC
LIMIT 100;

/* After-Index Q2 */
EXPLAIN ANALYZE
SELECT
  p.property_id, p.name, r.review_id, r.rating, r.created_at
FROM properties p
LEFT JOIN reviews r ON r.property_id = p.property_id
WHERE p.location = 'Paris'
ORDER BY r.created_at DESC
LIMIT 100;

/* After-Index Q3 */
WITH latest_pay AS (
  SELECT
    payment_id, booking_id, amount, status, paid_at,
    ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY paid_at DESC) AS rn
  FROM payments
)
EXPLAIN ANALYZE
SELECT
  b.booking_id, b.start_date, lp.payment_id, lp.amount, lp.status, lp.paid_at
FROM bookings b
LEFT JOIN latest_pay lp
  ON lp.booking_id = b.booking_id AND lp.rn = 1
WHERE b.start_date >= DATE '2025-01-01'
ORDER BY b.start_date DESC
LIMIT 100;

/* -------- Optional cleanup snippets (commented; pick your engine) -------- */

-- PostgreSQL drops:
-- DROP INDEX IF EXISTS idx_users_email;
-- DROP INDEX IF EXISTS idx_users_last_first;
-- DROP INDEX IF EXISTS idx_properties_host;
-- DROP INDEX IF EXISTS idx_properties_location;
-- DROP INDEX IF EXISTS idx_reviews_property;
-- DROP INDEX IF EXISTS idx_reviews_created;
-- DROP INDEX IF EXISTS idx_reviews_property_created;
-- DROP INDEX IF EXISTS idx_bookings_user;
-- DROP INDEX IF EXISTS idx_bookings_property;
-- DROP INDEX IF EXISTS idx_bookings_start;
-- DROP INDEX IF EXISTS idx_bookings_status;
-- DROP INDEX IF EXISTS idx_bookings_property_start;
-- DROP INDEX IF EXISTS idx_payments_booking;
-- DROP INDEX IF EXISTS idx_payments_paid_at;
-- DROP INDEX IF EXISTS idx_payments_booking_paid_at;

-- MySQL drops (syntax differs):
-- DROP INDEX idx_users_email ON users;
-- DROP INDEX idx_users_last_first ON users;
-- DROP INDEX idx_properties_host ON properties;
-- DROP INDEX idx_properties_location ON properties;
-- DROP INDEX idx_reviews_property ON reviews;
-- DROP INDEX idx_reviews_created ON reviews;
-- DROP INDEX idx_reviews_property_created ON reviews;
-- DROP INDEX idx_bookings_user ON bookings;
-- DROP INDEX idx_bookings_property ON bookings;
-- DROP INDEX idx_bookings_start ON bookings;
-- DROP INDEX idx_bookings_status ON bookings;
-- DROP INDEX idx_bookings_property_start ON bookings;
-- DROP INDEX idx_payments_booking ON payments;
-- DROP INDEX idx_payments_paid_at ON payments;
-- DROP INDEX idx_payments_booking_paid_at ON payments;
