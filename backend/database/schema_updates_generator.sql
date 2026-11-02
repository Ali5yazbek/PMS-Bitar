CREATE TABLE IF NOT EXISTS generators (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    capacity_liters FLOAT NOT NULL DEFAULT 0,
    initial_hours FLOAT NOT NULL DEFAULT 0,
    initial_fuel_level FLOAT NOT NULL DEFAULT 0,
    factory_burn_rate_per_hour FLOAT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS daily_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    generator_id INT NOT NULL,
    date DATE NOT NULL,
    submitted_hours FLOAT NOT NULL,
    calculated_hours_worked FLOAT NOT NULL,
    expected_factory_fuel_burn FLOAT NOT NULL,
    ml_predicted_fuel_burn FLOAT,
    predicted_fuel_remaining FLOAT,
    admin_actual_fuel FLOAT NULL,
    status_flag VARCHAR(50) DEFAULT 'Normal',
    ai_report TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (generator_id) REFERENCES generators(id) ON DELETE CASCADE
);
