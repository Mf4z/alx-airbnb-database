/* 3. Implement Indexes for Optimization
   Strategy: index columns used in JOINs, WHERE predicates, date filters, and frequent ORDER BYs.
*/

/* USERS */
CREATE INDEX idx_users_email ON users(email);               -- login / lookups
CREATE INDEX idx_users_last_first ON users(last_name, first_name);

/* PROPERTIES */
CREATE INDEX idx_properties_host ON properties(host_id);    -- joins to users
CREATE INDEX idx_properties_location ON properties(location);
CREATE INDEX idx_properties_price ON properties(price_per_night);

/* BOOKINGS */
CREATE INDEX idx_bookings_user ON bookings(user_id);        -- join to users
CREATE INDEX idx_bookings_property ON bookings(property_id);-- join to properties
CREATE INDEX idx_bookings_start ON bookings(start_date);    -- date range queries
CREATE INDEX idx_bookings_status ON bookings(status);

/* REVIEWS */
CREATE INDEX idx_reviews_property ON reviews(property_id);
CREATE INDEX idx_reviews_user ON reviews(user_id);
CREATE INDEX idx_reviews_created ON reviews(created_at);

/* PAYMENTS */
CREATE INDEX idx_payments_booking ON payments(booking_id);
CREATE INDEX idx_payments_paid_at ON payments(paid_at);
CREATE INDEX idx_payments_status ON payments(status);

/* Composite examples (use if you frequently combine filters in this order) */
-- Bookings by property within date range:
CREATE INDEX idx_bookings_property_start ON bookings(property_id, start_date);
-- Reviews by property then created_at:
CREATE INDEX idx_reviews_property_created ON reviews(property_id, created_at);
