<?php
/**
 * AgentPerformanceService.php
 * Tracks and exposes agent metrics (accuracy, approval rate, rejection rate, 
 * late submissions) and builds the monthly leaderboard.
 */
class AgentPerformanceService {
    private PDO $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Get the leaderboard for a given month and year.
     * Re-calculates ranks dynamically before returning.
     */
    public function getLeaderboard(int $month, int $year): array {
        try {
            // First ensure accuracy metrics are up to date (this handles any drift)
            $this->updateMetrics($month, $year);
            $this->updateRanks($month, $year);

            $stmt = $this->db->prepare("
                SELECT ap.*, u.name as agent_name, u.email as agent_email
                FROM agent_performance ap
                JOIN users u ON ap.user_id = u.id
                WHERE ap.month = ? AND ap.year = ? AND u.role = 'manager' -- assuming field agents are managers
                ORDER BY ap.rank_in_period ASC
            ");
            $stmt->execute([$month, $year]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);

        } catch (PDOException $e) {
            error_log("AgentPerformanceService::getLeaderboard error: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get individual agent stats.
     */
    public function getAgentStats(int $userId, int $month, int $year): ?array {
        try {
            $stmt = $this->db->prepare("
                SELECT * FROM agent_performance
                WHERE user_id = ? AND month = ? AND year = ?
            ");
            $stmt->execute([$userId, $month, $year]);
            return $stmt->fetch(PDO::FETCH_ASSOC) ?: null;
        } catch (PDOException $e) {
            return null;
        }
    }

    /**
     * Updates accuracy/approval rates for all agents in a given month.
     * Normally handled incrementally by FinancialSyncService, but good to run in batch.
     */
    private function updateMetrics(int $month, int $year): void {
        $this->db->prepare("
            UPDATE agent_performance
            SET accuracy_score = CASE WHEN total_submissions > 0
                THEN ROUND((approved_count / total_submissions) * 100, 2) ELSE 100 END,
                approval_rate = CASE WHEN total_submissions > 0
                THEN ROUND((approved_count / total_submissions) * 100, 2) ELSE 100 END,
                rejection_rate = CASE WHEN total_submissions > 0
                THEN ROUND((rejected_count / total_submissions) * 100, 2) ELSE 0 END
            WHERE month = ? AND year = ?
        ")->execute([$month, $year]);
    }

    /**
     * Computes the `rank_in_period` based on accuracy_score and total_submissions.
     */
    private function updateRanks(int $month, int $year): void {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("
                SELECT id FROM agent_performance
                WHERE month = ? AND year = ?
                ORDER BY accuracy_score DESC, approved_count DESC
            ");
            $stmt->execute([$month, $year]);
            
            $rank = 1;
            $updateStmt = $this->db->prepare("UPDATE agent_performance SET rank_in_period = ? WHERE id = ?");
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                $updateStmt->execute([$rank, $row['id']]);
                $rank++;
            }

            $this->db->commit();
        } catch (PDOException $e) {
            $this->db->rollBack();
        }
    }
}
