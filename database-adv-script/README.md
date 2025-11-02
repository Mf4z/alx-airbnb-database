# Database Advanced Script — ALX Airbnb Module

This directory contains advanced SQL deliverables: joins, subqueries, aggregations & window functions, indexing, optimization, partitioning, and performance monitoring.

## Files
- `joins_queries.sql` – INNER/LEFT/FULL OUTER JOIN queries (+ MySQL fallback for FULL OUTER).
- `subqueries.sql` – Correlated & non-correlated subqueries.
- `aggregations_and_window_functions.sql` – GROUP BY + window functions (ROW_NUMBER, RANK).
- `database_index.sql` – Index DDL for high-usage columns.
- `index_performance.md` – Before/after EXPLAIN/ANALYZE notes.
- `perfomance.sql` – Initial “heavy” query + refactor attempt(s).
- `optimization_report.md` – What we changed and why (with plan diffs).
- `partitioning.sql` – Booking table partitioning by `start_date`.
- `partition_performance.md` – Range query timings before/after partitioning.
- `performance_monitoring.md` – Monitoring using EXPLAIN ANALYZE (and alternatives to SHOW PROFILE).

## Assumptions
- Schema keys:
  - bookings.user_id → users.user_id
  - bookings.property_id → properties.property_id
  - properties.host_id → users.user_id
  - reviews.property_id → properties.property_id
  - payments.booking_id → bookings.booking_id
- Target engines: MySQL 8+ or PostgreSQL 13+. Where syntax differs, both versions are shown.

## How to run
- MySQL: `mysql -u root -p < file.sql`
- Postgres: `psql -d yourdb -f file.sql`

## Manual QA
When done, request manual QA review and include:
- Links to this directory
- The `*_performance.md` reports
- DB version output (`SELECT VERSION();`)
