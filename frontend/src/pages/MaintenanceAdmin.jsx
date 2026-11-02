import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { useSearchParams } from 'react-router-dom';
import { Check, X, Clock, History, Calendar, User, Search, AlertCircle, Filter, FileText } from 'lucide-react';

const MaintenanceAdmin = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [searchParams] = useSearchParams();
  const initialSearch = searchParams.get('search') || '';
  const [searchTerm, setSearchTerm] = useState(initialSearch);
  const [activeTab, setActiveTab] = useState('pending'); // 'pending' or 'history'
  const [selectedTask, setSelectedTask] = useState(null);
  const [historyStatusFilter, setHistoryStatusFilter] = useState('All');
  const [historyDateFilter, setHistoryDateFilter] = useState('');
  const [reportStartDate, setReportStartDate] = useState(() => {
    const d = new Date();
    d.setDate(1);
    return d.toISOString().split('T')[0];
  });
  const [reportEndDate, setReportEndDate] = useState(new Date().toISOString().split('T')[0]);
  const [selectedWorkerTasks, setSelectedWorkerTasks] = useState(null);
  const [toastMsg, setToastMsg] = useState('');
  const [prevPendingCount, setPrevPendingCount] = useState(0);
  const [confirmDialog, setConfirmDialog] = useState({
    isOpen: false,
    title: '',
    message: '',
    onConfirm: null,
    isAlert: false
  });

  const showConfirm = (title, message, onConfirm = null, isAlert = false) => {
    setConfirmDialog({
      isOpen: true,
      title,
      message,
      onConfirm,
      isAlert
    });
  };

  const closeConfirm = () => {
    setConfirmDialog(prev => ({ ...prev, isOpen: false }));
  };

  const { data: pendingTasks, isLoading: loadingPending } = useQuery({
    queryKey: ['adminPendingTasks'],
    queryFn: async () => {
      const res = await axios.get('/maintenance/admin/tasks');
      return res.data;
    },
    refetchInterval: 5000 // Auto-refresh every 5 seconds
  });

  const { data: historyTasks, isLoading: loadingHistory } = useQuery({
    queryKey: ['adminHistoryTasks'],
    queryFn: async () => {
      const res = await axios.get('/maintenance/admin/history');
      return res.data;
    },
    refetchInterval: 10000 // Auto-refresh every 10 seconds
  });

  const { data: tenantRequests, isLoading: loadingTenantRequests } = useQuery({
    queryKey: ['adminTenantRequests'],
    queryFn: async () => {
      const res = await axios.get('/maintenance-tickets/all');
      return res.data;
    },
    refetchInterval: 10000
  });

  const updateTicketStatusMutation = useMutation({
    mutationFn: ({ ticketId, data }) => axios.put(`/maintenance-tickets/${ticketId}/status`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['adminTenantRequests']);
    }
  });

  const { data: buildings, isLoading: loadingBuildings } = useQuery({
    queryKey: ['buildings'],
    queryFn: async () => {
      const res = await axios.get('/buildings');
      return res.data;
    },
    enabled: activeTab === 'schedule'
  });

  const { data: workerReports, isLoading: loadingReports } = useQuery({
    queryKey: ['workerReports', reportStartDate, reportEndDate],
    queryFn: async () => {
      const res = await axios.get(`/maintenance/admin/worker-reports?start_date=${reportStartDate}&end_date=${reportEndDate}`);
      return res.data;
    },
    enabled: activeTab === 'worker-report'
  });

  React.useEffect(() => {
    if (pendingTasks) {
      if (pendingTasks.length > prevPendingCount && prevPendingCount > 0) {
        setToastMsg(t('maintenance.new_pending_toast') || 'New maintenance task received!');
        setTimeout(() => setToastMsg(''), 5000);
      }
      setPrevPendingCount(pendingTasks.length);
    }
  }, [pendingTasks, prevPendingCount, t]);

  const approveMutation = useMutation({
    mutationFn: async (id) => {
      return axios.post(`/maintenance/admin/tasks/${id}/approve`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['adminPendingTasks']);
      queryClient.invalidateQueries(['adminHistoryTasks']);
      queryClient.invalidateQueries(['expiringItems']);
      setSelectedTask(null);
    }
  });

  const rejectMutation = useMutation({
    mutationFn: async (id) => {
      return axios.post(`/maintenance/admin/tasks/${id}/reject`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['adminPendingTasks']);
      queryClient.invalidateQueries(['adminHistoryTasks']);
      queryClient.invalidateQueries(['expiringItems']);
      setSelectedTask(null);
    }
  });

  const generateSmartMutation = useMutation({
    mutationFn: async (buildingId) => {
      return axios.post(`/maintenance/admin/buildings/${buildingId}/generate`);
    },
    onSuccess: (res) => {
      showConfirm('Success', res.data.message, null, true);
      queryClient.invalidateQueries(['adminPendingTasks']);
      queryClient.invalidateQueries(['adminHistoryTasks']);
    },
    onError: (err) => {
      showConfirm('Error', err.response?.data?.error || 'Failed to generate schedules.', null, true);
    }
  });

  const handleApprove = () => {
    showConfirm(
      'Approve Task',
      'Are you sure you want to approve this maintenance task? The next schedule will be created automatically.',
      () => approveMutation.mutate(selectedTask.id)
    );
  };

  const handleReject = () => {
    showConfirm(
      'Reject Task',
      'Are you sure you want to reject this task? The worker will have to resubmit it.',
      () => rejectMutation.mutate(selectedTask.id)
    );
  };

  const handleGenerateSmart = (building) => {
    showConfirm(
      'Generate Smart Schedule',
      `Are you sure you want to smart auto-generate schedules for all apartments in CFA ${building.name} that don't already have an active schedule?`,
      () => generateSmartMutation.mutate(building.id)
    );
  };

  const filteredPendingTasks = Array.isArray(pendingTasks) ? pendingTasks.filter(task => {
    if (!searchTerm) return true;
    const searchStr = `${task.building_name || ''} ${task.apartment_code || ''} ${task.worker_name || ''}`.toLowerCase();
    return searchStr.includes(searchTerm.toLowerCase());
  }) : [];

  const filteredHistoryTasks = Array.isArray(historyTasks) ? historyTasks.filter(task => {
    let statusMatch = historyStatusFilter === 'All' || task.status === historyStatusFilter;
    let dateMatch = true;
    if (historyDateFilter) {
      // Extract YYYY-MM from scheduled_date
      const taskMonth = task.scheduled_date ? task.scheduled_date.substring(0, 7) : '';
      dateMatch = taskMonth === historyDateFilter;
    }
    let searchMatch = true;
    if (searchTerm) {
      const searchStr = `${task.building_name || ''} ${task.apartment_code || ''} ${task.worker_name || ''}`.toLowerCase();
      searchMatch = searchStr.includes(searchTerm.toLowerCase());
    }
    return statusMatch && dateMatch && searchMatch;
  }) : [];

  return (
    <div className="flex flex-col h-full bg-background overflow-hidden">
      <div className="p-8 pb-0 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-6">{t('maintenance.title_admin')}</h1>
        
        <div className="flex flex-col md:flex-row justify-between md:items-center gap-4 mb-6">
          {/* Tabs */}
          <div className="flex border-b border-slate-700/50 overflow-x-auto hide-scrollbar w-full md:w-auto">
            <button
              className={`px-6 py-3 font-medium flex items-center transition-colors border-b-2 whitespace-nowrap ${
                activeTab === 'tenant-requests' 
                  ? 'text-primary border-primary bg-primary/5' 
                  : 'text-slate-400 border-transparent hover:text-white hover:bg-slate-800/30'
              }`}
              onClick={() => setActiveTab('tenant-requests')}
            >
              <AlertCircle size={18} className="me-2" /> Tenant Requests
              {tenantRequests?.filter(t => t.status === 'Open' || t.status === 'In Progress').length > 0 && (
                <span className="ms-2 bg-red-500 text-white text-xs px-2 py-0.5 rounded-full animate-pulse">
                  {tenantRequests.filter(t => t.status === 'Open' || t.status === 'In Progress').length}
                </span>
              )}
            </button>
            <button
              className={`px-6 py-3 font-medium flex items-center transition-colors border-b-2 whitespace-nowrap ${
                activeTab === 'pending' 
                  ? 'text-primary border-primary bg-primary/5' 
                  : 'text-slate-400 border-transparent hover:text-white hover:bg-slate-800/30'
              }`}
              onClick={() => setActiveTab('pending')}
            >
              <Clock size={18} className="me-2" /> {t('maintenance.tab_pending')}
              {pendingTasks?.length > 0 && (
                <span className="ms-2 bg-primary text-white text-xs px-2 py-0.5 rounded-full">{pendingTasks.length}</span>
              )}
            </button>
            <button
              className={`px-6 py-3 font-medium flex items-center transition-colors border-b-2 whitespace-nowrap ${
                activeTab === 'history' 
                  ? 'text-primary border-primary bg-primary/5' 
                  : 'text-slate-400 border-transparent hover:text-white hover:bg-slate-800/30'
              }`}
              onClick={() => setActiveTab('history')}
            >
              <History size={18} className="me-2" /> {t('maintenance.tab_history')}
            </button>
            <button
              className={`px-6 py-3 font-medium flex items-center transition-colors border-b-2 whitespace-nowrap ${
                activeTab === 'schedule' 
                  ? 'text-primary border-primary bg-primary/5' 
                  : 'text-slate-400 border-transparent hover:text-white hover:bg-slate-800/30'
              }`}
              onClick={() => setActiveTab('schedule')}
            >
              <Calendar size={18} className="me-2" /> {t('maintenance.tab_schedule')}
            </button>
            <button
              className={`px-6 py-3 font-medium flex items-center transition-colors border-b-2 whitespace-nowrap ${
                activeTab === 'worker-report' 
                  ? 'text-primary border-primary bg-primary/5' 
                  : 'text-slate-400 border-transparent hover:text-white hover:bg-slate-800/30'
              }`}
              onClick={() => setActiveTab('worker-report')}
            >
              <FileText size={18} className="me-2" /> {t('maintenance.tab_worker_report', 'Worker Report')}
            </button>
          </div>
          
          {/* Search Bar */}
          {activeTab !== 'schedule' && (
            <div className="relative w-full md:w-64 shrink-0">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input 
                type="text" 
                placeholder="Search building or apt..." 
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-800/50 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"
              />
            </div>
          )}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-8 pt-0 hide-scrollbar">
        {activeTab === 'tenant-requests' && (
          <div className="space-y-4">
            {loadingTenantRequests ? (
              <div className="text-white">Loading tenant requests...</div>
            ) : tenantRequests?.length === 0 ? (
              <div className="glass-card p-12 text-center">
                <AlertCircle size={48} className="text-slate-500 mx-auto mb-4" />
                <h3 className="text-xl font-bold text-white mb-2">No Tenant Requests</h3>
                <p className="text-slate-400">Tenants have not submitted any maintenance requests yet.</p>
              </div>
            ) : (
              <div className="space-y-4">
                {tenantRequests?.map(ticket => {
                  const statusColors = {
                    'Open': 'bg-blue-500/20 text-blue-400 border-blue-500/30',
                    'In Progress': 'bg-amber-500/20 text-amber-400 border-amber-500/30',
                    'Resolved': 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
                    'Rejected': 'bg-red-500/20 text-red-400 border-red-500/30',
                    'Closed': 'bg-slate-600/40 text-slate-400 border-slate-600/40'
                  };
                  const color = statusColors[ticket.status] || statusColors['Open'];
                  
                  return (
                    <div key={ticket.id} className={`glass-card p-6 border-l-4 ${ticket.status === 'Open' ? 'border-l-red-500' : 'border-l-slate-600'}`}>
                      <div className="flex justify-between items-start mb-4">
                        <div>
                          <h3 className="text-lg font-bold text-white flex items-center gap-2">
                            #{ticket.id} - {ticket.title}
                            <span className={`text-xs px-2 py-0.5 rounded-full border ${color}`}>{ticket.status}</span>
                            {ticket.priority === 'Urgent' && <span className="bg-red-500/20 text-red-400 text-xs px-2 py-0.5 rounded-full font-bold animate-pulse">URGENT</span>}
                          </h3>
                          <div className="text-sm text-slate-400 mt-1">
                            Submitted by: {ticket.tenant_name} | {ticket.building_name} - Apt {ticket.apartment_code} | {new Date(ticket.created_at).toLocaleString()}
                          </div>
                        </div>
                        <div className="flex gap-2">
                          <select 
                            value={ticket.status}
                            onChange={(e) => updateTicketStatusMutation.mutate({ ticketId: ticket.id, data: { status: e.target.value } })}
                            disabled={updateTicketStatusMutation.isPending}
                            className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-white focus:outline-none focus:border-primary"
                          >
                            <option value="Open">Open</option>
                            <option value="In Progress">In Progress</option>
                            <option value="Resolved">Resolved</option>
                            <option value="Rejected">Rejected</option>
                            <option value="Closed">Closed</option>
                          </select>
                        </div>
                      </div>
                      <div className="bg-slate-800/50 p-4 rounded-lg border border-slate-700 text-slate-300 text-sm whitespace-pre-wrap">
                        <span className="text-xs text-slate-400 font-semibold block mb-1">Issue Description:</span>
                        {ticket.description}
                      </div>

                      {/* Worker Resolution Proof & Notes */}
                      {(ticket.worker_notes || ticket.before_photo || ticket.after_photo || ticket.worker_name) && (
                        <div className="bg-emerald-950/25 border border-emerald-500/30 p-4 rounded-xl mt-3 space-y-3">
                          <div className="flex items-center justify-between text-xs text-emerald-300 font-semibold">
                            <span>Technician: {ticket.worker_name || 'Maintenance Tech'}</span>
                            {ticket.completion_date && <span>Completed: {new Date(ticket.completion_date).toLocaleString()}</span>}
                          </div>
                          {ticket.worker_notes && (
                            <p className="text-sm text-slate-200">
                              <span className="text-slate-400 font-medium">Resolution Notes: </span>
                              {ticket.worker_notes}
                            </p>
                          )}
                          {(ticket.before_photo || ticket.after_photo) && (
                            <div className="flex items-center gap-4 pt-1">
                              {ticket.before_photo && (
                                <div className="space-y-1">
                                  <span className="text-[10px] uppercase font-bold text-slate-400 block">Before Work</span>
                                  <img 
                                    src={ticket.before_photo} 
                                    alt="Before Repair" 
                                    className="w-24 h-24 object-cover rounded-lg border border-slate-700 hover:scale-105 transition-transform cursor-pointer shadow-md"
                                    onClick={() => window.open(ticket.before_photo, '_blank')}
                                  />
                                </div>
                              )}
                              {ticket.after_photo && (
                                <div className="space-y-1">
                                  <span className="text-[10px] uppercase font-bold text-emerald-400 block">After Repair</span>
                                  <img 
                                    src={ticket.after_photo} 
                                    alt="After Repair" 
                                    className="w-24 h-24 object-cover rounded-lg border border-emerald-500/50 hover:scale-105 transition-transform cursor-pointer shadow-md"
                                    onClick={() => window.open(ticket.after_photo, '_blank')}
                                  />
                                </div>
                              )}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {activeTab === 'pending' && (
          <div className="space-y-6">
            {loadingPending ? (
              <div className="text-white">{t('maintenance.loading_pending')}</div>
            ) : filteredPendingTasks && filteredPendingTasks.length > 0 ? (
              <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
                {filteredPendingTasks.map(task => (
                  <div key={task.id} className="glass-card p-6 flex flex-col md:flex-row gap-6 hover:border-primary/30 transition-colors">
                    <div className="flex-1">
                      <div className="flex items-center gap-3 mb-3">
                        <span className="px-3 py-1 rounded-full text-xs font-medium bg-warning/20 text-warning border border-warning/30">
                          {t('maintenance.badge_pending')}
                        </span>
                        <span className="text-slate-400 text-sm flex items-center">
                          <Calendar size={14} className="me-1" /> {t('maintenance.submitted')} {new Date(task.submission_date).toLocaleDateString()}
                        </span>
                      </div>
                      <h3 className="text-xl font-bold text-white">{t('maintenance.building')} {task.building_name}</h3>
                      <p className="text-lg text-slate-300 mb-4">{t('maintenance.apt')} {task.apartment_code}</p>
                      <div className="flex items-center text-sm text-slate-400 mb-4">
                        <User size={16} className="me-2" />
                        {t('maintenance.worker')} <span className="text-white ms-1 font-medium">{task.worker_name || 'Unknown'}</span>
                      </div>
                      <button 
                        onClick={() => setSelectedTask(task)}
                        className="btn-primary px-6 py-2 rounded-xl flex items-center"
                      >
                        <Search size={16} className="me-2" /> {t('maintenance.btn_review')}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="glass-card p-12 flex flex-col items-center justify-center text-center">
                <Check size={48} className="text-success mb-4 opacity-50" />
                <h3 className="text-xl font-bold text-white mb-2">{t('maintenance.no_pending')}</h3>
                <p className="text-muted">{t('maintenance.no_pending_sub')}</p>
              </div>
            )}
          </div>
        )}

        {activeTab === 'history' && (
          <div className="space-y-6">
            <div className="glass-card p-4 flex flex-col md:flex-row gap-4 items-center justify-between">
              <div className="flex items-center text-white font-medium">
                <Filter size={18} className="me-2 text-primary" /> {t('maintenance.filter_history')}
              </div>
              <div className="flex flex-col md:flex-row gap-4 w-full md:w-auto">
                <select
                  value={historyStatusFilter}
                  onChange={(e) => setHistoryStatusFilter(e.target.value)}
                  className="bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary appearance-none cursor-pointer"
                >
                  <option value="All" className="bg-slate-900">{t('maintenance.all_statuses')}</option>
                  <option value="Completed" className="bg-slate-900">{t('maintenance.status_completed')}</option>
                  <option value="Scheduled" className="bg-slate-900">{t('maintenance.status_scheduled')}</option>
                  <option value="Pending_Approval" className="bg-slate-900">{t('maintenance.status_pending')}</option>
                  <option value="Rejected" className="bg-slate-900">{t('maintenance.status_rejected')}</option>
                </select>
                
                <input
                  type="month"
                  value={historyDateFilter}
                  onChange={(e) => setHistoryDateFilter(e.target.value)}
                  className="bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary cursor-pointer"
                />
                
                {historyDateFilter && (
                  <button 
                    onClick={() => setHistoryDateFilter('')}
                    className="text-slate-400 hover:text-white transition-colors"
                    title="Clear Date Filter"
                  >
                    <X size={20} />
                  </button>
                )}
              </div>
            </div>
            
            <div className="glass-card overflow-hidden">
              {loadingHistory ? (
                <div className="p-8 text-white">Loading history...</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-start border-collapse">
                    <thead>
                      <tr className="border-b border-slate-700/50 bg-slate-800/30">
                        <th className="p-4 text-sm font-semibold text-muted uppercase text-start">{t('maintenance.col_date')}</th>
                        <th className="p-4 text-sm font-semibold text-muted uppercase text-start">{t('maintenance.col_loc')}</th>
                        <th className="p-4 text-sm font-semibold text-muted uppercase text-start">{t('maintenance.col_worker')}</th>
                        <th className="p-4 text-sm font-semibold text-muted uppercase text-start">{t('maintenance.col_status')}</th>
                        <th className="p-4 text-sm font-semibold text-muted uppercase text-end">{t('maintenance.col_action')}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700/50">
                      {filteredHistoryTasks && filteredHistoryTasks.length > 0 ? filteredHistoryTasks.map(task => (
                        <tr key={task.id} className="hover:bg-slate-800/30 transition-colors">
                          <td className="p-4 text-white">
                            <div className="font-medium">{task.completion_date ? new Date(task.completion_date).toLocaleDateString() : 'N/A'}</div>
                            <div className="text-xs text-slate-400">{t('maintenance.scheduled')} {task.scheduled_date}</div>
                          </td>
                          <td className="p-4">
                            <div className="text-white font-medium">{t('maintenance.building')} {task.building_name}</div>
                            <div className="text-slate-400 text-sm">{t('maintenance.apt')} {task.apartment_code}</div>
                          </td>
                          <td className="p-4 text-slate-300">{task.worker_name || '-'}</td>
                          <td className="p-4">
                            <span className={`px-2 py-1 rounded text-xs font-medium border ${
                              task.status === 'Completed' ? 'bg-success/20 text-success border-success/30' :
                              task.status === 'Rejected' ? 'bg-danger/20 text-danger border-danger/30' :
                              task.status === 'Pending_Approval' ? 'bg-warning/20 text-warning border-warning/30' :
                              'bg-slate-800 text-slate-400 border-slate-700'
                            }`}>
                              {t(`maintenance.status_${task.status.toLowerCase()}`)}
                            </span>
                          </td>
                          <td className="p-4 text-end">
                            <button 
                              onClick={() => setSelectedTask(task)}
                              className="text-primary hover:text-white text-sm font-medium transition-colors"
                            >
                              {t('maintenance.btn_details')}
                            </button>
                          </td>
                        </tr>
                      )) : (
                        <tr>
                          <td colSpan="5" className="p-8 text-center text-muted">{t('maintenance.no_history')}</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        )}

        {activeTab === 'schedule' && (
          <div className="space-y-6">
            <div className="glass-card p-6 flex items-center mb-6">
              <AlertCircle size={24} className="text-primary me-4 shrink-0" />
              <div>
                <h3 className="font-bold text-white text-lg">{t('maintenance.smart_title')}</h3>
                <p className="text-slate-400 text-sm">
                  {t('maintenance.smart_sub')}
                </p>
              </div>
            </div>
            
            {loadingBuildings ? (
              <div className="text-white">Loading buildings...</div>
            ) : buildings && buildings.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {buildings.map(building => (
                  <div key={building.id} className="glass-card p-6 flex flex-col justify-between">
                    <div className="mb-6">
                      <h3 className="text-xl font-bold text-white mb-2">{building.name}</h3>
                      <p className="text-muted text-sm">{t('maintenance.card_gen_sub')}</p>
                    </div>
                    <button 
                      onClick={() => handleGenerateSmart(building)}
                      disabled={generateSmartMutation.isLoading}
                      className="w-full btn-primary py-2 rounded-xl flex items-center justify-center font-medium"
                    >
                      {generateSmartMutation.isLoading ? t('maintenance.btn_gen_loading') : t('maintenance.btn_gen')}
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-muted">{t('maintenance.no_buildings')}</div>
            )}
          </div>
        )}

        {activeTab === 'worker-report' && (
          <div className="space-y-6">
            <div className="glass-card p-4 flex flex-col md:flex-row gap-4 items-center justify-between">
              <div className="flex items-center text-white font-medium">
                <Filter size={18} className="me-2 text-primary" /> Filter Report
              </div>
              <div className="flex flex-col md:flex-row gap-4 w-full md:w-auto">
                <div className="flex items-center gap-2">
                  <span className="text-slate-400 text-sm font-medium">From:</span>
                  <input
                    type="date"
                    value={reportStartDate}
                    onChange={(e) => setReportStartDate(e.target.value)}
                    className="bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary cursor-pointer"
                  />
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-slate-400 text-sm font-medium">To:</span>
                  <input
                    type="date"
                    value={reportEndDate}
                    onChange={(e) => setReportEndDate(e.target.value)}
                    className="bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2 text-white focus:outline-none focus:border-primary cursor-pointer"
                  />
                </div>
              </div>
            </div>

            {loadingReports ? (
              <div className="text-white">Loading reports...</div>
            ) : workerReports && workerReports.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                {workerReports.map(report => (
                  <div key={report.worker_id} className="glass-card p-6 flex flex-col justify-between">
                    <div className="flex items-center gap-4 mb-6">
                      <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center text-primary shrink-0">
                        <User size={24} />
                      </div>
                      <div>
                        <h3 className="text-lg font-bold text-white">{report.worker_name}</h3>
                        <p className="text-sm text-slate-400">Maintenance Role</p>
                      </div>
                    </div>
                    
                    {report.tasks_count > 0 ? (
                      <div className="bg-slate-800/50 rounded-xl p-4 mb-6 flex items-center justify-between border border-slate-700/50">
                        <div>
                          <p className="text-slate-400 text-sm">Tasks Completed</p>
                          <p className="text-2xl font-bold text-white">{report.tasks_count}</p>
                        </div>
                        <Check className="text-success" size={28} />
                      </div>
                    ) : (
                      <div className="bg-slate-800/50 rounded-xl p-4 mb-6 flex items-center justify-center border border-slate-700/50 text-center">
                        <p className="text-slate-400 text-sm font-medium">This worker didn't do anything.</p>
                      </div>
                    )}
                    
                    <button 
                      onClick={() => setSelectedWorkerTasks(report)}
                      disabled={report.tasks_count === 0}
                      className={`w-full py-2 rounded-xl flex items-center justify-center font-medium transition-colors ${
                        report.tasks_count === 0 
                        ? 'bg-slate-800 text-slate-500 cursor-not-allowed'
                        : 'btn-primary'
                      }`}
                    >
                      {report.tasks_count === 0 ? 'No Tasks to View' : 'View Tasks'}
                    </button>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-muted">No maintenance workers found.</div>
            )}
          </div>
        )}
      </div>

      {/* Review/Details Modal */}
      {selectedTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="glass-panel w-full max-w-4xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center p-6 border-b border-slate-700/50">
              <div>
                <h2 className="text-xl font-bold text-white">{t('maintenance.modal_title')}</h2>
                <p className="text-muted text-sm">{t('maintenance.building')} {selectedTask.building_name} - {t('maintenance.apt')} {selectedTask.apartment_code}</p>
              </div>
              <button onClick={() => setSelectedTask(null)} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto hide-scrollbar flex-1">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
                {/* Before Photo */}
                <div>
                  <h3 className="text-sm font-medium text-slate-400 uppercase tracking-wider mb-3">{t('maintenance.before_photo')}</h3>
                  {selectedTask.before_photo ? (
                    <div className="rounded-xl overflow-hidden border border-slate-700 bg-black aspect-video flex items-center justify-center">
                      <img src={selectedTask.before_photo} alt="Before" className="max-w-full max-h-full object-contain" />
                    </div>
                  ) : (
                    <div className="rounded-xl border border-slate-700 bg-slate-800/50 aspect-video flex items-center justify-center text-slate-500">
                      {t('maintenance.no_photo')}
                    </div>
                  )}
                </div>

                {/* After Photo */}
                <div>
                  <h3 className="text-sm font-medium text-slate-400 uppercase tracking-wider mb-3">{t('maintenance.after_photo')}</h3>
                  {selectedTask.after_photo ? (
                    <div className="rounded-xl overflow-hidden border border-slate-700 bg-black aspect-video flex items-center justify-center">
                      <img src={selectedTask.after_photo} alt="After" className="max-w-full max-h-full object-contain" />
                    </div>
                  ) : (
                    <div className="rounded-xl border border-slate-700 bg-slate-800/50 aspect-video flex items-center justify-center text-slate-500">
                      {t('maintenance.no_photo')}
                    </div>
                  )}
                </div>
              </div>

              <div className="glass-card p-6 border-s-4 border-s-primary">
                <h3 className="text-sm font-medium text-slate-400 uppercase tracking-wider mb-2">{t('maintenance.worker_notes')}</h3>
                <p className="text-white whitespace-pre-wrap">{selectedTask.notes || t('maintenance.no_notes')}</p>
              </div>
            </div>
            
            {selectedTask.status === 'Pending_Approval' && (
              <div className="p-6 border-t border-slate-700/50 flex justify-end gap-4 bg-slate-900/50">
                <button 
                  onClick={handleReject} 
                  className="px-6 py-2 rounded-xl text-danger font-medium hover:bg-danger/10 border border-danger/30 transition-colors flex items-center"
                  disabled={approveMutation.isLoading || rejectMutation.isLoading}
                >
                  <X size={18} className="me-2" /> {t('maintenance.btn_reject')}
                </button>
                <button 
                  onClick={handleApprove}
                  className="btn-primary px-8 py-2 rounded-xl flex items-center"
                  disabled={approveMutation.isLoading || rejectMutation.isLoading}
                >
                  <Check size={18} className="me-2" /> {t('maintenance.btn_approve')}
                </button>
              </div>
            )}
            
            {selectedTask.status !== 'Pending_Approval' && (
              <div className="p-6 border-t border-slate-700/50 flex justify-end gap-4 bg-slate-900/50">
                <button 
                  onClick={() => setSelectedTask(null)} 
                  className="px-6 py-2 rounded-xl text-white font-medium bg-slate-800 hover:bg-slate-700 transition-colors"
                >
                  {t('maintenance.btn_close')}
                </button>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Worker Tasks Modal */}
      {selectedWorkerTasks && (
        <div className="fixed inset-0 z-[55] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="glass-panel w-full max-w-4xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center p-6 border-b border-slate-700/50">
              <div>
                <h2 className="text-xl font-bold text-white">Tasks by {selectedWorkerTasks.worker_name}</h2>
                <p className="text-muted text-sm">Period: {reportStartDate} to {reportEndDate}</p>
              </div>
              <button onClick={() => setSelectedWorkerTasks(null)} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto hide-scrollbar flex-1 space-y-4">
              {selectedWorkerTasks.tasks.map(task => (
                <div key={task.id} className="bg-slate-800/30 border border-slate-700/50 rounded-xl p-4 flex flex-col md:flex-row gap-4 justify-between items-center hover:border-primary/50 transition-colors">
                  <div>
                    <h4 className="text-white font-bold mb-1">Building {task.building_name}</h4>
                    <p className="text-slate-400 text-sm">Apt {task.apartment_code}</p>
                  </div>
                  <div className="text-sm text-slate-500">
                    Submitted: {new Date(task.submission_date).toLocaleString()}
                  </div>
                  <button 
                    onClick={() => setSelectedTask(task)}
                    className="text-primary hover:text-white transition-colors flex items-center px-4 py-2 bg-primary/10 rounded-lg font-medium"
                  >
                    <Search size={16} className="me-2" /> View Details
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Custom Confirm/Alert Modal */}
      {confirmDialog.isOpen && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="glass-panel w-full max-w-md overflow-hidden flex flex-col animate-in zoom-in-95 duration-200">
            <div className="p-6">
              <div className="flex items-center gap-3 mb-4">
                {confirmDialog.isAlert ? (
                  <AlertCircle size={24} className={confirmDialog.title === 'Error' ? 'text-danger' : 'text-success'} />
                ) : (
                  <AlertCircle size={24} className="text-warning" />
                )}
                <h2 className="text-xl font-bold text-white">{confirmDialog.title}</h2>
              </div>
              <p className="text-slate-300 leading-relaxed">{confirmDialog.message}</p>
            </div>
            
            <div className="p-6 border-t border-slate-700/50 flex justify-end gap-4 bg-slate-900/50">
              {!confirmDialog.isAlert && (
                <button 
                  onClick={closeConfirm} 
                  className="px-6 py-2 rounded-xl text-white font-medium hover:bg-slate-800 transition-colors"
                >
                  Cancel
                </button>
              )}
              <button 
                onClick={() => {
                  if (confirmDialog.onConfirm) confirmDialog.onConfirm();
                  closeConfirm();
                }}
                className="btn-primary px-8 py-2 rounded-xl"
              >
                {confirmDialog.isAlert ? 'OK' : 'Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed bottom-4 right-4 bg-primary text-white px-6 py-3 rounded-xl shadow-xl animate-in fade-in slide-in-from-bottom-4 flex items-center gap-3 z-50">
          <AlertCircle size={20} />
          <span className="font-medium">{toastMsg}</span>
        </div>
      )}
    </div>
  );
};

export default MaintenanceAdmin;
