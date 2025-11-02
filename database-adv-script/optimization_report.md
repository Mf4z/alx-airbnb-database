# Optimization Report

## Baseline
- Query: `perfomance.sql` Version 1.
- Plan: full/large scans on `payments` and `bookings` when unindexed; external sort on `ORDER BY b.start_date DESC`.

## Changes Applied
1. **Indexes**
   - `bookings(start_date)`, `bookings(user_id)`, `bookings(property_id)`
   - `payments(booking_id, paid_at)`
2. **Column Pruning**
   - Selected only necessary columns.
3. **Latest Payment Only**
   - Window function approach to avoid joining all payments per booking.
4. **Prefiltering**
   - `recent_bookings` CTE to cut input size early.

## Results (illustrative)
- Examined rows ↓ by ~70–95% on large data.
- Sort cost ↓ due to `start_date` index and earlier filtering.
- Elapsed time: improved from **X ms** → **Y ms** (fill with your EXPLAIN ANALYZE numbers).

## Notes
- If MySQL < 8, replace window function with a correlated subquery:
```sql
LEFT JOIN payments lp
  ON lp.booking_id = b.booking_id
 AND lp.paid_at = (
   SELECT MAX(p2.paid_at) FROM payments p2 WHERE p2.booking_id = b.booking_id
 )
