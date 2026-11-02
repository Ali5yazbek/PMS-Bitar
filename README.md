# Property Management System (PMS)

An end-to-end **Enterprise Property, Energy, Maintenance & Financial Management Platform** unifying real-estate portfolio operations, automated rent & insurance ledgers, generator & electricity sub-metering, AC & tenant maintenance workflows, warehouse/POS inventory, and **Agency AI** across Web and Mobile (Android, iOS, and Web).

---

## Architecture Overview

```
PMS-Bitar/
├── backend/                # PHP 8+ REST API (JWT Auth, Router, PDO MySQL, NLP Engine)
│   ├── controllers/        # Domain controllers (Buildings, Tenants, Contracts, Energy, AI, etc.)
│   ├── core/               # Database, JWT, Router, NLPEngine, Audit & Integrity Scanners
│   ├── cron/               # Automated daily/monthly rent, compliance & notification schedulers
│   └── services/           # RentGenerationService & automated billing engines
├── frontend/               # React 18 Enterprise Web Portal (Tailwind CSS, Recharts, i18next EN/FR)
│   └── src/
│       ├── components/     # Shared layouts, modals, AI assistant, print layouts
│       └── pages/          # Admin, Manager, Cashier, Agent, and Tenant web portals
├── mobile/                 # Flutter Cross-Platform App (Android, iOS, Web — Riverpod & GoRouter)
│   └── lib/
│       ├── config/         # Luxury Obsidian & Royal Teal/Gold Design System
│       ├── providers/      # Riverpod state management & instant RAM auth/API caching
│       ├── screens/        # Role-based shells (Admin, Manager, Agent, Maintenance, Tenant)
│       └── services/       # Deduplicated, cached Dio API client & background prefetcher
└── python_microservice/    # FastAPI & Pandas/OpenPyXL microservice for executive Excel exports
```

---

## Key Modules & Capabilities

### 1. Property, Lease & Rent Automation
* **Buildings & Apartments**: Track occupancy (`Rented` vs. `Vacant`), monthly rent, insurance deposits, and unit-level profitability.
* **Smart Contracts & Rent Profiles**: Automated monthly/periodic rent invoice generation, partial payment tracking, overdue calculation, and lease renewal/termination archiving.
* **Insurance Ledger**: Dedicated tenant deposit accounts and transaction histories.

### 2. Energy, Generators & Sub-Metering
* **Generator Telemetry & Fuel Reserves**: Track generator KVA capacity, daily runtime logs, fuel refills, transfers, and consumption anomalies.
* **Apartment Electricity & Subscriptions**: Manage `Meter` (kWh), `Subscription`, and `Fixed Subscription` (Amps) plans with photo-verified meter reading submissions and automated invoice generation.

### 3. Field Agent & Maintenance Operations
* **Field Agent Mobile Hub**: Submit generator readings, apartment electricity readings, apartment cost/purchase receipts, and collect rent with QR/receipt verification.
* **AC & Tenant Maintenance**: Preventative AC maintenance scheduling, tenant-submitted repair tickets (with photo/audio attachments), technician task assignment, and admin approval queues.

### 4. Warehouse, Suppliers, Construction & POS
* **Inventory & Multi-Depot Transfers**: Track stock across warehouses, depots, and active construction sites.
* **Point of Sale (POS) & Cashier Sessions**: Daily cashier session management, sales invoicing, returns, and direct apartment expense allocation.

### 5. Agency AI (Full-Database Natural Language Intelligence)
* Built-in **Agency AI** assistant on Web and Mobile that understands natural human questions in **English, French, and Arabic**.
* Generates **360° Dossiers** for any tenant, apartment, building, or staff member—combining personal profiles, lease contracts, full invoice/debt ledgers, generator/electricity subscriptions, maintenance tickets, and apartment purchases in real time.

---

## Role-Based Access Control (RBAC)

| Role | Portal / Shell | Primary Capabilities |
| :--- | :--- | :--- |
| **Admin** | Web & Mobile Executive Suite | Full portfolio control, financial & audit reports, approval queues, permission matrix, Agency AI |
| **Manager** | Manager Operations Hub | Building & apartment oversight, maintenance verification, operational reporting |
| **Agent** | Field Agent Mobile App | Meter readings, generator daily logs, apartment purchases, rent collection |
| **Maintenance** | Technician Portal | Assigned AC maintenance tasks & tenant repair ticket execution |
| **Cashier** | POS & Cashier Portal | Daily register sessions, POS checkout, expense logging |
| **Tenant** | Tenant Self-Service Portal | Contract viewing/signing, rent & electricity invoice history, maintenance ticket submission |

---

## License
Proprietary — All rights reserved.
