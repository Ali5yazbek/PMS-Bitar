<?php
/**
 * ConsumptionPredictionService.php (Interface & Stub)
 * Predicts expected consumption using historical data and seasonal adjustments.
 */

interface ConsumptionPredictionServiceInterface {
    /**
     * Predict consumption for an apartment for a given month.
     */
    public function predict(int $apartmentId, string $month): float;
}

class ConsumptionPredictionServiceStub implements ConsumptionPredictionServiceInterface {
    public function predict(int $apartmentId, string $month): float {
        // TODO: Implement ARIMA, Prophet, or simple seasonal naive forecasting
        return 0.0;
    }
}
