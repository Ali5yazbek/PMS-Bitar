import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../api/axios';
import { Calendar as CalendarIcon, ChevronLeft, ChevronRight, CheckCircle, Clock, AlertCircle, X, FileText } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const ScheduleCenter = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [currentDate, setCurrentDate] = useState(new Date());
  
  // Modal State
  const [selectedDateEvents, setSelectedDateEvents] = useState(null);
  const [selectedDateStr, setSelectedDateStr] = useState(null);

  const { data: events, isLoading } = useQuery({
    queryKey: ['scheduleCalendar'],
    queryFn: async () => {
      const res = await api.get('/schedule/calendar');
      return res.data;
    }
  });

  const getDaysInMonth = (year, month) => {
    return new Date(year, month + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (year, month) => {
    return new Date(year, month, 1).getDay();
  };

  const prevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const daysInMonth = getDaysInMonth(currentDate.getFullYear(), currentDate.getMonth());
  const firstDay = getFirstDayOfMonth(currentDate.getFullYear(), currentDate.getMonth());
  
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const getEventColor = (evt, dateObj) => {
    const isToday = dateObj.getTime() === today.getTime();
    
    if (evt.event_type === 'ac' && evt.status === 'Completed') return 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    if (evt.event_type === 'rent' && evt.status === 'Paid') return 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    
    if (dateObj < today && evt.status !== 'Paid' && evt.status !== 'Completed') {
      return 'bg-red-500/20 text-red-400 border-red-500/30'; // Overdue
    }
    
    if (isToday) return 'bg-purple-500/20 text-purple-400 border-purple-500/30'; // Today
    
    if (evt.event_type === 'rent') return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
    if (evt.event_type === 'contract_end') return 'bg-purple-500/20 text-purple-400 border-purple-500/30';
    if (evt.event_type === 'ac') return 'bg-orange-500/20 text-orange-400 border-orange-500/30';
    
    return 'bg-slate-700/50 text-slate-300';
  };

  const renderCells = () => {
    const cells = [];
    // Padding days
    for (let i = 0; i < firstDay; i++) {
      cells.push(<div key={`pad-${i}`} className="p-2 min-h-[120px] bg-slate-900/30 border border-slate-800/50 rounded-xl opacity-50"></div>);
    }
    
    for (let day = 1; day <= daysInMonth; day++) {
      const dateStr = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
      const cellDate = new Date(currentDate.getFullYear(), currentDate.getMonth(), day);
      const isToday = cellDate.getTime() === today.getTime();
      
      const dayEvents = events?.filter(e => e.date === dateStr) || [];
      
      cells.push(
        <div 
          key={`day-${day}`} 
          onClick={() => {
            setSelectedDateEvents(dayEvents);
            setSelectedDateStr(dateStr);
          }}
          className={`p-3 min-h-[120px] cursor-pointer glass-card border flex flex-col transition-colors ${isToday ? 'border-purple-500/50 bg-purple-500/5' : 'border-slate-700/50 hover:bg-slate-800/50'}`}
        >
          <div className="flex justify-between items-start mb-2">
            <span className={`font-bold text-lg ${isToday ? 'text-purple-400' : 'text-slate-300'}`}>{day}</span>
            {dayEvents.length > 0 && <span className="text-xs bg-slate-800 px-2 py-0.5 rounded-full text-slate-400 border border-slate-700/50">{dayEvents.length}</span>}
          </div>
          <div className="flex-1 space-y-1.5 overflow-y-auto hide-scrollbar max-h-32">
            {dayEvents.map(evt => (
              <div key={`${evt.event_type}-${evt.id}`} className={`text-xs px-2 py-1.5 rounded-lg border flex items-center space-x-1.5 ${getEventColor(evt, cellDate)}`}>
                {evt.event_type === 'rent' ? <DollarSignIcon size={12} /> : evt.event_type === 'contract_end' ? <FileText size={12} /> : <CalendarIcon size={12} />}
                <span className="font-medium truncate w-full" title={`${evt.building_name} - ${evt.apartment_code}`}>
                  {evt.building_name}-{evt.apartment_code} 
                </span>
              </div>
            ))}
          </div>
        </div>
      );
    }
    return cells;
  };

  const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

  // Helper just for the dollar sign icon
  const DollarSignIcon = ({size}) => (
    <svg xmlns="http://www.w3.org/2000/svg" width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="1" x2="12" y2="23"></line><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path></svg>
  );

  return (
    <div className="flex h-full w-full bg-background overflow-hidden relative">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <CalendarIcon className="me-3 text-primary" size={32} />
              {t('schedule.title')}
            </h1>
            <p className="text-muted mt-2">{t('schedule.subtitle')}</p>
          </div>
          
          <div className="flex items-center space-x-4 bg-slate-800 p-2 rounded-xl border border-slate-700/50">
            <button onClick={prevMonth} className="p-2 hover:bg-slate-700 rounded-lg text-slate-300 transition-colors">
              <ChevronLeft size={20} />
            </button>
            <span className="text-lg font-bold text-white min-w-[150px] text-center">
              {monthNames[currentDate.getMonth()]} {currentDate.getFullYear()}
            </span>
            <button onClick={nextMonth} className="p-2 hover:bg-slate-700 rounded-lg text-slate-300 transition-colors">
              <ChevronRight size={20} />
            </button>
          </div>
        </div>

        {/* Legend */}
        <div className="flex flex-wrap gap-4 mb-8 p-4 glass-card justify-center">
          <div className="flex items-center space-x-2 text-sm"><span className="w-3 h-3 rounded-full bg-emerald-500"></span><span className="text-slate-300">{t('schedule.cal_completed')}</span></div>
          <div className="flex items-center space-x-2 text-sm"><span className="w-3 h-3 rounded-full bg-blue-500"></span><span className="text-slate-300">{t('schedule.cal_rent_due')}</span></div>
          <div className="flex items-center space-x-2 text-sm"><span className="w-3 h-3 rounded-full bg-orange-500"></span><span className="text-slate-300">{t('schedule.cal_ac_clean')}</span></div>
          <div className="flex items-center space-x-2 text-sm"><span className="w-3 h-3 rounded-full bg-red-500"></span><span className="text-slate-300">{t('schedule.card_rent_overdue')}</span></div>
          <div className="flex items-center space-x-2 text-sm"><span className="w-3 h-3 rounded-full bg-purple-500"></span><span className="text-slate-300">Today</span></div>
        </div>

        {isLoading ? (
          <div className="text-center p-12 text-muted">Loading schedule...</div>
        ) : (
          <div className="w-full min-w-[800px]">
            <div className="grid grid-cols-7 gap-4 mb-4">
              {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
                <div key={day} className="text-center font-bold text-muted uppercase tracking-wider text-sm">
                  {day}
                </div>
              ))}
            </div>
            <div className="grid grid-cols-7 gap-4 pb-12">
              {renderCells()}
            </div>
          </div>
        )}
      </div>

      {/* Day Events Modal */}
      {selectedDateEvents && (
        <div className="absolute inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-700/80 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col max-h-[80vh]">
            <div className="p-4 border-b border-slate-700 flex justify-between items-center bg-slate-800/50">
              <h2 className="text-xl font-bold text-white flex items-center">
                <CalendarIcon size={20} className="mr-3 text-primary" />
                Tasks for {selectedDateStr}
              </h2>
              <button 
                onClick={() => setSelectedDateEvents(null)} 
                className="p-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-full transition-colors"
              >
                <X size={20} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 bg-slate-900">
              {selectedDateEvents.length === 0 ? (
                <div className="text-center py-10 text-muted flex flex-col items-center">
                  <CheckCircle size={48} className="text-emerald-500/20 mb-4" />
                  <p className="text-lg">No tasks scheduled for this day!</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {selectedDateEvents.map(evt => {
                    const evtDateObj = new Date(evt.date);
                    const colorClasses = getEventColor(evt, evtDateObj);
                    return (
                      <div key={`${evt.event_type}-${evt.id}`} className={`p-4 rounded-xl border flex items-center justify-between ${colorClasses}`}>
                        <div className="flex items-center space-x-4">
                          <div className={`p-2 rounded-lg bg-black/10`}>
                            {evt.event_type === 'rent' ? <DollarSignIcon size={20} /> : evt.event_type === 'contract_end' ? <FileText size={20} /> : <AlertCircle size={20} />}
                          </div>
                          <div>
                            <p className="font-bold">{evt.event_type === 'rent' ? t('schedule.cal_rent_due') : evt.event_type === 'contract_end' ? t('schedule.cal_contract_end', { defaultValue: 'Contract Ending' }) : t('schedule.cal_ac_clean')}</p>
                            <p className="text-sm opacity-80">{evt.building_name} - Apartment {evt.apartment_code}</p>
                          </div>
                        </div>
                        <button 
                          onClick={() => {
                            setSelectedDateEvents(null);
                            navigate(evt.event_type === 'rent' ? `/rent?search=${evt.apartment_code}` : evt.event_type === 'contract_end' ? `/tenant-details/${evt.id}` : `/maintenance-admin?search=${evt.apartment_code}`);
                          }}
                          className="px-4 py-2 bg-black/20 hover:bg-black/40 rounded-lg text-sm font-medium transition-colors"
                        >
                          View Details
                        </button>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default ScheduleCenter;
