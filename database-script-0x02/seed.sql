
## `database-script-0x02/seed.sql`
```sql
-- Airbnb Clone — Sample Seed Data
-- Updated: 2025-10-26

-- Assumes schema is created and pgcrypto extension is enabled.

-- Users
INSERT INTO "user" (user_id, first_name, last_name, email, password_hash, phone_number, role)
VALUES
  (gen_random_uuid(), 'Alice', 'Hoster', 'alice@example.com', '$2b$10$hashA', '+33111111111', 'host'),
  (gen_random_uuid(), 'Bob', 'Guest',  'bob@example.com',   '$2b$10$hashB', '+33222222222', 'guest'),
  (gen_random_uuid(), 'Carol','Admin', 'carol@example.com', '$2b$10$hashC', '+33333333333', 'admin')
RETURNING user_id, email;

-- Grab IDs for convenience (psql variables)
-- (If running programmatically, fetch IDs after insert.)
-- For psql demo purposes, select them:
-- SELECT * FROM "user";

-- Properties (owned by Alice)
WITH host AS (
  SELECT user_id FROM "user" WHERE email='alice@example.com' LIMIT 1
)
INSERT INTO property (property_id, host_id, name, description, location, pricepernight)
SELECT gen_random_uuid(), host.user_id, 'Sunny Studio', 'Cozy studio near center', 'Paris, FR', 95.00 FROM host
UNION ALL
SELECT gen_random_uuid(), host.user_id, 'Loft Canal', 'Spacious loft by the canal', 'Paris, FR', 140.00 FROM host
RETURNING property_id, name;

-- Bookings (Bob books both properties)
WITH g AS (SELECT user_id FROM "user" WHERE email='bob@example.com' LIMIT 1),
     p AS (SELECT property_id, name FROM property ORDER BY name)
INSERT INTO booking (booking_id, property_id, user_id, start_date, end_date, total_price, status)
SELECT gen_random_uuid(), p.property_id, g.user_id, DATE '2025-11-10', DATE '2025-11-12', 2 * 95.00, 'confirmed'
FROM g, (SELECT property_id FROM property WHERE name='Sunny Studio' LIMIT 1) p
UNION ALL
SELECT gen_random_uuid(), p.property_id, g.user_id, DATE '2025-12-20', DATE '2025-12-23', 3 * 140.00, 'pending'
FROM g, (SELECT property_id FROM property WHERE name='Loft Canal' LIMIT 1) p
RETURNING booking_id, status;

-- Payments (only the confirmed booking is paid)
WITH b AS (
  SELECT booking_id, total_price FROM booking WHERE status='confirmed' LIMIT 1
)
INSERT INTO payment (payment_id, booking_id, amount, payment_method)
SELECT gen_random_uuid(), b.booking_id, b.total_price, 'stripe' FROM b;

-- Reviews (Bob reviews Sunny Studio)
WITH u AS (SELECT user_id FROM "user" WHERE email='bob@example.com' LIMIT 1),
     p AS (SELECT property_id FROM property WHERE name='Sunny Studio' LIMIT 1)
INSERT INTO review (review_id, property_id, user_id, rating, comment)
SELECT gen_random_uuid(), p.property_id, u.user_id, 5, 'Great stay, very clean and central.' FROM u, p;

-- Messages (Bob → Alice)
WITH s AS (SELECT user_id FROM "user" WHERE email='bob@example.com' LIMIT 1),
     r AS (SELECT user_id FROM "user" WHERE email='alice@example.com' LIMIT 1)
INSERT INTO message (message_id, sender_id, recipient_id, message_body)
SELECT gen_random_uuid(), s.user_id, r.user_id, 'Hi Alice, what is the check-in time?' FROM s, r;
