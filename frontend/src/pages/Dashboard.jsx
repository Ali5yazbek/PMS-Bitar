import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../api/axios';
import { useNavigate } from 'react-router-dom';
import { Calendar, AlertCircle, Sparkles, CheckCircle, Bell, ArrowRight, DollarSign, FileText, Zap, Shield, Activity, XCircle } from 'lucide-react';
import RentRenewalModal from '../components/RentRenewalModal';

const Dashboard = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const [activeCategory, setActiveCategory] = useState('All');
  
  // Modal State
  const [renewalModalOpen, setRenewalModalOpen] = useState(false);
  const [renewalProfileId, setRenewalProfileId] = useState(null);
  const [renewalTenantName, setRenewalTenantName] = useState('');
  
  const user = JSON.parse(localStorage.getItem('user')) || { name: 'User' };

  const { data: schedule, isLoading: schedLoading } = useQuery({
    queryKey: ['scheduleSummary'],
    queryFn: async () => {
      const res = await api.get('/schedule/summary');
      return res.data;
    }
  });

  const { data: finStats, isLoading: finLoading } = useQuery({
    queryKey: ['financialSummary'],
    queryFn: async () => {
      const res = await api.get('/dashboard/financial-summary');
      return res.data;
    }
  });

  const { data: collectionsData, isLoading: collLoading } = useQuery({
    queryKey: ['collections'],
    queryFn: async () => {
      const res = await api.get('/dashboard/collections');
      return res.data;
    }
  });

  const { data: alertsData, isLoading: alertsLoading } = useQuery({
    queryKey: ['alerts'],
    queryFn: async () => {
      const res = await api.get('/dashboard/alerts');
      return res.data;
    }
  });

  // 1. Financial Summary
  const financialCards = [
    { title: t('Total Rent Due'), value: finStats?.total_rent_due || 0, icon: DollarSign, color: 'text-blue-400', bg: 'bg-blue-500/10' },
    { title: t('Total Rent Collected'), value: finStats?.total_rent_collected || 0, icon: DollarSign, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { title: t('Outstanding Rent'), value: finStats?.outstanding_rent_balance || 0, icon: DollarSign, color: 'text-red-400', bg: 'bg-red-500/10' },
    { title: t('Unpaid Rent Invoices'), value: finStats?.unpaid_rent_invoices || 0, icon: FileText, color: 'text-orange-400', bg: 'bg-orange-500/10' },
    { title: t('Insurance Collected'), value: finStats?.insurance_collected || 0, icon: Shield, color: 'text-purple-400', bg: 'bg-purple-500/10' },
    { title: t('Electricity Collected'), value: finStats?.electricity_collected || 0, icon: Zap, color: 'text-yellow-400', bg: 'bg-yellow-500/10' },
    { title: t('Generator Collected'), value: finStats?.generator_collected || 0, icon: Activity, color: 'text-cyan-400', bg: 'bg-cyan-500/10' },
  ];

  // 2. Alerts & Expiring Items
  const alerts = alertsData?.alerts || [];
  
  // Get counts per category
  const categoryCounts = alerts.reduce((acc, alert) => {
    acc[alert.category] = (acc[alert.category] || 0) + 1;
    return acc;
  }, {});
  
  const alertCategories = ['All', ...Object.keys(categoryCounts)];

  const filteredAlerts = activeCategory === 'All' ? alerts : alerts.filter(a => a.category === activeCategory);

  const getPriorityClasses = (priority) => {
    if (priority === 'Critical') return 'bg-red-500/10 border-red-500/50 text-red-500';
    if (priority === 'Warning') return 'bg-orange-500/10 border-orange-500/50 text-orange-500';
    return 'bg-blue-500/10 border-blue-500/50 text-blue-500';
  };

  const getPriorityIcon = (priority) => {
    if (priority === 'Critical') return <XCircle size={20} className="text-red-500" />;
    if (priority === 'Warning') return <AlertCircle size={20} className="text-orange-500" />;
    return <AlertCircle size={20} className="text-blue-500" />;
  };

  // 3. Upcoming Schedule (Non-financial)
  const scheduleCards = [
    { title: t('schedule.card_ac_due'), value: schedule?.ac_due_today || 0, icon: Calendar, color: 'text-orange-400', bg: 'bg-orange-500/10' },
    { title: t('schedule.card_ac_overdue'), value: schedule?.ac_overdue || 0, icon: AlertCircle, color: 'text-red-400', bg: 'bg-red-500/10' },
    { title: t('schedule.card_ac_pending'), value: schedule?.ac_pending || 0, icon: CheckCircle, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { title: t('schedule.card_upcoming'), value: schedule?.upcoming_events || 0, icon: Bell, color: 'text-purple-400', bg: 'bg-purple-500/10' },
  ];

  const buildAiMessage = () => {
    if (!schedule) return null;
    let parts = [];
    if (schedule.ac_due_today > 0) parts.push(t('schedule.ai_item_ac_due', { count: schedule.ac_due_today }));
    if (schedule.ac_pending > 0) parts.push(t('schedule.ai_item_ac_pending', { count: schedule.ac_pending }));
    
    if (parts.length === 0) {
      return <p className="text-emerald-400 font-medium">{t('schedule.ai_all_caught_up')}</p>;
    }
    
    return (
      <ul className="list-disc pl-5 mt-4 space-y-2 text-slate-300">
        {parts.map((p, i) => <li key={i}>{p}</li>)}
      </ul>
    );
  };

  const formatCurrency = (val) => {
    return 'CFA ' + new Intl.NumberFormat('en-US').format(val || 0);
  };

  return (
    <div className="flex h-full w-full bg-background overflow-hidden relative">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <h1 className="text-3xl font-bold text-white mb-8">{t('dashboard.overview')}</h1>

        {/* Section 1: Financial Summary */}
        <div className="mb-10">
          <h2 className="text-xl font-bold text-white mb-4">{t('Financial Summary')} <span className="text-sm font-normal text-muted">({t('Current Month')})</span></h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {finLoading ? (
              Array.from({ length: 7 }).map((_, i) => (
                <div key={i} className="glass-card p-5 flex items-center space-x-4 animate-pulse">
                  <div className="bg-slate-700/50 w-12 h-12 rounded-xl"></div>
                  <div className="flex-1 space-y-2">
                    <div className="h-3 bg-slate-700/50 rounded w-2/3"></div>
                    <div className="h-5 bg-slate-700/50 rounded w-1/2"></div>
                  </div>
                </div>
              ))
            ) : (
              financialCards.map((s, idx) => {
                const Icon = s.icon;
                return (
                  <div key={idx} className="glass-card p-5 flex items-center space-x-4 hover-card group">
                    <div className={`${s.bg} p-3 rounded-xl group-hover:scale-110 transition-transform`}>
                      <Icon size={24} className={s.color} />
                    </div>
                    <div>
                      <p className="text-xs font-medium text-muted">{s.title}</p>
                      <p className="text-xl font-bold text-white mt-1">
                        {s.title === 'Unpaid Rent Invoices' ? s.value : formatCurrency(s.value)}
                      </p>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* Section 1.5: Today's Collections */}
        <div className="mb-10">
          <h2 className="text-xl font-bold text-white mb-4">{t('Today\'s Collections')} <span className="text-sm font-normal text-muted">({t('By Payment Method')})</span></h2>
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-4">
            {collLoading ? (
              Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="glass-card p-5 border-l-4 border-slate-700 flex items-center animate-pulse">
                  <div className="space-y-2 w-full">
                    <div className="h-3 bg-slate-700/50 rounded w-1/2"></div>
                    <div className="h-5 bg-slate-700/50 rounded w-1/3"></div>
                  </div>
                </div>
              ))
            ) : collectionsData?.payment_methods_breakdown?.length > 0 ? (
              collectionsData.payment_methods_breakdown.map((pm, idx) => (
                <div key={idx} className="glass-card p-5 border-l-4 border-l-primary flex items-center justify-between">
                  <div>
                    <p className="text-xs font-medium text-muted">{pm.payment_method || 'Unknown'}</p>
                    <p className="text-lg font-bold text-emerald-400 mt-1">{formatCurrency(pm.total)}</p>
                  </div>
                </div>
              ))
            ) : (
              <div className="col-span-full glass-card p-5 text-center text-muted">{t('No collections recorded today.')}</div>
            )}
          </div>
        </div>

        {/* Section 2: Alerts & Expiring Items */}
        <div className="mb-10">
          <h2 className="text-xl font-bold text-white mb-4 flex items-center">
            {t('Alerts & Action Center')}
            {alerts.length > 0 && <span className="ml-3 px-2.5 py-0.5 bg-red-500/20 text-red-400 text-sm rounded-full">{alerts.length}</span>}
          </h2>
          
          {/* Category Badges */}
          <div className="flex space-x-3 mb-6 overflow-x-auto hide-scrollbar pb-2">
            {alertsLoading ? (
              <div className="flex space-x-3">
                <div className="h-8 w-20 bg-slate-700/50 rounded-xl animate-pulse"></div>
                <div className="h-8 w-24 bg-slate-700/50 rounded-xl animate-pulse"></div>
              </div>
            ) : (
              alertCategories.map(cat => {
                const count = cat === 'All' ? alerts.length : categoryCounts[cat];
                const isActive = activeCategory === cat;
                return (
                  <button 
                    key={cat}
                    onClick={() => setActiveCategory(cat)}
                    className={`flex items-center space-x-2 px-4 py-2 rounded-xl text-sm font-medium transition-all whitespace-nowrap ${isActive ? 'bg-primary text-white shadow-lg shadow-primary/30' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                  >
                    <span>{cat}</span>
                    <span className={`px-2 py-0.5 rounded-full text-xs ${isActive ? 'bg-white/20 text-white' : 'bg-slate-700 text-slate-400'}`}>{count}</span>
                  </button>
                );
              })
            )}
          </div>

          {/* Alerts List */}
          {alertsLoading ? (
            <div className="space-y-3">
              {Array.from({ length: 3 }).map((_, i) => (
                <div key={i} className="p-4 rounded-xl border border-slate-700/50 flex flex-col md:flex-row md:items-center justify-between gap-4 animate-pulse bg-slate-800/30">
                  <div className="flex items-start space-x-3 w-full">
                    <div className="w-5 h-5 rounded-full bg-slate-700/50 flex-shrink-0"></div>
                    <div className="space-y-2 w-full">
                      <div className="h-4 bg-slate-700/50 rounded w-1/3"></div>
                      <div className="h-3 bg-slate-700/50 rounded w-1/2"></div>
                    </div>
                  </div>
                  <div className="h-8 bg-slate-700/50 rounded w-24"></div>
                </div>
              ))}
            </div>
          ) : filteredAlerts.length > 0 ? (
            <div className="space-y-3">
              {filteredAlerts.map(alert => (
                <div key={alert.id} className={`p-4 rounded-xl border flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm ${getPriorityClasses(alert.priority)}`}>
                  <div className="flex items-start space-x-3">
                    <div className="mt-1 flex-shrink-0">
                      {getPriorityIcon(alert.priority)}
                    </div>
                    <div>
                      <div className="flex items-center space-x-2">
                        <span className="font-bold text-white">{t(alert.title)}</span>
                        <span className="text-xs px-2 py-0.5 rounded border border-current opacity-80">{t(alert.priority)}</span>
                      </div>
                      <p className="text-sm opacity-90 mt-1">{t(alert.message)}</p>
                      <div className="flex items-center space-x-3 mt-2 text-xs opacity-70">
                        <span>{t('Apt')}: {alert.apartment_number}</span>
                        <span>•</span>
                        <span>{t('Tenant')}: {alert.tenant_name || t('No Active Tenant')}</span>
                      </div>
                    </div>
                  </div>
                  <button 
                    onClick={() => {
                      if (alert.id.startsWith('rent_prof_r_')) {
                        setRenewalProfileId(alert.related_record_id);
                        setRenewalTenantName(alert.tenant_name);
                        setRenewalModalOpen(true);
                      } else {
                        navigate(alert.action_url);
                      }
                    }}
                    className="flex-shrink-0 px-5 py-2 bg-white/10 hover:bg-white/20 rounded-lg text-sm font-medium transition-colors border border-white/10 flex items-center"
                  >
                    {alert.id.startsWith('rent_prof_r_') ? t('Decide Action') : t('View Details')}
                    <ArrowRight size={16} className="ml-2" />
                  </button>
                </div>
              ))}
            </div>
          ) : (
            <div className="glass-card p-8 text-center text-muted flex flex-col items-center">
              <CheckCircle size={48} className="text-emerald-500/20 mb-4" />
              <p>{t("No alerts in this category. You're all caught up!")}</p>
            </div>
          )}
        </div>

        {/* Section 3: Upcoming Schedule */}
        <div>
          <h2 className="text-xl font-bold text-white mb-4">{t('Upcoming Schedule')}</h2>
          
          <div className="glass-card p-6 mb-6 relative overflow-hidden group">
            <div className="absolute -top-10 -right-10 w-40 h-40 bg-indigo-500/20 blur-3xl rounded-full"></div>
            <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-purple-500/20 blur-3xl rounded-full"></div>
            
            <div className="relative z-10 flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
              <div className="flex items-start space-x-4">
                <div className="bg-indigo-500/20 p-3 rounded-xl flex-shrink-0">
                  <Sparkles className="text-indigo-400" size={28} />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-white mb-2">{t('schedule.ai_greeting', { name: user.name.split(' ')[0] })}</h2>
                  {buildAiMessage()}
                </div>
              </div>
              <button 
                onClick={() => navigate('/schedule')}
                className="bg-indigo-500 hover:bg-indigo-600 text-white px-5 py-2.5 rounded-xl transition-colors shadow-lg shadow-indigo-500/20 flex items-center space-x-2 whitespace-nowrap flex-shrink-0"
              >
                <Calendar size={18} className="mr-1" />
                <span>{t('Open Calendar')}</span>
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {schedLoading ? (
              Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="glass-card p-5 flex items-center space-x-4 animate-pulse">
                  <div className="bg-slate-700/50 w-12 h-12 rounded-xl"></div>
                  <div className="flex-1 space-y-2">
                    <div className="h-3 bg-slate-700/50 rounded w-1/2"></div>
                    <div className="h-6 bg-slate-700/50 rounded w-1/4"></div>
                  </div>
                </div>
              ))
            ) : (
              scheduleCards.map((s, idx) => {
                const Icon = s.icon;
                return (
                  <div key={idx} className="glass-card p-5 flex items-center space-x-4 hover-card group cursor-pointer" onClick={() => navigate('/schedule')}>
                    <div className={`${s.bg} p-3 rounded-xl group-hover:scale-110 transition-transform`}>
                      <Icon size={24} className={s.color} />
                    </div>
                    <div>
                      <p className="text-xs font-medium text-muted">{s.title}</p>
                      <p className="text-2xl font-bold text-white mt-1">{s.value}</p>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

      </div>

      <RentRenewalModal 
        isOpen={renewalModalOpen}
        onClose={() => setRenewalModalOpen(false)}
        profileId={renewalProfileId}
        tenantName={renewalTenantName}
      />
    </div>
  );
};

export default Dashboard;

