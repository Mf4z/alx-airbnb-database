/* 0. Joins — Advanced Querying */

/* A) INNER JOIN: all bookings with the user who made them */
-- Postgres / MySQL (same)
SELECT
  b.booking_id,
  b.property_id,
  b.user_id,
  b.start_date,
  b.end_date,
  u.first_name,
  u.last_name,
  u.email
FROM bookings AS b
INNER JOIN users AS u
  ON b.user_id = u.user_id;

/* B) LEFT JOIN: all properties and their reviews (including properties with no reviews) */
SELECT
  p.property_id,
  p.name AS property_name,
  p.location,
  r.review_id,
  r.rating,
  r.comment,
  r.created_at
FROM properties AS p
LEFT JOIN reviews AS r
  ON p.property_id = r.property_id;

/* C) FULL OUTER JOIN: all users and all bookings, even if unrelated
   Postgres version (supports FULL OUTER JOIN): */
-- PostgreSQL:
SELECT
  u.user_id AS user_user_id,
  u.first_name,
  u.last_name,
  b.booking_id,
  b.user_id AS booking_user_id,
  b.property_id,
  b.start_date,
  b.end_date
FROM users AS u
FULL OUTER JOIN bookings AS b
  ON u.user_id = b.user_id;

/* C-alt) MySQL fallback (no FULL OUTER JOIN): simulate with UNION of LEFT and RIGHT joins */
-- MySQL 8+:
SELECT
  u.user_id AS user_user_id,
  u.first_name,
  u.last_name,
  b.booking_id,
  b.user_id AS booking_user_id,
  b.property_id,
  b.start_date,
  b.end_date
FROM users AS u
LEFT JOIN bookings AS b
  ON u.user_id = b.user_id
UNION
SELECT
  u.user_id AS user_user_id,
  u.first_name,
  u.last_name,
  b.booking_id,
  b.user_id AS booking_user_id,
  b.property_id,
  b.start_date,
  b.end_date
FROM users AS u
RIGHT JOIN bookings AS b
  ON u.user_id = b.user_id;
