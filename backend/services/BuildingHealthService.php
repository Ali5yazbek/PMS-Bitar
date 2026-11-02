<?php
/**
 * BuildingHealthService.php
 * Calculates and caches a 0–100 health score for each building.
 * Score is based on: missing readings, rejection rate, anomalies,
 * late submissions, and long-pending requests.
 */
class BuildingHealthService {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Get health score for a single building.
     * Returns cached value if less than 1 hour old; otherwise recalculates.
     */
    public function getScore(int $buildingId): array {
        try {
            $stmt = $this->db->prepare("
                SELECT *, TIMESTAMPDIFF(MINUTE, calculated_at, NOW()) as age_minutes
                FROM building_health_scores
                WHERE building_id = ?
            ");
            $stmt->execute([$buildingId]);
            $cached = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($cached && $cached['age_minutes'] < 60) {
                return $cached;
            }
        } catch (PDOException $e) {}

        return $this->calculate($buildingId);
    }

    /**
     * Get health scores for ALL buildings, sorted by score ASC (worst first).
     */
    public function getAllScores(): array {
        try {
            // Recalculate any stale entries (> 1 hour)
            $stmt = $this->db->query("SELECT id FROM buildings ORDER BY name");
            $buildings = $stmt->fetchAll(PDO::FETCH_COLUMN);
            foreach ($buildings as $bId) {
                $this->getScore((int)$bId);
            }

            $stmt = $this->db->query("
                SELECT bhs.*, b.name as building_name
                FROM building_health_scores bhs
                JOIN buildings b ON bhs.building_id = b.id
                ORDER BY bhs.score ASC
            ");
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    /**
     * Recalculate and persist health score for a building.
     */
    public function calculate(int $buildingId): array {
        $scores = [
            'missing_readings_score' => 30.0,
            'rejection_rate_score'   => 25.0,
            'anomaly_score'          => 20.0,
            'late_submission_score'  => 15.0,
            'pending_requests_score' => 10.0,
        ];
        $details = [];

        try {
            // ── 1. Missing readings (max deduction: 30 pts) ────────────────
            $total = (int)$this->db->prepare("
                SELECT COUNT(*) FROM electricity_subscriptions es
                JOIN apartments a ON es.apartment_id = a.id
                WHERE a.building_id = ? AND es.status = 'Active'
            ")->execute([$buildingId]) ? $this->db->prepare("
                SELECT COUNT(*) FROM electricity_subscriptions es
                JOIN apartments a ON es.apartment_id = a.id
                WHERE a.building_id = ? AND es.status = 'Active'
            ")->fetchColumn() : 0;

            // Simpler approach:
            $aptStmt = $this->db->prepare("SELECT COUNT(*) FROM apartments WHERE building_id = ?");
            $aptStmt->execute([$buildingId]);
            $totalApts = (int)$aptStmt->fetchColumn();

            $readStmt = $this->db->prepare("
                SELECT COUNT(DISTINCT emr.apartment_id)
                FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = ? AND emr.reading_date >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
            ");
            $readStmt->execute([$buildingId]);
            $recentRead = (int)$readStmt->fetchColumn();

            $missingPct = $totalApts > 0 ? max(0, 1 - ($recentRead / $totalApts)) : 0;
            $scores['missing_readings_score'] = round(30 * (1 - $missingPct), 2);
            $details['missing_pct'] = round($missingPct * 100, 1);

            // ── 2. Rejection rate last 90 days (max deduction: 25 pts) ────
            $rejStmt = $this->db->prepare("
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN status = 'Rejected' THEN 1 ELSE 0 END) as rejected
                FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = ? AND emr.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
            ");
            $rejStmt->execute([$buildingId]);
            $rejData = $rejStmt->fetch(PDO::FETCH_ASSOC);
            $rejRate = ($rejData['total'] > 0) ? ($rejData['rejected'] / $rejData['total']) : 0;
            $scores['rejection_rate_score'] = round(25 * (1 - $rejRate), 2);
            $details['rejection_rate'] = round($rejRate * 100, 1);

            // ── 3. Anomalies (critical/high risk readings last 60 days) ────
            $anomStmt = $this->db->prepare("
                SELECT COUNT(*) FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = ?
                AND emr.risk_level IN ('high','critical')
                AND emr.created_at >= DATE_SUB(NOW(), INTERVAL 60 DAY)
            ");
            $anomStmt->execute([$buildingId]);
            $anomCount = (int)$anomStmt->fetchColumn();
            $anomScore = max(0, 20 - ($anomCount * 3));
            $scores['anomaly_score'] = (float)$anomScore;
            $details['anomaly_count'] = $anomCount;

            // ── 4. Late submissions (pending > 48h, max deduction: 15 pts) 
            $lateStmt = $this->db->prepare("
                SELECT COUNT(*) FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = ?
                AND emr.status = 'Pending Verification'
                AND emr.created_at < DATE_SUB(NOW(), INTERVAL 48 HOUR)
            ");
            $lateStmt->execute([$buildingId]);
            $lateCount = (int)$lateStmt->fetchColumn();
            $lateScore = max(0, 15 - ($lateCount * 2));
            $scores['late_submission_score'] = (float)$lateScore;
            $details['pending_over_48h'] = $lateCount;

            // ── 5. Pending count (max deduction: 10 pts) ─────────────────
            $pendStmt = $this->db->prepare("
                SELECT COUNT(*) FROM electricity_meter_readings emr
                JOIN apartments a ON emr.apartment_id = a.id
                WHERE a.building_id = ? AND emr.status = 'Pending Verification'
            ");
            $pendStmt->execute([$buildingId]);
            $pendCount = (int)$pendStmt->fetchColumn();
            $pendScore = max(0, 10 - $pendCount);
            $scores['pending_requests_score'] = (float)$pendScore;
            $details['pending_count'] = $pendCount;

        } catch (PDOException $e) {
            error_log("BuildingHealthService::calculate error: " . $e->getMessage());
        }

        $totalScore = array_sum($scores);
        $grade      = $this->getGrade($totalScore);

        // Persist
        try {
            $this->db->prepare("
                INSERT INTO building_health_scores
                    (building_id, score, grade, missing_readings_score, rejection_rate_score,
                     anomaly_score, late_submission_score, pending_requests_score, total_apartments, pending_count, details)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE
                    score = VALUES(score), grade = VALUES(grade),
                    missing_readings_score = VALUES(missing_readings_score),
                    rejection_rate_score = VALUES(rejection_rate_score),
                    anomaly_score = VALUES(anomaly_score),
                    late_submission_score = VALUES(late_submission_score),
                    pending_requests_score = VALUES(pending_requests_score),
                    total_apartments = VALUES(total_apartments),
                    pending_count = VALUES(pending_count),
                    details = VALUES(details),
                    calculated_at = NOW()
            ")->execute([
                $buildingId,
                $totalScore,
                $grade,
                $scores['missing_readings_score'],
                $scores['rejection_rate_score'],
                $scores['anomaly_score'],
                $scores['late_submission_score'],
                $scores['pending_requests_score'],
                $details['missing_pct'] ?? 0,
                $details['pending_count'] ?? 0,
                json_encode(array_merge($scores, $details)),
            ]);
        } catch (PDOException $e) {}

        return array_merge([
            'building_id' => $buildingId,
            'score'       => $totalScore,
            'grade'       => $grade,
        ], $scores, ['details' => $details]);
    }

    private function getGrade(float $score): string {
        if ($score >= 90) return 'Excellent';
        if ($score >= 75) return 'Good';
        if ($score >= 55) return 'Fair';
        if ($score >= 35) return 'Poor';
        return 'Critical';
    }
}
