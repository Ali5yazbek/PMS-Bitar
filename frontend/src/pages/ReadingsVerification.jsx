import React, { useState, useCallback, memo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { 
  CheckCircle, XCircle, Zap, AlertCircle, Building2, 
  ChevronRight, Home, User, Eye, X, History,
  AlertTriangle, Settings, BarChart2, CheckSquare, Maximize2, RotateCw, RefreshCw, Check, Search, Filter
} from 'lucide-react';

// ─── Pure Sub-Components (memoized to prevent re-renders) ────────────────────

const ConfidenceBar = memo(({ score, riskLevel }) => {
  let color = 'bg-danger';
  if (score >= 80) color = 'bg-success';
  else if (score >= 70) color = 'bg-warning';
  else if (score >= 40) color = 'bg-orange-500';
  return (
    <div className="w-full">
      <div className="flex justify-between text-xs mb-1">
        <span className="font-semibold text-slate-300">Confidence Score</span>
        <span className="font-bold">{score}% ({riskLevel?.toUpperCase()})</span>
      </div>
      <div className="h-2 w-full bg-slate-800 rounded-full overflow-hidden">
        <div className={`h-full ${color} transition-all duration-500`} style={{ width: `${score}%` }} />
      </div>
    </div>
  );
});

const AnomalyBadge = memo(({ warning }) => {
  let colorClass = 'text-blue-400 bg-blue-400/10 border-blue-400/20';
  if (warning.level === 'critical') colorClass = 'text-red-400 bg-red-400/10 border-red-400/20';
  else if (warning.level === 'high') colorClass = 'text-orange-400 bg-orange-400/10 border-orange-400/20';
  else if (warning.level === 'medium') colorClass = 'text-yellow-400 bg-yellow-400/10 border-yellow-400/20';
  return (
    <div className={`text-xs px-2 py-1 rounded-md border flex items-start gap-1.5 ${colorClass}`}>
      <AlertTriangle size={14} className="shrink-0 mt-0.5" />
      <div>
        <div className="font-bold">{warning.title}</div>
        <div className="opacity-80 leading-tight mt-0.5">{warning.message}</div>
      </div>
    </div>
  );
});

// ─── Review Side Panel (separate component to avoid re-renders) ──────────────

// Normalize frontend tab name to backend API type
// Frontend uses 'subscriptions' (plural), backend expects 'subscription' (singular)
const apiType = (tab) => tab === 'subscriptions' ? 'subscription' : tab;

const ReviewPanel = memo(({ reviewItem, onClose, activeTab, getFullImageUrl }) => {
  const queryClient = useQueryClient();
  const [imageZoom, setImageZoom] = useState(1);
  const [imageRotation, setImageRotation] = useState(0);
  const [isQuickEdit, setIsQuickEdit] = useState(false);
  const [editValues, setEditValues] = useState({
    current_reading: reviewItem?.current_reading || reviewItem?.current_meter_hours || reviewItem?.meter_hours || reviewItem?.current_kwh || reviewItem?.running_hours || '',
    reading_date: reviewItem?.reading_date || reviewItem?.date || '',
    notes: reviewItem?.notes || ''
  });
  const [isRejectOpen, setIsRejectOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('incorrect_reading');
  const [rejectComment, setRejectComment] = useState('');
  const [rejectSeverity, setRejectSeverity] = useState('medium');

  const { data: reviewDetails, isLoading: loadingDetails } = useQuery({
    queryKey: ['readingAnalysis', activeTab, reviewItem?.id],
    queryFn: async () => (await api.get(`/approval/analyze/${apiType(activeTab)}/${reviewItem?.id}`)).data,
    enabled: !!reviewItem,
    staleTime: 60000,
    retry: 1,
  });

  const { data: timeline } = useQuery({
    queryKey: ['readingTimeline', activeTab, reviewItem?.id],
    queryFn: async () => (await api.get(`/approval/timeline/${apiType(activeTab)}/${reviewItem?.id}`)).data,
    enabled: !!reviewItem,
    staleTime: 60000,
    retry: 1,
  });

  const approveMutation = useMutation({
    mutationFn: (id) => api.post(`/approval/approve/${apiType(activeTab)}/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvalQueue'] });
      onClose();
    },
    onError: (err) => {
      alert(err?.response?.data?.error || 'Approval failed. Please try again.');
    }
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, payload }) => api.post(`/approval/reject/${apiType(activeTab)}/${id}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvalQueue'] });
      setIsRejectOpen(false);
      onClose();
    },
    onError: (err) => {
      alert(err?.response?.data?.error || 'Rejection failed. Please try again.');
    }
  });

  const editMutation = useMutation({
    mutationFn: ({ id, payload }) => api.put(`/approval/quick-edit/${apiType(activeTab)}/${id}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvalQueue'] });
      queryClient.invalidateQueries({ queryKey: ['readingAnalysis'] });
      setIsQuickEdit(false);
    },
    onError: (err) => {
      alert(err?.response?.data?.error || 'Edit failed. Please try again.');
    }
  });

  const d = reviewDetails?.stats || {};
  const warnings = reviewDetails?.warnings || [];
  const photoUrl = getFullImageUrl(reviewItem?.photo_path || reviewItem?.photo_meter_path);

  return (
    <>
      {/* Full-screen split layout */}
      <div className="fixed inset-0 z-50 flex bg-slate-900/95 backdrop-blur-sm p-4 gap-0">
        
        {/* LEFT: Image Viewer */}
        <div className="flex-1 bg-black rounded-l-2xl border border-r-0 border-slate-700 relative overflow-hidden flex flex-col items-center justify-center">
          {/* Image controls */}
          <div className="absolute top-4 left-4 z-10 flex gap-2">
            <button className="bg-slate-800/80 p-2 rounded-lg text-white hover:bg-primary transition-colors" onClick={() => setImageZoom(z => Math.min(z + 0.25, 3))}>
              <Maximize2 size={20}/>
            </button>
            <button className="bg-slate-800/80 p-2 rounded-lg text-white hover:bg-primary transition-colors" onClick={() => setImageRotation(r => r + 90)}>
              <RotateCw size={20}/>
            </button>
            <button className="bg-slate-800/80 p-2 rounded-lg text-white hover:bg-primary transition-colors" onClick={() => { setImageZoom(1); setImageRotation(0); }}>
              <RefreshCw size={20}/>
            </button>
          </div>
          {photoUrl ? (
            <img
              src={photoUrl}
              alt="Meter"
              className="max-h-full max-w-full object-contain"
              style={{ transform: `scale(${imageZoom}) rotate(${imageRotation}deg)`, transition: 'transform 0.2s ease' }}
            />
          ) : (
            <div className="text-slate-500 flex flex-col items-center">
              <AlertCircle size={48} className="mb-4 opacity-50" />
              <p>No meter photo uploaded.</p>
            </div>
          )}
        </div>

        {/* RIGHT: Details & Actions */}
        <div className="w-[480px] bg-slate-800 rounded-r-2xl border border-slate-700 flex flex-col max-h-full overflow-hidden shadow-2xl">

          {/* Header */}
          <div className="p-5 border-b border-slate-700 flex justify-between items-center bg-slate-800/50 shrink-0">
            <div>
              <h2 className="text-xl font-bold text-white">Review Submission</h2>
              <p className="text-sm text-slate-400">
                {reviewItem.building_name} / Apt {reviewItem.apartment_code || reviewItem.generator_name}
              </p>
            </div>
            <button
              onClick={onClose}
              className="p-2 bg-slate-700 hover:bg-danger rounded-xl text-white transition-colors"
            >
              <X size={20}/>
            </button>
          </div>

          {/* Scrollable body */}
          <div className="flex-1 overflow-y-auto p-5 hide-scrollbar flex flex-col gap-5">

            {/* Reading values / Quick Edit */}
            {isQuickEdit ? (
              <div className="bg-slate-900 p-4 rounded-xl border border-primary/50">
                <div className="flex justify-between items-center mb-4">
                  <h3 className="font-bold text-primary flex items-center gap-2"><Settings size={18}/> Quick Edit Mode</h3>
                  <button onClick={() => setIsQuickEdit(false)} className="text-xs text-slate-400 hover:text-white transition-colors">Cancel</button>
                </div>
                <div className="grid gap-4">
                  <div>
                    <label className="text-xs text-slate-400 block mb-1">Current Reading</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg p-2 text-white font-mono focus:outline-none focus:border-primary"
                      value={editValues.current_reading} onChange={e => setEditValues(v => ({...v, current_reading: e.target.value}))} />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400 block mb-1">Reading Date</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg p-2 text-white focus:outline-none focus:border-primary"
                      value={editValues.reading_date} onChange={e => setEditValues(v => ({...v, reading_date: e.target.value}))} />
                  </div>
                  <div>
                    <label className="text-xs text-slate-400 block mb-1">Correction Reason (sent to agent)</label>
                    <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg p-2 text-white focus:outline-none focus:border-primary"
                      placeholder="e.g. Typo: 12500 instead of 12600"
                      value={editValues.edit_reason || ''} onChange={e => setEditValues(v => ({...v, edit_reason: e.target.value}))} />
                  </div>
                  <button
                    className="w-full py-3 bg-primary hover:bg-primary/80 text-white rounded-lg font-bold transition-colors flex justify-center items-center gap-2 disabled:opacity-50"
                    onClick={() => editMutation.mutate({ id: reviewItem.id, payload: editValues })}
                    disabled={editMutation.isPending}
                  >
                    {editMutation.isPending ? 'Saving...' : 'Save Correction'}
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex gap-3 items-center">
                <div className="flex-1 bg-slate-900 p-4 rounded-xl border border-slate-700 text-center">
                  <span className="text-xs text-slate-400 block mb-1">Previous</span>
                  <span className="font-mono text-xl text-slate-300">
                    {reviewItem.previous_reading || reviewItem.previous_meter_hours || reviewItem.previous_kwh || '0.00'}
                  </span>
                </div>
                <ChevronRight className="text-slate-600 shrink-0" />
                <div
                  className="flex-1 bg-slate-900 p-4 rounded-xl border border-primary/50 shadow-[0_0_15px_rgba(99,102,241,0.1)] text-center cursor-pointer hover:bg-slate-800 transition-colors"
                  onClick={() => setIsQuickEdit(true)}
                >
                  <span className="text-xs text-primary block mb-1 flex justify-center items-center gap-1">Current <Settings size={12}/></span>
                  <span className={`font-mono text-2xl font-bold ${reviewItem.corrected_reading ? 'text-green-400' : 'text-white'}`}>
                    {reviewItem.corrected_reading || reviewItem.current_reading || reviewItem.current_meter_hours || reviewItem.meter_hours || reviewItem.current_kwh || reviewItem.running_hours || '0.00'}
                  </span>
                </div>
                <ChevronRight className="text-slate-600 shrink-0" />
                <div className="flex-1 bg-slate-900 p-4 rounded-xl border border-slate-700 text-center">
                  <span className="text-xs text-indigo-400 block mb-1">Consumed</span>
                  <span className="font-mono text-xl text-indigo-300 font-bold">
                    +{reviewItem.consumption || reviewItem.running_hours || reviewItem.kwh_produced || 0}
                  </span>
                </div>
              </div>
            )}

            {/* Anomaly Warnings */}
            {warnings.length > 0 && (
              <div className="bg-slate-900/50 p-4 rounded-xl border border-slate-700">
                <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                  <AlertTriangle size={16} className="text-orange-500" /> Detected Anomalies ({warnings.length})
                </h3>
                <div className="flex flex-col gap-2">
                  {warnings.map((w, i) => <AnomalyBadge key={i} warning={w} />)}
                </div>
              </div>
            )}

            {/* Stats */}
            {!loadingDetails && (d.avg_3m !== undefined || d.building_avg !== undefined) && (
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="bg-slate-900 p-3 rounded-lg border border-slate-700">
                  <div className="text-slate-400 text-xs">{activeTab === 'generator' ? 'Average Run Time' : '3-Month Avg'}</div>
                  <div className="font-mono text-white mt-1">{d.avg_3m ?? '—'} {d.unit || (activeTab === 'generator' ? 'hrs/day' : 'kWh')}</div>
                </div>
                <div className="bg-slate-900 p-3 rounded-lg border border-slate-700">
                  <div className="text-slate-400 text-xs">{activeTab === 'generator' ? 'Factory Burn Rate' : 'Building Avg'}</div>
                  <div className="font-mono text-white mt-1">{d.building_avg ?? '—'} {d.secondary_unit || (activeTab === 'generator' ? 'L/h' : 'kWh')}</div>
                </div>
              </div>
            )}

            {/* Generator Operational Diagnostics */}
            {activeTab === 'generator' && (d.expected_burn !== undefined || d.fuel_remaining !== undefined) && (
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="bg-slate-900 p-3 rounded-lg border border-slate-700">
                  <div className="text-slate-400 text-xs">Expected Fuel Burn</div>
                  <div className="font-mono text-amber-400 mt-1 font-bold">~{d.expected_burn ?? '—'} L</div>
                </div>
                <div className="bg-slate-900 p-3 rounded-lg border border-slate-700">
                  <div className="text-slate-400 text-xs">Fuel Remaining in Tank</div>
                  <div className="font-mono text-green-400 mt-1 font-bold">{d.fuel_remaining ?? '—'} L</div>
                </div>
              </div>
            )}

            {/* History */}
            {reviewDetails?.history?.length > 0 && (
              <div className="border border-slate-700 rounded-xl overflow-hidden bg-slate-900">
                <div className="bg-slate-800 p-2 text-xs font-bold text-white text-center border-b border-slate-700">
                  {activeTab === 'generator' ? 'Previous Operations' : 'Last 5 Readings'}
                </div>
                <table className="w-full text-sm text-left">
                  <tbody>
                    {reviewDetails.history.slice(0, 5).map((h, i) => (
                      <tr key={i} className="border-b border-slate-800 last:border-0">
                        <td className="p-2 text-slate-400">{h.month_label || h.reading_date}</td>
                        <td className="p-2 font-mono text-slate-300">{h.current_reading} {activeTab === 'generator' ? 'hrs' : ''}</td>
                        <td className="p-2 font-mono text-indigo-400 text-right">+{h.consumption} {activeTab === 'generator' ? 'h' : ''}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            {/* Timeline */}
            {timeline?.length > 0 && (
              <div className="border-l-2 border-slate-700 ml-3 pl-4 py-2 space-y-4">
                {timeline.map((evt, i) => (
                  <div key={i} className="relative">
                    <div className="absolute -left-[23px] top-1 w-3 h-3 bg-slate-700 rounded-full border-2 border-slate-900" />
                    <div className="text-xs text-slate-400 mb-0.5">{new Date(evt.created_at).toLocaleString()}</div>
                    <div className="text-sm text-white font-medium capitalize">{evt.action} <span className="text-slate-400 font-normal">by {evt.user_display_name}</span></div>
                    {evt.reason && <div className="text-xs text-slate-400 italic mt-0.5">"{evt.reason}"</div>}
                  </div>
                ))}
              </div>
            )}

          </div>

          {/* Footer Action Buttons */}
          <div className="p-4 border-t border-slate-700 bg-slate-900 flex gap-3 shrink-0">
            <button
              className="flex-1 py-3 bg-slate-700 hover:bg-danger text-white rounded-xl font-bold transition-colors flex justify-center items-center gap-2 disabled:opacity-50"
              onClick={() => setIsRejectOpen(true)}
              disabled={approveMutation.isPending || rejectMutation.isPending}
            >
              <XCircle size={18} /> Reject
            </button>
            <button
              className="flex-[2] py-3 bg-success hover:bg-success/80 text-white rounded-xl font-bold transition-colors flex justify-center items-center gap-2 shadow-[0_0_20px_rgba(34,197,94,0.3)] disabled:opacity-50 disabled:cursor-not-allowed"
              onClick={() => approveMutation.mutate(reviewItem.id)}
              disabled={approveMutation.isPending || rejectMutation.isPending}
            >
              {approveMutation.isPending
                ? <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Approving...</>
                : <><CheckCircle size={18} /> Approve &amp; Generate</>
              }
            </button>
          </div>
        </div>
      </div>

      {/* Reject Modal */}
      {isRejectOpen && (
        <div className="fixed inset-0 z-[60] bg-black/80 flex items-center justify-center p-4" onClick={e => e.target === e.currentTarget && setIsRejectOpen(false)}>
          <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
            <div className="p-5 border-b border-slate-700 flex justify-between items-center bg-slate-900">
              <h3 className="font-bold text-white text-lg">Reject Submission</h3>
              <button onClick={() => setIsRejectOpen(false)} className="text-slate-400 hover:text-white transition-colors p-1"><X size={20}/></button>
            </div>
            <div className="p-6 flex flex-col gap-5">
              <div>
                <label className="text-sm font-bold text-slate-300 block mb-2">Rejection Reason</label>
                <select className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white focus:outline-none focus:border-primary" value={rejectReason} onChange={e => setRejectReason(e.target.value)}>
                  <option value="image_blurry">Image is too blurry</option>
                  <option value="missing_image">Missing meter photo</option>
                  <option value="incorrect_reading">Incorrect reading value</option>
                  <option value="wrong_meter">Wrong meter photographed</option>
                  <option value="wrong_apartment">Wrong apartment</option>
                  <option value="fraud_suspected">Fraud suspected</option>
                  <option value="other">Other</option>
                </select>
              </div>
              <div>
                <label className="text-sm font-bold text-slate-300 block mb-2">Severity (Risk Record)</label>
                <div className="flex bg-slate-900 rounded-lg p-1 border border-slate-700">
                  {['minor', 'medium', 'major', 'critical'].map(s => (
                    <button key={s} onClick={() => setRejectSeverity(s)}
                      className={`flex-1 text-xs py-2 rounded-md capitalize font-bold transition-colors ${rejectSeverity === s ? 'bg-slate-700 text-white' : 'text-slate-400 hover:text-white'}`}>
                      {s}
                    </button>
                  ))}
                </div>
              </div>
              <div>
                <label className="text-sm font-bold text-slate-300 block mb-2">Additional Comment (sent to agent)</label>
                <textarea className="w-full bg-slate-900 border border-slate-700 rounded-lg p-3 text-white min-h-[100px] resize-none focus:outline-none focus:border-primary"
                  placeholder="Explain what the agent needs to do..."
                  value={rejectComment} onChange={e => setRejectComment(e.target.value)} />
              </div>
              <button
                className="w-full py-3 bg-danger hover:bg-red-600 text-white rounded-xl font-bold transition-colors mt-2 flex justify-center items-center gap-2 disabled:opacity-50"
                onClick={() => rejectMutation.mutate({ id: reviewItem.id, payload: { reason_code: rejectReason, severity: rejectSeverity, comment: rejectComment } })}
                disabled={rejectMutation.isPending}
              >
                {rejectMutation.isPending
                  ? <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Rejecting...</>
                  : 'Confirm Rejection'
                }
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
});

// ─── Queue Card (memoized) ───────────────────────────────────────────────────

const QueueCard = memo(({ item, isSelected, onSelect, onOpen }) => {
  const score = item.confidence_score ?? 100;
  const flags = Array.isArray(item.anomaly_flags) ? item.anomaly_flags : [];
  return (
    <div
      className={`bg-slate-800 rounded-xl border-2 transition-all cursor-pointer hover:border-slate-500 ${isSelected ? 'border-primary' : 'border-slate-700/50'}`}
      onClick={(e) => { if (e.target.type !== 'checkbox') onOpen(item); }}
    >
      <div className="p-4 border-b border-slate-700/50 flex justify-between items-start">
        <div className="flex gap-3">
          <input type="checkbox" checked={isSelected} onChange={() => onSelect(item.id)}
            className="mt-1 w-5 h-5 rounded bg-slate-900 border-slate-600 text-primary cursor-pointer"
            onClick={e => e.stopPropagation()} />
          <div>
            <h3 className="font-bold text-white">{item.building_name} - Apt {item.apartment_code || item.generator_name}</h3>
            <div className="text-sm text-slate-400 mt-0.5">
              Submitted by {item.submitter_name} on {new Date(item.submitted_at || item.created_at).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}
            </div>
          </div>
        </div>
        <div className={`px-2 py-1 rounded text-xs font-bold shrink-0 ${
          item.risk_level === 'critical' ? 'bg-red-500/20 text-red-400' :
          item.risk_level === 'high' ? 'bg-orange-500/20 text-orange-400' :
          item.risk_level === 'medium' ? 'bg-yellow-500/20 text-yellow-400' : 'bg-green-500/20 text-green-400'
        }`}>
          {item.risk_level?.toUpperCase() || 'SAFE'}
        </div>
      </div>
      <div className="p-4 flex flex-col gap-3">
        <div className="flex justify-between items-center text-sm">
          <span className="text-slate-400">Reading</span>
          <span className="font-mono text-lg text-white font-bold">
            {item.current_reading || item.current_meter_hours || item.meter_hours || item.current_kwh || item.running_hours || '0.00'}
          </span>
        </div>
        {item.consumption !== undefined && (
          <div className="flex justify-between items-center text-sm">
            <span className="text-slate-400">Consumption</span>
            <span className="font-mono text-lg text-indigo-300 font-bold">+{item.consumption}</span>
          </div>
        )}
        <ConfidenceBar score={score} riskLevel={item.risk_level || 'low'} />
        {flags.length > 0 && (
          <div className="flex gap-1 flex-wrap mt-1">
            {flags.map((f, i) => (
              <span key={i} title={f.message} className="text-xs px-1.5 py-0.5 bg-slate-700 text-slate-300 rounded border border-slate-600">{f.title}</span>
            ))}
          </div>
        )}
      </div>
    </div>
  );
});

// ─── Main Component ──────────────────────────────────────────────────────────

const ReadingsVerification = () => {
  const queryClient = useQueryClient();

  const [activeTab, setActiveTab] = useState('electricity');
  const [selectedIds, setSelectedIds] = useState([]);
  const [reviewItem, setReviewItem] = useState(null);
  
  const [searchQuery, setSearchQuery] = useState('');
  const [riskFilter, setRiskFilter] = useState('all');
  const [dateFilter, setDateFilter] = useState('');
  const [viewMode, setViewMode] = useState('pending');

  // ── Queries (no aggressive refetch while panel is open) ──────────────────
  const { data: queue = [], isLoading: loadingQueue } = useQuery({
    queryKey: ['approvalQueue', activeTab, viewMode],
    queryFn: async () => {
      if (!['electricity', 'generator', 'subscriptions'].includes(activeTab)) return [];
      const res = await api.get(`/approval/queue/${apiType(activeTab)}?status=${viewMode}`);
      return res.data;
    },
    refetchInterval: reviewItem ? false : 15000,
    staleTime: 5000,
  });

  const { data: adminKpi } = useQuery({
    queryKey: ['adminKpi'],
    queryFn: async () => (await api.get('/approval/admin-kpi')).data,
    refetchInterval: 15000, // Frequent refetch for live notification counts
    staleTime: 5000,
  });

  const { data: leaderboard } = useQuery({
    queryKey: ['agentLeaderboard'],
    queryFn: async () => (await api.get('/approval/agent-leaderboard')).data,
    enabled: activeTab === 'admin-kpi',
    staleTime: 60000,
  });

  const { data: healthScores } = useQuery({
    queryKey: ['buildingHealth'],
    queryFn: async () => (await api.get('/approval/building-health')).data,
    enabled: activeTab === 'admin-kpi',
    staleTime: 60000,
  });

  const { data: settings } = useQuery({
    queryKey: ['approvalSettings'],
    queryFn: async () => (await api.get('/approval/settings')).data,
    enabled: activeTab === 'settings',
    staleTime: 60000,
  });

  // ── Bulk Approve Mutation ────────────────────────────────────────────────
  const bulkApproveMutation = useMutation({
    mutationFn: (payload) => api.post(`/approval/bulk-approve/${apiType(activeTab)}`, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvalQueue'] });
      setSelectedIds([]);
    },
    onError: (err) => alert(err?.response?.data?.error || 'Bulk approve failed.')
  });

  // ── Stable Handlers (useCallback prevents child re-renders) ─────────────
  const toggleSelect = useCallback((id) => {
    setSelectedIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  }, []);

  const toggleSelectAll = useCallback(() => {
    setSelectedIds(prev => prev.length === queue.length ? [] : queue.map(x => x.id));
  }, [queue]);

  const openReview = useCallback((item) => {
    setReviewItem(item);
  }, []);

  const closeReview = useCallback(() => {
    setReviewItem(null);
  }, []);

  const handleBulkApprove = useCallback((safeOnly) => {
    if (!safeOnly && !window.confirm('You are about to approve readings that may have high risk anomalies. Proceed?')) return;
    bulkApproveMutation.mutate({ ids: selectedIds, skip_high_risk: safeOnly });
  }, [selectedIds, bulkApproveMutation]);

  const getFullImageUrl = useCallback((path) => {
    if (!path) return null;
    return api.defaults.baseURL.replace(/\/backend\/api$/, '').replace(/\/api$/, '') + '/' + path;
  }, []);

  // ── Render Queue ─────────────────────────────────────────────────────────
  const renderQueue = () => {
    if (loadingQueue) return (
      <div className="flex items-center justify-center p-16">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
          <p className="text-slate-400">Loading queue...</p>
        </div>
      </div>
    );
    const renderEmptyState = () => {
      const getEmptyMessage = () => {
        if (viewMode === 'approved') return { title: 'No approved readings.', sub: 'You haven\'t approved any readings yet.' };
        if (viewMode === 'rejected') return { title: 'No rejected readings.', sub: 'You haven\'t rejected any readings yet.' };
        return { title: 'Queue is empty.', sub: 'All caught up! 🎉' };
      };
      const msg = getEmptyMessage();
      
      return (
        <div className="p-16 text-center">
          <CheckCircle size={48} className="mx-auto text-success/40 mb-4" />
          <p className="text-slate-300 text-lg font-semibold">{msg.title}</p>
          <p className="text-slate-500 mt-1">{msg.sub}</p>
        </div>
      );
    };

    const filteredQueue = queue.filter(item => {
      const matchSearch = !searchQuery || (
        (item.building_name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
        (item.apartment_code || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
        (item.generator_name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
        (item.submitter_name || '').toLowerCase().includes(searchQuery.toLowerCase())
      );
      const risk = item.risk_level || 'low';
      const matchRisk = riskFilter === 'all' || risk === riskFilter;
      const itemDate = (item.submitted_at || item.created_at || '').split('T')[0].split(' ')[0];
      const matchDate = !dateFilter || itemDate === dateFilter;
      return matchSearch && matchRisk && matchDate;
    });

    return (
      <>
        {/* Search & Filter Toolbar */}
        <div className="flex flex-col xl:flex-row gap-4 mb-6 xl:items-center">
          
          {/* Status Toggle */}
          <div className="flex bg-slate-800 p-1 rounded-lg border border-slate-700 shrink-0">
            <button 
              className={`px-4 py-1.5 rounded-md text-sm font-bold transition-colors ${viewMode === 'pending' ? 'bg-indigo-600 text-white' : 'text-slate-400 hover:text-white'}`}
              onClick={() => { setViewMode('pending'); setSelectedIds([]); }}
            >
              Pending
            </button>
            <button 
              className={`px-4 py-1.5 rounded-md text-sm font-bold transition-colors ${viewMode === 'approved' ? 'bg-success text-white' : 'text-slate-400 hover:text-white'}`}
              onClick={() => { setViewMode('approved'); setSelectedIds([]); }}
            >
              Approved
            </button>
            <button 
              className={`px-4 py-1.5 rounded-md text-sm font-bold transition-colors ${viewMode === 'rejected' ? 'bg-danger text-white' : 'text-slate-400 hover:text-white'}`}
              onClick={() => { setViewMode('rejected'); setSelectedIds([]); }}
            >
              Rejected
            </button>
          </div>

          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text" 
              placeholder="Search building, apartment, agent..." 
              className="w-full bg-slate-800 border border-slate-700 rounded-lg pl-10 pr-4 py-2 text-white focus:outline-none focus:border-primary transition-colors"
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
            />
          </div>

          <div className="relative shrink-0">
            <input 
              type="date"
              className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-slate-300 focus:outline-none focus:border-primary transition-colors"
              value={dateFilter}
              onChange={e => setDateFilter(e.target.value)}
            />
          </div>
          <div className="flex items-center gap-2 overflow-x-auto hide-scrollbar pb-2 xl:pb-0">
            <Filter size={18} className="text-slate-400 shrink-0" />
            {['all', 'low', 'medium', 'high', 'critical'].map(risk => (
              <button 
                key={risk}
                onClick={() => setRiskFilter(risk)}
                className={`px-3 py-1.5 rounded-lg text-sm font-bold capitalize whitespace-nowrap transition-colors ${
                  riskFilter === risk 
                    ? (risk === 'critical' ? 'bg-red-500/20 text-red-400 border border-red-500/50' : 
                       risk === 'high' ? 'bg-orange-500/20 text-orange-400 border border-orange-500/50' : 
                       risk === 'medium' ? 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/50' : 
                       risk === 'low' ? 'bg-green-500/20 text-green-400 border border-green-500/50' : 
                       'bg-primary/20 text-primary border border-primary/50')
                    : 'bg-slate-800 text-slate-400 border border-slate-700 hover:bg-slate-700'
                }`}
              >
                {risk}
              </button>
            ))}
          </div>
        </div>

        {filteredQueue.length === 0 ? (
          <div className="p-16 text-center bg-slate-800/30 rounded-xl border border-slate-700/50 border-dashed">
            <p className="text-slate-400 text-lg">No readings match your search/filter.</p>
            <button onClick={() => { setSearchQuery(''); setRiskFilter('all'); }} className="text-primary mt-2 hover:underline">Clear Filters</button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
            {filteredQueue.map(item => (
              <QueueCard
                key={item.id}
                item={item}
                isSelected={selectedIds.includes(item.id)}
                onSelect={toggleSelect}
                onOpen={openReview}
              />
            ))}
          </div>
        )}
      </>
    );
  };

  // ── Render KPI Dashboard ─────────────────────────────────────────────────
  const renderAdminKPI = () => {
    if (!adminKpi) return <div className="p-8 text-center text-slate-400">Loading Dashboards...</div>;
    return (
      <div className="flex flex-col gap-6">
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-6 gap-4">
          {[
            { label: 'Pending Approvals', value: adminKpi.pending_approvals, color: 'text-white' },
            { label: '🔴 High Risk', value: adminKpi.high_risk, color: 'text-orange-400' },
            { label: '✅ Bulk-Safe', value: adminKpi.bulk_safe, color: 'text-green-400' },
            { label: 'Rejection Rate', value: adminKpi.rejection_rate, color: 'text-slate-300' },
            { label: 'Revenue Waiting', value: `$${adminKpi.revenue_waiting?.toLocaleString() ?? 0}`, color: 'text-indigo-400' },
            { label: 'Over 48h Pending', value: adminKpi.pending_over_48h, color: 'text-red-400', alert: true },
          ].map((kpi, i) => (
            <div key={i} className={`bg-slate-800 p-5 rounded-xl border ${kpi.alert ? 'border-danger/30' : 'border-slate-700'} relative overflow-hidden`}>
              {kpi.alert && <div className="absolute top-0 right-0 bg-danger text-white text-[10px] font-bold px-2 py-0.5 rounded-bl-lg">ALERT</div>}
              <div className="text-sm text-slate-400">{kpi.label}</div>
              <div className={`text-3xl font-bold mt-2 ${kpi.color}`}>{kpi.value}</div>
            </div>
          ))}
        </div>

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
          {/* Leaderboard */}
          <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
            <div className="p-4 border-b border-slate-700 bg-slate-900">
              <h3 className="font-bold text-white flex items-center gap-2"><User size={18} className="text-primary"/> Agent Performance</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-800/50 text-slate-400">
                  <tr><th className="p-3">Rank</th><th className="p-3">Agent</th><th className="p-3 text-right">Score</th><th className="p-3 text-right">Approved</th><th className="p-3 text-right">Rejected</th></tr>
                </thead>
                <tbody className="divide-y divide-slate-700">
                  {leaderboard?.map((agent, i) => (
                    <tr key={i} className="hover:bg-slate-700/50">
                      <td className="p-3 font-bold text-white">{i+1}</td>
                      <td className="p-3 text-slate-200">{agent.agent_name}</td>
                      <td className="p-3 text-right font-mono text-green-400">{agent.accuracy_score}%</td>
                      <td className="p-3 text-right">{agent.approved_count}</td>
                      <td className="p-3 text-right text-red-400">{agent.rejected_count}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
          {/* Building Health */}
          <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
            <div className="p-4 border-b border-slate-700 bg-slate-900">
              <h3 className="font-bold text-white flex items-center gap-2"><Building2 size={18} className="text-primary"/> Building Health</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="bg-slate-800/50 text-slate-400">
                  <tr><th className="p-3">Building</th><th className="p-3">Grade</th><th className="p-3">Score</th><th className="p-3 text-right">Missing</th></tr>
                </thead>
                <tbody className="divide-y divide-slate-700">
                  {healthScores?.map((b, i) => {
                    let details = {};
                    try { details = JSON.parse(b.details || '{}'); } catch {}
                    return (
                      <tr key={i} className="hover:bg-slate-700/50">
                        <td className="p-3 font-medium text-white">{b.building_name}</td>
                        <td className="p-3">
                          <span className={`px-2 py-1 rounded text-xs font-bold ${
                            b.grade === 'Excellent' ? 'bg-green-500/20 text-green-400' :
                            b.grade === 'Good' ? 'bg-blue-500/20 text-blue-400' :
                            b.grade === 'Critical' ? 'bg-red-500/20 text-red-400' : 'bg-yellow-500/20 text-yellow-400'
                          }`}>{b.grade}</span>
                        </td>
                        <td className="p-3 font-mono text-slate-300">{b.score}</td>
                        <td className="p-3 text-right text-slate-400">{details.missing_pct || 0}%</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>

        {/* Activity Feed */}
        <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden">
          <div className="p-4 border-b border-slate-700 bg-slate-900">
            <h3 className="font-bold text-white flex items-center gap-2"><History size={18} className="text-primary"/> Recent Admin Activity</h3>
          </div>
          <div className="p-4 flex flex-col gap-3">
            {adminKpi.recent_activity?.map((act, i) => (
              <div key={i} className="flex gap-4 items-start text-sm border-b border-slate-700/50 pb-3 last:border-0 last:pb-0">
                <div className="text-slate-400 w-24 shrink-0 mt-0.5">{new Date(act.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</div>
                <div>
                  <span className="font-bold text-white">{act.user_display_name}</span>{' '}
                  <span className="text-slate-300">{act.action}</span>{' '}
                  <span className="text-primary">[{act.module} - {act.record_id}]</span>
                  {act.reason && <div className="text-xs text-slate-400 mt-1 italic">"{act.reason}"</div>}
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  // ── Render Settings ──────────────────────────────────────────────────────
  const renderSettings = () => (
    <div className="bg-slate-800 rounded-xl border border-slate-700 overflow-hidden max-w-4xl mx-auto">
      <div className="p-5 border-b border-slate-700 bg-slate-900">
        <h3 className="font-bold text-white text-lg flex items-center gap-2"><Settings className="text-primary"/> Approval Engine Thresholds</h3>
        <p className="text-sm text-slate-400 mt-1">Changes apply instantly to all new analysis requests.</p>
      </div>
      <table className="w-full text-left text-sm">
        <tbody className="divide-y divide-slate-700">
          {settings?.map((s, i) => (
            <tr key={i} className="hover:bg-slate-700/30">
              <td className="p-5">
                <div className="font-bold text-white text-base">{s.label}</div>
                <div className="text-slate-400 mt-1">{s.description}</div>
              </td>
              <td className="p-5 w-48 align-top">
                <input
                  type={s.data_type === 'boolean' ? 'text' : 'number'}
                  defaultValue={s.setting_value}
                  className="w-full bg-slate-900 border border-slate-600 rounded-lg p-2.5 text-white font-mono focus:outline-none focus:border-primary"
                  onBlur={e => {
                    if (e.target.value !== s.setting_value) {
                      api.put(`/approval/settings/${s.setting_key}`, { value: e.target.value })
                        .then(() => queryClient.invalidateQueries({ queryKey: ['approvalSettings'] }));
                    }
                  }}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  // ── Main Render ──────────────────────────────────────────────────────────
  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      <div className="flex-1 overflow-y-auto p-4 md:p-8 hide-scrollbar">

        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-1">Enterprise Verification</h1>
          <p className="text-slate-400">Smart anomaly detection and bulk approval workflows.</p>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mb-6 border-b border-slate-700 flex-wrap">
          {['electricity', 'generator', 'subscriptions'].map(tab => {
            const pendingCount = adminKpi?.[`${tab === 'subscriptions' ? 'subscription' : tab}_pending`] || 0;
            return (
              <button key={tab}
                onClick={() => { setActiveTab(tab); setSelectedIds([]); setSearchQuery(''); setRiskFilter('all'); setViewMode('pending'); setDateFilter(''); }}
                className={`px-4 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px capitalize ${activeTab === tab ? 'text-primary border-primary' : 'text-slate-400 border-transparent hover:text-white'}`}>
                <CheckSquare size={16} /> {tab} 
                {pendingCount > 0 && (
                  <span className="bg-danger text-white rounded-full px-2 py-0.5 text-xs font-bold shadow-sm border border-danger/50 shadow-danger/20">
                    {pendingCount}
                  </span>
                )}
              </button>
            );
          })}
          <div className="w-px h-8 bg-slate-700 self-center mx-2" />
          <button onClick={() => setActiveTab('admin-kpi')}
            className={`px-4 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'admin-kpi' ? 'text-indigo-400 border-indigo-400' : 'text-slate-400 border-transparent hover:text-white'}`}>
            <BarChart2 size={16} /> KPI Dashboard
          </button>
          <button onClick={() => setActiveTab('settings')}
            className={`px-4 py-3 font-medium transition-colors flex items-center gap-2 border-b-2 -mb-px ${activeTab === 'settings' ? 'text-slate-300 border-slate-300' : 'text-slate-400 border-transparent hover:text-white'}`}>
            <Settings size={16} /> Settings
          </button>
        </div>

        {/* Bulk Toolbar */}
        {selectedIds.length > 0 && ['electricity', 'generator', 'subscriptions'].includes(activeTab) && (
          <div className="sticky top-0 z-40 bg-indigo-900/90 backdrop-blur border border-indigo-500 rounded-xl p-3 mb-6 flex justify-between items-center shadow-[0_10px_30px_rgba(99,102,241,0.2)]">
            <div className="flex items-center gap-4 text-white">
              <div className="font-bold bg-indigo-800 px-3 py-1 rounded-lg">{selectedIds.length} Selected</div>
              <button className="text-sm text-indigo-300 hover:text-white underline" onClick={toggleSelectAll}>Select All</button>
            </div>
            <div className="flex gap-2">
              <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg text-sm font-bold border border-slate-600 transition-colors" onClick={() => setSelectedIds([])}>Cancel</button>
              <button className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-sm font-bold flex items-center gap-2 transition-colors disabled:opacity-50"
                onClick={() => handleBulkApprove(true)} disabled={bulkApproveMutation.isPending}>
                <Check size={16}/> Approve Safe Only
              </button>
              <button className="px-4 py-2 bg-success hover:bg-success/80 text-white rounded-lg text-sm font-bold flex items-center gap-2 transition-colors shadow-[0_0_15px_rgba(34,197,94,0.4)] disabled:opacity-50"
                onClick={() => handleBulkApprove(false)} disabled={bulkApproveMutation.isPending}>
                <CheckCircle size={16}/> Force Approve All
              </button>
            </div>
          </div>
        )}

        {/* Content */}
        {['electricity', 'generator', 'subscriptions'].includes(activeTab) && renderQueue()}
        {activeTab === 'admin-kpi' && renderAdminKPI()}
        {activeTab === 'settings' && renderSettings()}
      </div>

      {/* Review Panel (only mounted when item selected) */}
      {reviewItem && (
        <ReviewPanel
          key={reviewItem.id}
          reviewItem={reviewItem}
          onClose={closeReview}
          activeTab={activeTab}
          getFullImageUrl={getFullImageUrl}
        />
      )}
    </div>
  );
};

export default ReadingsVerification;
