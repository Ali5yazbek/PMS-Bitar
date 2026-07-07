import { useTranslation } from 'react-i18next';
import React, { useState, useMemo } from 'react';
import { ChevronLeft, ChevronRight, Calendar as CalendarIcon, AlertTriangle, Droplet, Activity } from 'lucide-react';

const GeneratorCalendar = ({ events }) => {
  const { t } = useTranslation();

  const [currentDate, setCurrentDate] = useState(new Date());

  const getDaysInMonth = (date) => {
    return new Date(date.getFullYear(), date.getMonth() + 1, 0).getDate();
  };

  const getFirstDayOfMonth = (date) => {
    return new Date(date.getFullYear(), date.getMonth(), 1).getDay();
  };

  const prevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const monthNames = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
  
  const daysInMonth = getDaysInMonth(currentDate);
  const firstDay = getFirstDayOfMonth(currentDate);
  
  // Create array of days for the grid
  const blanks = Array(firstDay).fill(null);
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);
  const calendarGrid = [...blanks, ...days];

  const getEventsForDay = (day) => {
    if (!day) return [];
    const targetDateStr = `${currentDate.getFullYear()}-${String(currentDate.getMonth() + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    
    return events?.filter(event => {
      // event.date could be YYYY-MM-DD or full timestamp, we match the prefix
      return event.date && event.date.startsWith(targetDateStr);
    }) || [];
  };

  const EventIcon = ({ type }) => {
    switch(type) {
      case 'refill': return <Droplet size={12} className="text-emerald-400" />;
      case 'maintenance': return <AlertTriangle size={12} className="text-red-400" />;
      case 'reading': return <Activity size={12} className="text-blue-400" />;
      default: return <CalendarIcon size={12} />;
    }
  };

  return (
    <div className="bg-slate-800/50 border border-slate-700 rounded-xl overflow-hidden shadow-lg w-full max-w-4xl">
      {/* Header */}
      <div className="flex items-center justify-between p-4 bg-slate-800 border-b border-slate-700">
        <div className="flex items-center gap-2">
          <CalendarIcon className="text-primary" size={20} />
          <h2 className="text-lg font-bold text-white">
            {monthNames[currentDate.getMonth()]} {currentDate.getFullYear()}
          </h2>
        </div>
        <div className="flex gap-2">
          <button onClick={prevMonth} className="p-2 hover:bg-slate-700 rounded-lg text-white transition-colors">
            <ChevronLeft size={20} />
          </button>
          <button onClick={() => setCurrentDate(new Date())} className="px-3 py-1.5 bg-primary/20 hover:bg-primary/30 text-primary rounded-lg text-sm font-medium transition-colors">
            {t('generatorcalendar.today', { defaultValue: `Today` })}
          </button>
          <button onClick={nextMonth} className="p-2 hover:bg-slate-700 rounded-lg text-white transition-colors">
            <ChevronRight size={20} />
          </button>
        </div>
      </div>

      {/* Days Header */}
      <div className="grid grid-cols-7 gap-px bg-slate-700">
        {['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map(day => (
          <div key={day} className="bg-slate-800 p-2 text-center text-xs font-bold text-muted uppercase tracking-wider">
            {day}
          </div>
        ))}
      </div>

      {/* Grid */}
      <div className="grid grid-cols-7 gap-px bg-slate-700">
        {calendarGrid.map((day, index) => {
          const dayEvents = getEventsForDay(day);
          const isToday = day === new Date().getDate() && 
                          currentDate.getMonth() === new Date().getMonth() && 
                          currentDate.getFullYear() === new Date().getFullYear();

          return (
            <div key={index} className={`min-h-[100px] bg-slate-800/80 p-2 transition-colors hover:bg-slate-700/50 ${!day ? 'opacity-30' : ''}`}>
              {day && (
                <>
                  <div className={`text-sm font-medium mb-1 w-7 h-7 flex items-center justify-center rounded-full ${isToday ? 'bg-primary text-white' : 'text-slate-300'}`}>
                    {day}
                  </div>
                  <div className="space-y-1 overflow-y-auto max-h-[70px] hide-scrollbar">
                    {dayEvents.map(evt => (
                      <div 
                        key={evt.id} 
                        className="text-[10px] px-1.5 py-1 rounded bg-slate-900 border border-slate-700 text-slate-300 truncate flex items-center gap-1.5"
                        title={evt.title}
                      >
                        <EventIcon type={evt.type} />
                        <span className="truncate">{evt.title}</span>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default GeneratorCalendar;
