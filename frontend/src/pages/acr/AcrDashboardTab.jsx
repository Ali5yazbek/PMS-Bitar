import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  RefreshCw, AlertCircle, AlertTriangle, CheckCircle2, Lock, Unlock,
  Clock, TrendingUp, Users, Activity, Zap, Target, BarChart2
} from 'lucide-react';
import api from '../../api/axios';
import ActionControlReportDetail from '../ActionControlReportDetail';

// ── Mini stat ─────────────────────────────────────────────────────────────────
const MiniStat = ({ label, value, icon: Icon, color, pulse }) => (
  <div className={`relative overflow-hidden rounded-xl p-4 border flex items-center gap-3 shadow-md ${color}`}>
    <Icon size={22} className="opacity-90 shrink-0" />
    <div>
      <div className={`text-2xl font-black tabular-nums ${pulse ? 'animate-pulse' : ''}`}>{value ?? '—'}</div>
      <div className="text-[11px] font-medium opacity-65 leading-tight">{label}</div>
    </div>
    <div className="absolute right-2 top-2 opacity-5"><Icon size={52} /></div>
  </div>
);

// ── Health ring ───────────────────────────────────────────────────────────────
const HealthRing = ({ score, label, size = 80 }) => {
  const r = size * 0.38; const circ = 2 * Math.PI * r;
  const dash = (score / 100) * circ;
  const color = score >= 80 ? '#4ade80' : score >= 60 ? '#facc15' : '#f87171';
  return (
    <div className="flex flex-col items-center gap-1">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#1e293b" strokeWidth="7" />
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth="7"
          strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"
          transform={`rotate(-90 ${size/2} ${size/2})`} style={{ transition: 'stroke-dasharray 0.8s ease' }} />
        <text x={size/2} y={size/2+5} textAnchor="middle" fill={color} fontSize={size*0.22} fontWeight="900">{score}%</text>
      </svg>
      <span className="text-[10px] text-slate-400 font-medium text-center leading-tight capitalize">{label}</span>
    </div>
  );
};

// ── Horizontal bar ────────────────────────────────────────────────────────────
const HBar = ({ label, value, max, color = 'bg-indigo-500' }) => (
  <div className="space-y-1">
    <div className="flex justify-between text-xs">
      <span className="text-slate-300 truncate pr-2">{label}</span>
      <span className="text-slate-400 shrink-0 font-bold">{value}</span>
    </div>
    <div className="h-2 bg-slate-700/60 rounded-full overflow-hidden">
      <div className={`h-2 rounded-full ${color} transition-all duration-700`} style={{ width: `${Math.min(100,(value / (max||1))*100)}%` }} />
    </div>
  </div>
);

// ── Module health scores ──────────────────────────────────────────────────────
const MODULE_LABELS = { tenants:'Tenant', apartments:'Apartment', contracts:'Contract', workshops:'Workshop' };

