import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Activity, RefreshCw, Filter, Monitor, MapPin, Search, ChevronRight, ChevronLeft } from 'lucide-react';
import api from '../../../api/axios';

const STATUS_COLORS = {
  success: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
  warning: 'bg-amber-500/20 text-amber-400 border-amber-500/30',
  error:   'bg-red-500/20 text-red-400 border-red-500/30',
  info:    'bg-blue-500/20 text-blue-400 border-blue-500/30'
};

const ACTION_ICONS = {
  created:  '✨',
  edited:   '✏️',
  deleted:  '🗑️',
  approved: '✅',
  exported: '📥',
  login:    '🔑',
  logout:   '🚪',
  navigation:'🧭'
};

export default function OpsLiveFeed() {
  const [filter, setFilter] = useState('');
  const [page, setPage] = useState(1);
  const [showFilters, setShowFilters] = useState(false);
  
  const { data: feed, isFetching } = useQuery({
    queryKey: ['ops-live-feed', page],
    queryFn: async () => (await api.get(`/operations/live-feed?page=${page}&limit=50`)).data,
    refetchInterval: 5000, 
  });

  const filteredFeed = (feed || []).filter(e => 
    !filter || 
    (e.user_name?.toLowerCase().includes(filter.toLowerCase()) || 
     e.module?.toLowerCase().includes(filter.toLowerCase()) ||
     e.action?.toLowerCase().includes(filter.toLowerCase()) ||
     e.description?.toLowerCase().includes(filter.toLowerCase()))
  );

  return (
    <div className="space-y-4">
      {/* Header controls */}
      <div className="flex items-center justify-between gap-4 flex-wrap bg-slate-900/40 p-4 rounded-2xl border border-slate-700/50">
        <div className="flex items-center gap-3">
          <div className="relative">
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full animate-ping" />
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full" />
            <Activity size={24} className="text-red-400" />
          </div>
          <div>
            <h3 className="font-bold text-white leading-tight">Live Activity Stream</h3>
            <p className="text-xs text-slate-400">Monitoring all system events in real-time</p>
          </div>
        </div>
        
        <div className="flex items-center gap-3 flex-1 max-w-md justify-end">
          <div className="relative flex-1">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input type="text" placeholder="Search logs..." value={filter} onChange={e => setFilter(e.target.value)}
              className="w-full bg-slate-800 border border-slate-700 text-white rounded-xl pl-9 pr-4 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 transition-all" />
          </div>
          <button onClick={() => setShowFilters(!showFilters)} className={`p-2.5 rounded-xl border transition-colors ${showFilters ? 'bg-indigo-600 text-white border-indigo-500' : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-white'}`}>
            <Filter size={16} />
          </button>
          <div className="flex items-center gap-2 text-xs font-semibold text-slate-400 bg-slate-800 px-3 py-2.5 rounded-xl border border-slate-700">
            <RefreshCw size={14} className={isFetching ? 'animate-spin text-indigo-400' : ''} />
            {isFetching ? 'Sync' : 'Live'}
          </div>
        </div>
      </div>

      {/* Advanced Filters Drawer (UI Only) */}
      {showFilters && (
        <div className="bg-slate-800/50 p-4 rounded-2xl border border-slate-700/50 flex gap-4 text-sm overflow-x-auto no-scrollbar">
          <select className="bg-slate-900 border border-slate-700 text-white rounded-lg px-3 py-1.5 focus:outline-none"><option>Today</option><option>Yesterday</option><option>Last Week</option><option>This Month</option></select>
          <select className="bg-slate-900 border border-slate-700 text-white rounded-lg px-3 py-1.5 focus:outline-none"><option>All Roles</option><option>Admin</option><option>Manager</option></select>
          <select className="bg-slate-900 border border-slate-700 text-white rounded-lg px-3 py-1.5 focus:outline-none"><option>All Buildings</option><option>Galaxy</option><option>Palmier</option></select>
          <select className="bg-slate-900 border border-slate-700 text-white rounded-lg px-3 py-1.5 focus:outline-none"><option>All Departments</option><option>Workshop</option><option>Finance</option></select>
          <select className="bg-slate-900 border border-slate-700 text-white rounded-lg px-3 py-1.5 focus:outline-none"><option>Any Severity</option><option>Critical</option><option>High</option></select>
        </div>
      )}

      {/* Feed List */}
      <div className="bg-slate-900/60 rounded-2xl border border-slate-700/50 overflow-hidden flex flex-col">
        <div className="h-[520px] overflow-y-auto no-scrollbar">
          {filteredFeed.length === 0 ? (
            <div className="p-10 text-center text-slate-500 text-sm">No activity found or waiting for events...</div>
          ) : (
            <div className="divide-y divide-slate-800/50">
              {filteredFeed.map((event) => (
                <div key={`${event.source_table}-${event.id}`} className="p-4 hover:bg-slate-800/40 transition-colors flex items-start gap-4">
                  
                  <div className="w-16 shrink-0 text-right">
                    <div className="text-sm font-bold text-slate-300">{new Date(event.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}</div>
                  </div>

                  <div className="text-2xl shrink-0 mt-0.5">{ACTION_ICONS[event.action] || '🔹'}</div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap mb-1">
                      <span className="font-bold text-white">{event.user_name || 'System'}</span>
                      {event.role && <span className="text-xs bg-slate-800 text-slate-400 px-2 py-0.5 rounded-full border border-slate-700">{event.role}</span>}
                      {event.department && <span className="text-xs text-slate-500">• {event.department}</span>}
                    </div>
                    <p className="text-sm text-slate-300 leading-snug">
                      <span className="font-semibold text-indigo-400 capitalize">{event.action}</span>
                      {event.module && <span className="text-slate-400 mx-1">in</span>}
                      {event.module && <span className="font-bold text-slate-200 capitalize">{event.module}</span>}
                      {event.record_id && <span className="ml-1 px-1.5 py-0.5 bg-slate-800 text-xs rounded border border-slate-700">#{event.record_id}</span>}
                    </p>
                    {event.description && <p className="text-xs text-slate-500 mt-1.5 leading-relaxed truncate">{event.description}</p>}
                  </div>

                  <div className="shrink-0 flex flex-col items-end gap-2 text-right">
                    <div className="flex gap-2">
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded uppercase border ${event.severity === 'critical' ? 'bg-red-500/20 text-red-500 border-red-500/40' : 'bg-slate-800 text-slate-500 border-slate-700'}`}>
                          {event.severity || 'low'}
                        </span>
                        <span className={`text-[10px] font-bold px-2.5 py-0.5 rounded-full uppercase border ${STATUS_COLORS[event.status] || STATUS_COLORS.success}`}>
                          {event.status}
                        </span>
                    </div>
                    <div className="flex flex-col gap-0.5 text-[10px] text-slate-500">
                      {event.ip_address && <div className="flex items-center gap-1 justify-end"><MapPin size={10} /> {event.ip_address}</div>}
                      {event.source_table && <div className="flex items-center gap-1 justify-end text-slate-600">DB: {event.source_table}</div>}
                    </div>
                  </div>

                </div>
              ))}
            </div>
          )}
        </div>
        
        {/* Pagination Controls */}
        <div className="p-3 bg-slate-800/40 border-t border-slate-700/50 flex items-center justify-between">
          <div className="text-xs text-slate-500">Showing page {page}</div>
          <div className="flex items-center gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="p-1 rounded bg-slate-800 text-white disabled:opacity-50 hover:bg-slate-700"><ChevronLeft size={16}/></button>
            <button onClick={() => setPage(p => p + 1)} disabled={filteredFeed.length < 50} className="p-1 rounded bg-slate-800 text-white disabled:opacity-50 hover:bg-slate-700"><ChevronRight size={16}/></button>
          </div>
        </div>
      </div>
    </div>
  );
}
