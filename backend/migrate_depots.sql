USE bitar_pms;

CREATE TABLE IF NOT EXISTS depots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS product_depots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    depot_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    UNIQUE KEY product_depot_unique (product_id, depot_id),
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (depot_id) REFERENCES depots(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS depot_transfers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    from_depot_id INT NOT NULL,
    to_depot_id INT NOT NULL,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_id INT NULL,
    notes TEXT,
    FOREIGN KEY (from_depot_id) REFERENCES depots(id),
    FOREIGN KEY (to_depot_id) REFERENCES depots(id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS depot_transfer_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    transfer_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    FOREIGN KEY (transfer_id) REFERENCES depot_transfers(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
);

-- Insert default Main Depot if no depots exist
INSERT INTO depots (name, is_primary)
SELECT 'Main Depot', TRUE
WHERE NOT EXISTS (SELECT 1 FROM depots);

-- Migrate existing products to Main Depot if they aren't already linked
INSERT INTO product_depots (product_id, depot_id, quantity)
SELECT p.id, (SELECT id FROM depots WHERE name = 'Main Depot' LIMIT 1), p.quantity
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM product_depots pd WHERE pd.product_id = p.id
);
