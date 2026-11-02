Top Navigation & Filters
Search Bar: A global search input to quickly find specific tenants, buildings, or receipt numbers.

Date Filter: A date picker defaulted strictly to Today's Date. (Agents can change this if they need to view past records, but it always resets to 'Today' on load).

Summary & Actions
Total Collection Card:

Displays: "Total Collected Today: [Amount]"

Displays: "Agent: [Agent Name]"

[Export to PDF] Button: Clicking this generates a printable daily summary report containing the Agent's name, the date, an itemized list of today's collections, and the grand total.

[+ Add Collection] Button: A prominent primary button that triggers the centered pop-up window.

Main Data Table
A table displaying the day's logged collections (matching the current date filter).

Columns: Time, Type (Rent/Electricity/Insurance), Building, Apartment, Tenant Name, Month(s) Covered, Amount Received, Status.

2. "Add Collection" Modal (Centered Pop-up)
When the agent clicks [+ Add Collection], a centered modal appears. The workflow inside this modal progresses logically:

Step 1: Collection Type
Dropdown/Radio Buttons: The agent must select what they are collecting money for:

Insurance

Rent Apartment

Electricity Subscription

Step 2: Location & Tenant Search
Building Search: A searchable dropdown field. The agent types the name of the building and selects it.

Apartment/Tenant Search: Once the building is selected, this secondary field unlocks. The agent can search by Tenant Name or Apartment Number. (This dropdown only shows records tied to the building selected above).

Step 3: Verification & Due Details
Once the tenant/apartment is selected, the system pulls their data.

Tenant Information (Read-Only): Displays full details (Tenant Name, Phone, Lease Start, ID/Reference). These fields are locked and cannot be edited by the Agent.

Due Months Selection: A checklist or multi-select dropdown showing all unpaid months.

If the tenant owes for multiple months (e.g., March, April, May), the agent selects which specific month(s) this payment covers.

Amount Due: Automatically displays the total expected amount based on the selected type and months.

Step 4: Payment Verification Method
The agent chooses how to verify the payment:

Option A: Scan QR Code (Recommended)

Opens the device camera or a scanner interface.

The Agent scans the QR code generated from the Tenant Role -> Apartments Page (which the tenant creates after a successful payment on their end).

Validation: The system checks the QR code. If it doesn't match the selected tenant, building, or payment type, it throws an error: "Invalid QR Code. Payment mismatch." and blocks the process.

Option B: Manual Collection

Used if the tenant is paying in cash or the QR code system is unavailable.

Step 5: Final Amount Entry & Submission
Amount Received: Regardless of the expected amount, this input field defaults to 0.00. The agent must manually type in the exact amount they are receiving from the tenant (to prevent blind-clicking and ensure accuracy).

[Save & Confirm] Button: Saves the transaction.

Post-Action: The modal closes automatically, a success toast notification appears, and the new collection immediately populates in the Main Data Table on the dashboard, updating the "Total Collection Card".