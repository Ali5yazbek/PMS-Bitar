import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { CheckCircle, XCircle, Zap, BatteryCharging, AlertCircle, Building2, ChevronRight, Home, User, Eye, Filter, X, Search, History } from 'lucide-react';

const ReadingsVerification = () => {
  const { t } = useTranslation();

  const getLocalISODate = () => {
    const d = new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    return d.toISOString().split('T')[0];
  };

  const [activeTab, setActiveTab] = useState('electricity');
  const [selectedReading, setSelectedReading] = useState(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [reportStartDate, setReportStartDate] = useState(getLocalISODate());
  const [reportEndDate, setReportEndDate] = useState(getLocalISODate());
  const [selectedAgentTasks, setSelectedAgentTasks] = useState(null);
  const [expandedTaskId, setExpandedTaskId] = useState(null);
  const queryClient = useQueryClient();

  const { data: meterReadings = [], isLoading: loadingMeters } = useQuery({
    queryKey: ['pendingMeterReadings'],
    queryFn: async () => {
      const res = await api.get('/energy/apartments/meter-readings/pending');
      return res.data;
    },
    refetchInterval: 3000,
  });

  const { data: generatorReadings = [], isLoading: loadingGenerators } = useQuery({
    queryKey: ['pendingGeneratorReadings'],
    queryFn: async () => {
      const res = await api.get('/energy/reports/pending');
      return res.data;
    },
    refetchInterval: 3000,
  });

  const { data: subReadings = [], isLoading: loadingSubReadings } = useQuery({
    queryKey: ['pendingSubReadings'],
    queryFn: async () => {
      try {
        const res = await api.get('/energy/agent/subscription-readings/pending');
        return res.data;
      } catch (e) {
        return [];
      }
    },
    refetchInterval: 5000,
  });

  const { data: agentReports = [], isLoading: loadingAgentReports } = useQuery({
    queryKey: ['agentReports', reportStartDate, reportEndDate],
    queryFn: async () => {
      const res = await api.get(`/energy/admin/agent-reports?start_date=${reportStartDate}&end_date=${reportEndDate}`);
      return res.data;
    },
    enabled: activeTab === 'agent-report',
  });

  const { data: generatorHistory = [], isLoading: loadingGenHistory } = useQuery({
    queryKey: ['generatorHistory'],
    queryFn: async () => {
      const res = await api.get('/energy/agent/history/generators');
      return res.data;
    },
    enabled: activeTab === 'generator-history',
  });

  const { data: subTasksData, isLoading: loadingSubHistory } = useQuery({
    queryKey: ['subHistory'],
    queryFn: async () => {
      const res = await api.get('/energy/agent/subscription-tasks');
      return res.data;
    },
    enabled: activeTab === 'subscriptions-history',
  });
  const subHistory = subTasksData?.history || [];

  const meterMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/meter-readings/${data.id}/verify`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['pendingMeterReadings']);
      setSelectedReading(null);
      setRejectionReason('');
    }
  });

  const generatorMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/reports/${data.id}/verify`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['pendingGeneratorReadings']);
      setSelectedReading(null);
      setRejectionReason('');
    }
  });

  const subReadingMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/agent/subscription-readings/${data.id}/verify`, {
      status: data.status,
      rejection_reason: data.rejection_reason
    }),
    onSuccess: () => {
      queryClient.invalidateQueries(['pendingSubReadings']);
      setSelectedReading(null);
      setRejectionReason('');
    }
  });

  const handleVerify = (status) => {
    if (status === 'Rejected' && !rejectionReason.trim()) {
      alert('Please provide a rejection reason.');
      return;
    }

    const payload = {
      id: selectedReading.id,
      status,
      rejection_reason: status === 'Rejected' ? rejectionReason : null
    };

    if (activeTab === 'electricity') {
      meterMutation.mutate(payload);
    } else if (activeTab === 'generator') {
      generatorMutation.mutate(payload);
    } else if (activeTab === 'subscriptions') {
      // Subscription readings use 'Accepted' / 'Rejected'
      subReadingMutation.mutate({ ...payload, status: status === 'Verified' ? 'Accepted' : 'Rejected' });
    }
  };

  const getFullImageUrl = (path) => {
    if (!path) return null;
    const baseUrl = api.defaults.baseURL.replace(/\/backend\/api$/, '').replace(/\/api$/, '');
    return `${baseUrl}/${path}`;
  };

  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <h1 className="text-3xl font-bold text-white mb-2">
          {t('readingsverification.readings_verification', { defaultValue: 'Readings Verification' })}
        </h1>
        <p className="text-muted mb-8">
          {t('readingsverification.review_and_verify_meter_and_ge', { defaultValue: 'Review and verify meter and generator readings submitted by utility agents.' })}
        </p>

        {/* Tabs */}
        <div className="flex gap-2 mb-6 border-b border-slate-700 pb-0 flex-wrap">
          <button
            onClick={() => setActiveTab('electricity')}
            className={`px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'electricity' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            <Zap size={18} />
            Electricity Meters ({meterReadings?.length || 0})
          </button>
          <button
            onClick={() => setActiveTab('generator')}
            className={`px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'generator' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            <BatteryCharging size={18} />
            Generators ({generatorReadings?.length || 0})
          </button>
          <button
            onClick={() => setActiveTab('subscriptions')}
            className={`relative px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'subscriptions' ? 'text-indigo-400 border-indigo-400' : 'text-muted border-transparent hover:text-white'}`}
          >
            <Zap size={18} className="text-indigo-400" />
            Subscription Meters ({subReadings?.length || 0})
            {subReadings?.length > 0 && (
              <span className="ml-1 px-1.5 py-0.5 bg-danger text-white text-xs font-bold rounded-full">
                {subReadings.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setActiveTab('agent-report')}
            className={`px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'agent-report' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            <User size={18} />
            Agent Report
          </button>
          <button
            onClick={() => setActiveTab('generator-history')}
            className={`px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'generator-history' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            <History size={18} />
            Generator History
          </button>
          <button
            onClick={() => setActiveTab('subscriptions-history')}
            className={`px-5 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'subscriptions-history' ? 'text-indigo-400 border-indigo-400' : 'text-muted border-transparent hover:text-white'}`}
          >
            <History size={18} className="text-indigo-400" />
            Subscription History
          </button>
        </div>

        {/* List */}
        <div className="glass-card p-6 min-h-[60vh]">
          {/* ── Electricity Tab ── */}
          {activeTab === 'electricity' && (
            loadingMeters ? <p className="text-muted">Loading...</p> :
            meterReadings?.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <CheckCircle size={48} className="mb-4 text-success/50" />
                <p>All electricity readings verified.</p>
              </div>
            ) : (
              <div className="grid gap-4">
                {meterReadings?.map(r => (
                  <div key={r.id} className="flex justify-between items-center p-4 bg-slate-800/50 rounded-xl border border-slate-700 hover:bg-slate-800 transition-colors cursor-pointer" onClick={() => setSelectedReading(r)}>
                    <div>
                      <h3 className="font-bold text-white">{r.building_name} - Apt {r.apartment_code}</h3>
                      <p className="text-sm text-muted">Submitted by: {r.submitter_name || 'Unknown'} on {new Date(r.created_at).toLocaleString()}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xl font-black text-indigo-300">{r.consumption} kWh</p>
                      <p className="text-xs text-muted">Total: {r.current_reading} kWh</p>
                    </div>
                  </div>
                ))}
              </div>
            )
          )}

          {/* ── Generator Tab ── */}
          {activeTab === 'generator' && (
            loadingGenerators ? <p className="text-muted">Loading...</p> :
            generatorReadings?.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <CheckCircle size={48} className="mb-4 text-success/50" />
                <p>All generator readings verified.</p>
              </div>
            ) : (
              <div className="grid gap-4">
                {generatorReadings?.map(r => (
                  <div key={r.id} className="flex justify-between items-center p-4 bg-slate-800/50 rounded-xl border border-slate-700 hover:bg-slate-800 transition-colors cursor-pointer" onClick={() => setSelectedReading(r)}>
                    <div>
                      <h3 className="font-bold text-white">{r.building_name} - {r.generator_name}</h3>
                      <p className="text-sm text-muted">Submitted by: {r.submitter_name || 'Unknown'} on {new Date(r.created_at).toLocaleString()}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xl font-black text-indigo-300">+{r.kwh_produced} kWh</p>
                      <p className="text-xs text-muted">Date: {new Date(r.date).toLocaleDateString()}</p>
                    </div>
                  </div>
                ))}
              </div>
            )
          )}

          {/* ── Subscription Meters Tab ── */}
          {activeTab === 'subscriptions' && (
            loadingSubReadings ? <p className="text-muted">Loading...</p> :
            subReadings?.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <CheckCircle size={48} className="mb-4 text-success/50" />
                <p>No pending subscription meter readings.</p>
              </div>
            ) : (
              <div className="grid gap-4">
                {subReadings?.map(r => (
                  <div
                    key={r.id}
                    className="p-4 bg-slate-800/50 rounded-xl border border-indigo-500/30 hover:bg-slate-800 transition-colors cursor-pointer"
                    onClick={() => setSelectedReading(r)}
                  >
                    {/* Breadcrumb */}
                    <div className="flex items-center gap-1.5 text-xs text-slate-400 mb-2">
                      <Building2 size={12} className="text-indigo-400" />
                      <span className="text-indigo-300 font-medium">{r.building_name}</span>
                      <ChevronRight size={12} />
                      <Home size={12} className="text-sky-400" />
                      <span className="text-sky-300 font-medium">Apt {r.apartment_code}</span>
                      <ChevronRight size={12} />
                      <User size={12} className="text-emerald-400" />
                      <span className="text-emerald-300 font-medium">{r.tenant_name || 'N/A'}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <div>
                        <p className="text-sm text-muted">Submitted by: {r.submitter_name || 'Agent'} • {new Date(r.created_at).toLocaleString()}</p>
                        <div className="flex gap-4 mt-1 text-sm">
                          <span className="text-slate-400">Prev: <span className="text-white font-bold">{r.previous_reading} kWh</span></span>
                          <span className="text-slate-400">New: <span className="text-primary font-bold">{r.current_reading} kWh</span></span>
                        </div>
                      </div>
                      <div className="text-right">
                        <p className="text-xl font-black text-indigo-300">+{parseFloat(r.consumption || 0).toFixed(0)} kWh</p>
                        <p className="text-xs text-muted">Sub: {r.start_date} → {r.end_date}</p>
                      </div>
                    </div>
                    {r.photo_path && (
                      <a
                        href={getFullImageUrl(r.photo_path)}
                        target="_blank"
                        rel="noreferrer"
                        onClick={e => e.stopPropagation()}
                        className="mt-2 flex items-center gap-1 text-xs text-info hover:underline"
                      >
                        <Eye size={12} /> View meter photo
                      </a>
                    )}
                  </div>
                ))}
              </div>
            )
          )}

          {/* ── Agent Report Tab ── */}
          {activeTab === 'agent-report' && (
            <div className="space-y-6">
              <div className="p-4 flex flex-col md:flex-row gap-4 items-center justify-between border border-slate-700/50 bg-slate-800/20 rounded-xl">
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

              {loadingAgentReports ? (
                <div className="text-muted py-8 text-center">Loading reports...</div>
              ) : agentReports?.length === 0 ? (
                <div className="text-muted py-8 text-center">No agents found.</div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
                  {agentReports.map(report => (
                    <div key={report.id} className="p-6 bg-slate-800/50 rounded-xl border border-slate-700 hover:bg-slate-800 transition-colors flex flex-col justify-between">
                      <div className="flex items-center gap-4 mb-6">
                        <div className="w-12 h-12 rounded-full bg-primary/20 flex items-center justify-center text-primary shrink-0">
                          <User size={24} />
                        </div>
                        <div>
                          <h3 className="text-lg font-bold text-white">{report.name}</h3>
                          <p className="text-sm text-slate-400">Agent Role</p>
                        </div>
                      </div>
                      
                      {report.tasks_count > 0 ? (
                        <div className="bg-slate-900/50 rounded-xl p-4 mb-6 flex items-center justify-between border border-slate-700/50">
                          <div>
                            <p className="text-slate-400 text-sm">Readings Submitted</p>
                            <p className="text-2xl font-bold text-white">{report.tasks_count}</p>
                          </div>
                          <CheckCircle className="text-success" size={28} />
                        </div>
                      ) : (
                        <div className="bg-slate-900/50 rounded-xl p-4 mb-6 flex items-center justify-center border border-slate-700/50 text-center min-h-[88px]">
                          <p className="text-slate-400 text-sm font-medium">This agent didn't do anything.</p>
                        </div>
                      )}
                      
                      <button 
                        onClick={() => setSelectedAgentTasks(report)}
                        disabled={report.tasks_count === 0}
                        className={`w-full py-2 rounded-xl flex items-center justify-center font-medium transition-colors ${
                          report.tasks_count === 0 
                          ? 'bg-slate-700 text-slate-500 cursor-not-allowed'
                          : 'bg-primary text-white hover:bg-primary/90'
                        }`}
                      >
                        {report.tasks_count === 0 ? 'No Tasks to View' : 'View Tasks'}
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ── Generator History Tab ── */}
          {activeTab === 'generator-history' && (
            loadingGenHistory ? <p className="text-muted">Loading...</p> :
            generatorHistory?.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <p>No generator history found.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-start border-collapse">
                  <thead>
                    <tr className="border-b border-slate-700/50 bg-slate-800/30">
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Date</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Building / Gen</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">kWh Produced</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {generatorHistory.map(r => (
                      <tr key={r.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="p-4 text-white font-medium">{new Date(r.date).toLocaleDateString()}</td>
                        <td className="p-4 text-white">{r.building_name} - {r.generator_name}</td>
                        <td className="p-4 text-indigo-300 font-bold">{r.kwh_produced} kWh</td>
                        <td className="p-4">
                          <span className={`px-2 py-1 rounded text-xs font-medium border ${r.status === 'Verified' ? 'bg-success/20 text-success border-success/30' : 'bg-slate-800 text-slate-400 border-slate-700'}`}>
                            {r.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
          )}

          {/* ── Subscription History Tab ── */}
          {activeTab === 'subscriptions-history' && (
            loadingSubHistory ? <p className="text-muted">Loading...</p> :
            subHistory?.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-12 text-muted">
                <p>No subscription history found.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-start border-collapse">
                  <thead>
                    <tr className="border-b border-slate-700/50 bg-slate-800/30">
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Date</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Location</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Consumption</th>
                      <th className="p-4 text-sm font-semibold text-muted uppercase text-start">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {subHistory.map(r => (
                      <tr key={r.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="p-4 text-white font-medium">{new Date(r.created_at).toLocaleDateString()}</td>
                        <td className="p-4 text-white">{r.building_name} - Apt {r.apartment_code}</td>
                        <td className="p-4 text-indigo-300 font-bold">{r.consumption} kWh</td>
                        <td className="p-4">
                          <span className={`px-2 py-1 rounded text-xs font-medium border ${r.status === 'Accepted' ? 'bg-success/20 text-success border-success/30' : r.status === 'Rejected' ? 'bg-danger/20 text-danger border-danger/30' : 'bg-warning/20 text-warning border-warning/30'}`}>
                            {r.status}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )
          )}
        </div>
      </div>

      {/* ── Side Panel ── */}
      {selectedReading && (
        <div className="w-96 border-l border-slate-700 p-6 overflow-y-auto flex flex-col gap-6 bg-background">
          <div className="flex justify-between items-center">
            <h2 className="text-xl font-bold text-white">Review Reading</h2>
            <button onClick={() => { setSelectedReading(null); setRejectionReason(''); }} className="text-muted hover:text-white text-2xl">×</button>
          </div>

          {/* Info */}
          {activeTab === 'subscriptions' && (
            <div className="bg-indigo-500/10 border border-indigo-500/30 rounded-xl p-4 space-y-2 text-sm">
              <div className="flex items-center gap-2 text-slate-300">
                <Building2 size={14} className="text-indigo-400" /> <span className="font-medium">{selectedReading.building_name}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-300">
                <Home size={14} className="text-sky-400" /> <span>Apt {selectedReading.apartment_code}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-300">
                <User size={14} className="text-emerald-400" /> <span>{selectedReading.tenant_name || 'N/A'}</span>
              </div>
              <hr className="border-indigo-500/20" />
              <div className="grid grid-cols-3 gap-2 text-center">
                <div><p className="text-xs text-slate-500">Previous</p><p className="font-bold text-white">{selectedReading.previous_reading}</p></div>
                <div><p className="text-xs text-slate-500">Current</p><p className="font-bold text-primary">{selectedReading.current_reading}</p></div>
                <div><p className="text-xs text-slate-500">Consumed</p><p className="font-bold text-info">{parseFloat(selectedReading.consumption || 0).toFixed(0)}</p></div>
              </div>
              <p className="text-xs text-slate-400 text-center">kWh each</p>
              <p className="text-xs text-amber-400 mt-2">⚡ Accepting will auto-renew this subscription by 1 month and save the meter reading.</p>
            </div>
          )}

          {activeTab !== 'subscriptions' && (
            <div className="bg-slate-800 rounded-xl p-4 space-y-3 text-sm">
              {activeTab === 'electricity' && <>
                <div className="flex justify-between"><span className="text-muted">Building / Apt:</span><span className="text-white font-medium">{selectedReading.building_name} - {selectedReading.apartment_code}</span></div>
                <div className="flex justify-between"><span className="text-muted">Prev. Reading:</span><span className="text-white">{selectedReading.previous_reading} kWh</span></div>
                <div className="flex justify-between"><span className="text-muted">New Reading:</span><span className="text-white font-bold">{selectedReading.current_reading} kWh</span></div>
                <div className="flex justify-between"><span className="text-muted">Consumption:</span><span className="text-indigo-300 font-bold">{selectedReading.consumption} kWh</span></div>
                <div className="flex justify-between"><span className="text-muted">Bill Amount:</span><span className="text-success font-bold">${selectedReading.bill_amount}</span></div>
              </>}
              {activeTab === 'generator' && <>
                <div className="flex justify-between"><span className="text-muted">Building:</span><span className="text-white font-medium">{selectedReading.building_name}</span></div>
                <div className="flex justify-between"><span className="text-muted">Generator:</span><span className="text-white">{selectedReading.generator_name}</span></div>
                <div className="flex justify-between"><span className="text-muted">kWh Produced:</span><span className="text-indigo-300 font-bold">+{selectedReading.kwh_produced}</span></div>
                <div className="flex justify-between"><span className="text-muted">Running Hours:</span><span className="text-white">{selectedReading.running_hours}h</span></div>
                <div className="flex justify-between"><span className="text-muted">Notes:</span><span className="text-white">{selectedReading.notes || '—'}</span></div>
              </>}
            </div>
          )}

          {/* Photo */}
          {selectedReading.photo_path && (
            <div>
              <p className="text-sm text-muted mb-2">Meter Photo</p>
              <img src={getFullImageUrl(selectedReading.photo_path)} alt="Meter" className="w-full rounded-xl border border-slate-700 object-cover max-h-56" />
            </div>
          )}

          {/* Notes if present */}
          {selectedReading.notes && (
            <div className="bg-slate-800/50 rounded-xl p-3">
              <p className="text-xs text-slate-400 mb-1">Agent Notes</p>
              <p className="text-sm text-white">{selectedReading.notes}</p>
            </div>
          )}

          {/* Rejection reason */}
          <div>
            <label className="block text-sm text-muted mb-2">Rejection Reason (if rejecting)</label>
            <textarea
              rows={3}
              value={rejectionReason}
              onChange={e => setRejectionReason(e.target.value)}
              className="w-full bg-slate-800 border border-slate-600 rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-danger resize-none"
              placeholder="Explain why the reading is being rejected..."
            />
          </div>

          {/* Actions */}
          <div className="flex gap-3 mt-auto">
            <button
              onClick={() => handleVerify('Verified')}
              className="flex-1 bg-success hover:bg-success/80 text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2 transition-colors shadow-lg shadow-success/20"
            >
              <CheckCircle size={18} /> {activeTab === 'subscriptions' ? 'Accept & Renew' : 'Verify'}
            </button>
            <button
              onClick={() => handleVerify('Rejected')}
              className="flex-1 bg-danger hover:bg-danger/80 text-white font-bold py-3 rounded-xl flex items-center justify-center gap-2 transition-colors shadow-lg shadow-danger/20"
            >
              <XCircle size={18} /> Reject
            </button>
          </div>
        </div>
      )}

      {/* ── Agent Tasks Modal ── */}
      {selectedAgentTasks && (
        <div className="fixed inset-0 z-[55] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-xl shadow-2xl w-full max-w-4xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center p-6 border-b border-slate-700/50">
              <div>
                <h2 className="text-xl font-bold text-white">Readings by {selectedAgentTasks.name}</h2>
                <p className="text-muted text-sm">Period: {reportStartDate} to {reportEndDate}</p>
              </div>
              <button onClick={() => setSelectedAgentTasks(null)} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto hide-scrollbar flex-1 space-y-4">
              {selectedAgentTasks.tasks.map(task => (
                <div key={task.id + task.task_type} className="bg-slate-800/30 border border-slate-700/50 rounded-xl flex flex-col hover:border-slate-600 transition-colors">
                  <div className="p-4 flex flex-col md:flex-row gap-4 justify-between items-center">
                    <div>
                      <h4 className="text-white font-bold mb-1">{task.task_type}</h4>
                      <p className="text-slate-400 text-sm">{task.location_info}</p>
                    </div>
                    <div className="flex items-center gap-4">
                      <div className="text-sm text-slate-500">
                        Submitted: {new Date(task.submission_date).toLocaleString()}
                      </div>
                      <button
                        onClick={() => setExpandedTaskId(expandedTaskId === task.id + task.task_type ? null : task.id + task.task_type)}
                        className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white text-sm font-medium rounded-lg transition-colors flex items-center gap-2"
                      >
                        <Eye size={16} />
                        {expandedTaskId === task.id + task.task_type ? 'Hide' : 'View'}
                      </button>
                    </div>
                  </div>
                  
                  {expandedTaskId === task.id + task.task_type && (
                    <div className="p-4 border-t border-slate-700/50 bg-slate-900/50">
                      {task.task_type === 'Electricity Meter Reading' && (
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                          <div><span className="text-muted block">Previous</span><span className="text-white">{task.previous_reading} kWh</span></div>
                          <div><span className="text-muted block">Current</span><span className="text-primary font-bold">{task.current_reading} kWh</span></div>
                          <div><span className="text-muted block">Consumption</span><span className="text-indigo-300 font-bold">{task.consumption} kWh</span></div>
                          <div><span className="text-muted block">Bill Amount</span><span className="text-success font-bold">${task.bill_amount}</span></div>
                          {task.notes && <div className="col-span-2 md:col-span-4"><span className="text-muted block">Notes</span><span className="text-white">{task.notes}</span></div>}
                          {task.photo_path && (
                            <div className="col-span-2 md:col-span-4 mt-2">
                              <a href={getFullImageUrl(task.photo_path)} target="_blank" rel="noreferrer" className="text-info hover:underline flex items-center gap-1">
                                <Eye size={12} /> View Photo
                              </a>
                            </div>
                          )}
                        </div>
                      )}
                      {task.task_type === 'Generator Reading' && (
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                          <div><span className="text-muted block">Previous</span><span className="text-white">{task.previous_kwh} kWh</span></div>
                          <div><span className="text-muted block">Current</span><span className="text-primary font-bold">{task.current_kwh} kWh</span></div>
                          <div><span className="text-muted block">Produced</span><span className="text-indigo-300 font-bold">+{task.kwh_produced} kWh</span></div>
                          <div><span className="text-muted block">Running Hours</span><span className="text-white font-bold">{task.running_hours} h</span></div>
                          {task.notes && <div className="col-span-2 md:col-span-4"><span className="text-muted block">Notes</span><span className="text-white">{task.notes}</span></div>}
                          {task.photo_meter_path && (
                            <div className="col-span-2 md:col-span-4 mt-2">
                              <a href={getFullImageUrl(task.photo_meter_path)} target="_blank" rel="noreferrer" className="text-info hover:underline flex items-center gap-1">
                                <Eye size={12} /> View Meter Photo
                              </a>
                            </div>
                          )}
                        </div>
                      )}
                      {task.task_type === 'Subscription Meter Reading' && (
                        <div className="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
                          <div><span className="text-muted block">Previous</span><span className="text-white">{task.previous_reading} kWh</span></div>
                          <div><span className="text-muted block">Current</span><span className="text-primary font-bold">{task.current_reading} kWh</span></div>
                          <div><span className="text-muted block">Consumption</span><span className="text-info font-bold">{parseFloat(task.consumption || 0).toFixed(0)} kWh</span></div>
                          {task.notes && <div className="col-span-2 md:col-span-3"><span className="text-muted block">Notes</span><span className="text-white">{task.notes}</span></div>}
                          {task.photo_path && (
                            <div className="col-span-2 md:col-span-3 mt-2">
                              <a href={getFullImageUrl(task.photo_path)} target="_blank" rel="noreferrer" className="text-info hover:underline flex items-center gap-1">
                                <Eye size={12} /> View Photo
                              </a>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReadingsVerification;
