-- ============================================================
-- Migration: Link tenant_documents to user_id
-- KYC documents belong to the PERSON (user), not to a lease.
-- Run once on the bitar_pms database.
-- ============================================================

-- Step 1: Add user_id column (nullable so we can populate it first)
ALTER TABLE tenant_documents
    ADD COLUMN IF NOT EXISTS user_id INT NULL AFTER id;

-- Step 2: Populate user_id from the existing tenant relationship
UPDATE tenant_documents td
JOIN tenants t ON td.tenant_id = t.id
SET td.user_id = t.user_id
WHERE td.user_id IS NULL;

-- Step 3: Deduplicate — keep one row per (user_id, document_type)
-- Best-status wins: Verified=1, Uploaded=2, Pending=3, Requested=4, other=5
-- Tie-break: keep the highest id (most recent upload)
DELETE td_bad
FROM tenant_documents td_bad
WHERE td_bad.id NOT IN (
    SELECT id_to_keep FROM (
        SELECT
            CAST(
                SUBSTRING_INDEX(
                    GROUP_CONCAT(
                        id ORDER BY
                            CASE status
                                WHEN 'Verified'  THEN 1
                                WHEN 'Uploaded'  THEN 2
                                WHEN 'Pending'   THEN 3
                                WHEN 'Requested' THEN 4
                                ELSE 5
                            END ASC,
                            id DESC
                        SEPARATOR ','
                    ),
                    ',', 1
                )
            AS UNSIGNED) AS id_to_keep
        FROM tenant_documents
        WHERE user_id IS NOT NULL
        GROUP BY user_id, document_type
    ) AS keepers
);

-- Step 4: Make user_id NOT NULL now that every row has one
ALTER TABLE tenant_documents
    MODIFY COLUMN user_id INT NOT NULL;

-- Step 5: Drop the old unique key on (tenant_id, document_type) if present
-- We look it up dynamically to handle any name it may have.
SET @old_uq = (
    SELECT tc.CONSTRAINT_NAME
    FROM information_schema.TABLE_CONSTRAINTS tc
    INNER JOIN information_schema.KEY_COLUMN_USAGE kcu
        ON  tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
        AND tc.TABLE_SCHEMA    = kcu.TABLE_SCHEMA
        AND tc.TABLE_NAME      = kcu.TABLE_NAME
    WHERE tc.TABLE_SCHEMA    = DATABASE()
      AND tc.TABLE_NAME      = 'tenant_documents'
      AND tc.CONSTRAINT_TYPE = 'UNIQUE'
      AND kcu.COLUMN_NAME    = 'tenant_id'
    LIMIT 1
);

SET @drop_old = IF(
    @old_uq IS NOT NULL,
    CONCAT('ALTER TABLE tenant_documents DROP INDEX `', @old_uq, '`'),
    'SELECT 1 -- no old unique key to drop'
);
PREPARE drop_stmt FROM @drop_old;
EXECUTE drop_stmt;
DEALLOCATE PREPARE drop_stmt;

-- Step 6: Add unique constraint on (user_id, document_type)
-- One KYC document per type per person.
ALTER TABLE tenant_documents
    ADD UNIQUE KEY IF NOT EXISTS uq_user_document_type (user_id, document_type);

-- Step 7: Add foreign key to users table (if not already present)
SET @has_fk = (
    SELECT COUNT(*)
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA          = DATABASE()
      AND TABLE_NAME            = 'tenant_documents'
      AND CONSTRAINT_NAME       = 'fk_tenant_docs_user_id'
      AND REFERENCED_TABLE_NAME = 'users'
);
SET @add_fk = IF(
    @has_fk = 0,
    'ALTER TABLE tenant_documents ADD CONSTRAINT fk_tenant_docs_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE',
    'SELECT 1 -- FK already exists'
);
PREPARE fk_stmt FROM @add_fk;
EXECUTE fk_stmt;
DEALLOCATE PREPARE fk_stmt;

-- Done
SELECT 'Migration complete: tenant_documents now linked to user_id.' AS result;
