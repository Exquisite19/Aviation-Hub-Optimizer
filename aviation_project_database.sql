CREATE DATABASE IF NOT EXISTS aviation_ops;
USE aviation_ops;

-- 1. Airports Master Data
CREATE TABLE airports (
    airport_code VARCHAR(3) PRIMARY KEY,
    airport_name VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL
);

-- 2. Gate Infrastructure Management
CREATE TABLE gates (
    gate_id VARCHAR(10) PRIMARY KEY,
    airport_code VARCHAR(3),
    terminal VARCHAR(10),
    gate_status VARCHAR(20) DEFAULT 'Available', -- Available, Occupied, Maintenance
    FOREIGN KEY (airport_code) REFERENCES airports(airport_code)
);

-- 3. Core Flight Schedules & Operations
CREATE TABLE flights (
    flight_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_number VARCHAR(10) NOT NULL,
    airline VARCHAR(50) NOT NULL,
    departure_ap VARCHAR(3),
    arrival_ap VARCHAR(3),
    scheduled_departure DATETIME,
    actual_departure DATETIME,
    scheduled_arrival DATETIME,
    actual_arrival DATETIME,
    passenger_count INT,
    gate_id VARCHAR(10),
    flight_status VARCHAR(20) DEFAULT 'Scheduled', -- Scheduled, Active, Delayed, Landed
    FOREIGN KEY (departure_ap) REFERENCES airports(airport_code),
    FOREIGN KEY (arrival_ap) REFERENCES airports(airport_code),
    FOREIGN KEY (gate_id) REFERENCES gates(gate_id)
);

-- 4. Granular Delay Ingestion
CREATE TABLE delay_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    flight_id INT,
    delay_type VARCHAR(30), -- Weather, Carrier, Air Traffic Control, Mechanical
    duration_minutes INT NOT NULL,
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
);

-- Populate Sample Data for Testing
INSERT INTO airports VALUES 
('JNB', 'O.R. Tambo International', 'South Africa'),
('MRU', 'Sir Seewoosagur Ramgoolam International', 'Mauritius'),
('LHR', 'London Heathrow', 'United Kingdom');

INSERT INTO gates VALUES 
('G1_JNB', 'JNB', 'Terminal A', 'Available'),
('G2_JNB', 'JNB', 'Terminal A', 'Occupied'),
('G1_MRU', 'MRU', 'Main', 'Available');

INSERT INTO flights (flight_number, airline, departure_ap, arrival_ap, scheduled_departure, scheduled_arrival, passenger_count, gate_id, flight_status)
VALUES 
('SA191', 'South African Airways', 'MRU', 'JNB', '2026-06-02 16:30:00', '2026-06-02 18:45:00', 180, 'G1_JNB', 'Delayed'),
('BA56', 'British Airways', 'LHR', 'JNB', '2026-06-02 05:00:00', '2026-06-02 17:15:00', 290, NULL, 'Delayed');

INSERT INTO delay_logs (flight_id, delay_type, duration_minutes) 
VALUES (1, 'Weather', 45), (2, 'Air Traffic Control', 90);

USE aviation_ops;

-- 1. Ensure there is an available gate at JNB
INSERT INTO gates (gate_id, airport_code, gate_status) 
VALUES ('Gate_B1', 'JNB', 'Available')
ON DUPLICATE KEY UPDATE gate_status = 'Available';

-- 2. Insert a test flight flagged as Delayed
INSERT INTO flights (flight_id, flight_number, airline, passenger_count, arrival_ap, flight_status)
VALUES (999, 'SA191', 'South African Airways', 160, 'JNB', 'Delayed')
ON DUPLICATE KEY UPDATE flight_status = 'Delayed';

-- 3. Log a delay reason for the business rules to score
INSERT INTO delay_logs (flight_id, duration_minutes, delay_type)
VALUES (999, 45, 'Mechanical')
ON DUPLICATE KEY UPDATE duration_minutes = 45;

USE aviation_ops;

-- 1. Reset all flights to have NO gate pre-assigned (set gate_id to NULL)
UPDATE flights 
SET gate_id = NULL 
WHERE flight_number IN ('SA191', 'BA56');

-- 2. Ensure both JNB gates are marked as completely 'Available'
UPDATE gates 
SET gate_status = 'Available' 
WHERE airport_code = 'JNB';

USE aviation_ops;
SELECT flight_id, flight_number, flight_status FROM flights;
SELECT * FROM delay_logs;

USE aviation_ops;
-- Clear out existing entries to prevent primary key conflicts
TRUNCATE TABLE delay_logs;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE flights;
SET FOREIGN_KEY_CHECKS = 1;

-- Re-insert flights with explicit IDs so they perfectly match the delay logs
INSERT INTO flights (flight_id, flight_number, airline, departure_ap, arrival_ap, passenger_count, gate_id, flight_status)
VALUES 
(1, 'SA191', 'South African Airways', 'MRU', 'JNB', 180, NULL, 'Delayed'),
(2, 'BA56', 'British Airways', 'LHR', 'JNB', 290, NULL, 'Delayed');

-- Re-insert delay logs matching those exact IDs
INSERT INTO delay_logs (flight_id, delay_type, duration_minutes) 
VALUES 
(1, 'Weather', 45), 
(2, 'Air Traffic Control', 90);

-- Ensure your JNB gates are open and ready for the script to allocate them
UPDATE gates SET gate_status = 'Available' WHERE airport_code = 'JNB';