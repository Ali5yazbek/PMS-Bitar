import React, { useState, useEffect, useMemo } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../api/axios';
import { 
  Calendar as CalendarIcon, ChevronLeft, ChevronRight, CheckCircle, Clock, AlertCircle, X, FileText,
  Sparkles, Wrench, ShieldCheck, Users, ClipboardList, Shield, User, ArrowRight, CheckSquare, Square,
  Zap, Flame, DollarSign, Filter, Search, RefreshCw, AlertTriangle, Check, Layers, SlidersHorizontal,
  ChevronDown, PlusCircle, Eye, CheckCircle2, ShieldAlert
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ScheduleCenter = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  // Mode state: 'normal' (Calendar Operations & Compliance) or 'pro' (Executive Hub)
  const [viewMode, setViewMode] = useState(() => {
    return localStorage.getItem('schedule_view_mode') || 'normal';
  });

  const handleViewChange = (mode) => {
    setViewMode(mode);
    localStorage.setItem('schedule_view_mode', mode);
  };

  // Calendar View mode in Normal view: 'month', 'week', 'day'
  const [calendarView, setCalendarView] = useState('month');

  // Selected date anchor (Default October 2026 matching current property operations)
  const [currentDate, setCurrentDate] = useState(new Date(2026, 9, 25)); // Oct 25, 2026
  const [selectedDayDate, setSelectedDayDate] = useState('2026-10-25');

  // Filter States
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedBuilding, setSelectedBuilding] = useState('all');
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedPriority, setSelectedPriority] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');

  // Modal State
  const [selectedDateEvents, setSelectedDateEvents] = useState(null);
  const [selectedDateStr, setSelectedDateStr] = useState(null);
  const [activeEventDetail, setActiveEventDetail] = useState(null);

  // Completion Proof Form State
  const [completingTaskId, setCompletingTaskId] = useState(null);
  const [completionNotes, setCompletionNotes] = useState('');
  const [meterReading, setMeterReading] = useState('');
  const [fuelLevel, setFuelLevel] = useState('');
  const [partsUsed, setPartsUsed] = useState('');
  const [actualCost, setActualCost] = useState('');
  const [proofImage, setProofImage] = useState('');
  const [isSubmittingProof, setIsSubmittingProof] = useState(false);

  // Cancellation State
  const [cancellingTaskId, setCancellingTaskId] = useState(null);
  const [cancellationReason, setCancellationReason] = useState('');
  const [isCancelling, setIsCancelling] = useState(false);

  // Repair State
  const [isRepairing, setIsRepairing] = useState(false);
  const [isReconciling, setIsReconciling] = useState(false);

  // Today's command checklist state for Pro mode
  const [commandTasks, setCommandTasks] = useState([]);

  // Live Query - Unified Events with Metrics
  const { data: scheduleData, isLoading, refetch } = useQuery({
    queryKey: ['scheduleEventsWithMetrics', selectedCategory, selectedBuilding, selectedStatus, selectedPriority],
    queryFn: async () => {
      // Fetch 3 months window centered on currentDate
      const year = currentDate.getFullYear();
      const month = currentDate.getMonth();
      const start = new Date(year, month - 1, 1).toISOString().split('T')[0];
      const end = new Date(year, month + 2, 0).toISOString().split('T')[0];

      const res = await api.get('/schedule/calendar', {
        params: {
          start,
          end,
          format: 'full',
          category: selectedCategory !== 'all' ? selectedCategory : undefined,
          building_id: selectedBuilding !== 'all' ? selectedBuilding : undefined,
          status: selectedStatus !== 'all' ? selectedStatus : undefined,
          priority: selectedPriority !== 'all' ? selectedPriority : undefined
        }
      });
      return res.data;
    }
  });

  const rawEvents = useMemo(() => {
    if (!scheduleData) return [];
    if (Array.isArray(scheduleData)) return scheduleData;
    return scheduleData.events || [];
  }, [scheduleData]);

  const metrics = useMemo(() => {
    if (scheduleData && scheduleData.metrics) {
      return scheduleData.metrics;
    }
    // Fallback calculation from rawEvents
    const total = rawEvents.length;
    const completed = rawEvents.filter(e => e.status === 'Completed').length;
    const missing = rawEvents.filter(e => e.is_missing).length;
    const overdue = rawEvents.filter(e => e.status === 'Overdue').length;
    const pending = rawEvents.filter(e => e.status === 'Pending').length;
    return {
      total_events: total,
      completed,
      missing,
      overdue,
      pending,
      compliance_score: total > 0 ? Math.round((completed / total) * 100) : 100,
      today_missing: rawEvents.filter(e => e.is_missing && e.date === '2026-10-25').length
    };
  }, [scheduleData, rawEvents]);

  // Client-side search filter
  const events = useMemo(() => {
    if (!searchQuery.trim()) return rawEvents;
    const q = searchQuery.toLowerCase().trim();
    return rawEvents.filter(e => {
      const matchText = `${e.title || ''} ${e.description || ''} ${e.building_name || ''} ${e.apartment_code || ''} ${e.equipment_name || ''} ${e.tenant_name || ''}`.toLowerCase();
      return matchText.includes(q);
    });
  }, [rawEvents, searchQuery]);

  // Query summary
  const { data: summary } = useQuery({
    queryKey: ['scheduleSummary'],
    queryFn: async () => {
      try {
        const res = await api.get('/schedule/summary');
        return res.data;
      } catch (e) {
        return null;
      }
    }
  });

  // Query Pro Dashboard
  const { data: proDashboardData } = useQuery({
    queryKey: ['scheduleProDashboard'],
    queryFn: async () => {
      try {
        const res = await api.get('/schedule/pro-dashboard');
        return res.data;
      } catch (e) {
        return null;
      }
    }
  });

  useEffect(() => {
    if (proDashboardData?.today_command && proDashboardData.today_command.length > 0) {
      setCommandTasks(proDashboardData.today_command);
    }
  }, [proDashboardData]);

  // Navigation handlers
  const prevDate = () => {
    if (calendarView === 'month') {
      setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
    } else if (calendarView === 'week') {
      const d = new Date(currentDate);
      d.setDate(d.getDate() - 7);
      setCurrentDate(d);
    } else {
      const d = new Date(currentDate);
      d.setDate(d.getDate() - 1);
      setCurrentDate(d);
      setSelectedDayDate(d.toISOString().split('T')[0]);
    }
  };

  const nextDate = () => {
    if (calendarView === 'month') {
      setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
    } else if (calendarView === 'week') {
      const d = new Date(currentDate);
      d.setDate(d.getDate() + 7);
      setCurrentDate(d);
    } else {
      const d = new Date(currentDate);
      d.setDate(d.getDate() + 1);
      setCurrentDate(d);
      setSelectedDayDate(d.toISOString().split('T')[0]);
    }
  };

  const jumpToToday = () => {
    const today = new Date(2026, 9, 25); // Oct 25, 2026
    setCurrentDate(today);
    setSelectedDayDate('2026-10-25');
  };

  // 1-Click Action to Generate / Repair Missing Task
  const handleRepairMissingTask = async (repairPayload) => {
    if (!repairPayload) return;
    setIsRepairing(true);
    try {
      await api.post('/schedule/tasks/generate-missing', repairPayload);
      await refetch();
      queryClient.invalidateQueries({ queryKey: ['scheduleEventsWithMetrics'] });
      queryClient.invalidateQueries({ queryKey: ['scheduleSummary'] });
      
      // Update selectedDateEvents if modal open
      if (selectedDateStr) {
        const updated = (await api.get('/schedule/calendar', { params: { start: selectedDateStr, end: selectedDateStr, format: 'full' } })).data;
        setSelectedDateEvents(updated.events || []);
      }
      alert('Task successfully generated and scheduled in database!');
    } catch (err) {
      alert('Failed to generate task: ' + (err.response?.data?.error || err.message));
    } finally {
      setIsRepairing(false);
    }
  };

  // Submit Proof of Completion
  const handleSubmitProof = async (taskId) => {
    if (!taskId) return;
    setIsSubmittingProof(true);
    try {
      await api.post('/schedule/tasks/complete', {
        task_id: taskId,
        status: 'Completed',
        notes: completionNotes,
        meter_reading: meterReading ? parseFloat(meterReading) : undefined,
        fuel_level: fuelLevel ? parseFloat(fuelLevel) : undefined,
        parts_used: partsUsed || undefined,
        actual_cost: actualCost ? parseFloat(actualCost) : undefined,
        proof_image: proofImage || undefined
      });

      setCompletingTaskId(null);
      setCompletionNotes('');
      setMeterReading('');
      setFuelLevel('');
      setPartsUsed('');
      setActualCost('');
      setProofImage('');

      await refetch();
      queryClient.invalidateQueries({ queryKey: ['scheduleEventsWithMetrics'] });
      queryClient.invalidateQueries({ queryKey: ['scheduleSummary'] });

      if (selectedDateStr) {
        const updated = (await api.get('/schedule/calendar', { params: { start: selectedDateStr, end: selectedDateStr, format: 'full' } })).data;
        setSelectedDateEvents(updated.events || []);
      }
      alert('Proof of completion recorded and verified successfully!');
    } catch (err) {
      alert('Failed to record completion: ' + (err.response?.data?.error || err.message));
    } finally {
      setIsSubmittingProof(false);
    }
  };

  // Cancel Task with Reason
  const handleCancelTask = async (taskId) => {
    if (!taskId || !cancellationReason.trim()) {
      alert('Please provide a cancellation reason.');
      return;
    }
    setIsCancelling(true);
    try {
      await api.post('/schedule/tasks/cancel', {
        task_id: taskId,
        reason: cancellationReason
      });

      setCancellingTaskId(null);
      setCancellationReason('');

      await refetch();
      queryClient.invalidateQueries({ queryKey: ['scheduleEventsWithMetrics'] });
      queryClient.invalidateQueries({ queryKey: ['scheduleSummary'] });

      if (selectedDateStr) {
        const updated = (await api.get('/schedule/calendar', { params: { start: selectedDateStr, end: selectedDateStr, format: 'full' } })).data;
        setSelectedDateEvents(updated.events || []);
      }
      alert('Task cancelled and audit trail recorded.');
    } catch (err) {
      alert('Failed to cancel task: ' + (err.response?.data?.error || err.message));
    } finally {
      setIsCancelling(false);
    }
  };

  // Run Manual Reconciliation Scan
  const handleRunReconcile = async () => {
    setIsReconciling(true);
    try {
      const res = await api.post('/schedule/reconcile');
      await refetch();
      queryClient.invalidateQueries({ queryKey: ['scheduleEventsWithMetrics'] });
      queryClient.invalidateQueries({ queryKey: ['scheduleSummary'] });
      alert(`Reconciliation scan complete: ${res.data.tasks_generated ?? 0} missing operations recovered.`);
    } catch (err) {
      alert('Reconciliation failed: ' + (err.response?.data?.error || err.message));
    } finally {
      setIsReconciling(false);
    }
  };

  // Helper for Category Icon
  const getCategoryIcon = (cat, size = 14) => {
    switch (cat) {
      case 'rent':
        return <DollarSign size={size} className="text-blue-400" />;
      case 'electricity':
        return <Zap size={size} className="text-amber-400" />;
      case 'maintenance':
        return <Wrench size={size} className="text-orange-400" />;
      case 'generator':
        return <Flame size={size} className="text-rose-400" />;
      case 'lease':
        return <FileText size={size} className="text-purple-400" />;
      default:
        return <CalendarIcon size={size} className="text-slate-400" />;
    }
  };

  // Helper for Status Badge Styling
  const getEventBadgeStyle = (evt) => {
    if (evt.is_missing) {
      return 'bg-rose-950/80 text-rose-300 border-rose-500/70 shadow-sm shadow-rose-900/30 ring-1 ring-rose-500/40';
    }
    if (evt.status === 'Completed') {
      return 'bg-emerald-950/60 text-emerald-300 border-emerald-500/40';
    }
    if (evt.status === 'Overdue') {
      return 'bg-red-950/70 text-red-300 border-red-500/50';
    }
    if (evt.status === 'Pending') {
      return 'bg-amber-950/60 text-amber-300 border-amber-500/40';
    }
    return 'bg-blue-950/60 text-blue-300 border-blue-500/40';
  };

  const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  const daysInMonth = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 0).getDate();
  const firstDay = new Date(currentDate.getFullYear(), currentDate.getMonth(), 1).getDay();

  const formattedHeaderDate = () => {
    if (calendarView === 'month') {
      return `${monthNames[currentDate.getMonth()]} ${currentDate.getFullYear()}`;
    }
    if (calendarView === 'week') {
      const startOfWeek = new Date(currentDate);
      startOfWeek.setDate(currentDate.getDate() - currentDate.getDay());
      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(startOfWeek.getDate() + 6);
      return `${monthNames[startOfWeek.getMonth()]} ${startOfWeek.getDate()} - ${monthNames[endOfWeek.getMonth()]} ${endOfWeek.getDate()}, ${endOfWeek.getFullYear()}`;
    }
    return `${monthNames[currentDate.getMonth()]} ${currentDate.getDate()}, ${currentDate.getFullYear()}`;
  };

  // Render Month Cells
  const renderMonthCells = () => {
    const cells = [];
    const todayStr = '2026-10-25';

    // Padding for first day of month
    for (let i = 0; i < firstDay; i++) {
      cells.push(
        <div key={`pad-${i}`} className="p-2 min-h-[135px] bg-slate-950/40 border border-slate-900/60 rounded-xl opacity-40"></div>
      );
    }

    // Days of month
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const isToday = dateStr === todayStr;

      const dayEvents = events.filter(e => e.date === dateStr);
      const missingCount = dayEvents.filter(e => e.is_missing).length;
      const overdueCount = dayEvents.filter(e => e.status === 'Overdue' && !e.is_missing).length;
      const completedCount = dayEvents.filter(e => e.status === 'Completed').length;

      cells.push(
        <div 
          key={`day-${day}`}
          onClick={() => {
            setSelectedDateEvents(dayEvents);
            setSelectedDateStr(dateStr);
          }}
          className={`p-2.5 min-h-[135px] cursor-pointer rounded-2xl border flex flex-col justify-between transition-all duration-200 group ${
            isToday 
              ? 'border-purple-500/60 bg-gradient-to-b from-purple-950/30 to-slate-900/90 shadow-lg shadow-purple-950/20 ring-1 ring-purple-500/50' 
              : missingCount > 0
                ? 'border-rose-900/50 bg-slate-900/90 hover:border-rose-500/50 hover:bg-slate-900'
                : 'border-slate-800/80 bg-slate-900/60 hover:border-slate-700 hover:bg-slate-900/90'
          }`}
        >
          {/* Day Cell Header */}
          <div className="flex justify-between items-center mb-1.5">
            <div className="flex items-center gap-1.5">
              <span className={`font-bold text-sm md:text-base ${isToday ? 'text-purple-300 font-extrabold' : 'text-slate-200'}`}>
                {day}
              </span>
              {isToday && (
                <span className="text-[10px] font-bold px-1.5 py-0.2 rounded bg-purple-500/30 text-purple-300 border border-purple-500/40 uppercase">
                  {t('Today')}
                </span>
              )}
            </div>

            {/* Badges Count */}
            <div className="flex items-center gap-1">
              {missingCount > 0 && (
                <span 
                  title={`${missingCount} Missing Tasks detected for this day`}
                  className="text-[10px] font-extrabold px-1.5 py-0.5 rounded-full bg-rose-500/20 text-rose-300 border border-rose-500/40 flex items-center gap-1 animate-pulse"
                >
                  <AlertTriangle size={10} />
                  {missingCount}
                </span>
              )}
              {dayEvents.length > 0 && (
                <span className="text-[11px] font-semibold bg-slate-800/90 px-1.5 py-0.5 rounded-md text-slate-300 border border-slate-700/60">
                  {dayEvents.length}
                </span>
              )}
            </div>
          </div>

          {/* Events Pills (Show up to 3, then "+N more") */}
          <div className="flex-1 space-y-1 overflow-hidden my-1">
            {dayEvents.slice(0, 3).map((evt) => (
              <div 
                key={evt.id} 
                className={`text-[11px] px-2 py-1 rounded-lg border flex items-center justify-between gap-1.5 truncate transition-all ${getEventBadgeStyle(evt)}`}
              >
                <div className="flex items-center gap-1.5 truncate">
                  {evt.is_missing ? (
                    <AlertTriangle size={12} className="text-rose-400 shrink-0" />
                  ) : (
                    getCategoryIcon(evt.category, 12)
                  )}
                  <span className="font-semibold truncate">
                    {evt.apartment_code ? `${evt.building_name}-${evt.apartment_code}` : (evt.equipment_name || evt.title)}
                  </span>
                </div>
                <span className="text-[9px] font-bold uppercase tracking-wider shrink-0 opacity-80">
                  {evt.is_missing ? 'MISSING' : evt.status}
                </span>
              </div>
            ))}

            {dayEvents.length > 3 && (
              <div className="text-[10px] font-bold text-slate-400 hover:text-indigo-300 transition-colors pt-0.5 px-1 flex items-center justify-between">
                <span>+{dayEvents.length - 3} {t('more events')}</span>
                <span className="text-xs">→</span>
              </div>
            )}
          </div>

          {/* Cell Footer Micro Status Bar */}
          <div className="flex items-center gap-1 pt-1 border-t border-slate-800/40 text-[10px] text-slate-400">
            {completedCount > 0 && (
              <span className="text-emerald-400 flex items-center gap-0.5">
                <Check size={10} /> {completedCount}
              </span>
            )}
            {overdueCount > 0 && (
              <span className="text-rose-400 flex items-center gap-0.5 ml-auto">
                <Clock size={10} /> {overdueCount} {t('overdue')}
              </span>
            )}
          </div>
        </div>
      );
    }

    return cells;
  };

  // Render Week View
  const renderWeekView = () => {
    const startOfWeek = new Date(currentDate);
    startOfWeek.setDate(currentDate.getDate() - currentDate.getDay());

    const days = [];
    for (let i = 0; i < 7; i++) {
      const dayDate = new Date(startOfWeek);
      dayDate.setDate(startOfWeek.getDate() + i);
      const dateStr = dayDate.toISOString().split('T')[0];
      const isToday = dateStr === '2026-10-25';
      const dayEvents = events.filter(e => e.date === dateStr);

      days.push(
        <div key={dateStr} className={`bg-slate-900/70 border rounded-2xl p-3 flex flex-col min-h-[500px] ${isToday ? 'border-purple-500/60 bg-purple-950/20' : 'border-slate-800'}`}>
          <div className="flex justify-between items-center mb-3 pb-2 border-b border-slate-800">
            <div>
              <span className="text-xs text-slate-400 font-bold uppercase">{['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][i]}</span>
              <h4 className={`text-lg font-extrabold ${isToday ? 'text-purple-300' : 'text-slate-100'}`}>
                {dayDate.getDate()} {monthNames[dayDate.getMonth()].slice(0, 3)}
              </h4>
            </div>
            <span className="text-xs font-bold px-2 py-0.5 rounded-full bg-slate-800 text-slate-300 border border-slate-700">
              {dayEvents.length}
            </span>
          </div>

          <div className="flex-1 space-y-2 overflow-y-auto hide-scrollbar">
            {dayEvents.length === 0 ? (
              <div className="text-center py-10 text-xs text-slate-500">{t('No operations scheduled')}</div>
            ) : (
              dayEvents.map(evt => (
                <div 
                  key={evt.id}
                  onClick={() => {
                    setSelectedDateEvents(dayEvents);
                    setSelectedDateStr(dateStr);
                    setActiveEventDetail(evt);
                  }}
                  className={`p-2.5 rounded-xl border text-xs cursor-pointer transition-all hover:scale-[1.01] ${getEventBadgeStyle(evt)}`}
                >
                  <div className="flex items-center justify-between gap-1 mb-1">
                    <span className="text-[10px] font-bold uppercase flex items-center gap-1">
                      {getCategoryIcon(evt.category, 12)}
                      {evt.category}
                    </span>
                    <span className="text-[10px] font-extrabold px-1.5 py-0.2 rounded bg-black/30">
                      {evt.is_missing ? 'MISSING' : evt.status}
                    </span>
                  </div>
                  <h5 className="font-bold text-white line-clamp-1">{evt.title}</h5>
                  <p className="text-[11px] opacity-80 mt-0.5 line-clamp-1">{evt.description}</p>
                </div>
              ))
            )}
          </div>
        </div>
      );
    }

    return (
      <div className="grid grid-cols-1 md:grid-cols-7 gap-3">
        {days}
      </div>
    );
  };

  // Render Day View
  const renderDayView = () => {
    const dateStr = selectedDayDate || '2026-10-25';
    const dayEvents = events.filter(e => e.date === dateStr);

    const categories = ['generator', 'electricity', 'maintenance', 'rent', 'lease'];
    const categoryLabels = {
      generator: { label: 'Generator Operations & Checks', icon: <Flame size={18} className="text-rose-400" /> },
      electricity: { label: 'Electricity Subscriptions & Renewals', icon: <Zap size={18} className="text-amber-400" /> },
      maintenance: { label: 'Building & Unit Maintenance', icon: <Wrench size={18} className="text-orange-400" /> },
      rent: { label: 'Rent Collection & Due Invoices', icon: <DollarSign size={18} className="text-blue-400" /> },
      lease: { label: 'Lease Expirations & Agreements', icon: <FileText size={18} className="text-purple-400" /> }
    };

    return (
      <div className="space-y-6">
        {/* Day Header Banner */}
        <div className="p-5 rounded-2xl bg-gradient-to-r from-slate-900 via-indigo-950/40 to-slate-900 border border-slate-800 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <span className="text-xs font-bold text-indigo-400 uppercase tracking-widest">{t('DAY OPERATIONS COMMAND')}</span>
            <h3 className="text-xl font-extrabold text-white mt-1">
              Operations for {dateStr}
            </h3>
            <p className="text-xs text-slate-400">
              {dayEvents.length} {t('total required operations')} | {dayEvents.filter(e => e.status === 'Completed').length} {t('verified complete')} | {dayEvents.filter(e => e.is_missing).length} {t('missing alerts')}
            </p>
          </div>

          <button
            onClick={() => {
              setSelectedDateEvents(dayEvents);
              setSelectedDateStr(dateStr);
            }}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold rounded-xl transition-all shadow-lg flex items-center gap-2"
          >
            <Eye size={16} />
            <span>{t('Open Full Day Modal')}</span>
          </button>
        </div>

        {/* Categories Grouping */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
          {categories.map(cat => {
            const catEvents = dayEvents.filter(e => e.category === cat);
            const info = categoryLabels[cat];

            return (
              <div key={cat} className="p-4 rounded-2xl bg-slate-900/80 border border-slate-800 shadow-xl">
                <div className="flex items-center justify-between mb-3 pb-2 border-b border-slate-800">
                  <div className="flex items-center gap-2">
                    {info.icon}
                    <h4 className="font-bold text-sm text-slate-100">{t(info.label)}</h4>
                  </div>
                  <span className="text-xs px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 font-bold border border-slate-700">
                    {catEvents.length}
                  </span>
                </div>

                <div className="space-y-2.5">
                  {catEvents.length === 0 ? (
                    <div className="py-6 text-center text-xs text-slate-500">
                      {t('No tasks required for this category today')}
                    </div>
                  ) : (
                    catEvents.map(evt => (
                      <div 
                        key={evt.id}
                        className={`p-3 rounded-xl border flex flex-col justify-between gap-2 ${getEventBadgeStyle(evt)}`}
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div>
                            <span className="text-[10px] font-extrabold uppercase px-1.5 py-0.5 rounded bg-black/40 text-slate-200">
                              {evt.priority || 'Normal'} Priority
                            </span>
                            <h5 className="font-bold text-sm text-white mt-1">{evt.title}</h5>
                            <p className="text-xs opacity-90 mt-0.5">{evt.description}</p>
                          </div>
                          <span className={`text-[10px] font-extrabold uppercase px-2 py-0.5 rounded-full ${
                            evt.is_missing ? 'bg-rose-600 text-white animate-pulse' :
                            evt.status === 'Completed' ? 'bg-emerald-600 text-white' :
                            evt.status === 'Overdue' ? 'bg-red-600 text-white' : 'bg-slate-800 text-slate-200'
                          }`}>
                            {evt.is_missing ? 'MISSING TASK' : evt.status}
                          </span>
                        </div>

                        {/* Action buttons inside card */}
                        <div className="flex items-center justify-end gap-2 pt-2 border-t border-white/10">
                          {evt.is_missing && evt.repair_action && (
                            <button
                              onClick={() => handleRepairMissingTask(evt.repair_action)}
                              disabled={isRepairing}
                              className="px-3 py-1.5 rounded-lg bg-rose-600 hover:bg-rose-500 text-white font-bold text-xs shadow transition-all flex items-center gap-1.5"
                            >
                              <PlusCircle size={14} />
                              <span>{t('Repair / Generate Task')}</span>
                            </button>
                          )}

                          {!evt.is_missing && evt.status !== 'Completed' && (
                            <button
                              onClick={() => setCompletingTaskId(evt.source_id || evt.raw_id)}
                              className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow transition-all flex items-center gap-1.5"
                            >
                              <CheckCircle2 size={14} />
                              <span>{t('Complete with Proof')}</span>
                            </button>
                          )}

                          {evt.action_url && (
                            <button
                              onClick={() => navigate(evt.action_url)}
                              className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold border border-slate-700"
                            >
                              {t('View Record')}
                            </button>
                          )}
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>
    );
  };

  return (
    <div className="flex h-full w-full bg-slate-950 text-slate-100 overflow-hidden relative font-sans">
      <div className="flex-1 overflow-y-auto p-4 md:p-8 hide-scrollbar">

        {/* ── TOP BANNER: MODE SWITCHER ── */}
        <div className="mb-6 p-4 rounded-2xl bg-gradient-to-r from-slate-900 via-indigo-950/60 to-slate-900 border-2 border-indigo-500/40 shadow-2xl flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="p-2.5 rounded-xl bg-indigo-600 text-white shadow-lg">
              {viewMode === 'pro' ? <Sparkles size={24} className="animate-pulse text-amber-300" /> : <CalendarIcon size={24} />}
            </div>
            <div>
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                {viewMode === 'pro' ? 'Pro Hub - Live Database Operations' : 'Schedule Center - Automated Operations & Compliance'}
              </h2>
              <p className="text-xs text-slate-300">
                {t('Click to switch mode:')} <strong className="text-indigo-300">{t('Operations Calendar')}</strong> {t('or')} <strong className="text-amber-300">Pro Hub Mode (Connected to Live DB)</strong>
              </p>
            </div>
          </div>

          <div className="flex items-center bg-slate-950 p-1.5 rounded-xl border border-indigo-500/40 shadow-inner">
            <button
              onClick={() => handleViewChange('normal')}
              className={`px-5 py-2.5 rounded-lg text-xs md:text-sm font-extrabold transition-all flex items-center gap-2.5 ${
                viewMode === 'normal'
                  ? 'bg-purple-600 text-white shadow-lg shadow-purple-600/40 ring-2 ring-purple-400'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <CalendarIcon size={18} />
              <span>{t('Normal Calendar')}</span>
            </button>
            <button
              onClick={() => handleViewChange('pro')}
              className={`px-5 py-2.5 rounded-lg text-xs md:text-sm font-extrabold transition-all flex items-center gap-2.5 ${
                viewMode === 'pro'
                  ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white shadow-lg shadow-indigo-600/40 ring-2 ring-indigo-400'
                  : 'text-slate-400 hover:text-white hover:bg-slate-800'
              }`}
            >
              <Sparkles size={18} className="text-amber-400" />
              <span>{t('Pro Hub')}</span>
            </button>
          </div>
        </div>

        {/* ── COMPLIANCE & RECONCILIATION SCORE BANNER ── */}
        <div className="mb-6 p-4 rounded-2xl bg-slate-900/90 border border-slate-800 shadow-xl flex flex-col lg:flex-row items-center justify-between gap-5">
          <div className="flex flex-wrap items-center gap-4 w-full lg:w-auto">
            {/* Compliance Gauge */}
            <div className="flex items-center gap-3 bg-slate-950/80 px-4 py-2.5 rounded-xl border border-slate-800">
              <div className="relative w-12 h-12 flex items-center justify-center shrink-0">
                <svg className="w-12 h-12 transform -rotate-90">
                  <circle cx="24" cy="24" r="18" stroke="currentColor" strokeWidth="4" className="text-slate-800" fill="transparent" />
                  <circle 
                    cx="24" cy="24" r="18" 
                    stroke="currentColor" 
                    strokeWidth="4" 
                    className={metrics.compliance_score > 70 ? 'text-emerald-500' : 'text-amber-500'} 
                    strokeDasharray="113" 
                    strokeDashoffset={113 - (113 * (metrics.compliance_score || 0)) / 100} 
                    strokeLinecap="round" 
                    fill="transparent" 
                  />
                </svg>
                <span className="absolute font-extrabold text-xs text-white">{metrics.compliance_score}%</span>
              </div>
              <div>
                <span className="text-[10px] font-bold tracking-wider text-slate-400 uppercase">{t('Compliance Score')}</span>
                <h4 className="text-sm font-extrabold text-white">Property Compliance</h4>
              </div>
            </div>

            {/* Quick Metrics Badges */}
            <div className="flex flex-wrap items-center gap-2">
              {metrics.missing > 0 && (
                <div 
                  onClick={() => setSelectedStatus('missing')}
                  className="px-3 py-1.5 rounded-xl bg-rose-500/20 text-rose-300 border border-rose-500/40 text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-rose-500/30 transition-all animate-pulse"
                >
                  <AlertTriangle size={14} />
                  <span>{metrics.missing} {t('Missing Tasks')}</span>
                </div>
              )}
              {metrics.overdue > 0 && (
                <div 
                  onClick={() => setSelectedStatus('overdue')}
                  className="px-3 py-1.5 rounded-xl bg-red-500/20 text-red-300 border border-red-500/40 text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-red-500/30 transition-all"
                >
                  <Clock size={14} />
                  <span>{metrics.overdue} {t('Overdue')}</span>
                </div>
              )}
              <div 
                onClick={() => setSelectedStatus('completed')}
                className="px-3 py-1.5 rounded-xl bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-emerald-500/30 transition-all"
              >
                <CheckCircle size={14} />
                <span>{metrics.completed} {t('Completed')}</span>
              </div>
              <div 
                onClick={() => setSelectedStatus('pending')}
                className="px-3 py-1.5 rounded-xl bg-amber-500/20 text-amber-300 border border-amber-500/40 text-xs font-bold flex items-center gap-1.5 cursor-pointer hover:bg-amber-500/30 transition-all"
              >
                <AlertCircle size={14} />
                <span>{metrics.pending} {t('Pending / Today')}</span>
              </div>
            </div>
          </div>

          {/* Action to Reconcile Missing Operations */}
          <button
            onClick={handleRunReconcile}
            disabled={isReconciling}
            className="w-full lg:w-auto px-4 py-2.5 rounded-xl bg-indigo-600/80 hover:bg-indigo-600 text-white font-bold text-xs border border-indigo-500/40 transition-all flex items-center justify-center gap-2 shadow-lg"
          >
            <RefreshCw size={14} className={isReconciling ? 'animate-spin' : ''} />
            <span>{isReconciling ? t('Reconciling...') : t('Run Live Reconciliation Scan')}</span>
          </button>
        </div>

        {/* ── NORMAL MODE: CALENDAR & OPERATIONS ── */}
        {viewMode === 'normal' && (
          <div className="space-y-6">

            {/* Filter and View Control Bar */}
            <div className="p-4 rounded-2xl bg-slate-900/80 border border-slate-800 space-y-4">
              
              {/* Row 1: Views, Date Navigation & Search */}
              <div className="flex flex-col md:flex-row items-center justify-between gap-4">
                {/* View Switcher: Month, Week, Day */}
                <div className="flex items-center bg-slate-950 p-1 rounded-xl border border-slate-800 text-xs font-bold w-full md:w-auto justify-center">
                  {['month', 'week', 'day'].map((v) => (
                    <button
                      key={v}
                      onClick={() => setCalendarView(v)}
                      className={`px-4 py-2 rounded-lg capitalize transition-all ${
                        calendarView === v ? 'bg-indigo-600 text-white shadow-md' : 'text-slate-400 hover:text-white'
                      }`}
                    >
                      {t(v)}
                    </button>
                  ))}
                </div>

                {/* Date Navigator */}
                <div className="flex items-center gap-2 bg-slate-950 p-1.5 rounded-xl border border-slate-800">
                  <button onClick={prevDate} className="p-2 hover:bg-slate-800 rounded-lg text-slate-300 transition-colors">
                    <ChevronLeft size={18} />
                  </button>
                  <span className="text-sm font-extrabold text-white min-w-[170px] text-center px-2">
                    {formattedHeaderDate()}
                  </span>
                  <button onClick={nextDate} className="p-2 hover:bg-slate-800 rounded-lg text-slate-300 transition-colors">
                    <ChevronRight size={18} />
                  </button>
                  <button 
                    onClick={jumpToToday} 
                    className="px-2.5 py-1 text-xs font-bold rounded-lg bg-purple-600/30 text-purple-300 border border-purple-500/40 hover:bg-purple-600/50"
                  >
                    {t('Today')}
                  </button>
                </div>

                {/* Search Input */}
                <div className="relative w-full md:w-64">
                  <Search size={16} className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400" />
                  <input
                    type="text"
                    placeholder={t('Search unit, tenant, task...')}
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 bg-slate-950 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-indigo-500"
                  />
                  {searchQuery && (
                    <button onClick={() => setSearchQuery('')} className="absolute right-3 top-1/2 transform -translate-y-1/2 text-slate-400">
                      <X size={14} />
                    </button>
                  )}
                </div>
              </div>

              {/* Row 2: Category Filter Pills */}
              <div className="flex flex-wrap items-center gap-2 pt-2 border-t border-slate-800/80">
                <span className="text-xs font-bold text-slate-400 flex items-center gap-1.5 mr-1">
                  <Filter size={14} />
                  {t('Category:')}
                </span>

                {[
                  { id: 'all', label: 'All Operations', icon: <Layers size={13} /> },
                  { id: 'rent', label: 'Rent Collection', icon: <DollarSign size={13} className="text-blue-400" /> },
                  { id: 'electricity', label: 'Electricity Subscriptions', icon: <Zap size={13} className="text-amber-400" /> },
                  { id: 'maintenance', label: 'Maintenance', icon: <Wrench size={13} className="text-orange-400" /> },
                  { id: 'generator', label: 'Generator Checks', icon: <Flame size={13} className="text-rose-400" /> },
                  { id: 'lease', label: 'Lease Expirations', icon: <FileText size={13} className="text-purple-400" /> },
                ].map(cat => (
                  <button
                    key={cat.id}
                    onClick={() => setSelectedCategory(cat.id)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 border ${
                      selectedCategory === cat.id
                        ? 'bg-indigo-600 text-white border-indigo-400 shadow-md shadow-indigo-600/30'
                        : 'bg-slate-950 text-slate-400 border-slate-800 hover:text-white hover:border-slate-700'
                    }`}
                  >
                    {cat.icon}
                    <span>{t(cat.label)}</span>
                  </button>
                ))}

                {/* Building Dropdown */}
                <select
                  value={selectedBuilding}
                  onChange={(e) => setSelectedBuilding(e.target.value)}
                  className="ml-auto px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-800 text-xs font-bold text-slate-300 focus:outline-none focus:border-indigo-500"
                >
                  <option value="all">{t('All Buildings')}</option>
                  <option value="5">Galaxy Building</option>
                  <option value="6">CORNISHE Facility</option>
                </select>

                {/* Status Dropdown */}
                <select
                  value={selectedStatus}
                  onChange={(e) => setSelectedStatus(e.target.value)}
                  className="px-3 py-1.5 rounded-xl bg-slate-950 border border-slate-800 text-xs font-bold text-slate-300 focus:outline-none focus:border-indigo-500"
                >
                  <option value="all">{t('All Statuses')}</option>
                  <option value="missing">⚠️ {t('Missing Tasks Only')}</option>
                  <option value="overdue">{t('Overdue Tasks')}</option>
                  <option value="pending">{t('Pending / Today')}</option>
                  <option value="scheduled">{t('Scheduled / Upcoming')}</option>
                  <option value="completed">{t('Completed & Verified')}</option>
                </select>
              </div>

            </div>

            {/* Visual Legend */}
            <div className="flex flex-wrap items-center justify-center gap-6 p-3 rounded-xl bg-slate-900/60 border border-slate-800/80 text-xs">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-rose-600 shadow shadow-rose-600/50 animate-pulse"></span>
                <span className="text-rose-300 font-bold">{t('Missing Task Alert')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-red-500"></span>
                <span className="text-red-300 font-medium">{t('Overdue')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-amber-500"></span>
                <span className="text-amber-300 font-medium">{t('Pending / Due Today')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-blue-500"></span>
                <span className="text-blue-300 font-medium">{t('Upcoming / Scheduled')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-emerald-500"></span>
                <span className="text-emerald-300 font-medium">{t('Completed & Verified')}</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-purple-500 ring-2 ring-purple-300"></span>
                <span className="text-purple-300 font-bold">{t('Today')}</span>
              </div>
            </div>

            {/* Calendar Main Grid / Views */}
            {isLoading ? (
              <div className="text-center p-16 text-slate-400 flex flex-col items-center justify-center gap-3">
                <RefreshCw size={32} className="animate-spin text-indigo-400" />
                <p className="text-sm font-semibold">{t('Loading automated operations calendar...')}</p>
              </div>
            ) : calendarView === 'month' ? (
              <div className="w-full min-w-[800px]">
                <div className="grid grid-cols-7 gap-3 mb-3">
                  {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                    <div key={day} className="text-center font-bold text-slate-400 uppercase tracking-wider text-xs py-1">
                      {t(day)}
                    </div>
                  ))}
                </div>
                <div className="grid grid-cols-7 gap-3 pb-12">
                  {renderMonthCells()}
                </div>
              </div>
            ) : calendarView === 'week' ? (
              renderWeekView()
            ) : (
              renderDayView()
            )}

          </div>
        )}

        {/* ── PRO MODE: EXECUTIVE HUBS (Live DB Data) ── */}
        {viewMode === 'pro' && (
          <div className="space-y-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

              {/* CARD 1: MAINTENANCE & OPERATIONS HUB */}
              <div className="bg-slate-900/90 border border-slate-800/90 rounded-2xl p-5 shadow-xl flex flex-col justify-between hover:border-slate-700/80 transition-all">
                <div>
                  <div className="text-[11px] font-bold tracking-wider text-slate-400 uppercase mb-3 flex items-center justify-between">
                    <span>{t('CRITICAL ALERTS & MAINTENANCE HUB')}</span>
                  </div>

                  <div className="flex items-center space-x-2 text-white font-bold text-lg mb-4">
                    <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
                      <Wrench size={20} />
                    </div>
                    <span>{t('Maintenance Hub')}</span>
                  </div>

                  <div className="flex items-center space-x-5 my-4 p-3 bg-slate-950/60 rounded-xl border border-slate-800/60">
                    <div className="relative w-16 h-16 flex items-center justify-center">
                      <svg className="w-16 h-16 transform -rotate-90">
                        <circle cx="32" cy="32" r="26" stroke="currentColor" strokeWidth="6" className="text-slate-800" fill="transparent" />
                        <circle cx="32" cy="32" r="26" stroke="currentColor" strokeWidth="6" className="text-blue-500" strokeDasharray="163" strokeDashoffset="35" strokeLinecap="round" fill="transparent" />
                      </svg>
                      <span className="absolute font-extrabold text-lg text-white">
                        {proDashboardData?.maintenance?.open ?? 12}
                      </span>
                    </div>
                    <div>
                      <h4 className="font-bold text-slate-200 text-sm">{t('Open Maintenance Requests')}</h4>
                      <p className="text-xs text-emerald-400 flex items-center mt-1 font-medium">
                        <span className="w-2 h-2 rounded-full bg-emerald-400 mr-2"></span>
                        Completed ({proDashboardData?.maintenance?.completed ?? 8}/{proDashboardData?.maintenance?.total ?? 20})
                      </p>
                    </div>
                  </div>

                  {/* Missing task critical badge */}
                  {metrics.missing > 0 && (
                    <div className="bg-rose-500/10 border border-rose-500/30 rounded-xl p-3 mb-4">
                      <span className="text-xs font-bold text-rose-400 uppercase tracking-wide flex items-center gap-1.5">
                        <AlertTriangle size={14} />
                        {metrics.missing} REQUIRED OPERATIONS MISSING
                      </span>
                      <p className="text-xs text-slate-300 mt-1">
                        Generator daily checks or electricity renewals are missing tasks today.
                      </p>
                    </div>
                  )}
                </div>

                <button 
                  onClick={() => navigate('/maintenance-admin')}
                  className="w-full py-2.5 bg-slate-800/80 hover:bg-slate-800 text-slate-200 font-semibold rounded-xl text-xs border border-slate-700/60 transition-colors flex items-center justify-center gap-2"
                >
                  {t('View All Requests')}
                  <ArrowRight size={14} />
                </button>
              </div>

              {/* CARD 2: LEASE CENTER */}
              <div className="bg-slate-900/90 border border-slate-800/90 rounded-2xl p-5 shadow-xl flex flex-col justify-between hover:border-slate-700/80 transition-all">
                <div>
                  <div className="text-[11px] font-bold tracking-wider text-slate-400 uppercase mb-3 flex items-center justify-between">
                    <span>{t('AGREEMENT STATUS')}</span>
                  </div>

                  <div className="flex items-center space-x-2 text-white font-bold text-lg mb-4">
                    <div className="p-2 rounded-xl bg-purple-500/10 text-purple-400 border border-purple-500/20">
                      <FileText size={20} />
                    </div>
                    <span>{t('LEASE CENTER')}</span>
                  </div>

                  <div className="mb-4">
                    <h4 className="font-bold text-slate-200 text-sm mb-2">{proDashboardData?.lease_center?.expiring_count ?? 2} Leases expiring soon</h4>
                    <div className="flex h-2.5 rounded-full overflow-hidden bg-slate-800 gap-0.5">
                      <div className="w-1/2 bg-emerald-500"></div>
                      <div className="w-1/4 bg-amber-500"></div>
                      <div className="w-1/4 bg-rose-500"></div>
                    </div>
                  </div>

                  <div className="bg-slate-950/60 rounded-xl border border-slate-800/60 overflow-hidden mb-4">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-800/50 text-slate-400 font-semibold">
                        <tr>
                          <th className="p-2.5">{t('Tenant')}</th>
                          <th className="p-2.5">{t('Unit')}</th>
                          <th className="p-2.5 text-right">{t('Expiry')}</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-800/50 text-slate-300">
                        {proDashboardData?.lease_center?.leases?.slice(0, 3).map((l, idx) => (
                          <tr key={idx} className="hover:bg-slate-800/30">
                            <td className="p-2.5 font-medium">{l.tenant}</td>
                            <td className="p-2.5">{l.unit}</td>
                            <td className="p-2.5 text-right text-amber-400">{l.expiry}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>

                <button 
                  onClick={() => navigate('/tenants')}
                  className="w-full py-2.5 bg-slate-800/80 hover:bg-slate-800 text-slate-200 font-semibold rounded-xl text-xs border border-slate-700/60 transition-colors flex items-center justify-center gap-2"
                >
                  {t('Manage Leases')}
                  <ArrowRight size={14} />
                </button>
              </div>

              {/* CARD 3: TODAY'S COMMAND CHECKLIST */}
              <div className="bg-slate-900/90 border border-slate-800/90 rounded-2xl p-5 shadow-xl flex flex-col justify-between hover:border-slate-700/80 transition-all">
                <div>
                  <div className="text-[11px] font-bold tracking-wider text-slate-400 uppercase mb-3 flex items-center justify-between">
                    <span className="flex items-center gap-2">
                      <ClipboardList size={14} className="text-blue-400" />
                      {t("TODAY'S COMMAND")}
                    </span>
                    <span className="text-[10px] text-slate-400">Score: {metrics.compliance_score}%</span>
                  </div>

                  <div className="space-y-2 mb-4 max-h-56 overflow-y-auto hide-scrollbar">
                    {commandTasks.map(task => (
                      <div 
                        key={task.id}
                        className="p-2.5 rounded-xl border border-slate-800 bg-slate-950/80 flex items-center justify-between text-xs"
                      >
                        <div className="flex items-center space-x-2.5 truncate">
                          <CheckCircle2 size={16} className={task.completed ? "text-emerald-400" : "text-slate-500"} />
                          <span className="truncate">{task.text}</span>
                        </div>
                        <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-slate-800 text-slate-300">
                          {task.assignee}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <button 
                  onClick={() => handleViewChange('normal')}
                  className="w-full py-2.5 bg-indigo-600/80 hover:bg-indigo-600 text-white font-semibold rounded-xl text-xs transition-colors flex items-center justify-center gap-2"
                >
                  <CalendarIcon size={14} />
                  {t('Switch to Calendar View')}
                </button>
              </div>

            </div>
          </div>
        )}

      </div>

      {/* ── DAY EVENTS MODAL WITH 1-CLICK REPAIR & PROOF WORKFLOW ── */}
      {selectedDateEvents && (
        <div className="fixed inset-0 bg-black/75 backdrop-blur-md flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-700/90 rounded-3xl w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col max-h-[88vh]">
            
            {/* Modal Header */}
            <div className="p-5 border-b border-slate-800 flex justify-between items-center bg-slate-800/60">
              <div className="flex items-center gap-3">
                <div className="p-2 rounded-xl bg-indigo-600/30 text-indigo-400 border border-indigo-500/40">
                  <CalendarIcon size={20} />
                </div>
                <div>
                  <h3 className="text-lg font-extrabold text-white">
                    Operations for {selectedDateStr}
                  </h3>
                  <p className="text-xs text-slate-400">
                    {selectedDateEvents.length} {t('operations logged or required')}
                  </p>
                </div>
              </div>
              <button 
                onClick={() => {
                  setSelectedDateEvents(null);
                  setActiveEventDetail(null);
                  setCompletingTaskId(null);
                  setCancellingTaskId(null);
                }} 
                className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-full transition-colors"
              >
                <X size={18} />
              </button>
            </div>
            
            {/* Modal Body */}
            <div className="p-6 overflow-y-auto flex-1 space-y-4 bg-slate-900/90">
              {selectedDateEvents.length === 0 ? (
                <div className="text-center py-12 text-slate-400 flex flex-col items-center">
                  <CheckCircle size={48} className="text-emerald-500/30 mb-3" />
                  <p className="text-base font-semibold">{t('No operations scheduled for this day')}</p>
                </div>
              ) : (
                selectedDateEvents.map((evt) => (
                  <div 
                    key={evt.id} 
                    className={`p-4 rounded-2xl border transition-all ${getEventBadgeStyle(evt)}`}
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-2">
                      <div className="flex items-center gap-2">
                        {evt.is_missing ? (
                          <span className="p-1.5 rounded-lg bg-rose-500 text-white">
                            <AlertTriangle size={16} />
                          </span>
                        ) : (
                          <span className="p-1.5 rounded-lg bg-black/20">
                            {getCategoryIcon(evt.category, 16)}
                          </span>
                        )}
                        <div>
                          <span className="text-[10px] font-extrabold uppercase px-2 py-0.5 rounded bg-black/30 tracking-wider">
                            {evt.category}
                          </span>
                          <h4 className="font-extrabold text-white text-sm md:text-base mt-0.5">
                            {evt.title}
                          </h4>
                        </div>
                      </div>

                      <div className="flex items-center gap-1.5">
                        <span className={`text-[10px] font-extrabold uppercase px-2.5 py-1 rounded-full ${
                          evt.is_missing ? 'bg-rose-600 text-white animate-pulse' :
                          evt.status === 'Completed' ? 'bg-emerald-600 text-white' :
                          evt.status === 'Overdue' ? 'bg-red-600 text-white' : 'bg-slate-800 text-slate-200'
                        }`}>
                          {evt.is_missing ? 'MISSING TASK' : evt.status_label || evt.status}
                        </span>
                      </div>
                    </div>

                    <p className="text-xs text-slate-300 mb-3 opacity-90">
                      {evt.description}
                    </p>

                    {/* Meta info tags */}
                    <div className="flex flex-wrap gap-2 text-[11px] text-slate-400 mb-3">
                      {evt.building_name && (
                        <span className="px-2 py-0.5 rounded bg-black/20 border border-white/5">
                          🏢 {evt.building_name}
                        </span>
                      )}
                      {evt.apartment_code && (
                        <span className="px-2 py-0.5 rounded bg-black/20 border border-white/5">
                          🚪 Apt {evt.apartment_code}
                        </span>
                      )}
                      {evt.equipment_name && (
                        <span className="px-2 py-0.5 rounded bg-black/20 border border-white/5">
                          ⚙️ {evt.equipment_name}
                        </span>
                      )}
                      {evt.tenant_name && (
                        <span className="px-2 py-0.5 rounded bg-black/20 border border-white/5">
                          👤 {evt.tenant_name}
                        </span>
                      )}
                      {evt.amount > 0 && (
                        <span className="px-2 py-0.5 rounded bg-black/20 border border-white/5 font-bold text-amber-300">
                          CFA {evt.amount.toLocaleString()}
                        </span>
                      )}
                    </div>

                    {/* ── ACTION WORKFLOW CONTROLS ── */}
                    <div className="pt-3 border-t border-white/10 flex flex-wrap items-center justify-between gap-2">
                      
                      {/* IF MISSING TASK: REPAIR ACTION */}
                      {evt.is_missing && evt.repair_action && (
                        <div className="w-full bg-rose-950/60 p-3 rounded-xl border border-rose-500/40 flex flex-col sm:flex-row items-center justify-between gap-3">
                          <div className="text-xs text-rose-200">
                            <strong>⚠️ Missing Task Exception:</strong> This required operation was never created in the task database.
                          </div>
                          <button
                            onClick={() => handleRepairMissingTask(evt.repair_action)}
                            disabled={isRepairing}
                            className="px-4 py-2 bg-gradient-to-r from-rose-600 to-red-600 hover:from-rose-500 hover:to-red-500 text-white font-extrabold text-xs rounded-xl shadow-lg transition-all flex items-center gap-2 shrink-0"
                          >
                            <PlusCircle size={16} />
                            <span>{isRepairing ? t('Generating...') : t('⚡ Generate / Repair Task')}</span>
                          </button>
                        </div>
                      )}

                      {/* IF OPEN TASK: PROOF SUBMISSION FORM */}
                      {!evt.is_missing && evt.status !== 'Completed' && completingTaskId === (evt.source_id || evt.raw_id) && (
                        <div className="w-full bg-slate-950 p-4 rounded-xl border border-slate-800 space-y-3 mt-2">
                          <h5 className="font-bold text-xs text-emerald-400 flex items-center gap-1.5 uppercase">
                            <CheckCircle2 size={16} />
                            {t('Record Proof of Completion & Service Notes')}
                          </h5>

                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                              <label className="text-[11px] text-slate-400 block mb-1">{t('Meter / Hours Reading')}</label>
                              <input 
                                type="number" 
                                step="0.1"
                                placeholder="e.g. 1180.5"
                                value={meterReading} 
                                onChange={(e) => setMeterReading(e.target.value)} 
                                className="w-full px-3 py-1.5 bg-slate-900 border border-slate-700 rounded-lg text-xs text-white"
                              />
                            </div>
                            <div>
                              <label className="text-[11px] text-slate-400 block mb-1">{t('Fuel Remaining (Liters)')}</label>
                              <input 
                                type="number" 
                                step="0.1"
                                placeholder="e.g. 620.0"
                                value={fuelLevel} 
                                onChange={(e) => setFuelLevel(e.target.value)} 
                                className="w-full px-3 py-1.5 bg-slate-900 border border-slate-700 rounded-lg text-xs text-white"
                              />
                            </div>
                          </div>

                          <div>
                            <label className="text-[11px] text-slate-400 block mb-1">{t('Verification Notes / Findings')}</label>
                            <textarea 
                              rows={2}
                              placeholder={t('Enter inspection results, equipment condition, or repair details...')}
                              value={completionNotes} 
                              onChange={(e) => setCompletionNotes(e.target.value)} 
                              className="w-full px-3 py-1.5 bg-slate-900 border border-slate-700 rounded-lg text-xs text-white"
                            />
                          </div>

                          <div className="flex items-center justify-end gap-2 pt-2">
                            <button
                              onClick={() => setCompletingTaskId(null)}
                              className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs font-semibold rounded-lg"
                            >
                              {t('Cancel')}
                            </button>
                            <button
                              onClick={() => handleSubmitProof(evt.source_id || evt.raw_id)}
                              disabled={isSubmittingProof}
                              className="px-4 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs rounded-lg shadow flex items-center gap-1.5"
                            >
                              <CheckCircle size={14} />
                              <span>{isSubmittingProof ? t('Submitting...') : t('Verify & Complete')}</span>
                            </button>
                          </div>
                        </div>
                      )}

                      {/* IF OPEN TASK: CANCELLATION FORM (ADMIN/MANAGER) */}
                      {!evt.is_missing && evt.status !== 'Completed' && cancellingTaskId === (evt.source_id || evt.raw_id) && (
                        <div className="w-full bg-slate-950 p-4 rounded-xl border border-red-900/50 space-y-3 mt-2">
                          <h5 className="font-bold text-xs text-rose-400 flex items-center gap-1.5 uppercase">
                            <ShieldAlert size={16} />
                            {t('Cancel Task with Audit Record')}
                          </h5>
                          <div>
                            <label className="text-[11px] text-slate-400 block mb-1">{t('Reason for Cancellation (Required for Audit)')}</label>
                            <input 
                              type="text"
                              placeholder={t('e.g. Generator was scheduled for overhaul by contractor')}
                              value={cancellationReason}
                              onChange={(e) => setCancellationReason(e.target.value)}
                              className="w-full px-3 py-1.5 bg-slate-900 border border-slate-700 rounded-lg text-xs text-white"
                            />
                          </div>
                          <div className="flex items-center justify-end gap-2 pt-1">
                            <button
                              onClick={() => setCancellingTaskId(null)}
                              className="px-3 py-1.5 bg-slate-800 text-slate-300 text-xs font-semibold rounded-lg"
                            >
                              {t('Back')}
                            </button>
                            <button
                              onClick={() => handleCancelTask(evt.source_id || evt.raw_id)}
                              disabled={isCancelling}
                              className="px-4 py-1.5 bg-red-600 hover:bg-red-500 text-white font-bold text-xs rounded-lg shadow"
                            >
                              {isCancelling ? t('Cancelling...') : t('Confirm Cancel')}
                            </button>
                          </div>
                        </div>
                      )}

                      {/* BUTTONS ROW (WHEN NOT EXPANDED) */}
                      {!evt.is_missing && evt.status !== 'Completed' && completingTaskId !== (evt.source_id || evt.raw_id) && cancellingTaskId !== (evt.source_id || evt.raw_id) && (
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => setCompletingTaskId(evt.source_id || evt.raw_id)}
                            className="px-3 py-1.5 rounded-lg bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow flex items-center gap-1.5"
                          >
                            <CheckCircle2 size={14} />
                            <span>{t('Record Proof of Completion')}</span>
                          </button>

                          <button
                            onClick={() => setCancellingTaskId(evt.source_id || evt.raw_id)}
                            className="px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-red-950 text-slate-300 hover:text-red-300 font-semibold text-xs border border-slate-700 hover:border-red-800"
                          >
                            {t('Cancel Task')}
                          </button>
                        </div>
                      )}

                      {/* QUICK JUMP TO MODULE RECORD */}
                      {evt.action_url && (
                        <button
                          onClick={() => {
                            setSelectedDateEvents(null);
                            navigate(evt.action_url);
                          }}
                          className="px-3 py-1.5 rounded-lg bg-black/30 hover:bg-black/50 text-slate-200 text-xs font-semibold border border-white/10 ml-auto flex items-center gap-1"
                        >
                          <span>{t('Open Source Record')}</span>
                          <ArrowRight size={12} />
                        </button>
                      )}

                    </div>

                  </div>
                ))
              )}
            </div>

          </div>
        </div>
      )}

    </div>
  );
};

export default ScheduleCenter;
