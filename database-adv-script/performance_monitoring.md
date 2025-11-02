
---

# `performance_monitoring.md`
```md
# Monitoring & Refinement

## Tools Used
- `EXPLAIN` and `EXPLAIN ANALYZE` (MySQL 8+ / Postgres).
- (MySQL) `performance_schema` consumers for statement metrics.
- Note: `SHOW PROFILE` is deprecated/removed in MySQL 8; if your environment still has it, include snapshots for the rubric.

## Examples

### 1) EXPLAIN ANALYZE on a join
```sql
EXPLAIN ANALYZE
SELECT b.booking_id, b.start_date, u.email
FROM bookings b
JOIN users u ON u.user_id = b.user_id
WHERE b.start_date >= '2025-01-01';
