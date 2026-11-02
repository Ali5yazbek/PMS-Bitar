-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 26, 2026 at 11:08 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bitar_pms`
--

-- --------------------------------------------------------

--
-- Table structure for table `accounts`
--

CREATE TABLE `accounts` (
  `id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `name` varchar(100) NOT NULL,
  `type` enum('Asset','Liability','Equity','Revenue','Expense') NOT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `accounts`
--

INSERT INTO `accounts` (`id`, `code`, `name`, `type`, `is_active`, `created_at`) VALUES
(1, '1000', 'Cash', 'Asset', 1, '2026-08-06 19:58:34'),
(2, '1100', 'Accounts Receivable', 'Asset', 1, '2026-08-06 19:58:34'),
(3, '1110', 'Tenant Receivable', 'Asset', 1, '2026-08-06 19:58:34'),
(4, '4000', 'Rental Revenue', 'Revenue', 1, '2026-08-06 19:58:34'),
(5, '4100', 'Late Fee Income', 'Revenue', 1, '2026-08-06 19:58:34');

-- --------------------------------------------------------

--
-- Table structure for table `activity_log`
--

CREATE TABLE `activity_log` (
  `id` int(11) NOT NULL,
  `module` varchar(100) NOT NULL DEFAULT '',
  `record_type` varchar(100) NOT NULL DEFAULT '',
  `record_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL DEFAULT '',
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(255) DEFAULT NULL,
  `user_role` varchar(100) DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `device` varchar(500) DEFAULT NULL,
  `browser` varchar(500) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `severity` enum('info','warning','critical') DEFAULT 'info',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_log`
--

INSERT INTO `activity_log` (`id`, `module`, `record_type`, `record_id`, `action`, `old_value`, `new_value`, `user_id`, `user_name`, `user_role`, `ip_address`, `device`, `browser`, `reason`, `severity`, `created_at`) VALUES
(1, 'generator', 'generator_reading', 23, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-04 21:05:52'),
(2, 'electricity', 'meter_reading', 8, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-05 19:55:58'),
(3, 'electricity', 'meter_reading', 9, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-05 19:56:01'),
(4, 'electricity', 'meter_reading', 10, 'approved', '{\"status\":\"Pending\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-05 20:20:23'),
(5, 'electricity', 'meter_reading', 11, 'approved', '{\"status\":\"Pending\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-06 22:03:04'),
(6, 'subscription', 'subscription_reading', 2, 'approved', '{\"status\":\"Pending\"}', '{\"status\":\"Accepted\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', NULL, 'Approved by admin', 'info', '2026-08-07 21:20:02'),
(7, 'electricity', 'meter_reading', 12, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', NULL, 'Approved by admin', 'info', '2026-08-07 21:46:33'),
(8, 'electricity', 'meter_reading', 13, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', NULL, 'Approved by admin', 'info', '2026-08-07 21:46:36'),
(9, 'subscription', 'subscription_reading', 3, 'approved', '{\"status\":\"Pending\"}', '{\"status\":\"Accepted\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', NULL, 'Approved by admin', 'info', '2026-08-07 21:46:51'),
(10, 'generator', 'generator_reading', 24, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-09 21:31:48'),
(11, 'generator', 'generator_reading', 25, 'approved', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Verified\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'Approved by admin', 'info', '2026-08-16 14:30:46'),
(12, 'generator', 'generator_reading', 1, 'rejected', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Rejected\",\"reason_code\":\"incorrect_reading\",\"severity\":\"medium\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'incorrect_reading', 'warning', '2026-08-27 20:03:29'),
(13, 'generator', 'generator_reading', 3, 'rejected', '{\"status\":\"Pending Verification\"}', '{\"status\":\"Rejected\",\"reason_code\":\"incorrect_reading\",\"severity\":\"medium\"}', 1, 'Admin', 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', NULL, 'incorrect_reading', 'warning', '2026-08-27 20:48:44');

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(255) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `action`, `entity_type`, `entity_id`, `details`, `created_at`) VALUES
(1, 5, 'Rent Collection', 'RentInvoice', 118, 'Collected $840000 via Cash', '2026-08-06 22:22:28'),
(2, 5, 'Rent Collection', 'RentInvoice', 121, 'Collected $210000 via Cash', '2026-08-07 21:17:47'),
(3, 5, 'Rent Collection', 'RentInvoice', 117, 'Collected $720000 via Cash', '2026-08-08 21:48:00'),
(4, 5, 'Rent Collection', 'RentInvoice', 122, 'Collected $840000 via Cash', '2026-08-08 22:34:33'),
(5, 5, 'Rent Collection', 'RentInvoice', 123, 'Collected $3000 via Cash', '2026-08-08 22:37:03'),
(6, 5, 'Generator Log', 'Generator', 7, 'Submitted daily report (Fuel Added: 1515.00L)', '2026-08-03 20:26:02'),
(7, 5, 'Generator Log', 'Generator', 7, 'Submitted daily report (Fuel Added: 4.00L)', '2026-08-09 21:25:52'),
(8, 5, 'Electricity Subscription', 'Subscription', 11, 'Submitted meter reading (Consumption: 0.00 kWh)', '2026-08-07 21:18:29'),
(9, 5, 'Electricity Subscription', 'Subscription', 13, 'Submitted meter reading (Consumption: 0.00 kWh)', '2026-08-07 21:42:08'),
(10, 5, 'Electricity Reading', 'Apartment', 12, 'Submitted meter reading (Consumption: 149.00 kWh)', '2026-07-25 21:26:21'),
(11, 5, 'Electricity Reading', 'Apartment', 13, 'Submitted meter reading (Consumption: 450.00 kWh)', '2026-08-05 20:04:05'),
(12, 5, 'Electricity Reading', 'Apartment', 11, 'Submitted fixed monthly payment confirmation', '2026-08-05 20:19:29'),
(13, 1, 'Electricity Reading', 'Apartment', 13, 'Submitted meter reading (Consumption: 50.00 kWh)', '2026-08-07 21:12:54'),
(14, 5, 'Generator Log', 'Generator', 13, 'Submitted daily report (Fuel Added: 0L)', '2026-08-27 19:44:54'),
(15, 5, 'Generator Log', 'Generator', 13, 'Submitted daily report (Fuel Added: 0L)', '2026-08-27 20:27:06'),
(16, 5, 'Generator Log', 'Generator', 12, 'Submitted daily report (Fuel Added: 0L)', '2026-08-27 20:48:09'),
(17, 5, 'Generator Log', 'Generator', 12, 'Submitted daily report (Fuel Added: 0L)', '2026-08-27 20:56:10');

-- --------------------------------------------------------

--
-- Table structure for table `ac_maintenance_tasks`
--

CREATE TABLE `ac_maintenance_tasks` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `worker_id` int(11) DEFAULT NULL,
  `scheduled_date` date NOT NULL,
  `status` enum('Scheduled','Pending_Approval','Completed','Rejected') DEFAULT 'Scheduled',
  `before_photo` longtext DEFAULT NULL,
  `after_photo` longtext DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `submission_date` datetime DEFAULT NULL,
  `completion_date` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `ac_maintenance_tasks`
--

INSERT INTO `ac_maintenance_tasks` (`id`, `apartment_id`, `worker_id`, `scheduled_date`, `status`, `before_photo`, `after_photo`, `notes`, `submission_date`, `completion_date`, `created_at`) VALUES
(12, 11, NULL, '2026-07-21', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-07-21 21:01:18'),
(13, 12, NULL, '2026-07-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-07-22 20:25:37'),
(14, 13, NULL, '2026-07-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-07-22 20:25:54'),
(15, 14, NULL, '2026-08-06', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-08-06 21:16:18'),
(16, 26, NULL, '2026-09-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-09-22 21:17:34'),
(17, 27, NULL, '2026-09-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-09-22 21:17:34'),
(18, 28, NULL, '2026-09-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-09-22 21:17:34'),
(19, 29, NULL, '2026-09-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-09-22 21:17:34'),
(20, 30, NULL, '2026-09-22', 'Scheduled', NULL, NULL, NULL, NULL, NULL, '2026-09-22 21:17:34');

-- --------------------------------------------------------

--
-- Table structure for table `agent_performance`
--

CREATE TABLE `agent_performance` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `month` int(11) NOT NULL,
  `year` int(11) NOT NULL,
  `total_submissions` int(11) DEFAULT 0,
  `approved_count` int(11) DEFAULT 0,
  `rejected_count` int(11) DEFAULT 0,
  `correction_count` int(11) DEFAULT 0,
  `late_submissions` int(11) DEFAULT 0,
  `avg_consumption_diff` decimal(10,2) DEFAULT 0.00,
  `accuracy_score` decimal(5,2) DEFAULT 100.00,
  `approval_rate` decimal(5,2) DEFAULT 100.00,
  `rejection_rate` decimal(5,2) DEFAULT 0.00,
  `avg_submission_hour` decimal(5,2) DEFAULT NULL,
  `rank_in_period` int(11) DEFAULT NULL,
  `calculated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `agent_performance`
--

INSERT INTO `agent_performance` (`id`, `user_id`, `month`, `year`, `total_submissions`, `approved_count`, `rejected_count`, `correction_count`, `late_submissions`, `avg_consumption_diff`, `accuracy_score`, `approval_rate`, `rejection_rate`, `avg_submission_hour`, `rank_in_period`, `calculated_at`) VALUES
(1, 1, 8, 2026, 0, 4, 0, 0, 0, 0.00, 100.00, 100.00, 0.00, NULL, 2, '2026-08-16 14:30:46'),
(2, 5, 8, 2026, 0, 7, 2, 0, 0, 0.00, 100.00, 100.00, 0.00, NULL, 1, '2026-08-27 20:48:44');

-- --------------------------------------------------------

--
-- Table structure for table `agent_purchases`
--

CREATE TABLE `agent_purchases` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `building_name` varchar(100) DEFAULT 'Galaxy',
  `apartment_number` varchar(50) DEFAULT 'A1',
  `supplier` varchar(100) NOT NULL,
  `amount` varchar(50) NOT NULL,
  `items` varchar(255) DEFAULT 'General Material',
  `notes` text DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Pending Review',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `agent_subscription_readings`
--

CREATE TABLE `agent_subscription_readings` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `subscription_id` int(11) NOT NULL,
  `building_name` varchar(255) DEFAULT NULL,
  `apartment_code` varchar(50) DEFAULT NULL,
  `tenant_name` varchar(255) DEFAULT NULL,
  `previous_reading` decimal(12,2) DEFAULT 0.00,
  `current_reading` decimal(12,2) DEFAULT NULL,
  `consumption` decimal(12,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `photo_path` varchar(500) DEFAULT NULL,
  `status` enum('Pending','Accepted','Rejected') DEFAULT 'Pending',
  `rejection_reason` text DEFAULT NULL,
  `submitted_by` int(11) DEFAULT NULL,
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `billing_month` int(11) DEFAULT NULL,
  `billing_year` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `status_lifecycle` enum('draft','submitted','pending_review','needs_correction','approved','rejected','cancelled','archived') DEFAULT 'submitted',
  `anomaly_flags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`anomaly_flags`)),
  `confidence_score` tinyint(3) UNSIGNED DEFAULT 100,
  `risk_level` enum('low','medium','high','critical') DEFAULT 'low',
  `rejection_reason_code` varchar(100) DEFAULT NULL,
  `rejection_severity` enum('minor','medium','major','critical') DEFAULT NULL,
  `corrected_reading` decimal(12,2) DEFAULT NULL,
  `corrected_by` int(11) DEFAULT NULL,
  `corrected_at` datetime DEFAULT NULL,
  `version_number` int(11) DEFAULT 1,
  `priority` tinyint(4) DEFAULT 2,
  `amount_collected` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `agent_subscription_readings`
--

INSERT INTO `agent_subscription_readings` (`id`, `apartment_id`, `subscription_id`, `building_name`, `apartment_code`, `tenant_name`, `previous_reading`, `current_reading`, `consumption`, `notes`, `photo_path`, `status`, `rejection_reason`, `submitted_by`, `reviewed_by`, `reviewed_at`, `billing_month`, `billing_year`, `created_at`, `latitude`, `longitude`, `status_lifecycle`, `anomaly_flags`, `confidence_score`, `risk_level`, `rejection_reason_code`, `rejection_severity`, `corrected_reading`, `corrected_by`, `corrected_at`, `version_number`, `priority`, `amount_collected`) VALUES
(2, 11, 17, 'Galaxy', 'A1', 'ali yazbekk', 0.00, 0.00, 0.00, '', 'uploads/subscription-meters/1786137509_subm_2495.png', 'Accepted', NULL, 5, NULL, '2026-08-08 00:20:02', 8, 2026, '2026-08-07 21:18:29', NULL, NULL, 'approved', '[]', 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, 0.00),
(3, 13, 19, 'Galaxy', 'A3', '', 500.00, 0.00, 0.00, '', 'uploads/subscription-meters/1786138928_subm_9934.png', 'Accepted', NULL, 5, NULL, '2026-08-08 00:46:51', 8, 2026, '2026-08-07 21:42:08', NULL, NULL, 'approved', '[{\"code\":\"LOW_CONSUMPTION\",\"level\":\"low\",\"title\":\"Very Low Consumption\",\"message\":\"Consumption (0 kWh) is 100% below the 3-month average (500 kWh).\",\"data\":{\"consumption\":0,\"avg_3m\":500,\"percent_below\":100}}]', 90, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, 250000.00);

-- --------------------------------------------------------

--
-- Table structure for table `apartments`
--

CREATE TABLE `apartments` (
  `id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `monthly_rent` decimal(10,2) NOT NULL,
  `monthly_insurance` decimal(10,2) NOT NULL,
  `status` enum('Vacant','Rented','Maintenance') DEFAULT 'Vacant',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `apartments`
--

INSERT INTO `apartments` (`id`, `building_id`, `code`, `monthly_rent`, `monthly_insurance`, `status`, `created_at`, `deleted_at`, `deleted_by`) VALUES
(11, 5, 'A1', 720000.00, 180000.00, 'Rented', '2026-07-21 21:01:18', NULL, NULL),
(12, 5, 'A2', 840000.00, 180000.00, 'Vacant', '2026-07-22 20:25:37', NULL, NULL),
(13, 5, 'A3', 855000.00, 312000.00, 'Vacant', '2026-07-22 20:25:54', NULL, NULL),
(14, 5, 'A5', 210000.00, 30000.00, 'Vacant', '2026-08-06 21:16:18', NULL, NULL),
(26, 5, '101', 500.00, 120.00, '', '2026-09-21 21:53:40', NULL, NULL),
(27, 5, '102', 650.00, 150.00, '', '2026-09-21 21:53:40', NULL, NULL),
(28, 5, '103', 550.00, 120.00, '', '2026-09-21 21:53:40', NULL, NULL),
(29, 5, '104', 700.00, 180.00, 'Vacant', '2026-09-21 21:53:40', NULL, NULL),
(30, 5, '105', 480.00, 100.00, 'Vacant', '2026-09-21 21:53:40', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `apartment_cost_deployments`
--

CREATE TABLE `apartment_cost_deployments` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `supplier_name` varchar(255) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `receipt_image` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `status` varchar(30) NOT NULL DEFAULT 'Accepted',
  `submitted_by` int(11) DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `apartment_cost_deployments`
--

INSERT INTO `apartment_cost_deployments` (`id`, `apartment_id`, `supplier_name`, `amount`, `receipt_image`, `notes`, `status`, `submitted_by`, `rejection_reason`, `reviewed_by`, `reviewed_at`, `date`, `created_at`) VALUES
(2, 11, 'Leader Supermarcher', 135000.00, 'uploads/receipts/agent/agent_purchase_6a691e272f466.jpeg', 'apartment electronics', 'Accepted', 5, NULL, 1, '2026-08-04 23:13:33', '2026-07-28', '2026-07-28 21:24:55'),
(3, 11, 'njnnkj', 454545.00, 'uploads/receipts/agent/agent_purchase_6a691ff004b83.jpeg', 'kk', 'Accepted', 5, NULL, 1, '2026-08-04 23:13:31', '2026-07-28', '2026-07-28 21:32:32');

-- --------------------------------------------------------

--
-- Table structure for table `apartment_expenses`
--

CREATE TABLE `apartment_expenses` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `cost` decimal(10,2) NOT NULL,
  `total` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approval_chains`
--

CREATE TABLE `approval_chains` (
  `id` int(11) NOT NULL,
  `name` varchar(200) NOT NULL,
  `action_type` varchar(100) NOT NULL COMMENT 'delete_tenant|update_contract|export_financial|...',
  `description` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approval_chain_steps`
--

CREATE TABLE `approval_chain_steps` (
  `id` int(11) NOT NULL,
  `chain_id` int(11) NOT NULL,
  `step_order` int(11) NOT NULL DEFAULT 1,
  `step_label` varchar(200) NOT NULL COMMENT 'e.g. Manager Approval',
  `approver_role` varchar(50) DEFAULT NULL,
  `approver_user_id` int(11) DEFAULT NULL,
  `can_reject` tinyint(1) NOT NULL DEFAULT 1,
  `can_delegate` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approval_requests`
--

CREATE TABLE `approval_requests` (
  `id` int(11) NOT NULL,
  `chain_id` int(11) NOT NULL,
  `requester_id` int(11) NOT NULL,
  `current_step` int(11) NOT NULL DEFAULT 1,
  `status` enum('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  `record_type` varchar(100) DEFAULT NULL,
  `record_id` int(11) DEFAULT NULL,
  `title` varchar(300) NOT NULL,
  `reason` text DEFAULT NULL,
  `data_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'What they want to change' CHECK (json_valid(`data_payload`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `resolved_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approval_request_steps`
--

CREATE TABLE `approval_request_steps` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL,
  `chain_step_id` int(11) NOT NULL,
  `approver_id` int(11) DEFAULT NULL,
  `status` enum('pending','approved','rejected','skipped') NOT NULL DEFAULT 'pending',
  `comment` text DEFAULT NULL,
  `acted_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `approval_settings`
--

CREATE TABLE `approval_settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(255) NOT NULL DEFAULT '',
  `label` varchar(255) NOT NULL DEFAULT '',
  `description` text DEFAULT NULL,
  `data_type` enum('integer','decimal','boolean','string') DEFAULT 'integer',
  `module` varchar(100) DEFAULT 'global',
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `approval_settings`
--

INSERT INTO `approval_settings` (`id`, `setting_key`, `setting_value`, `label`, `description`, `data_type`, `module`, `updated_by`, `updated_at`, `created_at`) VALUES
(1, 'high_consumption_percent', '200', 'High Consumption Threshold (%)', 'If consumption is more than X% above the apartment average, flag as high consumption.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(2, 'low_consumption_percent', '30', 'Low Consumption Threshold (%)', 'If consumption is more than X% below the apartment average, flag as low consumption.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(3, 'duplicate_reading_days', '2', 'Duplicate Detection Window (days)', 'Flag if the same reading value is submitted within this many days.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(4, 'critical_confidence_score', '40', 'Critical Risk Score Threshold', 'Readings at or below this confidence score are flagged as Critical risk.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(5, 'medium_confidence_score', '70', 'Medium Risk Score Threshold', 'Readings between critical and this value are High risk. Above this is Medium/Low.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(6, 'require_image', 'true', 'Require Meter Photo', 'If true, reject any submission that does not include a meter photo.', 'boolean', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(7, 'max_daily_consumption_kwh', '1000', 'Max Plausible Daily Consumption (kWh)', 'Any consumption above this value per day is flagged as a spike.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(8, 'auto_lock_after_submit', 'true', 'Lock Reading After Submission', 'If true, agents cannot edit a reading after it is submitted.', 'boolean', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(9, 'possible_digit_error_pct', '40', 'Possible Wrong Digit Threshold (%)', 'If the reading differs from expected by more than X%, suggest possible typing error.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(10, 'long_without_reading_days', '45', 'Long Without Reading Alert (days)', 'Alert if no reading has been submitted for this apartment in X days.', 'integer', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(11, 'bulk_approve_max_risk', 'low', 'Bulk Approve Max Risk Level', 'The maximum risk level that can be approved in bulk without warning.', 'string', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(12, 'auto_analyze_on_submit', 'true', 'Auto-Analyze on Submission', 'Automatically run anomaly detection when an agent submits a reading.', 'boolean', 'readings', NULL, NULL, '2026-08-04 20:25:45'),
(13, 'health_score_excellent_min', '90', 'Building Health: Excellent Minimum', 'Buildings with a health score >= this are graded Excellent.', 'integer', 'buildings', NULL, NULL, '2026-08-04 20:25:45'),
(14, 'health_score_good_min', '75', 'Building Health: Good Minimum', 'Buildings with a health score >= this are graded Good.', 'integer', 'buildings', NULL, NULL, '2026-08-04 20:25:45'),
(15, 'health_score_fair_min', '55', 'Building Health: Fair Minimum', 'Buildings with a health score >= this are graded Fair.', 'integer', 'buildings', NULL, NULL, '2026-08-04 20:25:45'),
(16, 'health_score_poor_min', '35', 'Building Health: Poor Minimum', 'Buildings with a health score >= this are graded Poor. Below this is Critical.', 'integer', 'buildings', NULL, NULL, '2026-08-04 20:25:45');

-- --------------------------------------------------------

--
-- Table structure for table `audit_logs`
--

CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_logs`
--

INSERT INTO `audit_logs` (`id`, `user_id`, `action`, `entity_type`, `entity_id`, `details`, `created_at`) VALUES
(1, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Refund of 300.00', '2026-06-18 21:38:22'),
(2, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 200', '2026-06-18 21:43:18'),
(3, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Apply_To_Rent of 200', '2026-06-18 21:43:38'),
(4, 1, 'CREATE', 'RentPayment', 2, 'Recorded payment of 200 for invoice #2', '2026-06-18 21:45:44'),
(5, 1, 'CREATE', 'WorkshopProject', 1, 'Created new workshop project: yazbek', '2026-06-18 22:09:11'),
(6, 1, 'CREATE', 'Building', 3, 'Created building: yazbek', '2026-06-19 20:06:00'),
(7, 1, 'CREATE', 'Apartment', 6, 'Created apartment: A1', '2026-06-19 20:07:29'),
(8, 1, '1', 'Added Product', 0, '1', '2026-06-19 20:20:34'),
(9, 1, 'CREATE', 'Tenant', 2, 'Added new tenant: test', '2026-06-19 20:22:56'),
(10, 1, 'CREATE', 'RentInvoice', NULL, 'Auto-generated 17 missing invoices', '2026-06-19 20:23:02'),
(11, 1, 'CREATE', 'RentPayment', 21, 'Recorded payment of 10000.00 for invoice #21', '2026-06-19 20:23:46'),
(12, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Deposit of 1000', '2026-06-19 20:24:06'),
(13, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Refund of 1000.00', '2026-06-19 20:24:11'),
(14, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Deposit of 155', '2026-06-19 20:24:18'),
(15, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Apply_To_Rent of 155', '2026-06-19 20:24:28'),
(16, 1, '1', 'Create', 0, '1', '2026-06-19 20:52:55'),
(17, 1, '1', 'Created POS Invoice', 0, '1', '2026-06-19 20:55:12'),
(18, 1, '1', 'Created POS Invoice', 0, '2', '2026-06-19 20:56:56'),
(19, 1, '1', 'Update', 0, '1', '2026-06-19 21:09:16'),
(20, 1, '1', 'Update', 0, '1', '2026-06-19 21:09:17'),
(21, 1, '1', 'Added Product', 0, '2', '2026-06-19 21:11:13'),
(22, 1, '1', 'Added Product', 0, '3', '2026-06-19 21:11:36'),
(23, 1, '1', 'Added Product', 0, '4', '2026-06-19 21:12:27'),
(24, 1, '1', 'Created POS Invoice', 0, '3', '2026-06-19 21:12:50'),
(25, 1, '1', 'Created POS Invoice', 0, '4', '2026-06-19 21:17:02'),
(26, 1, '1', 'Created POS Invoice', 0, '5', '2026-06-19 21:29:55'),
(27, 1, '1', 'Created POS Invoice', 0, '6', '2026-06-19 21:30:32'),
(28, 1, '1', 'Created POS Invoice', 0, '7', '2026-06-19 21:32:40'),
(29, 1, '1', 'Created POS Invoice', 0, '8', '2026-06-19 21:37:08'),
(30, 1, '1', 'Created POS Invoice', 0, '9', '2026-06-19 21:55:59'),
(31, 1, 'CREATE', 'RentPayment', 2, 'Recorded payment of 600.00 for invoice #2', '2026-06-19 22:42:26'),
(32, 1, '1', 'Created POS Invoice', 0, '10', '2026-06-19 22:56:21'),
(33, 1, '1', 'Created POS Invoice', 0, '11', '2026-06-19 23:08:53'),
(34, 1, '1', 'Update POS Invoice', 0, '11', '2026-06-19 23:10:26'),
(35, 1, 'CREATE', 'Building', 4, 'Created building: test', '2026-06-21 19:58:30'),
(36, 1, 'CREATE', 'User', 2, 'Created user account: ali@gmail.com with role maintenance', '2026-06-22 20:01:24'),
(37, 1, '1', 'Created POS Invoice', 0, '12', '2026-06-22 20:30:16'),
(38, 1, '1', 'Created POS Invoice', 0, '13', '2026-06-22 20:33:23'),
(39, 1, '1', 'Created POS Invoice', 0, '14', '2026-06-22 20:33:47'),
(40, 1, 'CREATE', 'Tenant', 3, 'Added new tenant: Ali Yazbeck', '2026-06-23 20:55:22'),
(41, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 21:51:24'),
(42, 1, 'CREATE', 'Apartment', 7, 'Created apartment: a1', '2026-06-27 21:57:29'),
(43, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Refund of 300.00', '2026-06-27 22:13:54'),
(44, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 400', '2026-06-27 22:14:12'),
(45, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deduct of 400', '2026-06-27 22:14:25'),
(46, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:14:52'),
(47, 1, 'CREATE', 'InsuranceTransaction', 2, 'Recorded insurance transaction: Apply_To_Rent of 300', '2026-06-27 22:15:01'),
(48, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:19:37'),
(49, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Refund of 300.00', '2026-06-27 22:21:02'),
(50, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:21:25'),
(51, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Refund of 300.00', '2026-06-27 22:21:29'),
(52, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:24:48'),
(53, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deduct of 300', '2026-06-27 22:25:49'),
(54, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:35:30'),
(55, 1, 'CREATE', 'InsuranceTransaction', 1, 'Recorded insurance transaction: Deposit of 300', '2026-06-27 22:35:35'),
(56, 1, 'CREATE', 'Tenant', 4, 'Added new tenant: dfsdf', '2026-06-27 22:40:30'),
(57, 1, 'CREATE', 'Contract', 4, 'Created new draft contract for apartment ID: 7', '2026-06-27 22:43:05'),
(58, 1, 'UPDATE', 'Contract', 4, 'Updated contract status to Pending_Signature', '2026-06-27 22:43:09'),
(59, 1, 'CREATE', 'User', 4, 'Created user account: ali1@gmail.com with role tenant', '2026-06-27 23:11:30'),
(60, 1, 'DELETE', 'Tenant', 2, 'Deleted tenant ID: 2', '2026-06-27 23:11:50'),
(61, 4, 'CREATE', 'Tenant', 5, 'Assigned user ali yazbekk to apartment.', '2026-06-27 23:17:49'),
(62, 4, 'UPDATE', 'Contract', 5, 'Updated contract status to Pending_Signature', '2026-06-27 23:18:05'),
(63, 4, 'UPDATE', 'Contract', 5, 'Tenant ID 5 uploaded signed contract', '2026-06-27 23:29:41'),
(64, 4, 'UPDATE', 'Contract', 5, 'Updated contract status to Approved', '2026-06-27 23:30:08'),
(65, 1, 'CREATE', 'InsuranceTransaction', 4, 'Recorded insurance transaction: Deposit of 200', '2026-06-28 09:47:02'),
(66, 1, 'CREATE', 'Tenant', 6, 'Assigned user ali yazbekk to apartment.', '2026-06-28 14:01:10'),
(67, 1, 'UPDATE', 'Contract', 6, 'Updated contract status to Pending_Signature', '2026-06-28 14:01:46'),
(68, 4, 'UPDATE', 'Contract', 6, 'User ID 4 uploaded signed contract', '2026-06-28 14:05:33'),
(69, 1, 'UPDATE', 'Contract', 6, 'Updated contract status to Approved', '2026-06-28 14:05:55'),
(70, 1, 'CREATE', 'RentInvoice', NULL, 'Auto-generated 1 missing invoices for contract 6', '2026-06-28 14:22:39'),
(71, 1, 'CREATE', 'Contract', 7, 'Renewed contract from old ID: 1', '2026-06-28 16:13:28'),
(72, 1, 'CREATE', 'Tenant', 7, 'Assigned user ali yazbekk to apartment.', '2026-06-28 16:15:38'),
(73, 1, 'DELETE', 'Contract', 4, 'Deleted contract permanently', '2026-06-28 16:48:22'),
(74, 1, 'CREATE', 'WorkshopProject', 2, 'Created new workshop project: were', '2026-06-28 17:04:30'),
(75, 1, 'CREATE', 'WorkshopProject', 3, 'Created new workshop project: dfsf', '2026-06-28 17:07:25'),
(76, 1, 'CREATE', 'WorkshopProject', 4, 'Created new workshop project: fdgfg', '2026-06-28 17:12:18'),
(77, 1, 'CREATE', 'User', 5, 'Created user account: hassan@gmail.com with role agent', '2026-06-28 22:17:55'),
(78, 1, 'UPDATE', 'User', 5, 'Updated user account: hassan@gmail.com', '2026-06-28 22:27:57'),
(79, 1, 'UPDATE', 'User', 5, 'Updated user account: hassan@gmail.com', '2026-06-28 22:30:08'),
(80, 1, 'DELETE', 'Tenant', 4, 'Deleted tenant ID: 4', '2026-06-28 22:52:45'),
(81, 1, 'CREATE', 'RentPayment', 37, 'Recorded payment of 1220 for invoice #37', '2026-06-29 22:02:16'),
(82, 1, 'CREATE', 'RentPayment', 42, 'Recorded payment of 1000.00 for invoice #42', '2026-06-29 22:10:26'),
(83, 1, 'CREATE', 'RentPayment', 39, 'Recorded payment of 10050.00 for invoice #39', '2026-06-29 22:10:33'),
(84, 1, 'CREATE', 'RentPayment', 47, 'Recorded payment of 3004.00 for invoice #47', '2026-06-29 22:10:37'),
(85, 1, 'CREATE', 'RentPayment', 36, 'Recorded payment of 1200.00 for invoice #36', '2026-06-29 22:10:39'),
(86, 1, 'CREATE', 'RentPayment', 46, 'Recorded payment of 3004.00 for invoice #46', '2026-06-29 22:10:42'),
(87, 1, 'CREATE', 'RentPayment', 37, 'Recorded payment of 8780.00 for invoice #37', '2026-06-29 22:10:45'),
(88, 1, 'CREATE', 'RentPayment', 45, 'Recorded payment of 3004.00 for invoice #45', '2026-06-29 22:10:47'),
(89, 1, 'CREATE', 'RentPayment', 35, 'Recorded payment of 1200.00 for invoice #35', '2026-06-29 22:10:50'),
(90, 1, 'CREATE', 'RentPayment', 34, 'Recorded payment of 1200.00 for invoice #34', '2026-06-29 22:10:53'),
(91, 1, 'CREATE', 'RentPayment', 44, 'Recorded payment of 3004.00 for invoice #44', '2026-06-29 22:10:56'),
(92, 1, 'CREATE', 'RentPayment', 33, 'Recorded payment of 1000.00 for invoice #33', '2026-06-29 22:11:00'),
(93, 1, 'CREATE', 'RentPayment', 43, 'Recorded payment of 3004.00 for invoice #43', '2026-06-29 22:11:02'),
(94, 1, 'CREATE', 'RentPayment', 32, 'Recorded payment of 1000.00 for invoice #32', '2026-06-29 22:11:05'),
(95, 1, 'CREATE', 'RentPayment', 31, 'Recorded payment of 1000.00 for invoice #31', '2026-06-29 22:11:08'),
(96, 1, 'CREATE', 'RentPayment', 3, 'Recorded payment of 1000.00 for invoice #3', '2026-06-29 22:11:10'),
(97, 1, '1', 'CREATE', 0, '2', '2026-07-01 19:33:15'),
(98, 1, '1', 'TRANSFER', 0, '1', '2026-07-01 19:38:15'),
(99, 1, '1', 'Create', 0, '1', '2026-07-01 20:17:38'),
(100, 1, '1', 'Created POS Invoice', 0, '15', '2026-07-01 20:33:01'),
(101, 1, 'UPDATE', 'User', 4, 'Updated user account: ali1@gmail.com', '2026-07-02 23:42:20'),
(102, 1, 'UPDATE', 'Contract', 9, 'Manually renewed rent for contract 9', '2026-07-05 00:43:27'),
(103, 1, 'CREATE', 'Apartment', 9, 'Created apartment: A2', '2026-07-05 19:44:49'),
(104, 1, 'UPDATE', 'Apartment', 9, 'Updated apartment: A2 and applied new rent to active contract/invoices', '2026-07-05 19:45:21'),
(105, 1, 'CREATE', 'Tenant', 9, 'Assigned user ali yazbekk to apartment.', '2026-07-05 19:47:32'),
(106, 1, 'UPDATE', 'Contract', 9, 'Paused rent for contract 9', '2026-07-05 20:39:01'),
(107, 1, 'UPDATE', 'Contract', 9, 'Ended rent for contract 9', '2026-07-05 20:39:19'),
(108, 1, 'CREATE', 'Contract', 11, 'Renewed contract from old ID: 5', '2026-07-09 22:02:17'),
(109, 1, 'UPDATE', 'User', 5, 'Updated user account: hassan@gmail.com', '2026-07-13 19:45:42');

-- --------------------------------------------------------

--
-- Table structure for table `audit_reports`
--

CREATE TABLE `audit_reports` (
  `id` int(11) NOT NULL,
  `employee_id` int(11) DEFAULT NULL COMMENT 'User who owns or is responsible for the record',
  `department` varchar(100) DEFAULT NULL,
  `module_name` varchar(100) DEFAULT NULL,
  `table_name` varchar(100) NOT NULL COMMENT 'tenants | apartments | contracts | workshops',
  `record_id` int(11) NOT NULL COMMENT 'PK of the problematic record',
  `field_name` varchar(150) NOT NULL,
  `actual_value` text DEFAULT NULL,
  `expected_value` text DEFAULT NULL,
  `problem_type` varchar(100) DEFAULT NULL,
  `severity` enum('critical','warning','info') NOT NULL DEFAULT 'warning',
  `description` text NOT NULL,
  `full_record_json` longtext DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Open',
  `is_locked` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=locked (only admin can edit), 0=unlocked',
  `assigned_to` int(11) DEFAULT NULL COMMENT 'user_id of the assigned manager',
  `unlock_until` datetime DEFAULT NULL,
  `unlock_reason` text DEFAULT NULL,
  `unlocked_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_reports`
--

INSERT INTO `audit_reports` (`id`, `employee_id`, `department`, `module_name`, `table_name`, `record_id`, `field_name`, `actual_value`, `expected_value`, `problem_type`, `severity`, `description`, `full_record_json`, `status`, `is_locked`, `assigned_to`, `unlock_until`, `unlock_reason`, `unlocked_by`, `created_at`, `updated_at`) VALUES
(1, NULL, 'General', NULL, 'tenants', 8, 'national_id', NULL, NULL, 'Missing', 'critical', 'National ID is missing for tenant: Test User', NULL, 'Resolved', 1, NULL, NULL, NULL, NULL, '2026-07-17 01:16:20', '2026-08-05 23:21:18'),
(2, NULL, 'General', NULL, 'contracts', 1, 'end_date', NULL, NULL, 'Expired', 'info', 'Contract #1 expires soon on 2026-07-18', NULL, 'open', 1, NULL, NULL, NULL, NULL, '2026-07-17 01:17:06', '2026-07-17 01:17:06'),
(3, 4, 'General', NULL, 'contracts', 5, 'end_date', NULL, NULL, 'Expired', 'critical', 'Contract #5 expired on 2026-07-10', NULL, 'open', 1, NULL, NULL, NULL, NULL, '2026-07-17 01:17:06', '2026-07-17 01:17:06'),
(4, 4, 'General', NULL, 'contracts', 6, 'end_date', NULL, NULL, 'Expired', 'critical', 'Contract #6 expired on 2026-07-10', NULL, 'open', 1, NULL, NULL, NULL, NULL, '2026-07-17 01:17:06', '2026-07-17 01:17:06'),
(5, 4, 'General', NULL, 'contracts', 8, 'end_date', NULL, NULL, 'Expired', 'critical', 'Contract #8 expired on 2026-07-05', NULL, 'open', 1, NULL, NULL, NULL, NULL, '2026-07-17 01:17:06', '2026-07-17 01:17:06'),
(6, 1, 'galaxy', 'Tenant', 'tenants', 10, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"10\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-18 22:46:11\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-18 22:46:11', '2026-08-07 00:07:30'),
(7, 1, 'Galaxy', 'Tenant', 'tenants', 11, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"11\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 00:38:53\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 00:38:53', '2026-07-22 00:38:53'),
(8, 1, 'Galaxy', 'Tenant', 'tenants', 12, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"12\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 22:45:41\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 22:45:41', '2026-07-22 22:45:41'),
(9, 1, 'Galaxy', 'Tenant', 'tenants', 13, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"13\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 22:50:02\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 22:50:02', '2026-07-22 22:50:02'),
(10, 1, 'Galaxy', 'Tenant', 'tenants', 14, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"14\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 23:02:08\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 23:02:08', '2026-07-22 23:02:08'),
(11, 1, 'Galaxy', 'Tenant', 'tenants', 15, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"15\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 23:03:57\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 23:03:57', '2026-07-22 23:03:57'),
(12, 1, 'Galaxy', 'Tenant', 'tenants', 16, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"16\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 23:26:30\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Open', 1, 1, NULL, NULL, NULL, '2026-07-22 23:26:30', '2026-07-22 23:26:30'),
(13, 1, 'Galaxy', 'Tenant', 'tenants', 17, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"17\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 23:41:48\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Resolved', 1, 1, NULL, NULL, NULL, '2026-07-22 23:41:48', '2026-08-07 00:09:37'),
(14, 1, 'Galaxy', 'Tenant', 'tenants', 18, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"18\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-22 23:49:06\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\"}', 'Resolved', 1, 1, NULL, NULL, NULL, '2026-07-22 23:49:06', '2026-08-07 00:08:36'),
(15, 1, 'Galaxy', 'Tenant', 'tenants', 1, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"1\",\"user_id\":null,\"full_name\":\"Ali Yazbek\",\"phone\":\"72691170\",\"email\":\"ali55yazbek@gmail.com\",\"national_id\":\"4819898\",\"created_at\":\"2026-06-18 23:39:08\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Resolved', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:05'),
(16, 1, 'Galaxy', 'Tenant', 'tenants', 3, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"3\",\"user_id\":null,\"full_name\":\"Ali Yazbeck\",\"phone\":\"456454858\",\"email\":\"82030850@students.liu.edu.lb\",\"national_id\":\"4545455\",\"created_at\":\"2026-06-23 23:55:22\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:30'),
(17, 1, 'Galaxy', 'Tenant', 'tenants', 5, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"5\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-06-28 02:17:49\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:30'),
(18, 1, 'Galaxy', 'Tenant', 'tenants', 8, 'national_id', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'national_id\' is missing.', '{\"id\":\"8\",\"user_id\":null,\"full_name\":\"Test User\",\"phone\":\"12345678\",\"email\":null,\"national_id\":\"\",\"created_at\":\"2026-07-05 01:37:36\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:30'),
(19, 1, 'Galaxy', 'Tenant', 'tenants', 8, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"8\",\"user_id\":null,\"full_name\":\"Test User\",\"phone\":\"12345678\",\"email\":null,\"national_id\":\"\",\"created_at\":\"2026-07-05 01:37:36\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:30'),
(20, 1, 'Galaxy', 'Tenant', 'tenants', 9, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"9\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-07-05 22:47:32\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-05 23:21:18', '2026-08-07 00:07:30'),
(21, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 23, 'fuel_level', 'Empty', 'Fuel level value', 'Missing Data', '', 'Fuel level was not recorded in this generator report.', '{\"generator_id\":\"7\",\"photo_meter_path\":\"uploads\\/generator-readings\\/1785788762_meter_Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png\",\"fuel_photo_path\":\"uploads\\/generator-readings\\/1785788762_fuel_Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png\",\"fuel_level\":null,\"current_meter_hours\":\"15155.00\",\"previous_meter_hours\":null,\"date\":\"2026-08-03\",\"notes\":\"\",\"submitted_by\":\"5\"}', 'Resolved', 1, 5, NULL, NULL, NULL, '2026-08-05 23:36:48', '2026-08-07 00:15:16'),
(22, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 7, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"150.00\",\"previous_reading\":\"1.00\",\"consumption\":\"149.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Rejected\"}', 'Resolved', 1, 5, NULL, NULL, NULL, '2026-08-05 23:36:48', '2026-08-07 00:15:14'),
(23, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 8, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"160.00\",\"previous_reading\":\"1.00\",\"consumption\":\"159.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Verified\"}', 'Resolved', 1, 5, NULL, NULL, NULL, '2026-08-05 23:36:48', '2026-08-07 00:15:12'),
(24, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 9, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"180.00\",\"previous_reading\":\"160.00\",\"consumption\":\"20.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Verified\"}', 'Resolved', 1, 5, NULL, NULL, NULL, '2026-08-05 23:36:48', '2026-08-07 00:15:12'),
(25, 1, 'Galaxy', 'Tenant', 'tenants', 1, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"1\",\"user_id\":null,\"full_name\":\"Ali Yazbek\",\"phone\":\"72691170\",\"email\":\"ali55yazbek@gmail.com\",\"national_id\":\"4819898\",\"created_at\":\"2026-06-18 23:39:08\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-07 00:07:29', '2026-08-07 00:07:30'),
(26, 1, 'Galaxy', 'Tenant', 'tenants', 19, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"19\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-08-07 00:17:19\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-07 00:17:19', '2026-08-07 00:17:19'),
(27, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 23, 'fuel_level', 'Empty', 'Fuel level value', 'Missing Data', '', 'Fuel level was not recorded in this generator report.', '{\"generator_id\":\"7\",\"photo_meter_path\":\"uploads\\/generator-readings\\/1785788762_meter_Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png\",\"fuel_photo_path\":\"uploads\\/generator-readings\\/1785788762_fuel_Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png\",\"fuel_level\":null,\"current_meter_hours\":\"15155.00\",\"previous_meter_hours\":null,\"date\":\"2026-08-03\",\"notes\":\"\",\"submitted_by\":\"5\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-07 01:26:17', '2026-08-07 01:33:09'),
(28, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 7, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"150.00\",\"previous_reading\":\"1.00\",\"consumption\":\"149.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Rejected\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-07 01:26:17', '2026-08-07 01:33:09'),
(29, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 8, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"160.00\",\"previous_reading\":\"1.00\",\"consumption\":\"159.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Verified\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-07 01:26:17', '2026-08-07 01:33:09'),
(30, 5, 'Galaxy', 'AgentApartmentReading', 'electricity_meter_readings', 9, 'photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Electricity meter photo is missing from this reading.', '{\"apartment_id\":\"12\",\"photo_path\":null,\"current_reading\":\"180.00\",\"previous_reading\":\"160.00\",\"consumption\":\"20.00\",\"price_per_kwh\":\"500.00\",\"reading_date\":\"2026-08-25\",\"notes\":null,\"submitted_by\":\"5\",\"status\":\"Verified\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-07 01:26:17', '2026-08-07 01:33:09'),
(31, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 24, 'fuel_level', 'Empty', 'Fuel level value', 'Missing Data', '', 'Fuel level was not recorded in this generator report.', '{\"id\":\"24\",\"generator_id\":\"7\",\"date\":\"2026-08-10\",\"fuel_added\":\"4.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"824.00\",\"spare_remaining\":\"824.00\",\"running_hours\":\"46.00\",\"meter_hours\":\"0.00\",\"kwh_produced\":\"33327.00\",\"notes\":\"2\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-10 00:25:52\",\"previous_kwh\":\"51515.00\",\"current_kwh\":\"84842.00\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1786310752_meter_Gemini_Generated_Image_gy3hkvgy3hkvgy3h.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":\"15155.00\",\"current_meter_hours\":\"8045.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":null,\"submitted_at\":\"2026-08-10 00:25:52\",\"approved_at\":null,\"rejected_at\":null,\"approved_by\":null,\"fuel_photo_path\":\"uploads\\/generator-readings\\/1786310752_fuel_Gemini_Generated_Image_gy3hkvgy3hkvgy3h.png\",\"anomaly_flags\":null,\"confidence_score\":\"100\",\"risk_level\":\"low\",\"rejection_reason_code\":null,\"rejection_severity\":null,\"reviewed_at\":null,\"reviewed_by\":null,\"version_number\":\"1\",\"priority\":\"2\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-10 00:25:52', '2026-08-10 00:25:52'),
(32, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 24, 'current_meter_hours', '8045.00', '>= 15155.00', 'Calculation Error', 'critical', 'Generator meter hours decreased (current < previous). Possible data entry error.', '{\"id\":\"24\",\"generator_id\":\"7\",\"date\":\"2026-08-10\",\"fuel_added\":\"4.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"824.00\",\"spare_remaining\":\"824.00\",\"running_hours\":\"46.00\",\"meter_hours\":\"0.00\",\"kwh_produced\":\"33327.00\",\"notes\":\"2\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-10 00:25:52\",\"previous_kwh\":\"51515.00\",\"current_kwh\":\"84842.00\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1786310752_meter_Gemini_Generated_Image_gy3hkvgy3hkvgy3h.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":\"15155.00\",\"current_meter_hours\":\"8045.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":null,\"submitted_at\":\"2026-08-10 00:25:52\",\"approved_at\":null,\"rejected_at\":null,\"approved_by\":null,\"fuel_photo_path\":\"uploads\\/generator-readings\\/1786310752_fuel_Gemini_Generated_Image_gy3hkvgy3hkvgy3h.png\",\"anomaly_flags\":null,\"confidence_score\":\"100\",\"risk_level\":\"low\",\"rejection_reason_code\":null,\"rejection_severity\":null,\"reviewed_at\":null,\"reviewed_by\":null,\"version_number\":\"1\",\"priority\":\"2\"}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-10 00:25:52', '2026-08-10 00:25:52'),
(33, 1, 'Galaxy', 'Tenant', 'tenants', 20, 'passport_url', 'Empty', 'Required', 'Missing Data', 'critical', 'Required field \'passport_url\' is missing.', '{\"id\":\"20\",\"user_id\":\"4\",\"full_name\":\"ali yazbekk\",\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id\":\"564564\",\"created_at\":\"2026-08-23 22:14:41\",\"address\":null,\"emergency_contact\":null,\"passport_url\":null,\"id_url\":null,\"status\":\"Active\",\"deleted_at\":null,\"deleted_by\":null,\"move_out_date\":null}', 'Open', 1, 1, NULL, NULL, NULL, '2026-08-23 22:14:41', '2026-08-23 22:14:41'),
(34, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 1, 'fuel_photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Generator fuel photo is missing from this daily report.', '{\"id\":\"1\",\"generator_id\":\"13\",\"date\":\"2026-08-27\",\"fuel_added\":\"0.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"836.00\",\"spare_remaining\":\"0.00\",\"running_hours\":\"-1966.50\",\"meter_hours\":\"1966.50\",\"kwh_produced\":\"0.00\",\"notes\":\"\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-27 22:44:54\",\"previous_kwh\":\"1966.50\",\"current_kwh\":\"1966.50\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1787862426_meter_Screenshot 2025-08-20 211344.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":null,\"current_meter_hours\":\"0.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":\"incorrect_reading\",\"submitted_at\":\"2026-08-27 23:27:06\",\"approved_at\":null,\"rejected_at\":\"2026-08-27 23:03:29\",\"approved_by\":null,\"fuel_photo_path\":null}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-27 22:44:54', '2026-08-27 23:27:06'),
(35, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 1, 'fuel_level', 'Empty', 'Fuel level value', 'Missing Data', '', 'Fuel level was not recorded in this generator report.', '{\"id\":\"1\",\"generator_id\":\"13\",\"date\":\"2026-08-27\",\"fuel_added\":\"0.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"836.00\",\"spare_remaining\":\"0.00\",\"running_hours\":\"-1966.50\",\"meter_hours\":\"1966.50\",\"kwh_produced\":\"0.00\",\"notes\":\"\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-27 22:44:54\",\"previous_kwh\":\"1966.50\",\"current_kwh\":\"1966.50\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1787862426_meter_Screenshot 2025-08-20 211344.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":null,\"current_meter_hours\":\"0.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":\"incorrect_reading\",\"submitted_at\":\"2026-08-27 23:27:06\",\"approved_at\":null,\"rejected_at\":\"2026-08-27 23:03:29\",\"approved_by\":null,\"fuel_photo_path\":null}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-27 22:44:54', '2026-08-27 23:27:06'),
(36, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 3, 'fuel_photo_path', 'Empty', 'Photo file path', 'Missing Photo', '', 'Generator fuel photo is missing from this daily report.', '{\"id\":\"3\",\"generator_id\":\"12\",\"date\":\"2026-08-27\",\"fuel_added\":\"0.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"600.00\",\"spare_remaining\":\"0.00\",\"running_hours\":\"1144.00\",\"meter_hours\":\"0.00\",\"kwh_produced\":\"0.00\",\"notes\":\"\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-27 23:48:09\",\"previous_kwh\":\"1144.00\",\"current_kwh\":\"0.00\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1787864170_meter_Screenshot 2025-08-21 210922.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":null,\"current_meter_hours\":\"1144.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":\"incorrect_reading\",\"submitted_at\":\"2026-08-27 23:56:10\",\"approved_at\":null,\"rejected_at\":\"2026-08-27 23:48:44\",\"approved_by\":null,\"fuel_photo_path\":null}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-27 23:48:09', '2026-08-27 23:56:10'),
(37, 5, 'Galaxy', 'AgentGenerator', 'generator_daily_reports', 3, 'fuel_level', 'Empty', 'Fuel level value', 'Missing Data', '', 'Fuel level was not recorded in this generator report.', '{\"id\":\"3\",\"generator_id\":\"12\",\"date\":\"2026-08-27\",\"fuel_added\":\"0.00\",\"expected_fuel_used\":\"0.00\",\"cost_per_liter\":\"0.00\",\"fuel_remaining\":\"600.00\",\"spare_remaining\":\"0.00\",\"running_hours\":\"1144.00\",\"meter_hours\":\"0.00\",\"kwh_produced\":\"0.00\",\"notes\":\"\",\"discrepancy_reason\":null,\"photo_path\":null,\"submitted_by\":\"5\",\"created_at\":\"2026-08-27 23:48:09\",\"previous_kwh\":\"1144.00\",\"current_kwh\":\"0.00\",\"efficiency_score\":null,\"alert_level\":\"Normal\",\"load_percentage\":null,\"outages_count\":\"0\",\"expected_fuel_consumption\":null,\"actual_fuel_consumption\":null,\"fuel_consumption_per_hour\":null,\"fuel_consumption_per_kwh\":null,\"cost_of_electricity\":null,\"fuel_variance\":null,\"estimated_days_empty\":null,\"photo_meter_path\":\"uploads\\/generator-readings\\/1787864170_meter_Screenshot 2025-08-21 210922.png\",\"actual_fuel_remaining\":null,\"estimated_fuel_remaining\":null,\"estimated_fuel_used\":null,\"actual_fuel_used\":null,\"fuel_difference\":null,\"status\":\"Pending Verification\",\"previous_meter_hours\":null,\"current_meter_hours\":\"1144.00\",\"liters_per_hour\":\"0.00\",\"liters_per_kwh\":\"0.00\",\"rejection_reason\":\"incorrect_reading\",\"submitted_at\":\"2026-08-27 23:56:10\",\"approved_at\":null,\"rejected_at\":\"2026-08-27 23:48:44\",\"approved_by\":null,\"fuel_photo_path\":null}', 'Open', 1, 5, NULL, NULL, NULL, '2026-08-27 23:48:09', '2026-08-27 23:56:10');

-- --------------------------------------------------------

--
-- Table structure for table `audit_scan_runs`
--

CREATE TABLE `audit_scan_runs` (
  `id` int(11) NOT NULL,
  `triggered_by` int(11) DEFAULT NULL COMMENT 'user_id or NULL for cron',
  `total_found` int(11) NOT NULL DEFAULT 0,
  `critical_found` int(11) NOT NULL DEFAULT 0,
  `warning_found` int(11) NOT NULL DEFAULT 0,
  `info_found` int(11) NOT NULL DEFAULT 0,
  `duration_ms` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_scan_runs`
--

INSERT INTO `audit_scan_runs` (`id`, `triggered_by`, `total_found`, `critical_found`, `warning_found`, `info_found`, `duration_ms`, `created_at`) VALUES
(1, NULL, 4, 3, 0, 1, 42, '2026-07-17 01:17:06'),
(2, NULL, 0, 0, 0, 0, 20, '2026-07-17 01:26:29'),
(3, 1, 0, 0, 0, 0, 23, '2026-07-17 02:04:47'),
(4, 1, 0, 0, 0, 0, 20, '2026-08-05 23:42:13');

-- --------------------------------------------------------

--
-- Table structure for table `audit_trail`
--

CREATE TABLE `audit_trail` (
  `id` int(11) NOT NULL,
  `audit_report_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` varchar(100) NOT NULL COMMENT 'detected|unlocked|locked|fixed|submitted|approved|rejected|commented',
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `audit_trail`
--

INSERT INTO `audit_trail` (`id`, `audit_report_id`, `user_id`, `action`, `old_value`, `new_value`, `comment`, `created_at`) VALUES
(1, 1, 0, 'detected', NULL, 'National ID is missing for tenant: Test User', NULL, '2026-07-17 01:16:20'),
(2, 2, 0, 'detected', NULL, 'Contract #1 expires soon on 2026-07-18', NULL, '2026-07-17 01:17:06'),
(3, 3, 0, 'detected', NULL, 'Contract #5 expired on 2026-07-10', NULL, '2026-07-17 01:17:06'),
(4, 4, 0, 'detected', NULL, 'Contract #6 expired on 2026-07-10', NULL, '2026-07-17 01:17:06'),
(5, 5, 0, 'detected', NULL, 'Contract #8 expired on 2026-07-05', NULL, '2026-07-17 01:17:06'),
(6, 6, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-18 22:46:11'),
(7, 7, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 00:38:53'),
(8, 8, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 22:45:41'),
(9, 9, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 22:50:02'),
(10, 10, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 23:02:08'),
(11, 11, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 23:03:57'),
(12, 12, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 23:26:30'),
(13, 13, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 23:41:48'),
(14, 14, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-07-22 23:49:06'),
(15, 15, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(16, 16, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(17, 17, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(18, 18, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(19, 19, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(20, 1, 1, 'Auto Resolved', 'Open', 'Resolved', 'System detected issue is fixed upon resave.', '2026-08-05 23:21:18'),
(21, 20, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:21:18'),
(22, 21, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:36:48'),
(23, 22, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:36:48'),
(24, 23, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:36:48'),
(25, 24, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-05 23:36:48'),
(26, 25, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 00:07:29'),
(27, 13, 1, 'Approve', '', '', '', '2026-08-07 00:09:37'),
(28, 21, 1, 'Notify', '', '', '', '2026-08-07 00:12:39'),
(29, 21, 1, 'Notify', '', '', '', '2026-08-07 00:12:40'),
(30, 21, 1, 'Notify', '', '', '', '2026-08-07 00:12:40'),
(31, 21, 1, 'Notify', '', '', '', '2026-08-07 00:12:40'),
(32, 24, 1, 'Approve', '', '', '', '2026-08-07 00:15:12'),
(33, 23, 1, 'Approve', '', '', '', '2026-08-07 00:15:12'),
(34, 22, 1, 'Approve', '', '', '', '2026-08-07 00:15:14'),
(35, 21, 1, 'Approve', '', '', '', '2026-08-07 00:15:16'),
(36, 26, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 00:17:19'),
(37, 27, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 01:26:17'),
(38, 28, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 01:26:17'),
(39, 29, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 01:26:17'),
(40, 30, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-07 01:26:17'),
(41, 31, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-10 00:25:52'),
(42, 32, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-10 00:25:52'),
(43, 33, 1, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-23 22:14:41'),
(44, 34, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-27 22:44:54'),
(45, 35, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-27 22:44:54'),
(46, 36, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-27 23:48:09'),
(47, 37, 5, 'Problem Found', NULL, 'Open', 'System detected an issue during save.', '2026-08-27 23:48:09');

-- --------------------------------------------------------

--
-- Table structure for table `buildings`
--

CREATE TABLE `buildings` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `buildings`
--

INSERT INTO `buildings` (`id`, `name`, `created_at`, `deleted_at`, `deleted_by`) VALUES
(5, 'Galaxy', '2026-07-21 21:00:57', NULL, NULL),
(6, 'df', '2026-08-17 21:41:04', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `building_events`
--

CREATE TABLE `building_events` (
  `id` int(11) NOT NULL,
  `building_id` int(11) DEFAULT NULL,
  `apartment_id` int(11) DEFAULT NULL,
  `event_type` varchar(100) NOT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `building_health_scores`
--

CREATE TABLE `building_health_scores` (
  `id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `score` decimal(5,2) DEFAULT 100.00,
  `grade` enum('Excellent','Good','Fair','Poor','Critical') DEFAULT 'Excellent',
  `missing_readings_score` decimal(5,2) DEFAULT 30.00,
  `rejection_rate_score` decimal(5,2) DEFAULT 25.00,
  `anomaly_score` decimal(5,2) DEFAULT 20.00,
  `late_submission_score` decimal(5,2) DEFAULT 15.00,
  `pending_requests_score` decimal(5,2) DEFAULT 10.00,
  `total_apartments` int(11) DEFAULT 0,
  `pending_count` int(11) DEFAULT 0,
  `rejected_count` int(11) DEFAULT 0,
  `details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`details`)),
  `calculated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `building_health_scores`
--

INSERT INTO `building_health_scores` (`id`, `building_id`, `score`, `grade`, `missing_readings_score`, `rejection_rate_score`, `anomaly_score`, `late_submission_score`, `pending_requests_score`, `total_apartments`, `pending_count`, `rejected_count`, `details`, `calculated_at`) VALUES
(1, 5, 92.50, 'Excellent', 22.50, 25.00, 20.00, 15.00, 10.00, 25, 0, 0, '{\"missing_readings_score\":22.5,\"rejection_rate_score\":25,\"anomaly_score\":20,\"late_submission_score\":15,\"pending_requests_score\":10,\"missing_pct\":25}', '2026-08-27 18:48:44');

-- --------------------------------------------------------

--
-- Table structure for table `building_restrictions`
--

CREATE TABLE `building_restrictions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `can_access` tinyint(1) NOT NULL DEFAULT 1,
  `granted_by` int(11) DEFAULT NULL,
  `granted_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `button_permissions`
--

CREATE TABLE `button_permissions` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `page_key` varchar(100) NOT NULL,
  `button_key` varchar(150) NOT NULL,
  `button_label` varchar(200) DEFAULT NULL,
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `is_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `cashier_sessions`
--

CREATE TABLE `cashier_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `opened_at` datetime NOT NULL,
  `closed_at` datetime DEFAULT NULL,
  `opening_cash` decimal(10,2) NOT NULL DEFAULT 0.00,
  `closing_cash` decimal(10,2) DEFAULT NULL,
  `total_sales` decimal(10,2) DEFAULT 0.00,
  `total_refunds` decimal(10,2) DEFAULT 0.00,
  `total_expenses` decimal(10,2) DEFAULT 0.00,
  `status` enum('Open','Closed') DEFAULT 'Open',
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `cashier_sessions`
--

INSERT INTO `cashier_sessions` (`id`, `user_id`, `opened_at`, `closed_at`, `opening_cash`, `closing_cash`, `total_sales`, `total_refunds`, `total_expenses`, `status`, `notes`) VALUES
(1, 1, '2026-07-19 23:13:20', NULL, 300000.00, NULL, 0.00, 0.00, 0.00, 'Open', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `cash_drawers`
--

CREATE TABLE `cash_drawers` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `balance` decimal(15,2) DEFAULT 0.00,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `constructions`
--

CREATE TABLE `constructions` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `owner` varchar(255) DEFAULT NULL,
  `location` varchar(255) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `status` varchar(50) DEFAULT 'Planning',
  `budget` decimal(10,2) DEFAULT 0.00,
  `estimated_cost` decimal(10,2) DEFAULT 0.00,
  `actual_cost` decimal(10,2) DEFAULT 0.00,
  `manager` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `workshop_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `constructions`
--

INSERT INTO `constructions` (`id`, `name`, `owner`, `location`, `start_date`, `end_date`, `status`, `budget`, `estimated_cost`, `actual_cost`, `manager`, `notes`, `created_at`, `workshop_id`) VALUES
(1, 'ali', 'bitar', 'bangui', '2026-10-10', '2027-10-10', 'Active', 750000.00, 0.00, 688618.49, 'yehya', NULL, '2026-06-19 20:52:55', NULL),
(2, 'fdgfg', 'Bitar Group', 'Local', '2026-06-28', '2026-12-25', 'Active', 99999999.99, 99999999.99, 75455500.00, 'Manager', NULL, '2026-06-28 17:12:18', 4);

-- --------------------------------------------------------

--
-- Table structure for table `construction_materials`
--

CREATE TABLE `construction_materials` (
  `id` int(11) NOT NULL,
  `construction_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `category` varchar(50) DEFAULT NULL,
  `estimated_quantity` decimal(10,2) NOT NULL,
  `used_quantity` decimal(10,2) DEFAULT 0.00,
  `wasted_quantity` decimal(10,2) DEFAULT 0.00,
  `waste_reason` text DEFAULT NULL,
  `unit` varchar(20) DEFAULT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `total_estimated_cost` decimal(10,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `item_name_fr` varchar(255) DEFAULT NULL,
  `item_name_ar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `construction_materials`
--

INSERT INTO `construction_materials` (`id`, `construction_id`, `item_name`, `category`, `estimated_quantity`, `used_quantity`, `wasted_quantity`, `waste_reason`, `unit`, `unit_price`, `total_estimated_cost`, `created_at`, `item_name_fr`, `item_name_ar`) VALUES
(1, 2, 'Concrete', 'Material', 108982.50, 0.00, 0.00, NULL, 'm3', 120.00, 13077900.00, '2026-06-28 17:12:18', NULL, NULL),
(2, 2, 'Steel', 'Material', 13077.90, 0.00, 0.00, NULL, 'Ton', 800.00, 10462320.00, '2026-06-28 17:12:18', NULL, NULL),
(3, 2, 'Cement', 'Material', 841177.50, 754555.00, 0.00, NULL, 'Bag', 12.00, 10094130.00, '2026-06-28 17:12:18', NULL, NULL),
(4, 2, 'Blocks', 'Material', 7830000.00, 0.00, 0.00, NULL, 'Piece', 0.50, 3915000.00, '2026-06-28 17:12:18', NULL, NULL),
(5, 2, 'Sand', 'Material', 63088.31, 0.00, 0.00, NULL, 'Ton', 30.00, 1892649.38, '2026-06-28 17:12:18', NULL, NULL),
(6, 2, 'Tiles', 'Material', 313200.00, 0.00, 0.00, NULL, 'm2', 15.00, 4698000.00, '2026-06-28 17:12:18', NULL, NULL),
(7, 2, 'Paint', 'Material', 391500.00, 0.00, 0.00, NULL, 'Liter', 4.00, 1566000.00, '2026-06-28 17:12:18', NULL, NULL),
(8, 2, 'Electrical Cables', 'Material', 1044000.00, 0.00, 0.00, NULL, 'Meter', 1.50, 1566000.00, '2026-06-28 17:12:18', NULL, NULL),
(9, 2, 'Water Pipes', 'Material', 391500.00, 0.00, 0.00, NULL, 'Meter', 3.00, 1174500.00, '2026-06-28 17:12:18', NULL, NULL),
(10, 2, 'Doors', 'Material', 13050.00, 0.00, 0.00, NULL, 'Piece', 150.00, 1957500.00, '2026-06-28 17:12:18', NULL, NULL),
(11, 2, 'Windows', 'Material', 135720.00, 0.00, 0.00, NULL, 'Piece', 200.00, 27144000.00, '2026-06-28 17:12:18', NULL, NULL),
(12, 2, 'Mason', 'Labor', 375840.00, 0.00, 0.00, NULL, 'Mandays', 25.00, 9396000.00, '2026-06-28 17:12:18', NULL, NULL),
(13, 2, 'Electrician', 'Labor', 140940.00, 0.00, 0.00, NULL, 'Mandays', 35.00, 4932900.00, '2026-06-28 17:12:18', NULL, NULL),
(14, 2, 'Plumber', 'Labor', 140940.00, 0.00, 0.00, NULL, 'Mandays', 35.00, 4932900.00, '2026-06-28 17:12:18', NULL, NULL),
(15, 2, 'Painter', 'Labor', 187920.00, 0.00, 0.00, NULL, 'Mandays', 20.00, 3758400.00, '2026-06-28 17:12:18', NULL, NULL),
(16, 2, 'Supervisor', 'Labor', 1080.00, 0.00, 0.00, NULL, 'Mandays', 50.00, 54000.00, '2026-06-28 17:12:18', NULL, NULL),
(17, 2, 'Excavator', 'Equipment', 30.00, 0.00, 0.00, NULL, 'Days', 200.00, 6000.00, '2026-06-28 17:12:18', NULL, NULL),
(18, 2, 'Crane', 'Equipment', 540.00, 0.00, 0.00, NULL, 'Days', 150.00, 81000.00, '2026-06-28 17:12:18', NULL, NULL),
(19, 2, 'Concrete Mixer', 'Equipment', 180.00, 0.00, 0.00, NULL, 'Days', 100.00, 18000.00, '2026-06-28 17:12:18', NULL, NULL),
(20, 2, 'Generator', 'Equipment', 540.00, 0.00, 0.00, NULL, 'Days', 50.00, 27000.00, '2026-06-28 17:12:18', NULL, NULL),
(21, 2, 'Permits & Fees', 'Other', 1.00, 0.00, 0.00, NULL, 'Lump Sum', 15000.00, 15000.00, '2026-06-28 17:12:18', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `construction_material_movements`
--

CREATE TABLE `construction_material_movements` (
  `id` int(11) NOT NULL,
  `construction_id` int(11) DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `type` enum('Warehouse_To_Site','Supplier_To_Site','Site_To_Warehouse','Site_To_Consumption','Site_To_Waste') DEFAULT NULL,
  `quantity` decimal(10,2) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `date` datetime DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `construction_material_movements`
--

INSERT INTO `construction_material_movements` (`id`, `construction_id`, `item_name`, `type`, `quantity`, `reference_id`, `user_id`, `notes`, `date`) VALUES
(1, 0, 'cement', 'Supplier_To_Site', 15000.00, 1, 1, NULL, '2026-06-28 21:01:43'),
(2, 2, 'Cement', 'Supplier_To_Site', 70000.00, 2, 1, NULL, '2026-06-28 21:07:33'),
(3, 2, 'Cement', 'Supplier_To_Site', 684545.00, 2, 1, NULL, '2026-06-28 21:07:44'),
(4, 2, 'Cement', 'Site_To_Consumption', 754545.00, NULL, 1, '', '2026-06-28 21:08:49'),
(5, 2, 'Cement', 'Supplier_To_Site', 10.00, 3, 1, NULL, '2026-06-28 21:20:56'),
(6, 2, 'Cement', 'Site_To_Consumption', 10.00, NULL, 1, '', '2026-06-28 21:21:24');

-- --------------------------------------------------------

--
-- Table structure for table `construction_site_stock`
--

CREATE TABLE `construction_site_stock` (
  `id` int(11) NOT NULL,
  `construction_id` int(11) DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `quantity` decimal(10,2) DEFAULT 0.00,
  `unit` varchar(50) DEFAULT NULL,
  `last_updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `construction_site_stock`
--

INSERT INTO `construction_site_stock` (`id`, `construction_id`, `item_name`, `quantity`, `unit`, `last_updated_at`) VALUES
(1, 1, 'cement', 15000.00, NULL, '2026-06-28 18:05:26'),
(2, 2, 'Cement', 0.00, NULL, '2026-06-28 18:21:24');

-- --------------------------------------------------------

--
-- Table structure for table `contracts`
--

CREATE TABLE `contracts` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `rent_start_date` date DEFAULT NULL,
  `rent_end_date` date DEFAULT NULL,
  `status` enum('Active','Terminated','Expired','Draft','Pending_Signature','Signed','Approved','Rejected','Renewal_Pending') DEFAULT 'Draft',
  `rent_status` enum('Active','Paused','Closed') DEFAULT 'Active',
  `insurance_status` enum('Pending Payment','Paid') DEFAULT 'Pending Payment',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `monthly_rent` decimal(10,2) DEFAULT 0.00,
  `monthly_insurance` decimal(10,2) DEFAULT 0.00,
  `payment_terms` text DEFAULT NULL,
  `contract_document_url` varchar(255) DEFAULT NULL,
  `signed_document_url` varchar(255) DEFAULT NULL,
  `manager_approval_date` datetime DEFAULT NULL,
  `contract_file` varchar(255) DEFAULT NULL,
  `payment_method_rule` enum('Any Method','Bank Transfer Only','Cash Only','Mobile Money Only') DEFAULT 'Any Method',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `contracts`
--

INSERT INTO `contracts` (`id`, `apartment_id`, `tenant_id`, `start_date`, `end_date`, `rent_start_date`, `rent_end_date`, `status`, `rent_status`, `insurance_status`, `created_at`, `monthly_rent`, `monthly_insurance`, `payment_terms`, `contract_document_url`, `signed_document_url`, `manager_approval_date`, `contract_file`, `payment_method_rule`, `deleted_at`, `deleted_by`) VALUES
(18, 11, 15, '2026-10-10', '2027-07-10', NULL, NULL, 'Active', 'Active', 'Paid', '2026-07-22 20:03:57', 720000.00, 180000.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(19, 12, 16, '2026-07-10', '2026-09-24', NULL, NULL, 'Terminated', '', 'Paid', '2026-07-22 20:26:30', 840000.00, 180000.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(22, 14, 19, '2026-07-15', '2026-09-21', NULL, NULL, 'Terminated', '', 'Pending Payment', '2026-08-06 21:17:19', 210000.00, 30000.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(23, 13, 20, '2026-10-10', '2026-09-21', NULL, NULL, 'Terminated', '', 'Pending Payment', '2026-08-23 19:14:41', 855000.00, 312000.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(35, 26, 32, '2026-04-21', '2027-04-21', '2026-04-21', '2027-04-21', 'Active', 'Active', '', '2026-09-21 21:53:40', 500.00, 120.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(36, 27, 33, '2026-04-21', '2027-04-21', '2026-04-21', '2027-04-21', 'Active', 'Active', '', '2026-09-21 21:53:40', 650.00, 150.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(37, 28, 34, '2026-04-21', '2027-04-21', '2026-04-21', '2027-04-21', 'Active', 'Active', '', '2026-09-21 21:53:40', 550.00, 120.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(38, 29, 35, '2026-04-21', '2026-09-24', '2026-04-21', '2027-04-21', 'Terminated', '', '', '2026-09-21 21:53:40', 700.00, 180.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL),
(39, 30, 36, '2026-04-21', '2026-09-22', '2026-04-21', '2027-04-21', 'Terminated', '', '', '2026-09-21 21:53:40', 480.00, 100.00, NULL, NULL, NULL, NULL, NULL, 'Any Method', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `contract_versions`
--

CREATE TABLE `contract_versions` (
  `id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `version_number` int(11) NOT NULL,
  `rent_amount` decimal(10,2) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `correction_requests`
--

CREATE TABLE `correction_requests` (
  `id` int(11) NOT NULL,
  `type` enum('generator_reading','electricity_reading') NOT NULL,
  `entity_id` int(11) NOT NULL,
  `original_value` decimal(12,2) DEFAULT NULL,
  `proposed_value` decimal(12,2) NOT NULL,
  `notes` text DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `status` enum('Pending','Approved','Rejected') DEFAULT 'Pending',
  `submitted_by` int(11) NOT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `daily_logs`
--

CREATE TABLE `daily_logs` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `submitted_hours` float NOT NULL,
  `calculated_hours_worked` float NOT NULL,
  `expected_factory_fuel_burn` float NOT NULL,
  `ml_predicted_fuel_burn` float DEFAULT NULL,
  `predicted_fuel_remaining` float DEFAULT NULL,
  `admin_actual_fuel` float DEFAULT NULL,
  `fuel_price_at_time` decimal(10,2) DEFAULT NULL,
  `status_flag` varchar(50) DEFAULT 'Normal',
  `ai_report` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `actual_fuel_spent` float DEFAULT NULL,
  `actual_consumption_rate` float DEFAULT NULL,
  `missing_fuel_variance` float DEFAULT NULL,
  `financial_loss_cfa` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `daily_logs`
--

INSERT INTO `daily_logs` (`id`, `generator_id`, `date`, `submitted_hours`, `calculated_hours_worked`, `expected_factory_fuel_burn`, `ml_predicted_fuel_burn`, `predicted_fuel_remaining`, `admin_actual_fuel`, `fuel_price_at_time`, `status_flag`, `ai_report`, `created_at`, `actual_fuel_spent`, `actual_consumption_rate`, `missing_fuel_variance`, `financial_loss_cfa`) VALUES
(1, 1, '2026-08-16', 1510, 0, 0, NULL, 800, NULL, NULL, 'Normal', 'Baseline setup confirmed. Zero runtime recorded with no fuel consumption or variance detected.', '2026-08-16 15:49:27', NULL, NULL, 0, 0),
(2, 1, '2026-08-16', 1510, 0, 0, NULL, 800, NULL, NULL, 'Normal', 'Baseline setup. Engine run time is 0 hours. No fuel consumption occurred and actual tank level was not provided. No anomalies detected.', '2026-08-16 15:50:38', NULL, NULL, NULL, NULL),
(3, 1, '2026-08-16', 1510, 0, 0, NULL, NULL, NULL, NULL, 'Pending Analysis', NULL, '2026-08-16 16:08:14', NULL, NULL, NULL, NULL),
(4, 1, '2026-08-16', 1530, 20, 310, 310, 0, NULL, NULL, 'Normal', '**Summary:** On August 16, 2026, Generator 1 operated for 20.00 hours under normal conditions with no anomalies detected. The system performance aligns precisely with both factory and machine learning expectations.\n\n**Fuel Diagnostics:** \n- Expected Consumption: 310.00 Liters\n- ML Predicted Consumption: 310.00 Liters\n- Estimated Remaining Fuel: 0.00 Liters\n\n**Analysis & Recommendations:** Generator 1 is operating normally, with the machine learning model\'s predicted fuel burn matching the factory expected fuel burn of 310.00 liters exactly. Because the estimated remaining fuel is currently at 0.00 liters, it is recommended to schedule an immediate refueling of the unit to ensure uninterrupted operation. No mechanical or behavioral anomalies were detected during today\'s run.', '2026-08-16 16:08:48', NULL, NULL, NULL, NULL),
(5, 12, '2026-08-01', 1005, 5, 50, 50, 950, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(6, 12, '2026-08-02', 1011, 6, 60, 60, 890, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(7, 12, '2026-08-03', 1016, 5, 50, NULL, 590, NULL, NULL, 'Normal', 'Run time verified at 5 hours based on meter readings. Because the agent did not provide the current tank level, actual fuel consumption and variance could not be computed. No anomalies detected.', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(8, 12, '2026-08-04', 1026, 10, 100, 100, 740, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(9, 12, '2026-08-05', 1031, 5, 50, 50, 690, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(10, 12, '2026-08-06', 1043, 12, 120, 120, 570, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(11, 12, '2026-08-07', 1049, 6, 60, 60, 510, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(12, 12, '2026-08-08', 1054, 5, 50, 50, 460, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(13, 12, '2026-08-09', 1065, 11, 110, 110, 350, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(14, 12, '2026-08-10', 1071, 6, 60, 60, 290, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(15, 12, '2026-08-11', 1080, 9, 90, 90, 710, NULL, NULL, 'Normal', 'The generator ran for 9.0 hours, which is within the plausible daily limit. Estimated fuel consumption is 90.0 L, leaving an estimated 710.0 L in the tank. A fuel variance anomaly check could not be performed because the agent did not record the current fuel level.', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(16, 12, '2026-08-12', 1086, 6, 60, 60, 140, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(17, 12, '2026-08-13', 1093, 7, 70, 70, 930, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(18, 12, '2026-08-14', 1102, 9, 90, 90, 840, NULL, NULL, 'Normal', 'Simulated AI Report OK', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(19, 12, '2026-08-15', 1112, 10, 100, NULL, 540, NULL, NULL, 'Normal', 'Generator ran for 10.0 hours based on meter telemetry with an estimated usage of 100.0 L. Fuel level verification is pending as the agent did not report the current tank level.', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(20, 12, '2026-08-16', 1122, 10, 100, NULL, 540, NULL, NULL, 'Normal', 'Generator run time successfully validated at 10.0 hours via meter reading. Estimated fuel spent is 100.0 L with an expected remaining volume of 540.0 L. Because the agent did not report the current tank level, actual fuel burn rates and theft alert evaluations cannot be calculated.', '2026-08-17 20:19:04', NULL, NULL, NULL, NULL),
(23, 13, '2026-08-01', 1924.15, 6.46, 51.68, NULL, 1163.32, NULL, NULL, 'Verified', 'Run time calculated successfully from meter hours. Since the physical tank reading was not provided, actual consumption metrics and theft alerts cannot be computed.', '2026-07-31 22:57:00', NULL, NULL, NULL, NULL),
(24, 13, '2026-08-18', 1930.05, 5.9, 47.2, NULL, 1116.12, 1125, NULL, 'Verified', 'Actual consumption rate (6.49 L/h) is lower than factory rate (8.00 L/h). More fuel remaining than expected; possible SENSOR_ERROR_OR_UNRECORDED_REFILL.', '2026-08-18 21:04:23', 38.32, 6.49, -8.88, 0),
(25, 13, '2026-08-19', 1937.19, 7.14, 57.12, NULL, 1067.88, 1080, NULL, 'Verified', 'SENSOR_ERROR_OR_UNRECORDED_REFILL: Actual fuel spent is significantly lower than estimated (more fuel remaining than expected).', '2026-08-19 20:20:48', 45, 6.3025, -12.12, 0),
(26, 13, '2026-08-22', 1945.2, 8.01, 64.08, NULL, 1015.92, 1040, NULL, 'Verified', 'SENSOR_ERROR_OR_UNRECORDED_REFILL: Fuel level higher than expected. Actual consumption (4.99 L/h) is significantly lower than factory baseline (8.00 L/h).', '2026-08-22 20:19:18', 40, 4.99, -24.08, 0),
(27, 13, '2026-08-24', 1950.2, 5, 40, NULL, 1000, 1000, 850.00, 'Verified', 'Normal operation. Fuel consumption matches expected factory rate perfectly.', '2026-08-24 19:52:46', 40, 8, 0, 0),
(28, 13, '2026-08-27', 1966.5, 16.3, 130.4, NULL, 869.6, 836, 850.00, 'Verified', 'VOL ALERT DETECTED: Actual consumption rate (10.06 L/h) exceeds factory baseline (8.0 L/h) by 25.75%, which is well above the 5% allowable threshold. Unaccounted fuel loss of 33.6 liters detected.', '2026-08-27 19:44:54', 164, 10.06, 33.6, 28560),
(29, 12, '2026-08-27', 1144, 22, 220, NULL, 320, 600, 850.00, 'Normal', 'SENSOR_ERROR_OR_UNRECORDED_REFILL: Current tank level exceeds starting level despite generator runtime.', '2026-08-27 20:48:09', -60, -2.73, -280, 0),
(30, 13, '2026-09-25', 1970, 3.5, 28, NULL, NULL, NULL, 850.00, 'Pending Analysis', NULL, '2026-09-25 20:30:20', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `daily_reports`
--

CREATE TABLE `daily_reports` (
  `id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `apartments_visited` text DEFAULT NULL,
  `tasks_completed` int(11) DEFAULT 0,
  `issues_found` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `status` enum('Completed','Pending','Missing Photos') DEFAULT 'Pending',
  `photos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`photos`)),
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `damage_reports`
--

CREATE TABLE `damage_reports` (
  `id` int(11) NOT NULL,
  `transaction_id` int(11) NOT NULL,
  `reason` text NOT NULL,
  `photos` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`photos`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `department_restrictions`
--

CREATE TABLE `department_restrictions` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `department` varchar(100) NOT NULL,
  `restricted_module` varchar(100) NOT NULL COMMENT 'workshop|maintenance|warehouse|invoices|...',
  `is_restricted` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `depots`
--

CREATE TABLE `depots` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_primary` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `depots`
--

INSERT INTO `depots` (`id`, `name`, `is_primary`, `created_at`) VALUES
(1, 'Main Depot', 1, '2026-06-30 22:51:36'),
(2, 'secondary', 0, '2026-07-01 19:33:15');

-- --------------------------------------------------------

--
-- Table structure for table `depot_transfers`
--

CREATE TABLE `depot_transfers` (
  `id` int(11) NOT NULL,
  `from_depot_id` int(11) NOT NULL,
  `to_depot_id` int(11) NOT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `depot_transfers`
--

INSERT INTO `depot_transfers` (`id`, `from_depot_id`, `to_depot_id`, `date`, `user_id`, `notes`) VALUES
(1, 1, 2, '2026-07-01 22:38:15', 1, 'test');

-- --------------------------------------------------------

--
-- Table structure for table `depot_transfer_items`
--

CREATE TABLE `depot_transfer_items` (
  `id` int(11) NOT NULL,
  `transfer_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `depot_transfer_items`
--

INSERT INTO `depot_transfer_items` (`id`, `transfer_id`, `product_id`, `quantity`) VALUES
(1, 1, 3, 14);

-- --------------------------------------------------------

--
-- Table structure for table `electricity_invoices`
--

CREATE TABLE `electricity_invoices` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `type` enum('Subscription','Meter') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `due_date` date NOT NULL,
  `status` enum('Unpaid','Partially Paid','Paid') DEFAULT 'Unpaid',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `amount_paid` decimal(10,2) NOT NULL DEFAULT 0.00,
  `qr_requested_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `electricity_invoices`
--

INSERT INTO `electricity_invoices` (`id`, `apartment_id`, `type`, `amount`, `due_date`, `status`, `created_at`, `amount_paid`, `qr_requested_at`) VALUES
(16, 11, 'Subscription', 150000.00, '2026-07-25', 'Paid', '2026-07-25 21:13:22', 150000.00, NULL),
(17, 12, 'Meter', 74500.00, '2026-09-01', 'Paid', '2026-07-25 21:26:21', 74500.00, NULL),
(18, 12, 'Meter', 79500.00, '2026-08-25', 'Paid', '2026-07-26 20:49:05', 79500.00, '2026-08-09 02:44:47'),
(19, 12, 'Meter', 10000.00, '2026-09-01', 'Paid', '2026-07-26 20:49:15', 10000.00, '2026-08-09 02:43:14'),
(20, 13, 'Meter', 25000.00, '2026-08-14', 'Unpaid', '2026-08-07 21:12:54', 0.00, NULL),
(21, 13, 'Subscription', 250000.00, '2026-08-07', 'Unpaid', '2026-08-07 21:13:17', 0.00, NULL),
(22, 11, 'Subscription', 150000.00, '2026-08-08', 'Unpaid', '2026-08-07 21:20:02', 0.00, NULL),
(23, 13, 'Meter', 500000.00, '2026-09-06', 'Unpaid', '2026-08-07 21:33:10', 0.00, NULL),
(24, 13, 'Subscription', 250000.00, '2026-09-07', 'Paid', '2026-08-07 21:46:51', 250000.00, NULL),
(25, 11, 'Subscription', 150000.00, '2026-09-07', 'Unpaid', '2026-08-08 23:03:14', 0.00, NULL),
(196, 26, '', 50.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(197, 26, 'Meter', 15.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(198, 26, '', 50.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(199, 26, 'Meter', 15.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(200, 26, '', 50.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(201, 26, 'Meter', 15.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(202, 26, '', 50.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(203, 26, 'Meter', 15.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(204, 26, '', 50.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(205, 26, 'Meter', 15.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(206, 27, '', 75.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(207, 27, 'Meter', 17.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(208, 27, '', 75.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(209, 27, 'Meter', 17.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(210, 27, '', 75.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(211, 27, 'Meter', 17.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(212, 27, '', 75.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(213, 27, 'Meter', 17.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(214, 27, '', 75.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(215, 27, 'Meter', 17.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(216, 28, '', 25.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(217, 28, 'Meter', 13.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(218, 28, '', 25.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(219, 28, 'Meter', 13.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(220, 28, '', 25.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(221, 28, 'Meter', 13.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(222, 28, '', 25.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(223, 28, 'Meter', 13.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(224, 28, '', 25.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(225, 28, 'Meter', 13.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(226, 29, '', 100.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(227, 29, 'Meter', 21.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(228, 29, '', 100.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(229, 29, 'Meter', 21.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(230, 29, '', 100.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(231, 29, 'Meter', 21.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(232, 29, '', 100.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(233, 29, 'Meter', 21.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(234, 29, '', 100.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(235, 29, 'Meter', 21.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(236, 30, '', 50.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(237, 30, 'Meter', 13.00, '2026-04-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(238, 30, '', 50.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(239, 30, 'Meter', 13.00, '2026-05-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(240, 30, '', 50.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(241, 30, 'Meter', 13.00, '2026-06-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(242, 30, '', 50.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(243, 30, 'Meter', 13.00, '2026-07-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(244, 30, '', 50.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL),
(245, 30, 'Meter', 13.00, '2026-08-21', 'Paid', '2026-09-21 21:53:40', 0.00, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `electricity_meter_readings`
--

CREATE TABLE `electricity_meter_readings` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `meter_number` varchar(100) DEFAULT NULL,
  `previous_reading` decimal(12,2) NOT NULL DEFAULT 0.00,
  `current_reading` decimal(12,2) NOT NULL DEFAULT 0.00,
  `price_per_kwh` decimal(10,2) NOT NULL DEFAULT 0.00,
  `consumption` decimal(12,2) NOT NULL DEFAULT 0.00,
  `bill_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `reading_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `photo_path` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `submitted_by` int(11) DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `status` enum('Pending','Pending Verification','Approved','Verified','Rejected','Resubmitted') DEFAULT 'Pending',
  `rejection_reason` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT current_timestamp(),
  `approved_at` datetime DEFAULT NULL,
  `rejected_at` datetime DEFAULT NULL,
  `billing_month` int(11) DEFAULT NULL,
  `billing_year` int(11) DEFAULT NULL,
  `status_lifecycle` enum('draft','submitted','pending_review','needs_correction','approved','rejected','cancelled','archived') DEFAULT 'submitted',
  `anomaly_flags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`anomaly_flags`)),
  `confidence_score` tinyint(3) UNSIGNED DEFAULT 100,
  `risk_level` enum('low','medium','high','critical') DEFAULT 'low',
  `rejection_reason_code` varchar(100) DEFAULT NULL,
  `rejection_severity` enum('minor','medium','major','critical') DEFAULT NULL,
  `corrected_reading` decimal(12,2) DEFAULT NULL,
  `corrected_by` int(11) DEFAULT NULL,
  `corrected_at` datetime DEFAULT NULL,
  `version_number` int(11) DEFAULT 1,
  `priority` tinyint(4) DEFAULT 2,
  `reviewed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `electricity_meter_readings`
--

INSERT INTO `electricity_meter_readings` (`id`, `apartment_id`, `meter_number`, `previous_reading`, `current_reading`, `price_per_kwh`, `consumption`, `bill_amount`, `reading_date`, `created_at`, `photo_path`, `notes`, `submitted_by`, `approved_by`, `status`, `rejection_reason`, `submitted_at`, `approved_at`, `rejected_at`, `billing_month`, `billing_year`, `status_lifecycle`, `anomaly_flags`, `confidence_score`, `risk_level`, `rejection_reason_code`, `rejection_severity`, `corrected_reading`, `corrected_by`, `corrected_at`, `version_number`, `priority`, `reviewed_at`) VALUES
(7, 12, NULL, 1.00, 150.00, 500.00, 149.00, 74500.00, '2026-08-25', '2026-07-25 21:26:21', NULL, NULL, 5, NULL, 'Rejected', NULL, '2026-07-26 00:26:21', NULL, NULL, NULL, NULL, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(8, 12, NULL, 1.00, 160.00, 500.00, 159.00, 79500.00, '2026-08-25', '2026-07-26 20:49:05', NULL, NULL, 5, 1, 'Verified', NULL, '2026-07-26 23:49:05', NULL, NULL, NULL, NULL, 'approved', '[{\"code\":\"MISSING_IMAGE\",\"level\":\"medium\",\"title\":\"Missing Meter Photo\",\"message\":\"No meter photo was uploaded with this reading. Photo is required for verification.\",\"data\":[]},{\"code\":\"FIRST_READING\",\"level\":\"info\",\"title\":\"First Reading\",\"message\":\"No historical data available for comparison. This appears to be the first reading for this meter.\",\"data\":[]}]', 88, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, '2026-08-05 22:55:58'),
(9, 12, NULL, 160.00, 180.00, 500.00, 20.00, 10000.00, '2026-08-25', '2026-07-26 20:49:15', NULL, NULL, 5, 1, 'Verified', NULL, '2026-07-26 23:49:15', NULL, NULL, NULL, NULL, 'approved', '[{\"code\":\"MISSING_IMAGE\",\"level\":\"medium\",\"title\":\"Missing Meter Photo\",\"message\":\"No meter photo was uploaded with this reading. Photo is required for verification.\",\"data\":[]},{\"code\":\"FIRST_READING\",\"level\":\"info\",\"title\":\"First Reading\",\"message\":\"No historical data available for comparison. This appears to be the first reading for this meter.\",\"data\":[]}]', 88, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, '2026-08-05 22:56:01'),
(10, 13, NULL, 0.00, 450.00, 0.00, 450.00, 0.00, '2026-08-05', '2026-08-05 20:04:05', 'uploads/electricity-meters/1785960245_Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png', '', 5, 1, 'Verified', NULL, '2026-08-05 23:04:05', NULL, NULL, 8, 2026, 'approved', '[{\"code\":\"FIRST_READING\",\"level\":\"info\",\"title\":\"First Reading\",\"message\":\"No historical data available for comparison. This appears to be the first reading for this meter.\",\"data\":[]}]', 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, '2026-08-05 23:20:23'),
(11, 11, NULL, 0.00, 0.00, 0.00, 0.00, 150000.00, '2026-08-05', '2026-08-05 20:19:29', NULL, '', 5, 1, 'Verified', NULL, '2026-08-05 23:19:29', NULL, NULL, 8, 2026, 'approved', '[{\"code\":\"MISSING_IMAGE\",\"level\":\"medium\",\"title\":\"Missing Meter Photo\",\"message\":\"No meter photo was uploaded with this reading. Photo is required for verification.\",\"data\":[]},{\"code\":\"FIRST_READING\",\"level\":\"info\",\"title\":\"First Reading\",\"message\":\"No historical data available for comparison. This appears to be the first reading for this meter.\",\"data\":[]}]', 88, 'low', NULL, NULL, NULL, NULL, NULL, 1, 4, '2026-08-07 01:03:04'),
(12, 13, NULL, 450.00, 500.00, 500.00, 50.00, 25000.00, '2026-08-07', '2026-08-07 21:12:54', NULL, NULL, 1, 1, 'Verified', NULL, '2026-08-08 00:12:54', NULL, NULL, NULL, NULL, 'approved', '[{\"code\":\"MISSING_IMAGE\",\"level\":\"medium\",\"title\":\"Missing Meter Photo\",\"message\":\"No meter photo was uploaded with this reading. Photo is required for verification.\",\"data\":[]},{\"code\":\"LOW_CONSUMPTION\",\"level\":\"low\",\"title\":\"Very Low Consumption\",\"message\":\"Consumption (50 kWh) is 89% below the 3-month average (450 kWh).\",\"data\":{\"consumption\":50,\"avg_3m\":450,\"percent_below\":89}},{\"code\":\"POSSIBLE_DIGIT_ERROR\",\"level\":\"high\",\"title\":\"Possible Typing Error\",\"message\":\"Submitted reading (500) differs 44.444444444444% from the expected value (~900). Check for digit transposition.\",\"data\":{\"submitted\":500,\"expected\":900,\"diff_pct\":44.4}}]', 50, 'high', NULL, NULL, NULL, NULL, NULL, 1, 2, '2026-08-08 00:46:33'),
(13, 13, NULL, 500.00, 1500.00, 500.00, 1000.00, 500000.00, '2026-09-06', '2026-08-07 21:33:10', NULL, NULL, 1, 1, 'Verified', NULL, '2026-08-08 00:33:10', NULL, NULL, NULL, NULL, 'approved', '[{\"code\":\"MISSING_IMAGE\",\"level\":\"medium\",\"title\":\"Missing Meter Photo\",\"message\":\"No meter photo was uploaded with this reading. Photo is required for verification.\",\"data\":[]},{\"code\":\"HIGH_CONSUMPTION\",\"level\":\"medium\",\"title\":\"High Consumption\",\"message\":\"Consumption (1000 kWh) is 300% above the 3-month average (250 kWh). Threshold: 200%.\",\"data\":{\"consumption\":1000,\"avg_3m\":250,\"percent_above\":300,\"threshold\":200}},{\"code\":\"POSSIBLE_DIGIT_ERROR\",\"level\":\"high\",\"title\":\"Possible Typing Error\",\"message\":\"Submitted reading (1500) differs 100% from the expected value (~750). Check for digit transposition.\",\"data\":{\"submitted\":1500,\"expected\":750,\"diff_pct\":100}}]', 42, 'high', NULL, NULL, NULL, NULL, NULL, 1, 2, '2026-08-08 00:46:36'),
(99, 26, 'MTR-26', 1000.00, 1050.00, 0.20, 50.00, 15.00, '2026-04-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 4, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(100, 26, 'MTR-26', 1050.00, 1100.00, 0.20, 50.00, 15.00, '2026-05-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 5, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(101, 26, 'MTR-26', 1100.00, 1150.00, 0.20, 50.00, 15.00, '2026-06-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 6, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(102, 26, 'MTR-26', 1150.00, 1200.00, 0.20, 50.00, 15.00, '2026-07-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 7, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(103, 26, 'MTR-26', 1200.00, 1250.00, 0.20, 50.00, 15.00, '2026-08-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 8, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(104, 27, 'MTR-27', 2100.00, 2160.00, 0.20, 60.00, 17.00, '2026-04-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 4, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(105, 27, 'MTR-27', 2160.00, 2220.00, 0.20, 60.00, 17.00, '2026-05-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 5, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(106, 27, 'MTR-27', 2220.00, 2280.00, 0.20, 60.00, 17.00, '2026-06-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 6, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(107, 27, 'MTR-27', 2280.00, 2340.00, 0.20, 60.00, 17.00, '2026-07-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 7, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(108, 27, 'MTR-27', 2340.00, 2400.00, 0.20, 60.00, 17.00, '2026-08-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 8, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(109, 28, 'MTR-28', 800.00, 840.00, 0.20, 40.00, 13.00, '2026-04-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 4, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(110, 28, 'MTR-28', 840.00, 880.00, 0.20, 40.00, 13.00, '2026-05-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 5, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(111, 28, 'MTR-28', 880.00, 920.00, 0.20, 40.00, 13.00, '2026-06-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 6, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(112, 28, 'MTR-28', 920.00, 960.00, 0.20, 40.00, 13.00, '2026-07-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 7, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(113, 28, 'MTR-28', 960.00, 1000.00, 0.20, 40.00, 13.00, '2026-08-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 8, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(114, 29, 'MTR-29', 3000.00, 3080.00, 0.20, 80.00, 21.00, '2026-04-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 4, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(115, 29, 'MTR-29', 3080.00, 3160.00, 0.20, 80.00, 21.00, '2026-05-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 5, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(116, 29, 'MTR-29', 3160.00, 3240.00, 0.20, 80.00, 21.00, '2026-06-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 6, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(117, 29, 'MTR-29', 3240.00, 3320.00, 0.20, 80.00, 21.00, '2026-07-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 7, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(118, 29, 'MTR-29', 3320.00, 3400.00, 0.20, 80.00, 21.00, '2026-08-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 8, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(119, 30, 'MTR-30', 1500.00, 1540.00, 0.20, 40.00, 13.00, '2026-04-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 4, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(120, 30, 'MTR-30', 1540.00, 1580.00, 0.20, 40.00, 13.00, '2026-05-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 5, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(121, 30, 'MTR-30', 1580.00, 1620.00, 0.20, 40.00, 13.00, '2026-06-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 6, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(122, 30, 'MTR-30', 1620.00, 1660.00, 0.20, 40.00, 13.00, '2026-07-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 7, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL),
(123, 30, 'MTR-30', 1660.00, 1700.00, 0.20, 40.00, 13.00, '2026-08-21', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Approved', NULL, '2026-09-22 00:53:40', NULL, NULL, 8, 2026, 'submitted', NULL, 100, 'low', NULL, NULL, NULL, NULL, NULL, 1, 2, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `electricity_subscriptions`
--

CREATE TABLE `electricity_subscriptions` (
  `id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `type` enum('Meter','Fixed Monthly','Fixed Amp') DEFAULT 'Meter',
  `monthly_fee` decimal(10,2) NOT NULL DEFAULT 0.00,
  `amps` decimal(10,2) DEFAULT 0.00,
  `cost_per_amp` decimal(10,2) DEFAULT 0.00,
  `start_date` date NOT NULL,
  `end_date` date DEFAULT NULL,
  `status` enum('Active','Inactive','Paused','Suspended','Cancelled') DEFAULT 'Active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `next_billing_date` date DEFAULT NULL,
  `last_meter_reading` decimal(12,2) DEFAULT NULL,
  `price_per_kwh` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `electricity_subscriptions`
--

INSERT INTO `electricity_subscriptions` (`id`, `apartment_id`, `type`, `monthly_fee`, `amps`, `cost_per_amp`, `start_date`, `end_date`, `status`, `created_at`, `next_billing_date`, `last_meter_reading`, `price_per_kwh`) VALUES
(17, 11, 'Fixed Amp', 150000.00, 10.00, 15000.00, '2026-08-08', '2026-10-07', 'Active', '2026-07-25 21:13:22', '2026-10-07', 0.00, NULL),
(18, 12, 'Meter', 0.00, 0.00, 0.00, '2026-08-25', '2026-09-25', '', '2026-07-25 21:13:43', '2026-09-25', 180.00, 500.00),
(19, 13, 'Fixed Monthly', 250000.00, 5.00, 50000.00, '2026-09-07', '2026-10-06', 'Active', '2026-07-26 20:53:44', '2026-10-06', 0.00, 500.00),
(42, 26, 'Fixed Amp', 50.00, 10.00, 5.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', NULL, 0.00),
(43, 26, 'Meter', 0.00, 0.00, 0.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', 1250.00, 0.20),
(44, 27, 'Fixed Amp', 75.00, 15.00, 5.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', NULL, 0.00),
(45, 27, 'Meter', 0.00, 0.00, 0.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', 2400.00, 0.20),
(46, 28, 'Fixed Amp', 25.00, 5.00, 5.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', NULL, 0.00),
(47, 28, 'Meter', 0.00, 0.00, 0.00, '2026-04-21', '2027-04-21', 'Active', '2026-09-21 21:53:40', '2026-09-21', 1000.00, 0.20),
(48, 29, 'Fixed Amp', 100.00, 20.00, 5.00, '2026-04-21', '2027-04-21', '', '2026-09-21 21:53:40', '2026-09-21', NULL, 0.00),
(49, 29, 'Meter', 0.00, 0.00, 0.00, '2026-04-21', '2027-04-21', '', '2026-09-21 21:53:40', '2026-09-21', 3400.00, 0.20),
(50, 30, 'Fixed Amp', 50.00, 10.00, 5.00, '2026-04-21', '2027-04-21', '', '2026-09-21 21:53:40', '2026-09-21', NULL, 0.00),
(51, 30, 'Meter', 0.00, 0.00, 0.00, '2026-04-21', '2027-04-21', '', '2026-09-21 21:53:40', '2026-09-21', 1700.00, 0.20);

-- --------------------------------------------------------

--
-- Table structure for table `energy_alerts`
--

CREATE TABLE `energy_alerts` (
  `id` int(11) NOT NULL,
  `type` enum('Warning','Info','Danger') NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `energy_alerts`
--

INSERT INTO `energy_alerts` (`id`, `type`, `message`, `is_read`, `created_at`) VALUES
(1, 'Danger', 'Low fuel detected on Generator ID 1. Current fuel: 0.5 Liters.', 0, '2026-06-20 20:35:08');

-- --------------------------------------------------------

--
-- Table structure for table `enterprise_activity_log`
--

CREATE TABLE `enterprise_activity_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `role` varchar(50) DEFAULT NULL,
  `department` varchar(100) DEFAULT NULL,
  `building_id` int(11) DEFAULT NULL,
  `department_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `module` varchar(100) NOT NULL,
  `record_id` varchar(100) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('success','warning','error','info') NOT NULL DEFAULT 'success',
  `severity` enum('low','medium','high','critical') NOT NULL DEFAULT 'low',
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `enterprise_activity_log`
--

INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-17 01:21:53'),
(2, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-17 01:21:53'),
(3, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-17 01:48:47'),
(4, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-17 01:48:47'),
(5, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 01:12:40'),
(6, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 01:12:50'),
(7, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 01:12:54'),
(8, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 01:13:32'),
(9, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:41:47'),
(10, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:41:47'),
(11, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:42:11'),
(12, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:42:28'),
(13, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:42:28'),
(14, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:44:18'),
(15, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:44:21'),
(16, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:44:25'),
(17, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:44:30'),
(18, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:44:32'),
(19, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:45:09'),
(20, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:45:09'),
(21, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:45:16'),
(22, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:45:18'),
(23, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:46:25'),
(24, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:52:04'),
(25, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:52:04'),
(26, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:52:55'),
(27, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 22:52:55'),
(28, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:07:53'),
(29, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:07:53'),
(30, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:07:59'),
(31, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:09:29'),
(32, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:10:03'),
(33, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:40:21'),
(34, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-18 23:40:21'),
(35, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:11:03'),
(36, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:11:04'),
(37, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:11:44'),
(38, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:11:44'),
(39, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 00:29:49'),
(40, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 00:29:49'),
(41, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:31:30'),
(42, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:31:30'),
(43, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:33:09'),
(44, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:33:09'),
(45, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:36:57'),
(46, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-19 00:36:57'),
(47, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:42:49'),
(48, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:44:05'),
(49, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:39'),
(50, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:40'),
(51, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:42'),
(52, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:47'),
(53, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:49'),
(54, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:52'),
(55, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:53'),
(56, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:45:57'),
(57, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:46:04'),
(58, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:46:13'),
(59, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 21:46:52'),
(60, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:14:34'),
(61, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:14:36'),
(62, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:14:38'),
(63, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:17:41'),
(64, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:17:44'),
(65, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:17:45'),
(66, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:17:47'),
(67, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:18:10'),
(68, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:18:10'),
(69, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:20:36'),
(70, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:20:38'),
(71, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:21:00'),
(72, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:21:14'),
(73, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:21:15'),
(74, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:21:18'),
(75, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:21:27'),
(76, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:22:43'),
(77, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:02'),
(78, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:02'),
(79, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:26'),
(80, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:43'),
(81, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:49'),
(82, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:23:51'),
(83, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:24:23'),
(84, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:24:26'),
(85, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:24:35'),
(86, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:24:43'),
(87, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:10'),
(88, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:22'),
(89, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:38'),
(90, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:44'),
(91, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:57'),
(92, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:25:58'),
(93, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:31:47'),
(94, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:31:47'),
(95, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:36:58'),
(96, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:36:58'),
(97, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:38:10'),
(98, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:38:15'),
(99, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:38:18'),
(100, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:40:53'),
(101, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:40:57'),
(102, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:41:40'),
(103, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:41:44'),
(104, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:41:46'),
(105, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:41:48'),
(106, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:41:49'),
(107, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:42:56'),
(108, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:42:58'),
(109, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:43:00'),
(110, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:43:03'),
(111, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 22:43:04'),
(112, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:03:27'),
(113, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:03:27'),
(114, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:03:38'),
(115, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:03:53'),
(116, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:04:00'),
(117, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:04:20'),
(118, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:04:22'),
(119, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:04:24'),
(120, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:04:26'),
(121, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:08:31'),
(122, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:08:31'),
(123, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:14:03'),
(124, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:14:03'),
(125, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:21:05'),
(126, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:27:01'),
(127, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:27:01'),
(128, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:31:38'),
(129, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:31:38'),
(130, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:33:45'),
(131, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:33:45'),
(132, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:33:49'),
(133, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:33:49'),
(134, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-19 23:39:15'),
(135, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 00:22:53'),
(136, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:27:37'),
(137, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:27:37'),
(138, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:27:43'),
(139, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:27:53'),
(140, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:27:55'),
(141, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:00'),
(142, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:30'),
(143, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:34'),
(144, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:34'),
(145, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:38'),
(146, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:28:56'),
(147, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:36:43'),
(148, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:36:43'),
(149, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:36:45'),
(150, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:37:16'),
(151, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:37:55'),
(152, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:37:55'),
(153, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:38:00'),
(154, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:38:00'),
(155, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:44:01'),
(156, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-21 00:44:01'),
(157, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:57:44'),
(158, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:57:44'),
(159, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:58:02'),
(160, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:58:24'),
(161, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:58:28'),
(162, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:58:28'),
(163, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:58:35'),
(164, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 22:59:18'),
(165, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:03:38'),
(166, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:03:40'),
(167, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:03:46'),
(168, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:04:03'),
(169, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:04:04'),
(170, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:04:19'),
(171, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:04:21'),
(172, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:08:17'),
(173, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:08:17'),
(174, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:13:51'),
(175, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:13:51'),
(176, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:13:58'),
(177, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:14:02'),
(178, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:14:11'),
(179, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:14:14'),
(180, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:10');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(181, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:25'),
(182, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:25'),
(183, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:30'),
(184, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:33'),
(185, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:39'),
(186, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:40'),
(187, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:17:50'),
(188, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:45:22'),
(189, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:45:22'),
(190, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:45:26'),
(191, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:45:26'),
(192, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:47:28'),
(193, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:47:28'),
(194, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:51:29'),
(195, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:51:29'),
(196, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:51:53'),
(197, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:51:53'),
(198, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:20'),
(199, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:20'),
(200, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:33'),
(201, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:52'),
(202, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:54'),
(203, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:54'),
(204, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:54:58'),
(205, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:55:01'),
(206, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:55:06'),
(207, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:58:32'),
(208, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:58:32'),
(209, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:58:37'),
(210, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:58:45'),
(211, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-21 23:58:49'),
(212, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:00:13'),
(213, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:00:13'),
(214, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:00:17'),
(215, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:00:32'),
(216, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:01'),
(217, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:02'),
(218, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:28'),
(219, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:31'),
(220, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:42'),
(221, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:01:51'),
(222, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:02:05'),
(223, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:02:07'),
(224, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:32:48'),
(225, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:32:55'),
(226, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:32:57'),
(227, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:32:58'),
(228, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:33:49'),
(229, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:33:50'),
(230, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:38:56'),
(231, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:39:53'),
(232, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:11'),
(233, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:13'),
(234, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:15'),
(235, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:16'),
(236, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:27'),
(237, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:27'),
(238, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:32'),
(239, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:52'),
(240, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:56'),
(241, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:40:56'),
(242, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:41:32'),
(243, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:41:35'),
(244, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:41:37'),
(245, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:41:38'),
(246, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 00:42:56'),
(247, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:44:43'),
(248, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:44:43'),
(249, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:44:59'),
(250, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:45:00'),
(251, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:45:02'),
(252, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:45:07'),
(253, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:45:08'),
(254, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:45:44'),
(255, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:36'),
(256, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:36'),
(257, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:49'),
(258, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:50'),
(259, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:53'),
(260, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:48:54'),
(261, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 22:50:04'),
(262, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:01:08'),
(263, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:02:14'),
(264, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:03:27'),
(265, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:03:29'),
(266, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:03:30'),
(267, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:25:14'),
(268, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:25:16'),
(269, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:25:57'),
(270, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:25:59'),
(271, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:28:30'),
(272, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:28:34'),
(273, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:41:14'),
(274, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:41:16'),
(275, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:41:52'),
(276, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:08'),
(277, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:13'),
(278, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:16'),
(279, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:22'),
(280, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:35'),
(281, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:37'),
(282, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:42:39'),
(283, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:47:57'),
(284, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:47:57'),
(285, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:48:13'),
(286, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:48:15'),
(287, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:48:18'),
(288, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:10'),
(289, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:12'),
(290, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:37'),
(291, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:38'),
(292, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:46'),
(293, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:49:50'),
(294, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:52:11'),
(295, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:53:51'),
(296, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:54:00'),
(297, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:54:00'),
(298, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:54:04'),
(299, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:54:39'),
(300, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-22 23:55:04'),
(301, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:07:16'),
(302, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:07:47'),
(303, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:08:47'),
(304, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:09:02'),
(305, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:09:53'),
(306, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:12'),
(307, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:37'),
(308, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:38'),
(309, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:44'),
(310, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:45'),
(311, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:47'),
(312, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:49'),
(313, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 00:12:51'),
(314, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:48:18'),
(315, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:48:18'),
(316, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:48:24'),
(317, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:48:42'),
(318, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:48:44'),
(319, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:49:36'),
(320, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:49:39'),
(321, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:49:45'),
(322, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:49:46'),
(323, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:49:50'),
(324, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:51:47'),
(325, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:51:58'),
(326, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:51:59'),
(327, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:53:48'),
(328, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:53:52'),
(329, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:53:55'),
(330, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:53:57'),
(331, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:54:02'),
(332, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:54:17'),
(333, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:54:22'),
(334, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:54:24'),
(335, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:55:58'),
(336, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:02'),
(337, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:07'),
(338, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:11'),
(339, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:13'),
(340, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:18'),
(341, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:56:20'),
(342, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:58:26'),
(343, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:58:28'),
(344, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:58:41'),
(345, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-26 23:59:01'),
(346, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:00:34'),
(347, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:00:37'),
(348, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:00:56'),
(349, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:00:57'),
(350, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:32'),
(351, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:32'),
(352, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:37'),
(353, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:40'),
(354, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:41'),
(355, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:43'),
(356, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:46'),
(357, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-27 00:01:47'),
(358, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:13'),
(359, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:16');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(360, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:19'),
(361, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:21'),
(362, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:36'),
(363, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:38'),
(364, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:41'),
(365, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:42'),
(366, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:03:47'),
(367, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:04:44'),
(368, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:04:46'),
(369, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:04:47'),
(370, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:15:35'),
(371, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:15:45'),
(372, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:16:16'),
(373, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-27 00:16:24'),
(374, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:05:08'),
(375, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:05:13'),
(376, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:05:16'),
(377, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:14:45'),
(378, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:14:45'),
(379, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:14:57'),
(380, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:14:58'),
(381, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:15:00'),
(382, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:15:05'),
(383, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:15:06'),
(384, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:15:07'),
(385, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:15:09'),
(386, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:16:15'),
(387, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:16:15'),
(388, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:16:35'),
(389, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:16:35'),
(390, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:16:42'),
(391, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:18:01'),
(392, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:24:07'),
(393, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:24:07'),
(394, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:25:02'),
(395, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:25:02'),
(396, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:22'),
(397, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:25'),
(398, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:27'),
(399, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:28'),
(400, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:29'),
(401, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:31'),
(402, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:43'),
(403, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:45'),
(404, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:46'),
(405, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:50'),
(406, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:52'),
(407, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:30:55'),
(408, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:32:50'),
(409, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:37:38'),
(410, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:37:44'),
(411, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:37:45'),
(412, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:38:38'),
(413, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:38:40'),
(414, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:38:42'),
(415, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:40:37'),
(416, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:40:39'),
(417, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:40:42'),
(418, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:48:08'),
(419, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-07-29 00:48:08'),
(420, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:48:17'),
(421, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:48:49'),
(422, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:53:40'),
(423, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:53:40'),
(424, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 00:53:49'),
(425, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:01:29'),
(426, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:01:29'),
(427, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:08'),
(428, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:08'),
(429, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:17'),
(430, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:17'),
(431, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:20'),
(432, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36 Edg/150.0.0.0', '2026-07-29 01:04:20'),
(433, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:01:03'),
(434, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:05:35'),
(435, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:05:35'),
(436, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:27'),
(437, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:32'),
(438, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:33'),
(439, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:36'),
(440, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:39'),
(441, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:43'),
(442, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:46'),
(443, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:48'),
(444, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:51'),
(445, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:06:53'),
(446, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:07:59'),
(447, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:08:04'),
(448, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:42'),
(449, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:42'),
(450, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:45'),
(451, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:47'),
(452, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:48'),
(453, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:49'),
(454, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:50'),
(455, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:51'),
(456, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:51'),
(457, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:52'),
(458, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:52'),
(459, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:10:54'),
(460, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:16'),
(461, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:16'),
(462, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:23'),
(463, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:43'),
(464, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:46'),
(465, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:47'),
(466, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:11:49'),
(467, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:12:00'),
(468, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:15:28'),
(469, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:15:39'),
(470, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:15:41'),
(471, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:15:44'),
(472, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:24:42'),
(473, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:24:42'),
(474, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:24:52'),
(475, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:25:23'),
(476, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:27:07'),
(477, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:27:07'),
(478, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:05'),
(479, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:05'),
(480, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:21'),
(481, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:23'),
(482, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:26'),
(483, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:28'),
(484, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:30'),
(485, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:31'),
(486, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:36'),
(487, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:39'),
(488, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:28:41'),
(489, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:21'),
(490, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:23'),
(491, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:24'),
(492, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:26'),
(493, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:35'),
(494, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:36'),
(495, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:37'),
(496, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:29:38'),
(497, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:31:58'),
(498, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:31:58'),
(499, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:32:00'),
(500, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:32:40'),
(501, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:32:42'),
(502, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:32:43'),
(503, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:32:48'),
(504, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:38:25'),
(505, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-03 23:38:25'),
(506, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:43:17'),
(507, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-03 23:43:17'),
(508, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:51:03'),
(509, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:51:03'),
(510, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:52:15'),
(511, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:03'),
(512, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:05'),
(513, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:06'),
(514, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:08'),
(515, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:11'),
(516, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:12'),
(517, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:53:58'),
(518, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:54:50'),
(519, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:54:50'),
(520, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:55:14'),
(521, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:55:19'),
(522, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:55:33'),
(523, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:55:39'),
(524, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:55:48'),
(525, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:56:07'),
(526, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:56:28'),
(527, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:57:57'),
(528, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:58:04'),
(529, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:58:36'),
(530, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:58:36'),
(531, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:58:36'),
(532, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:59:00'),
(533, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:59:00'),
(534, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:59:00'),
(535, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:59:15'),
(536, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-04 22:59:17'),
(537, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:59:42'),
(538, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 22:59:48'),
(539, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:01:13');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(540, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:01:41'),
(541, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:01:47'),
(542, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:02:23'),
(543, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:02:25'),
(544, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:21'),
(545, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:44'),
(546, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:45'),
(547, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:55'),
(548, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:58'),
(549, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:13:59'),
(550, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:14:00'),
(551, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:14:01'),
(552, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:14:02'),
(553, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:14:04'),
(554, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:21:35'),
(555, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:21:35'),
(556, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:28:41'),
(557, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:28:41'),
(558, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:02'),
(559, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:03'),
(560, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:05'),
(561, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:24'),
(562, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:26'),
(563, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:29:32'),
(564, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:30:11'),
(565, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:38:44'),
(566, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:38:44'),
(567, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:39:57'),
(568, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:40:01'),
(569, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:40:05'),
(570, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:40:43'),
(571, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:40:46'),
(572, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:54:14'),
(573, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-04 23:54:14'),
(574, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:03:26'),
(575, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:03:26'),
(576, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:22:07'),
(577, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:22:07'),
(578, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:22:24'),
(579, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:22:26'),
(580, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:08'),
(581, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:10'),
(582, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:12'),
(583, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:14'),
(584, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:15'),
(585, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:16'),
(586, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:19'),
(587, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:28:22'),
(588, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:35:33'),
(589, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:35:34'),
(590, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:35:35'),
(591, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:35:36'),
(592, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 00:35:37'),
(593, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:54:20'),
(594, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:54:20'),
(595, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:55:17'),
(596, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:05'),
(597, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:07'),
(598, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:21'),
(599, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:28'),
(600, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:33'),
(601, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 22:56:35'),
(602, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 22:57:17'),
(603, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 22:57:17'),
(604, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 22:57:26'),
(605, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 22:57:41'),
(606, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 22:57:44'),
(607, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:04:42'),
(608, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:04:46'),
(609, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:04:48'),
(610, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 23:12:51'),
(611, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 23:12:51'),
(612, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:20:02'),
(613, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:20:25'),
(614, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:20:28'),
(615, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:20:30'),
(616, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:21:03'),
(617, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:26:07'),
(618, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:27:04'),
(619, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:27:05'),
(620, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:27:08'),
(621, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:28:03'),
(622, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:28:16'),
(623, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:30:47'),
(624, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:31:31'),
(625, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:31:32'),
(626, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:31:34'),
(627, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:31:47'),
(628, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:31:53'),
(629, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:36:44'),
(630, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:37:26'),
(631, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:37:30'),
(632, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:37:53'),
(633, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:37:55'),
(634, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:37:59'),
(635, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:38:00'),
(636, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:38:01'),
(637, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:38:03'),
(638, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:39:50'),
(639, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:39:57'),
(640, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:40:01'),
(641, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:40:55'),
(642, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:40:57'),
(643, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:06'),
(644, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:09'),
(645, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:21'),
(646, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:21'),
(647, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:25'),
(648, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:27'),
(649, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:41:29'),
(650, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:44:54'),
(651, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:21'),
(652, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:22'),
(653, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:27'),
(654, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:29'),
(655, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:55'),
(656, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:58'),
(657, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:45:59'),
(658, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:46:18'),
(659, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:46:21'),
(660, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:46:23'),
(661, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:56:09'),
(662, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:56:14'),
(663, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:56:15'),
(664, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:56:17'),
(665, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:20'),
(666, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:21'),
(667, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:22'),
(668, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:22'),
(669, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:26'),
(670, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:28'),
(671, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:30'),
(672, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:33'),
(673, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:33'),
(674, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:34'),
(675, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:34'),
(676, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-05 23:59:36'),
(677, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 23:59:54'),
(678, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 23:59:58'),
(679, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-05 23:59:59'),
(680, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:00:04'),
(681, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:00:05'),
(682, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:00:06'),
(683, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:00:07'),
(684, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:00'),
(685, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:00'),
(686, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:27'),
(687, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:28'),
(688, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:39'),
(689, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:40'),
(690, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:41'),
(691, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:42'),
(692, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:43'),
(693, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:54'),
(694, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:56'),
(695, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:10:58'),
(696, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:12:01'),
(697, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:12:02'),
(698, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:32'),
(699, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:34'),
(700, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:35'),
(701, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:38'),
(702, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:40'),
(703, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:42'),
(704, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:49'),
(705, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:51'),
(706, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:12:53'),
(707, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:24:53'),
(708, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:24:53'),
(709, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:53:14'),
(710, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:53:14'),
(711, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:54:08'),
(712, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:54:24'),
(713, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:54:25'),
(714, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:08'),
(715, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:10'),
(716, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:13'),
(717, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:21'),
(718, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:21'),
(719, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:24');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(720, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:26'),
(721, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 00:55:30'),
(722, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:57:56'),
(723, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 00:57:56'),
(724, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 01:00:15'),
(725, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 01:00:23'),
(726, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 01:01:40'),
(727, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 01:01:40'),
(728, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:19:36'),
(729, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:20:08'),
(730, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:20:25'),
(731, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:20:39'),
(732, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:20:51'),
(733, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:21:18'),
(734, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:24:58'),
(735, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:24:58'),
(736, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:24:59'),
(737, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:25:00'),
(738, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-06 01:25:01'),
(739, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:16:27'),
(740, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:16:34'),
(741, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:16:36'),
(742, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:16:57'),
(743, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:16:59'),
(744, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:00'),
(745, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:01'),
(746, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:10'),
(747, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:40'),
(748, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:40'),
(749, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:49'),
(750, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:17:50'),
(751, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:29'),
(752, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:31'),
(753, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:42'),
(754, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:44'),
(755, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:45'),
(756, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:46'),
(757, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:47'),
(758, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:18:49'),
(759, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:09'),
(760, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:09'),
(761, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:09'),
(762, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:09'),
(763, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:18'),
(764, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:19'),
(765, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:21'),
(766, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:23'),
(767, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:31'),
(768, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:32'),
(769, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:33'),
(770, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:35'),
(771, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:38'),
(772, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:40'),
(773, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:41'),
(774, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:48'),
(775, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:52'),
(776, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:54'),
(777, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:56'),
(778, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:21:57'),
(779, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:43:34'),
(780, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:43:35'),
(781, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:43:37'),
(782, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:53:40'),
(783, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:53:40'),
(784, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:54:17'),
(785, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:16'),
(786, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:17'),
(787, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:18'),
(788, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:19'),
(789, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:20'),
(790, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:22'),
(791, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:24'),
(792, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-06 23:56:25'),
(793, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:03:36'),
(794, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:03:36'),
(795, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:06:29'),
(796, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:06:29'),
(797, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:12:09'),
(798, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:12:09'),
(799, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:12:18'),
(800, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:12:23'),
(801, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:13:56'),
(802, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:13:56'),
(803, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:14:34'),
(804, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:24'),
(805, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:24'),
(806, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:36'),
(807, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:38'),
(808, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:39'),
(809, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:15:43'),
(810, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:16:02'),
(811, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:16:04'),
(812, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:16:05'),
(813, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:16:21'),
(814, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:16:22'),
(815, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:17:23'),
(816, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:17:57'),
(817, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:17:59'),
(818, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:42'),
(819, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:42'),
(820, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:50'),
(821, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:52'),
(822, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:53'),
(823, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:54'),
(824, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:55'),
(825, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:23:57'),
(826, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:24:03'),
(827, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:24:04'),
(828, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:24:05'),
(829, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:24:07'),
(830, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:24:08'),
(831, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:44:10'),
(832, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 00:44:10'),
(833, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:44:19'),
(834, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:44:22'),
(835, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:44:35'),
(836, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:44:35'),
(837, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:05'),
(838, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:05'),
(839, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:28'),
(840, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:28'),
(841, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:28'),
(842, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:46'),
(843, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:46'),
(844, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:52'),
(845, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:48:59'),
(846, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:53:11'),
(847, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:53:11'),
(848, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:53:41'),
(849, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:53:41'),
(850, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:55:43'),
(851, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:55:43'),
(852, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:56:54'),
(853, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:56:59'),
(854, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:57:04'),
(855, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 00:57:07'),
(856, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:02:23'),
(857, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:02:23'),
(858, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:02:26'),
(859, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:38'),
(860, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:38'),
(861, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:44'),
(862, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:45'),
(863, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:47'),
(864, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:51'),
(865, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:52'),
(866, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:55'),
(867, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:57'),
(868, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:02:59'),
(869, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:00'),
(870, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:01'),
(871, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:06'),
(872, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:07'),
(873, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:09'),
(874, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:10'),
(875, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:12'),
(876, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:03:13'),
(877, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:03:51'),
(878, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:03:51'),
(879, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:03:53'),
(880, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:03:53'),
(881, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:04:57'),
(882, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:04:57'),
(883, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:05:14'),
(884, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:05:15'),
(885, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:05:15'),
(886, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:05:24'),
(887, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:47'),
(888, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:47'),
(889, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:53'),
(890, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:56'),
(891, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:57'),
(892, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:57'),
(893, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:06:58'),
(894, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:07:01'),
(895, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:10:37'),
(896, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:10:41'),
(897, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:12:49'),
(898, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:12:49'),
(899, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:14:48'),
(900, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:14:48');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(901, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:15:32'),
(902, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:15:39'),
(903, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:15:50'),
(904, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:15:50'),
(905, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:15:53'),
(906, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:16:08'),
(907, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:17:00'),
(908, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:17:00'),
(909, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:17:32'),
(910, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:17:56'),
(911, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:17:56'),
(912, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:18:02'),
(913, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:18:58'),
(914, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:18:58'),
(915, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:21:27'),
(916, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:21:27'),
(917, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 01:22:33'),
(918, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:22:58'),
(919, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:22:58'),
(920, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:23:06'),
(921, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:23:09'),
(922, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:23:11'),
(923, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:23:12'),
(924, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:23:23'),
(925, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:24:02'),
(926, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:24:18'),
(927, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:24:18'),
(928, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:24:36'),
(929, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:25:54'),
(930, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:26:05'),
(931, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:26:10'),
(932, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:26:12'),
(933, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:30:32'),
(934, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:30:32'),
(935, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:30:58'),
(936, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:30:58'),
(937, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:31:08'),
(938, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:31:33'),
(939, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:32:32'),
(940, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:33:06'),
(941, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:34:49'),
(942, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 01:34:49'),
(943, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:35:23'),
(944, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:35:23'),
(945, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:35:28'),
(946, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:35:29'),
(947, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:35:34'),
(948, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:36:20'),
(949, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:36:20'),
(950, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:36:28'),
(951, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:36:28'),
(952, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:17:57'),
(953, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:00'),
(954, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:01'),
(955, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:02'),
(956, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:03'),
(957, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:03'),
(958, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:05'),
(959, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:05'),
(960, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:06'),
(961, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:13'),
(962, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:38'),
(963, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:18:40'),
(964, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:20:49'),
(965, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:20:51'),
(966, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:20:52'),
(967, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:20:58'),
(968, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:20:59'),
(969, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:21:00'),
(970, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:26'),
(971, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:26'),
(972, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:26'),
(973, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:21:32'),
(974, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:47'),
(975, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:47'),
(976, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:47'),
(977, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:52'),
(978, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:53'),
(979, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:55'),
(980, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:56'),
(981, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:21:57'),
(982, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:00'),
(983, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:02'),
(984, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:03'),
(985, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:27'),
(986, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:30'),
(987, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:31'),
(988, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:33'),
(989, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:22:35'),
(990, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:23'),
(991, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:23'),
(992, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:29'),
(993, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:35'),
(994, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:39'),
(995, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:45'),
(996, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:50'),
(997, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:24:57'),
(998, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:25:01'),
(999, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:25:02'),
(1000, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:14'),
(1001, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:16'),
(1002, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:17'),
(1003, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:17'),
(1004, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:19'),
(1005, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:27:20'),
(1006, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:29:51'),
(1007, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:30:21'),
(1008, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:30:21'),
(1009, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:31:45'),
(1010, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:32:00'),
(1011, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:32:08'),
(1012, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:32:10'),
(1013, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:32:39'),
(1014, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:32:51'),
(1015, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:32:51'),
(1016, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:32:56'),
(1017, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:32:59'),
(1018, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:33:08'),
(1019, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:33:10'),
(1020, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:24'),
(1021, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:25'),
(1022, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:27'),
(1023, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:28'),
(1024, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:29'),
(1025, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:30'),
(1026, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:31'),
(1027, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:35:33'),
(1028, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:35:49'),
(1029, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:37:26'),
(1030, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:37:47'),
(1031, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:37:47'),
(1032, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:37:53'),
(1033, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:23'),
(1034, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:23'),
(1035, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:28'),
(1036, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:30'),
(1037, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:33'),
(1038, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:34'),
(1039, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:39'),
(1040, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:40'),
(1041, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:38:42'),
(1042, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:42:15'),
(1043, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:42:18'),
(1044, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 23:42:19'),
(1045, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:42:55'),
(1046, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:42:55'),
(1047, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:16'),
(1048, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:22'),
(1049, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:28'),
(1050, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:29'),
(1051, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:31'),
(1052, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:35'),
(1053, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:43:37'),
(1054, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:44:35'),
(1055, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:44:41'),
(1056, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:44:52'),
(1057, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:45:03'),
(1058, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:45:08'),
(1059, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:46:18'),
(1060, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:46:18'),
(1061, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:46:52'),
(1062, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:46:55'),
(1063, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:49:20'),
(1064, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:49:21'),
(1065, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:08'),
(1066, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:08'),
(1067, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:52'),
(1068, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:55'),
(1069, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:56'),
(1070, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:53:59'),
(1071, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:54:01'),
(1072, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:54:02'),
(1073, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:56:51'),
(1074, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:56:51'),
(1075, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:56:56'),
(1076, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:00'),
(1077, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:02'),
(1078, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:08'),
(1079, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:09'),
(1080, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:10'),
(1081, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:23'),
(1082, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-07 23:57:23');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1083, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:01:20'),
(1084, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:01:20'),
(1085, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:01:26'),
(1086, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:01:31'),
(1087, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:01:51'),
(1088, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:02:15'),
(1089, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:03'),
(1090, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:05'),
(1091, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:09'),
(1092, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:10'),
(1093, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:13'),
(1094, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:37'),
(1095, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:39'),
(1096, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:52'),
(1097, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:53'),
(1098, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:09:56'),
(1099, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:07'),
(1100, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:09'),
(1101, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:15'),
(1102, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:15'),
(1103, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:30'),
(1104, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:34'),
(1105, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:38'),
(1106, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:46'),
(1107, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:48'),
(1108, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:50'),
(1109, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:56'),
(1110, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:57'),
(1111, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:10:59'),
(1112, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:00'),
(1113, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:01'),
(1114, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:02'),
(1115, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:04'),
(1116, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:06'),
(1117, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:09'),
(1118, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:18'),
(1119, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:40'),
(1120, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:54'),
(1121, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:57'),
(1122, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:58'),
(1123, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:11:59'),
(1124, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:12:01'),
(1125, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:12:06'),
(1126, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:12:08'),
(1127, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:12:10'),
(1128, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:12:11'),
(1129, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:14:46'),
(1130, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:14:48'),
(1131, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:14:49'),
(1132, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:14:53'),
(1133, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:15:04'),
(1134, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:15:05'),
(1135, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:15:06'),
(1136, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:15:07'),
(1137, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:15:07'),
(1138, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:16:46'),
(1139, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:16:46'),
(1140, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:17:42'),
(1141, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:17:51'),
(1142, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:13'),
(1143, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:14'),
(1144, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:38'),
(1145, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:40'),
(1146, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:41'),
(1147, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:42'),
(1148, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:45'),
(1149, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:46'),
(1150, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:18:47'),
(1151, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:19:24'),
(1152, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:19:24'),
(1153, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:19:33'),
(1154, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:19:40'),
(1155, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:20:08'),
(1156, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:20:13'),
(1157, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:20:14'),
(1158, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:23:49'),
(1159, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:23:49'),
(1160, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:28:54'),
(1161, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:28:54'),
(1162, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:06'),
(1163, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:10'),
(1164, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:14'),
(1165, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:25'),
(1166, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:37'),
(1167, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:29:37'),
(1168, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:30:01'),
(1169, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:30:03'),
(1170, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:30:15'),
(1171, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:31:05'),
(1172, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:32:25'),
(1173, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:32:33'),
(1174, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:33:26'),
(1175, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:33:26'),
(1176, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:33:36'),
(1177, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:33:36'),
(1178, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:06'),
(1179, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:09'),
(1180, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:13'),
(1181, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:17'),
(1182, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:28'),
(1183, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:35:36'),
(1184, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:36:22'),
(1185, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:37:12'),
(1186, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:37:19'),
(1187, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:37:34'),
(1188, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:42:18'),
(1189, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:42:24'),
(1190, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:42:30'),
(1191, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:46:26'),
(1192, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:46:40'),
(1193, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:46:40'),
(1194, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:46:54'),
(1195, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:46:54'),
(1196, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:47:10'),
(1197, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:47:15'),
(1198, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:47:21'),
(1199, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:47:28'),
(1200, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:01'),
(1201, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:27'),
(1202, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:31'),
(1203, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:37'),
(1204, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:43'),
(1205, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:48'),
(1206, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:48:52'),
(1207, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:50:42'),
(1208, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:50:44'),
(1209, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:51:16'),
(1210, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:51:48'),
(1211, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:03'),
(1212, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:03'),
(1213, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:13'),
(1214, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:16'),
(1215, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:27'),
(1216, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:42'),
(1217, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:44'),
(1218, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:52:44'),
(1219, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:53:41'),
(1220, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:57:29'),
(1221, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:57:30'),
(1222, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:58:03'),
(1223, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:58:07'),
(1224, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:58:12'),
(1225, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 00:58:13'),
(1226, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 01:01:31'),
(1227, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 01:01:31'),
(1228, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 01:02:52'),
(1229, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2026-08-08 01:02:52'),
(1230, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 01:04:35'),
(1231, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 01:04:35'),
(1232, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:06'),
(1233, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:06'),
(1234, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:06'),
(1235, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:10'),
(1236, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:10'),
(1237, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:12'),
(1238, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:20'),
(1239, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:31:22'),
(1240, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:31:44'),
(1241, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:31:44'),
(1242, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:31:51'),
(1243, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:31:51'),
(1244, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:32:31'),
(1245, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:32:32'),
(1246, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:32:46'),
(1247, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:32:52'),
(1248, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:32:56'),
(1249, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:33:01'),
(1250, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:33:09'),
(1251, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:17'),
(1252, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:17'),
(1253, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:24'),
(1254, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:27'),
(1255, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:28'),
(1256, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:28'),
(1257, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:30'),
(1258, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:30'),
(1259, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:32'),
(1260, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:34'),
(1261, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:35'),
(1262, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:36'),
(1263, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:34:37'),
(1264, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:36:51'),
(1265, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:36:51'),
(1266, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:36:51'),
(1267, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:36:51');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1268, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:36:51'),
(1269, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:36:51'),
(1270, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:36:51'),
(1271, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:36:52'),
(1272, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:36:58'),
(1273, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:37:58'),
(1274, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:37:59'),
(1275, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:00'),
(1276, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:02'),
(1277, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:03'),
(1278, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:36'),
(1279, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:40'),
(1280, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:43'),
(1281, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:45'),
(1282, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:47'),
(1283, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:51'),
(1284, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-08 23:38:53'),
(1285, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:09'),
(1286, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:09'),
(1287, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:14'),
(1288, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:19'),
(1289, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:20'),
(1290, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:23'),
(1291, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:24'),
(1292, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:25'),
(1293, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:27'),
(1294, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:43:28'),
(1295, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:47:53'),
(1296, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:47:53'),
(1297, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-08 23:47:59'),
(1298, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:03:40'),
(1299, 2, 'milad', 'maintenance', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:03:40'),
(1300, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:04:34'),
(1301, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:04:34'),
(1302, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:04:37'),
(1303, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:04:38'),
(1304, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:21:59'),
(1305, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:21:59'),
(1306, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:22:26'),
(1307, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:22:26'),
(1308, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:22:52'),
(1309, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:22:52'),
(1310, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:22:54'),
(1311, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:22:54'),
(1312, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:26:36'),
(1313, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:26:36'),
(1314, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:26:36'),
(1315, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:26:36'),
(1316, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:26:36'),
(1317, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:26:36'),
(1318, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:26:36'),
(1319, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:27:15'),
(1320, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:27:15'),
(1321, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:27:15'),
(1322, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:31:55'),
(1323, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:35:30'),
(1324, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:35:30'),
(1325, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:38:05'),
(1326, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:38:05'),
(1327, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:38:08'),
(1328, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:38:08'),
(1329, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:38:10'),
(1330, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:38:10'),
(1331, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:46:06'),
(1332, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:46:06'),
(1333, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:46:10'),
(1334, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 00:46:10'),
(1335, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:52:35'),
(1336, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:52:35'),
(1337, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:57:03'),
(1338, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 00:57:03'),
(1339, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:01:07'),
(1340, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:01:07'),
(1341, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:01:07'),
(1342, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:01:07'),
(1343, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:14:37'),
(1344, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:14:38'),
(1345, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:21:08'),
(1346, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:21:08'),
(1347, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:21:48'),
(1348, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:21:48'),
(1349, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:21:48'),
(1350, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:22:07'),
(1351, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:23:23'),
(1352, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:23:23'),
(1353, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:24:27'),
(1354, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:24:28'),
(1355, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:24:29'),
(1356, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:24:30'),
(1357, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:31:45'),
(1358, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:31:45'),
(1359, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:31:47'),
(1360, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:31:47'),
(1361, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:36:20'),
(1362, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 01:36:20'),
(1363, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 01:37:45'),
(1364, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:02:44'),
(1365, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:02:44'),
(1366, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:03:05'),
(1367, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:03:07'),
(1368, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:03:45'),
(1369, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:03:54'),
(1370, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:36:49'),
(1371, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:36:49'),
(1372, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:37:11'),
(1373, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:37:11'),
(1374, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:37:12'),
(1375, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:37:12'),
(1376, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:44:32'),
(1377, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:44:32'),
(1378, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:44:36'),
(1379, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:46:34'),
(1380, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:46:38'),
(1381, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 02:49:14'),
(1382, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:56:34'),
(1383, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:56:35'),
(1384, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:56:37'),
(1385, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 02:59:49'),
(1386, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:01:11'),
(1387, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:01:25'),
(1388, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:03:22'),
(1389, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:04:38'),
(1390, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:04:38'),
(1391, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:04:42'),
(1392, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:12:16'),
(1393, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 03:12:53'),
(1394, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 22:30:09'),
(1395, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 22:30:09'),
(1396, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:39:43'),
(1397, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:39:59'),
(1398, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:40:01'),
(1399, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:40:05'),
(1400, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:40:12'),
(1401, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:42:40'),
(1402, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:42:41'),
(1403, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:42:43'),
(1404, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:42:59'),
(1405, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:02'),
(1406, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:03'),
(1407, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:06'),
(1408, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:07'),
(1409, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:11'),
(1410, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-09 23:43:46'),
(1411, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:33'),
(1412, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:33'),
(1413, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:37'),
(1414, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:43'),
(1415, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:52'),
(1416, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:56'),
(1417, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:44:59'),
(1418, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:45:02'),
(1419, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:45:04'),
(1420, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:45:09'),
(1421, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:57:43'),
(1422, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:57:43'),
(1423, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:57:47'),
(1424, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-09 23:57:47'),
(1425, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:02:45'),
(1426, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:02:45'),
(1427, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:02:58'),
(1428, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:03:01'),
(1429, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:03:07'),
(1430, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:03:15'),
(1431, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:49'),
(1432, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:51'),
(1433, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:51'),
(1434, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:54'),
(1435, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:54'),
(1436, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:05:57'),
(1437, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:06:00'),
(1438, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:14:24'),
(1439, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:14:24'),
(1440, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:14:49'),
(1441, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:14:52'),
(1442, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:17:14'),
(1443, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:17:47'),
(1444, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:17:55'),
(1445, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:17:56'),
(1446, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:18:00');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1447, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:25:15'),
(1448, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:25:27'),
(1449, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:25:29'),
(1450, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:26:25'),
(1451, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:29:12'),
(1452, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:29:14'),
(1453, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:29:16'),
(1454, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:30:26'),
(1455, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:31:14'),
(1456, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:31:52'),
(1457, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:31:55'),
(1458, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:31:55'),
(1459, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:31:57'),
(1460, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:32:03'),
(1461, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:33:05'),
(1462, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:33:07'),
(1463, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:34:20'),
(1464, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:34:21'),
(1465, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:34:28'),
(1466, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:34:28'),
(1467, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:48:51'),
(1468, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 00:48:51'),
(1469, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:55:18'),
(1470, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:55:21'),
(1471, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:55:37'),
(1472, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:55:39'),
(1473, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 00:59:40'),
(1474, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:33'),
(1475, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:33'),
(1476, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:35'),
(1477, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:37'),
(1478, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:40'),
(1479, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:10:42'),
(1480, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:11:57'),
(1481, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:13:51'),
(1482, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:13:51'),
(1483, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:13:53'),
(1484, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 01:15:41'),
(1485, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 01:16:07'),
(1486, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:17:46'),
(1487, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:17:49'),
(1488, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:17:49'),
(1489, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:17:51'),
(1490, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:23:12'),
(1491, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:23:13'),
(1492, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:23:24'),
(1493, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 01:23:37'),
(1494, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 01:23:38'),
(1495, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:26:09'),
(1496, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:26:33'),
(1497, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:26:34'),
(1498, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:26:34'),
(1499, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:29:12'),
(1500, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:29:12'),
(1501, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:30:33'),
(1502, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:30:38'),
(1503, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:30:40'),
(1504, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:34:50'),
(1505, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:34:54'),
(1506, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:35:09'),
(1507, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:35:14'),
(1508, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:35:54'),
(1509, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:46:53'),
(1510, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-10 01:46:53'),
(1511, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:42'),
(1512, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:42'),
(1513, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:48'),
(1514, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:51'),
(1515, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:53'),
(1516, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:57'),
(1517, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:32:59'),
(1518, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:33:00'),
(1519, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:33:10'),
(1520, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:33:13'),
(1521, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:34:41'),
(1522, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:34:58'),
(1523, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:24'),
(1524, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:26'),
(1525, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:27'),
(1526, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:27'),
(1527, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:30'),
(1528, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:32'),
(1529, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:47'),
(1530, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:35:49'),
(1531, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:45:30'),
(1532, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:45:36'),
(1533, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:45:42'),
(1534, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:45:43'),
(1535, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:45:48'),
(1536, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:58:00'),
(1537, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:58:00'),
(1538, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:41'),
(1539, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:42'),
(1540, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:43'),
(1541, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:45'),
(1542, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:47'),
(1543, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:48'),
(1544, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-10 23:59:50'),
(1545, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:00:11'),
(1546, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:00:13'),
(1547, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:00:14'),
(1548, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:00:19'),
(1549, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:00:22'),
(1550, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:01:08'),
(1551, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:01:13'),
(1552, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:02:15'),
(1553, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:02:17'),
(1554, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:02:27'),
(1555, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:33'),
(1556, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:39'),
(1557, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:41'),
(1558, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:41'),
(1559, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:44'),
(1560, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:07:50'),
(1561, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:08:34'),
(1562, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:08:35'),
(1563, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:08:38'),
(1564, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:08:41'),
(1565, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 00:11:56'),
(1566, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 01:32:44'),
(1567, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-11 01:32:44'),
(1568, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:23:33'),
(1569, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:23:36'),
(1570, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:48:12'),
(1571, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:48:12'),
(1572, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:49:05'),
(1573, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:49:09'),
(1574, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:49:19'),
(1575, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-14 01:49:25'),
(1576, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:18'),
(1577, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:24'),
(1578, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:27'),
(1579, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:29'),
(1580, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:40'),
(1581, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:51'),
(1582, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:30:54'),
(1583, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:31:04'),
(1584, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:31:05'),
(1585, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:31:06'),
(1586, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:32:42'),
(1587, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 17:32:43'),
(1588, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 17:58:35'),
(1589, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 17:59:05'),
(1590, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 17:59:05'),
(1591, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 18:17:03'),
(1592, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 18:17:03'),
(1593, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:18:56'),
(1594, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:18:56'),
(1595, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 18:25:08'),
(1596, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-16 18:25:08'),
(1597, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:31:56'),
(1598, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:31:56'),
(1599, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:32:12'),
(1600, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:32:24'),
(1601, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:32:29'),
(1602, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:32:29'),
(1603, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:47:55'),
(1604, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:47:55'),
(1605, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:53:56'),
(1606, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:53:56'),
(1607, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:59:20'),
(1608, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 18:59:21'),
(1609, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:01:31'),
(1610, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:01:31'),
(1611, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:04:29'),
(1612, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:04:29'),
(1613, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:06:39'),
(1614, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:06:39'),
(1615, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:09:01'),
(1616, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:09:01'),
(1617, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:14:28'),
(1618, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:14:28'),
(1619, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:26:26'),
(1620, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:26:26'),
(1621, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:33:25'),
(1622, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:33:25'),
(1623, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:42:22'),
(1624, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:42:23'),
(1625, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:59:42'),
(1626, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 19:59:42');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1627, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 20:04:56'),
(1628, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 20:04:56'),
(1629, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 20:05:55'),
(1630, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 20:05:58'),
(1631, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 23:55:53'),
(1632, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 23:56:09'),
(1633, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-16 23:56:11'),
(1634, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:00:28'),
(1635, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:03:46'),
(1636, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:04:25'),
(1637, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:04:29'),
(1638, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:04:30'),
(1639, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:05:48'),
(1640, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:05:49'),
(1641, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:09:11'),
(1642, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 00:09:11'),
(1643, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:58:36'),
(1644, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:59:04'),
(1645, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:59:11'),
(1646, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:59:15'),
(1647, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:59:48'),
(1648, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 22:59:50'),
(1649, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:08:42'),
(1650, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:08:42'),
(1651, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:15:58'),
(1652, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:15:58'),
(1653, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:16:30'),
(1654, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:20:42'),
(1655, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:24:35'),
(1656, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:24:35'),
(1657, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:28:53'),
(1658, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:28:53'),
(1659, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:38:38'),
(1660, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-17 23:38:38'),
(1661, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:13:01'),
(1662, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:13:01'),
(1663, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:15:29'),
(1664, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:15:29'),
(1665, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:29:15'),
(1666, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:29:15'),
(1667, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:34:25'),
(1668, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:41:06'),
(1669, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:57:29'),
(1670, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 00:57:29'),
(1671, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:19:37'),
(1672, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:19:37'),
(1673, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:34:26'),
(1674, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:34:26'),
(1675, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:36:50'),
(1676, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:36:50'),
(1677, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:38:56'),
(1678, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:38:56'),
(1679, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:38:57'),
(1680, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:38:57'),
(1681, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:39:06'),
(1682, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:39:08'),
(1683, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:57:20'),
(1684, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 01:57:21'),
(1685, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:10:50'),
(1686, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:10:50'),
(1687, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:16:09'),
(1688, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:16:09'),
(1689, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:19:33'),
(1690, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:19:33'),
(1691, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:19:51'),
(1692, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:19:51'),
(1693, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:28'),
(1694, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:28'),
(1695, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:28'),
(1696, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:28'),
(1697, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:34'),
(1698, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 02:21:37'),
(1699, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-18 23:45:39'),
(1700, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:03:41'),
(1701, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:03:45'),
(1702, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:19:03'),
(1703, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:19:03'),
(1704, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:30:44'),
(1705, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:30:45'),
(1706, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:35:42'),
(1707, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:35:42'),
(1708, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:35:45'),
(1709, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:35:52'),
(1710, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 00:35:55'),
(1711, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:18:48'),
(1712, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:19:46'),
(1713, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:19:48'),
(1714, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:19:50'),
(1715, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:26:04'),
(1716, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:26:04'),
(1717, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:26:04'),
(1718, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:26:04'),
(1719, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:40:06'),
(1720, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:40:06'),
(1721, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:42:44'),
(1722, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:42:44'),
(1723, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:43:37'),
(1724, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:43:48'),
(1725, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:43:50'),
(1726, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:48:02'),
(1727, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-19 23:48:02'),
(1728, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:02:06'),
(1729, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:02:06'),
(1730, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:04:28'),
(1731, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:04:28'),
(1732, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:41'),
(1733, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:41'),
(1734, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:41'),
(1735, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:41'),
(1736, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:50'),
(1737, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:16:52'),
(1738, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:21:08'),
(1739, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:21:08'),
(1740, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:27:41'),
(1741, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:27:41'),
(1742, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:27:46'),
(1743, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:27:48'),
(1744, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:38'),
(1745, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:38'),
(1746, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:38'),
(1747, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:38'),
(1748, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:48'),
(1749, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:34:50'),
(1750, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:35:52'),
(1751, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:35:57'),
(1752, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:35:59'),
(1753, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:38:29'),
(1754, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:38:29'),
(1755, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:38:41'),
(1756, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-20 00:38:41'),
(1757, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:14:44'),
(1758, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:18:34'),
(1759, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:18:37'),
(1760, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:18:39'),
(1761, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:18:40'),
(1762, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:35:40'),
(1763, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-22 23:35:40'),
(1764, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:03:37'),
(1765, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:03:39'),
(1766, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:08:26'),
(1767, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:12:50'),
(1768, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:12:50'),
(1769, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:13:04'),
(1770, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:13:07'),
(1771, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:13:09'),
(1772, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:18:45'),
(1773, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:18:45'),
(1774, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:29:38'),
(1775, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:29:38'),
(1776, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:30:02'),
(1777, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:30:02'),
(1778, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:30:11'),
(1779, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:30:11'),
(1780, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:35:56'),
(1781, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:35:56'),
(1782, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:40:11'),
(1783, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 01:40:11'),
(1784, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:34:39'),
(1785, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:34:39'),
(1786, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:34:48'),
(1787, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:35:40'),
(1788, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:35:42'),
(1789, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:35:43'),
(1790, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:35:56'),
(1791, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:35:59'),
(1792, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:36:00'),
(1793, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:36:02'),
(1794, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:37:49'),
(1795, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:37:51'),
(1796, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:37:53'),
(1797, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:37:55'),
(1798, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:38:00'),
(1799, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:48:40'),
(1800, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:48:40'),
(1801, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:57:21'),
(1802, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 21:57:21'),
(1803, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:09:43'),
(1804, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:09:56');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1805, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:09:58'),
(1806, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:10:18'),
(1807, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:10:22'),
(1808, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:10:24'),
(1809, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:10:28'),
(1810, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:13'),
(1811, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:14'),
(1812, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:16'),
(1813, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:19'),
(1814, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:26'),
(1815, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:30'),
(1816, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:35'),
(1817, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:37'),
(1818, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:13:38'),
(1819, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:14:49'),
(1820, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:26:05'),
(1821, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-23 22:26:05'),
(1822, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:13:13'),
(1823, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:13:18'),
(1824, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:13:21'),
(1825, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:42:19'),
(1826, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:42:19'),
(1827, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:50:43'),
(1828, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:50:43'),
(1829, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:50:43'),
(1830, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:50:43'),
(1831, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:50:59'),
(1832, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:01'),
(1833, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:04'),
(1834, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:43'),
(1835, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:43'),
(1836, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:43'),
(1837, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 00:51:43'),
(1838, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 01:01:23'),
(1839, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 01:01:23'),
(1840, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 22:45:50'),
(1841, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 22:45:50'),
(1842, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 22:45:57'),
(1843, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 22:45:59'),
(1844, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 23:38:17'),
(1845, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 23:38:17'),
(1846, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 23:46:29'),
(1847, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-24 23:46:29'),
(1848, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:43:29'),
(1849, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:43:46'),
(1850, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:43:46'),
(1851, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:43:55'),
(1852, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:44:07'),
(1853, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:44:10'),
(1854, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:44:25'),
(1855, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 22:44:25'),
(1856, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:45:33'),
(1857, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:45:35'),
(1858, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:45:50'),
(1859, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:46:15'),
(1860, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:46:16'),
(1861, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:46:18'),
(1862, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 22:47:12'),
(1863, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:01:53'),
(1864, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:01:53'),
(1865, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:02:33'),
(1866, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:03:16'),
(1867, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:03:36'),
(1868, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:03:36'),
(1869, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:07:52'),
(1870, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:07:52'),
(1871, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:09:11'),
(1872, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:09:11'),
(1873, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:28:19'),
(1874, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:28:20'),
(1875, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:46:42'),
(1876, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:46:45'),
(1877, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:48:39'),
(1878, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:48:48'),
(1879, 5, 'hassan haded', 'agent', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-08-27 23:48:48'),
(1880, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:55:11'),
(1881, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:55:13'),
(1882, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:55:17'),
(1883, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-27 23:55:18'),
(1884, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-28 00:10:42'),
(1885, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-28 00:10:42'),
(1886, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-28 00:11:52'),
(1887, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-28 00:11:53'),
(1888, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-28 00:11:54'),
(1889, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:04:22'),
(1890, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:04:35'),
(1891, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:04:40'),
(1892, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:06:45'),
(1893, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:06:45'),
(1894, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:07:43'),
(1895, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:16:14'),
(1896, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:16:14'),
(1897, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:18:46'),
(1898, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:20:02'),
(1899, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:20:02'),
(1900, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:22:26'),
(1901, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-17 23:22:29'),
(1902, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:09:07'),
(1903, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:14:50'),
(1904, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:14:52'),
(1905, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:14:54'),
(1906, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:03'),
(1907, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:05'),
(1908, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:11'),
(1909, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:13'),
(1910, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:14'),
(1911, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:34'),
(1912, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:35'),
(1913, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:15:47'),
(1914, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:16:11'),
(1915, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:16:12'),
(1916, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:16:14'),
(1917, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:17:40'),
(1918, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:17:40'),
(1919, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:17:42'),
(1920, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:17:42'),
(1921, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:25:49'),
(1922, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:25:53'),
(1923, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:25:59'),
(1924, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:26:01'),
(1925, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:26:42'),
(1926, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:26:49'),
(1927, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:26:57'),
(1928, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:26:57'),
(1929, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:26'),
(1930, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:28'),
(1931, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:30'),
(1932, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:33'),
(1933, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:34'),
(1934, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:27:36'),
(1935, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:30:01'),
(1936, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:30:55'),
(1937, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:21'),
(1938, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:30'),
(1939, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:31'),
(1940, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:35'),
(1941, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:37'),
(1942, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:40'),
(1943, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:31:41'),
(1944, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:32:34'),
(1945, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:32:37'),
(1946, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:32:38'),
(1947, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:44:37'),
(1948, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:44:37'),
(1949, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:45:10'),
(1950, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:45:12'),
(1951, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:45:14'),
(1952, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:45:19'),
(1953, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:53:50'),
(1954, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:53:50'),
(1955, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:54:06'),
(1956, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:54:09'),
(1957, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:54:10'),
(1958, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:54:12'),
(1959, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:54:13'),
(1960, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:55:29'),
(1961, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:55:58'),
(1962, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:56:06'),
(1963, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:56:06'),
(1964, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-21 23:56:07'),
(1965, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:04:23'),
(1966, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:08:12'),
(1967, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:08:13'),
(1968, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:08:22'),
(1969, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:08:39'),
(1970, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:08:42'),
(1971, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:33'),
(1972, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:35'),
(1973, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:37'),
(1974, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:41'),
(1975, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:42'),
(1976, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:44'),
(1977, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:47'),
(1978, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:50'),
(1979, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:51'),
(1980, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:09:53'),
(1981, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:26'),
(1982, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:26'),
(1983, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:27');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(1984, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:27'),
(1985, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:31'),
(1986, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:36'),
(1987, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:37'),
(1988, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:50:47'),
(1989, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:53:55'),
(1990, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:53:55'),
(1991, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:00'),
(1992, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:11'),
(1993, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:14'),
(1994, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:25'),
(1995, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:34'),
(1996, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:38'),
(1997, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:39'),
(1998, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:45'),
(1999, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:54:48'),
(2000, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:08'),
(2001, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:11'),
(2002, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:14'),
(2003, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:15'),
(2004, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:17'),
(2005, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:25'),
(2006, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:53'),
(2007, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:57'),
(2008, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:56:58'),
(2009, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:57:03'),
(2010, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:57:20'),
(2011, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:37'),
(2012, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:43'),
(2013, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:45'),
(2014, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:47'),
(2015, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:48'),
(2016, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:50'),
(2017, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 00:59:51'),
(2018, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 01:00:12'),
(2019, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 01:00:14'),
(2020, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-22 01:03:19'),
(2021, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:07'),
(2022, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:24'),
(2023, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:26'),
(2024, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:28'),
(2025, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:33'),
(2026, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:34'),
(2027, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:39'),
(2028, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:41'),
(2029, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:42'),
(2030, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:27:44'),
(2031, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:12'),
(2032, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:14'),
(2033, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:16'),
(2034, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:20'),
(2035, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:21'),
(2036, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:23'),
(2037, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:26'),
(2038, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:28:27'),
(2039, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:31:14'),
(2040, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:18'),
(2041, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:18'),
(2042, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:20'),
(2043, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:21'),
(2044, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:22'),
(2045, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:23'),
(2046, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:24'),
(2047, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:24'),
(2048, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:25'),
(2049, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:25'),
(2050, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:32:28'),
(2051, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:08'),
(2052, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:08'),
(2053, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:10'),
(2054, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:11'),
(2055, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:43'),
(2056, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:43'),
(2057, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:50'),
(2058, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:41:50'),
(2059, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:03'),
(2060, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:03'),
(2061, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:07'),
(2062, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:08'),
(2063, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:12'),
(2064, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:17'),
(2065, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:18'),
(2066, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:19'),
(2067, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:23'),
(2068, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:34'),
(2069, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:42:35'),
(2070, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:43:41'),
(2071, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:44:13'),
(2072, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:44:16'),
(2073, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-22 23:44:19'),
(2074, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:22'),
(2075, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:22'),
(2076, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:28'),
(2077, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:28'),
(2078, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:42'),
(2079, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:42'),
(2080, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:45'),
(2081, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:45'),
(2082, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:04:47'),
(2083, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:05:09'),
(2084, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:05:10'),
(2085, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:05:14'),
(2086, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:05:26'),
(2087, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:06:36'),
(2088, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:06:36'),
(2089, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:16:58'),
(2090, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:16:58'),
(2091, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:16:58'),
(2092, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:16:58'),
(2093, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:17:07'),
(2094, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:17:07'),
(2095, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:17:15'),
(2096, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:17:15'),
(2097, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:18:27'),
(2098, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:18:29'),
(2099, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:18:30'),
(2100, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:18:35'),
(2101, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:06'),
(2102, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:09'),
(2103, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:10'),
(2104, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:11'),
(2105, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:14'),
(2106, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:23'),
(2107, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:19:23'),
(2108, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:23:04'),
(2109, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:23:14'),
(2110, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 00:23:14'),
(2111, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:02:20'),
(2112, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:02:20'),
(2113, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:03:34'),
(2114, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:03:36'),
(2115, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:03:37'),
(2116, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:13:38'),
(2117, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:13:38'),
(2118, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 01:13:50'),
(2119, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:01:14'),
(2120, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:01:14'),
(2121, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:01:16'),
(2122, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:01:16'),
(2123, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:16:29'),
(2124, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:16:29'),
(2125, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:16:56'),
(2126, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:16:56'),
(2127, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:17:24'),
(2128, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:17:24'),
(2129, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:17:27'),
(2130, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:17:36'),
(2131, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:18:01'),
(2132, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:18:27'),
(2133, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:18:30'),
(2134, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 02:18:33'),
(2135, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:38:22'),
(2136, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:38:37'),
(2137, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:38:42'),
(2138, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:38:43'),
(2139, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:38:59'),
(2140, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:43:55'),
(2141, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:43:55'),
(2142, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:14'),
(2143, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:14'),
(2144, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:47'),
(2145, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:47'),
(2146, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:56'),
(2147, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:58'),
(2148, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:44:59'),
(2149, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:48:47'),
(2150, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:48:47'),
(2151, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:48:56'),
(2152, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:48:56'),
(2153, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:51:36'),
(2154, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:51:36'),
(2155, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:55:02'),
(2156, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:55:02'),
(2157, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:55:02'),
(2158, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:55:02'),
(2159, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:55:48'),
(2160, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:55:48'),
(2161, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:06'),
(2162, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:06'),
(2163, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:10'),
(2164, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:12'),
(2165, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:13'),
(2166, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:57:15'),
(2167, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 22:57:15');
INSERT INTO `enterprise_activity_log` (`id`, `user_id`, `user_name`, `role`, `department`, `building_id`, `department_id`, `action`, `module`, `record_id`, `description`, `status`, `severity`, `ip_address`, `device_info`, `created_at`) VALUES
(2168, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:17'),
(2169, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:18'),
(2170, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:19'),
(2171, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:57:23'),
(2172, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:59:21'),
(2173, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:59:22'),
(2174, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:59:23'),
(2175, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 22:59:26'),
(2176, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:34:19'),
(2177, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:34:19'),
(2178, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:34:41'),
(2179, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:34:41'),
(2180, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:34:47'),
(2181, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:35:28'),
(2182, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:35:28'),
(2183, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:43:25'),
(2184, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:43:25'),
(2185, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:44:06'),
(2186, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:44:06'),
(2187, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:45:20'),
(2188, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:45:20'),
(2189, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:48:33'),
(2190, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:48:33'),
(2191, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:49:19'),
(2192, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:52:20'),
(2193, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:52:39'),
(2194, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:58:16'),
(2195, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:58:16'),
(2196, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:58:20'),
(2197, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-23 23:58:20'),
(2198, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 23:58:56'),
(2199, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 23:58:58'),
(2200, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 23:59:00'),
(2201, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-23 23:59:02'),
(2202, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:02:13'),
(2203, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:02:13'),
(2204, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:02:20'),
(2205, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:02:20'),
(2206, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:03:45'),
(2207, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:03:45'),
(2208, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:03:53'),
(2209, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:03:53'),
(2210, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:04:03'),
(2211, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:04:03'),
(2212, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-24 00:04:30'),
(2213, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-24 00:04:32'),
(2214, 4, 'ali yazbekk', 'tenant', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-09-24 00:04:33'),
(2215, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 00:05:51'),
(2216, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:39:23'),
(2217, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:39:23'),
(2218, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:19'),
(2219, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:36'),
(2220, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:39'),
(2221, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:41'),
(2222, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:44'),
(2223, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:40:53'),
(2224, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:42:16'),
(2225, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:42:18'),
(2226, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:42:34'),
(2227, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:42:36'),
(2228, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:42:38'),
(2229, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:44:03'),
(2230, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:50:02'),
(2231, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:50:02'),
(2232, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:15'),
(2233, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:15'),
(2234, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:28'),
(2235, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:30'),
(2236, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:32'),
(2237, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:57:39'),
(2238, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:58:30'),
(2239, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:58:31'),
(2240, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 01:58:42'),
(2241, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-24 23:16:39'),
(2242, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:07:17'),
(2243, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:07:24'),
(2244, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:07:27'),
(2245, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:23:48'),
(2246, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:23:54'),
(2247, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:23:56'),
(2248, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-25 23:36:38'),
(2249, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:00:18'),
(2250, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:00:51'),
(2251, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:04:22'),
(2252, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:04:39'),
(2253, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:04:51'),
(2254, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:04:53'),
(2255, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:05:17'),
(2256, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:52:30'),
(2257, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:52:31'),
(2258, 1, 'Admin', 'admin', 'General', NULL, NULL, 'navigation', 'system', NULL, 'Opened PMS System', 'success', 'low', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-09-26 01:52:33');

-- --------------------------------------------------------

--
-- Table structure for table `enterprise_settings`
--

CREATE TABLE `enterprise_settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `value` text DEFAULT NULL,
  `label` varchar(200) DEFAULT NULL,
  `category` varchar(100) NOT NULL DEFAULT 'general',
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `enterprise_settings`
--

INSERT INTO `enterprise_settings` (`id`, `setting_key`, `value`, `label`, `category`, `updated_at`) VALUES
(1, 'daily_scan_enabled', '1', 'Enable Daily Audit Scan', 'scheduler', '2026-07-17 00:14:13'),
(2, 'daily_scan_time', '02:00', 'Daily Scan Time', 'scheduler', '2026-07-17 00:14:13'),
(3, 'weekly_scan_day', '0', 'Weekly Scan Day (0=Sunday)', 'scheduler', '2026-07-17 00:14:13'),
(4, 'notify_critical_count', '3', 'Notify when critical >= N', 'notifications', '2026-07-17 00:14:13'),
(5, 'notify_unresolved_days', '30', 'Alert if unresolved > N days', 'notifications', '2026-07-17 00:14:13'),
(6, 'sla_critical_hours', '24', 'SLA hours for critical issues', 'sla', '2026-07-17 00:14:13'),
(7, 'sla_warning_hours', '72', 'SLA hours for warning issues', 'sla', '2026-07-17 00:14:13'),
(8, 'auto_fix_enabled', '0', 'Enable Auto-Fix Suggestions', 'autofix', '2026-07-17 00:14:13'),
(9, 'duplicate_scan_enabled', '1', 'Enable Duplicate Detection', 'integrity', '2026-07-19 22:15:02'),
(10, 'financial_scan_enabled', '1', 'Enable Financial Audit', 'integrity', '2026-07-17 00:14:13');

-- --------------------------------------------------------

--
-- Table structure for table `estimation_rates`
--

CREATE TABLE `estimation_rates` (
  `id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `default_price` decimal(10,2) NOT NULL DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `estimation_rates`
--

INSERT INTO `estimation_rates` (`id`, `item_name`, `category`, `unit`, `default_price`) VALUES
(1, 'Concrete', 'Material', 'm3', 120.00),
(2, 'Steel', 'Material', 'Ton', 800.00),
(3, 'Cement', 'Material', 'Bag', 12.00),
(4, 'Blocks', 'Material', 'Piece', 0.50),
(5, 'Sand', 'Material', 'Ton', 30.00),
(6, 'Tiles', 'Material', 'm2', 15.00),
(7, 'Paint', 'Material', 'Liter', 4.00),
(8, 'Electrical Cables', 'Material', 'Meter', 1.50),
(9, 'Water Pipes', 'Material', 'Meter', 3.00),
(10, 'Doors', 'Material', 'Piece', 150.00),
(11, 'Windows', 'Material', 'Piece', 200.00),
(12, 'Mason', 'Labor', 'Mandays', 25.00),
(13, 'Electrician', 'Labor', 'Mandays', 35.00),
(14, 'Plumber', 'Labor', 'Mandays', 35.00),
(15, 'Painter', 'Labor', 'Mandays', 20.00),
(16, 'Supervisor', 'Labor', 'Mandays', 50.00),
(17, 'Excavator', 'Equipment', 'Days', 200.00),
(18, 'Crane', 'Equipment', 'Days', 150.00),
(19, 'Concrete Mixer', 'Equipment', 'Days', 100.00),
(20, 'Generator', 'Equipment', 'Days', 50.00),
(21, 'Permits & Fees', 'Other', 'Lump Sum', 15000.00);

-- --------------------------------------------------------

--
-- Table structure for table `expenses`
--

CREATE TABLE `expenses` (
  `id` int(11) NOT NULL,
  `category` varchar(50) NOT NULL,
  `entity_type` varchar(50) DEFAULT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `notes` text DEFAULT NULL,
  `reference_id` varchar(100) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expense_type` enum('Materials','Labor','Equipment','Transport','Fuel','Miscellaneous','General') DEFAULT 'General'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `expenses`
--

INSERT INTO `expenses` (`id`, `category`, `entity_type`, `entity_id`, `amount`, `date`, `notes`, `reference_id`, `user_id`, `created_at`, `expense_type`) VALUES
(1, 'Apartment', 'Apartment', 1, 1190.00, '2026-06-19', 'Materials from Warehouse', 'INV-1781902512-9439', 1, '2026-06-19 20:55:12', 'General'),
(2, 'Construction', 'Construction', 1, 7140.00, '2026-06-19', 'Materials from Warehouse', 'INV-1781902616-4163', 1, '2026-06-19 20:56:56', 'General'),
(3, 'Apartment', 'Apartment', 1, 71.40, '2026-06-19', 'Materials from Warehouse', 'INV-1781903570-8612', 1, '2026-06-19 21:12:50', 'General'),
(4, 'Apartment', 'Apartment', 6, 1225.70, '2026-06-19', 'Materials from Warehouse', 'INV-1781903822-4868', 1, '2026-06-19 21:17:02', 'General'),
(5, 'Apartment', 'Apartment', 1, 1405.39, '2026-06-19', 'Materials from Warehouse', 'INV-1781904595-7582', 1, '2026-06-19 21:29:55', 'General'),
(6, 'Apartment', 'Apartment', 1, 1547.00, '2026-06-19', 'Materials from Warehouse', 'INV-1781904632-8994', 1, '2026-06-19 21:30:32', 'General'),
(7, 'Apartment', 'Apartment', 1, 978.18, '2026-06-19', 'Materials from Warehouse', 'INV-1781905028-5268', 1, '2026-06-19 21:37:08', 'General'),
(8, 'Construction', 'Construction', 1, 798.49, '2026-06-22', 'Materials from Warehouse', 'INV-1782160216-8903', 1, '2026-06-22 20:30:16', 'General'),
(9, 'Construction', 'Construction', 1, 680680.00, '2026-06-22', 'Materials from Warehouse', 'INV-1782160427-8674', 1, '2026-06-22 20:33:47', 'General'),
(10, 'Construction Materials', 'construction', 0, 1500000.00, '2026-06-28', NULL, 'PO-20260628-3607', 1, '2026-06-28 18:01:43', 'Materials'),
(11, 'Construction Materials', 'construction', 2, 7000000.00, '2026-06-28', NULL, 'PO-20260628-4295', 1, '2026-06-28 18:07:33', 'Materials'),
(12, 'Construction Materials', 'construction', 2, 68454500.00, '2026-06-28', NULL, 'PO-20260628-4295', 1, '2026-06-28 18:07:44', 'Materials'),
(13, 'Construction Materials', 'construction', 2, 1000.00, '2026-06-28', NULL, 'PO-20260628-5618', 1, '2026-06-28 18:20:56', 'Materials'),
(14, 'Apartment', 'Apartment', 1, 10643.36, '2026-07-01', 'Materials from Warehouse', 'INV-1782937981-2261', 1, '2026-07-01 20:33:01', 'General');

-- --------------------------------------------------------

--
-- Table structure for table `field_agent_assignments`
--

CREATE TABLE `field_agent_assignments` (
  `id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `apartment_id` int(11) DEFAULT NULL,
  `active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `field_agent_tasks`
--

CREATE TABLE `field_agent_tasks` (
  `id` int(11) NOT NULL,
  `agent_id` int(11) NOT NULL,
  `type` enum('Generator','Apartment') NOT NULL,
  `building_id` int(11) NOT NULL,
  `apartment_id` int(11) DEFAULT NULL,
  `reading_id` int(11) DEFAULT NULL,
  `due_date` date NOT NULL,
  `priority` enum('Low','Normal','High','Urgent') DEFAULT 'Normal',
  `status` enum('Pending','Submitted','Approved','Rejected','Overdue','Cancelled') DEFAULT 'Pending',
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `field_permissions`
--

CREATE TABLE `field_permissions` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `entity` varchar(100) NOT NULL COMMENT 'tenants|apartments|contracts|workshops|...',
  `field_name` varchar(150) NOT NULL,
  `field_label` varchar(200) DEFAULT NULL,
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `is_editable` tinyint(1) NOT NULL DEFAULT 1,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `financial_activity_log`
--

CREATE TABLE `financial_activity_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `role` varchar(50) DEFAULT NULL,
  `building_id` int(11) DEFAULT NULL,
  `action` varchar(100) NOT NULL COMMENT 'invoice_created, payment_approved, rent_collected',
  `module` varchar(100) NOT NULL,
  `record_id` varchar(100) DEFAULT NULL,
  `amount` decimal(15,2) DEFAULT NULL,
  `currency` varchar(10) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `status` enum('success','warning','error','info') NOT NULL DEFAULT 'success',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `financial_audit_issues`
--

CREATE TABLE `financial_audit_issues` (
  `id` int(11) NOT NULL,
  `table_name` varchar(100) NOT NULL,
  `record_id` int(11) NOT NULL,
  `issue_type` varchar(100) NOT NULL COMMENT 'negative_payment|paid_exceeds_invoice|duplicate_payment|missing_transaction|...',
  `severity` enum('critical','warning','info') NOT NULL DEFAULT 'critical',
  `expected_value` decimal(15,2) DEFAULT NULL,
  `actual_value` decimal(15,2) DEFAULT NULL,
  `description` text NOT NULL,
  `status` enum('open','investigating','resolved','false_positive') NOT NULL DEFAULT 'open',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `financial_audit_issues`
--

INSERT INTO `financial_audit_issues` (`id`, `table_name`, `record_id`, `issue_type`, `severity`, `expected_value`, `actual_value`, `description`, `status`, `created_at`, `updated_at`) VALUES
(3, 'contracts', 6, 'missing_rent_profile', 'warning', NULL, NULL, 'Active contract #6 has no rent profile attached', 'resolved', '2026-07-17 01:10:47', '2026-07-18 01:14:18'),
(4, 'contracts', 11, 'missing_rent_profile', 'warning', NULL, NULL, 'Active contract #11 has no rent profile attached', 'resolved', '2026-07-17 01:10:47', '2026-07-18 01:14:19');

-- --------------------------------------------------------

--
-- Table structure for table `financial_transactions`
--

CREATE TABLE `financial_transactions` (
  `id` int(11) NOT NULL,
  `transaction_type` enum('electricity_invoice','subscription_invoice','generator_invoice','fuel_purchase','manual') NOT NULL,
  `module` varchar(100) DEFAULT NULL,
  `apartment_id` int(11) DEFAULT NULL,
  `building_id` int(11) DEFAULT NULL,
  `source_reading_id` int(11) DEFAULT NULL,
  `source_reading_type` varchar(100) DEFAULT NULL,
  `approval_log_id` int(11) DEFAULT NULL,
  `amount` decimal(10,2) DEFAULT 0.00,
  `invoice_id` int(11) DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `financial_transactions`
--

INSERT INTO `financial_transactions` (`id`, `transaction_type`, `module`, `apartment_id`, `building_id`, `source_reading_id`, `source_reading_type`, `approval_log_id`, `amount`, `invoice_id`, `created_by`, `notes`, `created_at`) VALUES
(1, 'generator_invoice', 'generator', NULL, NULL, 23, 'generator', NULL, 0.00, NULL, 1, NULL, '2026-08-04 21:05:52'),
(2, 'electricity_invoice', 'electricity', 12, 5, 8, 'electricity', NULL, 79500.00, NULL, 1, NULL, '2026-08-05 19:55:58'),
(3, 'electricity_invoice', 'electricity', 12, 5, 9, 'electricity', NULL, 10000.00, NULL, 1, NULL, '2026-08-05 19:56:01'),
(4, 'electricity_invoice', 'electricity', 13, 5, 10, 'electricity', NULL, 0.00, NULL, 1, NULL, '2026-08-05 20:20:23'),
(5, 'electricity_invoice', 'electricity', 11, 5, 11, 'electricity', NULL, 150000.00, NULL, 1, NULL, '2026-08-06 22:03:04'),
(6, 'subscription_invoice', 'electricity', 11, NULL, 2, 'subscription', NULL, 150000.00, 22, 1, NULL, '2026-08-07 21:20:02'),
(7, 'electricity_invoice', 'electricity', 13, 5, 12, 'electricity', NULL, 25000.00, NULL, 1, NULL, '2026-08-07 21:46:33'),
(8, 'electricity_invoice', 'electricity', 13, 5, 13, 'electricity', NULL, 500000.00, NULL, 1, NULL, '2026-08-07 21:46:36'),
(9, 'subscription_invoice', 'electricity', 13, NULL, 3, 'subscription', NULL, 250000.00, 24, 5, NULL, '2026-08-07 21:46:51'),
(10, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 5000.00, 19, 5, 'Agent collected electricity payment', '2026-08-08 23:32:19'),
(11, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 1000.00, 19, 5, 'Agent collected electricity payment', '2026-08-08 23:38:08'),
(12, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 2000.00, 19, 5, 'Agent collected electricity payment', '2026-08-08 23:42:48'),
(13, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 2000.00, 19, 5, 'Agent collected electricity payment', '2026-08-08 23:43:19'),
(14, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 1000.00, 18, 5, 'Agent collected electricity payment', '2026-08-08 23:44:03'),
(15, 'subscription_invoice', NULL, NULL, NULL, NULL, NULL, NULL, 78500.00, 18, 5, 'Agent collected electricity payment', '2026-08-08 23:45:06'),
(16, 'generator_invoice', 'generator', NULL, NULL, 24, 'generator', NULL, 0.00, NULL, 1, NULL, '2026-08-09 21:31:48'),
(17, 'generator_invoice', 'generator', NULL, NULL, 25, 'generator', NULL, 0.00, NULL, 1, NULL, '2026-08-16 14:30:46');

-- --------------------------------------------------------

--
-- Table structure for table `fuel_movements`
--

CREATE TABLE `fuel_movements` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `type` enum('Refill','Transfer_In','Transfer_Out','Adjustment','Emergency','Manual_Correction') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `cost_per_liter` decimal(10,2) DEFAULT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `date` datetime NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `receipt_path` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('Active','Voided') DEFAULT 'Active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `fuel_movements`
--

INSERT INTO `fuel_movements` (`id`, `generator_id`, `type`, `amount`, `cost_per_liter`, `supplier_id`, `date`, `user_id`, `notes`, `receipt_path`, `created_at`, `status`) VALUES
(4, 13, 'Refill', 0.00, 0.00, NULL, '2026-08-23 00:00:00', 1, ' [VOIDED]', NULL, '2026-08-23 21:34:41', 'Voided'),
(5, 13, 'Refill', 0.00, 0.00, NULL, '2026-08-23 00:00:00', 1, ' [VOIDED]', NULL, '2026-08-23 21:42:01', 'Voided'),
(6, 13, 'Refill', 0.00, 850.00, NULL, '2026-08-23 00:00:00', 1, NULL, NULL, '2026-08-23 21:42:30', 'Active');

-- --------------------------------------------------------

--
-- Table structure for table `generators`
--

CREATE TABLE `generators` (
  `id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `brand` varchar(255) DEFAULT NULL,
  `model` varchar(255) DEFAULT NULL,
  `serial_number` varchar(255) DEFAULT NULL,
  `capacity_kva` decimal(10,2) DEFAULT NULL,
  `fuel_capacity` decimal(10,2) NOT NULL DEFAULT 0.00,
  `current_fuel` decimal(10,2) NOT NULL DEFAULT 0.00,
  `initial_meter_reading` decimal(10,2) DEFAULT 0.00,
  `baseline_fuel_per_hour` decimal(10,2) DEFAULT 0.00,
  `price_per_kw` decimal(10,2) DEFAULT 0.00,
  `spare_fuel` decimal(10,2) NOT NULL DEFAULT 0.00,
  `purchase_date` date DEFAULT NULL,
  `status` enum('Running','Maintenance','Offline') DEFAULT 'Offline',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expected_fuel_consumption_per_hour` decimal(10,2) DEFAULT NULL,
  `expected_fuel_consumption_per_kwh` decimal(10,2) DEFAULT NULL,
  `maintenance_interval_hours` decimal(10,2) DEFAULT 250.00,
  `min_fuel_level_alert` decimal(10,2) DEFAULT 100.00,
  `normal_operating_thresholds` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`normal_operating_thresholds`)),
  `alert_thresholds` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`alert_thresholds`)),
  `efficiency_score` int(11) DEFAULT 100,
  `reliability_score` int(11) DEFAULT 100,
  `maintenance_score` int(11) DEFAULT 100,
  `fuel_accuracy_score` int(11) DEFAULT 100,
  `risk_score` int(11) DEFAULT 0,
  `health_score` int(11) DEFAULT 100,
  `last_maintenance_hours` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `generators`
--

INSERT INTO `generators` (`id`, `building_id`, `name`, `brand`, `model`, `serial_number`, `capacity_kva`, `fuel_capacity`, `current_fuel`, `initial_meter_reading`, `baseline_fuel_per_hour`, `price_per_kw`, `spare_fuel`, `purchase_date`, `status`, `notes`, `created_at`, `expected_fuel_consumption_per_hour`, `expected_fuel_consumption_per_kwh`, `maintenance_interval_hours`, `min_fuel_level_alert`, `normal_operating_thresholds`, `alert_thresholds`, `efficiency_score`, `reliability_score`, `maintenance_score`, `fuel_accuracy_score`, `risk_score`, `health_score`, `last_maintenance_hours`) VALUES
(12, 5, 'Galaxy Main Gen', 'Caterpillar', 'C32', NULL, 500.00, 1000.00, 640.00, 0.00, 0.00, 0.00, 0.00, NULL, 'Running', NULL, '2026-08-17 20:19:04', 10.00, NULL, 250.00, 100.00, NULL, NULL, 100, 100, 100, 0, 33, 67, 1122.00),
(13, 6, 'CORNISHE', NULL, '150 KVA Industrial', '4554546', 150.00, 2000.00, 836.00, 1917.69, 0.00, 0.00, 0.00, NULL, 'Offline', NULL, '2026-07-31 21:43:07', 8.00, 0.00, 250.00, 100.00, NULL, NULL, 100, 100, 100, 66, 11, 89, 1917.69);

-- --------------------------------------------------------

--
-- Table structure for table `generator_ai_profiles`
--

CREATE TABLE `generator_ai_profiles` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `normal_consumption_pattern` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`normal_consumption_pattern`)),
  `seasonal_patterns` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`seasonal_patterns`)),
  `high_load_periods` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`high_load_periods`)),
  `low_load_periods` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`low_load_periods`)),
  `aging_factor` decimal(5,4) DEFAULT 1.0000,
  `last_analyzed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `generator_ai_summaries`
--

CREATE TABLE `generator_ai_summaries` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL,
  `daily_summary` text NOT NULL,
  `weekly_summary` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `generator_ai_summaries`
--

INSERT INTO `generator_ai_summaries` (`id`, `date`, `daily_summary`, `weekly_summary`, `created_at`) VALUES
(1, '2026-06-23', 'Good morning. Today there are 1 generators requiring attention:\n\n• CORNISHE Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator: N/A\n', '2026-06-23 20:00:59'),
(4, '2026-06-28', 'Good morning. Today there are 1 generators requiring attention:\n\n• CORNISHE Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 10017 Hours\n• Highest Consumption Generator: CORNISHE\n• Lowest Efficiency Generator: N/A\n', '2026-06-28 15:13:01'),
(17, '2026-06-29', 'Good morning. All generators are operating normally. No immediate attention is required.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 11004 Hours\n• Highest Consumption Generator: CORNISHE\n• Lowest Efficiency Generator: N/A\n', '2026-06-29 20:02:57'),
(18, '2026-06-30', 'Good morning. All generators are operating normally. No immediate attention is required.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 11004 Hours\n• Highest Consumption Generator: CORNISHE\n• Lowest Efficiency Generator: N/A\n', '2026-06-30 21:35:31'),
(25, '2026-07-01', 'Good morning. Today there are 2 generators requiring attention:\n\n• CORNISHE Generator: No reading entered yesterday.\n• scad Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 11004 Hours\n• Highest Consumption Generator: CORNISHE\n• Lowest Efficiency Generator: N/A\n', '2026-07-01 20:25:17'),
(26, '2026-07-15', 'Good morning. Today there are 2 generators requiring attention:\n\n• CORNISHE Generator: No reading entered yesterday.\n• scad Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5 Hours\n• Highest Consumption Generator: scad\n• Lowest Efficiency Generator: N/A\n', '2026-07-15 19:51:20'),
(27, '2026-07-25', 'Good morning. All generators are operating normally. No immediate attention is required.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator: N/A\n', '2026-07-25 21:08:47'),
(28, '2026-07-26', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator: N/A\n', '2026-07-26 20:49:36'),
(30, '2026-08-03', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5151 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-03 20:15:41'),
(33, '2026-08-04', 'Good morning. All generators are operating normally. No immediate attention is required.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5151 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-04 19:56:28'),
(37, '2026-08-05', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5151 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-05 21:54:24'),
(38, '2026-08-06', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5151 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-06 20:21:40'),
(40, '2026-08-07', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5151 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-07 20:44:52'),
(45, '2026-08-10', 'Good morning. Today there are 1 generators requiring attention:\n\n• ةنةن Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 5197 Hours\n• Highest Consumption Generator: ةنةن\n• Lowest Efficiency Generator: N/A\n', '2026-08-10 20:35:26'),
(46, '2026-08-16', 'Good morning. Today there are 1 generators requiring attention:\n\n• Main Alpha Generator Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator: N/A\n', '2026-08-16 14:30:54'),
(56, '2026-08-17', 'Good morning. Today there are 1 generators requiring attention:\n\n• Main Alpha Generator Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 1550 Hours\n• Highest Consumption Generator: Main Alpha Generator\n• Lowest Efficiency Generator: N/A\n', '2026-08-17 19:59:15'),
(60, '2026-08-27', 'Good morning. Today there are 2 generators requiring attention:\n\n• Galaxy Main Gen Generator: No reading entered yesterday.\n• CORNISHE Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 80 Liters\n• Total Estimated Cost: 34000 CFA\n• Total Operating Hours: -1937 Hours\n• Highest Consumption Generator: CORNISHE\n• Lowest Efficiency Generator (Highest L/hr): CORNISHE\n', '2026-08-27 19:45:33'),
(61, '2026-09-17', 'Good morning. Today there are 2 generators requiring attention:\n\n• Galaxy Main Gen Generator: No reading entered yesterday.\n• CORNISHE Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator (Highest L/hr): N/A\n', '2026-09-17 20:04:40'),
(64, '2026-09-22', 'Good morning. Today there are 2 generators requiring attention:\n\n• Galaxy Main Gen Generator: No reading entered yesterday.\n• CORNISHE Generator: No reading entered yesterday.', 'Weekly Generator Report:\n\n• Total Fuel Consumed: 0 Liters\n• Total Estimated Cost: 0 CFA\n• Total Operating Hours: 0 Hours\n• Highest Consumption Generator: N/A\n• Lowest Efficiency Generator (Highest L/hr): N/A\n', '2026-09-22 21:04:42');

-- --------------------------------------------------------

--
-- Table structure for table `generator_alerts`
--

CREATE TABLE `generator_alerts` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `report_id` int(11) DEFAULT NULL,
  `alert_type` varchar(100) NOT NULL,
  `message` text NOT NULL,
  `severity` enum('Warning','Critical','Info') NOT NULL DEFAULT 'Warning',
  `status` enum('Unread','Read','Resolved') DEFAULT 'Unread',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `probabilities` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`probabilities`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `generator_alerts`
--

INSERT INTO `generator_alerts` (`id`, `generator_id`, `report_id`, `alert_type`, `message`, `severity`, `status`, `created_at`, `probabilities`) VALUES
(5, 12, 44, 'Consumption Anomaly', 'Critical Alert: Consumed 100L less than expected.', 'Critical', 'Unread', '2026-08-17 21:30:01', '{\"Data_Entry\":60,\"Meter_Manipulation\":30,\"Mechanical\":10}');

-- --------------------------------------------------------

--
-- Table structure for table `generator_analysis_archived`
--

CREATE TABLE `generator_analysis_archived` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `reading_date` date NOT NULL,
  `expected_fuel` decimal(10,2) DEFAULT NULL,
  `actual_fuel` decimal(10,2) DEFAULT NULL,
  `fuel_difference` decimal(10,2) DEFAULT NULL,
  `efficiency` decimal(10,2) DEFAULT NULL,
  `health_score` int(11) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `generator_daily_reports`
--

CREATE TABLE `generator_daily_reports` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `fuel_added` decimal(10,2) NOT NULL DEFAULT 0.00,
  `expected_fuel_used` decimal(10,2) DEFAULT 0.00,
  `cost_per_liter` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fuel_remaining` decimal(10,2) NOT NULL DEFAULT 0.00,
  `spare_remaining` decimal(10,2) NOT NULL DEFAULT 0.00,
  `running_hours` decimal(10,2) NOT NULL DEFAULT 0.00,
  `meter_hours` decimal(10,2) DEFAULT 0.00,
  `kwh_produced` decimal(10,2) NOT NULL DEFAULT 0.00,
  `notes` text DEFAULT NULL,
  `discrepancy_reason` text DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `submitted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `previous_kwh` decimal(10,2) DEFAULT NULL,
  `current_kwh` decimal(10,2) DEFAULT NULL,
  `efficiency_score` decimal(10,2) DEFAULT NULL,
  `alert_level` enum('Normal','Warning','Critical') DEFAULT 'Normal',
  `load_percentage` decimal(5,2) DEFAULT NULL,
  `outages_count` int(11) DEFAULT 0,
  `expected_fuel_consumption` decimal(10,2) DEFAULT NULL,
  `actual_fuel_consumption` decimal(10,2) DEFAULT NULL,
  `fuel_consumption_per_hour` decimal(10,2) DEFAULT NULL,
  `fuel_consumption_per_kwh` decimal(10,2) DEFAULT NULL,
  `cost_of_electricity` decimal(10,2) DEFAULT NULL,
  `fuel_variance` decimal(10,2) DEFAULT NULL,
  `estimated_days_empty` decimal(10,2) DEFAULT NULL,
  `photo_meter_path` varchar(255) DEFAULT NULL,
  `actual_fuel_remaining` decimal(10,2) DEFAULT NULL,
  `estimated_fuel_remaining` decimal(10,2) DEFAULT NULL,
  `estimated_fuel_used` decimal(10,2) DEFAULT NULL,
  `actual_fuel_used` decimal(10,2) DEFAULT NULL,
  `fuel_difference` decimal(10,2) DEFAULT NULL,
  `status` enum('Pending Verification','Verified','Flagged','Rejected') DEFAULT 'Pending Verification',
  `previous_meter_hours` decimal(10,2) DEFAULT 0.00,
  `current_meter_hours` decimal(10,2) DEFAULT 0.00,
  `liters_per_hour` decimal(10,2) DEFAULT 0.00,
  `liters_per_kwh` decimal(10,2) DEFAULT 0.00,
  `rejection_reason` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT current_timestamp(),
  `approved_at` datetime DEFAULT NULL,
  `rejected_at` datetime DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `fuel_photo_path` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `generator_daily_reports`
--

INSERT INTO `generator_daily_reports` (`id`, `generator_id`, `date`, `fuel_added`, `expected_fuel_used`, `cost_per_liter`, `fuel_remaining`, `spare_remaining`, `running_hours`, `meter_hours`, `kwh_produced`, `notes`, `discrepancy_reason`, `photo_path`, `submitted_by`, `created_at`, `previous_kwh`, `current_kwh`, `efficiency_score`, `alert_level`, `load_percentage`, `outages_count`, `expected_fuel_consumption`, `actual_fuel_consumption`, `fuel_consumption_per_hour`, `fuel_consumption_per_kwh`, `cost_of_electricity`, `fuel_variance`, `estimated_days_empty`, `photo_meter_path`, `actual_fuel_remaining`, `estimated_fuel_remaining`, `estimated_fuel_used`, `actual_fuel_used`, `fuel_difference`, `status`, `previous_meter_hours`, `current_meter_hours`, `liters_per_hour`, `liters_per_kwh`, `rejection_reason`, `submitted_at`, `approved_at`, `rejected_at`, `approved_by`, `fuel_photo_path`) VALUES
(1, 13, '2026-08-27', 0.00, 0.00, 0.00, 836.00, 0.00, 16.30, 1966.50, 0.00, '', NULL, NULL, 5, '2026-08-27 19:44:54', 1966.50, 1966.50, NULL, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'uploads/generator-readings/1787862426_meter_Screenshot 2025-08-20 211344.png', NULL, NULL, NULL, NULL, NULL, '', 0.00, 1966.50, 0.00, 0.00, 'incorrect_reading', '2026-08-27 23:27:06', NULL, '2026-08-27 23:03:29', NULL, NULL),
(3, 12, '2026-08-27', 0.00, 0.00, 0.00, 600.00, 0.00, 1144.00, 0.00, 0.00, '', NULL, NULL, 5, '2026-08-27 20:48:09', 1144.00, 0.00, NULL, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'uploads/generator-readings/1787864170_meter_Screenshot 2025-08-21 210922.png', NULL, NULL, NULL, NULL, NULL, 'Pending Verification', 0.00, 1144.00, 0.00, 0.00, 'incorrect_reading', '2026-08-27 23:56:10', NULL, '2026-08-27 23:48:44', NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `generator_daily_reports_archived`
--

CREATE TABLE `generator_daily_reports_archived` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `date` date NOT NULL,
  `fuel_added` decimal(10,2) NOT NULL DEFAULT 0.00,
  `expected_fuel_used` decimal(10,2) DEFAULT 0.00,
  `cost_per_liter` decimal(10,2) NOT NULL DEFAULT 0.00,
  `fuel_remaining` decimal(10,2) NOT NULL DEFAULT 0.00,
  `spare_remaining` decimal(10,2) NOT NULL DEFAULT 0.00,
  `running_hours` decimal(10,2) NOT NULL DEFAULT 0.00,
  `meter_hours` decimal(10,2) DEFAULT 0.00,
  `kwh_produced` decimal(10,2) NOT NULL DEFAULT 0.00,
  `notes` text DEFAULT NULL,
  `discrepancy_reason` text DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `submitted_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `previous_kwh` decimal(10,2) DEFAULT NULL,
  `current_kwh` decimal(10,2) DEFAULT NULL,
  `efficiency_score` decimal(10,2) DEFAULT NULL,
  `alert_level` enum('Normal','Warning','Critical') DEFAULT 'Normal',
  `load_percentage` decimal(5,2) DEFAULT NULL,
  `outages_count` int(11) DEFAULT 0,
  `expected_fuel_consumption` decimal(10,2) DEFAULT NULL,
  `actual_fuel_consumption` decimal(10,2) DEFAULT NULL,
  `fuel_consumption_per_hour` decimal(10,2) DEFAULT NULL,
  `fuel_consumption_per_kwh` decimal(10,2) DEFAULT NULL,
  `cost_of_electricity` decimal(10,2) DEFAULT NULL,
  `fuel_variance` decimal(10,2) DEFAULT NULL,
  `estimated_days_empty` decimal(10,2) DEFAULT NULL,
  `photo_meter_path` varchar(255) DEFAULT NULL,
  `actual_fuel_remaining` decimal(10,2) DEFAULT NULL,
  `estimated_fuel_remaining` decimal(10,2) DEFAULT NULL,
  `estimated_fuel_used` decimal(10,2) DEFAULT NULL,
  `actual_fuel_used` decimal(10,2) DEFAULT NULL,
  `fuel_difference` decimal(10,2) DEFAULT NULL,
  `status` enum('Pending Verification','Verified','Flagged','Rejected') DEFAULT 'Pending Verification',
  `previous_meter_hours` decimal(10,2) DEFAULT 0.00,
  `current_meter_hours` decimal(10,2) DEFAULT 0.00,
  `liters_per_hour` decimal(10,2) DEFAULT 0.00,
  `liters_per_kwh` decimal(10,2) DEFAULT 0.00,
  `rejection_reason` text DEFAULT NULL,
  `submitted_at` datetime DEFAULT current_timestamp(),
  `approved_at` datetime DEFAULT NULL,
  `rejected_at` datetime DEFAULT NULL,
  `approved_by` int(11) DEFAULT NULL,
  `fuel_photo_path` varchar(255) DEFAULT NULL,
  `anomaly_flags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`anomaly_flags`)),
  `confidence_score` tinyint(3) UNSIGNED DEFAULT 100,
  `risk_level` enum('low','medium','high','critical') DEFAULT 'low',
  `rejection_reason_code` varchar(100) DEFAULT NULL,
  `rejection_severity` enum('minor','medium','major','critical') DEFAULT NULL,
  `reviewed_at` datetime DEFAULT NULL,
  `reviewed_by` int(11) DEFAULT NULL,
  `version_number` int(11) DEFAULT 1,
  `priority` tinyint(4) DEFAULT 2
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `generator_daily_reports_archived`
--

INSERT INTO `generator_daily_reports_archived` (`id`, `generator_id`, `date`, `fuel_added`, `expected_fuel_used`, `cost_per_liter`, `fuel_remaining`, `spare_remaining`, `running_hours`, `meter_hours`, `kwh_produced`, `notes`, `discrepancy_reason`, `photo_path`, `submitted_by`, `created_at`, `previous_kwh`, `current_kwh`, `efficiency_score`, `alert_level`, `load_percentage`, `outages_count`, `expected_fuel_consumption`, `actual_fuel_consumption`, `fuel_consumption_per_hour`, `fuel_consumption_per_kwh`, `cost_of_electricity`, `fuel_variance`, `estimated_days_empty`, `photo_meter_path`, `actual_fuel_remaining`, `estimated_fuel_remaining`, `estimated_fuel_used`, `actual_fuel_used`, `fuel_difference`, `status`, `previous_meter_hours`, `current_meter_hours`, `liters_per_hour`, `liters_per_kwh`, `rejection_reason`, `submitted_at`, `approved_at`, `rejected_at`, `approved_by`, `fuel_photo_path`, `anomaly_flags`, `confidence_score`, `risk_level`, `rejection_reason_code`, `rejection_severity`, `reviewed_at`, `reviewed_by`, `version_number`, `priority`) VALUES
(29, 12, '2026-08-01', 0.00, 0.00, 0.00, 0.00, 0.00, 5.00, 1005.00, 363.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 50000.00, 50363.00, 7.26, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 950.00, 950.00, 50.00, 50.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(30, 12, '2026-08-02', 0.00, 0.00, 0.00, 0.00, 0.00, 6.00, 1011.00, 205.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 50363.00, 50568.00, 3.42, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 890.00, 890.00, 60.00, 60.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(31, 12, '2026-08-03', 0.00, 0.00, 0.00, 0.00, 0.00, 5.00, 1016.00, 471.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 50568.00, 51039.00, 9.42, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 840.00, 840.00, 50.00, 50.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(32, 12, '2026-08-04', 0.00, 0.00, 0.00, 0.00, 0.00, 10.00, 1026.00, 405.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 51039.00, 51444.00, 4.05, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 740.00, 740.00, 100.00, 100.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(33, 12, '2026-08-05', 0.00, 0.00, 0.00, 0.00, 0.00, 5.00, 1031.00, 402.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 51444.00, 51846.00, 8.04, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 690.00, 690.00, 50.00, 50.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(34, 12, '2026-08-06', 0.00, 0.00, 0.00, 0.00, 0.00, 12.00, 1043.00, 316.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 51846.00, 52162.00, 2.63, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 570.00, 570.00, 120.00, 120.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(35, 12, '2026-08-07', 0.00, 0.00, 0.00, 0.00, 0.00, 6.00, 1049.00, 466.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 52162.00, 52628.00, 7.77, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 510.00, 510.00, 60.00, 60.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(36, 12, '2026-08-08', 0.00, 0.00, 0.00, 0.00, 0.00, 5.00, 1054.00, 314.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 52628.00, 52942.00, 6.28, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 460.00, 460.00, 50.00, 50.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(37, 12, '2026-08-09', 0.00, 0.00, 0.00, 0.00, 0.00, 11.00, 1065.00, 349.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 52942.00, 53291.00, 3.17, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 350.00, 350.00, 110.00, 110.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(38, 12, '2026-08-10', 0.00, 0.00, 0.00, 0.00, 0.00, 6.00, 1071.00, 244.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 53291.00, 53535.00, 4.07, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 290.00, 290.00, 60.00, 60.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(39, 12, '2026-08-11', 0.00, 0.00, 0.00, 0.00, 0.00, 9.00, 1080.00, 227.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 53535.00, 53762.00, 2.52, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 200.00, 200.00, 90.00, 90.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(40, 12, '2026-08-12', 0.00, 0.00, 0.00, 0.00, 0.00, 6.00, 1086.00, 499.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 53762.00, 54261.00, 8.32, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 140.00, 140.00, 60.00, 60.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(41, 12, '2026-08-13', 0.00, 0.00, 0.00, 0.00, 0.00, 7.00, 1093.00, 442.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 54261.00, 54703.00, 6.31, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 930.00, 930.00, 70.00, 70.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(42, 12, '2026-08-14', 0.00, 0.00, 0.00, 0.00, 0.00, 9.00, 1102.00, 482.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 54703.00, 55185.00, 5.36, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 840.00, 840.00, 90.00, 90.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(43, 12, '2026-08-15', 0.00, 0.00, 0.00, 0.00, 0.00, 10.00, 1112.00, 346.00, NULL, NULL, NULL, NULL, '2026-08-17 20:19:04', 55185.00, 55531.00, 3.46, 'Normal', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 740.00, 740.00, 100.00, 100.00, NULL, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2),
(44, 12, '2026-08-16', 0.00, 0.00, 0.00, 0.00, 0.00, 10.00, 1122.00, 444.00, NULL, 'Critical Alert: Consumed 100L less than expected.', NULL, NULL, '2026-08-17 20:19:04', 55531.00, 55975.00, 0.00, 'Critical', NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 640.00, 640.00, 100.00, 0.00, -100.00, 'Verified', 0.00, 0.00, 0.00, 0.00, NULL, '2026-08-17 23:19:04', NULL, NULL, NULL, NULL, NULL, 100, 'low', NULL, NULL, NULL, NULL, 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `generator_predictions_archived`
--

CREATE TABLE `generator_predictions_archived` (
  `id` int(11) NOT NULL,
  `generator_id` int(11) NOT NULL,
  `prediction_date` date NOT NULL,
  `predicted_fuel` decimal(10,2) DEFAULT NULL,
  `predicted_cost` decimal(10,2) DEFAULT NULL,
  `predicted_remaining_days` decimal(10,2) DEFAULT NULL,
  `predicted_efficiency` decimal(10,2) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `global_menus`
--

CREATE TABLE `global_menus` (
  `id` int(11) NOT NULL,
  `menu_key` varchar(100) NOT NULL,
  `label` varchar(255) NOT NULL,
  `path` varchar(255) NOT NULL,
  `icon` varchar(100) DEFAULT 'FileText',
  `parent_key` varchar(100) DEFAULT NULL,
  `sort_order` int(11) DEFAULT 0,
  `is_custom` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `global_menus`
--

INSERT INTO `global_menus` (`id`, `menu_key`, `label`, `path`, `icon`, `parent_key`, `sort_order`, `is_custom`) VALUES
(1, 'dashboard', 'Dashboard', '/', 'LayoutDashboard', NULL, 10, 0),
(2, 'schedule', 'Schedule Center', '/schedule', 'Calendar', NULL, 80, 0),
(3, 'buildings_group', 'Buildings', '#', 'Building', NULL, 150, 0),
(4, 'buildings', 'Buildings List', '/buildings', 'Building', 'buildings_group', 20, 0),
(5, 'apartments', 'Apartments', '/apartments', 'Home', 'buildings_group', 90, 0),
(6, 'tenants', 'Tenants', '/tenants', 'Users', 'buildings_group', 160, 0),
(7, 'contracts', 'Contracts', '/contracts', 'FileText', 'buildings_group', 210, 0),
(8, 'reports_group', 'Reports', '#', 'FileText', NULL, 220, 0),
(9, 'apartment_costs', 'Apartment Cost Report', '/apartment-costs', 'DollarSign', 'reports_group', 30, 0),
(10, 'financial_buildings', 'Financial Building Report', '/financial-buildings-report', 'FileText', 'reports_group', 100, 0),
(11, 'financial_reports', 'Financial Reports', '/financial-reports', 'BarChart2', 'reports_group', 170, 0),
(12, 'rent_hub', 'Insurance Hub', '/rent-hub', 'Shield', 'reports_group', 230, 0),
(13, 'workshop_group', 'Workshop', '#', 'HardHat', NULL, 270, 0),
(14, 'constructions', 'Construction', '/constructions', 'Briefcase', 'workshop_group', 40, 0),
(15, 'workshop', 'Workshop', '/workshop', 'HardHat', 'workshop_group', 110, 0),
(16, 'suppliers', 'Suppliers', '/suppliers', 'Truck', 'workshop_group', 180, 0),
(17, 'purchase_orders', 'Purchase Orders', '/purchase-orders', 'FileCheck2', 'workshop_group', 240, 0),
(18, 'settings', 'Workshop Pricing', '/workshop-pricing', 'Settings', 'workshop_group', 280, 0),
(19, 'commerce_group', 'Sales', '#', 'ShoppingCart', NULL, 300, 0),
(20, 'pos', 'New Sale', '/pos', 'ShoppingCart', 'commerce_group', 50, 0),
(21, 'sales', 'Sales History', '/sales', 'FileText', 'commerce_group', 120, 0),
(25, 'depot', 'Warehouse', '/depot', 'Archive', 'commerce_group', 310, 0),
(26, 'movement_transfer', 'Stock Transfer', '/movement-transfer', 'Truck', 'commerce_group', 340, 0),
(27, 'modules_group', 'Modules', '#', 'Zap', NULL, 350, 0),
(28, 'maintenance_admin', 'AC Maintenance', '/maintenance-admin', 'Shield', 'modules_group', 60, 0),
(29, 'energy', 'Energy', '/energy', 'Zap', 'modules_group', 130, 0),
(30, 'energy_verification', 'Readings Verification', '/energy/verification', 'FileCheck2', 'modules_group', 190, 0),
(31, 'generator_sub_report', 'Gen Sub Report', '/generator-subscriptions-report', 'FileText', 'reports_group', 250, 0),
(32, 'fuel_reserve', 'Fuel Reserve', '/fuel-reserve', 'Fuel', 'modules_group', 290, 0),
(33, 'expenses', 'Expenses', '/expenses', 'CreditCard', 'modules_group', 320, 0),
(34, 'reports', 'General Reports', '/reports', 'FileText', 'modules_group', 330, 0),
(35, 'admin_group', 'Admin Tools', '#', 'Settings', NULL, 360, 0),
(36, 'system_settings', 'System Settings', '/settings', 'Settings', 'admin_group', 70, 0),
(37, 'data_quality', 'Data Quality', '/data-quality', 'ShieldAlert', 'admin_group', 140, 0),
(38, 'ai_chat', 'AI Engine', '/ai-chat', 'Sparkles', 'admin_group', 200, 0),
(39, 'action_control', 'Action Control', '/action-control', 'ShieldAlert', 'admin_group', 260, 0),
(40, 'ksd', 'fsdf', 'sdfsd', '', 'buildings_group', 0, 1),
(41, 'archived_tenants', 'Archived Tenants', '/tenant-archive', 'Archive', 'buildings_group', 165, 0);

-- --------------------------------------------------------

--
-- Table structure for table `global_settings`
--

CREATE TABLE `global_settings` (
  `id` int(11) NOT NULL,
  `setting_key` varchar(50) NOT NULL,
  `setting_value` varchar(255) NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `global_settings`
--

INSERT INTO `global_settings` (`id`, `setting_key`, `setting_value`, `updated_at`) VALUES
(1, 'usd_to_cfa', '600', '2026-07-04 21:37:36'),
(2, 'company_logo', '', '2026-07-17 21:53:11'),
(3, 'company_name', 'Bitar Group Ltd', '2026-07-17 22:13:52'),
(4, 'business_address', '123 Construction Blvd, Industry City', '2026-07-17 22:13:52'),
(5, 'phone', '+1 234 567 8900', '2026-07-17 22:13:52'),
(6, 'email', 'accounts@bitar.com', '2026-07-17 22:13:52'),
(7, 'website', 'www.bitar.com', '2026-07-17 22:13:52'),
(8, 'tax_number', 'TIN-987654321', '2026-07-17 22:13:52'),
(9, 'registration_number', 'REG-123456', '2026-07-17 22:13:52'),
(10, 'currency', 'CFA', '2026-07-17 22:13:52'),
(11, 'footer_message', 'Thank you for your business!', '2026-07-17 22:13:52'),
(12, 'receipt_header', 'RECEIPT', '2026-07-17 22:13:52'),
(13, 'receipt_footer', 'No returns after 30 days.', '2026-07-17 22:13:52');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_accounts`
--

CREATE TABLE `insurance_accounts` (
  `id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `total_saved` decimal(10,2) DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `insurance_accounts`
--

INSERT INTO `insurance_accounts` (`id`, `contract_id`, `total_saved`, `created_at`) VALUES
(16, 18, 280000.00, '2026-07-22 20:03:57'),
(17, 19, 360000.00, '2026-07-22 20:26:30'),
(20, 22, 30000.00, '2026-08-06 21:17:19'),
(21, 23, 312000.00, '2026-08-23 19:14:41'),
(33, 35, 120.00, '2026-04-20 21:00:00'),
(34, 36, 150.00, '2026-04-20 21:00:00'),
(35, 37, 120.00, '2026-04-20 21:00:00'),
(36, 38, 180.00, '2026-04-20 21:00:00'),
(37, 39, 100.00, '2026-04-20 21:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `insurance_transactions`
--

CREATE TABLE `insurance_transactions` (
  `id` int(11) NOT NULL,
  `account_id` int(11) NOT NULL,
  `type` enum('Deposit','Refund','Deduct','Apply_To_Rent') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `insurance_transactions`
--

INSERT INTO `insurance_transactions` (`id`, `account_id`, `type`, `amount`, `date`, `user_id`, `notes`, `created_at`) VALUES
(38, 16, 'Deposit', 180000.00, '2026-07-22', 1, 'Initial Insurance/Deposit (Auto-saved)', '2026-07-22 20:03:57'),
(39, 17, 'Deposit', 180000.00, '2026-07-22', 1, 'Initial Insurance/Deposit (Auto-saved)', '2026-07-22 20:26:30'),
(42, 20, 'Deposit', 30000.00, '2026-08-07', 1, 'Initial Insurance/Deposit (Auto-saved)', '2026-08-06 21:17:19'),
(43, 16, 'Deposit', 100000.00, '2026-08-17', 1, '', '2026-08-16 21:04:12'),
(44, 17, 'Deposit', 180000.00, '2026-08-17', 1, '', '2026-08-16 21:04:23'),
(45, 21, 'Deposit', 312000.00, '2026-08-23', 1, 'Initial Insurance/Deposit (Auto-saved)', '2026-08-23 19:14:41'),
(57, 33, 'Deposit', 120.00, '2026-04-21', NULL, 'Initial Policy Generation', '2026-09-21 21:53:40'),
(58, 34, 'Deposit', 150.00, '2026-04-21', NULL, 'Initial Policy Generation', '2026-09-21 21:53:40'),
(59, 35, 'Deposit', 120.00, '2026-04-21', NULL, 'Initial Policy Generation', '2026-09-21 21:53:40'),
(60, 36, 'Deposit', 180.00, '2026-04-21', NULL, 'Initial Policy Generation', '2026-09-21 21:53:40'),
(61, 37, 'Deposit', 100.00, '2026-04-21', NULL, 'Initial Policy Generation', '2026-09-21 21:53:40');

-- --------------------------------------------------------

--
-- Table structure for table `integrity_issues`
--

CREATE TABLE `integrity_issues` (
  `id` int(11) NOT NULL,
  `issue_type` varchar(100) NOT NULL COMMENT 'duplicate_national_id|duplicate_phone|orphan_record|broken_relationship|...',
  `severity` enum('critical','warning','info') NOT NULL DEFAULT 'warning',
  `table_name` varchar(100) NOT NULL,
  `record_id` int(11) NOT NULL,
  `duplicate_id` int(11) DEFAULT NULL COMMENT 'The other record in a duplicate pair',
  `description` text NOT NULL,
  `status` enum('open','ignored','merged','resolved') NOT NULL DEFAULT 'open',
  `resolved_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `integrity_issues`
--

INSERT INTO `integrity_issues` (`id`, `issue_type`, `severity`, `table_name`, `record_id`, `duplicate_id`, `description`, `status`, `resolved_by`, `created_at`, `updated_at`) VALUES
(3, 'duplicate_national_id', 'critical', 'tenants', 5, 9, 'Duplicate National ID \'564564\' found on 2 tenants: ali yazbekk, ali yazbekk', 'resolved', 1, '2026-07-17 01:10:47', '2026-07-18 01:14:25'),
(4, 'duplicate_phone', 'warning', 'tenants', 5, 9, 'Duplicate phone \'81994663\' found on 2 tenants: ali yazbekk, ali yazbekk', 'resolved', 1, '2026-07-17 01:10:47', '2026-07-18 01:14:24'),
(5, 'duplicate_national_id', 'critical', 'tenants', 5, 9, 'Duplicate National ID \'564564\' found on 6 tenants: ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk', 'resolved', 1, '2026-08-05 23:41:56', '2026-08-05 23:42:06'),
(6, 'duplicate_phone', 'warning', 'tenants', 5, 9, 'Duplicate phone \'81994663\' found on 6 tenants: ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk', 'resolved', 1, '2026-08-05 23:41:56', '2026-08-05 23:42:04'),
(9, 'duplicate_national_id', 'critical', 'tenants', 5, 9, 'Duplicate National ID \'564564\' found on 6 tenants: ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk', 'resolved', 1, '2026-08-05 23:42:30', '2026-09-17 23:21:04'),
(10, 'duplicate_phone', 'warning', 'tenants', 5, 9, 'Duplicate phone \'81994663\' found on 6 tenants: ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk, ali yazbekk', 'resolved', 1, '2026-08-05 23:42:30', '2026-09-17 23:21:07');

-- --------------------------------------------------------

--
-- Table structure for table `inventory_items`
--

CREATE TABLE `inventory_items` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `current_stock` decimal(10,2) DEFAULT 0.00,
  `min_stock` decimal(10,2) DEFAULT 0.00,
  `unit_cost` decimal(10,2) DEFAULT 0.00,
  `supplier` varchar(100) DEFAULT NULL,
  `warehouse_location` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_construction_material` tinyint(1) DEFAULT 0,
  `name_fr` varchar(255) DEFAULT NULL,
  `name_ar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `inventory_transactions`
--

CREATE TABLE `inventory_transactions` (
  `id` int(11) NOT NULL,
  `item_id` int(11) NOT NULL,
  `type` enum('IN','OUT') NOT NULL,
  `quantity` decimal(10,2) NOT NULL,
  `project_id` int(11) DEFAULT NULL,
  `user_id` int(11) NOT NULL,
  `notes` text DEFAULT NULL,
  `date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `invoices`
--

CREATE TABLE `invoices` (
  `id` int(11) NOT NULL,
  `invoice_number` varchar(100) NOT NULL,
  `date` date NOT NULL,
  `customer_type` enum('Walk In','Account','Apartment','Construction','Building','Supplier','Employee','Government','Other','Walk-In') DEFAULT 'Walk In',
  `customer_id` int(11) DEFAULT NULL,
  `customer_name` varchar(255) DEFAULT NULL,
  `subtotal` decimal(10,2) NOT NULL DEFAULT 0.00,
  `total_tva` decimal(10,2) NOT NULL DEFAULT 0.00,
  `discount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `final_amount` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `payment_type` enum('Cash','Card','Bank','Transfer','Cheque','Account','Mixed') DEFAULT 'Cash',
  `status` enum('Paid','Partial','Pending','Cancelled','Refunded','Returned','Active') DEFAULT 'Paid',
  `returned_amount` decimal(10,2) DEFAULT 0.00,
  `invoice_time` time DEFAULT NULL,
  `tax` decimal(10,2) DEFAULT 0.00,
  `notes` text DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `invoices`
--

INSERT INTO `invoices` (`id`, `invoice_number`, `date`, `customer_type`, `customer_id`, `customer_name`, `subtotal`, `total_tva`, `discount`, `final_amount`, `created_at`, `payment_type`, `status`, `returned_amount`, `invoice_time`, `tax`, `notes`, `reason`, `created_by`) VALUES
(1, 'INV-1781902512-9439', '2026-06-19', 'Apartment', 1, 'Apt A1  (galaxy)', 1000.00, 190.00, 0.00, 1190.00, '2026-06-19 20:55:12', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(2, 'INV-1781902616-4163', '2026-06-19', 'Construction', 1, 'ali', 6000.00, 1140.00, 0.00, 7140.00, '2026-06-19 20:56:56', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(3, 'INV-1781903570-8612', '2026-06-19', 'Apartment', 1, 'Apt A1  (galaxy)', 60.00, 11.40, 0.00, 71.40, '2026-06-19 21:12:50', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(4, 'INV-1781903822-4868', '2026-06-19', 'Apartment', 6, 'Apt A1 (yazbek)', 1030.00, 195.70, 0.00, 1225.70, '2026-06-19 21:17:02', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(5, 'INV-1781904595-7582', '2026-06-19', 'Apartment', 1, 'Apt A1  (galaxy)', 1181.00, 224.39, 0.00, 1405.39, '2026-06-19 21:29:55', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(6, 'INV-1781904632-8994', '2026-06-19', 'Apartment', 1, 'Apt A1  (galaxy)', 1300.00, 247.00, 0.00, 1547.00, '2026-06-19 21:30:32', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(7, 'INV-1781904760-2940', '2026-06-19', 'Walk-In', 0, 'masri', 1872.00, 355.68, 0.00, 2227.68, '2026-06-19 21:32:40', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(8, 'INV-1781905028-5268', '2026-06-19', 'Apartment', 1, 'Apt A1  (galaxy)', 822.00, 156.18, 0.00, 978.18, '2026-06-19 21:37:08', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(9, 'INV-1781906159-9487', '2026-06-19', 'Walk-In', 0, '', 520.00, 98.80, 0.00, 618.80, '2026-06-19 21:55:59', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(10, 'INV-1781909781-9228', '2026-06-19', 'Walk-In', 0, '', 57210.00, 10869.90, 0.00, 68079.90, '2026-06-19 22:56:21', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(11, 'INV-1781910533-6596', '2026-06-20', 'Walk-In', 0, '', 630.00, 119.70, 0.00, 749.70, '2026-06-19 23:08:53', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(12, 'INV-1782160216-8903', '2026-06-22', 'Construction', 1, 'ali', 671.00, 127.49, 0.00, 798.49, '2026-06-22 20:30:16', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(13, 'INV-1782160403-8022', '2026-06-22', 'Walk-In', 0, '', 5720.00, 1086.80, 0.00, 6806.80, '2026-06-22 20:33:23', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(14, 'INV-1782160427-8674', '2026-06-22', 'Construction', 1, 'ali', 572000.00, 108680.00, 0.00, 680680.00, '2026-06-22 20:33:47', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(15, 'INV-1782937981-2261', '2026-07-01', 'Apartment', 1, 'Apt CFA A1  (galaxy)', 8944.00, 1699.36, 0.00, 10643.36, '2026-07-01 20:33:01', 'Cash', 'Active', 0.00, NULL, 0.00, NULL, NULL, NULL),
(16, 'INV-1784493560-6713', '2026-07-19', 'Walk-In', 0, '', 671.00, 127.49, 0.00, 798.49, '2026-07-19 20:39:20', 'Cash', 'Paid', 0.00, NULL, 0.00, NULL, NULL, NULL),
(17, 'INV-1784493769-7790', '2026-07-19', 'Walk-In', 0, '', 500.00, 95.00, 0.00, 595.00, '2026-07-19 20:42:49', 'Cash', 'Paid', 0.00, NULL, 0.00, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `invoice_items`
--

CREATE TABLE `invoice_items` (
  `id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `quantity` int(11) NOT NULL,
  `returned_qty` int(11) NOT NULL DEFAULT 0,
  `cost_price` decimal(10,2) NOT NULL,
  `tva` decimal(5,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `invoice_items`
--

INSERT INTO `invoice_items` (`id`, `invoice_id`, `product_id`, `reference`, `quantity`, `returned_qty`, `cost_price`, `tva`, `total_price`) VALUES
(1, 1, 1, '1504456', 2, 0, 500.00, 19.00, 1190.00),
(2, 2, 1, '1504456', 12, 0, 500.00, 19.00, 7140.00),
(3, 3, 2, '454556', 6, 0, 10.00, 19.00, 71.40),
(4, 4, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(5, 4, 2, '454556', 1, 0, 10.00, 19.00, 11.90),
(6, 4, 1, '1504456', 1, 0, 500.00, 19.00, 595.00),
(7, 5, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(8, 5, 4, '45456', 1, 0, 151.00, 19.00, 179.69),
(9, 5, 2, '454556', 1, 0, 10.00, 19.00, 11.90),
(10, 5, 1, '1504456', 1, 0, 500.00, 19.00, 595.00),
(11, 6, 2, '454556', 28, 0, 10.00, 19.00, 333.20),
(12, 6, 1, '1504456', 1, 0, 500.00, 19.00, 595.00),
(13, 6, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(14, 7, 2, '454556', 3, 0, 10.00, 19.00, 35.70),
(15, 7, 3, '15156', 2, 0, 520.00, 19.00, 1237.60),
(16, 7, 4, '45456', 2, 0, 151.00, 19.00, 359.38),
(17, 7, 1, '1504456', 1, 0, 500.00, 19.00, 595.00),
(18, 8, 4, '45456', 2, 0, 151.00, 19.00, 359.38),
(19, 8, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(20, 9, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(21, 10, 3, '15156', 110, 0, 520.00, 19.00, 68068.00),
(22, 10, 2, '454556', 1, 0, 10.00, 19.00, 11.90),
(25, 11, 2, '454556', 11, 0, 10.00, 19.00, 130.90),
(26, 11, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(27, 12, 4, '45456', 1, 0, 151.00, 19.00, 179.69),
(28, 12, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(29, 13, 3, '15156', 11, 0, 520.00, 19.00, 6806.80),
(30, 14, 3, '15156', 1100, 0, 520.00, 19.00, 680680.00),
(31, 15, 2, '454556', 2, 0, 10.00, 19.00, 23.80),
(32, 15, 3, '15156', 16, 0, 520.00, 19.00, 9900.80),
(33, 15, 4, '45456', 4, 0, 151.00, 19.00, 718.76),
(34, 16, 3, '15156', 1, 0, 520.00, 19.00, 618.80),
(35, 16, 4, '45456', 1, 0, 151.00, 19.00, 179.69),
(36, 17, 1, '1504456', 1, 0, 500.00, 19.00, 595.00);

-- --------------------------------------------------------

--
-- Table structure for table `journal_entries`
--

CREATE TABLE `journal_entries` (
  `id` int(11) NOT NULL,
  `date` date NOT NULL,
  `description` varchar(255) NOT NULL,
  `debit_account_id` int(11) NOT NULL,
  `credit_account_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `reference_type` varchar(50) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `menu_permissions`
--

CREATE TABLE `menu_permissions` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `menu_key` varchar(100) NOT NULL,
  `menu_label` varchar(200) DEFAULT NULL,
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `sort_order` int(11) NOT NULL DEFAULT 0,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `menu_permissions`
--

INSERT INTO `menu_permissions` (`id`, `role`, `menu_key`, `menu_label`, `is_visible`, `sort_order`, `updated_at`) VALUES
(1, 'admin', 'archived_tenants', 'Archived Tenants', 1, 165, '2026-09-24 01:37:50');

-- --------------------------------------------------------

--
-- Table structure for table `mobile_sync_conflicts`
--

CREATE TABLE `mobile_sync_conflicts` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `entity_type` varchar(100) NOT NULL,
  `entity_id` int(11) NOT NULL,
  `server_version` int(11) DEFAULT 1,
  `client_version` int(11) DEFAULT 1,
  `client_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`client_payload`)),
  `server_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`server_payload`)),
  `resolution_status` enum('Pending','Merged','AdminWins','UserWins') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` varchar(50) NOT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `seen_by_agent` tinyint(1) DEFAULT 0,
  `delivery_channel` enum('Database','Push','Email','SMS','WhatsApp') DEFAULT 'Database',
  `delivery_status` enum('Pending','Sent','Delivered','Failed','Read') DEFAULT 'Pending'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `title`, `message`, `type`, `reference_id`, `is_read`, `created_at`, `seen_by_agent`, `delivery_channel`, `delivery_status`) VALUES
(1, 4, 'Generator Subscription Renewal', 'Your generator subscription is expiring soon. Would you like to renew?', 'generator_renewal_request', 3, 1, '2026-06-30 20:25:47', 0, 'Database', 'Pending'),
(2, 1, 'Tenant Renewal Response', 'The tenant in apartment A3 has responded to the renewal request with: Accept.', 'tenant_renewal_response', 3, 1, '2026-06-30 20:37:59', 0, 'Database', 'Pending'),
(3, 5, 'Meter Reading Accepted ✅', 'Your meter reading for galaxy - Apt A1  (Tenant: Ali Yazbek) has been ACCEPTED. Subscription renewed for next month.', 'agent_reading_accepted', 1, 1, '2026-06-30 22:03:13', 1, 'Database', 'Pending'),
(4, 1, 'New Purchase Submission 🛒', 'Agent submitted a purchase of $135000 for Galaxy - Apt A1. Please review.', 'agent_purchase_pending', NULL, 0, '2026-07-28 21:24:55', 0, 'Database', 'Pending'),
(5, 1, 'New Purchase Submission 🛒', 'Agent submitted a purchase of $454545 for Galaxy - Apt A1. Please review.', 'agent_purchase_pending', NULL, 0, '2026-07-28 21:32:32', 0, 'Database', 'Pending'),
(6, 5, 'Purchase Accepted ✅', 'Your purchase of $454545.00 for Galaxy - Apt A1 has been ACCEPTED and recorded.', 'agent_purchase_accepted', 3, 0, '2026-08-04 20:13:31', 0, 'Database', 'Pending'),
(7, 5, 'Purchase Accepted ✅', 'Your purchase of $135000.00 for Galaxy - Apt A1 has been ACCEPTED and recorded.', 'agent_purchase_accepted', 2, 0, '2026-08-04 20:13:33', 0, 'Database', 'Pending'),
(8, 1, '✅ Reading Approved', 'Your meter reading for Building — Generator has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 23, 0, '2026-08-04 21:05:52', 0, 'Database', 'Pending'),
(9, 5, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 8, 1, '2026-08-05 19:55:58', 1, 'Database', 'Pending'),
(10, 5, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 9, 1, '2026-08-05 19:56:01', 1, 'Database', 'Pending'),
(11, 5, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 10, 1, '2026-08-05 20:20:23', 1, 'Database', 'Pending'),
(12, 5, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 11, 1, '2026-08-06 22:03:04', 1, 'Database', 'Pending'),
(13, 4, 'Generator Subscription Renewal', 'Your generator subscription is expiring soon. Would you like to renew?', 'generator_renewal_request', 11, 1, '2026-08-07 21:14:28', 0, 'Database', 'Pending'),
(14, 5, '✅ Reading Approved', 'Your meter reading for Galaxy — Apt A1 has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 2, 1, '2026-08-07 21:20:02', 1, 'Database', 'Pending'),
(15, 1, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 12, 0, '2026-08-07 21:46:33', 0, 'Database', 'Pending'),
(16, 1, '✅ Reading Approved', 'Your meter reading for Building — Apt ? has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 13, 0, '2026-08-07 21:46:36', 0, 'Database', 'Pending'),
(17, 5, '✅ Reading Approved', 'Your meter reading for Galaxy — Apt A3 has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 3, 1, '2026-08-07 21:46:51', 1, 'Database', 'Pending'),
(18, 1, 'Tenant Renewal Response', 'The tenant in apartment A1 has responded to the renewal request with: Accept.', 'tenant_renewal_response', 11, 1, '2026-08-08 23:03:14', 0, 'Database', 'Pending'),
(19, 5, '✅ Reading Approved', 'Your meter reading for Building — Generator has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 24, 0, '2026-08-09 21:31:48', 0, 'Database', 'Pending'),
(20, 1, '✅ Reading Approved', 'Your meter reading for Building — Generator has been approved. The invoice has been generated automatically.', 'agent_reading_accepted', 25, 0, '2026-08-16 14:30:46', 0, 'Database', 'Pending'),
(21, 5, '❌ Reading Rejected', 'Your reading for Building — Generator was rejected.\nReason: Incorrect reading value entered\nSeverity: medium\nPlease resubmit with corrections.', 'agent_reading_rejected', 1, 0, '2026-08-27 20:03:29', 0, 'Database', 'Pending'),
(22, 5, '🚨 Action Required', 'A new reading is required for Building — Generator. Tap to resubmit.', 'agent_action_required', 1, 0, '2026-08-27 20:03:29', 0, 'Database', 'Pending'),
(23, 5, '❌ Reading Rejected', 'Your reading for Building — Generator was rejected.\nReason: Incorrect reading value entered\nSeverity: medium\nPlease resubmit with corrections.', 'agent_reading_rejected', 3, 0, '2026-08-27 20:48:44', 0, 'Database', 'Pending'),
(24, 5, '🚨 Action Required', 'A new reading is required for Building — Generator. Tap to resubmit.', 'agent_action_required', 3, 0, '2026-08-27 20:48:44', 0, 'Database', 'Pending');

-- --------------------------------------------------------

--
-- Table structure for table `notification_messages`
--

CREATE TABLE `notification_messages` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `category` enum('Task','Approval','Rejection','Emergency','Generator','Fuel','Rent','Electricity','Contract','Maintenance','Inventory','Workshop','POS','Security','System','Updates') DEFAULT 'Task',
  `priority` enum('Critical','High','Normal','Low') DEFAULT 'Normal',
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notification_templates`
--

CREATE TABLE `notification_templates` (
  `id` int(11) NOT NULL,
  `code` varchar(50) NOT NULL,
  `title_template` varchar(255) NOT NULL,
  `message_template` text NOT NULL,
  `type` varchar(50) DEFAULT 'System',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `page_permissions`
--

CREATE TABLE `page_permissions` (
  `id` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `page_key` varchar(100) NOT NULL COMMENT 'dashboard|tenants|apartments|contracts|...',
  `can_view` tinyint(1) NOT NULL DEFAULT 1,
  `can_add` tinyint(1) NOT NULL DEFAULT 0,
  `can_edit` tinyint(1) NOT NULL DEFAULT 0,
  `can_delete` tinyint(1) NOT NULL DEFAULT 0,
  `can_print` tinyint(1) NOT NULL DEFAULT 1,
  `can_export` tinyint(1) NOT NULL DEFAULT 0,
  `can_approve` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `page_permissions`
--

INSERT INTO `page_permissions` (`id`, `role`, `page_key`, `can_view`, `can_add`, `can_edit`, `can_delete`, `can_print`, `can_export`, `can_approve`, `updated_at`) VALUES
(1, 'admin', 'dashboard', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(2, 'admin', 'buildings', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(3, 'admin', 'apartments', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(4, 'admin', 'tenants', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(5, 'admin', 'contracts', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(6, 'admin', 'rent', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(7, 'admin', 'insurance', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(8, 'admin', 'workshop', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(9, 'admin', 'constructions', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(10, 'admin', 'suppliers', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(11, 'admin', 'purchase_orders', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(12, 'admin', 'sales', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(13, 'admin', 'energy', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(14, 'admin', 'generators', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(15, 'admin', 'fuel_reserve', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(16, 'admin', 'warehouse', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(17, 'admin', 'pos', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(18, 'admin', 'expenses', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(19, 'admin', 'reports', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(20, 'admin', 'users', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(21, 'admin', 'settings', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(22, 'admin', 'maintenance', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(23, 'admin', 'action_control', 1, 1, 1, 1, 1, 1, 1, '2026-07-17 00:14:13'),
(24, 'manager', 'dashboard', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(25, 'manager', 'buildings', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(26, 'manager', 'apartments', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(27, 'manager', 'tenants', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(28, 'manager', 'contracts', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(29, 'manager', 'rent', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(30, 'manager', 'insurance', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(31, 'manager', 'workshop', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(32, 'manager', 'constructions', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(33, 'manager', 'suppliers', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(34, 'manager', 'purchase_orders', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(35, 'manager', 'sales', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(36, 'manager', 'energy', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(37, 'manager', 'generators', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(38, 'manager', 'fuel_reserve', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(39, 'manager', 'warehouse', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(40, 'manager', 'pos', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(41, 'manager', 'expenses', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(42, 'manager', 'reports', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(43, 'manager', 'users', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(44, 'manager', 'settings', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(45, 'manager', 'maintenance', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(46, 'manager', 'action_control', 1, 1, 1, 1, 0, 1, 0, '2026-07-17 00:14:13'),
(47, 'cashier', 'dashboard', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(48, 'cashier', 'buildings', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(49, 'cashier', 'apartments', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(50, 'cashier', 'tenants', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(51, 'cashier', 'contracts', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(52, 'cashier', 'rent', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(53, 'cashier', 'insurance', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(54, 'cashier', 'workshop', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(55, 'cashier', 'constructions', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(56, 'cashier', 'suppliers', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(57, 'cashier', 'purchase_orders', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(58, 'cashier', 'sales', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(59, 'cashier', 'energy', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(60, 'cashier', 'generators', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(61, 'cashier', 'fuel_reserve', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(62, 'cashier', 'warehouse', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(63, 'cashier', 'pos', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(64, 'cashier', 'expenses', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(65, 'cashier', 'reports', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(66, 'cashier', 'users', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(67, 'cashier', 'settings', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(68, 'cashier', 'maintenance', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(69, 'cashier', 'action_control', 1, 1, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(70, 'agent', 'dashboard', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(71, 'agent', 'buildings', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(72, 'agent', 'apartments', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(73, 'agent', 'tenants', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(74, 'agent', 'contracts', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(75, 'agent', 'rent', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(76, 'agent', 'insurance', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(77, 'agent', 'workshop', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(78, 'agent', 'constructions', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(79, 'agent', 'suppliers', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(80, 'agent', 'purchase_orders', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(81, 'agent', 'sales', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(82, 'agent', 'energy', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(83, 'agent', 'generators', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(84, 'agent', 'fuel_reserve', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(85, 'agent', 'warehouse', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(86, 'agent', 'pos', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(87, 'agent', 'expenses', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(88, 'agent', 'reports', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(89, 'agent', 'users', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(90, 'agent', 'settings', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(91, 'agent', 'maintenance', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(92, 'agent', 'action_control', 1, 0, 0, 0, 0, 1, 0, '2026-07-17 00:14:13'),
(93, 'maintenance', 'dashboard', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(94, 'maintenance', 'buildings', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(95, 'maintenance', 'apartments', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(96, 'maintenance', 'tenants', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(97, 'maintenance', 'contracts', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(98, 'maintenance', 'rent', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(99, 'maintenance', 'insurance', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(100, 'maintenance', 'workshop', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(101, 'maintenance', 'constructions', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(102, 'maintenance', 'suppliers', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(103, 'maintenance', 'purchase_orders', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(104, 'maintenance', 'sales', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(105, 'maintenance', 'energy', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(106, 'maintenance', 'generators', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(107, 'maintenance', 'fuel_reserve', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(108, 'maintenance', 'warehouse', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(109, 'maintenance', 'pos', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(110, 'maintenance', 'expenses', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(111, 'maintenance', 'reports', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(112, 'maintenance', 'users', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(113, 'maintenance', 'settings', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(114, 'maintenance', 'maintenance', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(115, 'maintenance', 'action_control', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(116, 'tenant', 'dashboard', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(117, 'tenant', 'buildings', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(118, 'tenant', 'apartments', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(119, 'tenant', 'tenants', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(120, 'tenant', 'contracts', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(121, 'tenant', 'rent', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(122, 'tenant', 'insurance', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(123, 'tenant', 'workshop', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(124, 'tenant', 'constructions', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(125, 'tenant', 'suppliers', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(126, 'tenant', 'purchase_orders', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(127, 'tenant', 'sales', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(128, 'tenant', 'energy', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(129, 'tenant', 'generators', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(130, 'tenant', 'fuel_reserve', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(131, 'tenant', 'warehouse', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(132, 'tenant', 'pos', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(133, 'tenant', 'expenses', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(134, 'tenant', 'reports', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(135, 'tenant', 'users', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(136, 'tenant', 'settings', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(137, 'tenant', 'maintenance', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13'),
(138, 'tenant', 'action_control', 1, 0, 0, 0, 0, 0, 0, '2026-07-17 00:14:13');

-- --------------------------------------------------------

--
-- Table structure for table `permission_profiles`
--

CREATE TABLE `permission_profiles` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `description` text DEFAULT NULL,
  `base_role` varchar(50) NOT NULL DEFAULT 'manager' COMMENT 'admin|manager|cashier|agent|maintenance|tenant',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `code` varchar(100) DEFAULT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `barcode` varchar(100) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `unit` varchar(50) DEFAULT NULL,
  `cost_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `tva` decimal(5,2) NOT NULL DEFAULT 0.00,
  `selling_price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `quantity` int(11) NOT NULL DEFAULT 0,
  `minimum_quantity` int(11) NOT NULL DEFAULT 0,
  `description` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_construction_material` tinyint(1) DEFAULT 0,
  `name_fr` varchar(255) DEFAULT NULL,
  `name_ar` varchar(255) DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `name`, `code`, `reference`, `barcode`, `category`, `unit`, `cost_price`, `tva`, `selling_price`, `quantity`, `minimum_quantity`, `description`, `created_at`, `is_construction_material`, `name_fr`, `name_ar`, `deleted_at`, `deleted_by`) VALUES
(1, 'test', NULL, '1504456', NULL, NULL, NULL, 500.00, 19.00, 595.00, 31, 10, NULL, '2026-06-19 20:20:34', 0, NULL, NULL, NULL, NULL),
(2, 'lamba', NULL, '454556', NULL, NULL, NULL, 10.00, 19.00, 11.90, 202, 20, NULL, '2026-06-19 21:11:13', 0, NULL, NULL, NULL, NULL),
(3, 'shret kahrba', NULL, '15156', NULL, NULL, NULL, 520.00, 19.00, 618.80, 4209, 110, NULL, '2026-06-19 21:11:36', 0, NULL, NULL, NULL, NULL),
(4, 'trabe', NULL, '45456', NULL, NULL, NULL, 151.00, 19.00, 179.69, 99999989, 100000, NULL, '2026-06-19 21:12:27', 0, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `product_depots`
--

CREATE TABLE `product_depots` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `depot_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `product_depots`
--

INSERT INTO `product_depots` (`id`, `product_id`, `depot_id`, `quantity`) VALUES
(1, 1, 1, 31),
(2, 2, 1, 202),
(3, 3, 1, 4195),
(4, 4, 1, 99999989),
(5, 1, 2, 0),
(6, 2, 2, 0),
(7, 3, 2, 14),
(8, 4, 2, 0);

-- --------------------------------------------------------

--
-- Table structure for table `product_price_history`
--

CREATE TABLE `product_price_history` (
  `id` int(11) NOT NULL,
  `product_id` int(11) DEFAULT NULL,
  `price` decimal(10,2) DEFAULT NULL,
  `changed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `changed_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `purchase_orders`
--

CREATE TABLE `purchase_orders` (
  `id` int(11) NOT NULL,
  `po_number` varchar(100) NOT NULL,
  `supplier_id` int(11) DEFAULT NULL,
  `construction_id` int(11) DEFAULT NULL,
  `item_name` varchar(255) DEFAULT NULL,
  `quantity_ordered` decimal(10,2) DEFAULT NULL,
  `quantity_delivered` decimal(10,2) DEFAULT 0.00,
  `quantity_remaining` decimal(10,2) DEFAULT NULL,
  `unit_price` decimal(10,2) DEFAULT NULL,
  `tva` decimal(5,2) DEFAULT 0.00,
  `total_price` decimal(10,2) DEFAULT NULL,
  `expected_delivery_date` date DEFAULT NULL,
  `status` enum('Draft','Pending Approval','Approved','Rejected','Partially Delivered','Delivered','Cancelled') DEFAULT 'Draft',
  `payment_status` enum('Unpaid','Partially Paid','Paid') DEFAULT 'Unpaid',
  `amount_paid` decimal(10,2) DEFAULT 0.00,
  `remaining_balance` decimal(10,2) DEFAULT NULL,
  `payment_due_date` date DEFAULT NULL,
  `attachment_url` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `invoice_date` date DEFAULT NULL,
  `due_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `purchase_orders`
--

INSERT INTO `purchase_orders` (`id`, `po_number`, `supplier_id`, `construction_id`, `item_name`, `quantity_ordered`, `quantity_delivered`, `quantity_remaining`, `unit_price`, `tva`, `total_price`, `expected_delivery_date`, `status`, `payment_status`, `amount_paid`, `remaining_balance`, `payment_due_date`, `attachment_url`, `notes`, `created_at`, `created_by`, `invoice_date`, `due_date`) VALUES
(1, 'PO-20260628-3607', 1, 1, 'cement', 1500.00, 15000.00, -13500.00, 100.00, 0.00, 150000.00, '2026-06-28', 'Delivered', 'Unpaid', 0.00, NULL, NULL, NULL, NULL, '2026-06-28 17:59:24', 1, NULL, NULL),
(2, 'PO-20260628-4295', 1, 2, 'Cement', 754545.00, 754545.00, 0.00, 100.00, 0.00, 75454500.00, '2026-06-28', 'Delivered', 'Unpaid', 0.00, NULL, NULL, NULL, NULL, '2026-06-28 18:07:21', 1, NULL, NULL),
(3, 'PO-20260628-5618', 1, 2, 'Cement', 10.00, 10.00, 0.00, 100.00, 0.00, 1000.00, '0000-00-00', 'Delivered', 'Unpaid', 0.00, NULL, NULL, NULL, NULL, '2026-06-28 18:20:56', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `purchase_requests`
--

CREATE TABLE `purchase_requests` (
  `id` int(11) NOT NULL,
  `project_id` int(11) DEFAULT NULL,
  `item_id` int(11) DEFAULT NULL,
  `quantity_needed` decimal(10,2) NOT NULL,
  `estimated_cost` decimal(10,2) NOT NULL,
  `status` varchar(50) DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reading_audit_logs`
--

CREATE TABLE `reading_audit_logs` (
  `id` int(11) NOT NULL,
  `reading_type` enum('Generator','Apartment') NOT NULL,
  `reading_id` int(11) NOT NULL,
  `action` varchar(50) NOT NULL,
  `old_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `performed_by` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `reading_versions`
--

CREATE TABLE `reading_versions` (
  `id` int(11) NOT NULL,
  `reading_id` int(11) NOT NULL,
  `reading_type` enum('electricity','subscription','generator') NOT NULL,
  `version_number` int(11) DEFAULT 1,
  `previous_reading` decimal(12,2) DEFAULT NULL,
  `current_reading` decimal(12,2) DEFAULT NULL,
  `consumption` decimal(12,2) DEFAULT NULL,
  `reading_date` date DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `photo_path` varchar(500) DEFAULT NULL,
  `edited_by` int(11) DEFAULT NULL,
  `edit_reason` text DEFAULT NULL,
  `snapshot` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`snapshot`)),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `renewal_requests`
--

CREATE TABLE `renewal_requests` (
  `id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `status` enum('Requested','Declined','Approved','Pending') DEFAULT 'Pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rent_collection_requests`
--

CREATE TABLE `rent_collection_requests` (
  `id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `rent_period_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `status` enum('PENDING_RESPONSE','DENIED','SCHEDULED','COLLECTED','COMPLETED','CANCELLED','EXPIRED') DEFAULT 'PENDING_RESPONSE',
  `denial_reason` text DEFAULT NULL,
  `requested_collection_date` date DEFAULT NULL,
  `assigned_agent_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `confirmed_at` datetime DEFAULT NULL,
  `denied_at` datetime DEFAULT NULL,
  `collected_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rent_invoices`
--

CREATE TABLE `rent_invoices` (
  `id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `rent_profile_id` int(11) DEFAULT NULL,
  `invoice_number` varchar(100) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `period_start` date DEFAULT NULL,
  `period_end` date DEFAULT NULL,
  `due_date` date NOT NULL,
  `status` enum('Unpaid','Partial','Paid','Overdue','Voided') DEFAULT 'Unpaid',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `payment_method` enum('Cash','Bank Transfer','Mobile Money','Cheque','Other') DEFAULT NULL,
  `payment_date` date DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `account_number` varchar(100) DEFAULT NULL,
  `proof_of_payment` varchar(255) DEFAULT NULL,
  `rent_period_id` int(11) DEFAULT NULL,
  `qr_requested_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rent_invoices`
--

INSERT INTO `rent_invoices` (`id`, `contract_id`, `rent_profile_id`, `invoice_number`, `amount`, `period_start`, `period_end`, `due_date`, `status`, `notes`, `created_at`, `payment_method`, `payment_date`, `reference_number`, `bank_name`, `account_number`, `proof_of_payment`, `rent_period_id`, `qr_requested_at`) VALUES
(117, 18, NULL, 'INV-202610-18', 720000.00, '2026-10-10', '2026-11-09', '2026-11-09', 'Paid', NULL, '2026-07-22 20:03:57', 'Cash', '2026-08-09', '', NULL, NULL, NULL, NULL, NULL),
(118, 19, NULL, 'INV-202607-19', 840000.00, '2026-07-10', '2026-08-09', '2026-08-09', 'Paid', NULL, '2026-07-22 20:26:30', 'Cash', '2026-08-07', '', NULL, NULL, NULL, NULL, NULL),
(121, 22, NULL, 'INV-202607-22', 210000.00, '2026-07-15', '2026-08-14', '2026-08-14', 'Paid', NULL, '2026-08-06 21:17:19', 'Cash', '2026-08-08', '', NULL, NULL, NULL, NULL, NULL),
(122, 19, NULL, 'INV-20260807-19-1', 840000.00, NULL, NULL, '2026-07-10', 'Paid', NULL, '2026-08-06 22:01:50', 'Cash', '2026-08-09', '', NULL, NULL, NULL, 1, '2026-08-09 01:34:05'),
(123, 22, NULL, 'INV-20260807-22-2', 210000.00, NULL, NULL, '2026-07-15', 'Partial', NULL, '2026-08-06 22:01:50', 'Cash', '2026-08-09', '', NULL, NULL, NULL, 2, '2026-08-09 01:36:39'),
(124, 23, NULL, 'INV-202610-23', 855000.00, '2026-10-10', '2026-11-09', '2026-11-09', 'Voided', NULL, '2026-08-23 19:14:41', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(125, 22, NULL, 'INV-202609-22', 210000.00, '2026-09-15', '2026-10-14', '2026-09-15', 'Overdue', NULL, '2026-09-21 20:27:04', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(126, 19, NULL, 'INV-202608-19', 840000.00, '2026-08-10', '2026-09-09', '2026-08-10', 'Unpaid', NULL, '2026-09-21 20:31:52', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(127, 19, NULL, 'INV-202609-19', 840000.00, '2026-09-10', '2026-10-09', '2026-09-10', 'Unpaid', NULL, '2026-09-21 20:31:52', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(213, 35, NULL, 'INV-20260421-35-88', 500.00, NULL, NULL, '2026-04-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 88, NULL),
(214, 35, NULL, 'INV-20260521-35-89', 500.00, NULL, NULL, '2026-05-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 89, NULL),
(215, 35, NULL, 'INV-20260621-35-90', 500.00, NULL, NULL, '2026-06-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 90, NULL),
(216, 35, NULL, 'INV-20260721-35-91', 500.00, NULL, NULL, '2026-07-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 91, NULL),
(217, 35, NULL, 'INV-20260821-35-92', 500.00, NULL, NULL, '2026-08-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 92, NULL),
(218, 36, NULL, 'INV-20260421-36-93', 650.00, NULL, NULL, '2026-04-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 93, NULL),
(219, 36, NULL, 'INV-20260521-36-94', 650.00, NULL, NULL, '2026-05-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 94, NULL),
(220, 36, NULL, 'INV-20260621-36-95', 650.00, NULL, NULL, '2026-06-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 95, NULL),
(221, 36, NULL, 'INV-20260721-36-96', 650.00, NULL, NULL, '2026-07-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 96, NULL),
(222, 36, NULL, 'INV-20260821-36-97', 650.00, NULL, NULL, '2026-08-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 97, NULL),
(223, 37, NULL, 'INV-20260421-37-98', 550.00, NULL, NULL, '2026-04-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 98, NULL),
(224, 37, NULL, 'INV-20260521-37-99', 550.00, NULL, NULL, '2026-05-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 99, NULL),
(225, 37, NULL, 'INV-20260621-37-100', 550.00, NULL, NULL, '2026-06-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 100, NULL),
(226, 37, NULL, 'INV-20260721-37-101', 550.00, NULL, NULL, '2026-07-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 101, NULL),
(227, 37, NULL, 'INV-20260821-37-102', 550.00, NULL, NULL, '2026-08-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 102, NULL),
(228, 38, NULL, 'INV-20260421-38-103', 700.00, NULL, NULL, '2026-04-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 103, NULL),
(229, 38, NULL, 'INV-20260521-38-104', 700.00, NULL, NULL, '2026-05-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 104, NULL),
(230, 38, NULL, 'INV-20260621-38-105', 700.00, NULL, NULL, '2026-06-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 105, NULL),
(231, 38, NULL, 'INV-20260721-38-106', 700.00, NULL, NULL, '2026-07-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 106, NULL),
(232, 38, NULL, 'INV-20260821-38-107', 700.00, NULL, NULL, '2026-08-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 107, NULL),
(233, 39, NULL, 'INV-20260421-39-108', 480.00, NULL, NULL, '2026-04-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 108, NULL),
(234, 39, NULL, 'INV-20260521-39-109', 480.00, NULL, NULL, '2026-05-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 109, NULL),
(235, 39, NULL, 'INV-20260621-39-110', 480.00, NULL, NULL, '2026-06-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 110, NULL),
(236, 39, NULL, 'INV-20260721-39-111', 480.00, NULL, NULL, '2026-07-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 111, NULL),
(237, 39, NULL, 'INV-20260821-39-112', 480.00, NULL, NULL, '2026-08-21', 'Paid', NULL, '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, NULL, NULL, 112, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `rent_payments`
--

CREATE TABLE `rent_payments` (
  `id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `date` date NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `approval_status` enum('Pending','Approved') DEFAULT 'Approved'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rent_payments`
--

INSERT INTO `rent_payments` (`id`, `invoice_id`, `amount`, `date`, `user_id`, `notes`, `created_at`, `approval_status`) VALUES
(26, 118, 840000.00, '2026-08-07', 5, '', '2026-08-06 22:22:28', 'Approved'),
(27, 121, 210000.00, '2026-08-08', 5, '', '2026-08-07 21:17:47', 'Approved'),
(28, 117, 720000.00, '2026-08-09', 5, 'Agent Wizard', '2026-08-08 21:48:00', 'Approved'),
(29, 122, 840000.00, '2026-08-09', 5, 'Agent Wizard', '2026-08-08 22:34:33', 'Approved'),
(30, 123, 3000.00, '2026-08-09', 5, 'Agent Wizard', '2026-08-08 22:37:03', 'Approved');

-- --------------------------------------------------------

--
-- Table structure for table `rent_periods`
--

CREATE TABLE `rent_periods` (
  `id` int(11) NOT NULL,
  `contract_id` int(11) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rent_periods`
--

INSERT INTO `rent_periods` (`id`, `contract_id`, `start_date`, `end_date`, `created_at`) VALUES
(1, 19, '2026-07-10', '2026-08-10', '2026-08-06 22:01:50'),
(2, 22, '2026-07-15', '2026-08-15', '2026-08-06 22:01:50'),
(88, 35, '2026-04-21', '2026-05-21', '2026-09-21 21:53:40'),
(89, 35, '2026-05-21', '2026-06-21', '2026-09-21 21:53:40'),
(90, 35, '2026-06-21', '2026-07-21', '2026-09-21 21:53:40'),
(91, 35, '2026-07-21', '2026-08-21', '2026-09-21 21:53:40'),
(92, 35, '2026-08-21', '2026-09-21', '2026-09-21 21:53:40'),
(93, 36, '2026-04-21', '2026-05-21', '2026-09-21 21:53:40'),
(94, 36, '2026-05-21', '2026-06-21', '2026-09-21 21:53:40'),
(95, 36, '2026-06-21', '2026-07-21', '2026-09-21 21:53:40'),
(96, 36, '2026-07-21', '2026-08-21', '2026-09-21 21:53:40'),
(97, 36, '2026-08-21', '2026-09-21', '2026-09-21 21:53:40'),
(98, 37, '2026-04-21', '2026-05-21', '2026-09-21 21:53:40'),
(99, 37, '2026-05-21', '2026-06-21', '2026-09-21 21:53:40'),
(100, 37, '2026-06-21', '2026-07-21', '2026-09-21 21:53:40'),
(101, 37, '2026-07-21', '2026-08-21', '2026-09-21 21:53:40'),
(102, 37, '2026-08-21', '2026-09-21', '2026-09-21 21:53:40'),
(103, 38, '2026-04-21', '2026-05-21', '2026-09-21 21:53:40'),
(104, 38, '2026-05-21', '2026-06-21', '2026-09-21 21:53:40'),
(105, 38, '2026-06-21', '2026-07-21', '2026-09-21 21:53:40'),
(106, 38, '2026-07-21', '2026-08-21', '2026-09-21 21:53:40'),
(107, 38, '2026-08-21', '2026-09-21', '2026-09-21 21:53:40'),
(108, 39, '2026-04-21', '2026-05-21', '2026-09-21 21:53:40'),
(109, 39, '2026-05-21', '2026-06-21', '2026-09-21 21:53:40'),
(110, 39, '2026-06-21', '2026-07-21', '2026-09-21 21:53:40'),
(111, 39, '2026-07-21', '2026-08-21', '2026-09-21 21:53:40'),
(112, 39, '2026-08-21', '2026-09-21', '2026-09-21 21:53:40');

-- --------------------------------------------------------

--
-- Table structure for table `rent_profiles`
--

CREATE TABLE `rent_profiles` (
  `id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `contract_id` int(11) DEFAULT NULL,
  `rent_start_date` date NOT NULL,
  `monthly_amount` decimal(10,2) NOT NULL,
  `next_billing_date` date DEFAULT NULL,
  `billing_frequency` enum('Weekly','Monthly','Quarterly','Yearly') DEFAULT 'Monthly',
  `status` enum('Active','Paused','Closed') DEFAULT 'Active',
  `auto_renewal` tinyint(1) DEFAULT 0,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `default_payment_method` enum('Cash','Bank Transfer','Mobile Money','Cheque','Other') DEFAULT 'Cash'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rent_profiles`
--

INSERT INTO `rent_profiles` (`id`, `tenant_id`, `apartment_id`, `contract_id`, `rent_start_date`, `monthly_amount`, `next_billing_date`, `billing_frequency`, `status`, `auto_renewal`, `notes`, `created_at`, `updated_at`, `default_payment_method`) VALUES
(8, 15, 11, 18, '2026-10-10', 720000.00, '2026-12-10', 'Monthly', 'Active', 0, 'Auto-created on tenant registration', '2026-07-22 20:03:57', '2026-07-22 20:03:57', 'Cash'),
(9, 16, 12, 19, '2026-07-10', 840000.00, '2026-09-10', 'Monthly', 'Active', 1, 'Auto-created on tenant registration', '2026-07-22 20:26:30', '2026-09-23 22:57:47', 'Cash'),
(12, 19, 14, 22, '2026-07-15', 210000.00, '2026-10-15', 'Monthly', 'Active', 1, 'Auto-created on tenant registration', '2026-08-06 21:17:19', '2026-09-21 20:27:04', 'Cash'),
(13, 20, 13, 23, '2026-10-10', 855000.00, '2026-12-10', 'Monthly', 'Active', 0, 'Auto-created on tenant registration', '2026-08-23 19:14:41', '2026-08-23 19:14:41', 'Cash'),
(25, 32, 26, 35, '2026-04-21', 500.00, '2026-09-21', 'Monthly', 'Active', 1, NULL, '2026-09-21 21:53:40', '2026-09-21 21:53:40', 'Cash'),
(26, 33, 27, 36, '2026-04-21', 650.00, '2026-09-21', 'Monthly', 'Active', 1, NULL, '2026-09-21 21:53:40', '2026-09-21 21:53:40', 'Cash'),
(27, 34, 28, 37, '2026-04-21', 550.00, '2026-09-21', 'Monthly', 'Active', 1, NULL, '2026-09-21 21:53:40', '2026-09-21 21:53:40', 'Cash'),
(28, 35, 29, 38, '2026-04-21', 700.00, '2026-09-21', 'Monthly', 'Active', 1, NULL, '2026-09-21 21:53:40', '2026-09-21 21:53:40', 'Cash'),
(29, 36, 30, 39, '2026-04-21', 480.00, '2026-09-21', 'Monthly', 'Active', 1, NULL, '2026-09-21 21:53:40', '2026-09-21 21:53:40', 'Cash');

-- --------------------------------------------------------

--
-- Table structure for table `rent_profile_history`
--

CREATE TABLE `rent_profile_history` (
  `id` int(11) NOT NULL,
  `rent_profile_id` int(11) NOT NULL,
  `action` varchar(100) NOT NULL,
  `previous_value` varchar(255) DEFAULT NULL,
  `new_value` varchar(255) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `rent_profile_history`
--

INSERT INTO `rent_profile_history` (`id`, `rent_profile_id`, `action`, `previous_value`, `new_value`, `notes`, `user_id`, `created_at`) VALUES
(20, 12, 'Auto Renewal Changed', 'Off', 'On', 'Updated manually via API', 1, '2026-08-23 18:36:39'),
(21, 12, 'Auto Renewal Changed', 'On', 'Off', 'Updated manually via API', 1, '2026-08-23 18:36:44'),
(22, 12, 'Auto Renewal Changed', 'Off', 'On', 'Updated manually via API', 1, '2026-09-21 20:26:52'),
(23, 9, 'Auto Renewal Changed', 'Off', 'On', 'Updated manually via API', 1, '2026-09-23 22:57:47');

-- --------------------------------------------------------

--
-- Table structure for table `returns`
--

CREATE TABLE `returns` (
  `id` int(11) NOT NULL,
  `original_invoice_id` int(11) NOT NULL,
  `return_invoice_number` varchar(100) NOT NULL,
  `date` date NOT NULL,
  `total_refunded` decimal(10,2) NOT NULL DEFAULT 0.00,
  `reason` text DEFAULT NULL,
  `created_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `status` enum('Pending','Approved','Rejected','Completed') DEFAULT 'Completed',
  `photo` varchar(255) DEFAULT NULL,
  `manager_approval_id` int(11) DEFAULT NULL,
  `refund_method` enum('Cash','Bank','Account Credit','Store Credit') DEFAULT 'Cash'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `return_items`
--

CREATE TABLE `return_items` (
  `id` int(11) NOT NULL,
  `return_id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `quantity` int(11) NOT NULL,
  `price` decimal(10,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `return_condition` enum('Good','Damaged','Expired','Lost Packaging') DEFAULT 'Good'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `rich_audit_logs`
--

CREATE TABLE `rich_audit_logs` (
  `id` int(11) NOT NULL,
  `object_type` varchar(100) NOT NULL,
  `object_id` int(11) NOT NULL,
  `old_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_value`)),
  `new_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_value`)),
  `changed_by` int(11) NOT NULL,
  `role` varchar(50) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `gps_location` varchar(100) DEFAULT NULL,
  `photo_path` varchar(255) DEFAULT NULL,
  `comment` text DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `sales_audits`
--

CREATE TABLE `sales_audits` (
  `id` int(11) NOT NULL,
  `invoice_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `action` varchar(50) NOT NULL,
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_values`)),
  `reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `ip_address` varchar(45) DEFAULT NULL,
  `device` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `scheduled_jobs`
--

CREATE TABLE `scheduled_jobs` (
  `id` int(11) NOT NULL,
  `job_name` varchar(100) NOT NULL,
  `status` enum('Success','Failed','Pending','Running','Disabled') DEFAULT 'Pending',
  `duration_seconds` int(11) DEFAULT 0,
  `records_processed` int(11) DEFAULT 0,
  `last_run` timestamp NULL DEFAULT NULL,
  `next_run` timestamp NULL DEFAULT NULL,
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `scheduled_jobs`
--

INSERT INTO `scheduled_jobs` (`id`, `job_name`, `status`, `duration_seconds`, `records_processed`, `last_run`, `next_run`, `error_message`, `created_at`) VALUES
(1, 'Notification Scheduler', 'Success', 0, 0, '2026-08-06 22:01:13', NULL, NULL, '2026-08-06 22:01:13'),
(2, 'Daily Rent Scheduler', 'Success', 0, 2, '2026-08-06 22:01:50', NULL, NULL, '2026-08-06 22:01:50');

-- --------------------------------------------------------

--
-- Table structure for table `security_activity_log`
--

CREATE TABLE `security_activity_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `role` varchar(50) DEFAULT NULL,
  `action` varchar(100) NOT NULL COMMENT 'login, failed_login, password_reset, permission_changed',
  `description` text DEFAULT NULL,
  `status` enum('success','warning','error','info') NOT NULL DEFAULT 'success',
  `severity` enum('low','medium','high','critical') NOT NULL DEFAULT 'medium',
  `ip_address` varchar(45) DEFAULT NULL,
  `device_info` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `security_events`
--

CREATE TABLE `security_events` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(200) DEFAULT NULL,
  `event_type` varchar(100) NOT NULL COMMENT 'failed_login|bulk_delete|permission_escalation|data_export|...',
  `severity` enum('info','warning','critical') NOT NULL DEFAULT 'info',
  `description` text NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `security_events`
--

INSERT INTO `security_events` (`id`, `user_id`, `user_name`, `event_type`, `severity`, `description`, `ip_address`, `user_agent`, `metadata`, `created_at`) VALUES
(1, 1, NULL, 'permission_update', 'info', 'Updated page permissions for role: cashier', '::1', NULL, NULL, '2026-07-19 00:00:15'),
(2, 1, NULL, 'permission_update', 'info', 'Updated page permissions for role: manager', '::1', NULL, NULL, '2026-07-19 00:11:19'),
(3, 1, NULL, 'permission_update', 'info', 'Updated page permissions for role: agent', '::1', NULL, NULL, '2026-07-19 00:11:26'),
(4, 1, NULL, 'permission_update', 'info', 'Updated page permissions for role: maintenance', '::1', NULL, NULL, '2026-07-19 00:11:31'),
(5, 1, NULL, 'permission_update', 'info', 'Updated page permissions for role: tenant', '::1', NULL, NULL, '2026-07-19 00:11:36');

-- --------------------------------------------------------

--
-- Table structure for table `stock_movements`
--

CREATE TABLE `stock_movements` (
  `id` int(11) NOT NULL,
  `product_id` int(11) NOT NULL,
  `type` enum('IN','OUT') NOT NULL,
  `quantity` int(11) NOT NULL,
  `reference_type` varchar(100) DEFAULT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `date` datetime NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `stock_movements`
--

INSERT INTO `stock_movements` (`id`, `product_id`, `type`, `quantity`, `reference_type`, `reference_id`, `date`, `created_at`) VALUES
(1, 1, 'IN', 50, 'Manual', NULL, '2026-06-19 23:20:34', '2026-06-19 20:20:34'),
(2, 1, 'OUT', 2, 'Invoice', 1, '2026-06-19 23:55:12', '2026-06-19 20:55:12'),
(3, 1, 'OUT', 12, 'Invoice', 2, '2026-06-19 23:56:56', '2026-06-19 20:56:56'),
(4, 2, 'IN', 255, 'Manual', NULL, '2026-06-20 00:11:13', '2026-06-19 21:11:13'),
(5, 3, 'IN', 5456, 'Manual', NULL, '2026-06-20 00:11:36', '2026-06-19 21:11:36'),
(6, 4, 'IN', 100000000, 'Manual', NULL, '2026-06-20 00:12:27', '2026-06-19 21:12:27'),
(7, 2, 'OUT', 6, 'Invoice', 3, '2026-06-20 00:12:50', '2026-06-19 21:12:50'),
(8, 3, 'OUT', 1, 'Invoice', 4, '2026-06-20 00:17:02', '2026-06-19 21:17:02'),
(9, 2, 'OUT', 1, 'Invoice', 4, '2026-06-20 00:17:02', '2026-06-19 21:17:02'),
(10, 1, 'OUT', 1, 'Invoice', 4, '2026-06-20 00:17:02', '2026-06-19 21:17:02'),
(11, 3, 'OUT', 1, 'Invoice', 5, '2026-06-20 00:29:55', '2026-06-19 21:29:55'),
(12, 4, 'OUT', 1, 'Invoice', 5, '2026-06-20 00:29:55', '2026-06-19 21:29:55'),
(13, 2, 'OUT', 1, 'Invoice', 5, '2026-06-20 00:29:55', '2026-06-19 21:29:55'),
(14, 1, 'OUT', 1, 'Invoice', 5, '2026-06-20 00:29:55', '2026-06-19 21:29:55'),
(15, 2, 'OUT', 28, 'Invoice', 6, '2026-06-20 00:30:32', '2026-06-19 21:30:32'),
(16, 1, 'OUT', 1, 'Invoice', 6, '2026-06-20 00:30:32', '2026-06-19 21:30:32'),
(17, 3, 'OUT', 1, 'Invoice', 6, '2026-06-20 00:30:32', '2026-06-19 21:30:32'),
(18, 2, 'OUT', 3, 'Invoice', 7, '2026-06-20 00:32:40', '2026-06-19 21:32:40'),
(19, 3, 'OUT', 2, 'Invoice', 7, '2026-06-20 00:32:40', '2026-06-19 21:32:40'),
(20, 4, 'OUT', 2, 'Invoice', 7, '2026-06-20 00:32:40', '2026-06-19 21:32:40'),
(21, 1, 'OUT', 1, 'Invoice', 7, '2026-06-20 00:32:40', '2026-06-19 21:32:40'),
(22, 4, 'OUT', 2, 'Invoice', 8, '2026-06-20 00:37:08', '2026-06-19 21:37:08'),
(23, 3, 'OUT', 1, 'Invoice', 8, '2026-06-20 00:37:08', '2026-06-19 21:37:08'),
(24, 3, 'OUT', 1, 'Invoice', 9, '2026-06-20 00:55:59', '2026-06-19 21:55:59'),
(25, 3, 'OUT', 110, 'Invoice', 10, '2026-06-20 01:56:21', '2026-06-19 22:56:21'),
(26, 2, 'OUT', 1, 'Invoice', 10, '2026-06-20 01:56:21', '2026-06-19 22:56:21'),
(27, 2, 'OUT', 1, 'Invoice', 11, '2026-06-20 02:08:53', '2026-06-19 23:08:53'),
(28, 3, 'OUT', 1, 'Invoice', 11, '2026-06-20 02:08:53', '2026-06-19 23:08:53'),
(29, 2, 'OUT', 10, 'Invoice Edit', 11, '2026-06-20 02:10:26', '2026-06-19 23:10:26'),
(30, 4, 'OUT', 1, 'Invoice', 12, '2026-06-22 23:30:16', '2026-06-22 20:30:16'),
(31, 3, 'OUT', 1, 'Invoice', 12, '2026-06-22 23:30:16', '2026-06-22 20:30:16'),
(32, 3, 'OUT', 11, 'Invoice', 13, '2026-06-22 23:33:23', '2026-06-22 20:33:23'),
(33, 3, 'OUT', 1100, 'Invoice', 14, '2026-06-22 23:33:47', '2026-06-22 20:33:47'),
(34, 3, 'OUT', 14, 'Transfer Out', 1, '2026-07-01 22:38:15', '2026-07-01 19:38:15'),
(35, 3, 'IN', 14, 'Transfer In', 1, '2026-07-01 22:38:15', '2026-07-01 19:38:15'),
(36, 2, 'OUT', 2, 'Invoice', 15, '2026-07-01 23:33:01', '2026-07-01 20:33:01'),
(37, 3, 'OUT', 16, 'Invoice', 15, '2026-07-01 23:33:01', '2026-07-01 20:33:01'),
(38, 4, 'OUT', 4, 'Invoice', 15, '2026-07-01 23:33:01', '2026-07-01 20:33:01'),
(39, 3, 'OUT', 1, 'Invoice', 16, '2026-07-19 23:39:20', '2026-07-19 20:39:20'),
(40, 4, 'OUT', 1, 'Invoice', 16, '2026-07-19 23:39:20', '2026-07-19 20:39:20'),
(41, 1, 'OUT', 1, 'Invoice', 17, '2026-07-19 23:42:49', '2026-07-19 20:42:49');

-- --------------------------------------------------------

--
-- Table structure for table `subscription_history`
--

CREATE TABLE `subscription_history` (
  `id` int(11) NOT NULL,
  `subscription_id` int(11) NOT NULL,
  `action` varchar(255) NOT NULL,
  `previous_value` text DEFAULT NULL,
  `new_value` text DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `performed_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subscription_history`
--

INSERT INTO `subscription_history` (`id`, `subscription_id`, `action`, `previous_value`, `new_value`, `reason`, `performed_by`, `created_at`) VALUES
(1, 17, 'Created', NULL, '{\"type\":\"Fixed Amp\",\"monthly_fee\":150000,\"amps\":10,\"cost_per_amp\":15000,\"status\":\"Active\"}', 'New Subscription', 1, '2026-07-25 21:13:22'),
(2, 18, 'Created', NULL, '{\"type\":\"Meter\",\"monthly_fee\":0,\"amps\":0,\"cost_per_amp\":0,\"status\":\"Active\"}', 'New Subscription', 1, '2026-07-25 21:13:43'),
(3, 18, 'Updated', '{\"id\":\"18\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"monthly_fee\":\"0.00\",\"amps\":\"0.00\",\"cost_per_amp\":\"0.00\",\"start_date\":\"2026-07-25\",\"end_date\":\"2026-08-25\",\"status\":\"Active\",\"created_at\":\"2026-07-26 00:13:43\",\"next_billing_date\":\"2026-08-25\",\"last_meter_reading\":null,\"price_per_kwh\":null}', '{\"id\":\"18\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"monthly_fee\":0,\"amps\":0,\"cost_per_amp\":0,\"start_date\":\"2026-07-25\",\"end_date\":\"2026-08-25\",\"status\":\"Active\",\"created_at\":\"2026-07-26 00:13:43\",\"next_billing_date\":\"2026-08-25\",\"last_meter_reading\":null,\"price_per_kwh\":null}', 'Admin Update', 1, '2026-07-25 21:21:19'),
(4, 18, 'Updated', '{\"id\":\"18\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"monthly_fee\":\"0.00\",\"amps\":\"0.00\",\"cost_per_amp\":\"0.00\",\"start_date\":\"2026-07-25\",\"end_date\":\"2026-08-25\",\"status\":\"Active\",\"created_at\":\"2026-07-26 00:13:43\",\"next_billing_date\":\"2026-09-25\",\"last_meter_reading\":\"1.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"18\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"monthly_fee\":0,\"amps\":0,\"cost_per_amp\":0,\"start_date\":\"2026-07-25\",\"end_date\":\"2026-08-25\",\"status\":\"Active\",\"created_at\":\"2026-07-26 00:13:43\",\"next_billing_date\":\"2026-09-25\",\"last_meter_reading\":\"1.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-07-26 20:49:05'),
(5, 19, 'Created', NULL, '{\"type\":\"Meter\",\"monthly_fee\":0,\"amps\":0,\"cost_per_amp\":0,\"status\":\"Active\"}', 'New Subscription', 1, '2026-07-26 20:53:44'),
(6, 19, 'Updated', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Meter\",\"monthly_fee\":\"0.00\",\"amps\":\"0.00\",\"cost_per_amp\":\"0.00\",\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-07\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-07\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Fixed Amp\",\"monthly_fee\":250000,\"amps\":5,\"cost_per_amp\":50000,\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-07\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-08-07 21:13:17'),
(7, 19, 'Updated', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Fixed Amp\",\"monthly_fee\":\"250000.00\",\"amps\":\"5.00\",\"cost_per_amp\":\"50000.00\",\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Fixed Monthly\",\"monthly_fee\":250000,\"amps\":5,\"cost_per_amp\":50000,\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-08-07 21:14:10'),
(8, 19, 'Updated', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Fixed Monthly\",\"monthly_fee\":\"250000.00\",\"amps\":\"5.00\",\"cost_per_amp\":\"50000.00\",\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Meter\",\"monthly_fee\":250000,\"amps\":5,\"cost_per_amp\":50000,\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-08-07 21:32:53'),
(9, 19, 'Updated', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Meter\",\"monthly_fee\":\"250000.00\",\"amps\":\"5.00\",\"cost_per_amp\":\"50000.00\",\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Meter\",\"monthly_fee\":250000,\"amps\":5,\"cost_per_amp\":50000,\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-08-07 21:33:10'),
(10, 19, 'Updated', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Meter\",\"monthly_fee\":\"250000.00\",\"amps\":\"5.00\",\"cost_per_amp\":\"50000.00\",\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', '{\"id\":\"19\",\"apartment_id\":\"13\",\"type\":\"Fixed Monthly\",\"monthly_fee\":250000,\"amps\":5,\"cost_per_amp\":50000,\"start_date\":\"2026-08-07\",\"end_date\":\"2026-09-06\",\"status\":\"Active\",\"created_at\":\"2026-07-26 23:53:44\",\"next_billing_date\":\"2026-09-06\",\"last_meter_reading\":\"500.00\",\"price_per_kwh\":\"500.00\"}', 'Admin Update', 1, '2026-08-07 21:33:31');

-- --------------------------------------------------------

--
-- Table structure for table `suppliers`
--

CREATE TABLE `suppliers` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `contact_info` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `supplier_type` set('Fuel','Construction','Electrical','General') DEFAULT 'General',
  `credit_limit` decimal(15,2) DEFAULT 0.00,
  `payment_terms_days` int(11) DEFAULT 30,
  `opening_balance` decimal(15,2) DEFAULT 0.00,
  `opening_balance_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `suppliers`
--

INSERT INTO `suppliers` (`id`, `name`, `contact_info`, `created_at`, `supplier_type`, `credit_limit`, `payment_terms_days`, `opening_balance`, `opening_balance_date`) VALUES
(1, 'suoermarket leader', '56582', '2026-06-28 17:54:26', 'Construction', 0.00, 30, 0.00, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `supplier_payments`
--

CREATE TABLE `supplier_payments` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `payment_date` date NOT NULL,
  `payment_method` varchar(50) DEFAULT NULL,
  `reference_number` varchar(100) DEFAULT NULL,
  `bank_name` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `attachment_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `supplier_payments`
--

INSERT INTO `supplier_payments` (`id`, `supplier_id`, `amount`, `payment_date`, `payment_method`, `reference_number`, `bank_name`, `notes`, `attachment_url`, `created_at`, `created_by`) VALUES
(1, 1, 1000.00, '2026-06-28', 'Cash', 'dfgfd', 'hgjh', 'gsergrs', NULL, '2026-06-28 18:52:49', NULL),
(2, 1, 10000.00, '2026-06-28', 'Cash', '', '', '', NULL, '2026-06-28 18:55:40', NULL),
(3, 1, 150000.00, '2026-08-05', 'Cash', '', '', 'iejdkejfd', NULL, '2026-08-05 20:29:51', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `supplier_payment_allocations`
--

CREATE TABLE `supplier_payment_allocations` (
  `id` int(11) NOT NULL,
  `payment_id` int(11) NOT NULL,
  `purchase_order_id` int(11) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `supplier_transactions`
--

CREATE TABLE `supplier_transactions` (
  `id` int(11) NOT NULL,
  `supplier_id` int(11) NOT NULL,
  `type` enum('Purchase','Payment','Return','Opening Balance','Adjustment') NOT NULL,
  `reference_id` varchar(100) NOT NULL,
  `amount` decimal(15,2) NOT NULL,
  `balance_after` decimal(15,2) DEFAULT 0.00,
  `transaction_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `supplier_transactions`
--

INSERT INTO `supplier_transactions` (`id`, `supplier_id`, `type`, `reference_id`, `amount`, `balance_after`, `transaction_date`, `created_at`) VALUES
(1, 1, 'Purchase', 'PO-20260628-3607', 150000.00, 150000.00, '2026-06-28', '2026-06-28 18:55:01'),
(2, 1, 'Purchase', 'PO-20260628-4295', 75454500.00, 75604500.00, '2026-06-28', '2026-06-28 18:55:01'),
(3, 1, 'Purchase', 'PO-20260628-5618', 1000.00, 75605500.00, '2026-06-28', '2026-06-28 18:55:01'),
(4, 1, 'Payment', 'PAY-1', -1000.00, 75604500.00, '2026-06-28', '2026-06-28 18:55:01'),
(5, 1, 'Payment', 'PAY-2', -10000.00, 75594500.00, '2026-06-28', '2026-06-28 18:55:40'),
(6, 1, 'Payment', 'PAY-3', -150000.00, 75444500.00, '2026-08-05', '2026-08-05 20:29:51');

-- --------------------------------------------------------

--
-- Table structure for table `system_activity_log`
--

CREATE TABLE `system_activity_log` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `action` varchar(100) NOT NULL COMMENT 'backup, restore, cron_job, migration',
  `description` text DEFAULT NULL,
  `status` enum('success','warning','error','info') NOT NULL DEFAULT 'success',
  `severity` enum('low','medium','high','critical') NOT NULL DEFAULT 'low',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tasks`
--

CREATE TABLE `tasks` (
  `id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `type` enum('Rent Collection','Maintenance','Manager Approval','Data Quality') NOT NULL,
  `assigned_to` int(11) DEFAULT NULL,
  `status` enum('Pending','In Progress','Completed','Cancelled','Failed') DEFAULT 'Pending',
  `due_date` date DEFAULT NULL,
  `priority` enum('Low','Normal','High','Urgent') DEFAULT 'Normal',
  `related_entity_type` varchar(50) DEFAULT NULL,
  `related_entity_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tasks`
--

INSERT INTO `tasks` (`id`, `title`, `type`, `assigned_to`, `status`, `due_date`, `priority`, `related_entity_type`, `related_entity_id`, `created_at`, `updated_at`) VALUES
(1, 'Collect Rent - Pending Invoice', 'Rent Collection', 5, 'Completed', '2026-07-10', 'High', 'Contract', 19, '2026-08-06 22:04:34', '2026-08-06 22:22:28'),
(2, 'Collect Rent - Pending Invoice', 'Rent Collection', 5, 'Completed', '2026-07-15', 'High', 'Contract', 22, '2026-08-06 22:04:34', '2026-08-07 21:17:47'),
(3, 'Collect Rent - Pending Invoice', 'Rent Collection', 5, 'Completed', '2026-11-09', 'High', 'Contract', 18, '2026-08-06 22:04:34', '2026-08-08 21:48:00'),
(4, 'Collect Rent - Pending Invoice', 'Rent Collection', 5, 'Pending', '2026-11-09', 'High', 'Contract', 21, '2026-08-06 22:04:34', '2026-08-06 22:04:34');

-- --------------------------------------------------------

--
-- Table structure for table `task_assignment_history`
--

CREATE TABLE `task_assignment_history` (
  `id` int(11) NOT NULL,
  `task_id` int(11) NOT NULL,
  `previous_agent_id` int(11) DEFAULT NULL,
  `new_agent_id` int(11) DEFAULT NULL,
  `action` enum('Assigned','Reassigned','Returned','Completed') NOT NULL,
  `gps_location` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `temp_permissions`
--

CREATE TABLE `temp_permissions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `granted_by` int(11) NOT NULL,
  `permission_type` varchar(100) NOT NULL COMMENT 'edit_contracts|delete_records|view_financial|...',
  `target_table` varchar(100) DEFAULT NULL,
  `target_id` int(11) DEFAULT NULL,
  `expires_at` datetime NOT NULL,
  `reason` text DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `used_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `tenants`
--

CREATE TABLE `tenants` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `full_name` varchar(255) NOT NULL,
  `phone` varchar(50) NOT NULL,
  `email` varchar(255) DEFAULT NULL,
  `national_id` varchar(100) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `address` text DEFAULT NULL,
  `emergency_contact` varchar(255) DEFAULT NULL,
  `passport_url` varchar(255) DEFAULT NULL,
  `id_url` varchar(255) DEFAULT NULL,
  `status` enum('Active','Inactive','Terminated') DEFAULT 'Active',
  `deleted_at` timestamp NULL DEFAULT NULL,
  `deleted_by` int(11) DEFAULT NULL,
  `move_out_date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tenants`
--

INSERT INTO `tenants` (`id`, `user_id`, `full_name`, `phone`, `email`, `national_id`, `created_at`, `address`, `emergency_contact`, `passport_url`, `id_url`, `status`, `deleted_at`, `deleted_by`, `move_out_date`) VALUES
(15, 4, 'ali yazbekk', '81994663', 'ali1@gmail.com', '564564', '2026-07-22 20:03:57', NULL, NULL, NULL, NULL, 'Active', NULL, NULL, NULL),
(16, 4, 'ali yazbekk', '81994663', 'ali1@gmail.com', '564564', '2026-07-22 20:26:30', NULL, NULL, NULL, NULL, 'Terminated', NULL, NULL, '2026-09-24'),
(19, 4, 'ali yazbekk', '81994663', 'ali1@gmail.com', '564564', '2026-08-06 21:17:19', NULL, NULL, NULL, NULL, 'Terminated', NULL, NULL, '2026-09-21'),
(20, 4, 'ali yazbekk', '81994663', 'ali1@gmail.com', '564564', '2026-08-23 19:14:41', NULL, NULL, NULL, NULL, 'Terminated', NULL, NULL, '2026-09-21'),
(32, NULL, 'Rami', '12345678', 'rami@test.com', '12345', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Active', NULL, NULL, NULL),
(33, NULL, 'Sarah', '12345678', 'sarah@test.com', '12345', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Active', NULL, NULL, NULL),
(34, NULL, 'Karim', '12345678', 'karim@test.com', '12345', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Active', NULL, NULL, NULL),
(35, NULL, 'Layla', '12345678', 'layla@test.com', '12345', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Terminated', NULL, NULL, '2026-09-24'),
(36, NULL, 'Omar', '12345678', 'omar@test.com', '12345', '2026-09-21 21:53:40', NULL, NULL, NULL, NULL, 'Terminated', NULL, NULL, '2026-09-22');

-- --------------------------------------------------------

--
-- Table structure for table `tenant_archive_history`
--

CREATE TABLE `tenant_archive_history` (
  `archive_id` int(11) NOT NULL,
  `original_tenant_id` int(11) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `national_id_passport` varchar(100) DEFAULT NULL,
  `past_apartment_number` varchar(50) DEFAULT NULL,
  `termination_date` date DEFAULT NULL,
  `termination_reason` varchar(255) DEFAULT NULL,
  `contact_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`contact_details`)),
  `rental_ledger` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`rental_ledger`)),
  `utility_ledger` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`utility_ledger`)),
  `insurance_records` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`insurance_records`)),
  `maintenance_history` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`maintenance_history`)),
  `archived_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tenant_archive_history`
--

INSERT INTO `tenant_archive_history` (`archive_id`, `original_tenant_id`, `full_name`, `national_id_passport`, `past_apartment_number`, `termination_date`, `termination_reason`, `contact_details`, `rental_ledger`, `utility_ledger`, `insurance_records`, `maintenance_history`, `archived_at`) VALUES
(1, 35, 'Layla', '12345', 'Galaxy - 104', '2026-09-24', 'Lease Terminated', '{\"phone\":\"12345678\",\"email\":\"layla@test.com\"}', '[{\"id\":\"228\",\"contract_id\":\"38\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260421-38-103\",\"amount\":\"700.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-04-21\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-09-22 00:53:40\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"103\",\"qr_requested_at\":null},{\"id\":\"229\",\"contract_id\":\"38\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260521-38-104\",\"amount\":\"700.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-05-21\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-09-22 00:53:40\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"104\",\"qr_requested_at\":null},{\"id\":\"230\",\"contract_id\":\"38\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260621-38-105\",\"amount\":\"700.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-06-21\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-09-22 00:53:40\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"105\",\"qr_requested_at\":null},{\"id\":\"231\",\"contract_id\":\"38\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260721-38-106\",\"amount\":\"700.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-07-21\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-09-22 00:53:40\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"106\",\"qr_requested_at\":null},{\"id\":\"232\",\"contract_id\":\"38\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260821-38-107\",\"amount\":\"700.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-08-21\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-09-22 00:53:40\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"107\",\"qr_requested_at\":null}]', '{\"electricity\":[{\"id\":\"226\",\"apartment_id\":\"29\",\"type\":\"\",\"amount\":\"100.00\",\"due_date\":\"2026-04-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"227\",\"apartment_id\":\"29\",\"type\":\"Meter\",\"amount\":\"21.00\",\"due_date\":\"2026-04-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"228\",\"apartment_id\":\"29\",\"type\":\"\",\"amount\":\"100.00\",\"due_date\":\"2026-05-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"229\",\"apartment_id\":\"29\",\"type\":\"Meter\",\"amount\":\"21.00\",\"due_date\":\"2026-05-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"230\",\"apartment_id\":\"29\",\"type\":\"\",\"amount\":\"100.00\",\"due_date\":\"2026-06-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"231\",\"apartment_id\":\"29\",\"type\":\"Meter\",\"amount\":\"21.00\",\"due_date\":\"2026-06-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"232\",\"apartment_id\":\"29\",\"type\":\"\",\"amount\":\"100.00\",\"due_date\":\"2026-07-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"233\",\"apartment_id\":\"29\",\"type\":\"Meter\",\"amount\":\"21.00\",\"due_date\":\"2026-07-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"234\",\"apartment_id\":\"29\",\"type\":\"\",\"amount\":\"100.00\",\"due_date\":\"2026-08-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null},{\"id\":\"235\",\"apartment_id\":\"29\",\"type\":\"Meter\",\"amount\":\"21.00\",\"due_date\":\"2026-08-21\",\"status\":\"Paid\",\"created_at\":\"2026-09-22 00:53:40\",\"amount_paid\":\"0.00\",\"qr_requested_at\":null}]}', '[]', '[]', '2026-09-23 22:43:51'),
(2, 16, 'ali yazbekk', '564564', 'Galaxy - A2', '2026-09-24', 'Lease Terminated', '{\"phone\":\"81994663\",\"email\":\"ali1@gmail.com\",\"national_id_passport\":\"564564\",\"documents\":[{\"id\":\"5\",\"user_id\":\"4\",\"tenant_id\":\"15\",\"document_type\":\"national_id\",\"file_url\":\"uploads\\/tenant_documents\\/user_4_national_id_1790197114.jpeg\",\"original_filename\":\"WhatsApp Image 2026-09-01 at 12.03.17 AM.jpeg\",\"status\":\"Uploaded\",\"admin_notes\":\"Please re-upload a clearer copy.\",\"uploaded_at\":\"2026-09-23 23:58:34\",\"verified_at\":null,\"verified_by\":null,\"created_at\":\"2026-09-22 23:41:31\",\"updated_at\":\"2026-09-23 23:58:34\"},{\"id\":\"8\",\"user_id\":\"4\",\"tenant_id\":\"16\",\"document_type\":\"passport\",\"file_url\":\"uploads\\/tenant_documents\\/user_4_passport_1790197119.png\",\"original_filename\":\"Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png\",\"status\":\"Uploaded\",\"admin_notes\":null,\"uploaded_at\":\"2026-09-23 23:58:39\",\"verified_at\":null,\"verified_by\":null,\"created_at\":\"2026-09-22 23:42:29\",\"updated_at\":\"2026-09-23 23:58:39\"},{\"id\":\"9\",\"user_id\":\"4\",\"tenant_id\":\"16\",\"document_type\":\"work_contract\",\"file_url\":\"uploads\\/tenant_documents\\/user_4_work_contract_1790197110.jpeg\",\"original_filename\":\"WhatsApp Image 2026-09-01 at 12.03.17 AM.jpeg\",\"status\":\"Uploaded\",\"admin_notes\":null,\"uploaded_at\":\"2026-09-23 23:58:30\",\"verified_at\":null,\"verified_by\":null,\"created_at\":\"2026-09-22 23:42:31\",\"updated_at\":\"2026-09-23 23:58:30\"}]}', '[{\"id\":\"118\",\"contract_id\":\"19\",\"rent_profile_id\":null,\"invoice_number\":\"INV-202607-19\",\"amount\":\"840000.00\",\"period_start\":\"2026-07-10\",\"period_end\":\"2026-08-09\",\"due_date\":\"2026-08-09\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-07-22 23:26:30\",\"payment_method\":\"Cash\",\"payment_date\":\"2026-08-07\",\"reference_number\":\"\",\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":null,\"qr_requested_at\":null},{\"id\":\"122\",\"contract_id\":\"19\",\"rent_profile_id\":null,\"invoice_number\":\"INV-20260807-19-1\",\"amount\":\"840000.00\",\"period_start\":null,\"period_end\":null,\"due_date\":\"2026-07-10\",\"status\":\"Paid\",\"notes\":null,\"created_at\":\"2026-08-07 01:01:50\",\"payment_method\":\"Cash\",\"payment_date\":\"2026-08-09\",\"reference_number\":\"\",\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":\"1\",\"qr_requested_at\":\"2026-08-09 01:34:05\"},{\"id\":\"126\",\"contract_id\":\"19\",\"rent_profile_id\":null,\"invoice_number\":\"INV-202608-19\",\"amount\":\"840000.00\",\"period_start\":\"2026-08-10\",\"period_end\":\"2026-09-09\",\"due_date\":\"2026-08-10\",\"status\":\"Unpaid\",\"notes\":null,\"created_at\":\"2026-09-21 23:31:52\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":null,\"qr_requested_at\":null},{\"id\":\"127\",\"contract_id\":\"19\",\"rent_profile_id\":null,\"invoice_number\":\"INV-202609-19\",\"amount\":\"840000.00\",\"period_start\":\"2026-09-10\",\"period_end\":\"2026-10-09\",\"due_date\":\"2026-09-10\",\"status\":\"Unpaid\",\"notes\":null,\"created_at\":\"2026-09-21 23:31:52\",\"payment_method\":null,\"payment_date\":null,\"reference_number\":null,\"bank_name\":null,\"account_number\":null,\"proof_of_payment\":null,\"rent_period_id\":null,\"qr_requested_at\":null}]', '{\"electricity\":[{\"id\":\"17\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"amount\":\"74500.00\",\"due_date\":\"2026-09-01\",\"status\":\"Paid\",\"created_at\":\"2026-07-26 00:26:21\",\"amount_paid\":\"74500.00\",\"qr_requested_at\":null},{\"id\":\"18\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"amount\":\"79500.00\",\"due_date\":\"2026-08-25\",\"status\":\"Paid\",\"created_at\":\"2026-07-26 23:49:05\",\"amount_paid\":\"79500.00\",\"qr_requested_at\":\"2026-08-09 02:44:47\"},{\"id\":\"19\",\"apartment_id\":\"12\",\"type\":\"Meter\",\"amount\":\"10000.00\",\"due_date\":\"2026-09-01\",\"status\":\"Paid\",\"created_at\":\"2026-07-26 23:49:15\",\"amount_paid\":\"10000.00\",\"qr_requested_at\":\"2026-08-09 02:43:14\"}]}', '[]', '[]', '2026-09-23 22:58:23');

-- --------------------------------------------------------

--
-- Table structure for table `tenant_documents`
--

CREATE TABLE `tenant_documents` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `document_type` enum('passport','national_id','work_contract') NOT NULL,
  `file_url` varchar(500) DEFAULT NULL,
  `original_filename` varchar(255) DEFAULT NULL,
  `status` enum('Uploaded','Verified','Pending','Missing','Requested') NOT NULL DEFAULT 'Pending',
  `admin_notes` text DEFAULT NULL,
  `uploaded_at` datetime DEFAULT NULL,
  `verified_at` datetime DEFAULT NULL,
  `verified_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tenant_documents`
--

INSERT INTO `tenant_documents` (`id`, `user_id`, `tenant_id`, `document_type`, `file_url`, `original_filename`, `status`, `admin_notes`, `uploaded_at`, `verified_at`, `verified_by`, `created_at`, `updated_at`) VALUES
(5, 4, 15, 'national_id', 'uploads/tenant_documents/user_4_national_id_1790197114.jpeg', 'WhatsApp Image 2026-09-01 at 12.03.17 AM.jpeg', 'Uploaded', 'Please re-upload a clearer copy.', '2026-09-23 23:58:34', NULL, NULL, '2026-09-22 20:41:31', '2026-09-23 20:58:34'),
(8, 4, 16, 'passport', 'uploads/tenant_documents/user_4_passport_1790197119.png', 'Gemini_Generated_Image_uvj7z9uvj7z9uvj7.png', 'Uploaded', NULL, '2026-09-23 23:58:39', NULL, NULL, '2026-09-22 20:42:29', '2026-09-23 20:58:39'),
(9, 4, 16, 'work_contract', 'uploads/tenant_documents/user_4_work_contract_1790197110.jpeg', 'WhatsApp Image 2026-09-01 at 12.03.17 AM.jpeg', 'Uploaded', NULL, '2026-09-23 23:58:30', NULL, NULL, '2026-09-22 20:42:31', '2026-09-23 20:58:30');

-- --------------------------------------------------------

--
-- Table structure for table `tenant_maintenance_tickets`
--

CREATE TABLE `tenant_maintenance_tickets` (
  `id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `apartment_id` int(11) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `priority` enum('Low','Medium','High','Urgent') NOT NULL DEFAULT 'Medium',
  `status` enum('Open','In Progress','Resolved','Rejected','Closed') NOT NULL DEFAULT 'Open',
  `admin_notes` text DEFAULT NULL,
  `submitted_by` int(11) DEFAULT NULL,
  `resolved_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `tenant_maintenance_tickets`
--

INSERT INTO `tenant_maintenance_tickets` (`id`, `tenant_id`, `apartment_id`, `title`, `description`, `category`, `priority`, `status`, `admin_notes`, `submitted_by`, `resolved_at`, `created_at`, `updated_at`) VALUES
(1, 15, 11, 'eenfjenfje', 'sdads', 'AC / HVAC', 'Urgent', 'In Progress', NULL, 4, NULL, '2026-09-22 20:43:54', '2026-09-22 21:23:18'),
(2, 15, 11, 'eere', 'sdcd', 'Plumbing', 'Urgent', 'In Progress', NULL, 4, NULL, '2026-09-22 21:06:33', '2026-09-22 21:23:11');

-- --------------------------------------------------------

--
-- Table structure for table `tenant_request_slas`
--

CREATE TABLE `tenant_request_slas` (
  `id` int(11) NOT NULL,
  `request_id` int(11) NOT NULL,
  `tenant_id` int(11) NOT NULL,
  `building_id` int(11) NOT NULL,
  `apartment_id` int(11) NOT NULL,
  `assigned_worker_id` int(11) DEFAULT NULL,
  `status` enum('Created','Assigned','Accepted','Started','Paused','Waiting Parts','Completed','Waiting Approval','Closed') DEFAULT 'Created',
  `priority` enum('Critical','High','Normal','Low') DEFAULT 'Normal',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `accepted_at` timestamp NULL DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `closed_at` timestamp NULL DEFAULT NULL,
  `response_time_seconds` int(11) DEFAULT NULL,
  `completion_time_seconds` int(11) DEFAULT NULL,
  `sla_target_minutes` int(11) DEFAULT 240,
  `is_sla_met` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `translations`
--

CREATE TABLE `translations` (
  `id` int(11) NOT NULL,
  `translation_key` varchar(255) NOT NULL,
  `lang_code` varchar(5) NOT NULL,
  `translated_value` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `translations`
--

INSERT INTO `translations` (`id`, `translation_key`, `lang_code`, `translated_value`) VALUES
(1, 'Welcome Back', 'en', 'Welcome Back'),
(2, 'Welcome Back', 'fr', 'Bon retour'),
(3, 'Welcome Back', 'ar', 'مرحباً بعودتك'),
(4, 'Sign in to access your dashboard', 'en', 'Sign in to access your dashboard'),
(5, 'Sign in to access your dashboard', 'fr', 'Connectez-vous pour accéder à votre tableau de bord'),
(6, 'Sign in to access your dashboard', 'ar', 'قم بتسجيل الدخول للوصول إلى لوحة التحكم'),
(7, 'login.email_address', 'en', 'Email or Username'),
(8, 'login.email_address', 'fr', 'Email ou nom d\'utilisateur'),
(9, 'login.email_address', 'ar', 'البريد الإلكتروني أو اسم المستخدم'),
(10, 'name@company.com', 'en', 'name@company.com'),
(11, 'name@company.com', 'fr', 'nom@entreprise.com'),
(12, 'name@company.com', 'ar', 'name@company.com'),
(13, 'login.password', 'en', 'Password'),
(14, 'login.password', 'fr', 'Mot de passe'),
(15, 'login.password', 'ar', 'كلمة المرور'),
(16, 'Forgot Password?', 'en', 'Forgot Password?'),
(17, 'Forgot Password?', 'fr', 'Mot de passe oublié ?'),
(18, 'Forgot Password?', 'ar', 'هل نسيت كلمة المرور؟'),
(19, 'Enter your password', 'en', 'Enter your password'),
(20, 'Enter your password', 'fr', 'Entrez votre mot de passe'),
(21, 'Enter your password', 'ar', 'أدخل كلمة المرور'),
(22, 'Keep me signed in', 'en', 'Keep me signed in'),
(23, 'Keep me signed in', 'fr', 'Garder ma session active'),
(24, 'Keep me signed in', 'ar', 'أبقني مسجلاً'),
(25, 'Signing in...', 'en', 'Signing in...'),
(26, 'Signing in...', 'fr', 'Connexion en cours...'),
(27, 'Signing in...', 'ar', 'جاري تسجيل الدخول...'),
(28, 'login.sign_in', 'en', 'Sign In to Dashboard'),
(29, 'login.sign_in', 'fr', 'Se connecter'),
(30, 'login.sign_in', 'ar', 'تسجيل الدخول'),
(31, 'System Online', 'en', 'System Online'),
(32, 'System Online', 'fr', 'Système En Ligne'),
(33, 'System Online', 'ar', 'النظام متصل'),
(34, 'Active Modules', 'en', 'Active Modules'),
(35, 'Active Modules', 'fr', 'Modules Actifs'),
(36, 'Active Modules', 'ar', 'الوحدات النشطة'),
(37, 'Rent & Utilities', 'en', 'Rent & Utilities'),
(38, 'Rent & Utilities', 'fr', 'Loyer & Services'),
(39, 'Rent & Utilities', 'ar', 'الإيجار والمرافق'),
(40, 'Currency Supported', 'en', 'Currency Supported'),
(41, 'Currency Supported', 'fr', 'Devises Supportées'),
(42, 'Currency Supported', 'ar', 'العملات المدعومة'),
(43, 'CFA / USD / EUR', 'en', 'CFA / USD / EUR'),
(44, 'CFA / USD / EUR', 'fr', 'CFA / USD / EUR'),
(45, 'CFA / USD / EUR', 'ar', 'فرنك سيفا / دولار / يورو'),
(46, 'LEASE CENTER', 'fr', 'CENTRE DE LOCATION'),
(47, 'LEASE CENTER', 'ar', 'مركز التأجير'),
(48, 'New End Date', 'fr', 'Nouvelle Date de Fin'),
(49, 'New End Date', 'ar', 'تاريخ الانتهاء الجديد'),
(50, 'Pro Hub', 'fr', 'Pro Hub'),
(51, 'Pro Hub', 'ar', 'المركز الاحترافي'),
(52, 'Email Record', 'fr', 'Envoyer par Email'),
(53, 'Email Record', 'ar', 'إرسال السجل بالبريد'),
(54, 'Normal View', 'fr', 'Vue Normale'),
(55, 'Normal View', 'ar', 'عرض عادي'),
(56, 'View All Expiries', 'fr', 'Voir Toutes les Expirations'),
(57, 'View All Expiries', 'ar', 'عرض جميع الانتهاءات'),
(58, 'Open Maintenance Requests', 'fr', 'Demandes de Maintenance Ouvertes'),
(59, 'Open Maintenance Requests', 'ar', 'طلبات الصيانة المفتوحة'),
(60, 'Maintenance', 'fr', 'Maintenance'),
(61, 'Maintenance', 'ar', 'الصيانة'),
(62, 'Total Rent Due', 'fr', 'Total des Loyers Dus'),
(63, 'Total Rent Due', 'ar', 'إجمالي الإيجار المستحق'),
(64, 'Add Tenant', 'fr', 'Ajouter un Locataire'),
(65, 'Add Tenant', 'ar', 'إضافة مستأجر'),
(66, 'Status:', 'fr', 'Statut :'),
(67, 'Status:', 'ar', 'الحالة:'),
(68, 'Code', 'fr', 'Code'),
(69, 'Code', 'ar', 'الرمز'),
(70, 'Generator Collected', 'fr', 'Générateur Encaissé'),
(71, 'Generator Collected', 'ar', 'المولد المحصل'),
(72, 'Contract Type', 'fr', 'Type de Contrat'),
(73, 'Contract Type', 'ar', 'نوع العقد'),
(74, 'Priority', 'fr', 'Priorité'),
(75, 'Priority', 'ar', 'الأولوية'),
(76, 'Upcoming Schedule', 'fr', 'Planning à Venir'),
(77, 'Upcoming Schedule', 'ar', 'الجدول القادم'),
(78, 'Termination Date:', 'fr', 'Date de Résiliation :'),
(79, 'Termination Date:', 'ar', 'تاريخ الإنهاء:'),
(80, 'Selected Apartment Details', 'fr', 'Détails de l\'Appartement Sélectionné'),
(81, 'Selected Apartment Details', 'ar', 'تفاصيل الشقة المحددة'),
(82, 'Electricity Collected', 'fr', 'Électricité Encaissée'),
(83, 'Electricity Collected', 'ar', 'الكهرباء المحصلة'),
(84, 'Email:', 'fr', 'Email :'),
(85, 'Email:', 'ar', 'البريد الإلكتروني:'),
(86, 'Unit', 'fr', 'Unité'),
(87, 'Unit', 'ar', 'الوحدة'),
(88, 'Contact & Documents', 'fr', 'Contact & Documents'),
(89, 'Contact & Documents', 'ar', 'الاتصال والمستندات'),
(90, 'Total Billed', 'fr', 'Total Facturé'),
(91, 'Total Billed', 'ar', 'إجمالي الفواتير'),
(92, 'No tasks scheduled for this day!', 'fr', 'Aucune tâche programmée pour ce jour !'),
(93, 'No tasks scheduled for this day!', 'ar', 'لا توجد مهام مجدولة لهذا اليوم!'),
(94, 'Cancel', 'fr', 'Annuler'),
(95, 'Cancel', 'ar', 'إلغاء'),
(96, 'Tenants Directory', 'fr', 'Répertoire des Locataires'),
(97, 'Tenants Directory', 'ar', 'دليل المستأجرين'),
(98, 'Unpaid', 'fr', 'Impayé'),
(99, 'Unpaid', 'ar', 'غير مدفوع'),
(100, 'Note: To create a new tenant, go to User Management and create a user with the ', 'fr', 'Note : Pour créer un nouveau locataire, allez dans Gestion des Utilisateurs et créez un utilisateur avec le '),
(101, 'Note: To create a new tenant, go to User Management and create a user with the ', 'ar', 'ملاحظة: لإنشاء مستأجر جديد، انتقل إلى إدارة المستخدمين وقم بإنشاء مستخدم باستخدام '),
(102, 'Contract End Date', 'fr', 'Date de Fin de Contrat'),
(103, 'Contract End Date', 'ar', 'تاريخ نهاية العقد'),
(104, 'No Active Tenant', 'fr', 'Aucun Locataire Actif'),
(105, 'No Active Tenant', 'ar', 'لا يوجد مستأجر نشط'),
(106, 'View Full Team Performance', 'fr', 'Voir les Performances de l\'Équipe'),
(107, 'View Full Team Performance', 'ar', 'عرض أداء الفريق بالكامل'),
(108, 'AGREEMENT STATUS', 'fr', 'STATUT DES ACCORDS'),
(109, 'AGREEMENT STATUS', 'ar', 'حالة الاتفاقيات'),
(110, 'Contract Start Date', 'fr', 'Date de Début de Contrat'),
(111, 'Contract Start Date', 'ar', 'تاريخ بداية العقد'),
(112, 'Amount', 'fr', 'Montant'),
(113, 'Amount', 'ar', 'المبلغ'),
(114, 'Paid', 'fr', 'Payé'),
(115, 'Paid', 'ar', 'مدفوع'),
(116, 'New Start Date', 'fr', 'Nouvelle Date de Début'),
(117, 'New Start Date', 'ar', 'تاريخ البدء الجديد'),
(118, 'Insurance Collected', 'fr', 'Assurance Encaissée'),
(119, 'Insurance Collected', 'ar', 'التأمين المحصل'),
(120, 'Expiring soon', 'fr', 'Expire bientôt'),
(121, 'Expiring soon', 'ar', 'ينتهي قريباً'),
(122, 'View All Requests', 'fr', 'Voir Toutes les Demandes'),
(123, 'View All Requests', 'ar', 'عرض جميع الطلبات'),
(124, 'Click to switch mode:', 'fr', 'Cliquez pour changer de mode :'),
(125, 'Click to switch mode:', 'ar', 'انقر لتبديل الوضع:'),
(126, 'Manage all registered tenants and contracts', 'fr', 'Gérer tous les locataires et contrats enregistrés'),
(127, 'Manage all registered tenants and contracts', 'ar', 'إدارة جميع المستأجرين والعقود المسجلة'),
(128, 'Date and past apartment number', 'fr', 'Date et ancien numéro d\'appartement'),
(129, 'Date and past apartment number', 'ar', 'التاريخ ورقم الشقة السابقة'),
(130, 'Current Month', 'fr', 'Mois en Cours'),
(131, 'Current Month', 'ar', 'الشهر الحالي'),
(132, 'Rental History', 'fr', 'Historique de Location'),
(133, 'Rental History', 'ar', 'تاريخ الإيجار'),
(134, 'Renew Contract', 'fr', 'Renouveler le Contrat'),
(135, 'Renew Contract', 'ar', 'تجديد العقد'),
(136, 'Select Registered Tenant User', 'fr', 'Sélectionner un Utilisateur Locataire'),
(137, 'Select Registered Tenant User', 'ar', 'حدد مستخدم مستأجر مسجل'),
(138, 'Due Date', 'fr', 'Date d\'Échéance'),
(139, 'Due Date', 'ar', 'تاريخ الاستحقاق'),
(140, 'View history and records of past terminated tenants', 'fr', 'Voir l\'historique et les dossiers des locataires résiliés'),
(141, 'View history and records of past terminated tenants', 'ar', 'عرض تاريخ وسجلات المستأجرين المنتهية عقودهم'),
(142, 'Manage Compliance', 'fr', 'Gérer la Conformité'),
(143, 'Manage Compliance', 'ar', 'إدارة الامتثال'),
(144, 'Filter:', 'fr', 'Filtrer :'),
(145, 'Filter:', 'ar', 'تصفية:'),
(146, 'Status', 'fr', 'Statut'),
(147, 'Status', 'ar', 'الحالة'),
(148, 'Financial Summary', 'fr', 'Résumé Financier'),
(149, 'Financial Summary', 'ar', 'الملخص المالي'),
(150, 'Alerts & Action Center', 'fr', 'Centre d\'Alertes et d\'Action'),
(151, 'Alerts & Action Center', 'ar', 'مركز التنبيهات والإجراءات'),
(152, 'Assign Tenant to Contract', 'fr', 'Associer le Locataire au Contrat'),
(153, 'Assign Tenant to Contract', 'ar', 'تعيين مستأجر للعقد'),
(154, 'CONTRACT STATUS', 'fr', 'STATUT DU CONTRAT'),
(155, 'CONTRACT STATUS', 'ar', 'حالة العقد'),
(156, 'Apartment', 'fr', 'Appartement'),
(157, 'Apartment', 'ar', 'الشقة'),
(158, 'No tenants found', 'fr', 'Aucun locataire trouvé'),
(159, 'No tenants found', 'ar', 'لم يتم العثور على مستأجرين'),
(160, 'Apt:', 'fr', 'Apt :'),
(161, 'Apt:', 'ar', 'شقة:'),
(162, 'Critical', 'fr', 'Critique'),
(163, 'Critical', 'ar', 'حرج'),
(164, 'Total Rent Collected', 'fr', 'Total des Loyers Perçus'),
(165, 'Total Rent Collected', 'ar', 'إجمالي الإيجار المحصل'),
(166, 'Next Action', 'fr', 'Prochaine Action'),
(167, 'Next Action', 'ar', 'الإجراء التالي'),
(168, 'Tenant', 'fr', 'Locataire'),
(169, 'Tenant', 'ar', 'مستأجر'),
(170, 'Day', 'fr', 'Jour'),
(171, 'Day', 'ar', 'يوم'),
(172, 'Tenant Name', 'fr', 'Nom du Locataire'),
(173, 'Tenant Name', 'ar', 'اسم المستأجر'),
(174, 'Utilities', 'fr', 'Services'),
(175, 'Utilities', 'ar', 'المرافق'),
(176, 'TODAY', 'fr', 'Aujourd\'hui'),
(177, 'TODAY', 'ar', 'اليوم'),
(178, 'Phone:', 'fr', 'Tél :'),
(179, 'Phone:', 'ar', 'الهاتف:'),
(180, 'ID/Passport:', 'fr', 'ID/Passeport :'),
(181, 'ID/Passport:', 'ar', 'الهوية/جواز السفر:'),
(182, 'National ID', 'fr', 'ID National'),
(183, 'National ID', 'ar', 'الهوية الوطنية'),
(184, 'Phone', 'fr', 'Téléphone'),
(185, 'Phone', 'ar', 'الهاتف'),
(186, 'Assignee', 'fr', 'Assigné'),
(187, 'Assignee', 'ar', 'المكلف'),
(188, 'Insurance Status', 'fr', 'Statut Assurance'),
(189, 'Insurance Status', 'ar', 'حالة التأمين'),
(190, 'Rooms', 'fr', 'Pièces'),
(191, 'Rooms', 'ar', 'غرف'),
(192, 'By Payment Method', 'fr', 'Par Méthode de Paiement'),
(193, 'By Payment Method', 'ar', 'حسب طريقة الدفع'),
(194, 'Open Calendar', 'fr', 'Ouvrir le Calendrier'),
(195, 'Open Calendar', 'ar', 'فتح التقويم'),
(198, 'Apt', 'fr', 'Apt'),
(199, 'Apt', 'ar', 'شقة'),
(200, 'Export as PDF', 'fr', 'Exporter en PDF'),
(201, 'Export as PDF', 'ar', 'تصدير كملف PDF'),
(202, 'Full Name', 'fr', 'Nom Complet'),
(203, 'Full Name', 'ar', 'الاسم الكامل'),
(204, 'Default Rent', 'fr', 'Loyer par Défaut'),
(205, 'Default Rent', 'ar', 'الإيجار الافتراضي'),
(206, 'Building', 'fr', 'Bâtiment'),
(207, 'Building', 'ar', 'المبنى'),
(208, 'View Details', 'fr', 'Voir les Détails'),
(209, 'View Details', 'ar', 'عرض التفاصيل'),
(210, 'Normal Calendar', 'fr', 'Calendrier Normal'),
(211, 'Normal Calendar', 'ar', 'التقويم العادي'),
(212, 'CONTRACT HUB', 'fr', 'CENTRE DES CONTRATS'),
(213, 'CONTRACT HUB', 'ar', 'مركز العقود'),
(214, 'Outstanding Rent', 'fr', 'Loyers Impayés'),
(215, 'Outstanding Rent', 'ar', 'الإيجار المستحق'),
(216, 'Assign to Apartment', 'fr', 'Assigner à l\'Appartement'),
(217, 'Assign to Apartment', 'ar', 'تعيين إلى شقة'),
(218, 'Unpaid Rent Invoices', 'fr', 'Factures de Loyer Impayées'),
(219, 'Unpaid Rent Invoices', 'ar', 'فواتير إيجار غير مدفوعة'),
(220, 'Decide Action', 'fr', 'Décider d\'une Action'),
(221, 'Decide Action', 'ar', 'تحديد إجراء'),
(222, 'Type', 'fr', 'Type'),
(223, 'Type', 'ar', 'النوع'),
(224, 'Date', 'fr', 'Date'),
(225, 'Date', 'ar', 'التاريخ'),
(226, 'Manage Contracts', 'fr', 'Gérer les Contrats'),
(227, 'Manage Contracts', 'ar', 'إدارة العقود'),
(228, 'Month', 'fr', 'Mois'),
(229, 'Month', 'ar', 'شهر'),
(230, 'Preventative', 'fr', 'Préventif'),
(231, 'Preventative', 'ar', 'وقائي'),
(232, 'CRITICAL ALERTS & MAINTENANCE HUB', 'fr', 'ALERTES CRITIQUES & CENTRE DE MAINTENANCE'),
(233, 'CRITICAL ALERTS & MAINTENANCE HUB', 'ar', 'التنبيهات الحرجة ومركز الصيانة'),
(234, 'Expiry', 'fr', 'Expiration'),
(235, 'Expiry', 'ar', 'الانتهاء'),
(236, 'Selected Tenant Details', 'fr', 'Détails du Locataire Sélectionné'),
(237, 'Selected Tenant Details', 'ar', 'تفاصيل المستأجر المحدد'),
(238, 'Archived Tenant Report', 'fr', 'Rapport des Locataires Archivés'),
(239, 'Archived Tenant Report', 'ar', 'تقرير المستأجرين المؤرشفين'),
(240, 'Contract renewed successfully', 'fr', 'Contrat renouvelé avec succès'),
(241, 'Contract renewed successfully', 'ar', 'تم تجديد العقد بنجاح'),
(242, 'Maintenance Hub', 'fr', 'Centre de Maintenance'),
(243, 'Maintenance Hub', 'ar', 'مركز الصيانة'),
(244, 'RENT & COMPLIANCE HUB', 'fr', 'CENTRE DES LOYERS ET DE CONFORMITÉ'),
(245, 'RENT & COMPLIANCE HUB', 'ar', 'مركز الإيجارات والامتثال'),
(246, 'EMPLOYEE', 'fr', 'EMPLOYÉ'),
(247, 'EMPLOYEE', 'ar', 'موظف'),
(248, 'Last Apartment:', 'fr', 'Dernier Appartement :'),
(249, 'Last Apartment:', 'ar', 'آخر شقة:'),
(250, 'Rent Status', 'fr', 'Statut Loyer'),
(251, 'Rent Status', 'ar', 'حالة الإيجار'),
(252, 'Archived / Terminated', 'fr', 'Archivé / Résilié'),
(253, 'Archived / Terminated', 'ar', 'مؤرشف / منهي'),
(254, 'Next 3 months', 'fr', '3 Prochains Mois'),
(255, 'Next 3 months', 'ar', 'الأشهر الثلاثة القادمة'),
(256, 'TODAY\'S COMMAND', 'fr', 'COMMANDES DU JOUR'),
(257, 'TODAY\'S COMMAND', 'ar', 'أوامر اليوم'),
(258, 'TODAY\'S TASKS & ALERTS', 'fr', 'TÂCHES ET ALERTES DU JOUR'),
(259, 'TODAY\'S TASKS & ALERTS', 'ar', 'مهام وتنبيهات اليوم'),
(260, 'No alerts in this category. You\'re all caught up!', 'fr', 'Aucune alerte dans cette catégorie. Vous êtes à jour !'),
(261, 'No alerts in this category. You\'re all caught up!', 'ar', 'لا توجد تنبيهات في هذه الفئة. أنت على اطلاع دائم!');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `username` varchar(100) DEFAULT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','manager','cashier','maintenance','agent','tenant') DEFAULT 'cashier',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `phone` varchar(50) DEFAULT NULL,
  `national_id` varchar(100) DEFAULT NULL,
  `preferred_language` varchar(5) DEFAULT 'en'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `username`, `email`, `password`, `role`, `created_at`, `phone`, `national_id`, `preferred_language`) VALUES
(1, 'Admin', 'admin', 'admin@bitar.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', '2026-06-18 20:28:14', NULL, NULL, 'en'),
(2, 'milad', 'ali', 'ali@gmail.com', '$2y$10$LOexb8wJXMoNS/SXGIynOuSCBw.8gvxH.QMpCGzt5BEIvKUFGDZpe', 'maintenance', '2026-06-22 20:01:24', NULL, NULL, 'en'),
(3, 'dfsdf', 'dwdwd', 'dwdwd@gmail.com', '$2y$10$ieQec6Sx8oLH/toQL7l6d.aJOfH5ujKudaOGZAltwH7lzKzw1mCxC', 'cashier', '2026-06-27 22:40:30', NULL, NULL, 'en'),
(4, 'ali yazbekk', 'ali1', 'ali1@gmail.com', '$2y$10$mMOZ7Dv0hZnD.yh6zKmK7OgbRnTdgByL.Xz/pRz27rs0V0lwoaxI.', 'tenant', '2026-06-27 23:11:30', '81994663', '564564', 'en'),
(5, 'hassan haded', 'hassan', 'hassan@gmail.com', '$2y$10$TAry9z/tP1GFOdqwsP38S.G.nj9/12HTkFkvyOLMOD7a27t2XiAvK', 'agent', '2026-06-28 22:17:55', '', '', 'en'),
(6, 'Mohamad', 'mohamad', 'mohamad@example.com', '12345', 'maintenance', '2026-06-30 22:22:36', NULL, NULL, 'en');

-- --------------------------------------------------------

--
-- Table structure for table `user_sessions`
--

CREATE TABLE `user_sessions` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `session_token` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `login_time` datetime NOT NULL DEFAULT current_timestamp(),
  `last_activity` datetime NOT NULL DEFAULT current_timestamp(),
  `current_page` varchar(150) DEFAULT NULL,
  `current_record_id` varchar(100) DEFAULT NULL,
  `edit_mode` varchar(50) DEFAULT NULL,
  `current_action` varchar(255) DEFAULT NULL,
  `unsaved_changes` tinyint(1) NOT NULL DEFAULT 0,
  `changed_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`changed_fields`)),
  `status` enum('online','idle','away','editing','viewing','offline') NOT NULL DEFAULT 'online'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_sessions`
--

INSERT INTO `user_sessions` (`id`, `user_id`, `session_token`, `ip_address`, `user_agent`, `login_time`, `last_activity`, `current_page`, `current_record_id`, `edit_mode`, `current_action`, `unsaved_changes`, `changed_fields`, `status`) VALUES
(1, 1, 'auth_1', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36 Edg/153.0.0.0', '2026-07-17 00:58:37', '2026-09-26 01:52:52', '/schedule', NULL, 'editing', 'PMS System', 0, NULL, 'away'),
(321, 4, 'auth_4', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/153.0.0.0 Safari/537.36', '2026-07-19 00:11:03', '2026-09-24 01:44:27', '/tenant-profile', NULL, 'viewing', 'PMS System', 0, NULL, 'away'),
(1095, 5, 'auth_5', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36', '2026-07-21 00:27:37', '2026-08-28 01:08:25', '/agent-generators', NULL, 'editing', 'PMS System', 0, NULL, 'idle'),
(4790, 2, 'auth_2', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/151.0.0.0 Safari/537.36 Edg/151.0.0.0', '2026-08-07 22:36:20', '2026-08-09 00:03:40', '/maintenance', NULL, 'viewing', 'PMS System', 0, NULL, 'online');

-- --------------------------------------------------------

--
-- Table structure for table `validation_rules`
--

CREATE TABLE `validation_rules` (
  `id` int(11) NOT NULL,
  `module` varchar(100) NOT NULL,
  `field_name` varchar(100) NOT NULL,
  `is_required` tinyint(1) DEFAULT 1,
  `rule_type` varchar(100) DEFAULT NULL,
  `expected_format` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `validation_rules`
--

INSERT INTO `validation_rules` (`id`, `module`, `field_name`, `is_required`, `rule_type`, `expected_format`, `created_at`) VALUES
(1, 'Tenant', 'national_id', 1, NULL, NULL, '2026-07-17 22:42:05'),
(2, 'Tenant', 'passport_url', 1, NULL, NULL, '2026-07-17 22:42:05'),
(3, 'Tenant', 'full_name', 1, NULL, NULL, '2026-07-17 22:42:05'),
(4, 'Contracts', 'contract_file', 1, NULL, NULL, '2026-07-17 22:42:05'),
(5, 'Generator', 'photo_path', 1, NULL, NULL, '2026-07-17 22:42:05');

-- --------------------------------------------------------

--
-- Table structure for table `worker_device_telemetry`
--

CREATE TABLE `worker_device_telemetry` (
  `id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `current_screen` varchar(100) DEFAULT NULL,
  `current_building_id` int(11) DEFAULT NULL,
  `last_api_endpoint` varchar(255) DEFAULT NULL,
  `pending_queue_count` int(11) DEFAULT 0,
  `offline_queue_count` int(11) DEFAULT 0,
  `app_version` varchar(20) DEFAULT '1.0.0',
  `device_os` varchar(50) DEFAULT NULL,
  `gps_lat` decimal(10,8) DEFAULT NULL,
  `gps_lng` decimal(11,8) DEFAULT NULL,
  `battery_level` int(11) DEFAULT NULL,
  `internet_speed` varchar(50) DEFAULT NULL,
  `crash_count` int(11) DEFAULT 0,
  `last_sync_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `workshop_estimates`
--

CREATE TABLE `workshop_estimates` (
  `id` int(11) NOT NULL,
  `project_id` int(11) NOT NULL,
  `item_name` varchar(100) NOT NULL,
  `category` varchar(50) NOT NULL,
  `quantity` decimal(10,2) NOT NULL,
  `unit` varchar(20) DEFAULT NULL,
  `unit_price` decimal(10,2) NOT NULL,
  `total_price` decimal(10,2) NOT NULL,
  `is_reserved` tinyint(1) DEFAULT 0,
  `item_name_fr` varchar(255) DEFAULT NULL,
  `item_name_ar` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `workshop_estimates`
--

INSERT INTO `workshop_estimates` (`id`, `project_id`, `item_name`, `category`, `quantity`, `unit`, `unit_price`, `total_price`, `is_reserved`, `item_name_fr`, `item_name_ar`) VALUES
(1, 1, 'Concrete', 'Material', 1320.00, 'm3', 120.00, 158400.00, 0, NULL, NULL),
(2, 1, 'Steel', 'Material', 158.40, 'Ton', 800.00, 126720.00, 0, NULL, NULL),
(3, 1, 'Cement', 'Material', 9960.00, 'Bag', 12.00, 119520.00, 0, NULL, NULL),
(4, 1, 'Blocks', 'Material', 72000.00, 'Piece', 0.50, 36000.00, 0, NULL, NULL),
(5, 1, 'Sand', 'Material', 747.00, 'Ton', 30.00, 22410.00, 0, NULL, NULL),
(6, 1, 'Tiles', 'Material', 3920.00, 'm2', 15.00, 58800.00, 0, NULL, NULL),
(7, 1, 'Paint', 'Material', 3600.00, 'Liter', 4.00, 14400.00, 0, NULL, NULL),
(8, 1, 'Electrical Cables', 'Material', 9600.00, 'Meter', 1.50, 14400.00, 0, NULL, NULL),
(9, 1, 'Water Pipes', 'Material', 3600.00, 'Meter', 3.00, 10800.00, 0, NULL, NULL),
(10, 1, 'Doors', 'Material', 144.00, 'Piece', 150.00, 21600.00, 0, NULL, NULL),
(11, 1, 'Windows', 'Material', 240.00, 'Piece', 200.00, 48000.00, 0, NULL, NULL),
(12, 1, 'Mason', 'Labor', 2304.00, 'Mandays', 25.00, 57600.00, 0, NULL, NULL),
(13, 1, 'Electrician', 'Labor', 864.00, 'Mandays', 35.00, 30240.00, 0, NULL, NULL),
(14, 1, 'Plumber', 'Labor', 864.00, 'Mandays', 35.00, 30240.00, 0, NULL, NULL),
(15, 1, 'Painter', 'Labor', 1152.00, 'Mandays', 20.00, 23040.00, 0, NULL, NULL),
(16, 1, 'Supervisor', 'Labor', 720.00, 'Mandays', 50.00, 36000.00, 0, NULL, NULL),
(17, 1, 'Excavator', 'Equipment', 30.00, 'Days', 200.00, 6000.00, 0, NULL, NULL),
(18, 1, 'Crane', 'Equipment', 360.00, 'Days', 150.00, 54000.00, 0, NULL, NULL),
(19, 1, 'Concrete Mixer', 'Equipment', 120.00, 'Days', 100.00, 12000.00, 0, NULL, NULL),
(20, 1, 'Generator', 'Equipment', 360.00, 'Days', 50.00, 18000.00, 0, NULL, NULL),
(21, 1, 'Permits & Fees', 'Other', 1.00, 'Lump Sum', 15000.00, 15000.00, 0, NULL, NULL),
(22, 2, 'Concrete', 'Material', 4000.00, 'm3', 120.00, 480000.00, 0, NULL, NULL),
(23, 2, 'Steel', 'Material', 480.00, 'Ton', 800.00, 384000.00, 0, NULL, NULL),
(24, 2, 'Cement', 'Material', 35500.00, 'Bag', 12.00, 426000.00, 0, NULL, NULL),
(25, 2, 'Blocks', 'Material', 750000.00, 'Piece', 0.50, 375000.00, 0, NULL, NULL),
(26, 2, 'Sand', 'Material', 2662.50, 'Ton', 30.00, 79875.00, 0, NULL, NULL),
(27, 2, 'Tiles', 'Material', 30000.00, 'm2', 15.00, 450000.00, 0, NULL, NULL),
(28, 2, 'Paint', 'Material', 37500.00, 'Liter', 4.00, 150000.00, 0, NULL, NULL),
(29, 2, 'Electrical Cables', 'Material', 100000.00, 'Meter', 1.50, 150000.00, 0, NULL, NULL),
(30, 2, 'Water Pipes', 'Material', 37500.00, 'Meter', 3.00, 112500.00, 0, NULL, NULL),
(31, 2, 'Doors', 'Material', 12500.00, 'Piece', 150.00, 1875000.00, 0, NULL, NULL),
(32, 2, 'Windows', 'Material', 2500.00, 'Piece', 200.00, 500000.00, 0, NULL, NULL),
(33, 2, 'Mason', 'Labor', 36072.00, 'Mandays', 25.00, 901800.00, 0, NULL, NULL),
(34, 2, 'Electrician', 'Labor', 13527.00, 'Mandays', 35.00, 473445.00, 0, NULL, NULL),
(35, 2, 'Plumber', 'Labor', 13527.00, 'Mandays', 35.00, 473445.00, 0, NULL, NULL),
(36, 2, 'Painter', 'Labor', 18036.00, 'Mandays', 20.00, 360720.00, 0, NULL, NULL),
(37, 2, 'Supervisor', 'Labor', 1080.00, 'Mandays', 50.00, 54000.00, 0, NULL, NULL),
(38, 2, 'Excavator', 'Equipment', 30.00, 'Days', 200.00, 6000.00, 0, NULL, NULL),
(39, 2, 'Crane', 'Equipment', 540.00, 'Days', 150.00, 81000.00, 0, NULL, NULL),
(40, 2, 'Concrete Mixer', 'Equipment', 180.00, 'Days', 100.00, 18000.00, 0, NULL, NULL),
(41, 2, 'Generator', 'Equipment', 540.00, 'Days', 50.00, 27000.00, 0, NULL, NULL),
(42, 2, 'Permits & Fees', 'Other', 1.00, 'Lump Sum', 15000.00, 15000.00, 0, NULL, NULL),
(43, 3, 'Concrete', 'Material', 76007.50, 'm3', 120.00, 9120900.00, 0, NULL, NULL),
(44, 3, 'Steel', 'Material', 9120.90, 'Ton', 800.00, 7296720.00, 0, NULL, NULL),
(45, 3, 'Cement', 'Material', 532802.50, 'Bag', 12.00, 6393630.00, 0, NULL, NULL),
(46, 3, 'Blocks', 'Material', 75000.00, 'Piece', 0.50, 37500.00, 0, NULL, NULL),
(47, 3, 'Sand', 'Material', 39960.19, 'Ton', 30.00, 1198805.63, 0, NULL, NULL),
(48, 3, 'Tiles', 'Material', 3000.00, 'm2', 15.00, 45000.00, 0, NULL, NULL),
(49, 3, 'Paint', 'Material', 3750.00, 'Liter', 4.00, 15000.00, 0, NULL, NULL),
(50, 3, 'Electrical Cables', 'Material', 10000.00, 'Meter', 1.50, 15000.00, 0, NULL, NULL),
(51, 3, 'Water Pipes', 'Material', 3750.00, 'Meter', 3.00, 11250.00, 0, NULL, NULL),
(52, 3, 'Doors', 'Material', 125.00, 'Piece', 150.00, 18750.00, 0, NULL, NULL),
(53, 3, 'Windows', 'Material', 125.00, 'Piece', 200.00, 25000.00, 0, NULL, NULL),
(54, 3, 'Mason', 'Labor', 3672.00, 'Mandays', 25.00, 91800.00, 0, NULL, NULL),
(55, 3, 'Electrician', 'Labor', 1377.00, 'Mandays', 35.00, 48195.00, 0, NULL, NULL),
(56, 3, 'Plumber', 'Labor', 1377.00, 'Mandays', 35.00, 48195.00, 0, NULL, NULL),
(57, 3, 'Painter', 'Labor', 1836.00, 'Mandays', 20.00, 36720.00, 0, NULL, NULL),
(58, 3, 'Supervisor', 'Labor', 1080.00, 'Mandays', 50.00, 54000.00, 0, NULL, NULL),
(59, 3, 'Excavator', 'Equipment', 30.00, 'Days', 200.00, 6000.00, 0, NULL, NULL),
(60, 3, 'Crane', 'Equipment', 540.00, 'Days', 150.00, 81000.00, 0, NULL, NULL),
(61, 3, 'Concrete Mixer', 'Equipment', 180.00, 'Days', 100.00, 18000.00, 0, NULL, NULL),
(62, 3, 'Generator', 'Equipment', 540.00, 'Days', 50.00, 27000.00, 0, NULL, NULL),
(63, 3, 'Permits & Fees', 'Other', 1.00, 'Lump Sum', 15000.00, 15000.00, 0, NULL, NULL),
(64, 4, 'Concrete', 'Material', 108982.50, 'm3', 120.00, 13077900.00, 0, NULL, NULL),
(65, 4, 'Steel', 'Material', 13077.90, 'Ton', 800.00, 10462320.00, 0, NULL, NULL),
(66, 4, 'Cement', 'Material', 841177.50, 'Bag', 12.00, 10094130.00, 0, NULL, NULL),
(67, 4, 'Blocks', 'Material', 7830000.00, 'Piece', 0.50, 3915000.00, 0, NULL, NULL),
(68, 4, 'Sand', 'Material', 63088.31, 'Ton', 30.00, 1892649.38, 0, NULL, NULL),
(69, 4, 'Tiles', 'Material', 313200.00, 'm2', 15.00, 4698000.00, 0, NULL, NULL),
(70, 4, 'Paint', 'Material', 391500.00, 'Liter', 4.00, 1566000.00, 0, NULL, NULL),
(71, 4, 'Electrical Cables', 'Material', 1044000.00, 'Meter', 1.50, 1566000.00, 0, NULL, NULL),
(72, 4, 'Water Pipes', 'Material', 391500.00, 'Meter', 3.00, 1174500.00, 0, NULL, NULL),
(73, 4, 'Doors', 'Material', 13050.00, 'Piece', 150.00, 1957500.00, 0, NULL, NULL),
(74, 4, 'Windows', 'Material', 135720.00, 'Piece', 200.00, 27144000.00, 0, NULL, NULL),
(75, 4, 'Mason', 'Labor', 375840.00, 'Mandays', 25.00, 9396000.00, 0, NULL, NULL),
(76, 4, 'Electrician', 'Labor', 140940.00, 'Mandays', 35.00, 4932900.00, 0, NULL, NULL),
(77, 4, 'Plumber', 'Labor', 140940.00, 'Mandays', 35.00, 4932900.00, 0, NULL, NULL),
(78, 4, 'Painter', 'Labor', 187920.00, 'Mandays', 20.00, 3758400.00, 0, NULL, NULL),
(79, 4, 'Supervisor', 'Labor', 1080.00, 'Mandays', 50.00, 54000.00, 0, NULL, NULL),
(80, 4, 'Excavator', 'Equipment', 30.00, 'Days', 200.00, 6000.00, 0, NULL, NULL),
(81, 4, 'Crane', 'Equipment', 540.00, 'Days', 150.00, 81000.00, 0, NULL, NULL),
(82, 4, 'Concrete Mixer', 'Equipment', 180.00, 'Days', 100.00, 18000.00, 0, NULL, NULL),
(83, 4, 'Generator', 'Equipment', 540.00, 'Days', 50.00, 27000.00, 0, NULL, NULL),
(84, 4, 'Permits & Fees', 'Other', 1.00, 'Lump Sum', 15000.00, 15000.00, 0, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `workshop_projects`
--

CREATE TABLE `workshop_projects` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `land_area` decimal(10,2) NOT NULL,
  `floors` int(11) NOT NULL,
  `apartments_per_floor` int(11) NOT NULL,
  `total_apartments` int(11) NOT NULL,
  `status` varchar(50) DEFAULT 'Planning',
  `progress` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `workshop_projects`
--

INSERT INTO `workshop_projects` (`id`, `name`, `land_area`, `floors`, `apartments_per_floor`, `total_apartments`, `status`, `progress`, `created_at`) VALUES
(1, 'yazbek', 800.00, 4, 6, 24, 'Planning', 0, '2026-06-18 22:09:11'),
(2, 'were', 1000.00, 5, 50, 250, 'Planning', 0, '2026-06-28 17:04:30'),
(3, 'dfsf', 50505.00, 5, 5, 25, 'Planning', 0, '2026-06-28 17:07:25'),
(4, 'fdgfg', 55255.00, 5, 522, 2610, 'Construction_Started', 0, '2026-06-28 17:12:18');

-- --------------------------------------------------------

--
-- Table structure for table `workshop_specifications`
--

CREATE TABLE `workshop_specifications` (
  `id` int(11) NOT NULL,
  `project_id` int(11) NOT NULL,
  `bedrooms` int(11) NOT NULL,
  `bathrooms` int(11) NOT NULL,
  `kitchens` int(11) NOT NULL,
  `living_rooms` int(11) NOT NULL,
  `balconies` int(11) NOT NULL,
  `windows` int(11) NOT NULL,
  `doors` int(11) NOT NULL,
  `parking_spaces` int(11) NOT NULL,
  `elevators` int(11) NOT NULL,
  `roof_area` decimal(10,2) NOT NULL,
  `garden_area` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `workshop_specifications`
--

INSERT INTO `workshop_specifications` (`id`, `project_id`, `bedrooms`, `bathrooms`, `kitchens`, `living_rooms`, `balconies`, `windows`, `doors`, `parking_spaces`, `elevators`, `roof_area`, `garden_area`) VALUES
(1, 1, 5, 5, 1, 1, 1, 10, 6, 1, 1, 800.00, 50.00),
(2, 2, 50, 10, 20, 0, 0, 10, 50, 0, 0, 0.00, 0.00),
(3, 3, 0, 5, 5, 0, 0, 5, 5, 0, 0, 0.00, 0.00),
(4, 4, 552, 55, 52, 0, 0, 52, 5, 0, 0, 0.00, 0.00);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `activity_log`
--
ALTER TABLE `activity_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_record` (`record_type`,`record_id`),
  ADD KEY `idx_module` (`module`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_activity_logs_entity` (`entity_type`,`entity_id`),
  ADD KEY `idx_activity_logs_user` (`user_id`);

--
-- Indexes for table `ac_maintenance_tasks`
--
ALTER TABLE `ac_maintenance_tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `worker_id` (`worker_id`);

--
-- Indexes for table `agent_performance`
--
ALTER TABLE `agent_performance`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_agent_month` (`user_id`,`month`,`year`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_period` (`year`,`month`);

--
-- Indexes for table `agent_purchases`
--
ALTER TABLE `agent_purchases`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `agent_subscription_readings`
--
ALTER TABLE `agent_subscription_readings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `subscription_id` (`subscription_id`),
  ADD KEY `idx_asr_subscription_id` (`subscription_id`),
  ADD KEY `idx_asr_status` (`status`);

--
-- Indexes for table `apartments`
--
ALTER TABLE `apartments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `building_id` (`building_id`),
  ADD KEY `idx_apartments_building_id` (`building_id`),
  ADD KEY `idx_apartments_status` (`status`);

--
-- Indexes for table `apartment_cost_deployments`
--
ALTER TABLE `apartment_cost_deployments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`);

--
-- Indexes for table `apartment_expenses`
--
ALTER TABLE `apartment_expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `approval_chains`
--
ALTER TABLE `approval_chains`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `approval_chain_steps`
--
ALTER TABLE `approval_chain_steps`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_chain` (`chain_id`);

--
-- Indexes for table `approval_requests`
--
ALTER TABLE `approval_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_requester` (`requester_id`);

--
-- Indexes for table `approval_request_steps`
--
ALTER TABLE `approval_request_steps`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_request` (`request_id`);

--
-- Indexes for table `approval_settings`
--
ALTER TABLE `approval_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `audit_reports`
--
ALTER TABLE `audit_reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_employee` (`employee_id`),
  ADD KEY `idx_table_record` (`table_name`,`record_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_severity` (`severity`);

--
-- Indexes for table `audit_scan_runs`
--
ALTER TABLE `audit_scan_runs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `audit_trail`
--
ALTER TABLE `audit_trail`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_report` (`audit_report_id`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `buildings`
--
ALTER TABLE `buildings`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `building_events`
--
ALTER TABLE `building_events`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `building_health_scores`
--
ALTER TABLE `building_health_scores`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `building_id` (`building_id`);

--
-- Indexes for table `building_restrictions`
--
ALTER TABLE `building_restrictions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_building` (`user_id`,`building_id`),
  ADD KEY `idx_user` (`user_id`);

--
-- Indexes for table `button_permissions`
--
ALTER TABLE `button_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_page_button` (`role`,`page_key`,`button_key`);

--
-- Indexes for table `cashier_sessions`
--
ALTER TABLE `cashier_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `cash_drawers`
--
ALTER TABLE `cash_drawers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `constructions`
--
ALTER TABLE `constructions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `construction_materials`
--
ALTER TABLE `construction_materials`
  ADD PRIMARY KEY (`id`),
  ADD KEY `construction_id` (`construction_id`);

--
-- Indexes for table `construction_material_movements`
--
ALTER TABLE `construction_material_movements`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `construction_site_stock`
--
ALTER TABLE `construction_site_stock`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `contracts`
--
ALTER TABLE `contracts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `tenant_id` (`tenant_id`),
  ADD KEY `idx_contracts_apartment_id` (`apartment_id`),
  ADD KEY `idx_contracts_tenant_id` (`tenant_id`),
  ADD KEY `idx_contracts_status` (`status`);

--
-- Indexes for table `contract_versions`
--
ALTER TABLE `contract_versions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_contract_versions_contract` (`contract_id`);

--
-- Indexes for table `correction_requests`
--
ALTER TABLE `correction_requests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `daily_logs`
--
ALTER TABLE `daily_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `daily_reports`
--
ALTER TABLE `daily_reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `agent_id` (`agent_id`),
  ADD KEY `building_id` (`building_id`);

--
-- Indexes for table `damage_reports`
--
ALTER TABLE `damage_reports`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transaction_id` (`transaction_id`);

--
-- Indexes for table `department_restrictions`
--
ALTER TABLE `department_restrictions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_dept_module` (`role`,`department`,`restricted_module`);

--
-- Indexes for table `depots`
--
ALTER TABLE `depots`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `depot_transfers`
--
ALTER TABLE `depot_transfers`
  ADD PRIMARY KEY (`id`),
  ADD KEY `from_depot_id` (`from_depot_id`),
  ADD KEY `to_depot_id` (`to_depot_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `depot_transfer_items`
--
ALTER TABLE `depot_transfer_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transfer_id` (`transfer_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `electricity_invoices`
--
ALTER TABLE `electricity_invoices`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `idx_electricity_invoices_apartment_id` (`apartment_id`),
  ADD KEY `idx_electricity_invoices_status` (`status`),
  ADD KEY `idx_electricity_invoices_type` (`type`);

--
-- Indexes for table `electricity_meter_readings`
--
ALTER TABLE `electricity_meter_readings`
  ADD PRIMARY KEY (`id`),
  ADD KEY `apartment_id` (`apartment_id`);

--
-- Indexes for table `electricity_subscriptions`
--
ALTER TABLE `electricity_subscriptions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_apartment_type` (`apartment_id`,`type`),
  ADD KEY `idx_electricity_subs_apartment_id` (`apartment_id`),
  ADD KEY `idx_electricity_subs_status` (`status`);

--
-- Indexes for table `energy_alerts`
--
ALTER TABLE `energy_alerts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `enterprise_activity_log`
--
ALTER TABLE `enterprise_activity_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_time` (`user_id`,`created_at`),
  ADD KEY `idx_module_action` (`module`,`action`),
  ADD KEY `idx_building` (`building_id`),
  ADD KEY `idx_department` (`department_id`);

--
-- Indexes for table `enterprise_settings`
--
ALTER TABLE `enterprise_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `estimation_rates`
--
ALTER TABLE `estimation_rates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `item_name` (`item_name`);

--
-- Indexes for table `expenses`
--
ALTER TABLE `expenses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `field_agent_assignments`
--
ALTER TABLE `field_agent_assignments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `field_agent_tasks`
--
ALTER TABLE `field_agent_tasks`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `field_permissions`
--
ALTER TABLE `field_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_entity_field` (`role`,`entity`,`field_name`);

--
-- Indexes for table `financial_activity_log`
--
ALTER TABLE `financial_activity_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_time` (`user_id`,`created_at`),
  ADD KEY `idx_module_action` (`module`,`action`);

--
-- Indexes for table `financial_audit_issues`
--
ALTER TABLE `financial_audit_issues`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_issue_type` (`issue_type`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `financial_transactions`
--
ALTER TABLE `financial_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_apartment` (`apartment_id`),
  ADD KEY `idx_building` (`building_id`),
  ADD KEY `idx_type` (`transaction_type`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `fuel_movements`
--
ALTER TABLE `fuel_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `generator_id` (`generator_id`),
  ADD KEY `supplier_id` (`supplier_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `generators`
--
ALTER TABLE `generators`
  ADD PRIMARY KEY (`id`),
  ADD KEY `building_id` (`building_id`);

--
-- Indexes for table `generator_ai_profiles`
--
ALTER TABLE `generator_ai_profiles`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `generator_id` (`generator_id`);

--
-- Indexes for table `generator_ai_summaries`
--
ALTER TABLE `generator_ai_summaries`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `date` (`date`);

--
-- Indexes for table `generator_alerts`
--
ALTER TABLE `generator_alerts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `generator_id` (`generator_id`),
  ADD KEY `report_id` (`report_id`);

--
-- Indexes for table `generator_analysis_archived`
--
ALTER TABLE `generator_analysis_archived`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_gen_date` (`generator_id`,`reading_date`);

--
-- Indexes for table `generator_daily_reports`
--
ALTER TABLE `generator_daily_reports`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_generator_date` (`generator_id`,`date`),
  ADD KEY `submitted_by` (`submitted_by`);

--
-- Indexes for table `generator_daily_reports_archived`
--
ALTER TABLE `generator_daily_reports_archived`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_generator_date` (`generator_id`,`date`),
  ADD KEY `submitted_by` (`submitted_by`);

--
-- Indexes for table `generator_predictions_archived`
--
ALTER TABLE `generator_predictions_archived`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_gen_pred_date` (`generator_id`,`prediction_date`);

--
-- Indexes for table `global_menus`
--
ALTER TABLE `global_menus`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `menu_key` (`menu_key`);

--
-- Indexes for table `global_settings`
--
ALTER TABLE `global_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`);

--
-- Indexes for table `insurance_accounts`
--
ALTER TABLE `insurance_accounts`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `contract_id` (`contract_id`);

--
-- Indexes for table `insurance_transactions`
--
ALTER TABLE `insurance_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `account_id` (`account_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `integrity_issues`
--
ALTER TABLE `integrity_issues`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_issue_type` (`issue_type`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `inventory_items`
--
ALTER TABLE `inventory_items`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `item_id` (`item_id`);

--
-- Indexes for table `invoices`
--
ALTER TABLE `invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`);

--
-- Indexes for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_id` (`invoice_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `journal_entries`
--
ALTER TABLE `journal_entries`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_journal_entries_date` (`date`),
  ADD KEY `idx_journal_entries_debit` (`debit_account_id`),
  ADD KEY `idx_journal_entries_credit` (`credit_account_id`);

--
-- Indexes for table `menu_permissions`
--
ALTER TABLE `menu_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_menu` (`role`,`menu_key`);

--
-- Indexes for table `mobile_sync_conflicts`
--
ALTER TABLE `mobile_sync_conflicts`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_notifications_user_id` (`user_id`),
  ADD KEY `idx_notifications_is_read` (`is_read`);

--
-- Indexes for table `notification_messages`
--
ALTER TABLE `notification_messages`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `notification_templates`
--
ALTER TABLE `notification_templates`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`);

--
-- Indexes for table `page_permissions`
--
ALTER TABLE `page_permissions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_role_page` (`role`,`page_key`);

--
-- Indexes for table `permission_profiles`
--
ALTER TABLE `permission_profiles`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `code` (`code`),
  ADD UNIQUE KEY `reference` (`reference`),
  ADD UNIQUE KEY `barcode` (`barcode`);

--
-- Indexes for table `product_depots`
--
ALTER TABLE `product_depots`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `product_depot_unique` (`product_id`,`depot_id`),
  ADD KEY `depot_id` (`depot_id`);

--
-- Indexes for table `product_price_history`
--
ALTER TABLE `product_price_history`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `purchase_requests`
--
ALTER TABLE `purchase_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `project_id` (`project_id`),
  ADD KEY `item_id` (`item_id`);

--
-- Indexes for table `reading_audit_logs`
--
ALTER TABLE `reading_audit_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `reading_versions`
--
ALTER TABLE `reading_versions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_reading` (`reading_type`,`reading_id`),
  ADD KEY `idx_editor` (`edited_by`);

--
-- Indexes for table `renewal_requests`
--
ALTER TABLE `renewal_requests`
  ADD PRIMARY KEY (`id`),
  ADD KEY `contract_id` (`contract_id`);

--
-- Indexes for table `rent_collection_requests`
--
ALTER TABLE `rent_collection_requests`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_request` (`contract_id`,`rent_period_id`),
  ADD KEY `tenant_id` (`tenant_id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `assigned_agent_id` (`assigned_agent_id`);

--
-- Indexes for table `rent_invoices`
--
ALTER TABLE `rent_invoices`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `invoice_number` (`invoice_number`),
  ADD KEY `contract_id` (`contract_id`),
  ADD KEY `idx_rent_invoices_status` (`status`),
  ADD KEY `idx_rent_invoices_period` (`rent_period_id`);

--
-- Indexes for table `rent_payments`
--
ALTER TABLE `rent_payments`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invoice_id` (`invoice_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `rent_periods`
--
ALTER TABLE `rent_periods`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_rent_periods_contract` (`contract_id`),
  ADD KEY `idx_rent_periods_start_end` (`start_date`,`end_date`);

--
-- Indexes for table `rent_profiles`
--
ALTER TABLE `rent_profiles`
  ADD PRIMARY KEY (`id`),
  ADD KEY `tenant_id` (`tenant_id`),
  ADD KEY `apartment_id` (`apartment_id`),
  ADD KEY `contract_id` (`contract_id`);

--
-- Indexes for table `rent_profile_history`
--
ALTER TABLE `rent_profile_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `rent_profile_id` (`rent_profile_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `returns`
--
ALTER TABLE `returns`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `return_invoice_number` (`return_invoice_number`);

--
-- Indexes for table `return_items`
--
ALTER TABLE `return_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `return_id` (`return_id`);

--
-- Indexes for table `rich_audit_logs`
--
ALTER TABLE `rich_audit_logs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `sales_audits`
--
ALTER TABLE `sales_audits`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `scheduled_jobs`
--
ALTER TABLE `scheduled_jobs`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `job_name` (`job_name`),
  ADD KEY `idx_scheduled_jobs_status` (`status`);

--
-- Indexes for table `security_activity_log`
--
ALTER TABLE `security_activity_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_time` (`user_id`,`created_at`),
  ADD KEY `idx_action` (`action`);

--
-- Indexes for table `security_events`
--
ALTER TABLE `security_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_event_type` (`event_type`),
  ADD KEY `idx_severity` (`severity`),
  ADD KEY `idx_user` (`user_id`),
  ADD KEY `idx_created` (`created_at`);

--
-- Indexes for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `subscription_history`
--
ALTER TABLE `subscription_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `subscription_id` (`subscription_id`);

--
-- Indexes for table `suppliers`
--
ALTER TABLE `suppliers`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_payments`
--
ALTER TABLE `supplier_payments`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_payment_allocations`
--
ALTER TABLE `supplier_payment_allocations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `supplier_transactions`
--
ALTER TABLE `supplier_transactions`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `system_activity_log`
--
ALTER TABLE `system_activity_log`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_action` (`action`);

--
-- Indexes for table `tasks`
--
ALTER TABLE `tasks`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tasks_assigned_to` (`assigned_to`),
  ADD KEY `idx_tasks_status` (`status`),
  ADD KEY `idx_tasks_due_date` (`due_date`);

--
-- Indexes for table `task_assignment_history`
--
ALTER TABLE `task_assignment_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_task_assignment_history_task_id` (`task_id`);

--
-- Indexes for table `temp_permissions`
--
ALTER TABLE `temp_permissions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_active` (`user_id`,`is_active`),
  ADD KEY `idx_expires` (`expires_at`);

--
-- Indexes for table `tenants`
--
ALTER TABLE `tenants`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `idx_tenants_status` (`status`);

--
-- Indexes for table `tenant_archive_history`
--
ALTER TABLE `tenant_archive_history`
  ADD PRIMARY KEY (`archive_id`);

--
-- Indexes for table `tenant_documents`
--
ALTER TABLE `tenant_documents`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_document_type` (`user_id`,`document_type`);

--
-- Indexes for table `tenant_maintenance_tickets`
--
ALTER TABLE `tenant_maintenance_tickets`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_tenant_id` (`tenant_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `tenant_request_slas`
--
ALTER TABLE `tenant_request_slas`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `translations`
--
ALTER TABLE `translations`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `key_lang` (`translation_key`,`lang_code`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD UNIQUE KEY `username` (`username`);

--
-- Indexes for table `user_sessions`
--
ALTER TABLE `user_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_session` (`user_id`,`session_token`),
  ADD KEY `idx_last_activity` (`last_activity`);

--
-- Indexes for table `validation_rules`
--
ALTER TABLE `validation_rules`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `mod_field` (`module`,`field_name`);

--
-- Indexes for table `worker_device_telemetry`
--
ALTER TABLE `worker_device_telemetry`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `user_id` (`user_id`);

--
-- Indexes for table `workshop_estimates`
--
ALTER TABLE `workshop_estimates`
  ADD PRIMARY KEY (`id`),
  ADD KEY `project_id` (`project_id`);

--
-- Indexes for table `workshop_projects`
--
ALTER TABLE `workshop_projects`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `workshop_specifications`
--
ALTER TABLE `workshop_specifications`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `project_id` (`project_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `activity_log`
--
ALTER TABLE `activity_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `ac_maintenance_tasks`
--
ALTER TABLE `ac_maintenance_tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT for table `agent_performance`
--
ALTER TABLE `agent_performance`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `agent_purchases`
--
ALTER TABLE `agent_purchases`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `agent_subscription_readings`
--
ALTER TABLE `agent_subscription_readings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `apartments`
--
ALTER TABLE `apartments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `apartment_cost_deployments`
--
ALTER TABLE `apartment_cost_deployments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `apartment_expenses`
--
ALTER TABLE `apartment_expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `approval_chains`
--
ALTER TABLE `approval_chains`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `approval_chain_steps`
--
ALTER TABLE `approval_chain_steps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `approval_requests`
--
ALTER TABLE `approval_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `approval_request_steps`
--
ALTER TABLE `approval_request_steps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `approval_settings`
--
ALTER TABLE `approval_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `audit_logs`
--
ALTER TABLE `audit_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=110;

--
-- AUTO_INCREMENT for table `audit_reports`
--
ALTER TABLE `audit_reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `audit_scan_runs`
--
ALTER TABLE `audit_scan_runs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `audit_trail`
--
ALTER TABLE `audit_trail`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=48;

--
-- AUTO_INCREMENT for table `buildings`
--
ALTER TABLE `buildings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `building_events`
--
ALTER TABLE `building_events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `building_health_scores`
--
ALTER TABLE `building_health_scores`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `building_restrictions`
--
ALTER TABLE `building_restrictions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `button_permissions`
--
ALTER TABLE `button_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `cashier_sessions`
--
ALTER TABLE `cashier_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `cash_drawers`
--
ALTER TABLE `cash_drawers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `constructions`
--
ALTER TABLE `constructions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `construction_materials`
--
ALTER TABLE `construction_materials`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `construction_material_movements`
--
ALTER TABLE `construction_material_movements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `construction_site_stock`
--
ALTER TABLE `construction_site_stock`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `contracts`
--
ALTER TABLE `contracts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `contract_versions`
--
ALTER TABLE `contract_versions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `correction_requests`
--
ALTER TABLE `correction_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `daily_logs`
--
ALTER TABLE `daily_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `daily_reports`
--
ALTER TABLE `daily_reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `damage_reports`
--
ALTER TABLE `damage_reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `department_restrictions`
--
ALTER TABLE `department_restrictions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `depots`
--
ALTER TABLE `depots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `depot_transfers`
--
ALTER TABLE `depot_transfers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `depot_transfer_items`
--
ALTER TABLE `depot_transfer_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `electricity_invoices`
--
ALTER TABLE `electricity_invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=246;

--
-- AUTO_INCREMENT for table `electricity_meter_readings`
--
ALTER TABLE `electricity_meter_readings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=124;

--
-- AUTO_INCREMENT for table `electricity_subscriptions`
--
ALTER TABLE `electricity_subscriptions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT for table `energy_alerts`
--
ALTER TABLE `energy_alerts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `enterprise_activity_log`
--
ALTER TABLE `enterprise_activity_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2259;

--
-- AUTO_INCREMENT for table `enterprise_settings`
--
ALTER TABLE `enterprise_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `estimation_rates`
--
ALTER TABLE `estimation_rates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=22;

--
-- AUTO_INCREMENT for table `expenses`
--
ALTER TABLE `expenses`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=15;

--
-- AUTO_INCREMENT for table `field_agent_assignments`
--
ALTER TABLE `field_agent_assignments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `field_agent_tasks`
--
ALTER TABLE `field_agent_tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `field_permissions`
--
ALTER TABLE `field_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `financial_activity_log`
--
ALTER TABLE `financial_activity_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `financial_audit_issues`
--
ALTER TABLE `financial_audit_issues`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `financial_transactions`
--
ALTER TABLE `financial_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `fuel_movements`
--
ALTER TABLE `fuel_movements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `generators`
--
ALTER TABLE `generators`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `generator_ai_profiles`
--
ALTER TABLE `generator_ai_profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `generator_ai_summaries`
--
ALTER TABLE `generator_ai_summaries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=65;

--
-- AUTO_INCREMENT for table `generator_alerts`
--
ALTER TABLE `generator_alerts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `generator_analysis_archived`
--
ALTER TABLE `generator_analysis_archived`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `generator_daily_reports`
--
ALTER TABLE `generator_daily_reports`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `generator_daily_reports_archived`
--
ALTER TABLE `generator_daily_reports_archived`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=45;

--
-- AUTO_INCREMENT for table `generator_predictions_archived`
--
ALTER TABLE `generator_predictions_archived`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `global_menus`
--
ALTER TABLE `global_menus`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `global_settings`
--
ALTER TABLE `global_settings`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;

--
-- AUTO_INCREMENT for table `insurance_accounts`
--
ALTER TABLE `insurance_accounts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `insurance_transactions`
--
ALTER TABLE `insurance_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=62;

--
-- AUTO_INCREMENT for table `integrity_issues`
--
ALTER TABLE `integrity_issues`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `inventory_items`
--
ALTER TABLE `inventory_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `invoices`
--
ALTER TABLE `invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT for table `invoice_items`
--
ALTER TABLE `invoice_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `journal_entries`
--
ALTER TABLE `journal_entries`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `menu_permissions`
--
ALTER TABLE `menu_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `mobile_sync_conflicts`
--
ALTER TABLE `mobile_sync_conflicts`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `notification_messages`
--
ALTER TABLE `notification_messages`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notification_templates`
--
ALTER TABLE `notification_templates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `page_permissions`
--
ALTER TABLE `page_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=254;

--
-- AUTO_INCREMENT for table `permission_profiles`
--
ALTER TABLE `permission_profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `product_depots`
--
ALTER TABLE `product_depots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `product_price_history`
--
ALTER TABLE `product_price_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `purchase_orders`
--
ALTER TABLE `purchase_orders`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `purchase_requests`
--
ALTER TABLE `purchase_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reading_audit_logs`
--
ALTER TABLE `reading_audit_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `reading_versions`
--
ALTER TABLE `reading_versions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `renewal_requests`
--
ALTER TABLE `renewal_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `rent_collection_requests`
--
ALTER TABLE `rent_collection_requests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rent_invoices`
--
ALTER TABLE `rent_invoices`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=238;

--
-- AUTO_INCREMENT for table `rent_payments`
--
ALTER TABLE `rent_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `rent_periods`
--
ALTER TABLE `rent_periods`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=113;

--
-- AUTO_INCREMENT for table `rent_profiles`
--
ALTER TABLE `rent_profiles`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=30;

--
-- AUTO_INCREMENT for table `rent_profile_history`
--
ALTER TABLE `rent_profile_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `returns`
--
ALTER TABLE `returns`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `return_items`
--
ALTER TABLE `return_items`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `rich_audit_logs`
--
ALTER TABLE `rich_audit_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `sales_audits`
--
ALTER TABLE `sales_audits`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scheduled_jobs`
--
ALTER TABLE `scheduled_jobs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `security_activity_log`
--
ALTER TABLE `security_activity_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `security_events`
--
ALTER TABLE `security_events`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `stock_movements`
--
ALTER TABLE `stock_movements`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=42;

--
-- AUTO_INCREMENT for table `subscription_history`
--
ALTER TABLE `subscription_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `suppliers`
--
ALTER TABLE `suppliers`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `supplier_payments`
--
ALTER TABLE `supplier_payments`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `supplier_payment_allocations`
--
ALTER TABLE `supplier_payment_allocations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `supplier_transactions`
--
ALTER TABLE `supplier_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `system_activity_log`
--
ALTER TABLE `system_activity_log`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tasks`
--
ALTER TABLE `tasks`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `task_assignment_history`
--
ALTER TABLE `task_assignment_history`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `temp_permissions`
--
ALTER TABLE `temp_permissions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tenants`
--
ALTER TABLE `tenants`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `tenant_archive_history`
--
ALTER TABLE `tenant_archive_history`
  MODIFY `archive_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tenant_documents`
--
ALTER TABLE `tenant_documents`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=31;

--
-- AUTO_INCREMENT for table `tenant_maintenance_tickets`
--
ALTER TABLE `tenant_maintenance_tickets`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `tenant_request_slas`
--
ALTER TABLE `tenant_request_slas`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `translations`
--
ALTER TABLE `translations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=262;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `user_sessions`
--
ALTER TABLE `user_sessions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14137;

--
-- AUTO_INCREMENT for table `validation_rules`
--
ALTER TABLE `validation_rules`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `worker_device_telemetry`
--
ALTER TABLE `worker_device_telemetry`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `workshop_estimates`
--
ALTER TABLE `workshop_estimates`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=85;

--
-- AUTO_INCREMENT for table `workshop_projects`
--
ALTER TABLE `workshop_projects`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `workshop_specifications`
--
ALTER TABLE `workshop_specifications`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `ac_maintenance_tasks`
--
ALTER TABLE `ac_maintenance_tasks`
  ADD CONSTRAINT `ac_maintenance_tasks_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `ac_maintenance_tasks_ibfk_2` FOREIGN KEY (`worker_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `agent_subscription_readings`
--
ALTER TABLE `agent_subscription_readings`
  ADD CONSTRAINT `agent_subscription_readings_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `agent_subscription_readings_ibfk_2` FOREIGN KEY (`subscription_id`) REFERENCES `electricity_subscriptions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `apartments`
--
ALTER TABLE `apartments`
  ADD CONSTRAINT `apartments_ibfk_1` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `apartment_cost_deployments`
--
ALTER TABLE `apartment_cost_deployments`
  ADD CONSTRAINT `apartment_cost_deployments_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `apartment_expenses`
--
ALTER TABLE `apartment_expenses`
  ADD CONSTRAINT `apartment_expenses_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `apartment_expenses_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Constraints for table `audit_logs`
--
ALTER TABLE `audit_logs`
  ADD CONSTRAINT `audit_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `building_health_scores`
--
ALTER TABLE `building_health_scores`
  ADD CONSTRAINT `building_health_scores_ibfk_1` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `cashier_sessions`
--
ALTER TABLE `cashier_sessions`
  ADD CONSTRAINT `cashier_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `cash_drawers`
--
ALTER TABLE `cash_drawers`
  ADD CONSTRAINT `cash_drawers_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `construction_materials`
--
ALTER TABLE `construction_materials`
  ADD CONSTRAINT `construction_materials_ibfk_1` FOREIGN KEY (`construction_id`) REFERENCES `constructions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `contracts`
--
ALTER TABLE `contracts`
  ADD CONSTRAINT `contracts_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `contracts_ibfk_2` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `contract_versions`
--
ALTER TABLE `contract_versions`
  ADD CONSTRAINT `contract_versions_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `daily_reports`
--
ALTER TABLE `daily_reports`
  ADD CONSTRAINT `daily_reports_ibfk_1` FOREIGN KEY (`agent_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `daily_reports_ibfk_2` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `damage_reports`
--
ALTER TABLE `damage_reports`
  ADD CONSTRAINT `damage_reports_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `insurance_transactions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `depot_transfers`
--
ALTER TABLE `depot_transfers`
  ADD CONSTRAINT `depot_transfers_ibfk_1` FOREIGN KEY (`from_depot_id`) REFERENCES `depots` (`id`),
  ADD CONSTRAINT `depot_transfers_ibfk_2` FOREIGN KEY (`to_depot_id`) REFERENCES `depots` (`id`),
  ADD CONSTRAINT `depot_transfers_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `depot_transfer_items`
--
ALTER TABLE `depot_transfer_items`
  ADD CONSTRAINT `depot_transfer_items_ibfk_1` FOREIGN KEY (`transfer_id`) REFERENCES `depot_transfers` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `depot_transfer_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `electricity_invoices`
--
ALTER TABLE `electricity_invoices`
  ADD CONSTRAINT `electricity_invoices_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `electricity_meter_readings`
--
ALTER TABLE `electricity_meter_readings`
  ADD CONSTRAINT `electricity_meter_readings_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `electricity_subscriptions`
--
ALTER TABLE `electricity_subscriptions`
  ADD CONSTRAINT `electricity_subscriptions_ibfk_1` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `expenses`
--
ALTER TABLE `expenses`
  ADD CONSTRAINT `expenses_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `fuel_movements`
--
ALTER TABLE `fuel_movements`
  ADD CONSTRAINT `fuel_movements_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fuel_movements_ibfk_2` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fuel_movements_ibfk_3` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `generators`
--
ALTER TABLE `generators`
  ADD CONSTRAINT `generators_ibfk_1` FOREIGN KEY (`building_id`) REFERENCES `buildings` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `generator_ai_profiles`
--
ALTER TABLE `generator_ai_profiles`
  ADD CONSTRAINT `generator_ai_profiles_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `generator_alerts`
--
ALTER TABLE `generator_alerts`
  ADD CONSTRAINT `generator_alerts_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `generator_alerts_ibfk_2` FOREIGN KEY (`report_id`) REFERENCES `generator_daily_reports_archived` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `generator_analysis_archived`
--
ALTER TABLE `generator_analysis_archived`
  ADD CONSTRAINT `generator_analysis_archived_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `generator_daily_reports`
--
ALTER TABLE `generator_daily_reports`
  ADD CONSTRAINT `generator_daily_reports_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `generator_daily_reports_ibfk_2` FOREIGN KEY (`submitted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `generator_daily_reports_archived`
--
ALTER TABLE `generator_daily_reports_archived`
  ADD CONSTRAINT `generator_daily_reports_archived_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `generator_daily_reports_archived_ibfk_2` FOREIGN KEY (`submitted_by`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `generator_predictions_archived`
--
ALTER TABLE `generator_predictions_archived`
  ADD CONSTRAINT `generator_predictions_archived_ibfk_1` FOREIGN KEY (`generator_id`) REFERENCES `generators` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `insurance_accounts`
--
ALTER TABLE `insurance_accounts`
  ADD CONSTRAINT `insurance_accounts_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `insurance_transactions`
--
ALTER TABLE `insurance_transactions`
  ADD CONSTRAINT `insurance_transactions_ibfk_1` FOREIGN KEY (`account_id`) REFERENCES `insurance_accounts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `insurance_transactions_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `inventory_transactions`
--
ALTER TABLE `inventory_transactions`
  ADD CONSTRAINT `inventory_transactions_ibfk_1` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`id`);

--
-- Constraints for table `invoice_items`
--
ALTER TABLE `invoice_items`
  ADD CONSTRAINT `invoice_items_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `invoice_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Constraints for table `journal_entries`
--
ALTER TABLE `journal_entries`
  ADD CONSTRAINT `journal_entries_ibfk_1` FOREIGN KEY (`debit_account_id`) REFERENCES `accounts` (`id`),
  ADD CONSTRAINT `journal_entries_ibfk_2` FOREIGN KEY (`credit_account_id`) REFERENCES `accounts` (`id`);

--
-- Constraints for table `product_depots`
--
ALTER TABLE `product_depots`
  ADD CONSTRAINT `product_depots_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_depots_ibfk_2` FOREIGN KEY (`depot_id`) REFERENCES `depots` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `purchase_requests`
--
ALTER TABLE `purchase_requests`
  ADD CONSTRAINT `purchase_requests_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `workshop_projects` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `purchase_requests_ibfk_2` FOREIGN KEY (`item_id`) REFERENCES `inventory_items` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `renewal_requests`
--
ALTER TABLE `renewal_requests`
  ADD CONSTRAINT `renewal_requests_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rent_collection_requests`
--
ALTER TABLE `rent_collection_requests`
  ADD CONSTRAINT `rent_collection_requests_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_collection_requests_ibfk_2` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_collection_requests_ibfk_3` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_collection_requests_ibfk_4` FOREIGN KEY (`assigned_agent_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `rent_invoices`
--
ALTER TABLE `rent_invoices`
  ADD CONSTRAINT `rent_invoices_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rent_payments`
--
ALTER TABLE `rent_payments`
  ADD CONSTRAINT `rent_payments_ibfk_1` FOREIGN KEY (`invoice_id`) REFERENCES `rent_invoices` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_payments_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `rent_periods`
--
ALTER TABLE `rent_periods`
  ADD CONSTRAINT `rent_periods_ibfk_1` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `rent_profiles`
--
ALTER TABLE `rent_profiles`
  ADD CONSTRAINT `rent_profiles_ibfk_1` FOREIGN KEY (`tenant_id`) REFERENCES `tenants` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_profiles_ibfk_2` FOREIGN KEY (`apartment_id`) REFERENCES `apartments` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_profiles_ibfk_3` FOREIGN KEY (`contract_id`) REFERENCES `contracts` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `rent_profile_history`
--
ALTER TABLE `rent_profile_history`
  ADD CONSTRAINT `rent_profile_history_ibfk_1` FOREIGN KEY (`rent_profile_id`) REFERENCES `rent_profiles` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `rent_profile_history_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `return_items`
--
ALTER TABLE `return_items`
  ADD CONSTRAINT `return_items_ibfk_1` FOREIGN KEY (`return_id`) REFERENCES `returns` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `stock_movements`
--
ALTER TABLE `stock_movements`
  ADD CONSTRAINT `stock_movements_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `subscription_history`
--
ALTER TABLE `subscription_history`
  ADD CONSTRAINT `subscription_history_ibfk_1` FOREIGN KEY (`subscription_id`) REFERENCES `electricity_subscriptions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tasks`
--
ALTER TABLE `tasks`
  ADD CONSTRAINT `tasks_ibfk_1` FOREIGN KEY (`assigned_to`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `task_assignment_history`
--
ALTER TABLE `task_assignment_history`
  ADD CONSTRAINT `task_assignment_history_ibfk_1` FOREIGN KEY (`task_id`) REFERENCES `tasks` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `tenants`
--
ALTER TABLE `tenants`
  ADD CONSTRAINT `tenants_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `workshop_estimates`
--
ALTER TABLE `workshop_estimates`
  ADD CONSTRAINT `workshop_estimates_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `workshop_projects` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `workshop_specifications`
--
ALTER TABLE `workshop_specifications`
  ADD CONSTRAINT `workshop_specifications_ibfk_1` FOREIGN KEY (`project_id`) REFERENCES `workshop_projects` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
