<?php
/**
 * OCRService.php (Interface & Stub)
 * Placeholder for future AI/OCR image extraction.
 * ApprovalEngineController will inject an implementation of this interface.
 */

interface OCRServiceInterface {
    /**
     * Extracts meter reading numeric value from an image.
     */
    public function extractReading(string $imagePath): ?float;

    /**
     * Compares OCR result with agent-submitted reading to detect errors.
     */
    public function compareWithSubmitted(float $ocrValue, float $submittedValue): array;
}

class OCRServiceStub implements OCRServiceInterface {
    public function extractReading(string $imagePath): ?float {
        // TODO: Integrate Google Cloud Vision or AWS Textract
        return null;
    }

    public function compareWithSubmitted(float $ocrValue, float $submittedValue): array {
        $diff = abs($ocrValue - $submittedValue);
        return [
            'match' => $diff < 1.0,
            'ocr_value' => $ocrValue,
            'diff' => $diff
        ];
    }
}
