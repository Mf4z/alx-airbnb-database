# Normalization to 3NF — Airbnb DB
_Updated: 2025-10-26_

This note documents how the schema reaches **Third Normal Form (3NF)**.

## 1. Assumptions & Keys
- **Primary keys**: UUIDs on all entities.
- **Foreign keys**: enforce referential integrity (e.g., `property.host_id → user.user_id`).
- **Natural keys**: `user.email` is unique; others use surrogate UUIDs.

## 2. 1NF (Atomic columns, primary keys, no repeating groups)
- All attributes are atomic (e.g., `rating` is an integer, not a list).
- Tables have a declared PK.
- No repeating columns like `photo1`, `photo2`, etc. (Photos would live in a separate table if/when needed.)

## 3. 2NF (No partial dependency on a composite key)
- Every table uses a **single-column** surrogate PK (UUID).  
- Therefore, no attribute depends on part of a composite key → **2NF satisfied**.

## 4. 3NF (No transitive dependencies on non-key attributes)
- **User**: derived values (e.g., full name) are not stored; `email` is unique. No non-key depends on other non-keys.
- **Property**: `host_id` (FK) is the only dependency outside; attributes (name, description, pricepernight) depend only on `property_id`.  
  _Optional improvement_: split `location` into `city`, `country` for better filtering. Kept as `location` to match requirements.
- **Booking**: `total_price` is derived but persisted for audit/performance; it depends on `(price at booking time, dates, fees)`. To maintain 3NF while persisting denormalized totals, we add:
  - `CHECK (end_date > start_date)`
  - Application/service is responsible for writing immutable `total_price` snapshot at booking time (business invariant).
- **Payment**: depends only on `booking_id` and its own attributes; payment method enumerated.
- **Review**: depends on both `user_id` and `property_id`.  
  Add **business uniqueness**: one review per user per booking (if reviews are tied to bookings later) or per user per property per completed stay. For now, we keep `UNIQUE (property_id, user_id)` to prevent duplicates.
- **Message**: both `sender_id` and `recipient_id` reference `user.user_id`. Content depends only on the PK.

Thus, no attribute is transitively dependent on another non-key attribute → **3NF holds**.

## 5. Additional Integrity Rules
- **Booking overlap** is enforced in application/service (can be assisted by exclusion constraints with daterange in PostgreSQL if we adopt them).
- **Review uniqueness**: `UNIQUE (property_id, user_id)`.
- **Status domains** via ENUMs ensure only valid states.
- **Email uniqueness** ensures no duplicates.

## 6. Index Strategy (Performance)
- Implicit PK indexes on all UUID PKs.
- Unique index on `user.email`.
- Foreign key helper indexes:  
  - `property.host_id`  
  - `booking.property_id`, `booking.user_id`  
  - `payment.booking_id`  
  - `review.property_id`, `review.user_id`  
  - `message.sender_id`, `message.recipient_id`
- Optional partial indexes for common filters (e.g., active bookings) and date-range queries.

**Conclusion**: The model satisfies 3NF while keeping a denormalized `total_price` snapshot for audit/perf (a conscious tradeoff with clear invariants).
