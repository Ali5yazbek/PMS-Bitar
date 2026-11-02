import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { HeartPulse, Database, HardDrive, FileX, Mail, AlertTriangle, CheckCircle2, Server, RefreshCw } from 'lucide-react';
import api from '../../api/axios';

const HealthBar = ({ label, value, max = 100, color = 'bg-indigo-500', unit = '' }) => {
  const pct = Math.min(100, max > 0 ? (value / max) * 100 : 0);
  const danger = pct > 90;
  return (
    <div className="space-y-1.5">
      <div className="flex justify-between text-xs">
        <span className="text-slate-300">{label}</span>
        <span className={`font-bold ${danger ? 'text-red-400' : 'text-white'}`}>{value}{unit}</span>
      </div>
      <div className="h-2.5 bg-slate-700/60 rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all duration-700 ${danger ? 'bg-red-500' : color}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
};

const MetricCard = ({ label, value, icon: Icon, colorClass, note }) => (
  <div className={`relative overflow-hidden rounded-2xl p-5 border flex items-center gap-4 shadow-lg ${colorClass}`}>
    <Icon size={26} className="opacity-90 shrink-0" />
    <div>
      <div className="text-2xl font-black tabular-nums">{value ?? '—'}</div>
      <div className="text-xs font-medium opacity-65 mt-0.5 leading-tight">{label}</div>
      {note && <div className="text-[10px] opacity-40 mt-0.5">{note}</div>}
    </div>
    <div className="absolute right-3 top-3 opacity-5"><Icon size={60} /></div>
  </div>
);

const ModuleHealthCard = ({ module, score }) => {
  const color = score >= 80 ? 'text-emerald-400 border-emerald-500/20 bg-emerald-950/30'
               : score >= 60 ? 'text-amber-400 border-amber-500/20 bg-amber-950/30'
               : 'text-red-400 border-red-500/20 bg-red-950/30';
  const label = { tenants:'Tenants', apartments:'Apartments', contracts:'Contracts', workshops:'Workshops' };
  return (
    <div className={`rounded-xl border p-4 text-center space-y-1.5 ${color}`}>
      <div className="text-3xl font-black">{score}%</div>
      <div className="text-xs font-semibold capitalize">{label[module] || module}</div>
      <div className={`text-[10px] ${score>=80?'opacity-60':'font-bold'}`}>
        {score >= 80 ? 'Healthy' : score >= 60 ? 'Needs Attention' : 'Critical'}
      </div>
    </div>
  );
};

export default function AcrHealthTab() {
  const { data: health, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['acr-system-health'],
    queryFn: async () => (await api.get('/system-health')).data,
    refetchInterval: 60000,
  });

  const db      = health?.database  || {};
  const storage = health?.storage   || {};
  const issues  = health?.issues    || {};
  const mods    = health?.module_health || {};

  return (
    <div className="space-y-5">
      {/* Header + refresh */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <HeartPulse size={20} className="text-emerald-400" />
          <h3 className="font-bold text-white">System Health Overview</h3>
          {health?.overall_health != null && (
            <span className={`ml-2 px-3 py-1 rounded-full text-sm font-black
              ${health.overall_health >= 80 ? 'bg-emerald-500/20 text-emerald-400' : health.overall_health >= 60 ? 'bg-amber-500/20 text-amber-400' : 'bg-red-500/20 text-red-400'}`}>
              {health.overall_health}% Overall
            </span>
          )}
        </div>
        <button onClick={() => refetch()} className="p-2 bg-slate-700/60 hover:bg-slate-700 text-slate-300 rounded-xl transition-colors">
          <RefreshCw size={15} className={isFetching ? 'animate-spin' : ''} />
        </button>
      </div>

      {isLoading ? (
        <div className="flex items-center justify-center py-20">
          <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : (
        <>
          {/* Module health */}
          {Object.keys(mods).length > 0 && (
            <div>
              <p className="text-xs font-semibold text-slate-400 uppercase mb-3">Module Health</p>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {Object.entries(mods).map(([mod, score]) => (
                  <ModuleHealthCard key={mod} module={mod} score={score} />
                ))}
              </div>
            </div>
          )}

          {/* Issue metrics */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            <MetricCard label="Open Audits"       value={issues.open_audit}         icon={AlertTriangle} colorClass="bg-amber-950/60 border-amber-500/20 text-amber-400" />
            <MetricCard label="Pending Review"    value={issues.pending_audit}       icon={AlertTriangle} colorClass="bg-purple-950/60 border-purple-500/20 text-purple-400" />
            <MetricCard label="Integrity Issues"  value={issues.open_integrity}      icon={Database}      colorClass="bg-red-950/60 border-red-500/20 text-red-400" />
            <MetricCard label="Financial Issues"  value={issues.open_financial}      icon={AlertTriangle} colorClass="bg-orange-950/60 border-orange-500/20 text-orange-400" />
            <MetricCard label="Critical Events"   value={issues.critical_events_24h} icon={HeartPulse}    colorClass="bg-red-950/60 border-red-500/20 text-red-400" note="Last 24h" />
            <MetricCard label="Pending Approvals" value={issues.pending_approvals}   icon={CheckCircle2}  colorClass="bg-blue-950/60 border-blue-500/20 text-blue-400" />
          </div>

          {/* DB + Storage */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
              <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Database size={16} className="text-blue-400" />Database</h3>
              <div className="space-y-4">
                <HealthBar label="Total Size" value={parseFloat(db.total_size_mb || 0).toFixed(1)} max={500} unit=" MB" color="bg-blue-500" />
                <HealthBar label="Table Count" value={db.table_count || 0} max={200} unit=" tables" color="bg-indigo-500" />
                <div className="pt-2 border-t border-slate-700/30">
                  <p className="text-xs font-semibold text-slate-400 mb-2">Largest Tables</p>
                  {(db.top_tables || []).slice(0,5).map((t,i) => (
                    <div key={i} className="flex justify-between text-xs py-1 border-b border-slate-800/50">
                      <span className="text-slate-400 font-mono">{t.name}</span>
                      <span className="text-slate-300">{t.rows?.toLocaleString()} rows • {t.size_mb} MB</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
              <h3 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><HardDrive size={16} className="text-purple-400" />File Storage</h3>
              <div className="space-y-4">
                <HealthBar label="Storage Used" value={parseFloat(storage.size_mb || 0).toFixed(1)} max={1024} unit=" MB" color="bg-purple-500" />
                <div className="grid grid-cols-2 gap-3 pt-2 border-t border-slate-700/30">
                  <div className="text-center">
                    <div className="text-2xl font-black text-white">{storage.file_count?.toLocaleString() || 0}</div>
                    <div className="text-xs text-slate-400">Total Files</div>
                  </div>
                  <div className="text-center">
                    <div className={`text-2xl font-black ${(storage.broken_files||0) > 0 ? 'text-red-400' : 'text-emerald-400'}`}>
                      {storage.broken_files || 0}
                    </div>
                    <div className="text-xs text-slate-400">Broken Files</div>
                  </div>
                </div>
                {(health?.expiring_perms || 0) > 0 && (
                  <div className="bg-amber-950/30 border border-amber-500/20 rounded-xl p-3">
                    <p className="text-amber-400 text-xs font-semibold">⚠️ {health.expiring_perms} temp permissions expiring in &lt;2h</p>
                  </div>
                )}
                {health?.last_scan && (
                  <div className="bg-emerald-950/30 border border-emerald-500/20 rounded-xl p-3">
                    <p className="text-emerald-400 text-xs font-semibold">
                      ✅ Last scan: {new Date(health.last_scan.created_at).toLocaleString()}
                    </p>
                    <p className="text-slate-500 text-xs mt-0.5">{health.last_scan.total_issues_found} issues detected</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
