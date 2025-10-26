# Airbnb Clone Database — Entity Relationship Diagram (ERD)
_Updated: 2025-10-26_

This document describes the **entities**, **attributes**, and **relationships** in the Airbnb Clone database schema.  
The design ensures data integrity, minimal redundancy, and efficient querying through proper normalization.

---

## 🧱 Entities Overview

### User
- **user_id** (PK, UUID)
- first_name, last_name, email (unique), password_hash
- phone_number, role (guest, host, admin)
- created_at

### Property
- **property_id** (PK, UUID)
- host_id (FK → User.user_id)
- name, description, location, pricepernight
- created_at, updated_at

### Booking
- **booking_id** (PK, UUID)
- property_id (FK → Property.property_id)
- user_id (FK → User.user_id)
- start_date, end_date, total_price, status
- created_at

### Payment
- **payment_id** (PK, UUID)
- booking_id (FK → Booking.booking_id)
- amount, payment_date, payment_method

### Review
- **review_id** (PK, UUID)
- property_id (FK → Property.property_id)
- user_id (FK → User.user_id)
- rating, comment, created_at

### Message
- **message_id** (PK, UUID)
- sender_id (FK → User.user_id)
- recipient_id (FK → User.user_id)
- message_body, sent_at

---

## 🔗 Relationships

| Relationship | Type | Description |
|---------------|-------|-------------|
| User → Property | 1 : N | A Host can have many Properties |
| User → Booking | 1 : N | A Guest can make many Bookings |
| Property → Booking | 1 : N | A Property can be booked many times |
| Booking → Payment | 1 : 1 | Each Booking has one Payment record |
| User → Review | 1 : N | A User can post many Reviews |
| Property → Review | 1 : N | A Property can have many Reviews |
| User → Message | 1 : N | A User can send and receive many Messages |

---
