# Index Performance Notes

**Setup**
- DB: MySQL 8.0.x (or PostgreSQL 13+)
- Tables: users, properties, bookings, reviews, payments
- Analyzed with `EXPLAIN` and `EXPLAIN ANALYZE`.

## Queries Tested

1) Bookings joined to Users (by user_id)
```sql
EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, u.email
FROM bookings b
JOIN users u ON u.user_id = b.user_id
WHERE b.start_date >= '2025-01-01' AND b.status = 'confirmed';
