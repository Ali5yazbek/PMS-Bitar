import React from 'react';
import { useNavigate } from 'react-router-dom';
import { X, Calendar, AlertTriangle, FileText, Zap, PenTool, ExternalLink } from 'lucide-react';
import { format } from 'date-fns';

const getIconForType = (type) => {
  switch (type) {
    case 'Contract': return <FileText size={20} className="text-blue-400" />;
    case 'Subscription': return <Zap size={20} className="text-yellow-400" />;
    case 'Maintenance': return <PenTool size={20} className="text-indigo-400" />;
    default: return <AlertTriangle size={20} className="text-red-400" />;
  }
};

const ExpiryAlertsModal = ({ isOpen, onClose, alerts }) => {
  const navigate = useNavigate();

  const handleView = (alert) => {
    onClose();
    if (alert.type === 'Contract') {
      navigate(`/tenants/${alert.tenant_id}`);
    } else if (alert.type === 'Subscription') {
      navigate(`/apartments/${alert.apartment_id}/electricity`);
    } else if (alert.type === 'Maintenance') {
      navigate(`/maintenance-admin`);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-[100] flex items-center justify-center p-4">
      <div 
        className="glass-card w-full max-w-3xl rounded-2xl border border-slate-700/50 shadow-2xl flex flex-col max-h-[90vh] animate-in fade-in zoom-in duration-200"
      >
        {/* Header */}
        <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30 rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-red-500/20 rounded-lg">
              <AlertTriangle className="text-red-400" size={24} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white">Upcoming Expirations</h2>
              <p className="text-sm text-slate-400">Items expiring within the next 30 days or overdue</p>
            </div>
          </div>
          <button 
            onClick={onClose}
            className="p-2 hover:bg-slate-700/50 rounded-lg transition-colors text-slate-400 hover:text-white"
          >
            <X size={24} />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto flex-1 custom-scrollbar">
          {alerts?.length === 0 ? (
            <div className="text-center py-12">
              <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-slate-800/50 mb-4">
                <Calendar className="text-slate-500" size={32} />
              </div>
              <h3 className="text-lg font-medium text-white mb-2">You're all caught up!</h3>
              <p className="text-slate-400">No items are expiring in the next 30 days.</p>
            </div>
          ) : (
            <div className="space-y-4">
              {alerts?.map((alert) => {
                const isOverdue = alert.days_left < 0;
                const isUrgent = alert.days_left >= 0 && alert.days_left <= 7;
                
                return (
                  <div 
                    key={`${alert.type}-${alert.id}`}
                    className="flex flex-col md:flex-row md:items-center justify-between p-4 bg-slate-800/40 rounded-xl border border-slate-700/50 hover:bg-slate-800/60 transition-colors"
                  >
                    <div className="flex items-start md:items-center gap-4 mb-4 md:mb-0">
                      <div className="p-3 bg-slate-700/30 rounded-xl hidden md:block">
                        {getIconForType(alert.type)}
                      </div>
                      <div>
                        <div className="flex items-center gap-2 mb-1">
                          <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-slate-700 text-slate-300">
                            {alert.type}
                          </span>
                          <h4 className="text-white font-medium">{alert.name}</h4>
                        </div>
                        <p className="text-sm text-slate-400 flex items-center gap-2">
                          <span className="text-slate-300 font-medium">Apt {alert.apartment_code}</span>
                          <span>&bull;</span>
                          <span>{alert.building_name}</span>
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-4 pl-[52px] md:pl-0">
                      <div className="text-left md:text-right hidden sm:block">
                        <div className="text-sm text-slate-400 mb-1">Due Date</div>
                        <div className="font-medium text-white">
                          {format(new Date(alert.due_date), 'dd MMM yyyy')}
                        </div>
                      </div>
                      
                      <div className={`
                        px-4 py-2 rounded-xl text-center min-w-[100px] border
                        ${isOverdue 
                          ? 'bg-red-500/10 border-red-500/20 text-red-400' 
                          : isUrgent 
                            ? 'bg-orange-500/10 border-orange-500/20 text-orange-400'
                            : 'bg-indigo-500/10 border-indigo-500/20 text-indigo-400'}
                      `}>
                        <div className="text-xl font-bold">
                          {Math.abs(alert.days_left)}
                        </div>
                        <div className="text-xs font-medium uppercase tracking-wider">
                          {isOverdue ? 'Days Overdue' : 'Days Left'}
                        </div>
                      </div>

                      <button
                        onClick={() => handleView(alert)}
                        className="p-2 ml-2 bg-slate-700/50 hover:bg-primary/20 text-slate-300 hover:text-primary rounded-lg transition-colors border border-transparent hover:border-primary/30"
                        title="View Details"
                      >
                        <ExternalLink size={20} />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
        
        {/* Footer */}
        <div className="p-6 border-t border-slate-700/50 bg-slate-800/30 rounded-b-2xl flex justify-end">
          <button
            onClick={onClose}
            className="px-6 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors font-medium"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  );
};

export default ExpiryAlertsModal;
