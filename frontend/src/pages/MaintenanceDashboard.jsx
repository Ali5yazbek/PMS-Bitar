import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { 
  CheckCircle, 
  Camera, 
  AlertCircle, 
  X, 
  Wrench, 
  User, 
  Phone, 
  Flame, 
  Building2, 
  DoorClosed,
  Layers,
  Sparkles
} from 'lucide-react';

const MaintenanceDashboard = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [selectedTask, setSelectedTask] = useState(null);
  const [activeFilter, setActiveFilter] = useState('all'); // 'all', 'tenant_ticket', 'routine_ac'
  const [beforePhoto, setBeforePhoto] = useState(null);
  const [afterPhoto, setAfterPhoto] = useState(null);
  const [notes, setNotes] = useState('');
  const [errorMsg, setErrorMsg] = useState('');

  // User from local storage
  const user = JSON.parse(localStorage.getItem('user'));

  const { data: tasks = [], isLoading, error } = useQuery({
    queryKey: ['workerTasks'],
    queryFn: async () => {
      const res = await axios.get('/maintenance/tasks');
      return res.data || [];
    }
  });

  const submitMutation = useMutation({
    mutationFn: async (payload) => {
      return axios.post(`/maintenance/tasks/${payload.id}/submit`, payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['workerTasks']);
      closeModal();
    },
    onError: (err) => {
      setErrorMsg(err.response?.data?.error || 'Failed to submit task resolution.');
    }
  });

  const handleFileChange = (e, setPhoto) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          const MAX_WIDTH = 900;
          const MAX_HEIGHT = 900;
          let width = img.width;
          let height = img.height;

          if (width > height) {
            if (width > MAX_WIDTH) {
              height *= MAX_WIDTH / width;
              width = MAX_WIDTH;
            }
          } else {
            if (height > MAX_HEIGHT) {
              width *= MAX_HEIGHT / height;
              height = MAX_HEIGHT;
            }
          }
          canvas.width = width;
          canvas.height = height;

          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, width, height);

          const dataUrl = canvas.toDataURL('image/jpeg', 0.75);
          setPhoto(dataUrl);
        };
        img.src = reader.result;
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!beforePhoto || !afterPhoto || !notes.trim()) {
      setErrorMsg(t('maintenance_worker.req_error') || 'Before Photo, After Photo, and Resolution Notes are required.');
      return;
    }
    submitMutation.mutate({
      id: selectedTask.id,
      task_id: selectedTask.id,
      task_type: selectedTask.task_type || 'routine_ac',
      before_photo: beforePhoto,
      after_photo: afterPhoto,
      notes,
      worker_notes: notes,
      worker_id: user?.id
    });
  };

  const closeModal = () => {
    setSelectedTask(null);
    setBeforePhoto(null);
    setAfterPhoto(null);
    setNotes('');
    setErrorMsg('');
  };

  // Counts
  const tenantCount = tasks.filter(t => t.task_type === 'tenant_ticket').length;
  const acCount = tasks.filter(t => t.task_type === 'routine_ac' || !t.task_type).length;
  const urgentCount = tasks.filter(t => (t.priority || '').toLowerCase() === 'urgent' || (t.priority || '').toLowerCase() === 'high').length;

  const filteredTasks = tasks.filter(t => {
    if (activeFilter === 'tenant_ticket') return t.task_type === 'tenant_ticket';
    if (activeFilter === 'routine_ac') return t.task_type === 'routine_ac' || !t.task_type;
    return true;
  });

  const getPriorityBadge = (priority) => {
    const p = (priority || 'medium').toLowerCase();
    if (p === 'urgent') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-500/20 text-rose-300 border border-rose-500/40 animate-pulse">
          <Flame size={12} className="text-rose-400" /> URGENT
        </span>
      );
    }
    if (p === 'high') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-500/20 text-amber-300 border border-amber-500/40">
          <AlertCircle size={12} className="text-amber-400" /> HIGH
        </span>
      );
    }
    if (p === 'low') {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-500/20 text-slate-300 border border-slate-500/30">
          LOW
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-500/20 text-blue-300 border border-blue-500/30">
        MEDIUM
      </span>
    );
  };

  if (isLoading) {
    return (
      <div className="flex-1 flex items-center justify-center h-full bg-background">
        <div className="flex flex-col items-center gap-3">
          <div className="w-10 h-10 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
          <p className="text-slate-400 font-medium">Loading maintenance tasks...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex-1 p-8 bg-background h-full">
        <div className="bg-rose-500/10 border border-rose-500/30 text-rose-300 p-6 rounded-2xl flex items-center gap-4">
          <AlertCircle size={28} className="text-rose-400 shrink-0" />
          <div>
            <h3 className="font-bold text-lg">Error loading work orders</h3>
            <p className="text-sm text-rose-300/80">Please check your network connection or try refreshing the page.</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto p-6 md:p-8 hide-scrollbar bg-background h-full">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-8">
        <div>
          <h1 className="text-2xl md:text-3xl font-extrabold text-white flex items-center gap-3">
            <Wrench className="text-primary w-8 h-8" />
            Maintenance Operations & Work Orders
          </h1>
          <p className="text-slate-400 mt-1">
            Real-time field tasks: tenant apartment repair requests and scheduled routine cleanings.
          </p>
        </div>

        {/* Quick KPI stats */}
        <div className="flex items-center gap-3">
          <div className="px-4 py-2 rounded-xl bg-slate-800/80 border border-slate-700/60 flex items-center gap-2">
            <span className="text-xs text-slate-400 uppercase font-semibold">Total Assigned</span>
            <span className="text-lg font-bold text-white">{tasks.length}</span>
          </div>
          {urgentCount > 0 && (
            <div className="px-4 py-2 rounded-xl bg-rose-500/20 border border-rose-500/40 flex items-center gap-2 animate-pulse">
              <Flame size={16} className="text-rose-400" />
              <span className="text-xs text-rose-300 uppercase font-bold">{urgentCount} Urgent</span>
            </div>
          )}
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex flex-wrap items-center gap-2 mb-6 border-b border-slate-800 pb-4">
        <button
          onClick={() => setActiveFilter('all')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeFilter === 'all'
              ? 'bg-primary text-white shadow-lg shadow-primary/25'
              : 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-800'
          }`}
        >
          <Layers size={16} />
          All Tasks
          <span className="ml-1 px-2 py-0.5 rounded-full text-xs bg-black/30 font-bold">{tasks.length}</span>
        </button>

        <button
          onClick={() => setActiveFilter('tenant_ticket')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeFilter === 'tenant_ticket'
              ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/25'
              : 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-800'
          }`}
        >
          <User size={16} />
          Tenant Requests
          <span className={`ml-1 px-2 py-0.5 rounded-full text-xs font-bold ${
            tenantCount > 0 ? 'bg-indigo-400/30 text-indigo-200' : 'bg-black/30'
          }`}>
            {tenantCount}
          </span>
        </button>

        <button
          onClick={() => setActiveFilter('routine_ac')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-all ${
            activeFilter === 'routine_ac'
              ? 'bg-cyan-600 text-white shadow-lg shadow-cyan-600/25'
              : 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-800'
          }`}
        >
          <Sparkles size={16} />
          Routine AC Cleanings
          <span className="ml-1 px-2 py-0.5 rounded-full text-xs bg-black/30 font-bold">{acCount}</span>
        </button>
      </div>

      {/* Task Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        {filteredTasks && filteredTasks.length > 0 ? (
          filteredTasks.map(task => {
            const isTenantTicket = task.task_type === 'tenant_ticket';

            return (
              <div 
                key={`${task.task_type || 'ac'}-${task.id}`} 
                className={`glass-card p-6 flex flex-col justify-between border transition-all hover:border-slate-600/80 ${
                  isTenantTicket 
                    ? 'border-indigo-500/30 bg-gradient-to-b from-slate-900/90 via-slate-900/80 to-indigo-950/20 shadow-lg' 
                    : 'border-slate-700/60 bg-slate-900/70'
                }`}
              >
                <div>
                  {/* Top Status & Category Badges */}
                  <div className="flex items-center justify-between gap-2 mb-4">
                    <div className="flex items-center gap-2 flex-wrap">
                      {isTenantTicket ? (
                        <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold tracking-wider uppercase bg-indigo-500/20 text-indigo-300 border border-indigo-500/40 flex items-center gap-1">
                          <User size={12} /> Tenant Request
                        </span>
                      ) : (
                        <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold tracking-wider uppercase bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 flex items-center gap-1">
                          <Sparkles size={12} /> Routine AC
                        </span>
                      )}

                      {getPriorityBadge(task.priority)}
                    </div>

                    <span className="text-xs text-slate-400 font-mono">
                      {task.scheduled_date || (task.created_at ? task.created_at.substring(0, 10) : '')}
                    </span>
                  </div>

                  {/* Apartment & Building Header */}
                  <div className="flex items-start justify-between gap-2 mb-3">
                    <div>
                      <div className="flex items-center gap-1.5 text-xs text-slate-400 font-medium">
                        <Building2 size={14} className="text-slate-400" />
                        <span>{task.building_name || 'Building'}</span>
                      </div>
                      <h3 className="text-xl font-extrabold text-white flex items-center gap-2 mt-0.5">
                        <DoorClosed size={20} className="text-primary" />
                        Apartment {task.apartment_code || 'N/A'}
                      </h3>
                    </div>

                    {task.category && (
                      <span className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-slate-800 text-slate-300 border border-slate-700">
                        {task.category}
                      </span>
                    )}
                  </div>

                  {/* Tenant Details (if available) */}
                  {task.tenant_name && (
                    <div className="mb-3.5 px-3 py-2 rounded-xl bg-slate-800/50 border border-slate-700/50 flex items-center justify-between text-xs text-slate-300">
                      <div className="flex items-center gap-2">
                        <User size={14} className="text-slate-400" />
                        <span className="font-semibold text-slate-200">{task.tenant_name}</span>
                      </div>
                      {task.tenant_phone && (
                        <a 
                          href={`tel:${task.tenant_phone}`}
                          className="flex items-center gap-1 text-primary hover:underline font-mono"
                        >
                          <Phone size={12} />
                          {task.tenant_phone}
                        </a>
                      )}
                    </div>
                  )}

                  {/* Problem Title & Description */}
                  <div className="mb-6">
                    <h4 className="text-base font-bold text-slate-100 mb-1.5 line-clamp-2">
                      {task.title || (isTenantTicket ? 'Tenant Reported Issue' : 'AC Filter & Coil Cleaning')}
                    </h4>
                    
                    <div className="p-3 rounded-xl bg-slate-950/60 border border-slate-800/80 text-sm text-slate-300 max-h-28 overflow-y-auto hide-scrollbar leading-relaxed">
                      {task.description ? (
                        <p>{task.description}</p>
                      ) : (
                        <p className="text-slate-500 italic">No additional problem description provided.</p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Complete Button */}
                <button 
                  onClick={() => setSelectedTask(task)}
                  className={`w-full py-2.5 px-4 flex items-center justify-center gap-2 rounded-xl font-bold text-sm shadow-md transition-all active:scale-[0.98] ${
                    isTenantTicket
                      ? 'bg-gradient-to-r from-indigo-600 to-primary text-white hover:opacity-95 shadow-indigo-900/30'
                      : 'btn-primary shadow-primary/20'
                  }`}
                >
                  <CheckCircle size={18} />
                  {isTenantTicket ? 'Resolve Tenant Work Order' : 'Complete AC Cleaning'}
                </button>
              </div>
            );
          })
        ) : (
          <div className="col-span-full glass-card p-12 flex flex-col items-center justify-center text-center">
            <CheckCircle size={52} className="text-emerald-400 mb-4 opacity-75" />
            <h3 className="text-2xl font-bold text-white mb-2">No Active Work Orders</h3>
            <p className="text-slate-400 max-w-md">
              {activeFilter === 'tenant_ticket' 
                ? 'Great news! There are currently no unresolved tenant apartment requests.'
                : activeFilter === 'routine_ac'
                ? 'No routine AC cleanings are currently pending.'
                : 'All maintenance tasks and apartment requests are up to date!'}
            </p>
          </div>
        )}
      </div>

      {/* Task Completion Modal */}
      {selectedTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-md p-4 animate-fadeIn">
          <div className="glass-panel w-full max-w-2xl overflow-hidden flex flex-col max-h-[92vh] border border-slate-700/80 rounded-2xl shadow-2xl">
            {/* Modal Header */}
            <div className="flex justify-between items-start p-6 border-b border-slate-700/60 bg-slate-900/80">
              <div>
                <div className="flex items-center gap-2 mb-1.5">
                  <span className={`px-2.5 py-0.5 rounded-full text-xs font-bold uppercase tracking-wider ${
                    selectedTask.task_type === 'tenant_ticket'
                      ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/40'
                      : 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/40'
                  }`}>
                    {selectedTask.task_type === 'tenant_ticket' ? 'Tenant Issue Resolution' : 'AC Cleaning Task'}
                  </span>
                  {selectedTask.category && (
                    <span className="px-2 py-0.5 rounded text-xs bg-slate-800 text-slate-300">
                      {selectedTask.category}
                    </span>
                  )}
                </div>
                <h2 className="text-xl font-bold text-white">
                  {selectedTask.title || 'Work Order Resolution'}
                </h2>
                <p className="text-slate-400 text-xs mt-1">
                  Building: <span className="text-slate-200 font-semibold">{selectedTask.building_name}</span> &bull; Apt: <span className="text-primary font-bold">{selectedTask.apartment_code}</span>
                  {selectedTask.tenant_name && <span> &bull; Tenant: <span className="text-slate-200">{selectedTask.tenant_name}</span></span>}
                </p>
              </div>

              <button 
                onClick={closeModal} 
                className="text-slate-400 hover:text-white transition-colors p-1.5 rounded-lg hover:bg-slate-800"
              >
                <X size={22} />
              </button>
            </div>
            
            {/* Modal Form Body */}
            <div className="p-6 overflow-y-auto hide-scrollbar flex-1 space-y-6">
              {errorMsg && (
                <div className="bg-rose-500/20 text-rose-300 p-4 rounded-xl border border-rose-500/40 flex items-center gap-3">
                  <AlertCircle size={20} className="shrink-0 text-rose-400" />
                  <span className="text-sm font-medium">{errorMsg}</span>
                </div>
              )}

              {/* Problem Brief (For Worker Reference) */}
              <div className="p-4 rounded-xl bg-slate-900/90 border border-slate-800">
                <span className="text-xs uppercase tracking-wider font-bold text-slate-400 block mb-1">
                  Reported Problem Description
                </span>
                <p className="text-sm text-slate-200 leading-relaxed">
                  {selectedTask.description || 'Routine preventive maintenance inspection and service.'}
                </p>
              </div>

              <form id="task-form" onSubmit={handleSubmit} className="space-y-6">
                {/* Photo Documentation: Before & After */}
                <div>
                  <label className="block text-sm font-semibold text-slate-200 mb-2">
                    Photo Proof Documentation <span className="text-rose-400">*</span>
                  </label>
                  <p className="text-xs text-slate-400 mb-4">
                    Attach clear before & after photos verifying the issue and the completed repair work.
                  </p>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Before Photo */}
                    <div className="space-y-1.5">
                      <span className="block text-xs font-semibold text-slate-300 uppercase">
                        1. Before Photo (Initial Problem)
                      </span>
                      <div className={`border-2 border-dashed ${
                        beforePhoto ? 'border-primary/60 bg-primary/5' : 'border-slate-700 hover:border-slate-500'
                      } rounded-xl p-3 text-center cursor-pointer transition-all relative overflow-hidden h-44 flex items-center justify-center`}>
                        <input 
                          type="file" 
                          accept="image/*" 
                          capture="environment"
                          onChange={(e) => handleFileChange(e, setBeforePhoto)} 
                          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                        />
                        {beforePhoto ? (
                          <img src={beforePhoto} alt="Before work" className="w-full h-full object-cover rounded-lg" />
                        ) : (
                          <div className="flex flex-col items-center gap-2">
                            <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-slate-400">
                              <Camera size={20} />
                            </div>
                            <span className="text-xs font-medium text-slate-300">Take or Upload Before Photo</span>
                            <span className="text-[10px] text-slate-500">Camera or gallery</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* After Photo */}
                    <div className="space-y-1.5">
                      <span className="block text-xs font-semibold text-slate-300 uppercase">
                        2. After Photo (Fixed & Tested)
                      </span>
                      <div className={`border-2 border-dashed ${
                        afterPhoto ? 'border-emerald-500/60 bg-emerald-500/5' : 'border-slate-700 hover:border-slate-500'
                      } rounded-xl p-3 text-center cursor-pointer transition-all relative overflow-hidden h-44 flex items-center justify-center`}>
                        <input 
                          type="file" 
                          accept="image/*" 
                          capture="environment"
                          onChange={(e) => handleFileChange(e, setAfterPhoto)} 
                          className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                        />
                        {afterPhoto ? (
                          <img src={afterPhoto} alt="After work" className="w-full h-full object-cover rounded-lg" />
                        ) : (
                          <div className="flex flex-col items-center gap-2">
                            <div className="w-10 h-10 rounded-full bg-slate-800 flex items-center justify-center text-slate-400">
                              <Camera size={20} />
                            </div>
                            <span className="text-xs font-medium text-slate-300">Take or Upload After Photo</span>
                            <span className="text-[10px] text-slate-500">Camera or gallery</span>
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Worker Resolution Notes */}
                <div className="space-y-2">
                  <label className="block text-sm font-semibold text-slate-200">
                    Resolution Notes & Actions Taken <span className="text-rose-400">*</span>
                  </label>
                  <textarea 
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Describe exactly what was repaired, replaced, or adjusted (e.g. replaced leaking gasket, cleared drainage line, tested AC cooling, confirmed normal operation with tenant)."
                    className="w-full bg-slate-900 border border-slate-700/80 rounded-xl p-3.5 text-white placeholder:text-slate-500 focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary h-28 resize-none text-sm leading-relaxed"
                    required
                  ></textarea>
                </div>
              </form>
            </div>
            
            {/* Modal Footer */}
            <div className="p-5 border-t border-slate-700/60 flex items-center justify-end gap-3 bg-slate-900/90">
              <button 
                type="button" 
                onClick={closeModal} 
                className="px-5 py-2.5 rounded-xl text-slate-300 font-semibold hover:bg-slate-800 transition-colors text-sm"
                disabled={submitMutation.isLoading}
              >
                Cancel
              </button>
              <button 
                type="submit" 
                form="task-form"
                className="btn-primary px-7 py-2.5 rounded-xl font-bold text-sm flex items-center gap-2 shadow-lg shadow-primary/20"
                disabled={submitMutation.isLoading}
              >
                {submitMutation.isLoading ? (
                  <>
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                    Submitting Resolution...
                  </>
                ) : (
                  <>
                    <CheckCircle size={18} />
                    Mark Resolved & Submit
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MaintenanceDashboard;
