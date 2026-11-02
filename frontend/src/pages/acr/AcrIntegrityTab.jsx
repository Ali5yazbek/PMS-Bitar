import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { RefreshCw, Database, AlertCircle, CheckCircle2, Eye, XCircle, AlertTriangle, DollarSign } from 'lucide-react';
import api from '../../api/axios';

const ISSUE_TYPE_LABELS = {
  duplicate_national_id:   '🪪 Duplicate National ID',
  duplicate_phone:         '📱 Duplicate Phone',
  duplicate_passport:      '🛂 Duplicate Passport',
  duplicate_active_contract: '📄 Duplicate Active Contract',
  orphaned_contract:       '🔗 Orphaned Contract',
};

const FIN_TYPE_LABELS = {
  negative_amount:         '➖ Negative Amount',
  overpayment:             '💸 Paid > Invoice',
  missing_rent_profile:    '❓ Missing Rent Profile',
  duplicate_payment:       '🔄 Duplicate Payment',
};

const SeverityChip = ({ s }) => {
  const c = { critical:'bg-red-500/20 text-red-400', warning:'bg-amber-500/20 text-amber-400', info:'bg-blue-500/20 text-blue-400' };
  return <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold capitalize ${c[s]||c.info}`}>{s}</span>;
};

const IssueRow = ({ issue, onResolve, onIgnore, isFinancial }) => {
  const sev = issue.severity || 'warning';
  const border = { critical:'border-red-500/20', warning:'border-amber-500/20', info:'border-blue-500/20' };
  const label = isFinancial ? (FIN_TYPE_LABELS[issue.issue_type] || issue.issue_type) : (ISSUE_TYPE_LABELS[issue.issue_type] || issue.issue_type);

  return (
    <div className={`flex items-start gap-3 p-3.5 rounded-xl border ${border[sev]} bg-slate-800/40 hover:bg-slate-700/30 transition-colors`}>
      <SeverityChip s={sev} />
      <div className="flex-1 min-w-0">
        <div className="text-sm font-semibold text-slate-200">{label}</div>
        <p className="text-xs text-slate-400 mt-0.5 leading-relaxed">{issue.description}</p>
        {isFinancial && (issue.expected_value !== null || issue.actual_value !== null) && (
          <div className="flex gap-3 mt-1.5 text-xs">
            {issue.expected_value !== null && <span className="bg-emerald-900/30 text-emerald-300 px-2 py-0.5 rounded">Expected: {issue.expected_value}</span>}
            {issue.actual_value   !== null && <span className="bg-red-900/30 text-red-300 px-2 py-0.5 rounded">Actual: {issue.actual_value}</span>}
          </div>
        )}
        {!isFinancial && issue.duplicate_id && (
          <div className="text-xs text-slate-500 mt-1">
            Duplicate pair: Record #{issue.record_id} ↔ #{issue.duplicate_id}
          </div>
        )}
      </div>
      <div className="flex gap-1.5 shrink-0">
        {onResolve && (
          <button onClick={() => onResolve(issue.id)}
            className="flex items-center gap-1 px-2.5 py-1 bg-emerald-600/70 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold transition-all">
            <CheckCircle2 size={12} />Resolve
          </button>
        )}
        {onIgnore && (
          <button onClick={() => onIgnore(issue.id)}
            className="flex items-center gap-1 px-2.5 py-1 bg-slate-600/70 hover:bg-slate-500 text-slate-300 rounded-lg text-xs font-semibold transition-all">
            <XCircle size={12} />Ignore
          </button>
        )}
      </div>
    </div>
  );
};

export default function AcrIntegrityTab({ isAdmin }) {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState('integrity');
  const [running, setRunning] = useState(false);
  const [lastResult, setLastResult] = useState(null);

  const { data: dash }        = useQuery({ queryKey:['integrity-dash'],    queryFn: async () => (await api.get('/integrity/dashboard')).data });
  const { data: issues }      = useQuery({ queryKey:['integrity-issues'],  queryFn: async () => (await api.get('/integrity/issues?status=open')).data });
  const { data: financial }   = useQuery({ queryKey:['integrity-fin'],     queryFn: async () => (await api.get('/integrity/financial?status=open')).data });

  const resolveMut  = useMutation({ mutationFn: (id) => api.put(`/integrity/issues/${id}/resolve`),  onSuccess: () => { queryClient.invalidateQueries(['integrity-issues']); queryClient.invalidateQueries(['integrity-dash']); } });
  const ignoreMut   = useMutation({ mutationFn: (id) => api.put(`/integrity/issues/${id}/ignore`),   onSuccess: () => queryClient.invalidateQueries(['integrity-issues']) });
  const resolveFinMut = useMutation({ mutationFn: (id) => api.put(`/integrity/financial/${id}/resolve`), onSuccess: () => { queryClient.invalidateQueries(['integrity-fin']); queryClient.invalidateQueries(['integrity-dash']); } });

  const handleRunScan = async () => {
    setRunning(true);
    try {
      const res = await api.post('/integrity/run');
      setLastResult(res.data?.result);
      queryClient.invalidateQueries(['integrity-issues']);
      queryClient.invalidateQueries(['integrity-fin']);
      queryClient.invalidateQueries(['integrity-dash']);
    } catch(e) {}
    setRunning(false);
  };

  const totals = dash?.totals || {};

  return (
    <div className="space-y-5">
      {/* Summary + scan button */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {[
          { label:'Integrity Issues', value: totals.integrity_open,    icon:Database,    color:'text-amber-400 bg-amber-950/60 border-amber-500/20' },
          { label:'🔴 Critical',      value: totals.integrity_critical, icon:AlertCircle, color:'text-red-400 bg-red-950/60 border-red-500/20' },
          { label:'Financial Issues', value: totals.financial_open,    icon:DollarSign,  color:'text-purple-400 bg-purple-950/60 border-purple-500/20' },
          { label:'Critical Financial', value: totals.financial_critical, icon:AlertCircle, color:'text-red-400 bg-red-950/60 border-red-500/20' },
        ].map((c, i) => (
          <div key={i} className={`relative overflow-hidden rounded-xl p-4 border flex items-center gap-3 ${c.color}`}>
            <c.icon size={20} className="shrink-0" />
            <div>
              <div className="text-2xl font-black">{c.value ?? '—'}</div>
              <div className="text-[10px] font-medium opacity-60 leading-tight">{c.label}</div>
            </div>
          </div>
        ))}
      </div>

      {isAdmin && (
        <div className="flex items-center gap-3">
          <button onClick={handleRunScan} disabled={running}
            className="flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg shadow-indigo-500/20 disabled:opacity-50">
            <RefreshCw size={16} className={running ? 'animate-spin' : ''} />
            {running ? 'Scanning database…' : '🔍 Run Integrity Scan'}
          </button>
          {lastResult && (
            <div className="text-sm text-slate-300 bg-slate-800/60 border border-slate-700/50 rounded-xl px-4 py-2">
              Found: <span className="text-red-400 font-bold">{lastResult.critical} critical</span>, <span className="text-amber-400 font-bold">{lastResult.warning} warning</span>
            </div>
          )}
        </div>
      )}

      {/* Sub-tabs */}
      <div className="flex gap-1 bg-slate-900/40 border border-slate-700/40 rounded-xl p-1.5">
        {[
          { id:'integrity', label:`🔍 Duplicates & Orphans (${issues?.length || 0})` },
          { id:'financial', label:`💰 Financial Audit (${financial?.length || 0})` },
        ].map(t => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={`flex-1 px-4 py-2 rounded-lg text-sm font-semibold transition-all ${tab===t.id?'bg-slate-700 text-white':'text-slate-400 hover:text-white'}`}>
            {t.label}
          </button>
        ))}
      </div>

      {/* Issue lists */}
      <div className="space-y-2">
        {tab === 'integrity' && (
          issues?.length ? issues.map(issue => (
            <IssueRow key={issue.id} issue={issue}
              onResolve={isAdmin ? resolveMut.mutate : null}
              onIgnore={isAdmin ? ignoreMut.mutate : null}
            />
          )) : (
            <div className="flex flex-col items-center py-12 bg-slate-800/40 rounded-2xl border border-slate-700/30">
              <CheckCircle2 size={36} className="text-emerald-500 mb-3" />
              <p className="text-slate-300 font-semibold">No Integrity Issues Found</p>
              <p className="text-slate-500 text-sm mt-1">Run a scan to check for duplicates and orphaned records</p>
            </div>
          )
        )}
        {tab === 'financial' && (
          financial?.length ? financial.map(issue => (
            <IssueRow key={issue.id} issue={issue} isFinancial
              onResolve={isAdmin ? resolveFinMut.mutate : null}
            />
          )) : (
            <div className="flex flex-col items-center py-12 bg-slate-800/40 rounded-2xl border border-slate-700/30">
              <CheckCircle2 size={36} className="text-emerald-500 mb-3" />
              <p className="text-slate-300 font-semibold">No Financial Anomalies Found</p>
              <p className="text-slate-500 text-sm mt-1">Negative amounts, overpayments, and missing records will appear here</p>
            </div>
          )
        )}
      </div>
    </div>
  );
}
