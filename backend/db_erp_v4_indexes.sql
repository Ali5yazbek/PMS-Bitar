-- ========================================================
-- ERP V4 Performance Optimization Script (Indexes)
-- ========================================================

-- 1. Indexing for Accounting / Journal Entries
CREATE INDEX idx_journal_entries_date ON journal_entries(date);
CREATE INDEX idx_journal_entries_debit ON journal_entries(debit_account_id);
CREATE INDEX idx_journal_entries_credit ON journal_entries(credit_account_id);

-- 2. Indexing for Tasks and Assignments
CREATE INDEX idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_task_assignment_history_task_id ON task_assignment_history(task_id);

-- 3. Indexing for Contracts and Rent Periods
CREATE INDEX idx_rent_periods_contract ON rent_periods(contract_id);
CREATE INDEX idx_rent_periods_start_end ON rent_periods(start_date, end_date);
CREATE INDEX idx_rent_invoices_period ON rent_invoices(rent_period_id);
CREATE INDEX idx_contract_versions_contract ON contract_versions(contract_id);

-- 4. Indexing for Activity Logs
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);

-- 5. Indexing for Scheduled Jobs
CREATE INDEX idx_scheduled_jobs_status ON scheduled_jobs(status);
