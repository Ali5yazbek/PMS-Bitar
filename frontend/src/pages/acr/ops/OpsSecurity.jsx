import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { ShieldAlert, Trash2, DownloadCloud, AlertOctagon, Info } from 'lucide-react';
import api from '../../../api/axios';

export default function OpsSecurity() {
  const { data } = useQuery({
    queryKey: ['ops-security'],
    queryFn: async () => (await api.get('/operations/security')).data,
    refetchInterval: 30000,
  });

  const massDeletes = data?.mass_deletes || [];
  const largeExports = data?.large_exports || [];
  const events = data?.events || [];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 h-[600px] overflow-y-auto no-scrollbar">
      {/* AI Detections */}
      <div className="space-y-5">
        <div className="bg-red-950/20 border border-red-500/30 rounded-2xl p-5">
          <h3 className="font-bold text-red-400 flex items-center gap-2 mb-4">
            <Trash2 size={18} /> Mass Deletion Detection
          </h3>
          {massDeletes.length > 0 ? (
            <div className="space-y-3">
              {massDeletes.map((md, i) => (
                <div key={i} className="p-3 bg-red-900/30 border border-red-500/40 rounded-xl flex justify-between items-center">
                  <div>
                    <div className="font-bold text-white">{md.user_name}</div>
                    <div className="text-xs text-red-300">Deleted {md.delete_count} records rapidly</div>
                  </div>
                  <div className="text-right">
                    <div className="text-xs text-slate-400">Last event</div>
                    <div className="text-sm font-mono text-red-200">{new Date(md.last_delete).toLocaleTimeString()}</div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-sm text-slate-500 flex items-center gap-2"><CheckCircle2 size={16} className="text-emerald-500" /> No mass deletions detected.</div>
          )}
        </div>

        <div className="bg-amber-950/20 border border-amber-500/30 rounded-2xl p-5">
          <h3 className="font-bold text-amber-400 flex items-center gap-2 mb-4">
            <DownloadCloud size={18} /> Large Export Detection
          </h3>
          {largeExports.length > 0 ? (
            <div className="space-y-3">
              {largeExports.map((ex, i) => (
                <div key={i} className="p-3 bg-amber-900/30 border border-amber-500/40 rounded-xl flex justify-between items-center">
                  <div>
                    <div className="font-bold text-white">{ex.user_name}</div>
                    <div className="text-xs text-amber-300">Exported {ex.module} ({ex.export_count} times)</div>
                  </div>
                  <div className="text-right">
                    <div className="text-xs text-slate-400">Last export</div>
                    <div className="text-sm font-mono text-amber-200">{new Date(ex.last_export).toLocaleTimeString()}</div>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-sm text-slate-500 flex items-center gap-2"><CheckCircle2 size={16} className="text-emerald-500" /> No excessive exports detected.</div>
          )}
        </div>
      </div>

      {/* Security Events Log */}
      <div className="bg-slate-900/40 rounded-2xl border border-slate-700/50 flex flex-col">
        <div className="p-4 bg-slate-800/40 border-b border-slate-700/50 flex items-center gap-2">
          <ShieldAlert size={18} className="text-indigo-400" />
          <h3 className="font-bold text-white">Recent Security Events</h3>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {events.map((e) => (
            <div key={e.id} className="p-3 rounded-xl border bg-slate-800/30 border-slate-700/50 flex gap-3">
              <div className="mt-1">
                {e.severity === 'critical' ? <AlertOctagon size={16} className="text-red-500" /> :
                 e.severity === 'warning' ? <AlertTriangle size={16} className="text-amber-500" /> :
                 <Info size={16} className="text-blue-500" />}
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-bold text-white text-sm">{e.event_type}</span>
                  <span className="text-xs text-slate-400">{new Date(e.created_at).toLocaleString()}</span>
                </div>
                <div className="text-xs text-slate-300 mt-0.5">{e.description}</div>
                <div className="text-[10px] text-slate-500 mt-1 flex gap-2">
                  <span>User: {e.user_name || 'System'}</span>
                  <span>IP: {e.ip_address}</span>
                </div>
              </div>
            </div>
          ))}
          {events.length === 0 && <div className="text-center text-slate-500 text-sm py-10">No security events found.</div>}
        </div>
      </div>
    </div>
  );
}

// Dummy component needed because CheckCircle2/AlertTriangle were used but not imported
const CheckCircle2 = ({ size, className }) => <svg width={size} height={size} className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>;
const AlertTriangle = ({ size, className }) => <svg width={size} height={size} className={className} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>;
