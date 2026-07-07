import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { ArrowLeft, Zap, DollarSign, Activity } from 'lucide-react';

const BuildingSubscriptions = () => {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [selectedApt, setSelectedApt] = useState(null);
  const [activeTab, setActiveTab] = useState('monthly'); // 'monthly' or 'metered'
  const [filterTab, setFilterTab] = useState('all'); // 'all', 'fixed', 'metered'
  const [searchTerm, setSearchTerm] = useState('');
  const [expirySoon, setExpirySoon] = useState(false);
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [invoiceModalApt, setInvoiceModalApt] = useState(null);
  const [renewModalApt, setRenewModalApt] = useState(null);
  const [toast, setToast] = useState(null); // { message, type }

  const [monthlyForm, setMonthlyForm] = useState({
    amps: '', cost_per_amp: '', start_date: new Date().toISOString().split('T')[0], end_date: ''
  });
  const [meterForm, setMeterForm] = useState({
    previous_reading: 0, current_reading: '', price_per_kwh: '', start_date: new Date().toISOString().split('T')[0], end_date: ''
  });

  const { data: apartments, isLoading } = useQuery({
    queryKey: ['buildingSubscriptions', id],
    queryFn: async () => {
      const res = await api.get(`/energy/buildings/${id}/subscriptions`);
      return res.data;
    }
  });

  const { data: stats } = useQuery({
    queryKey: ['generatorStats', id],
    queryFn: async () => {
      try {
        const res = await api.get(`/energy/generators/${id}/stats`);
        return res.data;
      } catch (err) {
        return null;
      }
    },
    retry: false
  });

  const monthlyMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${selectedApt}/subscriptions`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['buildingSubscriptions', id]);
      setSelectedApt(null);
    }
  });

  const meterMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${selectedApt}/meter-readings`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['buildingSubscriptions', id]);
      setSelectedApt(null);
    }
  });

  const requestRenewalMutation = useMutation({
    mutationFn: (aptId) => api.post(`/energy/apartments/${aptId}/request-renewal`),
    onSuccess: () => {
      setToast({ message: 'Renewal request sent to tenant successfully!', type: 'success' });
      setRenewModalApt(null);
      setTimeout(() => setToast(null), 3000);
    },
    onError: (error) => {
      setToast({ message: error?.response?.data?.error || 'Failed to send renewal request', type: 'error' });
      setRenewModalApt(null);
      setTimeout(() => setToast(null), 3000);
    }
  });

  const directRenewMutation = useMutation({
    mutationFn: (aptId) => api.post(`/energy/apartments/${aptId}/renew-subscription`),
    onSuccess: () => {
      setToast({ message: 'Subscription renewed successfully!', type: 'success' });
      queryClient.invalidateQueries(['buildingSubscriptions', id]);
      setRenewModalApt(null);
      setTimeout(() => setToast(null), 3000);
    },
    onError: (error) => {
      setToast({ message: error?.response?.data?.error || 'Failed to renew subscription', type: 'error' });
      setRenewModalApt(null);
      setTimeout(() => setToast(null), 3000);
    }
  });

  const { data: subscriptionInvoices, isLoading: loadingInvoices } = useQuery({
    queryKey: ['subscriptionInvoices', invoiceModalApt],
    queryFn: async () => {
      const res = await api.get(`/energy/apartments/${invoiceModalApt}/subscription-invoices`);
      return res.data;
    },
    enabled: !!invoiceModalApt
  });

  if (isLoading) return <div className="flex-1 p-8 flex items-center justify-center"><div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div></div>;

  const filteredApartments = apartments?.filter(apt => {
    if (filterTab === 'fixed' && !(apt.amps > 0)) return false;
    if (filterTab === 'metered' && apt.amps > 0) return false;
    
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      const matchApt = apt.apartment_code?.toLowerCase().includes(term);
      const matchTenant = apt.tenant_name?.toLowerCase().includes(term);
      if (!matchApt && !matchTenant) return false;
    }
    
    if (expirySoon) {
      if (!apt.end_date) return false;
      const endDate = new Date(apt.end_date);
      const today = new Date();
      const diffDays = Math.ceil((endDate - today) / (1000 * 60 * 60 * 24));
      if (diffDays < 0 || diffDays > 7) return false;
    }

    if (fromDate && apt.start_date && apt.start_date < fromDate) return false;
    if (toDate && apt.end_date && apt.end_date > toDate) return false;
    
    return true;
  });

  const openConfig = (apt, type) => {
    setSelectedApt(apt.apartment_id);
    setActiveTab(type);
    
    setMonthlyForm({
      amps: apt.amps || '',
      cost_per_amp: apt.cost_per_amp || '',
      start_date: apt.start_date || new Date().toISOString().split('T')[0],
      end_date: apt.end_date || ''
    });
    
    setMeterForm({
      previous_reading: apt.last_reading || 0,
      current_reading: '',
      price_per_kwh: stats?.generator?.price_per_kw || '',
      start_date: apt.start_date || new Date().toISOString().split('T')[0],
      end_date: apt.end_date || ''
    });
  };

  return (
    <div className="flex-1 overflow-y-auto p-8 hide-scrollbar bg-background">
      <div className="flex items-center gap-4 mb-8">
        <button onClick={() => navigate('/buildings')} className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-white transition-colors">
          <ArrowLeft size={20} />
        </button>
        <div>
          <h1 className="text-3xl font-bold text-white">{t('buildingsubscriptions.generator_subscriptions', { defaultValue: `Generator Subscriptions` })}</h1>
          <p className="text-muted mt-1">{t('buildingsubscriptions.manage_generator_billing_for_a', { defaultValue: `Manage generator billing for all apartments in this building.` })}</p>
        </div>
      </div>

      <div className="flex flex-wrap gap-4 bg-slate-900 p-4 rounded-lg mb-6 w-full items-center">
        <div className="flex bg-slate-800 p-1 rounded-lg">
          <button 
            onClick={() => setFilterTab('all')} 
            className={`px-4 py-1.5 text-sm font-bold rounded-md transition-colors ${filterTab === 'all' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white'}`}
          >
            All Units
          </button>
          <button 
            onClick={() => setFilterTab('fixed')} 
            className={`px-4 py-1.5 text-sm font-bold rounded-md transition-colors ${filterTab === 'fixed' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white'}`}
          >
            Fixed Amps
          </button>
          <button 
            onClick={() => setFilterTab('metered')} 
            className={`px-4 py-1.5 text-sm font-bold rounded-md transition-colors ${filterTab === 'metered' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white'}`}
          >
            Metered
          </button>
        </div>

        <input 
          type="text" 
          placeholder="Search apartment or tenant..." 
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="bg-slate-800 border border-slate-700 rounded-lg px-4 py-1.5 text-sm text-white"
        />

        <label className="flex items-center gap-2 text-sm text-slate-300 cursor-pointer">
          <input 
            type="checkbox" 
            checked={expirySoon} 
            onChange={(e) => setExpirySoon(e.target.checked)} 
            className="rounded border-slate-700 bg-slate-800 text-primary focus:ring-primary"
          />
          Expiry Soon (7 days)
        </label>

        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-400">From:</span>
          <input 
            type="date" 
            value={fromDate}
            onChange={(e) => setFromDate(e.target.value)}
            className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-white"
          />
        </div>
        <div className="flex items-center gap-2">
          <span className="text-sm text-slate-400">To:</span>
          <input 
            type="date" 
            value={toDate}
            onChange={(e) => setToDate(e.target.value)}
            className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-white"
          />
        </div>
      </div>

      <div className="glass-card p-6">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-700 text-sm text-muted">
                <th className="pb-3 font-medium">{t('buildingsubscriptions.apartment', { defaultValue: `Apartment` })}</th>
                <th className="pb-3 font-medium">Tenant</th>
                <th className="pb-3 font-medium">{t('buildingsubscriptions.current_plan', { defaultValue: `Current Plan` })}</th>
                <th className="pb-3 font-medium">Start</th>
                <th className="pb-3 font-medium">End</th>
                <th className="pb-3 font-medium">{t('buildingsubscriptions.last_reading', { defaultValue: `Last Reading` })}</th>
                <th className="pb-3 font-medium">Paid</th>
                <th className="pb-3 font-medium">{t('buildingsubscriptions.unpaid_balance', { defaultValue: `Unpaid` })}</th>
                <th className="pb-3 font-medium text-right">{t('buildingsubscriptions.actions', { defaultValue: `Actions` })}</th>
              </tr>
            </thead>
            <tbody>
              {filteredApartments?.map(apt => (
                <tr key={apt.apartment_id} className="border-b border-slate-800/50 hover:bg-slate-800/20 transition-colors">
                  <td className="py-4 font-bold text-white text-lg">{apt.apartment_code}</td>
                  <td className="py-4 text-slate-300 font-medium">{apt.tenant_name || '-'}</td>
                  <td className="py-4">
                    {apt.amps > 0 ? (
                      <span className="bg-primary/20 text-indigo-300 px-3 py-1 rounded-full text-sm">
                        {t('buildingsubscriptions.fixed', { defaultValue: `Fixed:` })} {apt.amps} {t('buildingsubscriptions.amps_cfa', { defaultValue: `Amps (CFA` })} {apt.monthly_fee})
                      </span>
                    ) : (
                      <span className="text-muted text-sm italic">{t('buildingsubscriptions.metered_none', { defaultValue: `Metered / None` })}</span>
                    )}
                  </td>
                  <td className="py-4 text-slate-300">{apt.start_date || '-'}</td>
                  <td className="py-4 text-slate-300 font-medium">
                    {apt.end_date ? (
                      <div className="flex items-center gap-2">
                        {apt.end_date}
                        {(() => {
                          const today = new Date();
                          const endDate = new Date(apt.end_date);
                          const diffTime = endDate - today;
                          const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                          if (diffDays >= 0 && diffDays <= 7) {
                            return <span className="bg-warning/20 text-warning px-2 py-0.5 rounded text-xs font-bold whitespace-nowrap">Expiry in {diffDays} day{diffDays !== 1 ? 's' : ''}</span>;
                          } else if (diffDays < 0) {
                            return <span className="bg-danger/20 text-danger px-2 py-0.5 rounded text-xs font-bold whitespace-nowrap">Expired</span>;
                          }
                          return null;
                        })()}
                      </div>
                    ) : '-'}
                  </td>
                  <td className="py-4 text-white font-medium">{(!apt.amps || apt.amps == 0) ? (apt.last_reading || '-') : '-'}</td>
                  <td className="py-4 text-success font-medium"><DollarSign size={14} className="inline" /> {apt.paid_amount || 0}</td>
                  <td className="py-4">
                    {apt.unpaid_balance > 0 ? (
                      <span className="text-danger font-bold flex items-center gap-1"><DollarSign size={14} /> {apt.unpaid_balance}</span>
                    ) : (
                      <span className="text-success text-sm">{t('buildingsubscriptions.clear', { defaultValue: `Clear` })}</span>
                    )}
                  </td>
                  <td className="py-4 text-right flex justify-end gap-2">
                    <button onClick={() => openConfig(apt, apt.amps > 0 ? 'monthly' : 'metered')} className="px-3 py-1.5 bg-primary hover:bg-primary/80 text-white rounded-lg text-sm transition-colors shadow-lg shadow-primary/20">{t('buildingsubscriptions.manage_plan', { defaultValue: `Manage Plan` })}</button>
                    <button onClick={() => setRenewModalApt(apt.apartment_id)} className="px-3 py-1.5 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg text-sm transition-colors">Renewly</button>
                    <button onClick={() => setInvoiceModalApt(apt.apartment_id)} className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-sm transition-colors border border-slate-700">Invoice</button>
                  </td>
                </tr>
              ))}
              {(!filteredApartments || filteredApartments.length === 0) && (
                <tr><td colSpan="7" className="py-8 text-center text-muted">{t('buildingsubscriptions.no_apartments_found_in_this_bu', { defaultValue: `No apartments found in this building.` })}</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Subscription/Meter Modal */}
      {selectedApt && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-md p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            {(() => {
              const aptDetails = apartments?.find(a => a.apartment_id === selectedApt);
              return (
                <>
                  <div className="mb-6 text-center">
                    <h2 className="text-2xl font-bold text-white mb-1">
                      {aptDetails?.apartment_code} - {t('buildingsubscriptions.generator_billing', { defaultValue: 'Generator Billing' })}
                    </h2>
                    <p className="text-slate-400 text-sm">{t('buildingsubscriptions.select_billing_method', { defaultValue: 'Select billing method for this unit.' })}</p>
                  </div>
                  
                  <div className="flex bg-slate-900 p-1 rounded-lg mb-6">
                    <button 
                      onClick={() => setActiveTab('monthly')} 
                      className={`flex-1 py-2 text-sm font-bold rounded-md transition-colors ${activeTab === 'monthly' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white'}`}
                    >
                      {t('buildingsubscriptions.monthly_fixed', { defaultValue: 'Monthly (Fixed Amps)' })}
                    </button>
                    <button 
                      onClick={() => setActiveTab('metered')} 
                      className={`flex-1 py-2 text-sm font-bold rounded-md transition-colors ${activeTab === 'metered' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white'}`}
                    >
                      {t('buildingsubscriptions.metered_kwh', { defaultValue: 'Metered (kWh)' })}
                    </button>
                  </div>
                </>
              );
            })()}
            
            {activeTab === 'monthly' && (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.amps', { defaultValue: `Amps` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={monthlyForm.amps} onChange={e => setMonthlyForm({...monthlyForm, amps: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.cost_per_amp_cfa', { defaultValue: `Cost per Amp (CFA)` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={monthlyForm.cost_per_amp} onChange={e => setMonthlyForm({...monthlyForm, cost_per_amp: e.target.value})} />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.start_date', { defaultValue: `Start Date` })}</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={monthlyForm.start_date} onChange={e => setMonthlyForm({...monthlyForm, start_date: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.end_date', { defaultValue: `End Date` })}</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={monthlyForm.end_date} onChange={e => setMonthlyForm({...monthlyForm, end_date: e.target.value})} />
                  </div>
                </div>
                <div className="pt-2">
                  <p className="text-sm text-muted">{t('buildingsubscriptions.monthly_fee', { defaultValue: `Monthly Fee:` })} <strong className="text-white">{t('buildingsubscriptions.cfa', { defaultValue: `CFA` })} {(monthlyForm.amps * monthlyForm.cost_per_amp) || 0}</strong></p>
                </div>
              </div>
            )}

            {activeTab === 'metered' && (
              <div className="space-y-4">
                <div className="bg-slate-800/50 p-4 rounded-lg border border-slate-700 flex justify-between items-center">
                   <span className="text-muted">{t('buildingsubscriptions.previous_reading', { defaultValue: `Previous Reading:` })}</span>
                   <span className="text-xl font-bold text-white">{meterForm.previous_reading} {t('buildingsubscriptions.kw', { defaultValue: `KW` })}</span>
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.current_reading', { defaultValue: `Current Reading` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white text-xl font-bold" 
                    autoFocus
                    value={meterForm.current_reading} onChange={e => setMeterForm({...meterForm, current_reading: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.price_per_kw_cfa', { defaultValue: `Price per KW (CFA)` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={meterForm.price_per_kwh} onChange={e => setMeterForm({...meterForm, price_per_kwh: e.target.value})} />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.start_date', { defaultValue: `Start Date` })}</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={meterForm.start_date} onChange={e => setMeterForm({...meterForm, start_date: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.end_date', { defaultValue: `End Date` })}</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={meterForm.end_date} onChange={e => setMeterForm({...meterForm, end_date: e.target.value})} />
                  </div>
                </div>
                {meterForm.current_reading && (
                  <div className="bg-slate-900/80 p-5 rounded-xl border border-slate-700/50 mt-6 flex justify-between items-center shadow-inner">
                    <div>
                      <p className="text-xs text-muted uppercase tracking-wider mb-1 font-semibold">{t('buildingsubscriptions.consumption', { defaultValue: `Consumption` })}</p>
                      <p className={`text-xl font-bold ${(meterForm.current_reading - meterForm.previous_reading) > 0 ? 'text-indigo-300' : 'text-danger'}`}>
                        {meterForm.current_reading - meterForm.previous_reading} {t('buildingsubscriptions.kwh', { defaultValue: `kWh` })}
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-muted uppercase tracking-wider mb-1 font-semibold">{t('buildingsubscriptions.estimated_cost', { defaultValue: `Estimated Cost` })}</p>
                      <p className={`text-2xl font-black ${(meterForm.current_reading - meterForm.previous_reading) > 0 ? 'text-success' : 'text-danger'}`}>
                        {t('buildingsubscriptions.cfa', { defaultValue: `CFA` })} {((meterForm.current_reading - meterForm.previous_reading) * meterForm.price_per_kwh).toLocaleString(undefined, { minimumFractionDigits: 0 })}
                      </p>
                    </div>
                  </div>
                )}
              </div>
            )}

            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setSelectedApt(null)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('buildingsubscriptions.cancel', { defaultValue: `Cancel` })}</button>
              <button 
                onClick={() => {
                  if (activeTab === 'monthly') monthlyMutation.mutate(monthlyForm);
                  else meterMutation.mutate(meterForm);
                }}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors"
                disabled={activeTab === 'monthly' ? monthlyMutation.isLoading : meterMutation.isLoading}
              >
                {activeTab === 'monthly' ? 'Save Subscription' : 'Submit Reading'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Invoice Modal */}
      {invoiceModalApt && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-3xl p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold text-white">
                Subscription Invoices - {apartments?.find(a => a.apartment_id === invoiceModalApt)?.tenant_name || 'Tenant'}
              </h2>
              <button onClick={() => setInvoiceModalApt(null)} className="text-slate-400 hover:text-white">✕</button>
            </div>
            
            {loadingInvoices ? (
              <div className="py-8 text-center"><div className="animate-spin inline-block w-8 h-8 border-4 border-primary border-t-transparent rounded-full"></div></div>
            ) : (
              <div className="overflow-x-auto print:overflow-visible">
                <table className="w-full text-left border-collapse" id="invoice-table">
                  <thead>
                    <tr className="border-b border-slate-700 text-sm text-muted">
                      <th className="pb-3">Period / Due Date</th>
                      <th className="pb-3">Plan (Amps)</th>
                      <th className="pb-3">Cost (CFA)</th>
                      <th className="pb-3">Paid (CFA)</th>
                      <th className="pb-3">Remain (CFA)</th>
                      <th className="pb-3 print:hidden text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {subscriptionInvoices?.map(inv => (
                      <tr key={inv.id} className="border-b border-slate-800/50">
                        <td className="py-3 text-white">{inv.due_date}</td>
                        <td className="py-3 text-slate-300">{inv.amps || '-'}</td>
                        <td className="py-3 text-slate-300">{inv.amount}</td>
                        <td className="py-3 text-success">{inv.amount_paid}</td>
                        <td className="py-3 text-danger font-bold">{(inv.amount - inv.amount_paid) > 0 ? (inv.amount - inv.amount_paid) : 0}</td>
                        <td className="py-3 print:hidden text-right">
                          <button onClick={() => navigate(`/apartments/${invoiceModalApt}/electricity`)} className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-white rounded text-xs border border-slate-700 transition-colors">
                            Pay Record
                          </button>
                        </td>
                      </tr>
                    ))}
                    {(!subscriptionInvoices || subscriptionInvoices.length === 0) && (
                      <tr><td colSpan="6" className="py-6 text-center text-muted">No invoices found.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}
            
            <div className="flex justify-end gap-3 mt-8 print:hidden">
              <button onClick={() => setInvoiceModalApt(null)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">Close</button>
              <button onClick={() => window.print()} className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors flex items-center gap-2">
                Print Invoice List
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Renew Modal */}
      {renewModalApt && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-md p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <h2 className="text-2xl font-bold text-white mb-2">Renew Subscription</h2>
            <p className="text-slate-400 mb-8">
              Would you like to ask the tenant to confirm this renewal, or renew it directly yourself?
            </p>
            <div className="flex flex-col sm:flex-row justify-end gap-3">
              <button 
                onClick={() => setRenewModalApt(null)} 
                className="px-4 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button 
                onClick={() => requestRenewalMutation.mutate(renewModalApt)}
                disabled={requestRenewalMutation.isLoading || directRenewMutation.isLoading}
                className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors border border-slate-600"
              >
                {requestRenewalMutation.isLoading ? 'Sending...' : 'Ask Tenant'}
              </button>
              <button 
                onClick={() => directRenewMutation.mutate(renewModalApt)}
                disabled={requestRenewalMutation.isLoading || directRenewMutation.isLoading}
                className="px-4 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors font-bold"
              >
                {directRenewMutation.isLoading ? 'Renewing...' : 'Renew Directly'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toast && (
        <div className={`fixed bottom-4 right-4 text-white px-6 py-3 rounded-lg shadow-2xl z-50 animate-bounce ${toast.type === 'error' ? 'bg-danger' : 'bg-emerald-600'}`}>
          {toast.message}
        </div>
      )}
    </div>
  );
};

export default BuildingSubscriptions;
