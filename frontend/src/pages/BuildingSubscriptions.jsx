import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { ArrowLeft, Zap, DollarSign, Activity, FileText } from 'lucide-react';
import ApartmentBillingModal from '../components/ApartmentBillingModal';

const BuildingSubscriptions = () => {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [selectedApt, setSelectedApt] = useState(null);
  const [activeTab, setActiveTab] = useState('fixed_monthly'); // 'fixed_monthly', 'fixed_amp', or 'meter'
  const [filterTab, setFilterTab] = useState('all'); // 'all', 'fixed', or 'metered'
  const [searchTerm, setSearchTerm] = useState('');
  const [expirySoon, setExpirySoon] = useState(false);
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');
  const [invoiceModalApt, setInvoiceModalApt] = useState(null);
  const [renewModalApt, setRenewModalApt] = useState(null);
  const [manageBillingApt, setManageBillingApt] = useState(null);
  const [toast, setToast] = useState(null); // { message, type }
  const [payInvoiceModal, setPayInvoiceModal] = useState(null); // { invoice }
  const [payInvoiceAmount, setPayInvoiceAmount] = useState('');
  const [payInvoiceMethod, setPayInvoiceMethod] = useState('Cash');

  const [subForm, setSubForm] = useState({
    type: 'Fixed Monthly', monthly_fee: '', amps: '', cost_per_amp: '',
    last_meter_reading: '', current_reading: '', price_per_kwh: ''
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
    onSuccess: (res) => {
      queryClient.invalidateQueries(['buildingSubscriptions', id]);
      const d = res.data;
      if (d?.start_date && d?.end_date) {
        setToast({ message: `✅ Subscription saved! Period: ${d.start_date} → ${d.end_date}`, type: 'success' });
        setTimeout(() => setToast(null), 5000);
      }
      setSelectedApt(null);
    },
    onError: (err) => {
      setToast({ message: err?.response?.data?.error || 'Failed to save subscription', type: 'error' });
      setTimeout(() => setToast(null), 4000);
    }
  });


  const payInvoiceMutation = useMutation({
    mutationFn: ({ id, amount }) => api.put(`/electricity/invoices/${id}/pay`, { amount_paid: amount }),
    onSuccess: () => {
      queryClient.invalidateQueries(['subscriptionInvoices', invoiceModalApt]);
      setPayInvoiceModal(null);
      setPayInvoiceAmount('');
      setPayInvoiceMethod('Cash');
    },
    onError: (error) => {
      setToast({ message: error?.response?.data?.error || 'Payment failed', type: 'error' });
      setTimeout(() => setToast(null), 3000);
    }
  });

  const meterMutation = useMutation({
    mutationFn: ({aptId, data}) => api.post(`/energy/apartments/${aptId}/meter-readings`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['buildingSubscriptions', id]);
      setRenewModalApt(null);
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

  const handlePrintInvoice = (inv) => {
    const aptDetails = apartments?.find(a => a.apartment_id === invoiceModalApt);
    const tenantName = aptDetails?.tenant_name || 'Tenant';
    const aptCode = aptDetails?.apartment_code || '';
    
    const printWindow = window.open('', '', 'width=800,height=600');
    printWindow.document.write(`
      <html>
        <head>
          <title>Invoice - ${tenantName}</title>
          <style>
            body { font-family: system-ui, -apple-system, sans-serif; padding: 40px; color: #111; max-width: 600px; margin: 0 auto; }
            .header { text-align: center; border-bottom: 2px solid #e2e8f0; padding-bottom: 20px; margin-bottom: 30px; }
            .header h1 { margin: 0 0 10px 0; font-size: 24px; color: #1e293b; }
            .details { margin-bottom: 30px; border: 1px solid #e2e8f0; border-radius: 8px; padding: 20px; }
            .row { display: flex; justify-content: space-between; margin-bottom: 12px; border-bottom: 1px dashed #e2e8f0; padding-bottom: 8px; }
            .row:last-child { border-bottom: none; margin-bottom: 0; padding-bottom: 0; }
            .label { color: #64748b; font-weight: 500; }
            .value { font-weight: 600; text-align: right; }
            .amount { font-size: 20px; font-weight: bold; margin-top: 20px; text-align: center; padding: 15px; background: #f8fafc; border-radius: 8px; }
            .paid { color: #10b981; }
            .unpaid { color: #ef4444; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>Generator Subscription Invoice</h1>
            <p><strong>Apartment:</strong> ${aptCode} &nbsp;|&nbsp; <strong>Tenant:</strong> ${tenantName}</p>
          </div>
          <div class="details">
            <div class="row"><span class="label">Period / Due Date</span> <span class="value">${inv.due_date}</span></div>
            <div class="row"><span class="label">Plan</span> <span class="value">${inv.amps ? inv.amps + ' Amps' : 'Metered'}</span></div>
            <div class="row"><span class="label">Total Cost</span> <span class="value">CFA ${Number(inv.amount).toLocaleString()}</span></div>
            <div class="row"><span class="label">Amount Paid</span> <span class="value">CFA ${Number(inv.amount_paid).toLocaleString()}</span></div>
            <div class="row"><span class="label">Remaining Balance</span> <span class="value">CFA ${((inv.amount - inv.amount_paid) > 0 ? (inv.amount - inv.amount_paid) : 0).toLocaleString()}</span></div>
          </div>
          <div class="amount ${(inv.amount - inv.amount_paid) > 0 ? 'unpaid' : 'paid'}">
            Status: ${(inv.amount - inv.amount_paid) > 0 ? 'Unpaid / Partial' : 'Paid in Full'}
          </div>
          <script>
            window.onload = function() { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  const handlePrintInvoiceList = () => {
    const aptDetails = apartments?.find(a => a.apartment_id === invoiceModalApt);
    const tenantName = aptDetails?.tenant_name || 'Tenant';
    const aptCode = aptDetails?.apartment_code || '';
    
    const printWindow = window.open('', '', 'width=800,height=600');
    
    let tableRows = '';
    let totalPaid = 0;
    let totalRemain = 0;

    if (subscriptionInvoices && subscriptionInvoices.length > 0) {
      tableRows = subscriptionInvoices.map(inv => {
        const remain = (inv.amount - inv.amount_paid) > 0 ? (inv.amount - inv.amount_paid) : 0;
        totalPaid += Number(inv.amount_paid) || 0;
        totalRemain += remain;

        return `
          <tr>
            <td>${inv.due_date}</td>
            <td>${inv.amps ? inv.amps + ' Amps' : 'Metered'}</td>
            <td>CFA ${Number(inv.amount).toLocaleString()}</td>
            <td class="paid">CFA ${Number(inv.amount_paid).toLocaleString()}</td>
            <td class="unpaid">CFA ${remain.toLocaleString()}</td>
          </tr>
        `;
      }).join('');
    } else {
      tableRows = `<tr><td colspan="5" style="text-align:center;">No invoices found.</td></tr>`;
    }

    printWindow.document.write(`
      <html>
        <head>
          <title>Invoice List - ${tenantName}</title>
          <style>
            body { font-family: system-ui, -apple-system, sans-serif; padding: 40px; color: #111; max-width: 800px; margin: 0 auto; }
            .header { text-align: center; border-bottom: 2px solid #e2e8f0; padding-bottom: 20px; margin-bottom: 30px; }
            .header h1 { margin: 0 0 10px 0; font-size: 24px; color: #1e293b; }
            table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
            th, td { padding: 12px; text-align: left; border-bottom: 1px solid #e2e8f0; }
            th { background-color: #f8fafc; color: #475569; font-weight: 600; }
            .paid { color: #10b981; }
            .unpaid { color: #ef4444; font-weight: bold; }
            .summary { float: right; width: 280px; border: 1px solid #e2e8f0; border-radius: 8px; padding: 15px; background: #f8fafc; margin-bottom: 40px; }
            .summary-row { display: flex; justify-content: space-between; margin-bottom: 8px; font-size: 16px; }
            .summary-row:last-child { margin-bottom: 0; font-weight: bold; border-top: 1px solid #cbd5e1; padding-top: 8px; margin-top: 8px; font-size: 18px; }
            .summary-label { color: #475569; font-weight: 500; }
            .summary-value { text-align: right; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>Generator Subscription Invoices</h1>
            <p><strong>Apartment:</strong> ${aptCode} &nbsp;|&nbsp; <strong>Tenant:</strong> ${tenantName}</p>
          </div>
          <table>
            <thead>
              <tr>
                <th>Period / Due Date</th>
                <th>Plan</th>
                <th>Cost</th>
                <th>Paid</th>
                <th>Remain</th>
              </tr>
            </thead>
            <tbody>
              ${tableRows}
            </tbody>
          </table>
          <div class="summary">
            <div class="summary-row">
              <span class="summary-label">Total Paid:</span> 
              <span class="summary-value paid">CFA ${totalPaid.toLocaleString()}</span>
            </div>
            <div class="summary-row">
              <span class="summary-label">Total Remaining:</span> 
              <span class="summary-value unpaid">CFA ${totalRemain.toLocaleString()}</span>
            </div>
          </div>
          <script>
            window.onload = function() { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

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

  const openConfig = (apt) => {
    setSelectedApt(apt.apartment_id);
    let type = apt.type || 'Meter';
    if (!apt.type) {
      if (apt.amps > 0) type = 'Fixed Amp';
      else if (apt.monthly_fee > 0) type = 'Fixed Monthly';
    }
    
    let tab = 'meter';
    if (type === 'Fixed Monthly') tab = 'fixed_monthly';
    if (type === 'Fixed Amp') tab = 'fixed_amp';

    setActiveTab(tab);
    
    setSubForm({
      type: type,
      amps: apt.amps || '',
      cost_per_amp: apt.cost_per_amp || '',
      monthly_fee: apt.monthly_fee || '',
      last_meter_reading: apt.last_meter_reading || '',
      current_reading: '',
      price_per_kwh: apt.price_per_kwh || ''
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
                    {!apt.subscription_id ? (
                      <span className="bg-slate-800 text-slate-400 px-3 py-1 rounded-full text-sm">No Plan</span>
                    ) : apt.type === 'Fixed Amp' ? (
                      <span className="bg-primary/20 text-indigo-300 px-3 py-1 rounded-full text-sm">
                        Fixed: {apt.amps} Amps (CFA {apt.monthly_fee})
                      </span>
                    ) : apt.type === 'Fixed Monthly' ? (
                      <span className="bg-primary/20 text-indigo-300 px-3 py-1 rounded-full text-sm">
                        Fixed Monthly: CFA {apt.monthly_fee}
                      </span>
                    ) : (
                      <span className="bg-slate-700/50 text-slate-300 px-3 py-1 rounded-full text-sm">Metered</span>
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
                  <td className="py-4 text-white font-medium">{(!apt.amps || apt.amps == 0) ? (apt.last_reading || apt.last_meter_reading || '-') : '-'}</td>
                  <td className="py-4 text-success font-medium"><DollarSign size={14} className="inline" /> {apt.paid_amount || 0}</td>
                  <td className="py-4">
                    {apt.unpaid_balance > 0 ? (
                      <span className="text-danger font-bold flex items-center gap-1"><DollarSign size={14} /> {apt.unpaid_balance}</span>
                    ) : (
                      <span className="text-success text-sm">{t('buildingsubscriptions.clear', { defaultValue: `Clear` })}</span>
                    )}
                  </td>
                  <td className="py-4 text-right flex justify-end gap-2">
                    <button 
                      onClick={() => setManageBillingApt(apt.apartment_id)} 
                      className="px-4 py-2 bg-primary hover:bg-indigo-600 text-white rounded-xl text-sm font-bold transition-all shadow-lg shadow-primary/20 flex items-center gap-2"
                    >
                      <Zap size={16} /> Manage Billing
                    </button>
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
                  
                  <div className="relative flex bg-slate-900 p-1 rounded-lg mb-6">
                    <button 
                      onClick={() => { setActiveTab('fixed_monthly'); setSubForm({...subForm, type: 'Fixed Monthly'}); }} 
                      className={`relative z-10 flex-1 py-2 text-sm font-bold transition-colors ${activeTab === 'fixed_monthly' ? 'text-white bg-primary rounded shadow' : 'text-slate-400 hover:text-white'}`}
                    >
                      Fixed Monthly
                    </button>
                    <button 
                      onClick={() => { setActiveTab('fixed_amp'); setSubForm({...subForm, type: 'Fixed Amp'}); }} 
                      className={`relative z-10 flex-1 py-2 text-sm font-bold transition-colors ${activeTab === 'fixed_amp' ? 'text-white bg-primary rounded shadow' : 'text-slate-400 hover:text-white'}`}
                    >
                      Fixed Amp
                    </button>
                    <button 
                      onClick={() => { setActiveTab('meter'); setSubForm({...subForm, type: 'Meter'}); }} 
                      className={`relative z-10 flex-1 py-2 text-sm font-bold transition-colors ${activeTab === 'meter' ? 'text-white bg-primary rounded shadow' : 'text-slate-400 hover:text-white'}`}
                    >
                      Meter Reading
                    </button>
                  </div>
                </>
              );
            })()}
            
            {activeTab === 'fixed_monthly' && (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Fixed Monthly Fee (CFA)</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={subForm.monthly_fee} onChange={e => setSubForm({...subForm, monthly_fee: e.target.value})} />
                </div>
                {/* Auto-date info */}
                <div className="flex items-start gap-3 p-3 bg-indigo-500/10 border border-indigo-500/30 rounded-xl">
                  <span className="text-indigo-400 text-lg mt-0.5">📅</span>
                  <div>
                    <p className="text-sm font-semibold text-indigo-300">Dates are set automatically</p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Start: <strong className="text-white">{new Date().toLocaleDateString('en-GB')}</strong> &nbsp;→&nbsp;
                      End: <strong className="text-white">{new Date(Date.now() + 30*24*60*60*1000).toLocaleDateString('en-GB')}</strong>
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Every new or renewed subscription runs exactly 30 days from today.</p>
                  </div>
                </div>
              </div>
            )}


            {activeTab === 'fixed_amp' && (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.amps', { defaultValue: `Amps` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={subForm.amps} onChange={e => setSubForm({...subForm, amps: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.cost_per_amp_cfa', { defaultValue: `Cost per Amp (CFA)` })}</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={subForm.cost_per_amp} onChange={e => setSubForm({...subForm, cost_per_amp: e.target.value})} />
                </div>
                {/* Auto-date info */}
                <div className="flex items-start gap-3 p-3 bg-indigo-500/10 border border-indigo-500/30 rounded-xl">
                  <span className="text-indigo-400 text-lg mt-0.5">📅</span>
                  <div>
                    <p className="text-sm font-semibold text-indigo-300">Dates are set automatically</p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Start: <strong className="text-white">{new Date().toLocaleDateString('en-GB')}</strong> &nbsp;→&nbsp;
                      End: <strong className="text-white">{new Date(Date.now() + 30*24*60*60*1000).toLocaleDateString('en-GB')}</strong>
                    </p>
                    <p className="text-xs text-slate-500 mt-1">Every new or renewed subscription runs exactly 30 days from today.</p>
                  </div>
                </div>
                <div className="pt-2">
                  <p className="text-sm text-muted">{t('buildingsubscriptions.monthly_fee', { defaultValue: `Monthly Fee:` })} <strong className="text-white">{t('buildingsubscriptions.cfa', { defaultValue: `CFA` })} {(subForm.amps * subForm.cost_per_amp) || 0}</strong></p>
                </div>
              </div>
            )}



            {activeTab === 'meter' && (
              <div className="space-y-4">
                <div className="grid grid-cols-3 gap-4">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Start kWh (Initial Reading)</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={subForm.last_meter_reading} onChange={e => setSubForm({...subForm, last_meter_reading: e.target.value})} placeholder="e.g., 1" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Current kWh (End of Month 1)</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={subForm.current_reading} onChange={e => setSubForm({...subForm, current_reading: e.target.value})} placeholder="e.g., 120" />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Price per kWh (CFA)</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={subForm.price_per_kwh} onChange={e => setSubForm({...subForm, price_per_kwh: e.target.value})} placeholder="e.g., 150" />
                  </div>
                </div>
                {/* Auto-date info */}
                <div className="flex items-start gap-3 p-3 bg-indigo-500/10 border border-indigo-500/30 rounded-xl">
                  <span className="text-indigo-400 text-lg mt-0.5">📅</span>
                  <div>
                    <p className="text-sm font-semibold text-indigo-300">Dates are set automatically</p>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Start: <strong className="text-white">{new Date().toLocaleDateString('en-GB')}</strong> &nbsp;→&nbsp;
                      End: <strong className="text-white">{new Date(Date.now() + 30*24*60*60*1000).toLocaleDateString('en-GB')}</strong>
                    </p>
                    <p className="text-xs text-slate-500 mt-1">The agent will capture the meter reading each month. Invoices are generated based on consumption.</p>
                  </div>
                </div>
              </div>
            )}


            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setSelectedApt(null)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('buildingsubscriptions.cancel', { defaultValue: `Cancel` })}</button>
              <button 
                onClick={() => {
                  monthlyMutation.mutate(subForm);
                }}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors"
                disabled={monthlyMutation.isLoading}
              >
                {monthlyMutation.isLoading ? 'Saving...' : 'Save Subscription'}
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
                          <div className="flex justify-end gap-2">
                            <button
                              onClick={() => {
                                setPayInvoiceModal(inv);
                                setPayInvoiceAmount(inv.amount - inv.amount_paid > 0 ? inv.amount - inv.amount_paid : 0);
                              }}
                              disabled={(inv.amount - inv.amount_paid) <= 0}
                              className="px-3 py-1 bg-primary/80 hover:bg-primary text-white rounded text-xs border border-primary/50 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
                            >
                              Pay Record
                            </button>
                            <button onClick={() => handlePrintInvoice(inv)} className="px-3 py-1 bg-indigo-500 hover:bg-indigo-600 text-white rounded text-xs shadow-md transition-colors">
                              Print
                            </button>
                          </div>
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
              <button onClick={handlePrintInvoiceList} className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors flex items-center gap-2">
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
            {(() => {
              const aptDetails = apartments?.find(a => a.apartment_id === renewModalApt);
              const isMetered = !aptDetails?.type || (aptDetails.type !== 'Fixed Amp' && aptDetails.type !== 'Fixed Monthly');

              if (isMetered) {
                return (
                  <div className="space-y-4">
                    <h2 className="text-2xl font-bold text-white mb-4">Direct Renew</h2>
                    <div className="bg-slate-800/50 p-4 rounded-lg border border-slate-700 flex justify-between items-center">
                       <span className="text-muted">Previous reading was {meterForm.previous_reading}. What is the current reading?</span>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">{t('buildingsubscriptions.current_reading', { defaultValue: `Current Reading` })}</label>
                      <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white text-xl font-bold" 
                        autoFocus
                        value={meterForm.current_reading} onChange={e => setMeterForm({...meterForm, current_reading: e.target.value})} />
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
                    <div className="flex justify-end gap-3 mt-8">
                      <button onClick={() => setRenewModalApt(null)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('buildingsubscriptions.cancel', { defaultValue: `Cancel` })}</button>
                      <button 
                        onClick={() => meterMutation.mutate({aptId: renewModalApt, data: meterForm})}
                        disabled={!meterForm.current_reading || meterMutation.isLoading}
                        className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors"
                      >
                        {meterMutation.isLoading ? 'Saving...' : 'Save & Renew'}
                      </button>
                    </div>
                  </div>
                );
              } else {
                return (
                  <>
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
                  </>
                );
              }
            })()}
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toast && (
        <div className={`fixed bottom-4 right-4 text-white px-6 py-3 rounded-lg shadow-2xl z-50 animate-bounce ${toast.type === 'error' ? 'bg-danger' : 'bg-emerald-600'}`}>
          {toast.message}
        </div>
      )}

      {/* Pay Invoice Modal */}
      {payInvoiceModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="glass-card p-6 w-full max-w-md border border-slate-700 animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-bold mb-2 text-white">Pay Invoice</h3>
            <p className="text-sm text-slate-400 mb-6 bg-slate-800/50 p-3 rounded-lg border border-slate-700">
              <span className="block mb-1">Due Date: <strong className="text-white">{payInvoiceModal.due_date}</strong></span>
              <span className="block mb-1">Total: <strong className="text-white">CFA {Number(payInvoiceModal.amount).toLocaleString()}</strong></span>
              <span className="block">Already Paid: <strong className="text-success">CFA {Number(payInvoiceModal.amount_paid || 0).toLocaleString()}</strong></span>
            </p>
            <div className="space-y-4 mb-6">
              <div>
                <label className="block text-sm font-medium text-muted mb-2">Amount to Pay (CFA)</label>
                <input
                  type="number"
                  min="1"
                  max={payInvoiceModal.amount - (payInvoiceModal.amount_paid || 0)}
                  value={payInvoiceAmount}
                  onChange={e => {
                    const val = Number(e.target.value);
                    const max = payInvoiceModal.amount - (payInvoiceModal.amount_paid || 0);
                    setPayInvoiceAmount(val > max ? max : e.target.value);
                  }}
                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary text-lg font-bold"
                  autoFocus
                />
                <p className="text-xs text-orange-400 mt-1">Remaining: CFA {(payInvoiceModal.amount - (payInvoiceModal.amount_paid || 0)).toLocaleString()}</p>
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-2">Payment Method</label>
                <select
                  value={payInvoiceMethod}
                  onChange={e => setPayInvoiceMethod(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                >
                  <option value="Cash">Cash</option>
                  <option value="Bank Transfer">Bank Transfer</option>
                  <option value="Mobile Money">Mobile Money</option>
                  <option value="Check">Check</option>
                </select>
              </div>
            </div>
            <div className="flex gap-3">
              <button
                onClick={() => { setPayInvoiceModal(null); setPayInvoiceAmount(''); setPayInvoiceMethod('Cash'); }}
                className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg flex-1 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => payInvoiceMutation.mutate({ id: payInvoiceModal.id, amount: Number(payInvoiceAmount) })}
                disabled={!payInvoiceAmount || Number(payInvoiceAmount) <= 0 || payInvoiceMutation.isPending}
                className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex-1 disabled:opacity-50 transition-colors font-medium shadow-lg shadow-primary/20"
              >
                {payInvoiceMutation.isPending ? 'Processing...' : 'Confirm Payment'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Render the new Unified Billing Modal */}
      {manageBillingApt && (
        <ApartmentBillingModal 
          apartmentId={manageBillingApt} 
          onClose={() => setManageBillingApt(null)} 
        />
      )}
    </div>
  );
};

export default BuildingSubscriptions;
