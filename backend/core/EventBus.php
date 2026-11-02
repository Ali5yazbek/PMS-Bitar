<?php
namespace Core;

/**
 * EventBus handles the registration and dispatching of domain events.
 * It decouples modules by allowing them to subscribe to events (e.g., PaymentReceivedEvent)
 * without the dispatching module needing to know about the listeners.
 */
class EventBus {
    private static $listeners = [];

    /**
     * Subscribe a listener callback to an event class.
     *
     * @param string $eventClass The fully qualified class name of the event.
     * @param callable $listener The callback to execute.
     */
    public static function subscribe($eventClass, callable $listener) {
        if (!isset(self::$listeners[$eventClass])) {
            self::$listeners[$eventClass] = [];
        }
        self::$listeners[$eventClass][] = $listener;
    }

    /**
     * Dispatch an event to all subscribed listeners.
     *
     * @param object $event The event instance.
     */
    public static function dispatch($event) {
        $eventClass = get_class($event);
        if (isset(self::$listeners[$eventClass])) {
            foreach (self::$listeners[$eventClass] as $listener) {
                // Execute listener. In a more advanced setup, this could be queued.
                call_user_func($listener, $event);
            }
        }
    }
}
