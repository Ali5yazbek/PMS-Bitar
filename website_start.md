# Bitar Property Management & ERP System - Full System Architecture (A to Z)

This document provides a comprehensive, end-to-end overview of the Bitar system, encompassing the backend API (PHP) and the mobile application (Flutter/Dart). It details every user role, system module, mobile screen, and database table.

---

## 1. System Overview

Bitar is a complete Property Management System (PMS) and Enterprise Resource Planning (ERP) platform. It handles everything from tenant contracts and rent collection to generator fuel monitoring, electricity metering, construction projects, warehouse inventory, and Point of Sale (POS) operations.

---

## 2. User Roles

The system operates based on specific user roles, each with distinct permissions, dashboards, and workflows:

### A. Admin (`admin`)
- **Description:** The superuser of the system with full control over all modules, global settings, users, and system data.
- **Access:** Complete access to all controllers and mobile screens.
- **Key Responsibilities:** System health monitoring, data integrity checks, full financial reporting, approval engine management, and overriding any process.

### B. Manager (`manager`)
- **Description:** Operational supervisors handling the day-to-day management of properties and finances.
- **Access:** Manager Dashboard, Financial Reports, Tenant management, Contracts, and maintenance approvals.
- **Key Responsibilities:** Approving contracts and renewals, overseeing agents, managing building expenses, and viewing analytical dashboards.

### C. Cashier (`cashier`)
- **Description:** Point of sale and financial collection personnel.
- **Access:** Cashier Dashboard, POS Screen, Invoices, Rent Collection, Electricity payments.
- **Key Responsibilities:** Receiving rent, processing walk-in and building-related invoices, issuing receipts, and reconciling daily cash.

### D. Agent / Worker (`agent` / `worker`)
- **Description:** On-the-ground personnel handling physical tasks such as maintenance, rent collection, and meter reading.
- **Access:** Agent Dashboard, Agent Collection History, Agent Subscriptions, Generator Reports, AC Maintenance tasks.
- **Key Responsibilities:** Adding generator daily reports, logging fuel movements, capturing AC maintenance photos (before/after), and performing energy verifications on site.

### E. Tenant (`tenant`)
- **Description:** Residents or commercial renters occupying the apartments.
- **Access:** Tenant Dashboard, Tenant Contracts, Tenant Payments, Tenant Subscriptions, Portal.
- **Key Responsibilities:** Viewing their active contracts, checking payment history (rent, electricity, insurance), paying bills, and submitting damage reports or maintenance requests.

---

## 3. Core Modules & Workflows (A to Z)

### A. Real Estate & Property Management
- **Buildings & Apartments:** Management of physical assets, tracking status (Vacant, Rented, Maintenance).
- **Tenants:** Registration of tenants, including ID/passport uploads, contact information, and emergency contacts.
- **Contracts:** Digital leasing agreements detailing monthly rent, insurance, start/end dates, and payment terms. Supports states like Draft, Pending Signature, Signed, Approved, Terminated, and Expired. 
- **Renewals:** System handles contract renewal requests and approvals.

### B. Financials & Accounting
- **Rent Invoices & Payments:** Automated invoice generation for rent, supporting partial or full payments.
- **Insurance Hub:** Dedicated module to track insurance deposits, refunds, deductions (for damages), and application of insurance funds towards rent.
- **General Invoices:** Used for all POS/Accounting transactions, categorized by Walk-In, Building, Apartment, or Construction.
- **Expenses & Profit/Loss:** Tracking all operational costs against specific entities (apartments, buildings, generators).

### C. Utility Management (Energy & Electricity)
- **Electricity Subscriptions:** Fixed-rate subscriptions based on Amps.
- **Meter Readings:** Capturing previous and current kWh meter readings to calculate variable consumption bills.
- **Invoicing:** Generating hybrid electricity invoices combining subscriptions and meter readings.

### D. Generator & Fuel Management (AI-Powered)
- **Generators:** Tracking capacity, fuel thresholds, maintenance schedules, and efficiency scores.
- **Fuel Movements:** Logging every refill, transfer, and adjustment of diesel/fuel.
- **Daily Reports:** Agents submit daily metrics (running hours, meter hours, fuel added) with photo evidence.
- **AI Analytics:** The system utilizes an AI Controller to profile generator consumption patterns, detect anomalies, calculate efficiency metrics, and trigger predictive alerts (Warning/Critical).

### E. Maintenance & Operations
- **AC Maintenance:** Task scheduling for workers to service AC units. Requires before and after photos and manager approval.
- **Damage Reports:** Incidents reported by tenants or agents, linked to financial transactions if insurance needs to be deducted.
- **Approval Engine:** Complex workflow engine to handle requests requiring higher-level sign-off (e.g., contract approvals, purchase requests).

### F. Inventory, Warehouse & POS (ERP Features)
- **Products & Stock:** Managing catalog, categories, selling prices, and minimum stock alerts.
- **Inventory & Stock Movements:** Tracking "IN" and "OUT" movements for full traceability across warehouses/depots.
- **POS Screen:** A cashier interface for processing immediate sales of items.

### G. Construction & Workshop
- **Constructions & Projects:** Managing large-scale real estate development (budgets, timelines, land area, progress tracking).
- **Workshop Estimates & Specifications:** Detailing required materials, unit costs, and structural features (bedrooms, elevators, parking) for new developments.

