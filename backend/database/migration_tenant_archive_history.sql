-- 3. Archived Tenant History Master Record
CREATE TABLE IF NOT EXISTS tenant_archive_history (
    archive_id INT PRIMARY KEY AUTO_INCREMENT,
    original_tenant_id INT NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    national_id_passport VARCHAR(100),
    past_apartment_number VARCHAR(50),
    termination_date DATE,
    termination_reason VARCHAR(255),
    contact_details JSON,
    rental_ledger JSON,
    utility_ledger JSON,
    insurance_records JSON,
    maintenance_history JSON,
    archived_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
