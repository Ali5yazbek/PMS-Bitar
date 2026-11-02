import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Search, AlertOctagon, AlertCircle, AlertTriangle, Info, RefreshCw, Filter } from 'lucide-react';
import api from '../../api/axios';

const SEV_CFG = {
  critical: { icon:'🔴', bg:'bg-red-950/40', border:'border-red-500/20', text:'text-red-400', label:'Critical' },
  warning:  { icon:'🟠', bg:'bg-amber-950/40', border:'border-amber-500/20', text:'text-amber-400', label:'Warning' },
  info:     { icon:'🔵', bg:'bg-blue-950/40', border:'border-blue-500/20', text:'text-blue-400', label:'Info' },
};

const EVENT_TYPES = [
  { value:'failed_login',           label:'Failed Login',            icon:'🔐' },
  { value:'bulk_delete',            label:'Bulk Delete',             icon:'🗑️' },
  { value:'permission_escalation',  label:'Permission Escalation',   icon:'⚠️' },
  { value:'data_export',            label:'Data Export',             icon:'📤' },
  { value:'permission_update',      label:'Permission Update',       icon:'🔒' },
  { value:'temp_permission_granted',label:'Temp Permission Granted', icon:'⏱️' },
  { value:'unlock_action',          label:'Record Unlocked',         icon:'🔓' },
];

export default function AcrSecurityTab() {
  const [search,   setSearch]   = useState('');
  const [type,     setType]     = useState('');
  const [severity, setSeverity] = useState('');
  const [from,     setFrom]     = useState('');
  const [to,       setTo]       = useState('');
  const [applied,  setApplied]  = useState({});

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['acr-security', applied],
    queryFn: async () => {
      const p = new URLSearchParams();
      Object.entries(applied).forEach(([k,v]) => { if (v) p.set(k, v); });
      return (await api.get(`/approvals/security-events?${p}`)).data;
    },
    refetchInterval: 60000,
  });

  const events  = data?.events  || [];
  const summary = data?.summary || [];

  const summaryMap = {};
  summary.forEach(s => { summaryMap[s.severity] = s; });

  return (
    <div className="space-y-5">
      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-3">
        {['critical','warning','info'].map(sev => {
          const s = summaryMap[sev] || {};
          const cfg = SEV_CFG[sev];
          return (
            <div key={sev} className={`rounded-xl p-4 border ${cfg.bg} ${cfg.border} text-center`}>
              <div className={`text-3xl font-black ${cfg.text}`}>{s.count || 0}</div>
              <div className="text-xs text-slate-400 mt-1">{cfg.icon} {cfg.label} Events</div>
              <div className="text-xs text-slate-500 mt-0.5">Last 24h: {s.last_24h || 0}</div>
            </div>
          );
        })}
      </div>

      {/* Filters */}
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-4 space-y-3">
        <div className="flex flex-wrap gap-2 items-center">
          <div className="relative flex-1 min-w-[200px]">
            <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input type="text" placeholder="Search events, users, descriptions…" value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full bg-slate-700/80 border border-slate-600/50 text-white rounded-xl pl-9 pr-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500" />
          </div>
          <select value={type} onChange={e => setType(e.target.value)}
            className="bg-slate-700/80 border border-slate-600/50 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500">
            <option value="">Event Type ▼</option>
            {EVENT_TYPES.map(t => <option key={t.value} value={t.value}>{t.icon} {t.label}</option>)}
          </select>
          <select value={severity} onChange={e => setSeverity(e.target.value)}
            className="bg-slate-700/80 border border-slate-600/50 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500">
            <option value="">Severity ▼</option>
            <option value="critical">🔴 Critical</option>
            <option value="warning">🟠 Warning</option>
            <option value="info">🔵 Info</option>
          </select>
          <input type="date" value={from} onChange={e => setFrom(e.target.value)}
            className="bg-slate-700/80 border border-slate-600/50 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500" />
          <input type="date" value={to} onChange={e => setTo(e.target.value)}
            className="bg-slate-700/80 border border-slate-600/50 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500" />
          <button onClick={() => setApplied({ q:search, type, severity, from, to })}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold">
            <Search size={15} />Search
          </button>
          <button onClick={() => refetch()}
            className="p-2 bg-slate-700/60 hover:bg-slate-700 text-slate-300 rounded-xl transition-colors">
            <RefreshCw size={15} className={isLoading ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {/* Event timeline */}
      <div className="space-y-2">
        {isLoading ? (
          [1,2,3,4].map(i => <div key={i} className="h-14 bg-slate-800/40 rounded-xl animate-pulse border border-slate-700/30" />)
        ) : events.length > 0 ? (
          events.map(evt => {
            const cfg = SEV_CFG[evt.severity] || SEV_CFG.info;
            const typeInfo = EVENT_TYPES.find(t => t.value === evt.event_type);
            return (
              <div key={evt.id} className={`flex items-start gap-3 p-3.5 rounded-xl border ${cfg.bg} ${cfg.border} transition-all hover:scale-[1.005]`}>
                <div className="text-xl shrink-0 mt-0.5">{typeInfo?.icon || '🔔'}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className={`text-xs font-bold ${cfg.text} uppercase`}>{cfg.label}</span>
                    <span className="text-xs text-slate-400">{evt.user_full_name || evt.user_name || 'System'}</span>
                    <span className="text-xs bg-slate-700/60 text-slate-300 px-2 py-0.5 rounded-full capitalize">{evt.event_type?.replace(/_/g,' ')}</span>
                    <span className="text-xs text-slate-600 ml-auto">{new Date(evt.created_at).toLocaleString()}</span>
                  </div>
                  <p className="text-sm text-slate-300 mt-1 leading-snug">{evt.description}</p>
                  {evt.ip_address && <p className="text-xs text-slate-600 mt-0.5">IP: {evt.ip_address}</p>}
                </div>
              </div>
            );
          })
        ) : (
          <div className="flex flex-col items-center py-16 bg-slate-800/40 rounded-2xl border border-slate-700/30">
            <AlertOctagon size={36} className="text-slate-600 mb-3" />
            <p className="text-slate-400">No security events found</p>
          </div>
        )}
      </div>

      {/* Audit Trail Search */}
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
        <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2">
          <Search size={16} className="text-purple-400" />Audit Trail Search
        </h3>
        <AuditSearchPanel />
      </div>
    </div>
  );
}

