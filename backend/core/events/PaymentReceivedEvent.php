<?php
namespace Core\Events;

require_once __DIR__ . '/Event.php';

class PaymentReceivedEvent implements Event {
    public $paymentId;
    public $invoiceId;
    public $amount;
    public $userId;
    public $contractId;

    public function __construct($paymentId, $invoiceId, $amount, $userId, $contractId = null) {
        $this->paymentId = $paymentId;
        $this->invoiceId = $invoiceId;
        $this->amount = $amount;
        $this->userId = $userId;
        $this->contractId = $contractId;
    }

    public function getName(): string {
        return 'PaymentReceived';
    }
}
