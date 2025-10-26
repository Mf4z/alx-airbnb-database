
## `database-script-0x01/schema.sql`
```sql
-- Airbnb Clone — PostgreSQL Schema
-- Updated: 2025-10-26

-- Extensions (choose one; default to pgcrypto)
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- for gen_random_uuid()
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- alternative: uuid_generate_v4()

-- ==== ENUM types ====
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM ('guest','host','admin');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'booking_status') THEN
    CREATE TYPE booking_status AS ENUM ('pending','confirmed','canceled');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payment_method') THEN
    CREATE TYPE payment_method AS ENUM ('credit_card','paypal','stripe');
  END IF;
END$$;

-- ==== USERS ====
CREATE TABLE IF NOT EXISTS "user" (
  user_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name     VARCHAR(100) NOT NULL,
  last_name      VARCHAR(100) NOT NULL,
  email          VARCHAR(255) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  phone_number   VARCHAR(50),
  role           user_role NOT NULL DEFAULT 'guest',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==== PROPERTY ====
CREATE TABLE IF NOT EXISTS property (
  property_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id        UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  name           VARCHAR(160) NOT NULL,
  description    TEXT NOT NULL,
  location       VARCHAR(255) NOT NULL,
  pricepernight  NUMERIC(12,2) NOT NULL CHECK (pricepernight > 0),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-update updated_at (optional trigger)
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_property_updated_at ON property;
CREATE TRIGGER trg_property_updated_at
BEFORE UPDATE ON property
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ==== BOOKING ====
CREATE TABLE IF NOT EXISTS booking (
  booking_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id  UUID NOT NULL REFERENCES property(property_id) ON DELETE RESTRICT,
  user_id      UUID NOT NULL REFERENCES "user"(user_id) ON DELETE RESTRICT,
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  total_price  NUMERIC(12,2) NOT NULL CHECK (total_price >= 0),
  status       booking_status NOT NULL DEFAULT 'pending',
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (end_date > start_date)
);

-- Optional: prevent overlaps per property using daterange + exclusion constraint
-- Requires btree_gist extension
-- CREATE EXTENSION IF NOT EXISTS btree_gist;
-- ALTER TABLE booking
--   ADD EXCLUDE USING gist (
--     property_id WITH =,
--     daterange(start_date, end_date, '[]') WITH &&
--   ) WHERE (status IN ('pending','confirmed'));

-- ==== PAYMENT (1:1 with booking) ====
CREATE TABLE IF NOT EXISTS payment (
  payment_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id     UUID NOT NULL UNIQUE REFERENCES booking(booking_id) ON DELETE CASCADE,
  amount         NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
  payment_date   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  payment_method payment_method NOT NULL
);

-- ==== REVIEW ====
CREATE TABLE IF NOT EXISTS review (
  review_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id  UUID NOT NULL REFERENCES property(property_id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
  rating       INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment      TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uniq_review_per_user_property UNIQUE (property_id, user_id)
);

-- ==== MESSAGE ====
CREATE TABLE IF NOT EXISTS message (
  message_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id     UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
  recipient_id  UUID NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
  message_body  TEXT NOT NULL,
  sent_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==== Helpful indexes (FK helpers & lookups) ====
CREATE INDEX IF NOT EXISTS idx_user_email ON "user"(email);
CREATE INDEX IF NOT EXISTS idx_property_host ON property(host_id);
CREATE INDEX IF NOT EXISTS idx_booking_property ON booking(property_id);
CREATE INDEX IF NOT EXISTS idx_booking_user ON booking(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_booking ON payment(booking_id);
CREATE INDEX IF NOT EXISTS idx_review_property ON review(property_id);
CREATE INDEX IF NOT EXISTS idx_review_user ON review(user_id);
CREATE INDEX IF NOT EXISTS idx_message_sender ON message(sender_id);
CREATE INDEX IF NOT EXISTS idx_message_recipient ON message(recipient_id);
