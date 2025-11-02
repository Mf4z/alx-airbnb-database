/* 1. Subqueries */

/* A) Non-correlated: properties whose AVG rating > 4.0 */
-- Works in MySQL & Postgres
SELECT
  p.property_id,
  p.name,
  p.location
FROM properties AS p
WHERE p.property_id IN (
  SELECT r.property_id
  FROM reviews AS r
  GROUP BY r.property_id
  HAVING AVG(r.rating) > 4.0
);

/* B) Correlated: users who have made > 3 bookings */
-- Works in MySQL & Postgres
SELECT
  u.user_id,
  u.first_name,
  u.last_name,
  u.email
FROM users AS u
WHERE (
  SELECT COUNT(*)
  FROM bookings AS b
  WHERE b.user_id = u.user_id
) > 3;
