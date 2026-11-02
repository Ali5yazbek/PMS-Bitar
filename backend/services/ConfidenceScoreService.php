<?php
/**
 * ConfidenceScoreService.php
 * Translates anomaly warnings into a 0–100 confidence score,
 * a risk level, and a priority order for queue sorting.
 */
class ConfidenceScoreService {

    // Score deduction per warning code
    private const DEDUCTIONS = [
        'METER_ROLLBACK'         => 65,
        'POSSIBLE_DIGIT_ERROR'   => 28,
        'DUPLICATE_READING'      => 22,
        'HIGH_CONSUMPTION'       => 18,
        'UNUSUAL_MONTHLY_SPIKE'  => 18,
        'MISSING_IMAGE'          => 12,
        'LOW_CONSUMPTION'        => 10,
        'LONG_WITHOUT_READING'   => 6,
        'FIRST_READING'          => 0,   // informational only
    ];

    // Minimum score when a warning is present (floor per level)
    private const LEVEL_FLOORS = [
        'critical' => 0,
        'high'     => 10,
        'medium'   => 30,
        'low'      => 60,
        'info'     => 85,
    ];

    /**
     * Calculate confidence score (0–100) from a list of warning objects.
     *
     * @param array $warnings   Output from ReadingAnalysisService::analyze()['warnings']
     * @param array $settings   ['critical_confidence_score' => '40', 'medium_confidence_score' => '70']
     * @return array { score, risk_level, priority, label, color }
     */
    public function calculate(array $warnings, array $settings = []): array {
        $score = 100;

        foreach ($warnings as $w) {
            $code      = $w['code']  ?? '';
            $level     = $w['level'] ?? 'info';
            $deduction = self::DEDUCTIONS[$code] ?? 5;
            $score    -= $deduction;

            // Apply floor based on level
            $floor = self::LEVEL_FLOORS[$level] ?? 0;
            $score  = max($score, $floor);
        }

        $score = max(0, min(100, $score));

        $criticalThreshold = (int)($settings['critical_confidence_score'] ?? 40);
        $mediumThreshold   = (int)($settings['medium_confidence_score']   ?? 70);

        return [
            'score'      => $score,
            'risk_level' => $this->getRiskLevel($score, $criticalThreshold, $mediumThreshold),
            'priority'   => $this->getPriority($score, $criticalThreshold, $mediumThreshold),
            'label'      => $this->getLabel($score, $criticalThreshold, $mediumThreshold),
            'color'      => $this->getColor($score, $criticalThreshold, $mediumThreshold),
        ];
    }

    /**
     * Determine risk level from score.
     */
    public function getRiskLevel(int $score, int $critical = 40, int $medium = 70): string {
        if ($score <= $critical)        return 'critical';
        if ($score <= $critical + 15)   return 'high';
        if ($score <= $medium)          return 'medium';
        return 'low';
    }

    /**
     * Queue priority (1 = highest, 4 = lowest).
     * Used to sort the pending queue: critical first, then high, medium, low.
     */
    public function getPriority(int $score, int $critical = 40, int $medium = 70): int {
        if ($score <= $critical)        return 1; // 🔴 Critical
        if ($score <= $critical + 15)   return 2; // 🟠 High
        if ($score <= $medium)          return 3; // 🟡 Medium
        return 4;                                  // 🟢 Low
    }

    /**
     * Human-readable label for the frontend badge.
     */
    public function getLabel(int $score, int $critical = 40, int $medium = 70): string {
        if ($score >= 95)               return 'Safe';
        if ($score >= 80)               return 'Good';
        if ($score > $medium)           return 'Review Recommended';
        if ($score > $critical)         return 'Suspicious';
        return 'High Risk';
    }

    /**
     * Tailwind/CSS color class for the badge.
     */
    public function getColor(int $score, int $critical = 40, int $medium = 70): string {
        if ($score >= 80)        return 'success';    // green
        if ($score > $medium)    return 'warning';    // yellow
        if ($score > $critical)  return 'orange';     // orange
        return 'danger';                              // red
    }
}
