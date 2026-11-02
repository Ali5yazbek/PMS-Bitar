import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  LayoutDashboard, ClipboardList, ShieldCheck, Grid3X3,
  AlertOctagon, GitBranch, Database, CalendarClock,
  HeartPulse, Settings2, RefreshCw, Bell, Activity
} from 'lucide-react';
import api from '../api/axios';

// Lazy-loaded tab components
const AcrDashboardTab     = React.lazy(() => import('./acr/AcrDashboardTab'));
const AcrAuditTab         = React.lazy(() => import('./acr/AcrAuditTab'));
const AcrPermissionTab    = React.lazy(() => import('./acr/AcrPermissionTab'));
const AcrRoleMatrixTab    = React.lazy(() => import('./acr/AcrRoleMatrixTab'));
const AcrSecurityTab      = React.lazy(() => import('./acr/AcrSecurityTab'));
const AcrApprovalTab      = React.lazy(() => import('./acr/AcrApprovalTab'));
const AcrIntegrityTab     = React.lazy(() => import('./acr/AcrIntegrityTab'));
const AcrSchedulerTab     = React.lazy(() => import('./acr/AcrSchedulerTab'));
const AcrHealthTab        = React.lazy(() => import('./acr/AcrHealthTab'));
const AcrSettingsTab      = React.lazy(() => import('./acr/AcrSettingsTab'));
const AcrOperationsTab    = React.lazy(() => import('./acr/AcrOperationsTab'));

const TABS = [
  { id: 'dashboard',   label: 'Dashboard',       icon: LayoutDashboard, adminOnly: false },
  { id: 'audit',       label: 'Audit Reports',   icon: ClipboardList,   adminOnly: false },
  { id: 'permissions', label: 'Permission Center',icon: ShieldCheck,    adminOnly: true  },
  { id: 'matrix',      label: 'Role Matrix',      icon: Grid3X3,        adminOnly: true  },
  { id: 'security',    label: 'Security Logs',    icon: AlertOctagon,   adminOnly: true  },
  { id: 'approvals',   label: 'Approval Center',  icon: GitBranch,      adminOnly: false },
  { id: 'integrity',   label: 'Data Integrity',   icon: Database,       adminOnly: true  },
  { id: 'scheduler',   label: 'Scheduled Scans',  icon: CalendarClock,  adminOnly: true  },
  { id: 'health',      label: 'System Health',    icon: HeartPulse,     adminOnly: true  },
  { id: 'settings',    label: 'Settings',         icon: Settings2,      adminOnly: true  },
  { id: 'operations',  label: 'Live Operations',  icon: Activity,       adminOnly: true  },
];

const TabLoader = () => (
  <div className="flex items-center justify-center py-20">
    <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
  </div>
);

export default function ActionControlReport() {
  const [user]    = useState(() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } });
  const isAdmin   = user?.role === 'admin';
  const isManager = user?.role === 'manager' || isAdmin;

  const visibleTabs = TABS.filter(t => !t.adminOnly || isAdmin);
  const [activeTab, setActiveTab] = useState(visibleTabs[0]?.id || 'dashboard');

  // Pending approval badge
  const { data: myActions } = useQuery({
    queryKey: ['acr-my-actions'],
    queryFn: async () => (await api.get('/approvals/my-actions')).data,
    refetchInterval: 30000,
    enabled: isManager,
  });
  const pendingApprovals = myActions?.length || 0;

  const renderTab = () => {
    const props = { isAdmin, isManager, user };
    switch (activeTab) {
      case 'dashboard':   return <AcrDashboardTab {...props} />;
      case 'audit':       return <AcrAuditTab {...props} />;
      case 'permissions': return <AcrPermissionTab {...props} />;
      case 'matrix':      return <AcrRoleMatrixTab {...props} />;
      case 'security':    return <AcrSecurityTab {...props} />;
      case 'approvals':   return <AcrApprovalTab {...props} pendingCount={pendingApprovals} />;
      case 'integrity':   return <AcrIntegrityTab {...props} />;
      case 'scheduler':   return <AcrSchedulerTab {...props} />;
      case 'health':      return <AcrHealthTab {...props} />;
      case 'settings':    return <AcrSettingsTab {...props} />;
      case 'operations':  return <AcrOperationsTab {...props} />;
      default: return null;
    }
  };

  return (
    <div className="flex flex-col h-full min-h-screen pb-10">
      {/* ── Header ──────────────────────────────────────────────────────────── */}
      <div className="relative overflow-hidden rounded-2xl mb-4 p-5 bg-gradient-to-r from-slate-900 via-indigo-950/80 to-slate-900 border border-indigo-500/20 shadow-2xl shrink-0">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(99,102,241,0.2),transparent_65%)]" />
        <div className="relative flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/40 shrink-0">
            <ShieldCheck size={24} className="text-white" />
          </div>
          <div className="flex-1 min-w-0">
            <h1 className="text-xl font-black text-white tracking-tight">Enterprise Control Center</h1>
            <p className="text-indigo-300 text-xs mt-0.5">
              Permission management · Audit governance · Security · Data integrity · System health
            </p>
          </div>
          {pendingApprovals > 0 && (
            <div className="flex items-center gap-2 bg-amber-500/20 border border-amber-500/30 rounded-xl px-3 py-2 shrink-0">
              <Bell size={16} className="text-amber-400 animate-pulse" />
              <span className="text-amber-300 text-sm font-bold">{pendingApprovals} awaiting your approval</span>
            </div>
          )}
        </div>
      </div>

      {/* ── Tab Bar ─────────────────────────────────────────────────────────── */}
      <div className="flex flex-wrap gap-1 bg-slate-900/60 border border-slate-700/50 rounded-2xl p-2 mb-4 shrink-0">
        {visibleTabs.map(tab => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          const hasBadge = tab.id === 'approvals' && pendingApprovals > 0;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`relative flex items-center gap-2 px-3.5 py-2.5 rounded-xl text-sm font-semibold transition-all duration-200
                ${isActive
                  ? 'bg-gradient-to-br from-indigo-600 to-purple-600 text-white shadow-lg shadow-indigo-500/30'
                  : 'text-slate-400 hover:text-white hover:bg-slate-700/60'
                }`}
            >
              <Icon size={15} />
              <span className="hidden sm:inline">{tab.label}</span>
              {hasBadge && (
                <span className="absolute -top-1.5 -right-1.5 bg-amber-500 text-white text-[10px] font-black w-4 h-4 rounded-full flex items-center justify-center animate-pulse">
                  {pendingApprovals}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* ── Tab Content ─────────────────────────────────────────────────────── */}
      <div className="flex-1 min-w-0">
        <React.Suspense fallback={<TabLoader />}>
          {renderTab()}
        </React.Suspense>
      </div>
    </div>
  );
}