export default function AcrDashboardTab({ isAdmin }) {
  const queryClient = useQueryClient();
  const [selectedEmployee, setSelectedEmployee] = useState(null);

  const { data: dash, isLoading }       = useQuery({ queryKey:['acr-dashboard'],  queryFn: async () => (await api.get('/action-control/dashboard')).data,  refetchInterval:30000 });
  const { data: analytics, isLoading:al } = useQuery({ queryKey:['acr-analytics'], queryFn: async () => (await api.get('/system-health/analytics')).data });
  const { data: health }                  = useQuery({ queryKey:['acr-health'],    queryFn: async () => (await api.get('/system-health')).data });

  const runAuditMutation = useMutation({
    mutationFn: () => api.post('/action-control/run-audit'),
    onSuccess: () => { queryClient.invalidateQueries(['acr-dashboard']); queryClient.invalidateQueries(['acr-analytics']); },
  });

  const stats = dash?.stats;
  const moduleHealth = health?.module_health || {};

  if (selectedEmployee) {
    return <ActionControlReportDetail employee={selectedEmployee} showFullDetails={false} professionalMode={false} isAdmin={isAdmin} onBack={() => setSelectedEmployee(null)} />;
  }

  return (
    <div className="space-y-5">
      {/* ── Widget row ──────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-3">
        <div className="col-span-2"><MiniStat label="Total Problems" value={stats?.total} icon={AlertTriangle} color="bg-slate-800/80 border-slate-700/50 text-slate-200" /></div>
        <div className="col-span-2"><MiniStat label="🔴 Critical"   value={stats?.critical} icon={AlertCircle}  color="bg-red-950/70 border-red-500/30 text-red-400"     pulse={stats?.critical > 0} /></div>
        <div className="col-span-2"><MiniStat label="🟠 Warning"    value={stats?.warning}  icon={AlertTriangle} color="bg-amber-950/70 border-amber-500/30 text-amber-400" /></div>
        <div className="col-span-2"><MiniStat label="✅ Fixed"      value={stats?.fixed}    icon={CheckCircle2}  color="bg-emerald-950/70 border-emerald-500/30 text-emerald-400" /></div>
        <div className="col-span-2"><MiniStat label="🔒 Locked"     value={stats?.locked}   icon={Lock}  color="bg-slate-800/80 border-slate-700/50 text-slate-300" /></div>
        <div className="col-span-2"><MiniStat label="🔓 Unlocked"   value={stats?.unlocked} icon={Unlock} color="bg-amber-950/70 border-amber-500/30 text-amber-400" /></div>
        <div className="col-span-2"><MiniStat label="⏳ Pending Review" value={stats?.pending_review} icon={Clock} color="bg-purple-950/70 border-purple-500/30 text-purple-400" /></div>
        <div className="col-span-2"><MiniStat label="✅ Approved Today"  value={stats?.approved_today} icon={CheckCircle2} color="bg-emerald-950/70 border-emerald-500/30 text-emerald-400" /></div>
      </div>

      {/* ── Module Health Scores + Overall ────────────────────────────────── */}
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
        <div className="flex items-center gap-2 mb-4">
          <Target size={18} className="text-indigo-400" />
          <h3 className="font-bold text-white">AI Health Scores</h3>
          {isAdmin && (
            <button onClick={() => runAuditMutation.mutate()} disabled={runAuditMutation.isPending}
              className="ml-auto flex items-center gap-1.5 px-3 py-1.5 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-xs font-semibold transition-all">
              <RefreshCw size={13} className={runAuditMutation.isPending ? 'animate-spin' : ''} />
              {runAuditMutation.isPending ? 'Scanning…' : 'Run Audit'}
            </button>
          )}
        </div>
        <div className="flex flex-wrap justify-center gap-6">
          <HealthRing score={health?.overall_health ?? 0} label="Overall" size={100} />
          {Object.entries(moduleHealth).map(([mod, score]) => (
            <HealthRing key={mod} score={score} label={MODULE_LABELS[mod] || mod} />
          ))}
          {Object.keys(moduleHealth).length === 0 && (
            ['Tenant','Apartment','Contract','Workshop','Generator'].map(m => (
              <HealthRing key={m} score={100} label={m} />
            ))
          )}
        </div>
      </div>

      {/* ── Charts row ─────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">

        {/* Problems by Module */}
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><BarChart2 size={16} className="text-indigo-400" />By Module</h3>
          {al ? (
            <div className="w-6 h-6 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
          ) : (
            <div className="space-y-3">
              {(analytics?.byModule || []).map((m, i) => (
                <HBar key={i} label={MODULE_LABELS[m.module] || m.module}
                  value={m.total} max={Math.max(...(analytics?.byModule||[]).map(x=>x.total), 1)}
                  color={m.critical > 0 ? 'bg-red-500' : 'bg-amber-500'} />
              ))}
              {!analytics?.byModule?.length && <p className="text-slate-500 text-xs">Run an audit to see data</p>}
            </div>
          )}
        </div>

        {/* Problems by Department */}
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Users size={16} className="text-purple-400" />By Department</h3>
          <div className="space-y-3">
            {(analytics?.byDept || []).slice(0,6).map((d, i) => (
              <HBar key={i} label={d.department || 'Unknown'} value={d.total}
                max={Math.max(...(analytics?.byDept||[]).map(x=>x.total), 1)} color="bg-purple-500" />
            ))}
            {!analytics?.byDept?.length && <p className="text-slate-500 text-xs">No department data yet</p>}
          </div>
        </div>

        {/* Problems Over Time (simple sparkline) */}
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><TrendingUp size={16} className="text-emerald-400" />Last 30 Days Trend</h3>
          {analytics?.overTime?.length > 0 ? (
            <div className="flex items-end gap-1 h-24">
              {analytics.overTime.slice(-14).map((d, i) => {
                const maxVal = Math.max(...analytics.overTime.map(x => x.total), 1);
                const h = Math.max(4, (d.total / maxVal) * 90);
                return (
                  <div key={i} className="flex-1 flex flex-col items-center gap-1 group relative">
                    <div className="absolute -top-6 left-1/2 -translate-x-1/2 bg-slate-700 text-white text-[10px] px-1.5 py-0.5 rounded opacity-0 group-hover:opacity-100 whitespace-nowrap z-10">
                      {d.day}: {d.total}
                    </div>
                    <div style={{ height: `${h}%` }}
                      className="w-full rounded-sm bg-gradient-to-t from-indigo-600 to-purple-500 transition-all" />
                  </div>
                );
              })}
            </div>
          ) : <p className="text-slate-500 text-xs">No trend data yet</p>}
        </div>
      </div>

      {/* ── Second row of charts ─────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">

        {/* Top Employees with Errors */}
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Users size={16} className="text-red-400" />Top Employees with Errors</h3>
          {(analytics?.byEmployee || []).length > 0 ? (
            <div className="space-y-2">
              {analytics.byEmployee.slice(0,6).map((e, i) => (
                <div key={i} className="flex items-center gap-3 p-2 rounded-lg hover:bg-slate-700/40 transition-colors cursor-pointer"
                  onClick={() => setSelectedEmployee({ employee_id: null, employee_name: e.employee })}>
                  <div className="w-7 h-7 rounded-full bg-gradient-to-br from-red-500 to-pink-600 flex items-center justify-center text-white text-xs font-bold shrink-0">
                    {e.employee?.[0]?.toUpperCase()}
                  </div>
                  <span className="text-slate-300 text-sm flex-1 truncate">{e.employee}</span>
                  <div className="flex gap-2 text-xs">
                    {e.critical > 0 && <span className="bg-red-500/20 text-red-400 px-2 py-0.5 rounded-full">🔴{e.critical}</span>}
                    <span className="bg-slate-600/50 text-slate-300 px-2 py-0.5 rounded-full">{e.total}</span>
                  </div>
                </div>
              ))}
            </div>
          ) : <p className="text-slate-500 text-xs">No employee data yet</p>}
        </div>

        {/* Most Common Errors */}
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Activity size={16} className="text-amber-400" />Most Common Errors</h3>
          {(analytics?.commonErrors || []).length > 0 ? (
            <div className="space-y-2">
              {analytics.commonErrors.slice(0,8).map((e, i) => (
                <div key={i} className="flex items-center gap-3">
                  <span className="text-slate-400 text-xs font-mono w-4">{i+1}.</span>
                  <span className="text-slate-300 text-xs flex-1 truncate">{e.field_name} — {e.problem_type}</span>
                  <span className="bg-amber-500/20 text-amber-400 text-xs px-2 py-0.5 rounded-full font-bold shrink-0">{e.count}×</span>
                </div>
              ))}
            </div>
          ) : <p className="text-slate-500 text-xs">No error patterns yet</p>}
        </div>
      </div>

      {/* ── By Severity + Avg Resolution ─────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
          <h3 className="font-bold text-white text-sm mb-4">By Severity</h3>
          <div className="flex gap-4">
            {(analytics?.bySeverity || []).map(s => {
              const cfg = { critical:['text-red-400','bg-red-500'], warning:['text-amber-400','bg-amber-500'], info:['text-blue-400','bg-blue-500'] };
              const [tc, bc] = cfg[s.severity] || ['text-slate-400','bg-slate-500'];
              return (
                <div key={s.severity} className="flex-1 text-center space-y-2">
                  <div className={`text-3xl font-black ${tc}`}>{s.count}</div>
                  <div className="h-24 bg-slate-700/50 rounded-lg relative overflow-hidden">
                    <div className={`absolute bottom-0 left-0 right-0 ${bc} transition-all duration-700 rounded-b-lg`}
                      style={{ height: `${Math.min(100, (s.count / (stats?.total || 1)) * 100)}%` }} />
                  </div>
                  <div className={`text-xs font-bold capitalize ${tc}`}>{s.severity}</div>
                </div>
              );
            })}
          </div>
        </div>
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5 flex flex-col items-center justify-center">
          <Zap size={32} className="text-indigo-400 mb-3" />
          <div className="text-4xl font-black text-white">
            {analytics?.resolutionAvg ? `${Math.round(analytics.resolutionAvg)}h` : '—'}
          </div>
          <div className="text-slate-400 text-sm mt-1">Avg. Resolution Time</div>
          <div className="mt-4 text-xs text-slate-500">
            {(analytics?.resolutionAvg || 0) <= 24
              ? '✅ Within SLA (24h for critical)'
              : '⚠️ Exceeds SLA target'}
          </div>
        </div>
      </div>
    </div>
  );
}
