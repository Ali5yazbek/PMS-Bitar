import React, { useState } from 'react';
import { Activity, Users, TrendingUp, ShieldAlert, BarChart3 } from 'lucide-react';
import OpsLiveFeed from './ops/OpsLiveFeed';
import OpsOnlineUsers from './ops/OpsOnlineUsers';
import OpsProductivity from './ops/OpsProductivity';
import OpsSecurity from './ops/OpsSecurity';
import OpsAnalytics from './ops/OpsAnalytics';

export default function AcrOperationsTab({ isAdmin }) {
  const [activeSubTab, setActiveSubTab] = useState('feed');

  const tabs = [
    { id: 'feed',         label: 'Live Activity',     icon: Activity },
    { id: 'users',        label: 'Online Users',      icon: Users },
    { id: 'productivity', label: 'Productivity',      icon: TrendingUp },
    { id: 'security',     label: 'Security & AI',     icon: ShieldAlert },
    { id: 'analytics',    label: 'Timeline & Charts', icon: BarChart3 },
  ];

  if (!isAdmin) {
    return (
      <div className="p-8 text-center bg-slate-900/50 rounded-2xl border border-slate-800">
        <ShieldAlert size={48} className="mx-auto text-red-500 mb-4 opacity-80" />
        <h2 className="text-xl font-bold text-white mb-2">Access Denied</h2>
        <p className="text-slate-400">The Live Operations Center is strictly reserved for Super Administrators.</p>
      </div>
    );
  }

  return (
    <div className="space-y-5">
      {/* Live System Status Banner */}
      <div className="flex items-center justify-between bg-slate-900/80 border border-slate-700/50 p-3 rounded-2xl">
        <div className="flex gap-6 items-center text-xs font-bold uppercase tracking-wider text-slate-400 pl-2">
           <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Database</div>
           <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> API Engine</div>
           <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-emerald-500" /> Notifications</div>
           <div className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-emerald-500" /> Cron Tasks</div>
        </div>
        <div className="flex gap-4 items-center text-xs font-bold text-slate-300 pr-2">
           <div>Storage <span className="text-emerald-400">72%</span></div>
           <div>Memory <span className="text-indigo-400">41%</span></div>
           <div className="flex items-center gap-1 bg-indigo-500/20 text-indigo-300 px-2 py-0.5 rounded border border-indigo-500/30">
              <Users size={12} /> Active Sessions: Live
           </div>
        </div>
      </div>

      {/* Sub-tab navigation */}
      <div className="flex gap-1.5 p-1.5 bg-slate-900/60 border border-slate-700/50 rounded-2xl overflow-x-auto no-scrollbar">
        {tabs.map(t => (
          <button key={t.id} onClick={() => setActiveSubTab(t.id)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-bold whitespace-nowrap transition-all duration-300 ${activeSubTab === t.id ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-600/20' : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800'}`}>
            <t.icon size={16} />
            {t.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="min-h-[600px]">
        {activeSubTab === 'feed' && <OpsLiveFeed />}
        {activeSubTab === 'users' && <OpsOnlineUsers />}
        {activeSubTab === 'productivity' && <OpsProductivity />}
        {activeSubTab === 'security' && <OpsSecurity />}
        {activeSubTab === 'analytics' && <OpsAnalytics />}
      </div>
    </div>
  );
}
