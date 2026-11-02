-- ========================================================
-- ERP V4 Architecture Migration Script
-- Adds generic task centers, accounting journals, versioning, 
-- event buses, and soft deletes.
-- ========================================================

-- 1. Soft Deletes (Audit Protection)
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE buildings ADD COLUMN IF NOT EXISTS deleted_by INT NULL;
ALTER TABLE apartments ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE apartments ADD COLUMN IF NOT EXISTS deleted_by INT NULL;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS deleted_by INT NULL;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE contracts ADD COLUMN IF NOT EXISTS deleted_by INT NULL;
ALTER TABLE products ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP NULL DEFAULT NULL;
ALTER TABLE products ADD COLUMN IF NOT EXISTS deleted_by INT NULL;

-- 2. Rent Periods (Dynamic Generation)
CREATE TABLE IF NOT EXISTS rent_periods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE
);

ALTER TABLE rent_invoices ADD COLUMN IF NOT EXISTS rent_period_id INT NULL;
ALTER TABLE rent_payments ADD COLUMN IF NOT EXISTS approval_status ENUM('Pending', 'Approved') DEFAULT 'Approved';

-- 3. Versioning & Timelines
CREATE TABLE IF NOT EXISTS contract_versions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contract_id INT NOT NULL,
    version_number INT NOT NULL,
    rent_amount DECIMAL(10,2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NULL,
    FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS building_events (
    id INT AUTO_INCREMENT PRIMARY KEY,
    building_id INT NULL,
    apartment_id INT NULL,
    event_type VARCHAR(100) NOT NULL,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NULL
);

-- 4. Unified Tasks Center
CREATE TABLE IF NOT EXISTS tasks (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    type ENUM('Rent Collection', 'Maintenance', 'Manager Approval', 'Data Quality') NOT NULL,
    assigned_to INT NULL,
    status ENUM('Pending', 'In Progress', 'Completed', 'Cancelled', 'Failed') DEFAULT 'Pending',
    due_date DATE NULL,
    priority ENUM('Low', 'Normal', 'High', 'Urgent') DEFAULT 'Normal',
    related_entity_type VARCHAR(50) NULL,
    related_entity_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (assigned_to) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS task_assignment_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    task_id INT NOT NULL,
    previous_agent_id INT NULL,
    new_agent_id INT NULL,
    action ENUM('Assigned', 'Reassigned', 'Returned', 'Completed') NOT NULL,
    gps_location VARCHAR(100) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
);

-- 5. Accounting Foundation
CREATE TABLE IF NOT EXISTS accounts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    type ENUM('Asset', 'Liability', 'Equity', 'Revenue', 'Expense') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT IGNORE INTO accounts (code, name, type) VALUES 
('1000', 'Cash', 'Asset'),
('1100', 'Accounts Receivable', 'Asset'),
('1110', 'Tenant Receivable', 'Asset'),
('4000', 'Rental Revenue', 'Revenue'),
('4100', 'Late Fee Income', 'Revenue');

CREATE TABLE IF NOT EXISTS journal_entries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATE NOT NULL,
    description VARCHAR(255) NOT NULL,
    debit_account_id INT NOT NULL,
    credit_account_id INT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    reference_type VARCHAR(50) NULL,
    reference_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by INT NULL,
    FOREIGN KEY (debit_account_id) REFERENCES accounts(id),
    FOREIGN KEY (credit_account_id) REFERENCES accounts(id)
);

CREATE TABLE IF NOT EXISTS cash_drawers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 6. Scheduled Jobs & Notifications
CREATE TABLE IF NOT EXISTS scheduled_jobs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    job_name VARCHAR(100) NOT NULL UNIQUE,
    status ENUM('Success', 'Failed', 'Pending', 'Running', 'Disabled') DEFAULT 'Pending',
    duration_seconds INT DEFAULT 0,
    records_processed INT DEFAULT 0,
    last_run TIMESTAMP NULL,
    next_run TIMESTAMP NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notification_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title_template VARCHAR(255) NOT NULL,
    message_template TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'System',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE notifications ADD COLUMN IF NOT EXISTS delivery_channel ENUM('Database', 'Push', 'Email', 'SMS', 'WhatsApp') DEFAULT 'Database';
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS delivery_status ENUM('Pending', 'Sent', 'Delivered', 'Failed', 'Read') DEFAULT 'Pending';

-- 7. User Sessions
CREATE TABLE IF NOT EXISTS user_sessions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    login_time TIMESTAMP NULL,
    logout_time TIMESTAMP NULL,
    active_minutes INT DEFAULT 0,
    idle_minutes INT DEFAULT 0,
    date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
