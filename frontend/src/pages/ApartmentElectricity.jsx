import { useTranslation } from 'react-i18next';
import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { ArrowLeft, Zap, FileText, TrendingUp, DollarSign, Copy } from 'lucide-react';

import Tesseract from 'tesseract.js';

const ApartmentElectricity = () => {
  const { t } = useTranslation();

  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('meter'); // 'meter' or 'subscription'
  const [toastMsg, setToastMsg] = useState('');
  const [ocrLoading, setOcrLoading] = useState(false);
  
  // Meter form state
  const [meterForm, setMeterForm] = useState({
    previous_reading: '', current_reading: '', price_per_kwh: '', reading_date: new Date().toISOString().split('T')[0], photo: null
  });

  // Subscription form state
  const [subForm, setSubForm] = useState({
    monthly_fee: '', start_date: new Date().toISOString().split('T')[0], end_date: '', status: 'Active'
  });

  const { data: readings } = useQuery({
    queryKey: ['meterReadings', id],
    queryFn: async () => {
      const res = await api.get(`/energy/apartments/${id}/meter-readings`);
      return res.data;
    }
  });

  const { data: invoices } = useQuery({
    queryKey: ['electricityInvoices', id],
    queryFn: async () => {
      const res = await api.get(`/electricity/apartments/${id}/invoices`);
      return res.data;
    }
  });

  const { data: analysis } = useQuery({
    queryKey: ['apartmentAnalysis', id],
    queryFn: async () => {
      const res = await api.get(`/electricity/apartments/${id}/analysis`);
      return res.data;
    }
  });

  const { data: activeSub } = useQuery({
    queryKey: ['apartmentSubscription', id],
    queryFn: async () => {
      const res = await api.get(`/energy/apartments/${id}/subscriptions`);
      return res.data;
    }
  });

  useEffect(() => {
    if (activeSub && activeSub.status !== 'None') {
      setSubForm({
        monthly_fee: activeSub.monthly_fee || '',
        start_date: activeSub.start_date || new Date().toISOString().split('T')[0],
        end_date: activeSub.end_date || '',
        status: activeSub.status || 'Active'
      });
    }
  }, [activeSub]);

  useEffect(() => {
    if (readings && readings.length > 0 && meterForm.previous_reading === '') {
      setMeterForm(prev => ({ ...prev, previous_reading: readings[0].current_reading || readings[0].consumption }));
    }
  }, [readings]);

  const consumption = (parseFloat(meterForm.current_reading) || 0) - (parseFloat(meterForm.previous_reading) || 0);
  const estimatedCost = consumption > 0 ? consumption * (parseFloat(meterForm.price_per_kwh) || 0) : 0;

  const handlePhotoUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setMeterForm({ ...meterForm, photo: file });
      setOcrLoading(true);
      Tesseract.recognize(
        file,
        'eng',
        { logger: m => console.log(m) }
      ).then(({ data: { text } }) => {
        // Simple extraction of the largest number or last numbers
        const numbers = text.replace(/[^0-9]/g, '');
        if (numbers) {
          setMeterForm(prev => ({ ...prev, current_reading: numbers }));
        }
        setOcrLoading(false);
      }).catch(err => {
        console.error(err);
        setOcrLoading(false);
      });
    }
  };

  const meterMutation = useMutation({
    mutationFn: (data) => {
      const formData = new FormData();
      formData.append('apartment_id', id);
      Object.keys(data).forEach(key => {
        if (data[key] !== null) formData.append(key, data[key]);
      });
      return api.post(`/energy/apartments/${id}/meter-readings`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['meterReadings', id]);
      queryClient.invalidateQueries(['electricityInvoices', id]);
      queryClient.invalidateQueries(['apartmentAnalysis', id]);
      setMeterForm({...meterForm, previous_reading: meterForm.current_reading, current_reading: '', photo: null});
    }
  });

  const subMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${id}/subscriptions`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['apartmentSubscription', id]);
      queryClient.invalidateQueries(['electricityInvoices', id]);
      setToastMsg('Subscription saved successfully!');
      setTimeout(() => setToastMsg(''), 3000);
    }
  });

  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex items-center gap-4 mb-8">
          <button onClick={() => navigate('/apartments')} className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-white transition-colors">
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-white">{t('apartmentelectricity.apartment_electricity', { defaultValue: `Apartment Electricity` })}</h1>
            <p className="text-muted mt-1">{t('apartmentelectricity.manage_billing_and_usage_for_t', { defaultValue: `Manage billing and usage for this unit` })}</p>
          </div>
        </div>

        {/* Smart Analysis Panel */}
        <div className="mb-8 p-6 glass-card relative overflow-hidden border border-primary/20 bg-primary/5">
          <div className="absolute top-0 right-0 w-32 h-32 bg-primary/10 rounded-bl-full -z-10 blur-xl"></div>
          <h3 className="text-lg font-bold text-white mb-2 flex items-center gap-2">
            <Zap size={20} className="text-primary" /> {t('apartmentelectricity.smart_analysis', { defaultValue: `Smart Analysis` })}
          </h3>
          <p className="text-muted mb-4">{analysis?.insight || 'Loading analysis...'}</p>
          <div className="flex gap-8">
             <div>
                <p className="text-sm text-slate-400 uppercase tracking-wider mb-1">{t('apartmentelectricity.latest_consumption', { defaultValue: `Latest Consumption` })}</p>
                <p className="text-2xl font-bold text-white">{analysis?.latest_consumption || 0} <span className="text-sm font-normal text-muted">{t('apartmentelectricity.kwh', { defaultValue: `kWh` })}</span></p>
             </div>
             <div>
                <p className="text-sm text-slate-400 uppercase tracking-wider mb-1">{t('apartmentelectricity.building_average', { defaultValue: `Building Average` })}</p>
                <p className="text-2xl font-bold text-white">{analysis?.building_average || 0} <span className="text-sm font-normal text-muted">{t('apartmentelectricity.kwh', { defaultValue: `kWh` })}</span></p>
             </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex space-x-4 mb-6 border-b border-slate-700 pb-2">
          <button 
            onClick={() => setActiveTab('meter')}
            className={`px-4 py-2 font-medium transition-colors ${activeTab === 'meter' ? 'text-primary border-b-2 border-primary' : 'text-muted hover:text-white'}`}
          >
            {t('apartmentelectricity.meter_reading', { defaultValue: `Meter Reading` })}
          </button>
          <button 
            onClick={() => setActiveTab('subscription')}
            className={`px-4 py-2 font-medium transition-colors ${activeTab === 'subscription' ? 'text-primary border-b-2 border-primary' : 'text-muted hover:text-white'}`}
          >
            {t('apartmentelectricity.fixed_subscription', { defaultValue: `Fixed Subscription` })}
          </button>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          
          {/* Action Form */}
          <div>
            {activeTab === 'meter' ? (
              <div className="glass-card p-6">
                <h3 className="text-lg font-bold text-white mb-4">{t('apartmentelectricity.record_new_reading', { defaultValue: `Record New Reading` })}</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.date', { defaultValue: `Date` })}</label>
                    <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={meterForm.reading_date} onChange={e => setMeterForm({...meterForm, reading_date: e.target.value})} />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.previous_kwh', { defaultValue: `Previous (kWh)` })}</label>
                      <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                        value={meterForm.previous_reading} onChange={e => setMeterForm({...meterForm, previous_reading: e.target.value})} />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.current_kwh', { defaultValue: `Current (kWh)` })}</label>
                      <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                        value={meterForm.current_reading} onChange={e => setMeterForm({...meterForm, current_reading: e.target.value})} />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.price_per_kwh_cfa', { defaultValue: `Price per kWh (CFA)` })}</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={meterForm.price_per_kwh} onChange={e => setMeterForm({...meterForm, price_per_kwh: e.target.value})} />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.meter_photo_required', { defaultValue: `Meter Photo (Required)` })}</label>
                    <div className="flex items-center gap-2">
                      <input type="file" accept="image/*" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-1.5 text-white file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-white hover:file:bg-indigo-600" 
                        onChange={handlePhotoUpload} />
                      {ocrLoading && <span className="text-xs text-primary animate-pulse">{t('apartmentelectricity.reading_ocr', { defaultValue: `Reading OCR...` })}</span>}
                    </div>
                  </div>
                  
                  {meterForm.current_reading && (
                    <div className="bg-slate-900/80 p-5 rounded-xl border border-slate-700/50 mt-6 flex justify-between items-center shadow-inner">
                      <div>
                        <p className="text-xs text-muted uppercase tracking-wider mb-1 font-semibold">{t('apartmentelectricity.consumption', { defaultValue: `Consumption` })}</p>
                        <p className={`text-xl font-bold ${consumption > 0 ? 'text-indigo-300' : 'text-danger'}`}>{consumption} {t('apartmentelectricity.kwh', { defaultValue: `kWh` })}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-muted uppercase tracking-wider mb-1 font-semibold">{t('apartmentelectricity.estimated_cost', { defaultValue: `Estimated Cost` })}</p>
                        <p className={`text-2xl font-black ${consumption > 0 ? 'text-success' : 'text-danger'}`}>{t('apartmentelectricity.cfa', { defaultValue: `CFA` })} {estimatedCost.toLocaleString(undefined, { minimumFractionDigits: 0 })}</p>
                      </div>
                    </div>
                  )}

                  <button 
                    onClick={() => meterMutation.mutate(meterForm)}
                    disabled={meterMutation.isLoading || !meterForm.current_reading || !meterForm.photo}
                    className="w-full bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg transition-colors mt-4 disabled:opacity-50"
                  >
                    {t('apartmentelectricity.submit_generate_invoice', { defaultValue: `Submit & Generate Invoice` })}
                  </button>
                </div>
              </div>
            ) : (
              <div className="glass-card p-6">
                <h3 className="text-lg font-bold text-white mb-4">{t('apartmentelectricity.subscription_settings', { defaultValue: `Subscription Settings` })}</h3>
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.monthly_fee_cfa', { defaultValue: `Monthly Fee (CFA)` })}</label>
                    <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={subForm.monthly_fee} onChange={e => setSubForm({...subForm, monthly_fee: e.target.value})} />
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.start_date', { defaultValue: `Start Date` })}</label>
                      <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                        value={subForm.start_date} onChange={e => setSubForm({...subForm, start_date: e.target.value})} />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.end_date', { defaultValue: `End Date` })}</label>
                      <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                        value={subForm.end_date} onChange={e => setSubForm({...subForm, end_date: e.target.value})} />
                    </div>
                  </div>
                  <div>
                     <label className="block text-sm font-medium text-muted mb-1">{t('apartmentelectricity.status', { defaultValue: `Status` })}</label>
                     <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white"
                        value={subForm.status} onChange={e => setSubForm({...subForm, status: e.target.value})}>
                        <option value="Active">{t('apartmentelectricity.active', { defaultValue: `Active` })}</option>
                        <option value="Inactive">{t('apartmentelectricity.inactive', { defaultValue: `Inactive` })}</option>
                     </select>
                  </div>
                  <button 
                    onClick={() => subMutation.mutate(subForm)}
                    disabled={subMutation.isLoading}
                    className="w-full bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg transition-colors mt-4"
                  >
                    {t('apartmentelectricity.save_subscription', { defaultValue: `Save Subscription` })}
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* History Lists */}
          <div className="space-y-6">
            <div className="glass-card p-6">
               <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2"><FileText size={18} /> {t('apartmentelectricity.recent_invoices', { defaultValue: `Recent Invoices` })}</h3>
               {invoices?.length === 0 ? <p className="text-muted text-sm">{t('apartmentelectricity.no_invoices_found', { defaultValue: `No invoices found.` })}</p> : (
                 <div className="space-y-3">
                   {Array.isArray(invoices) && invoices.slice(0, 5).map(inv => (
                     <div key={inv.id} className="flex justify-between items-center p-3 bg-slate-800/50 rounded-lg border border-slate-700/50">
                        <div className="flex justify-between items-center w-full">
                            <div>
                               <p className="font-medium text-white">{t('apartmentelectricity.cfa', { defaultValue: `CFA` })} {inv.amount}</p>
                               <p className="text-xs text-muted">{t('apartmentelectricity.due', { defaultValue: `Due:` })} {new Date(inv.due_date).toLocaleDateString()} | {inv.type}</p>
                            </div>
                            <div className="flex items-center gap-3">
                               <span className={`px-2 py-1 text-xs rounded-full ${inv.status === 'Paid' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'}`}>
                                 {inv.status}
                               </span>
                               <button 
                                 onClick={() => {
                                   navigator.clipboard.writeText(`Generator/Electricity Bill (${inv.type}) - ${new Date(inv.due_date).toLocaleDateString()}\nTotal Due: CFA ${inv.amount} CFA\nStatus: CFA ${inv.status}`);
                                   setToastMsg('Copied to clipboard!');
                                   setTimeout(() => setToastMsg(''), 3000);
                                 }}
                                 className="p-2 bg-slate-700/50 hover:bg-slate-600 rounded-lg text-indigo-300 transition-colors"
                                 title={t('apartmentelectricity.copy_details_for_tenant', { defaultValue: `Copy details for tenant` })}
                               >
                                 <Copy size={16} />
                               </button>
                            </div>
                        </div>
                     </div>
                   ))}
                 </div>
               )}
            </div>

             {activeTab === 'meter' && (
                <div className="glass-card p-6">
                  <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2"><TrendingUp size={18} /> {t('apartmentelectricity.reading_history', { defaultValue: `Reading History` })}</h3>
                  {readings?.length === 0 ? <p className="text-muted text-sm">{t('apartmentelectricity.no_readings_found', { defaultValue: `No readings found.` })}</p> : (
                    <div className="space-y-3">
                      {Array.isArray(readings) && readings.slice(0, 5).map(read => (
                        <div key={read.id} className="flex justify-between items-center p-3 bg-slate-800/50 rounded-lg border border-slate-700/50">
                            <div className="flex justify-between items-center w-full">
                                <div>
                                  <p className="font-medium text-white">{read.consumption} {t('apartmentelectricity.kwh', { defaultValue: `kWh` })}</p>
                                  <p className="text-xs text-muted">{new Date(read.reading_date).toLocaleDateString()}</p>
                                </div>
                                <div className="text-right">
                                   <p className="font-medium text-white">{t('apartmentelectricity.cfa', { defaultValue: `CFA` })} {read.bill_amount}</p>
                                   <p className="text-xs text-muted">{t('apartmentelectricity.cfa', { defaultValue: `@ CFA` })} {read.price_per_kwh}</p>
                                </div>
                                <div className="text-right flex flex-col items-end gap-1">
                                    <span className={`px-2 py-0.5 text-[10px] font-bold uppercase rounded-full ${
                                        read.status === 'Verified' ? 'bg-success/20 text-success' : 
                                        read.status === 'Rejected' ? 'bg-danger/20 text-danger' : 'bg-warning/20 text-warning'
                                    }`}>
                                        {read.status}
                                    </span>
                                    {read.photo_path && (
                                        <a href={`${api.defaults.baseURL.replace('/api', '')}/${read.photo_path}`} target="_blank" rel="noreferrer" className="text-xs text-primary hover:underline flex items-center gap-1">
                                            {t('apartmentelectricity.view_photo', { defaultValue: `View Photo` })}
                                        </a>
                                    )}
                                </div>
                                <button 
                                  onClick={() => {
                                    navigator.clipboard.writeText(`Electricity Bill - ${new Date(read.reading_date).toLocaleDateString()}\nConsumed: CFA ${read.consumption} kWh\nRate: CFA ${read.price_per_kwh} CFA/kWh\nTotal Due: CFA ${read.bill_amount} CFA`);
                                    setToastMsg('Copied to clipboard!');
                                    setTimeout(() => setToastMsg(''), 3000);
                                  }}
                                  className="ml-4 p-2 bg-slate-700/50 hover:bg-slate-600 rounded-lg text-indigo-300 transition-colors"
                                  title={t('apartmentelectricity.copy_details_for_tenant', { defaultValue: `Copy details for tenant` })}
                                >
                                  <Copy size={16} />
                                </button>
                            </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
             )}
          </div>

        </div>
      </div>

      {/* Toast Notification */}
      {toastMsg && (
        <div className="fixed bottom-4 right-4 bg-success text-white px-6 py-3 rounded-lg shadow-xl animate-in fade-in slide-in-from-bottom-4 flex items-center gap-2 z-50">
          <Zap size={18} />
          <span className="font-medium">{toastMsg}</span>
        </div>
      )}
    </div>
  );
};

export default ApartmentElectricity;
