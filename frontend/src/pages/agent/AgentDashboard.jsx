import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Zap, Home, AlertCircle, CheckCircle, Clock, X, Bell, CheckCircle2, XCircle, ChevronRight, Building2, User } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

// ─── Pop-up Notification Item ─────────────────────────────────────────────────
const NotificationPopup = ({ notif, onDismiss }) => {
  const isAccepted = notif.type === 'agent_reading_accepted';

  return (
    <div className={`flex items-start gap-3 p-4 rounded-2xl border shadow-xl animate-slide-in-right max-w-sm ${
      isAccepted
        ? 'bg-success/10 border-success/40 shadow-success/20'
        : 'bg-danger/10 border-danger/40 shadow-danger/20'
    }`}>
      <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
        isAccepted ? 'bg-success/20 text-success' : 'bg-danger/20 text-danger'
      }`}>
        {isAccepted ? <CheckCircle2 size={18} /> : <XCircle size={18} />}
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-bold text-white mb-0.5">{notif.title}</p>
        <p className="text-xs text-slate-300 leading-relaxed line-clamp-3">{notif.message}</p>
        <p className="text-xs text-slate-500 mt-1.5">
          {new Date(notif.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
        </p>
      </div>
      <button
        onClick={() => onDismiss(notif.id)}
        className="text-slate-400 hover:text-white transition-colors shrink-0"
      >
        <X size={16} />
      </button>
    </div>
  );
};

const AgentDashboard = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const user = (() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } })();

  const { data: stats, isLoading } = useQuery({
    queryKey: ['agent_dashboard_stats'],
    queryFn: async () => {
      try {
        const res = await axios.get('/energy/agent/dashboard-stats');
        return res.data;
      } catch (e) {
        return null;
      }
    },
    refetchInterval: 30000,
  });

  // Pop-up notifications for accept/reject decisions
  const { data: notifications = [] } = useQuery({
    queryKey: ['agent_reading_notifications'],
    queryFn: async () => {
      try {
        const res = await axios.get(`/energy/agent/reading-notifications?user_id=${user?.id || 1}`);
        return res.data;
      } catch (e) {
        return [];
      }
    },
    refetchInterval: 15000,
  });

  const dismissMutation = useMutation({
    mutationFn: (id) => axios.post(`/energy/agent/reading-notifications/${id}/seen`),
    onSuccess: () => queryClient.invalidateQueries(['agent_reading_notifications']),
  });

  const assignedBuildings = stats?.assignedBuildings || 0;
  const pendingGenReadings = stats?.pendingGenReadings || 0;
  const submittedGenToday = stats?.submittedGenToday || 0;
  const rejectedGen = stats?.rejectedGen || 0;

  const pendingAptReadings = stats?.pendingAptReadings || 0;
  const completedAptMonth = stats?.completedAptMonth || 0;
  const rejectedApt = stats?.rejectedApt || 0;
  const pendingSubTasks = stats?.pendingSubTasks || 0;

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">

      {/* ── Pop-up Notifications ─────────────────────────────────────────────── */}
      {notifications.length > 0 && (
        <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-3" style={{ maxWidth: '380px' }}>
          {notifications.slice(0, 5).map(notif => (
            <NotificationPopup
              key={notif.id}
              notif={notif}
              onDismiss={(id) => dismissMutation.mutate(id)}
            />
          ))}
        </div>
      )}

      {/* ── Header ────────────────────────────────────────────────────────────── */}
      <div className="mb-8">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">My Agent Dashboard</h1>
            <p className="text-muted">Welcome back{user?.name ? `, ${user.name}` : ''}. Here is the overview of your assigned readings.</p>
          </div>
          {notifications.length > 0 && (
            <div className="relative">
              <div className="w-10 h-10 bg-warning/20 border border-warning/30 rounded-full flex items-center justify-center text-warning animate-pulse">
                <Bell size={18} />
              </div>
              <span className="absolute -top-1 -right-1 w-5 h-5 bg-danger text-white text-xs font-bold rounded-full flex items-center justify-center">
                {notifications.length}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* ── Subscription Tasks Alert ──────────────────────────────────────────── */}
      {pendingSubTasks > 0 && (
        <div
          className="mb-8 p-5 bg-gradient-to-r from-primary/20 to-indigo-500/10 border border-primary/30 rounded-2xl flex items-center gap-4 cursor-pointer hover:from-primary/30 hover:border-primary/50 transition-all shadow-lg shadow-primary/10"
          onClick={() => navigate('/agent-subscriptions')}
        >
          <div className="w-12 h-12 bg-primary/20 text-primary rounded-xl flex items-center justify-center shrink-0">
            <Zap size={24} />
          </div>
          <div className="flex-1">
            <p className="text-white font-bold text-lg">{pendingSubTasks} Subscription Task{pendingSubTasks !== 1 ? 's' : ''} Need Attention!</p>
            <p className="text-sm text-slate-300">Generator subscriptions expiring in the next 5 days require meter readings.</p>
          </div>
          <ChevronRight size={20} className="text-primary shrink-0" />
        </div>
      )}

      {/* ── Generator Section ─────────────────────────────────────────────────── */}
      <div className="mb-10">
        <h2 className="text-xl font-bold text-white mb-4 flex items-center">
          <Zap className="me-2 text-warning" size={24} /> Generator Readings
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="glass-card p-6 border-l-4 border-indigo-500 shadow-lg hover:shadow-indigo-500/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Assigned Buildings</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : assignedBuildings}</p>
          </div>
          <div className="glass-card p-6 border-l-4 border-warning shadow-lg hover:shadow-warning/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Pending Today</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : pendingGenReadings}</p>
          </div>
          <div className="glass-card p-6 border-l-4 border-success shadow-lg hover:shadow-success/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Submitted Today</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : submittedGenToday}</p>
          </div>
          <div className="glass-card p-6 border-l-4 border-danger shadow-lg hover:shadow-danger/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Rejected Readings</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : rejectedGen}</p>
          </div>
        </div>
      </div>

      {/* ── Apartment Readings ────────────────────────────────────────────────── */}
      <div className="mb-10">
        <h2 className="text-xl font-bold text-white mb-4 flex items-center">
          <Home className="me-2 text-primary" size={24} /> Apartment Readings
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="glass-card p-6 border-l-4 border-indigo-500 shadow-lg hover:shadow-indigo-500/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Pending This Month</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : pendingAptReadings}</p>
          </div>
          <div className="glass-card p-6 border-l-4 border-success shadow-lg hover:shadow-success/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Completed This Month</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : completedAptMonth}</p>
          </div>
          <div
            className="glass-card p-6 border-l-4 border-primary shadow-lg hover:shadow-primary/20 transition-all cursor-pointer hover:scale-[1.02]"
            onClick={() => navigate('/agent-subscriptions')}
          >
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Sub. Tasks Due</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : pendingSubTasks}</p>
            <p className="text-xs text-primary mt-1">Click to view →</p>
          </div>
          <div className="glass-card p-6 border-l-4 border-danger shadow-lg hover:shadow-danger/20 transition-all">
            <h3 className="text-slate-400 text-sm font-bold uppercase mb-2">Rejected Readings</h3>
            <p className="text-3xl font-extrabold text-white">{isLoading ? '...' : rejectedApt}</p>
          </div>
        </div>
      </div>

      {/* ── Quick Actions ─────────────────────────────────────────────────────── */}
      <div>
        <h2 className="text-xl font-bold text-white mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[
            { label: 'Subscription Tasks', icon: Zap, path: '/agent-subscriptions', color: 'from-primary/20 to-indigo-600/10 border-primary/30 hover:border-primary/60', iconColor: 'text-primary', badge: pendingSubTasks },
            { label: 'Generator Readings', icon: Zap, path: '/agent-generators', color: 'from-warning/20 to-yellow-600/10 border-warning/30 hover:border-warning/60', iconColor: 'text-warning' },
            { label: 'Apartment Readings', icon: Home, path: '/agent-apartments', color: 'from-sky-500/20 to-blue-600/10 border-sky-500/30 hover:border-sky-500/60', iconColor: 'text-sky-400' },
          ].map(item => {
            const Icon = item.icon;
            return (
              <button
                key={item.path}
                onClick={() => navigate(item.path)}
                className={`relative glass-card p-5 rounded-2xl bg-gradient-to-br ${item.color} border transition-all text-left hover:scale-[1.02] active:scale-[0.98] shadow-lg`}
              >
                {item.badge > 0 && (
                  <span className="absolute top-3 right-3 w-6 h-6 bg-danger text-white text-xs font-bold rounded-full flex items-center justify-center animate-pulse">
                    {item.badge}
                  </span>
                )}
                <Icon size={28} className={`${item.iconColor} mb-3`} />
                <p className="text-white font-bold">{item.label}</p>
                <p className="text-xs text-slate-400 mt-1 flex items-center gap-1">Open <ChevronRight size={12} /></p>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
};

export default AgentDashboard;
