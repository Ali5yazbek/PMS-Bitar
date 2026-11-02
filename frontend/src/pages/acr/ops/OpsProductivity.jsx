import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Trophy, CheckCircle2, FileText, AlertTriangle, TrendingUp } from 'lucide-react';
import api from '../../../api/axios';

export default function OpsProductivity() {
  const { data } = useQuery({
    queryKey: ['ops-productivity'],
    queryFn: async () => (await api.get('/operations/productivity')).data,
    refetchInterval: 60000, // Poll every minute
  });

  const { leaderboard = [], summary = {} } = data || {};

  return (
    <div className="space-y-6">
      {/* Overview Cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {[
          { label: 'Total Actions Today', value: summary.total_events || 0, icon: TrendingUp, color: 'text-blue-400 bg-blue-500/10 border-blue-500/20' },
          { label: 'Records Created',     value: summary.records_created || 0, icon: CheckCircle2, color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20' },
          { label: 'Records Edited',      value: summary.records_edited || 0, icon: FileText, color: 'text-indigo-400 bg-indigo-500/10 border-indigo-500/20' },
          { label: 'Records Deleted',     value: summary.records_deleted || 0, icon: AlertTriangle, color: 'text-red-400 bg-red-500/10 border-red-500/20' },
        ].map((c, i) => (
          <div key={i} className={`p-5 rounded-2xl border flex items-center gap-4 ${c.color}`}>
            <c.icon size={24} className="shrink-0 opacity-80" />
            <div>
              <div className="text-3xl font-black">{c.value}</div>
              <div className="text-xs font-semibold opacity-70 uppercase tracking-wider">{c.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Leaderboard */}
      <div className="bg-slate-900/60 rounded-2xl border border-slate-700/50 overflow-hidden">
        <div className="p-4 bg-slate-800/40 border-b border-slate-700/50 flex items-center gap-2">
          <Trophy size={18} className="text-amber-400" />
          <h3 className="font-bold text-white">Daily Productivity Leaderboard</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-800/20 border-b border-slate-700/50">
                <th className="px-4 py-3 text-xs font-bold text-slate-400 uppercase tracking-wider">Rank</th>
                <th className="px-4 py-3 text-xs font-bold text-slate-400 uppercase tracking-wider">Employee</th>
                <th className="px-4 py-3 text-xs font-bold text-slate-400 uppercase tracking-wider">Role</th>
                <th className="px-4 py-3 text-xs font-bold text-emerald-400 uppercase tracking-wider">Tasks Done</th>
                <th className="px-4 py-3 text-xs font-bold text-indigo-400 uppercase tracking-wider">Reports</th>
                <th className="px-4 py-3 text-xs font-bold text-red-400 uppercase tracking-wider">Problems Caused</th>
                <th className="px-4 py-3 text-xs font-bold text-slate-400 uppercase tracking-wider">Total Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {leaderboard.map((u, i) => (
                <tr key={i} className="hover:bg-slate-800/40 transition-colors">
                  <td className="px-4 py-3">
                    <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold
                      ${i===0 ? 'bg-amber-500 text-amber-950' : i===1 ? 'bg-slate-300 text-slate-800' : i===2 ? 'bg-amber-700 text-amber-100' : 'bg-slate-800 text-slate-400'}`}>
                      {i + 1}
                    </div>
                  </td>
                  <td className="px-4 py-3">
                    <div className="font-bold text-white">{u.user_name}</div>
                    {u.department && <div className="text-[10px] text-slate-500">{u.department}</div>}
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-300 capitalize">{u.role}</td>
                  <td className="px-4 py-3 font-mono text-emerald-400 font-bold">{u.tasks_completed}</td>
                  <td className="px-4 py-3 font-mono text-indigo-400 font-bold">{u.reports_submitted}</td>
                  <td className="px-4 py-3 font-mono text-red-400 font-bold">{u.problems}</td>
                  <td className="px-4 py-3 font-mono text-slate-300 font-bold">{u.total_actions}</td>
                </tr>
              ))}
              {leaderboard.length === 0 && (
                <tr><td colSpan="7" className="text-center py-10 text-slate-500 text-sm">No activity recorded today yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
