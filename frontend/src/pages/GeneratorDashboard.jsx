import React, { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { ArrowLeft, Battery, Droplet, Activity, Calendar, Clock, Plus, Settings, AlertTriangle } from 'lucide-react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  LineChart, Line
} from 'recharts';

import Tesseract from 'tesseract.js';

const GeneratorDashboard = () => {
  const { t } = useTranslation();
  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [showReportModal, setShowReportModal] = useState(false);
  const [showAddGenerator, setShowAddGenerator] = useState(false);
  const [showFuelModal, setShowFuelModal] = useState(false);
  const [showVerifyModal, setShowVerifyModal] = useState(false);
  const [verifyForm, setVerifyForm] = useState({ report_id: '', actual_fuel_remaining: '' });
  const [activeTab, setActiveTab] = useState('Overview');
  const [generatorForm, setGeneratorForm] = useState({
    name: '', fuel_capacity: '', capacity_kva: '', price_per_kw: '',
    model: '', serial_number: '', expected_fuel_consumption_per_hour: '', 
    expected_fuel_consumption_per_kwh: '', maintenance_interval_hours: 250, min_fuel_level_alert: 100,
    current_fuel: '', current_meter_reading: '', current_engine_hours: ''
  });
  const [ocrLoading, setOcrLoading] = useState(false);
  const [reportForm, setReportForm] = useState({
    date: new Date().toISOString().split('T')[0],
    meter_hours: '',
    meter_minutes: '',
    current_kwh: '',
    notes: '',
    photo: null,
    fuel_photo: null
  });
  
  const [fuelForm, setFuelForm] = useState({
    date: new Date().toISOString().split('T')[0],
    type: 'Refill',
    amount: '',
    cost_per_liter: '',
    supplier_id: '',
    notes: '',
    receipt: null
  });

  const { data: fuelMovements, isLoading: fuelLoading } = useQuery({
    queryKey: ['fuelMovements', id],
    queryFn: async () => {
      const res = await api.get(`/fuel/generators/${id}/movements`);
      return res.data;
    },
    enabled: activeTab === 'Fuel'
  });

  const { data: stats, isLoading, error } = useQuery({
    queryKey: ['generatorStats', id],
    queryFn: async () => {
      const res = await api.get(`/energy/generators/${id}/stats`);
      return res.data;
    },
    retry: false
  });

  const { data: reports } = useQuery({
    queryKey: ['generatorReports', stats?.generator?.id],
    queryFn: async () => {
      const res = await api.get(`/energy/generators/${stats.generator.id}/reports`);
      return res.data;
    },
    enabled: !!stats?.generator?.id
  });

  const { data: aiInsights } = useQuery({
    queryKey: ['generatorAIInsights', stats?.generator?.id],
    queryFn: async () => {
      const res = await api.get(`/energy/generators/${stats.generator.id}/ai-insights`);
      return res.data;
    },
    enabled: !!stats?.generator?.id
  });

  const previousReport = useMemo(() => {
    if (!reports) return null;
    return reports.find(r => r.date < reportForm.date);
  }, [reports, reportForm.date]);

  const reportMutation = useMutation({
    mutationFn: (data) => {
      const formData = new FormData();
      formData.append('generator_id', stats?.generator?.id || id);
      
      const payload = { ...data };
      const hours = parseFloat(payload.meter_hours || 0);
      const minutes = parseFloat(payload.meter_minutes || 0);
      payload.meter_hours = (hours + (minutes / 60)).toFixed(2);
      delete payload.meter_minutes;

      Object.keys(payload).forEach(key => {
        if (payload[key] !== null) formData.append(key, payload[key]);
      });
      return api.post('/energy/reports', formData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['generatorStats', id]);
      queryClient.invalidateQueries(['generatorReports', stats?.generator?.id]);
      setShowReportModal(false);
      setReportForm({
        date: new Date().toISOString().split('T')[0],
        meter_hours: '', meter_minutes: '', current_kwh: '', notes: '', photo: null, fuel_photo: null
      });
    }
  });

  const verifyMutation = useMutation({
    mutationFn: (data) => api.post('/energy/reports/verify', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['generatorStats', id]);
      queryClient.invalidateQueries(['generatorReports', stats?.generator?.id]);
      setShowVerifyModal(false);
    }
  });

  const fuelMutation = useMutation({
    mutationFn: (data) => {
      const formData = new FormData();
      formData.append('generator_id', stats?.generator?.id || id);
      Object.keys(data).forEach(key => {
        if (data[key] !== null) formData.append(key, data[key]);
      });
      return api.post('/fuel/movements', formData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['fuelMovements', id]);
      queryClient.invalidateQueries(['generatorStats', id]);
      setShowFuelModal(false);
      setFuelForm({
        date: new Date().toISOString().split('T')[0],
        type: 'Refill', amount: '', cost_per_liter: '', supplier_id: '', notes: '', receipt: null
      });
    }
  });

  const { data: suppliers } = useQuery({
    queryKey: ['fuelSuppliers'],
    queryFn: async () => {
      const res = await api.get('/fuel/suppliers');
      return res.data;
    }
  });

  const handlePhotoUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setReportForm({ ...reportForm, photo: file });
      setOcrLoading(true);
      Tesseract.recognize(
        file,
        'eng',
        { logger: m => console.log(m) }
      ).then(({ data: { text } }) => {
        // Extract numbers from text (simplistic matching)
        const numbers = text.replace(/[^0-9]/g, '');
        if (numbers) {
          setReportForm(prev => ({ ...prev, current_kwh: numbers }));
        }
        setOcrLoading(false);
      }).catch(err => {
        console.error(err);
        setOcrLoading(false);
      });
    }
  };

  const handleFuelPhotoUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setReportForm({ ...reportForm, fuel_photo: file });
    }
  };

  const openReportModal = () => {
    setReportForm({
        date: new Date().toISOString().split('T')[0],
        meter_hours: '', 
        meter_minutes: '',
        current_kwh: '',
        notes: '', photo: null, fuel_photo: null
    });
    setShowReportModal(true);
  };

  const createGeneratorMutation = useMutation({
    mutationFn: (data) => api.post('/energy/generators', { ...data, building_id: id }),
    onSuccess: () => {
      queryClient.invalidateQueries(['generatorStats', id]);
      setShowAddGenerator(false);
    }
  });

  const statusMutation = useMutation({
    mutationFn: (status) => api.put(`/energy/generators/${stats?.generator?.id}/status`, { status }),
    onSuccess: () => queryClient.invalidateQueries(['generatorStats', id])
  });

  const deleteGeneratorMutation = useMutation({
    mutationFn: () => api.delete(`/energy/generators/${stats?.generator?.id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['generatorStats', id]);
      window.location.reload();
    }
  });

  if (isLoading) {
    return (
      <div className="flex-1 p-8 flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  if ((error && error.response?.status === 404) || (!isLoading && stats && !stats.generator)) {
    return (
      <div className="flex h-full w-full overflow-hidden bg-background">
        <div className="flex-1 overflow-y-auto p-8 flex flex-col items-center justify-center">
           <div className="bg-slate-800 p-4 rounded-full text-warning mb-6">
              <Activity size={48} />
           </div>
           <h2 className="text-2xl font-bold text-white mb-2">{t('generator.no_generator')}</h2>
           <p className="text-muted mb-8 text-center max-w-md">This building does not have a generator registered yet. You need to create a generator record first.</p>
           <div className="flex gap-4">
             <button 
                onClick={() => setShowAddGenerator(true)}
                className="bg-primary hover:bg-indigo-600 text-white px-6 py-3 rounded-xl transition-colors font-medium flex items-center gap-2 shadow-lg shadow-primary/30"
             >
                <Plus size={18} /> Register Generator
             </button>
             <button 
                onClick={() => navigate('/buildings')}
                className="bg-slate-800 hover:bg-slate-700 text-white px-6 py-3 rounded-xl transition-colors font-medium flex items-center gap-2"
             >
                <ArrowLeft size={18} /> Back to Buildings
             </button>
           </div>

           {/* Add Generator Modal */}
           {showAddGenerator && (
             <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
               <div className="glass-card w-full max-w-md p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200 text-left">
                 <h2 className="text-2xl font-bold text-white mb-6">{t('generator.register_title')}</h2>
                 <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-2 hide-scrollbar">
                   <div className="grid grid-cols-2 gap-4">
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Generator Name</label>
                       <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         placeholder={t('generator.name')}
                         value={generatorForm.name} onChange={e => setGeneratorForm({...generatorForm, name: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Model</label>
                       <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.model} onChange={e => setGeneratorForm({...generatorForm, model: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Serial Number</label>
                       <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.serial_number} onChange={e => setGeneratorForm({...generatorForm, serial_number: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Fuel Tank Capacity (Liters)</label>
                       <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.fuel_capacity} onChange={e => setGeneratorForm({...generatorForm, fuel_capacity: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Initial Fuel Level (Liters)</label>
                       <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.current_fuel} onChange={e => setGeneratorForm({...generatorForm, current_fuel: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-warning mb-1">Initial Meter Reading (kWh)</label>
                       <input type="number" className="w-full bg-warning/10 border border-warning/30 rounded-lg px-4 py-2 text-warning placeholder-warning/50" 
                         placeholder="Current meter state"
                         value={generatorForm.current_meter_reading} onChange={e => setGeneratorForm({...generatorForm, current_meter_reading: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-warning mb-1">Initial Engine Hours (h)</label>
                       <input type="number" step="0.01" className="w-full bg-warning/10 border border-warning/30 rounded-lg px-4 py-2 text-warning placeholder-warning/50" 
                         placeholder="Current hours"
                         value={generatorForm.current_engine_hours} onChange={e => setGeneratorForm({...generatorForm, current_engine_hours: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Capacity (KVA)</label>
                       <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.capacity_kva} onChange={e => setGeneratorForm({...generatorForm, capacity_kva: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Exp. Fuel / Hour (L)</label>
                       <input type="number" step="0.1" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.expected_fuel_consumption_per_hour} onChange={e => setGeneratorForm({...generatorForm, expected_fuel_consumption_per_hour: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Exp. Fuel / KWH (L)</label>
                       <input type="number" step="0.01" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.expected_fuel_consumption_per_kwh} onChange={e => setGeneratorForm({...generatorForm, expected_fuel_consumption_per_kwh: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Maintenance Interval (Hrs)</label>
                       <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.maintenance_interval_hours} onChange={e => setGeneratorForm({...generatorForm, maintenance_interval_hours: e.target.value})} />
                     </div>
                     <div>
                       <label className="block text-sm font-medium text-muted mb-1">Min Fuel Alert (Liters)</label>
                       <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                         value={generatorForm.min_fuel_level_alert} onChange={e => setGeneratorForm({...generatorForm, min_fuel_level_alert: e.target.value})} />
                     </div>
                   </div>
                 </div>
                 <div className="flex justify-end gap-3 mt-8 pt-4 border-t border-slate-700">
                   <button onClick={() => setShowAddGenerator(false)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('generator.cancel')}</button>
                   <button 
                     onClick={() => createGeneratorMutation.mutate(generatorForm)}
                     className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors"
                     disabled={createGeneratorMutation.isLoading || !generatorForm.name}
                   >
                     {createGeneratorMutation.isLoading ? 'Saving...' : 'Register'}
                   </button>
                 </div>
               </div>
             </div>
           )}

        </div>
      </div>
    );
  }

  const { generator, today, month, predictions } = stats || {};

  // Prepare chart data from reports (reverse to show chronological if sorted desc)
  const chartData = reports ? [...reports].reverse().slice(-14) : [];

  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex items-center gap-4 mb-8">
          <button onClick={() => navigate('/buildings')} className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-white transition-colors">
            <ArrowLeft size={20} />
          </button>
          <div>
            <h1 className="text-3xl font-bold text-white">{generator?.name || t('energy.generator')} Dashboard</h1>
            <div className="flex items-center mt-1 gap-2">
              <span className="text-muted">Status:</span>
              <select 
                value={generator?.status || 'Offline'}
                onChange={(e) => statusMutation.mutate(e.target.value)}
                disabled={statusMutation.isLoading}
                className={`bg-slate-800 border border-slate-700 rounded-lg px-2 py-1 text-sm outline-none focus:border-primary ${
                  generator?.status === 'Running' ? 'text-success' : 
                  generator?.status === 'Maintenance' ? 'text-warning' : 'text-slate-400'
                }`}
              >
                <option value="Running" className="text-success">Running</option>
                <option value="Maintenance" className="text-warning">Maintenance</option>
                <option value="Offline" className="text-slate-400">Offline</option>
              </select>
              {statusMutation.isLoading && <span className="text-xs text-muted animate-pulse">Updating...</span>}
              <button 
                onClick={() => {
                  if(window.confirm('Are you sure you want to permanently delete this generator and all its data?')) {
                    deleteGeneratorMutation.mutate();
                  }
                }}
                className="ml-4 p-1.5 bg-danger/10 text-danger hover:bg-danger hover:text-white rounded transition-colors text-xs flex items-center gap-1"
                title="Delete Generator"
              >
                Delete Generator
              </button>
            </div>
          </div>
          <div className="ml-auto flex gap-3">
            <button 
              onClick={openReportModal}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30"
            >
              <Plus size={20} />
              <span>{t('energy.add_reading')}</span>
            </button>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-6 border-b border-slate-700 mb-8">
          <button 
            onClick={() => setActiveTab('Overview')} 
            className={`font-medium pb-4 px-2 transition-colors ${activeTab === 'Overview' ? 'text-primary border-b-2 border-primary' : 'text-muted hover:text-slate-300'}`}
          >
            Overview & AI Analytics
          </button>
          <button 
            onClick={() => setActiveTab('Fuel')} 
            className={`font-medium pb-4 px-2 transition-colors ${activeTab === 'Fuel' ? 'text-primary border-b-2 border-primary' : 'text-muted hover:text-slate-300'}`}
          >
            Fuel Management (Enterprise)
          </button>
        </div>

        {activeTab === 'Overview' && (
          <>
            {/* Real-time Status Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="glass-card p-6 border border-slate-700/50">
            <div className="flex justify-between items-start mb-4">
              <h3 className="text-muted font-medium text-sm uppercase tracking-wider">{t('generator.current_est')}</h3>
              <Droplet size={18} className="text-blue-400" />
            </div>
            <div className="text-3xl font-bold text-white mb-4">{generator?.current_fuel || 0} <span className="text-lg text-muted font-normal">{t('generator.liters')}</span></div>
            
            {reports && reports.length > 0 && reports[0].status === 'Pending Verification' ? (
              <button 
                onClick={() => {
                  setVerifyForm({ report_id: reports[0].id, actual_fuel_remaining: generator?.current_fuel || '' });
                  setShowVerifyModal(true);
                }}
                className="w-full text-center bg-blue-500/20 hover:bg-blue-500/40 text-blue-400 text-sm font-medium py-2 rounded-lg transition-colors border border-blue-500/30"
              >
                Tell Me Actual Remaining Fuel
              </button>
            ) : (
              <div className="text-sm text-success text-center py-2 bg-success/10 rounded-lg border border-success/20">
                Latest Reading Verified
              </div>
            )}
            
            <div className="w-full bg-slate-800 rounded-full h-1.5 mt-4">
              <div className="bg-blue-500 h-1.5 rounded-full" style={{ width: `${Math.min(100, ((generator?.current_fuel || 0) / (generator?.fuel_capacity || 1)) * 100)}%` }}></div>
            </div>
          </div>
          
          <div className="glass-card p-6 border border-slate-700/50">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-muted font-medium text-sm uppercase tracking-wider">{t('generator.spare')}</h3>
              <Battery size={18} className="text-warning" />
            </div>
            <div className="text-3xl font-bold text-white">{generator?.spare_fuel || 0} <span className="text-lg text-muted font-normal">{t('generator.liters')}</span></div>
          </div>

          <div className="glass-card p-6 border border-slate-700/50">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-muted font-medium text-sm uppercase tracking-wider">{t('generator.kwh_today')}</h3>
              <Activity size={18} className="text-success" />
            </div>
            <div className="text-3xl font-bold text-white">{today?.kwh_produced || 0}</div>
            <p className="text-sm text-success mt-2">↑ Active</p>
          </div>

          <div className="glass-card p-6 border border-slate-700/50">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-muted font-medium text-sm uppercase tracking-wider">{t('generator.efficiency')}</h3>
              <Settings size={18} className="text-primary" />
            </div>
            <div className="text-3xl font-bold text-white">{month?.efficiency_score || 0}</div>
            <p className="text-sm text-muted mt-2">kWh per Liter (Month)</p>
          </div>
        </div>

        {/* AI Analytics Section */}
        {aiInsights && (
          <div className="mb-8 border-t border-slate-700/50 pt-8">
            <h2 className="text-xl font-bold text-white mb-6 flex items-center gap-2">
              <span className="bg-primary/20 text-primary p-2 rounded-lg"><Activity size={20} /></span>
              Python AI Engine Insights
            </h2>
            
            {/* Alerts */}
            {aiInsights.active_alerts && aiInsights.active_alerts.length > 0 && (
              <div className="mb-6 space-y-3">
                {aiInsights.active_alerts.map(alert => (
                  <div key={alert.id} className={`p-4 rounded-xl border flex items-start gap-3 shadow-lg ${
                    alert.severity === 'Critical' ? 'bg-danger/10 border-danger/30 text-danger shadow-danger/10' :
                    alert.severity === 'High' ? 'bg-warning/10 border-warning/30 text-warning shadow-warning/10' :
                    'bg-info/10 border-info/30 text-info shadow-info/10'
                  }`}>
                    <AlertTriangle className="shrink-0 mt-0.5" />
                    <div>
                      <h4 className="font-bold">{alert.alert_type} (Severity: {alert.severity})</h4>
                      <p className="text-sm opacity-90 mt-1">{alert.message}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Predictions */}
              {aiInsights.predictions ? (
                <div className="glass-card p-6 border border-slate-700/50 lg:col-span-2">
                  <h3 className="text-lg font-bold text-white mb-4">AI Predictions for Tomorrow</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="p-4 bg-slate-900/50 rounded-xl border border-slate-700 flex flex-col justify-center">
                      <p className="text-xs text-muted mb-1 uppercase tracking-wider">Expected Fuel Use</p>
                      <p className="text-2xl font-bold text-blue-400">{aiInsights.predictions.predicted_fuel} L</p>
                    </div>
                    <div className="p-4 bg-slate-900/50 rounded-xl border border-slate-700 flex flex-col justify-center">
                      <p className="text-xs text-muted mb-1 uppercase tracking-wider">Expected Cost</p>
                      <p className="text-2xl font-bold text-danger">CFA {aiInsights.predictions.predicted_cost}</p>
                    </div>
                    <div className="p-4 bg-slate-900/50 rounded-xl border border-slate-700 flex flex-col justify-center">
                      <p className="text-xs text-muted mb-1 uppercase tracking-wider">Days Remaining</p>
                      <p className="text-2xl font-bold text-success">{aiInsights.predictions.predicted_remaining_days}</p>
                    </div>
                    <div className="p-4 bg-slate-900/50 rounded-xl border border-slate-700 flex flex-col justify-center">
                      <p className="text-xs text-muted mb-1 uppercase tracking-wider">Target Efficiency</p>
                      <p className="text-2xl font-bold text-primary">{aiInsights.predictions.predicted_efficiency}%</p>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="glass-card p-6 border border-slate-700/50 lg:col-span-2 flex items-center justify-center text-slate-500">
                  <p>Nightly predictions have not run yet.</p>
                </div>
              )}

              {/* Health Score */}
              {aiInsights.latest_analysis ? (
                <div className="glass-card p-6 border border-slate-700/50 flex flex-col items-center justify-center">
                  <h3 className="text-lg font-bold text-white mb-4 self-start">Overall Health Score</h3>
                  <div className="relative w-32 h-32 flex items-center justify-center mt-2">
                    <svg className="w-full h-full transform -rotate-90">
                      <circle cx="64" cy="64" r="56" className="stroke-slate-700" strokeWidth="12" fill="none" />
                      <circle cx="64" cy="64" r="56" className={`stroke-current transition-all duration-1000 ${
                        aiInsights.latest_analysis.health_score >= 90 ? 'text-success' :
                        aiInsights.latest_analysis.health_score >= 70 ? 'text-warning' : 'text-danger'
                      }`} strokeWidth="12" fill="none" strokeDasharray="351.8" strokeDashoffset={351.8 - (351.8 * aiInsights.latest_analysis.health_score) / 100} strokeLinecap="round" />
                    </svg>
                    <div className="absolute flex flex-col items-center justify-center">
                      <span className="text-4xl font-bold text-white">{aiInsights.latest_analysis.health_score}</span>
                    </div>
                  </div>
                  <p className={`text-sm mt-6 font-medium text-center ${
                        aiInsights.latest_analysis.health_score >= 90 ? 'text-success' :
                        aiInsights.latest_analysis.health_score >= 70 ? 'text-warning' : 'text-danger'
                      }`}>
                    {aiInsights.latest_analysis.health_score >= 90 ? 'Optimal Performance' : 
                     aiInsights.latest_analysis.health_score >= 70 ? 'Needs Attention' : 'Critical Issues Detected'}
                  </p>
                </div>
              ) : (
                <div className="glass-card p-6 border border-slate-700/50 flex flex-col items-center justify-center text-slate-500">
                  <p>Awaiting first reading analysis.</p>
                </div>
              )}
            </div>
          </div>
        )}

        {/* Charts */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
           <div className="glass-card p-6">
            <h3 className="text-lg font-bold text-white mb-6">Fuel Usage vs Production (Last 14 Days)</h3>
            <div className="w-full h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" vertical={false} />
                  <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis yAxisId="left" stroke="#3b82f6" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis yAxisId="right" orientation="right" stroke="#10b981" fontSize={12} tickLine={false} axisLine={false} />
                  <RechartsTooltip 
                    contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }}
                  />
                  <Bar yAxisId="left" dataKey="fuel_added" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Fuel Used (L)" />
                  <Bar yAxisId="right" dataKey="kwh_produced" fill="#10b981" radius={[4, 4, 0, 0]} name="Production (kWh)" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* Recent Reports Table */}
        <div className="glass-card p-6">
          <h2 className="text-xl font-bold text-white mb-6">{t('generator.recent_reports')}</h2>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-700 text-sm text-muted">
                  <th className="pb-3 font-medium">Date</th>
                  <th className="pb-3 font-medium">Energy Produced</th>
                  <th className="pb-3 font-medium">{t('generator.th_run')}</th>
                  <th className="pb-3 font-medium">Est. Used (L)</th>
                  <th className="pb-3 font-medium">Actual Used (L)</th>
                  <th className="pb-3 font-medium">Score (kWh/L)</th>
                  <th className="pb-3 font-medium">Photos</th>
                  <th className="pb-3 font-medium">Status</th>
                  <th className="pb-3 font-medium">Action</th>
                </tr>
              </thead>
              <tbody>
                {reports?.slice(0, 10).map((report, index, array) => {
                  const previousReport = array[index + 1];
                  let dateDisplay = new Date(report.date).toLocaleDateString();
                  if (previousReport) {
                    const prevDateStr = new Date(previousReport.date).toLocaleDateString();
                    if (prevDateStr !== dateDisplay) {
                      dateDisplay = `${prevDateStr} - ${dateDisplay}`;
                    }
                  } else if (report.notes === 'Initial Baseline Reading' || report.kwh_produced == 0) {
                    dateDisplay = `${dateDisplay} (Baseline)`;
                  }

                  return (
                  <tr key={report.id} className="border-b border-slate-800/50 hover:bg-slate-800/20 transition-colors">
                    <td className="py-4 text-white text-sm whitespace-nowrap">{dateDisplay}</td>
                    <td className="py-4 text-success font-bold text-sm">+{report.kwh_produced} kWh</td>
                    <td className="py-4 text-white text-sm">{report.running_hours}h</td>
                    <td className="py-4 text-muted text-sm">{report.estimated_fuel_used ? parseFloat(report.estimated_fuel_used).toFixed(1) : '-'} L</td>
                    <td className="py-4 text-white font-bold text-sm">{report.actual_fuel_used !== null ? `${parseFloat(report.actual_fuel_used).toFixed(1)} L` : '-'}</td>
                    <td className="py-4 text-indigo-300 font-bold text-sm">{report.efficiency_score ? parseFloat(report.efficiency_score).toFixed(2) : '-'}</td>
                    <td className="py-4 text-sm flex flex-col gap-1">
                      {report.photo_path && <a href={`${api.defaults.baseURL.replace('/api', '')}/${report.photo_path}`} target="_blank" rel="noreferrer" className="text-primary hover:underline text-xs">Meter Photo</a>}
                      {report.fuel_photo_path && <a href={`${api.defaults.baseURL.replace('/api', '')}/${report.fuel_photo_path}`} target="_blank" rel="noreferrer" className="text-blue-400 hover:underline text-xs">Fuel Photo</a>}
                    </td>
                    <td className="py-4 text-sm">
                      <span className={`px-2 py-1 rounded text-xs font-bold ${
                        report.status === 'Verified' ? 'bg-success/20 text-success' : 
                        report.status === 'Rejected' ? 'bg-danger/20 text-danger' :
                        report.status === 'Flagged' ? 'bg-warning/20 text-warning' : 'bg-slate-700 text-slate-300'
                      }`}>
                        {report.status || 'Verified'}
                      </span>
                    </td>
                    <td className="py-4 text-sm">
                      <button 
                        onClick={() => {
                          setVerifyForm({ 
                            report_id: report.id, 
                            actual_fuel_remaining: report.actual_fuel_remaining || generator?.current_fuel || '',
                            report_data: report
                          });
                          setShowVerifyModal(true);
                        }}
                        className="bg-indigo-500/20 hover:bg-indigo-500/40 text-indigo-300 border border-indigo-500/30 px-4 py-1.5 rounded-lg text-xs font-bold transition-colors shadow-lg shadow-indigo-500/20"
                      >
                        {report.status === 'Verified' ? 'View / Edit' : 'Analyze'}
                      </button>
                    </td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
        </>
        )}

        {activeTab === 'Fuel' && (
          <div className="space-y-6 animate-in fade-in zoom-in duration-300">
            <div className="flex justify-between items-center">
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <Droplet className="text-blue-500" /> Fuel Movement Audit
              </h2>
              <button 
                className="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-lg text-sm font-medium transition-colors border border-slate-700"
                onClick={() => setShowFuelModal(true)}
              >
                + Record Movement
              </button>
            </div>
            
            <div className="glass-card p-0 overflow-hidden">
              {fuelLoading ? (
                <div className="p-8 text-center text-muted">Loading fuel data...</div>
              ) : (
                <table className="w-full text-left border-collapse">
                  <thead className="bg-slate-800/50">
                    <tr className="border-b border-slate-700 text-xs text-muted uppercase tracking-wider">
                      <th className="p-4 font-medium">Date</th>
                      <th className="p-4 font-medium">Type</th>
                      <th className="p-4 font-medium">Amount (L)</th>
                      <th className="p-4 font-medium">Cost / L</th>
                      <th className="p-4 font-medium">Supplier</th>
                      <th className="p-4 font-medium">User</th>
                      <th className="p-4 font-medium">Notes</th>
                    </tr>
                  </thead>
                  <tbody>
                    {fuelMovements?.map((m) => (
                      <tr key={m.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors text-sm">
                        <td className="p-4 text-white">{new Date(m.date).toLocaleString()}</td>
                        <td className="p-4">
                          <span className={`px-2 py-1 rounded text-xs font-bold ${
                            m.type === 'Refill' ? 'bg-success/20 text-success' :
                            m.type === 'Transfer_Out' ? 'bg-danger/20 text-danger' :
                            m.type === 'Adjustment' ? 'bg-warning/20 text-warning' : 'bg-primary/20 text-primary'
                          }`}>
                            {m.type.replace('_', ' ')}
                          </span>
                        </td>
                        <td className="p-4 text-white font-bold">{m.amount} L</td>
                        <td className="p-4 text-muted">{m.cost_per_liter ? `CFA ${m.cost_per_liter}` : '-'}</td>
                        <td className="p-4 text-muted">{m.supplier_name || '-'}</td>
                        <td className="p-4 text-muted">{m.user_name || 'System'}</td>
                        <td className="p-4 text-muted">{m.notes || '-'}</td>
                      </tr>
                    ))}
                    {(!fuelMovements || fuelMovements.length === 0) && (
                      <tr>
                        <td colSpan="7" className="p-8 text-center text-muted italic">{t('generator.no_fuel')}</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              )}
            </div>
          </div>
        )}

      </div>

      {/* Right Panel: Smart Predictions */}
      <div className="hidden xl:flex w-80 glass-panel p-6 flex-col overflow-y-auto hide-scrollbar z-10 border-l border-slate-800">
        <h2 className="text-xl font-bold text-white mb-6">{t('generator.system_analytics')}</h2>
        
        <div className="space-y-6">
          <div className="p-5 glass-card relative overflow-hidden bg-slate-800/50 border border-slate-700">
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('generator.enterprise_health')}</h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.health_score')}</span>
                <span className={`font-bold ${generator?.health_score < 70 ? 'text-danger' : 'text-success'}`}>{generator?.health_score || 100}%</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.efficiency')}</span>
                <span className="text-white font-bold">{generator?.efficiency_score || 100}%</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.fuel_accuracy')}</span>
                <span className="text-white font-bold">{generator?.fuel_accuracy_score || 100}%</span>
              </div>
            </div>
          </div>

          <div className="p-5 glass-card relative overflow-hidden bg-slate-800/50 border border-slate-700">
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('generator.fuel_estimations')}</h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.avg_daily')}</span>
                <span className="text-white font-bold">{predictions?.avg_daily_fuel} L</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.est_days')}</span>
                <span className={`font-bold ${predictions?.estimated_remaining_days < 7 ? 'text-danger' : 'text-success'}`}>
                  {predictions?.estimated_remaining_days} Days
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted text-sm">Fuel Needed (Next Mo.)</span>
                <span className="text-warning font-bold">{predictions?.fuel_next_month} L</span>
              </div>
            </div>
          </div>
          
          <div className="p-5 glass-card relative overflow-hidden bg-slate-800/50 border border-slate-700">
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('generator.sys_rec')}</h3>
            <div className="text-sm text-indigo-200 bg-primary/10 p-4 rounded-lg border border-primary/20">
              <p>Based on current consumption trends, you should purchase approximately <strong className="text-white">{predictions?.fuel_next_month} liters</strong> of diesel for next month. Estimated cost: <strong className="text-white">CFA {predictions?.cost_next_month}</strong>.</p>
            </div>
          </div>

          <div className="p-5 glass-card relative overflow-hidden bg-slate-800/50 border border-slate-700">
             <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('generator.elec_proj')}</h3>
              <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('generator.next_week')}</span>
                <span className="text-white font-bold">{predictions?.next_week_kwh} kWh</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted text-sm">{t('generator.next_month')}</span>
                <span className="text-white font-bold">{predictions?.next_month_kwh} kWh</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Report Modal */}
      {showReportModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-2xl p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <h2 className="text-2xl font-bold text-white mb-6">{t('energy.add_reading')}</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Date</label>
                <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                  value={reportForm.date} onChange={e => setReportForm({...reportForm, date: e.target.value})} />
              </div>
              <div className="col-span-1">
                <div className="flex justify-between items-end mb-1">
                  <label className="block text-sm font-medium text-muted">Current Engine Hours <span className="text-xs opacity-70 font-normal">(Optional)</span></label>
                  <span className="text-xs text-indigo-300 font-medium">Previous: {previousReport?.meter_hours || previousReport?.current_meter_hours || 0}h</span>
                </div>
                <div className="flex gap-2">
                  <div className="flex-1">
                    <input type="number" placeholder={t('generator.init_hours')} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={reportForm.meter_hours} onChange={e => setReportForm({...reportForm, meter_hours: e.target.value})} />
                  </div>
                  <div className="flex-1">
                    <input type="number" placeholder="Minutes" min="0" max="59" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                      value={reportForm.meter_minutes} onChange={e => setReportForm({...reportForm, meter_minutes: e.target.value})} />
                  </div>
                </div>
              </div>
              <div className="col-span-2">
                <div className="flex justify-between items-end mb-1">
                  <label className="block text-sm font-medium text-muted">Current Meter Reading (kWh) <span className="text-xs opacity-70 font-normal">(Optional if no meter)</span></label>
                  <span className="text-xs text-indigo-300 font-medium">Previous: {previousReport?.current_kwh || 0} kWh</span>
                </div>
                <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                  value={reportForm.current_kwh} onChange={e => setReportForm({...reportForm, current_kwh: e.target.value})} />
              </div>
              <div className="col-span-2">
                <label className="block text-sm font-medium text-muted mb-1">Photo of Generator Screen (Optional for Admin)</label>
                <div className="flex items-center gap-2">
                  <input type="file" accept="image/*" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-1.5 text-white file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-white hover:file:bg-indigo-600" 
                    onChange={handlePhotoUpload} />
                  {ocrLoading && <span className="text-xs text-primary animate-pulse">Reading...</span>}
                </div>
              </div>
              <div className="col-span-2">
                <label className="block text-sm font-medium text-muted mb-1">Fuel Gauge Photo (Optional)</label>
                <input type="file" accept="image/*" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-1.5 text-white file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-600 file:text-white hover:file:bg-blue-500" 
                  onChange={handleFuelPhotoUpload} />
              </div>

              <div className="col-span-2">
                <label className="block text-sm font-medium text-muted mb-1">Notes</label>
                <textarea className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" rows="3"
                  value={reportForm.notes} onChange={e => setReportForm({...reportForm, notes: e.target.value})}></textarea>
              </div>
            </div>
            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setShowReportModal(false)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('generator.cancel')}</button>
              <button 
                onClick={() => reportMutation.mutate(reportForm)}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors disabled:opacity-50"
                disabled={reportMutation.isLoading || !reportForm.photo}
              >
                {reportMutation.isLoading ? 'Submitting...' : 'Submit Reading'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Verify Fuel Modal (Manager AI Analysis) */}
      {showVerifyModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-lg p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200 text-left">
            <div className="flex items-center gap-3 mb-6 border-b border-slate-700/50 pb-4">
              <div className="bg-primary/20 p-2 rounded-lg text-primary">
                <Activity size={24} />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white">{t('generator.verify_title')}</h2>
                <p className="text-sm text-muted mt-1">{t('generator.verify_sub')}</p>
              </div>
            </div>

            <div className="space-y-6">
              {/* Report Details & AI Checks */}
              <div className="grid grid-cols-2 gap-4">
                 <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <h3 className="text-xs font-bold text-muted uppercase tracking-wider mb-3">{t('generator.meter_readings')}</h3>
                    <div className="space-y-2 text-sm">
                       <div className="flex justify-between"><span className="text-muted">Previous Meter:</span> <span className="text-white">{verifyForm.report_data?.previous_kwh || '-'}</span></div>
                       <div className="flex justify-between"><span className="text-muted">Current Meter:</span> <span className="text-white font-bold">{verifyForm.report_data?.current_kwh || '-'}</span></div>
                       <div className="flex justify-between"><span className="text-muted">Current Hours:</span> <span className="text-white">{verifyForm.report_data?.meter_hours || '-'}</span></div>
                    </div>
                 </div>
                 <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                    <h3 className="text-xs font-bold text-muted uppercase tracking-wider mb-3">{t('generator.performance')}</h3>
                    <div className="space-y-2 text-sm">
                       <div className="flex justify-between"><span className="text-muted">Energy Produced:</span> <span className="text-success font-bold">+{verifyForm.report_data?.kwh_produced} kWh</span></div>
                       <div className="flex justify-between"><span className="text-muted">Engine Run Time:</span> <span className="text-indigo-300 font-bold">{verifyForm.report_data?.running_hours} h</span></div>
                       <div className="flex justify-between"><span className="text-warning/80 font-bold">Est. Fuel Spent Today:</span> <span className="text-warning font-bold bg-warning/20 px-2 py-0.5 rounded">{verifyForm.report_data?.estimated_fuel_used ? parseFloat(verifyForm.report_data.estimated_fuel_used).toFixed(1) : '-'} L</span></div>
                       <div className="flex justify-between"><span className="text-indigo-300/80 font-bold">Est. Fuel Remaining:</span> <span className="text-white font-bold bg-indigo-500/20 px-2 py-0.5 rounded">{verifyForm.report_data?.estimated_fuel_remaining ? parseFloat(verifyForm.report_data.estimated_fuel_remaining).toFixed(1) : '-'} L</span></div>
                    </div>
                 </div>
              </div>

              {/* Manager Input */}
              <div className="bg-blue-500/10 p-5 rounded-xl border border-blue-500/20">
                <label className="block text-sm font-bold text-blue-200 mb-2">
                  What is the Actual Fuel Liter Remaining in the tank?
                </label>
                <p className="text-xs text-blue-300/70 mb-4">
                  If it is not the same as the system estimate, the AI will analyze it to detect leaks, theft, or sensor issues. Leave blank if you haven't checked and want to accept the system's estimate.
                </p>
                <div className="flex items-center gap-4">
                  <input type="number" className="w-full bg-slate-900 border border-blue-500/30 rounded-lg px-4 py-3 text-white text-xl font-bold focus:border-blue-500 focus:ring-1 focus:ring-blue-500 outline-none transition-all placeholder-blue-300/30" 
                    placeholder={`System Estimate: CFA ${parseFloat(verifyForm.report_data?.estimated_fuel_remaining || 0).toFixed(1)}`}
                    value={verifyForm.actual_fuel_remaining} 
                    onChange={e => setVerifyForm({...verifyForm, actual_fuel_remaining: e.target.value})} 
                    autoFocus
                  />
                  <span className="text-muted font-medium text-lg">{t('generator.liters')}</span>
                </div>
              </div>

              {/* Dynamic AI Feedback */}
              {(() => {
                const estimated = parseFloat(verifyForm.report_data?.estimated_fuel_remaining);
                const actual = verifyForm.actual_fuel_remaining === '' ? estimated : parseFloat(verifyForm.actual_fuel_remaining);
                
                if (isNaN(actual) || isNaN(estimated)) return null;
                
                const diff = actual - estimated;
                const diffPercentage = estimated > 0 ? (diff / estimated) * 100 : 0;
                const runningHours = parseFloat(verifyForm.report_data?.running_hours || 1);
                const estimatedFuelUsed = parseFloat(verifyForm.report_data?.estimated_fuel_used || 0);
                const avgConsumptionPerHour = runningHours > 0 ? (estimatedFuelUsed / runningHours).toFixed(1) : 0;
                const avgDailyConsumption = stats?.predictions?.avg_daily_fuel || '-';
                const remainingDays = stats?.predictions?.estimated_remaining_days || '-';
                
                let title = "";
                let titleColor = "";
                let description = "";
                let recommendation = "";
                let colorClass = "";
                let icon = null;

                const absDiff = Math.abs(diff);

                if (diff === 0) {
                  title = t('generator.ai_verification_success_title', { defaultValue: "Fuel verification successful." });
                  titleColor = "text-success";
                  description = t('generator.ai_verification_success_desc', { defaultValue: "Actual fuel matches the system estimate." });
                  colorClass = "bg-success/10 border-success/30 text-success";
                  icon = <Activity size={24} />;
                } else if (absDiff <= 10) {
                  title = t('generator.ai_verification_small_title', { defaultValue: "Small fuel difference detected." });
                  titleColor = "text-warning";
                  description = t('generator.ai_verification_small_desc', { defaultValue: "This may be caused by:\n• Manual gauge reading variation.\n• Previous reading adjustments.\n• Small unrecorded fuel additions.\n• Generator consumption differences.\n\nPlease verify before confirming." });
                  recommendation = t('generator.ai_verification_small_rec', { defaultValue: "Accept the reading and continue monitoring." });
                  colorClass = "bg-warning/10 border-warning/40 text-yellow-100";
                  icon = <Activity size={24} className="text-warning" />;
                } else if (absDiff <= 20) {
                  title = t('generator.ai_verification_medium_title', { defaultValue: "Medium fuel difference detected." });
                  titleColor = "text-orange-400";
                  description = t('generator.ai_verification_medium_desc', { defaultValue: "This may be caused by:\n• Unrecorded fuel additions.\n• Generator consumption differences.\n\nPlease verify before confirming." });
                  recommendation = t('generator.ai_verification_medium_rec', { defaultValue: "Review today's fuel transactions." });
                  colorClass = "bg-orange-500/10 border-orange-500/40 text-orange-100";
                  icon = <AlertTriangle size={24} className="text-orange-400" />;
                } else {
                  title = t('generator.ai_verification_large_title', { defaultValue: "Significant fuel difference detected." });
                  titleColor = "text-danger";
                  description = t('generator.ai_verification_large_desc', { defaultValue: "Recommended actions:\n• Verify fuel additions.\n• Verify previous readings.\n• Verify gauge measurements.\n• Check for data entry mistakes.\n\nDo not automatically assume theft or fuel leakage." });
                  recommendation = t('generator.ai_verification_large_rec', { defaultValue: "Verify all readings before saving." });
                  colorClass = "bg-danger/10 border-danger/40 text-red-100";
                  icon = <AlertTriangle size={24} className="text-danger" />;
                }

                return (
                  <div className={`p-5 rounded-xl border animate-in fade-in slide-in-from-bottom-2 ${colorClass}`}>
                    <div className="flex items-start gap-4 mb-4">
                      <div className="mt-1 shrink-0">{icon}</div>
                      <div>
                        <h4 className={`text-lg font-bold ${titleColor} mb-1`}>{title}</h4>
                        {diff !== 0 && (
                          <p className="text-sm font-semibold opacity-90 mb-2">{t('generator.fuel_diff_detected', { defaultValue: 'Fuel Difference Detected:' })} {diff > 0 ? '+' : ''}{diff.toFixed(1)} {t('generator.liters')}</p>
                        )}
                        <p className="text-sm opacity-80 whitespace-pre-line leading-relaxed">{description}</p>
                        {recommendation && (
                          <div className="mt-4 p-3 bg-black/30 rounded-lg border border-white/10 flex flex-col gap-1">
                            <span className="font-bold text-white text-sm">{t('generator.recommendation', { defaultValue: 'Recommendation:' })}</span> 
                            <span className="text-sm">{recommendation}</span>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Detailed Analysis */}
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6 border-t border-white/10 pt-5">
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.estimated')}</div>
                        <div className="font-bold text-lg">{estimated.toFixed(1)} <span className="text-sm font-normal">L</span></div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.actual')}</div>
                        <div className="font-bold text-lg">{actual.toFixed(1)} <span className="text-sm font-normal">L</span></div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.difference')}</div>
                        <div className="font-bold text-lg">{diff > 0 ? '+' : ''}{diff.toFixed(1)} <span className="text-sm font-normal">L</span></div>
                        <div className="text-xs opacity-70">{diffPercentage > 0 ? '+' : ''}{diffPercentage.toFixed(1)}%</div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.energy_produced', { defaultValue: 'Energy Produced' })}</div>
                        <div className="font-bold text-lg text-success">+{verifyForm.report_data?.kwh_produced || 0} <span className="text-sm font-normal">kWh</span></div>
                        <div className="text-xs opacity-70">
                           {verifyForm.report_data?.running_hours || 0} {t('generator.hours', { defaultValue: 'hours' })}
                        </div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.avg_per_hour', { defaultValue: 'Avg per Hour' })}</div>
                        <div className="font-bold text-lg">{avgConsumptionPerHour} <span className="text-sm font-normal">L/h</span></div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">{t('generator.avg_daily_use', { defaultValue: 'Avg Daily Use' })}</div>
                        <div className="font-bold text-lg">{avgDailyConsumption} <span className="text-sm font-normal">L</span></div>
                      </div>
                      <div className="bg-black/20 p-3 rounded-lg border border-white/5 md:col-span-3">
                        <div className="text-[10px] opacity-70 uppercase tracking-wider mb-1">Remaining Prediction</div>
                        <div className="font-bold text-lg">{remainingDays} <span className="text-sm font-normal">Days</span></div>
                      </div>
                    </div>
                  </div>
                );
              })()}
            </div>

            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setShowVerifyModal(false)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('generator.cancel')}</button>
              <button 
                onClick={() => {
                  const finalFuel = verifyForm.actual_fuel_remaining === '' 
                    ? verifyForm.report_data?.estimated_fuel_remaining 
                    : verifyForm.actual_fuel_remaining;
                  verifyMutation.mutate({ ...verifyForm, actual_fuel_remaining: finalFuel });
                }}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors font-bold"
                disabled={verifyMutation.isLoading}
              >
                {verifyMutation.isLoading ? 'Analyzing...' : 'Run AI Analysis & Verify'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Fuel Movement Modal */}
      {showFuelModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="glass-card w-full max-w-lg p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200 text-left">
            <h2 className="text-2xl font-bold text-white mb-6">Record Fuel Movement</h2>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Date</label>
                  <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={fuelForm.date} onChange={e => setFuelForm({...fuelForm, date: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Movement Type</label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white"
                    value={fuelForm.type} onChange={e => setFuelForm({...fuelForm, type: e.target.value})}>
                    <option value="Refill">Refill</option>
                    <option value="Transfer_In">Transfer In</option>
                    <option value="Transfer_Out">Transfer Out</option>
                    <option value="Adjustment">Adjustment</option>
                  </select>
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Amount (Liters)</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={fuelForm.amount} onChange={e => setFuelForm({...fuelForm, amount: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Cost per Liter (CFA)</label>
                  <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" 
                    value={fuelForm.cost_per_liter} onChange={e => setFuelForm({...fuelForm, cost_per_liter: e.target.value})} />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Supplier</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white"
                  value={fuelForm.supplier_id} onChange={e => setFuelForm({...fuelForm, supplier_id: e.target.value})}>
                  <option value="">-- Select Supplier (Optional) --</option>
                  {suppliers?.map(s => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Receipt Photo</label>
                <input type="file" accept="image/*" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-1.5 text-white file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-primary file:text-white hover:file:bg-indigo-600" 
                  onChange={(e) => setFuelForm({...fuelForm, receipt: e.target.files[0]})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Notes</label>
                <textarea className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white" rows="3"
                  value={fuelForm.notes} onChange={e => setFuelForm({...fuelForm, notes: e.target.value})}></textarea>
              </div>
            </div>
            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setShowFuelModal(false)} className="px-6 py-2 rounded-lg text-white hover:bg-slate-800 transition-colors">{t('generator.cancel')}</button>
              <button 
                onClick={() => fuelMutation.mutate(fuelForm)}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg shadow-lg shadow-primary/30 transition-colors"
                disabled={fuelMutation.isLoading || !fuelForm.amount}
              >
                {fuelMutation.isLoading ? 'Saving...' : 'Record Movement'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default GeneratorDashboard;
