<?php
namespace Controllers;

use Core\Database;
use Core\Response;

class TaskController {
    private $db;

    public function __construct() {
        $this->db = Database::getInstance()->getConnection();
    }

    /**
     * Get all tasks for the logged-in user, across all modules
     */
    public function getMyTasks($userId) {
        try {
            $stmt = $this->db->prepare("
                SELECT t.*, u.full_name as assigned_by_name
                FROM tasks t
                LEFT JOIN users u ON t.assigned_to = u.id
                WHERE t.assigned_to = ? AND t.status NOT IN ('Completed', 'Cancelled')
                ORDER BY 
                    CASE t.priority 
                        WHEN 'Urgent' THEN 1 
                        WHEN 'High' THEN 2 
                        WHEN 'Normal' THEN 3 
                        WHEN 'Low' THEN 4 
                    END,
                    t.due_date ASC
            ");
            $stmt->execute([$userId]);
            $tasks = $stmt->fetchAll(\PDO::FETCH_ASSOC);

            return Response::json(['status' => 'success', 'data' => $tasks]);
        } catch (\Exception $e) {
            return Response::json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Update Task Status
     */
    public function updateTaskStatus($taskId, $status, $userId) {
        try {
            $this->db->beginTransaction();

            $stmt = $this->db->prepare("UPDATE tasks SET status = ? WHERE id = ?");
            $stmt->execute([$status, $taskId]);

            // Log history
            $action = 'Assigned'; // default
            if ($status === 'In Progress') $action = 'Started';
            if ($status === 'Completed') $action = 'Completed';
            if ($status === 'Cancelled') $action = 'Cancelled';

            $stmt = $this->db->prepare("
                INSERT INTO task_assignment_history (task_id, new_agent_id, action) 
                VALUES (?, ?, ?)
            ");
            $stmt->execute([$taskId, $userId, $action]);

            // Unified Activity Log
            $stmt = $this->db->prepare("INSERT INTO activity_logs (user_id, action, entity_type, entity_id) VALUES (?, ?, 'Task', ?)");
            $stmt->execute([$userId, "Task status changed to " . $status, $taskId]);

            $this->db->commit();
            return Response::json(['status' => 'success']);
        } catch (\Exception $e) {
            $this->db->rollBack();
            return Response::json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
