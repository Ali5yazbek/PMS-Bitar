<?php
namespace Core\Events;

/**
 * Base interface for all domain events.
 */
interface Event {
    /**
     * Get the name of the event.
     */
    public function getName(): string;
}