// ── Audit Trail Search ─────────────────────────────────────────────────────────
function AuditSearchPanel() {
  const [q, setQ]       = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo]     = useState('');
  const [applied, setApplied] = useState(null);

  const { data, isLoading } = useQuery({
    queryKey: ['audit-search', applied],
    queryFn: async () => {
      if (!applied?.q && !applied?.from) return [];
      const p = new URLSearchParams(applied);
      return (await api.get(`/approvals/audit-search?${p}`)).data;
    },
    enabled: !!applied,
  });

  return (
    <div className="space-y-3">
      <div className="flex gap-2 flex-wrap">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input type="text" placeholder="Search by name, action, value, contract ID…" value={q}
            onChange={e => setQ(e.target.value)} onKeyDown={e => e.key === 'Enter' && setApplied({q,from,to})}
            className="w-full bg-slate-700 border border-slate-600 text-white rounded-xl pl-9 pr-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-purple-500" />
        </div>
        <input type="date" value={from} onChange={e => setFrom(e.target.value)}
          className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-purple-500" />
        <input type="date" value={to} onChange={e => setTo(e.target.value)}
          className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-purple-500" />
        <button onClick={() => setApplied({q, from, to})}
          className="flex items-center gap-1.5 px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-xl text-sm font-semibold">
          <Search size={14} />Search Trail
        </button>
      </div>
      {isLoading && <div className="text-xs text-slate-500 animate-pulse py-2">Searching…</div>}
      {data?.length > 0 && (
        <div className="space-y-2 max-h-64 overflow-y-auto">
          {data.map(item => (
            <div key={item.id} className="flex items-start gap-3 p-3 bg-slate-900/60 rounded-xl border border-slate-700/30 text-xs">
              <div className="shrink-0">
                {item.action === 'approved' ? '✅' : item.action === 'rejected' ? '❌' : item.action === 'submitted_fix' ? '📝' : '•'}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex gap-2 flex-wrap items-center">
                  <span className="font-semibold text-white capitalize">{item.action?.replace(/_/g,' ')}</span>
                  <span className="text-slate-400">by {item.user_name || 'System'}</span>
                  <span className="text-slate-600">{new Date(item.created_at).toLocaleString()}</span>
                </div>
                {(item.old_value || item.new_value) && (
                  <div className="flex gap-2 mt-1">
                    {item.old_value && <span className="bg-red-900/40 text-red-300 px-1.5 py-0.5 rounded line-through">{item.old_value}</span>}
                    {item.new_value && <span className="bg-emerald-900/40 text-emerald-300 px-1.5 py-0.5 rounded">{item.new_value}</span>}
                  </div>
                )}
                {item.comment && <p className="text-slate-500 mt-0.5">{item.comment}</p>}
              </div>
            </div>
          ))}
        </div>
      )}
      {applied && !isLoading && data?.length === 0 && (
        <p className="text-slate-500 text-sm text-center py-4">No audit trail records match your search</p>
      )}
    </div>
  );
}
