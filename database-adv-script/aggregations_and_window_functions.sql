/* 2. Aggregations & Window Functions */

/* A) Total number of bookings per user */
SELECT
  u.user_id,
  u.first_name,
  u.last_name,
  COUNT(b.booking_id) AS total_bookings
FROM users AS u
LEFT JOIN bookings AS b
  ON b.user_id = u.user_id
GROUP BY u.user_id, u.first_name, u.last_name
ORDER BY total_bookings DESC;

/* B) Rank properties by total bookings (RANK and ROW_NUMBER examples) */
-- MySQL 8+ and PostgreSQL both support window functions
WITH property_counts AS (
  SELECT
    p.property_id,
    p.name,
    COUNT(b.booking_id) AS booking_count
  FROM properties AS p
  LEFT JOIN bookings AS b
    ON b.property_id = p.property_id
  GROUP BY p.property_id, p.name
)
SELECT
  property_id,
  name,
  booking_count,
  RANK()       OVER (ORDER BY booking_count DESC) AS popularity_rank,
  ROW_NUMBER() OVER (ORDER BY booking_count DESC) AS seq
FROM property_counts
ORDER BY booking_count DESC, name;
