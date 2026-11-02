import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { 
  Zap, 
  Home, 
  DollarSign, 
  Calendar, 
  Clock, 
  RefreshCw, 
  PlusCircle, 
  CreditCard, 
  Search, 
  Printer, 
  Gauge, 
  ArrowRight, 
  ArrowLeft, 
  Check, 
  Sparkles, 
  AlertCircle, 
  UserCheck, 
  CheckCircle2 
} from 'lucide-react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import InteractiveCurrency from './common/InteractiveCurrency';

const TenantBillingDashboard = ({ 
  tenant, 
  electricitySubscription, 
  latestReading, 
  electricityInvoices, 
  elecFilter,
  setElecFilter,
  elecSearch,
  setElecSearch,
  onPayInvoice, 
  onPrintInvoice,
  onPrintAll 
}) => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('Plan');
  
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const isAgent = user.role === 'agent' || user.role === 'Agent';
  const canEditFee = ['admin', 'super_admin', 'manager', 'Admin', 'Super Admin', 'Manager'].includes(user.role);

  // Global settings for exchange rate
  const { data: settings } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => (await api.get('/global-settings')).data 
  });
  const exchangeRate = settings?.usd_to_cfa ? Number(settings.usd_to_cfa) : 600;

  // Auto-calculated monthly dates
  const getTodayStr = () => new Date().toISOString().split('T')[0];
  const getNextMonthStr = () => {
    const d = new Date();
    d.setDate(d.getDate() + 30);
    return d.toISOString().split('T')[0];
  };

  // Determine if a real, valid plan is currently active
  const hasActivePlan = Boolean(
    electricitySubscription && 
    electricitySubscription.status !== 'None' && 
    electricitySubscription.status !== 'Inactive' && 
    electricitySubscription.id && 
    electricitySubscription.type && 
    electricitySubscription.type !== ''
  );

  // Wizard state for smart onboarding
  const [showWizard, setShowWizard] = useState(false);
  const [wizardStep, setWizardStep] = useState('welcome'); // 'welcome' | 'choose' | 'configure_meter' | 'configure_monthly'
  const [wizardData, setWizardData] = useState({
    type: 'Meter',
    starting_reading: '',
    price_per_kwh: '250',
    monthly_fee: '',
    start_date: getTodayStr(),
    end_date: getNextMonthStr()
  });
  const [monthlyUSD, setMonthlyUSD] = useState('');

  // Meter Reading Sub-Tab form
  const [meterForm, setMeterForm] = useState({ 
    previous_reading: latestReading?.latest_reading || electricitySubscription?.last_meter_reading || 0, 
    current_reading: '', 
    price_per_kwh: electricitySubscription?.price_per_kwh || 250,
    end_date: getTodayStr() 
  });

  const [switchPlanModal, setSwitchPlanModal] = useState(false);
  const [switchPlanData, setSwitchPlanData] = useState({
    type: 'Meter',
    price_per_kwh: electricitySubscription?.price_per_kwh || '250',
    initial_reading: latestReading?.latest_reading || ''
  });

  const [editFeeMode, setEditFeeMode] = useState(false);
  const [newFee, setNewFee] = useState(electricitySubscription?.monthly_fee || '');

  const getStatusColor = (status) => {
    switch (status) {
      case 'Paid': return 'bg-success/20 text-success border border-success/30';
      case 'Unpaid': return 'bg-danger/20 text-danger border border-danger/30';
      case 'Partial': return 'bg-warning/20 text-warning border border-warning/30';
      case 'Partially Paid': return 'bg-warning/20 text-warning border border-warning/30';
      default: return 'bg-slate-800 text-slate-300 border border-slate-600';
    }
  };

  // Setup / Save Electricity Plan Mutation
  const setupPlanMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${tenant.apartment_id}/subscriptions`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['latestReading', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setShowWizard(false);
      setWizardStep('welcome');
      alert('Electricity plan configured successfully!');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to configure electricity plan');
    }
  });

  const switchPlanMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${tenant.apartment_id}/subscriptions/${electricitySubscription.id}/switch-plan`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setSwitchPlanModal(false);
      alert('Plan switched successfully. Prorated invoice generated.');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to switch plan');
    }
  });

  const submitReadingMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${tenant.apartment_id}/meter-readings`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['latestReading', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setMeterForm({ ...meterForm, current_reading: '' });
      setActiveTab('Invoices');
      alert('Meter reading submitted and invoice generated successfully.');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to submit reading');
    }
  });

  const updateFeeMutation = useMutation({
    mutationFn: (fee) => api.put(`/energy/apartments/${tenant.apartment_id}/subscriptions/${electricitySubscription.id}/fee`, { monthly_fee: fee }),
    onSuccess: () => {
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setEditFeeMode(false);
      alert('Monthly fee updated successfully.');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to update fee');
    }
  });

  const handleSwitchPlan = (e) => {
    e.preventDefault();
    if (window.confirm('Are you sure you want to switch to a Meter plan mid-cycle? This will generate a prorated invoice for the days used.')) {
      switchPlanMutation.mutate(switchPlanData);
    }
  };

  const handleSubmitReading = (e) => {
    e.preventDefault();
    if (Number(meterForm.current_reading) <= Number(meterForm.previous_reading)) {
      alert('Current reading must be strictly greater than the previous reading.');
      return;
    }
    submitReadingMutation.mutate(meterForm);
  };

  // Connected Currency Handlers for Setup Wizard
  const handleMonthlyCFAChange = (val) => {
    setWizardData(prev => ({ ...prev, monthly_fee: val }));
    if (val === '') {
      setMonthlyUSD('');
    } else {
      const num = parseFloat(val);
      if (!isNaN(num)) setMonthlyUSD((num / exchangeRate).toFixed(2));
    }
  };

  const handleMonthlyUSDChange = (val) => {
    setMonthlyUSD(val);
    if (val === '') {
      setWizardData(prev => ({ ...prev, monthly_fee: '' }));
    } else {
      const num = parseFloat(val);
      if (!isNaN(num)) setWizardData(prev => ({ ...prev, monthly_fee: Math.round(num * exchangeRate).toString() }));
    }
  };

  const handleConfirmMeterPlan = (e) => {
    e.preventDefault();
    if (!wizardData.starting_reading || parseFloat(wizardData.starting_reading) < 0) {
      alert('Please enter a valid starting meter reading (e.g. 0 or the current meter counter).');
      return;
    }
    setupPlanMutation.mutate({
      apartment_id: tenant.apartment_id,
      type: 'Meter',
      starting_reading: wizardData.starting_reading,
      price_per_kwh: wizardData.price_per_kwh,
      start_date: wizardData.start_date,
      end_date: wizardData.end_date,
      status: 'Active'
    });
  };

  const handleConfirmMonthlyPlan = (e) => {
    e.preventDefault();
    if (!wizardData.monthly_fee || parseFloat(wizardData.monthly_fee) <= 0) {
      alert('Please enter a valid monthly fee amount.');
      return;
    }
    setupPlanMutation.mutate({
      apartment_id: tenant.apartment_id,
      type: 'Fixed Subscription',
      monthly_fee: wizardData.monthly_fee,
      start_date: wizardData.start_date,
      end_date: wizardData.end_date,
      status: 'Active'
    });
  };

  return (
    <div className="space-y-6">
      {/* Dashboard Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/30 text-warning shadow-lg shadow-amber-950/40">
            <Zap size={26} />
          </div>
          <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Tenant Billing Dashboard</h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Manage electricity metering, monthly subscription plans, and billing history
            </p>
          </div>
        </div>

        {/* Reconfigure button if plan already active */}
        {hasActivePlan && !showWizard && canEditFee && (
          <button
            onClick={() => {
              setWizardData({
                type: electricitySubscription.type === 'Meter' ? 'Meter' : 'Fixed Subscription',
                starting_reading: latestReading?.latest_reading || electricitySubscription.last_meter_reading || '',
                price_per_kwh: electricitySubscription.price_per_kwh || '250',
                monthly_fee: electricitySubscription.monthly_fee || '',
                start_date: getTodayStr(),
                end_date: getNextMonthStr()
              });
              setWizardStep('choose');
              setShowWizard(true);
            }}
            className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white border border-slate-700 rounded-xl text-xs font-semibold transition-all flex items-center gap-2"
          >
            <RefreshCw size={14} />
            <span>Change / Reconfigure Plan</span>
          </button>
        )}
      </div>

      {/* Internal Tabs */}
      <div className="flex gap-2 sm:gap-4 border-b border-slate-700/50 pb-2">
        {[
          { id: 'Plan', label: 'Subscription Plan', icon: Zap },
          { id: 'Meter', label: 'Meter Readings', icon: Gauge },
          { id: 'Invoices', label: 'Invoice History', icon: DollarSign }
        ].map(tab => {
          const Icon = tab.icon;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-2.5 font-medium rounded-xl text-sm transition-all flex items-center gap-2 ${
                activeTab === tab.id 
                  ? 'text-warning bg-amber-500/10 border border-amber-500/30 shadow-sm' 
                  : 'text-slate-400 hover:text-white hover:bg-slate-800/40'
              }`}
            >
              <Icon size={16} />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Main Tab Content */}
      <div className="glass-card p-6 min-h-[420px]">
        
        {/* ==================== PLAN TAB ==================== */}
        {activeTab === 'Plan' && (
          <div>
            {/* Condition A: No plan configured OR Wizard open -> SMART ONBOARDING WIZARD */}
            {(!hasActivePlan || showWizard) ? (
              <div className="max-w-3xl">
                
                {/* 1. WELCOME STEP */}
                {wizardStep === 'welcome' && (
                  <div className="p-8 rounded-2xl bg-gradient-to-br from-slate-900 via-slate-800/80 to-amber-950/20 border border-amber-500/30 relative overflow-hidden shadow-2xl">
                    <div className="absolute top-0 right-0 w-80 h-80 bg-amber-500/5 rounded-bl-full pointer-events-none blur-3xl" />
                    
                    <div className="max-w-xl space-y-4">
                      <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/30 text-amber-400 text-xs font-semibold uppercase tracking-wider">
                        <Sparkles size={14} /> New Tenant Electricity Setup
                      </div>
                      
                      <h3 className="text-2xl sm:text-3xl font-bold text-white tracking-tight">
                        Let's Start Electricity Billing
                      </h3>
                      
                      <p className="text-slate-300 text-sm leading-relaxed">
                        There is currently no active electricity billing plan configured for{' '}
                        <strong className="text-white font-semibold">
                          {tenant?.full_name || tenant?.name || 'this tenant'}
                        </strong>{' '}
                        ({tenant?.apartment_code ? `Unit ${tenant.apartment_code}` : 'Apartment'}).
                        Select your preferred billing method to get the cycle started!
                      </p>

                      <div className="pt-2">
                        <button
                          onClick={() => setWizardStep('choose')}
                          className="bg-gradient-to-r from-warning to-amber-500 hover:from-amber-400 hover:to-warning text-slate-950 px-6 py-3.5 rounded-xl font-bold text-sm shadow-lg shadow-warning/25 hover:shadow-warning/40 transition-all flex items-center gap-2.5 cursor-pointer"
                        >
                          <Zap size={18} className="fill-slate-950" />
                          <span>Let's Start</span>
                          <ArrowRight size={16} />
                        </button>
                      </div>
                    </div>
                  </div>
                )}

                {/* 2. CHOOSE METHOD STEP */}
                {wizardStep === 'choose' && (
                  <div className="space-y-6 animate-in fade-in duration-200">
                    <div className="flex items-center justify-between">
                      <div>
                        <h3 className="text-xl font-bold text-white">Choose Electricity Billing Method</h3>
                        <p className="text-xs text-slate-400 mt-1">
                          Do you want Meter Reading (per kWh) or a Fixed Monthly Subscription?
                        </p>
                      </div>
                      {showWizard && hasActivePlan && (
                        <button 
                          onClick={() => setShowWizard(false)}
                          className="text-xs text-slate-400 hover:text-white px-3 py-1.5 rounded-lg bg-slate-800"
                        >
                          Cancel
                        </button>
                      )}
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                      {/* Option 1: Meter Reading */}
                      <div 
                        onClick={() => {
                          setWizardData(prev => ({ ...prev, type: 'Meter' }));
                          setWizardStep('configure_meter');
                        }}
                        className="p-6 rounded-2xl bg-slate-800/50 hover:bg-slate-800/90 border border-slate-700 hover:border-amber-500/60 transition-all cursor-pointer group flex flex-col justify-between shadow-xl"
                      >
                        <div>
                          <div className="flex justify-between items-start mb-4">
                            <div className="p-3 rounded-xl bg-amber-500/10 border border-amber-500/20 text-warning group-hover:scale-105 transition-transform">
                              <Gauge size={28} />
                            </div>
                            <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30 uppercase tracking-wider">
                              Pay Per kWh
                            </span>
                          </div>
                          <h4 className="text-lg font-bold text-white mb-2 group-hover:text-amber-400 transition-colors">
                            Meter Reading
                          </h4>
                          <p className="text-xs text-slate-300 leading-relaxed mb-4">
                            Billed based on actual kilowatt-hour consumption. Set a starting meter reading now; at the end of the month, the utility agent visits and adds the closing reading.
                          </p>
                        </div>
                        <div className="pt-4 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-warning">
                          <span>Configure Starting Counter</span>
                          <ArrowRight size={16} className="group-hover:translate-x-1 transition-transform" />
                        </div>
                      </div>

                      {/* Option 2: Monthly Subscription */}
                      <div 
                        onClick={() => {
                          setWizardData(prev => ({ ...prev, type: 'Fixed Subscription' }));
                          setWizardStep('configure_monthly');
                        }}
                        className="p-6 rounded-2xl bg-slate-800/50 hover:bg-slate-800/90 border border-slate-700 hover:border-indigo-500/60 transition-all cursor-pointer group flex flex-col justify-between shadow-xl"
                      >
                        <div>
                          <div className="flex justify-between items-start mb-4">
                            <div className="p-3 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 group-hover:scale-105 transition-transform">
                              <Calendar size={28} />
                            </div>
                            <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 uppercase tracking-wider">
                              Flat Monthly
                            </span>
                          </div>
                          <h4 className="text-lg font-bold text-white mb-2 group-hover:text-indigo-400 transition-colors">
                            Monthly Subscription
                          </h4>
                          <p className="text-xs text-slate-300 leading-relaxed mb-4">
                            Direct flat monthly subscription fee billed every cycle. Cycle start and end dates are automatically set for the month with no meter visits required.
                          </p>
                        </div>
                        <div className="pt-4 border-t border-slate-700/60 flex items-center justify-between text-xs font-semibold text-indigo-300">
                          <span>Set Monthly Rate & Dates</span>
                          <ArrowRight size={16} className="group-hover:translate-x-1 transition-transform" />
                        </div>
                      </div>
                    </div>
                  </div>
                )}

                {/* 3A. CONFIGURE METER READING */}
                {wizardStep === 'configure_meter' && (
                  <form onSubmit={handleConfirmMeterPlan} className="space-y-6 animate-in fade-in duration-200">
                    <div className="flex items-center justify-between pb-4 border-b border-slate-700/60">
                      <div className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={() => setWizardStep('choose')}
                          className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-colors"
                        >
                          <ArrowLeft size={18} />
                        </button>
                        <div>
                          <h3 className="text-lg font-bold text-white">Setup Meter Reading Plan</h3>
                          <p className="text-xs text-slate-400">Establish the baseline counter and automatic month cycle</p>
                        </div>
                      </div>
                      <span className="text-xs px-2.5 py-1 rounded-full bg-amber-500/10 text-amber-300 border border-amber-500/20 font-medium">
                        Usage-Based
                      </span>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
                      {/* Starting Meter Reading */}
                      <div className="sm:col-span-2 p-4 rounded-xl bg-slate-800/40 border border-slate-700/70 space-y-2">
                        <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                          <Gauge size={14} className="text-warning" />
                          <span>Starting Meter Reading (kWh)</span>
                          <span className="text-danger">*</span>
                        </label>
                        <input
                          type="number"
                          step="any"
                          required
                          autoFocus
                          placeholder="e.g. 12450.5"
                          value={wizardData.starting_reading}
                          onChange={e => setWizardData({ ...wizardData, starting_reading: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-700 focus:border-warning focus:ring-1 focus:ring-warning text-white rounded-xl px-4 py-3 text-lg font-bold outline-none"
                        />
                        <p className="text-[11px] text-slate-400 leading-relaxed pt-1">
                          💡 <strong>Starting Baseline:</strong> This establishes the opening meter counter for the tenant with <strong>0 CFA charge today</strong>. At the end of the month, the utility agent visits, reads the meter, and records the new count to calculate the usage bill.
                        </p>
                      </div>

                      {/* Price Per kWh */}
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                          Price per kWh (CFA) <span className="text-danger">*</span>
                        </label>
                        <input
                          type="number"
                          step="any"
                          required
                          value={wizardData.price_per_kwh}
                          onChange={e => setWizardData({ ...wizardData, price_per_kwh: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-700 focus:border-warning rounded-xl px-4 py-2.5 text-white text-sm font-semibold outline-none"
                        />
                      </div>

                      {/* Auto Cycle End (Agent Check Date) */}
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                          <Clock size={13} className="text-amber-400" />
                          <span>Next Agent Reading Date</span>
                        </label>
                        <input
                          type="date"
                          required
                          value={wizardData.end_date}
                          onChange={e => setWizardData({ ...wizardData, end_date: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 text-sm font-medium outline-none"
                        />
                      </div>
                    </div>

                    {/* Agent Notice Card */}
                    <div className="p-4 rounded-xl bg-amber-500/10 border border-amber-500/20 flex items-start gap-3">
                      <Calendar size={18} className="text-warning shrink-0 mt-0.5" />
                      <div className="text-xs text-amber-200 leading-relaxed">
                        <strong>Automatic Month Schedule:</strong> Start date is set to <strong>{wizardData.start_date}</strong>. At the end of the month (<strong>{wizardData.end_date}</strong>), the utility agent will visit the apartment as normal to inspect the physical meter and submit the closing reading.
                      </div>
                    </div>

                    {/* Submit Actions */}
                    <div className="flex justify-end gap-3 pt-4 border-t border-slate-700/60">
                      <button
                        type="button"
                        onClick={() => setWizardStep('choose')}
                        className="px-5 py-2.5 rounded-xl text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 transition-colors text-sm font-medium"
                      >
                        Back
                      </button>
                      <button
                        type="submit"
                        disabled={setupPlanMutation.isPending || !wizardData.starting_reading}
                        className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-warning to-amber-500 hover:from-amber-400 hover:to-warning text-slate-950 font-bold text-sm shadow-lg shadow-warning/20 disabled:opacity-50 transition-all flex items-center gap-2"
                      >
                        {setupPlanMutation.isPending ? (
                          <>
                            <div className="w-4 h-4 border-2 border-slate-950/30 border-t-slate-950 rounded-full animate-spin" />
                            <span>Setting Starting Meter...</span>
                          </>
                        ) : (
                          <>
                            <Check size={16} />
                            <span>Confirm & Set Starting Meter</span>
                          </>
                        )}
                      </button>
                    </div>
                  </form>
                )}

                {/* 3B. CONFIGURE MONTHLY SUBSCRIPTION */}
                {wizardStep === 'configure_monthly' && (
                  <form onSubmit={handleConfirmMonthlyPlan} className="space-y-6 animate-in fade-in duration-200">
                    <div className="flex items-center justify-between pb-4 border-b border-slate-700/60">
                      <div className="flex items-center gap-3">
                        <button
                          type="button"
                          onClick={() => setWizardStep('choose')}
                          className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-colors"
                        >
                          <ArrowLeft size={18} />
                        </button>
                        <div>
                          <h3 className="text-lg font-bold text-white">Setup Fixed Monthly Subscription</h3>
                          <p className="text-xs text-slate-400">Directly add the monthly rate and auto-calculated cycle dates</p>
                        </div>
                      </div>
                      <span className="text-xs px-2.5 py-1 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20 font-medium">
                        Flat Rate
                      </span>
                    </div>

                    <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/70 space-y-3">
                      <div className="flex items-center justify-between">
                        <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                          <DollarSign size={14} className="text-emerald-400" />
                          <span>Monthly Fee Amount</span>
                          <span className="text-danger">*</span>
                        </label>
                        <span className="text-[11px] font-medium px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                          1 USD = {exchangeRate.toLocaleString()} CFA
                        </span>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        {/* CFA Primary */}
                        <div>
                          <span className="text-[11px] text-slate-400 mb-1 block">In CFA (Primary)</span>
                          <div className="relative">
                            <input
                              type="number"
                              step="any"
                              required
                              autoFocus
                              placeholder="e.g. 35000"
                              value={wizardData.monthly_fee}
                              onChange={e => handleMonthlyCFAChange(e.target.value)}
                              className="w-full bg-slate-900 border border-slate-700 focus:border-indigo-500 rounded-xl pl-3 pr-12 py-2.5 text-white text-base font-bold outline-none"
                            />
                            <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400 text-xs font-bold">
                              CFA
                            </div>
                          </div>
                        </div>

                        {/* USD Equivalent */}
                        <div>
                          <span className="text-[11px] text-slate-400 mb-1 block">In USD ($)</span>
                          <div className="relative">
                            <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none text-slate-400 font-semibold text-sm">
                              $
                            </div>
                            <input
                              type="number"
                              step="any"
                              placeholder="0.00"
                              value={monthlyUSD}
                              onChange={e => handleMonthlyUSDChange(e.target.value)}
                              className="w-full bg-slate-900 border border-slate-700 focus:border-indigo-500 rounded-xl pl-8 pr-3 py-2.5 text-white text-sm font-medium outline-none"
                            />
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Auto-selected Start and End Dates */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                          <Calendar size={13} className="text-primary" />
                          <span>Cycle Start Date</span>
                        </label>
                        <input
                          type="date"
                          required
                          value={wizardData.start_date}
                          onChange={e => setWizardData({ ...wizardData, start_date: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 text-sm font-medium outline-none"
                        />
                      </div>
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                          <Calendar size={13} className="text-primary" />
                          <span>Next Billing Date (Cycle End)</span>
                        </label>
                        <input
                          type="date"
                          required
                          value={wizardData.end_date}
                          onChange={e => setWizardData({ ...wizardData, end_date: e.target.value })}
                          className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 text-sm font-medium outline-none"
                        />
                      </div>
                    </div>

                    <div className="p-4 rounded-xl bg-indigo-500/10 border border-indigo-500/20 flex items-start gap-3">
                      <CheckCircle2 size={18} className="text-indigo-400 shrink-0 mt-0.5" />
                      <div className="text-xs text-indigo-200 leading-relaxed">
                        <strong>Automatic Monthly Cycle:</strong> Direct setup adds the start date (<strong>{wizardData.start_date}</strong>) and end date (<strong>{wizardData.end_date}</strong>). An initial flat subscription invoice will be generated directly.
                      </div>
                    </div>

                    {/* Submit Actions */}
                    <div className="flex justify-end gap-3 pt-4 border-t border-slate-700/60">
                      <button
                        type="button"
                        onClick={() => setWizardStep('choose')}
                        className="px-5 py-2.5 rounded-xl text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700 transition-colors text-sm font-medium"
                      >
                        Back
                      </button>
                      <button
                        type="submit"
                        disabled={setupPlanMutation.isPending || !wizardData.monthly_fee}
                        className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-primary to-indigo-600 hover:from-indigo-500 hover:to-primary text-white font-bold text-sm shadow-lg shadow-primary/25 disabled:opacity-50 transition-all flex items-center gap-2"
                      >
                        {setupPlanMutation.isPending ? (
                          <>
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                            <span>Activating Monthly Plan...</span>
                          </>
                        ) : (
                          <>
                            <Check size={16} />
                            <span>Confirm & Activate Monthly Plan</span>
                          </>
                        )}
                      </button>
                    </div>
                  </form>
                )}
              </div>
            ) : (
              /* Condition B: Plan IS ACTIVE and not in wizard mode -> DISPLAY CLEAN PLAN DETAILS */
              <div className="max-w-2xl space-y-6">
                <div className="flex items-center justify-between">
                  <h3 className="text-xl font-bold text-white">Current Electricity Subscription</h3>
                  <span className={`px-3 py-1 rounded-full text-xs font-semibold ${
                    electricitySubscription.status === 'Active' ? 'bg-success/20 text-success border border-success/30' : 'bg-slate-800 text-slate-300'
                  }`}>
                    {electricitySubscription.status || 'Active'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  {/* Plan Type */}
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/70">
                    <span className="text-slate-400 text-xs block mb-1 uppercase font-semibold">Plan Type</span>
                    <span className="text-white font-bold text-base flex items-center gap-2">
                      {electricitySubscription.type === 'Meter' ? (
                        <>
                          <Gauge size={18} className="text-warning" />
                          <span>Metered (Usage-Based)</span>
                        </>
                      ) : (
                        <>
                          <Calendar size={18} className="text-indigo-400" />
                          <span>Fixed Monthly Subscription</span>
                        </>
                      )}
                    </span>
                  </div>

                  {/* Fee or Price per kWh */}
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/70 relative">
                    {electricitySubscription.type === 'Meter' ? (
                      <>
                        <span className="text-slate-400 text-xs block mb-1 uppercase font-semibold">Price per kWh</span>
                        <span className="text-amber-400 font-bold text-base">
                          {electricitySubscription.price_per_kwh || 250} CFA / kWh
                        </span>
                      </>
                    ) : (
                      <>
                        <div className="flex justify-between items-center mb-1">
                          <span className="text-slate-400 text-xs uppercase font-semibold">Monthly Fee</span>
                          {canEditFee && !editFeeMode && (
                            <button 
                              onClick={() => setEditFeeMode(true)}
                              className="text-xs bg-slate-700 hover:bg-slate-600 px-2 py-0.5 rounded text-slate-300 transition-colors"
                            >
                              Edit
                            </button>
                          )}
                        </div>
                        {editFeeMode ? (
                          <div className="flex gap-2 items-center">
                            <input 
                              type="number" 
                              value={newFee} 
                              onChange={e => setNewFee(e.target.value)} 
                              className="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-white w-full max-w-[120px] text-sm"
                            />
                            <button 
                              onClick={() => updateFeeMutation.mutate(newFee)}
                              disabled={updateFeeMutation.isLoading}
                              className="bg-success/20 text-success hover:bg-success hover:text-white px-2 py-1 rounded text-xs transition-colors font-bold"
                            >
                              Save
                            </button>
                            <button 
                              onClick={() => {
                                setEditFeeMode(false);
                                setNewFee(electricitySubscription?.monthly_fee || '');
                              }}
                              className="bg-slate-700 text-slate-300 hover:bg-slate-600 px-2 py-1 rounded text-xs transition-colors"
                            >
                              Cancel
                            </button>
                          </div>
                        ) : (
                          <span className="text-white font-bold text-base">
                            CFA {Number(electricitySubscription.monthly_fee || 0).toLocaleString()}
                          </span>
                        )}
                      </>
                    )}
                  </div>

                  {/* Meter Reading details or Cycle Start */}
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/70">
                    <span className="text-slate-400 text-xs block mb-1 uppercase font-semibold">
                      {electricitySubscription.type === 'Meter' ? 'Baseline / Latest Meter' : 'Current Cycle Start'}
                    </span>
                    <span className="text-white font-bold text-base">
                      {electricitySubscription.type === 'Meter' 
                        ? `${latestReading?.latest_reading ?? electricitySubscription.last_meter_reading ?? 0} kWh`
                        : (electricitySubscription.start_date || 'N/A')
                      }
                    </span>
                  </div>

                  {/* Next Billing / Agent Check Date */}
                  <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/70">
                    <span className="text-slate-400 text-xs block mb-1 uppercase font-semibold">
                      {electricitySubscription.type === 'Meter' ? 'Agent Next Reading Due' : 'Next Billing Date'}
                    </span>
                    <span className="text-indigo-300 font-bold text-base">
                      {electricitySubscription.next_billing_date || 'N/A'}
                    </span>
                  </div>
                </div>

                {/* Helpful Agent / Meter info banner */}
                {electricitySubscription.type === 'Meter' ? (
                  <div className="p-4 rounded-xl bg-primary/10 border border-primary/20 flex items-start gap-3">
                    <Calendar size={18} className="text-indigo-400 shrink-0 mt-0.5" />
                    <p className="text-xs text-indigo-200 leading-relaxed">
                      At the end of the monthly cycle around <strong>{electricitySubscription.next_billing_date || 'month-end'}</strong>, the utility agent visits the apartment to record the current reading. Consumption is calculated from the baseline ({latestReading?.latest_reading ?? electricitySubscription.last_meter_reading ?? 0} kWh).
                    </p>
                  </div>
                ) : (
                  <div className="border-t border-slate-700/70 pt-6">
                    <h4 className="text-sm font-bold text-white mb-1">Mid-Cycle Plan Switching</h4>
                    <p className="text-xs text-slate-400 mb-3">
                      Switching to a Meter plan mid-cycle will automatically calculate the prorated amount used for the current month and generate an immediate invoice.
                    </p>
                    {isAgent ? (
                      <div className="bg-slate-800/50 border border-slate-700 p-3 rounded-xl text-center text-xs text-slate-400">
                        Agents cannot change subscription plans. Please contact an Administrator.
                      </div>
                    ) : (
                      <button 
                        onClick={() => setSwitchPlanModal(true)}
                        className="bg-primary hover:bg-indigo-600 text-white px-5 py-2.5 rounded-xl font-semibold text-xs transition-all shadow-lg shadow-primary/20 flex items-center gap-2"
                      >
                        <RefreshCw size={14} /> Switch to Meter Plan
                      </button>
                    )}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* ==================== METER TAB ==================== */}
        {activeTab === 'Meter' && (
          <div className="max-w-2xl">
            {(!hasActivePlan || electricitySubscription.type !== 'Meter') ? (
              <div className="text-center p-8 bg-slate-800/50 rounded-2xl border border-slate-700">
                <Clock className="mx-auto text-slate-500 mb-4" size={48} />
                <h4 className="text-white font-bold text-lg mb-2">Not a Metered Plan</h4>
                <p className="text-slate-400 text-sm mb-4">
                  This apartment is currently not on a meter reading subscription plan.
                </p>
                <button
                  onClick={() => {
                    setActiveTab('Plan');
                    setWizardStep('choose');
                    setShowWizard(true);
                  }}
                  className="px-5 py-2.5 bg-warning text-slate-950 font-bold rounded-xl text-xs hover:bg-amber-400 transition-colors"
                >
                  Configure Meter Plan
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmitReading} className="space-y-6">
                <div className="bg-primary/10 border border-primary/30 p-4 rounded-xl mb-6">
                  <h4 className="text-primary font-bold flex items-center gap-2 mb-1 text-sm">
                    <Calendar size={16} /> Continuous Meter Logic Active
                  </h4>
                  <p className="text-xs text-indigo-200">
                    The system automatically calculates consumption based on the previous baseline reading and generates the invoice. The new reading becomes the baseline for the next cycle.
                  </p>
                </div>
                
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-xs font-semibold text-slate-400 mb-2">Previous Reading (Last Cycle)</label>
                    <input 
                      type="number" 
                      value={latestReading?.latest_reading ?? meterForm.previous_reading} 
                      disabled
                      className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 opacity-70 font-bold text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold text-slate-400 mb-2">Price Per kWh (CFA)</label>
                    <input 
                      type="number" 
                      value={meterForm.price_per_kwh}
                      disabled 
                      className="w-full bg-slate-900 border border-slate-700 text-white rounded-xl px-4 py-2.5 opacity-70 font-bold text-sm"
                    />
                  </div>
                  <div className="col-span-2">
                    <label className="block text-xs font-semibold text-slate-400 mb-2">Current New Reading</label>
                    <input 
                      type="number" 
                      required
                      value={meterForm.current_reading} 
                      onChange={(e) => setMeterForm({...meterForm, current_reading: e.target.value})}
                      className="w-full bg-slate-800 border border-slate-600 focus:border-primary focus:ring-1 focus:ring-primary text-white rounded-xl px-4 py-3 font-bold"
                      placeholder="Enter the new count from the meter"
                    />
                  </div>
                </div>

                {isAgent ? (
                  <div className="bg-slate-800/50 border border-slate-700 p-4 rounded-xl text-center text-slate-400 text-xs">
                    Agents submit meter readings through the dedicated Agent Utility Portal.
                  </div>
                ) : (
                  <button 
                    type="submit"
                    disabled={submitReadingMutation.isLoading}
                    className="bg-warning hover:bg-yellow-500 text-black px-6 py-3 rounded-xl font-bold transition-all w-full flex items-center justify-center gap-2 text-sm shadow-lg shadow-warning/20"
                  >
                    <PlusCircle size={18} /> 
                    {submitReadingMutation.isLoading ? 'Processing...' : 'Submit Reading & Generate Invoice'}
                  </button>
                )}
              </form>
            )}
          </div>
        )}

        {/* ==================== INVOICES TAB ==================== */}
        {activeTab === 'Invoices' && (
          <div className="overflow-hidden">
            <div className="p-4 border-b border-slate-700 flex flex-wrap gap-4 items-center justify-between bg-slate-800/20">
              <div className="flex items-center gap-4 flex-1">
                <div className="relative max-w-sm flex-1">
                  <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="text"
                    placeholder="Search invoices..."
                    value={elecSearch}
                    onChange={(e) => setElecSearch(e.target.value)}
                    className="w-full bg-slate-900 border border-slate-700 text-white text-sm rounded-xl pl-9 pr-3 py-2 focus:ring-1 focus:ring-primary focus:border-primary transition-all"
                  />
                </div>
                <input
                  type="month"
                  value={elecFilter}
                  onChange={(e) => setElecFilter(e.target.value)}
                  className="bg-slate-900 border border-slate-700 text-white text-sm rounded-xl px-3 py-2 focus:ring-1 focus:ring-primary focus:border-primary transition-all"
                />
              </div>
              
              {electricityInvoices?.length > 0 && onPrintAll && (
                <button
                  onClick={onPrintAll}
                  className="flex items-center gap-2 bg-indigo-500/20 text-indigo-300 hover:bg-indigo-500/30 px-4 py-2 rounded-xl font-medium transition-colors border border-indigo-500/30 text-xs"
                >
                  <Printer size={16} /> Print All
                </button>
              )}
            </div>
            
            <table className="min-w-full divide-y divide-slate-700/50 text-left">
              <thead>
                <tr className="bg-slate-800/30">
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Due Date</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Type</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Amount Due</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Paid</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Status</th>
                  <th className="px-6 py-4 text-right text-xs font-semibold text-muted uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {electricityInvoices?.map(invoice => (
                  <tr key={invoice.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4 text-white font-medium text-sm">{invoice.due_date}</td>
                    <td className="px-6 py-4 text-slate-300 text-sm">
                      <span className="font-semibold">{invoice.type}</span>
                      {invoice.notes && <span className="text-xs text-muted block mt-1">{invoice.notes}</span>}
                      {invoice.previous_reading !== null && invoice.current_reading !== null && (
                        <div className="text-xs text-slate-400 mt-1">
                          <span className="block">Previous: {invoice.previous_reading}</span>
                          <span className="block">Current: {invoice.current_reading}</span>
                          {invoice.consumption && <span className="block text-indigo-300">Used: {invoice.consumption} kWh</span>}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4 text-white font-bold text-sm"><InteractiveCurrency amountCFA={invoice.amount} /></td>
                    <td className="px-6 py-4 text-success font-medium text-sm"><InteractiveCurrency amountCFA={invoice.amount_paid || 0} /></td>
                    <td className="px-6 py-4">
                      <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${getStatusColor(invoice.status)}`}>
                        {invoice.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex justify-end gap-2 items-center">
                        {invoice.status !== 'Paid' && onPayInvoice && (
                          <button
                            onClick={() => onPayInvoice(invoice)}
                            className="bg-primary/20 text-indigo-300 px-3 py-1.5 rounded-lg text-xs font-medium transition-colors hover:bg-primary/30"
                          >
                            Pay
                          </button>
                        )}
                        {onPrintInvoice && (
                          <button
                            onClick={() => onPrintInvoice(invoice.id)}
                            className="text-slate-400 hover:text-indigo-400 p-2 transition-colors rounded-lg hover:bg-slate-800"
                            title="Print Receipt"
                          >
                            <Printer size={16} />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
                {!electricityInvoices?.length && (
                  <tr><td colSpan="6" className="px-6 py-8 text-center text-muted">No billing history found.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Switch Plan Modal */}
      {switchPlanModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-[#0F172A] border border-slate-700 p-6 sm:p-8 w-full max-w-md rounded-2xl animate-in zoom-in-95 shadow-2xl">
            <h3 className="text-xl font-bold mb-2 text-white">Switch to Meter Plan</h3>
            <p className="text-slate-400 mb-6 text-xs leading-relaxed">
              This action will calculate prorated charges for the current cycle and immediately start meter tracking.
            </p>
            
            <form onSubmit={handleSwitchPlan} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1">New Price Per kWh (CFA)</label>
                <input 
                  type="number" 
                  required
                  value={switchPlanData.price_per_kwh} 
                  onChange={(e) => setSwitchPlanData({...switchPlanData, price_per_kwh: e.target.value})}
                  className="w-full bg-slate-800 border border-slate-600 focus:border-primary text-white rounded-xl px-4 py-2.5 text-sm outline-none"
                />
              </div>
              <div>
                <label className="block text-xs font-semibold text-slate-400 mb-1">Initial Meter Reading (Starting count)</label>
                <input 
                  type="number" 
                  required
                  value={switchPlanData.initial_reading} 
                  onChange={(e) => setSwitchPlanData({...switchPlanData, initial_reading: e.target.value})}
                  className="w-full bg-slate-800 border border-slate-600 focus:border-primary text-white rounded-xl px-4 py-2.5 text-sm outline-none"
                  placeholder="e.g. 1000"
                />
              </div>
              
              <div className="flex gap-3 mt-6">
                <button 
                  type="button" 
                  onClick={() => setSwitchPlanModal(false)}
                  className="flex-1 py-2.5 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-xl transition-colors text-sm"
                >
                  Cancel
                </button>
                <button 
                  type="submit"
                  disabled={switchPlanMutation.isLoading}
                  className="flex-1 py-2.5 bg-primary hover:bg-indigo-600 text-white font-bold rounded-xl transition-colors shadow-lg shadow-primary/20 text-sm"
                >
                  {switchPlanMutation.isLoading ? 'Processing...' : 'Confirm Switch'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default TenantBillingDashboard;
