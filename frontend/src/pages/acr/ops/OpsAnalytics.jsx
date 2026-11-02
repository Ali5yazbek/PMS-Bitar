import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { BarChart3, PieChart as PieChartIcon } from 'lucide-react';
import api from '../../../api/axios';

// A simple vertical bar chart component since we don't have Recharts installed in this snippet
const SimpleBarChart = ({ data, maxVal }) => {
  return (
    <div className="flex items-end justify-between h-48 mt-4 gap-2 px-2">
      {data.map((d, i) => {
        const heightPct = maxVal > 0 ? (d.val / maxVal) * 100 : 0;
        return (
          <div key={i} className="flex flex-col items-center flex-1 group relative">
            <div className="absolute -top-8 bg-slate-800 text-white text-xs px-2 py-1 rounded opacity-0 group-hover:opacity-100 transition-opacity z-10 pointer-events-none whitespace-nowrap">
              {d.val} events
            </div>
            <div className="w-full bg-indigo-500 hover:bg-indigo-400 rounded-t-sm transition-all" style={{ height: `${Math.max(4, heightPct)}%` }} />
            <div className="text-[10px] text-slate-500 mt-2 rotate-45 origin-top-left">{d.label}</div>
          </div>
        );
      })}
    </div>
  );
};

export default function OpsAnalytics() {
  const { data } = useQuery({
    queryKey: ['ops-analytics'],
    queryFn: async () => (await api.get('/operations/analytics')).data,
    refetchInterval: 60000,
  });

  const hourly = data?.hourly_activity || [];
  const modules = data?.top_modules || [];

  // Format hourly data (0-23 hours)
  const hourMap = {};
  for(let i=0; i<24; i++) hourMap[i] = 0;
  hourly.forEach(h => { hourMap[h.hour] = h.event_count; });
  const hourChartData = Object.entries(hourMap).map(([h, val]) => ({
    label: `${h.padStart(2, '0')}:00`,
    val: parseInt(val)
  }));
  const maxHour = Math.max(...hourChartData.map(d => d.val), 10);

  // Format module data
  const maxMod = Math.max(...modules.map(m => m.event_count), 10);

  return (
    <div className="space-y-6">
      <div className="bg-slate-900/40 rounded-2xl border border-slate-700/50 p-6">
        <h3 className="font-bold text-white flex items-center gap-2">
          <BarChart3 size={18} className="text-indigo-400" />
          System Activity (Last 24 Hours)
        </h3>
        <p className="text-xs text-slate-400 mb-6">Total operations recorded per hour</p>
        
        <SimpleBarChart data={hourChartData} maxVal={maxHour} />
      </div>

      <div className="bg-slate-900/40 rounded-2xl border border-slate-700/50 p-6">
        <h3 className="font-bold text-white flex items-center gap-2">
          <PieChartIcon size={18} className="text-emerald-400" />
          Top Modules (Last 7 Days)
        </h3>
        <p className="text-xs text-slate-400 mb-6">Most active areas of the system</p>
        
        <div className="space-y-4">
          {modules.map((m, i) => (
            <div key={i} className="flex items-center gap-4">
              <div className="w-24 text-sm text-slate-300 font-semibold capitalize truncate">{m.module}</div>
              <div className="flex-1 bg-slate-800 rounded-full h-3 overflow-hidden">
                <div className="bg-emerald-500 h-full rounded-full" style={{ width: `${(m.event_count / maxMod) * 100}%` }} />
              </div>
              <div className="w-12 text-right text-xs font-mono text-slate-400">{m.event_count}</div>
            </div>
          ))}
          {modules.length === 0 && <div className="text-center text-slate-500 py-4">No module activity data.</div>}
        </div>
      </div>
    </div>
  );
}