---

## 4. Mobile Application Structure (Flutter)

The mobile app provides dedicated views depending on the authenticated role. Key screens include:

- **Auth:** `login_screen.dart`
- **Shell:** `main_shell.dart`, `dashboard_screen.dart`, `global_search_screen.dart`, `notifications_screen.dart`, `settings_screen.dart`
- **Dashboards:** `admin_mobile_monitoring_screen.dart`, `manager_dashboard_screen.dart`, `cashier_dashboard_screen.dart`, `agent_dashboard_screen.dart`, `tenant_dashboard_screen.dart`
- **Real Estate:** `buildings_screen.dart`, `building_details_screen.dart`, `apartments_screen.dart`, `tenants_screen.dart`, `tenant_details_screen.dart`, `contracts_screen.dart`
- **Finance/Reports:** `financial_reports_screen.dart`, `financial_building_report_screen.dart`, `apartment_cost_report_screen.dart`, `insurance_hub_screen.dart`
- **Agent/Operations:** `agent_apartments_screen.dart`, `agent_collection_history_screen.dart`, `agent_rent_collection_screen.dart`, `energy_verification_screen.dart`, `agent_generators_screen.dart`, `gen_report_screen.dart`, `agent_daily_report_screen.dart`
- **Maintenance:** `ac_maintenance_screen.dart`, `maintenance_dashboard_screen.dart`, `maintenance_history_screen.dart`, `unified_task_center_screen.dart`
- **ERP/Construction:** `warehouse_screen.dart`, `construction_screen.dart`, `workshop_screen.dart`, `workshop_details_screen.dart`, `pos_screen.dart`
- **Tenant Portal:** `tenant_contract_screen.dart`, `tenant_payments_screen.dart`, `tenant_subscriptions_screen.dart`

---

## 5. Database Schema (Table by Table)

Here is a complete list of all database tables handling the system's data:

### Users & Auditing
1. **`users`**: System access credentials and roles (`admin`, `manager`, `cashier`, `tenant`, etc.).
2. **`activity_logs`**: General tracking of what users do in the system.
3. **`audit_logs`**: High-security logging of critical data changes.

### Real Estate Entities
4. **`buildings`**: Main property structures.
5. **`apartments`**: Units within buildings; tracks monthly rent/insurance and vacancy status.
6. **`tenants`**: Renter profiles, linked to `users`, including ID scans.
7. **`contracts`**: The core binding agreement between a tenant and an apartment.
8. **`renewal_requests`**: Workflow for extending an expiring contract.

### Financials & Rent
9. **`rent_invoices`**: Generated bills for apartment rent.
10. **`rent_payments`**: Recorded payments against rent invoices.
11. **`insurance_accounts`**: Tracks the total insurance deposit held per contract.
12. **`insurance_transactions`**: Individual deposits, deductions, or refunds applied to an insurance account.
13. **`expenses`**: General operational costs.
14. **`apartment_expenses`**: Specific costs tied directly to an apartment's maintenance/upkeep.

### Utility & Electricity
15. **`electricity_subscriptions`**: Fixed-rate Amp subscriptions for apartments.
16. **`electricity_meter_readings`**: Logs of kW usage over time.
17. **`electricity_invoices`**: Billing for both subscriptions and meter usage.
18. **`energy_alerts`**: System notifications regarding abnormal energy consumption.

### Generator & AI Management
19. **`generators`**: Hardware specifications, baseline fuel metrics, and health scores.
20. **`generator_daily_reports`**: Submission of running hours, fuel levels, and kwh produced.
21. **`fuel_movements`**: Auditable trail of fuel added, transferred, or adjusted.
22. **`fuel_suppliers`**: Companies supplying diesel.
23. **`generator_alerts`**: Critical or Warning flags generated by anomalies in daily reports.
24. **`generator_ai_profiles`**: Long-term machine learning profiles mapping seasonal and load patterns.
25. **`generator_ai_summaries`**: AI-generated text summaries of daily/weekly performance.

### Maintenance & Operations
26. **`ac_maintenance_tasks`**: Scheduled jobs for servicing ACs, including photo verification.
27. **`damage_reports`**: Logs of property damage and associated photographic evidence.

### POS, Inventory & Purchasing
28. **`products`**: Catalog of items available for sale or use (cost, price, VAT, barcode).
29. **`invoices`**: Point of Sale transactions.
30. **`invoice_items`**: Line items for POS transactions.
31. **`inventory_items`**: Stock items tracked in warehouses.
32. **`inventory_transactions`**: General IN/OUT logging for inventory.
33. **`stock_movements`**: Specific product stock adjustments.
34. **`purchase_requests`**: Approval-based requests for ordering new stock or materials.

### Construction & Workshop
35. **`constructions`**: Ongoing building sites, tracking budget vs actual costs.
36. **`workshop_projects`**: Planning phase for new developments (floors, land area, apartments).
37. **`workshop_specifications`**: Blueprint details (bedrooms, kitchens, elevators, gardens).
38. **`workshop_estimates`**: Cost forecasting and material requirements for workshop projects.
39. **`estimation_rates`**: Standardized default pricing for workshop estimation units.
