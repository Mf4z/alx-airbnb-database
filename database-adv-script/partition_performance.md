# Partition Performance

**Goal:** Speed up date-range queries on `bookings`.

## Query Tested
```sql
EXPLAIN ANALYZE
SELECT booking_id, user_id, property_id, start_date, end_date, status
FROM bookings_part
WHERE start_date BETWEEN '2025-01-01' AND '2025-06-30';
