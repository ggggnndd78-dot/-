# Ghiyarak Customer Support & Complaint Management

## Scope

This document describes the Phase 18 implementation for customer support and complaint management. It builds on the existing support foundation and keeps compatibility with previous phases.

## Implemented Capabilities

- Support tickets
- Ticket conversations
- Internal support notes
- Ticket attachments metadata
- Ticket assignment
- Ticket reopen and status updates
- Complaint submission and review
- Complaint linkage to orders, service orders, payments, shipments, and organizations
- Help center categories
- Help center articles
- FAQ system
- WhatsApp support links
- Notifications for ticket and complaint changes
- Audit logging for support actions

## Main Tables

- support_tickets
- support_ticket_messages
- support_ticket_attachments
- support_complaints
- help_center_categories
- help_center_articles
- faqs
- whatsapp_support_links

## Ticket Workflow

OPEN → IN_PROGRESS → WAITING_CUSTOMER / WAITING_SUPPORT → RESOLVED → CLOSED

Tickets can be reopened from RESOLVED or CLOSED by an authorized user.

## Complaint Workflow

SUBMITTED → UNDER_REVIEW → INVESTIGATION → RESOLVED / REJECTED → CLOSED

Complaints can reference:

- Order
- Merchant organization
- Workshop organization
- Workshop service order
- Delivery shipment
- Payment transaction

## Security

- Customers see only their own tickets and complaints.
- Support agents and admins can manage all support records.
- Organization members can see support items related to their organization.
- Internal notes are hidden from customers.
- Every critical action writes an audit log.

## APIs

### Tickets

- POST /support/tickets
- GET /support/tickets/my
- GET /support/tickets/manage
- GET /support/tickets/:id
- POST /support/tickets/:id/messages
- PATCH /support/tickets/:id/assign
- PATCH /support/tickets/:id/status
- PATCH /support/tickets/:id/reopen

### Complaints

- POST /support/complaints
- GET /support/complaints/my
- GET /support/complaints/manage
- GET /support/complaints/:id
- PATCH /support/complaints/:id/status

### Help Center

- GET /support/help/categories
- POST /support/help/categories
- PATCH /support/help/categories/:id
- GET /support/help/articles
- GET /support/help/articles/:slug
- POST /support/help/articles
- PATCH /support/help/articles/:id

### FAQs

- GET /support/faqs
- POST /support/faqs
- PATCH /support/faqs/:id

### WhatsApp Links

- GET /support/whatsapp-links
- POST /support/whatsapp-links
- PATCH /support/whatsapp-links/:id

## UI

Flutter includes:

- Help Center page
- Ticket list
- Ticket details and conversation
- Complaint list and submission
- Support operations hub

## Future Expansion

The design supports future analytics such as:

- Ticket volume
- Resolution time
- Complaint categories
- Agent performance
- Customer satisfaction
