import { useEffect, useRef, useCallback } from 'react';
import { useLocation } from 'react-router-dom';
import api from '../api/axios';

export default function SessionTracker() {
  const location = useLocation();
  const idleTimeout = useRef(null);
  const isIdle = useRef(false);
  const isEditing = useRef(false);
  const pingTimeout = useRef(null);
  const lastPingTime = useRef(0);

  // Extract a "record ID" from the URL if it looks like a detail page, e.g. /tenants/302
  const getRecordId = (path) => {
    const parts = path.split('/');
    const lastPart = parts[parts.length - 1];
    return !isNaN(lastPart) ? lastPart : null;
  };

  const sendPing = useCallback((eventType = 'heartbeat') => {
    // Only track if user is authenticated
    if (!localStorage.getItem('token')) return;

    // Debounce pings slightly so we don't spam the server on rapid typing
    if (Date.now() - lastPingTime.current < 2000 && eventType === 'heartbeat') return;
    
    lastPingTime.current = Date.now();

    const unsaved = document.querySelector('form.dirty, .is-dirty') !== null;
    const currentAction = document.title || 'Viewing Page';
    const recordId = getRecordId(location.pathname);
    
    // Attempt to scrape currently dirty inputs
    let changedFields = [];
    if (unsaved) {
        document.querySelectorAll('input, select, textarea').forEach(el => {
            if (el.value !== el.defaultValue) {
                changedFields.push({ [el.name || el.id]: el.value });
            }
        });
    }

    const payload = {
      event_type: eventType,
      current_page: location.pathname,
      current_action: currentAction,
      current_record_id: recordId,
      edit_mode: isEditing.current ? 'editing' : 'viewing',
      unsaved_changes: unsaved,
      changed_fields: changedFields.length > 0 ? changedFields : null,
      status: isIdle.current ? 'idle' : (!document.hasFocus() ? 'away' : (isEditing.current ? 'editing' : 'online'))
    };

    api.post('/operations/ping', payload).catch(err => console.error("Session tracking ping failed", err));
  }, [location.pathname]);

  const scheduleNextPing = useCallback(() => {
    if (pingTimeout.current) clearTimeout(pingTimeout.current);
    // Poll every 30 seconds
    pingTimeout.current = setTimeout(() => {
      sendPing('heartbeat');
      scheduleNextPing();
    }, 30000);
  }, [sendPing]);

  const resetIdle = useCallback(() => {
    const wasIdle = isIdle.current;
    isIdle.current = false;
    
    if (wasIdle) {
      sendPing('active'); // Immediately notify server they are back
    }
    
    if (idleTimeout.current) clearTimeout(idleTimeout.current);
    
    // Mark idle after 5 minutes of no mouse/keyboard activity
    idleTimeout.current = setTimeout(() => {
      isIdle.current = true;
      sendPing('idle'); // Immediately notify server they are idle
    }, 5 * 60 * 1000);
  }, [sendPing]);

  // Handle Input Changes globally to detect editing
  const handleInput = useCallback(() => {
    if (!isEditing.current) {
        isEditing.current = true;
        sendPing('edit_started');
    }
    resetIdle();
  }, [sendPing, resetIdle]);

  useEffect(() => {
    const activityEvents = ['mousemove', 'mousedown', 'keydown', 'touchstart', 'scroll'];
    activityEvents.forEach(e => window.addEventListener(e, resetIdle));
    
    // Listen for focus/blur for "away" status
    const handleFocus = () => { resetIdle(); sendPing('focus'); };
    const handleBlur = () => { sendPing('blur'); };
    window.addEventListener('focus', handleFocus);
    window.addEventListener('blur', handleBlur);

    // Delegate input tracking for the editing state
    document.body.addEventListener('input', handleInput);

    resetIdle();
    scheduleNextPing();

    return () => {
      activityEvents.forEach(e => window.removeEventListener(e, resetIdle));
      window.removeEventListener('focus', handleFocus);
      window.removeEventListener('blur', handleBlur);
      document.body.removeEventListener('input', handleInput);
      if (idleTimeout.current) clearTimeout(idleTimeout.current);
      if (pingTimeout.current) clearTimeout(pingTimeout.current);
    };
  }, [resetIdle, handleInput, scheduleNextPing, sendPing]);

  // Trigger immediate ping on navigation
  useEffect(() => {
    isEditing.current = false; // Reset editing state on navigation
    sendPing('navigation');
  }, [location.pathname, sendPing]);

  return null; // Silent component
}
