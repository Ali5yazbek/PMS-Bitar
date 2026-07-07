import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { 
  Zap, Activity, Droplet, DollarSign, Clock, AlertTriangle, 
  Calendar as CalendarIcon, FileSpreadsheet, Printer, Bot, Plus, X 
} from 'lucide-react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip, ResponsiveContainer,
  LineChart, Line
} from 'recharts';
import Tesseract from 'tesseract.js';
import GeneratorCalendar from '../components/GeneratorCalendar';
import AIChatAssistant from '../components/AIChatAssistant';
import { exportToExcel, printToPDF } from '../utils/ExportUtils';

const EnergyManagement = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [showReportModal, setShowReportModal] = useState(false);
  const [ocrLoading, setOcrLoading] = useState(false);
  const [reportForm, setReportForm] = useState({
    date: new Date().toISOString().split('T')[0],
    generator_id: '',
    meter_hours: '',
    current_kwh: '',
    notes: '',
    photo: null
  });

  // Queries
  const { data: executiveData, isLoading: execLoading } = useQuery({
    queryKey: ['executiveDashboard'],
    queryFn: async () => {
      const res = await api.get('/energy/executive-dashboard');
      return res.data;
    }
  });

  const { data: aiSummaries, isLoading: aiLoading } = useQuery({
    queryKey: ['aiSummaries'],
    queryFn: async () => {
      const res = await api.get('/energy/ai/summaries');
      return res.data;
    }
  });

  const { data: calendarEvents } = useQuery({
    queryKey: ['calendarEvents'],
    queryFn: async () => {
      const res = await api.get('/energy/calendar');
      return res.data;
    }
  });

  const reportMutation = useMutation({
    mutationFn: (data) => {
      const formData = new FormData();
      Object.keys(data).forEach(key => {
        if (data[key] !== null) formData.append(key, data[key]);
      });
      return api.post('/energy/reports', formData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['executiveDashboard']);
      queryClient.invalidateQueries(['aiSummaries']);
      queryClient.invalidateQueries(['calendarEvents']);
      setShowReportModal(false);
      setReportForm({
        date: new Date().toISOString().split('T')[0],
        generator_id: '', meter_hours: '', current_kwh: '', notes: '', photo: null
      });
    }
  });

  const handlePhotoUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      setReportForm({ ...reportForm, photo: file });
      setOcrLoading(true);
      Tesseract.recognize(file, 'eng', { logger: m => console.log(m) })
        .then(({ data: { text } }) => {
          const numbers = text.replace(/[^0-9]/g, '');
          if (numbers) setReportForm(prev => ({ ...prev, current_kwh: numbers }));
          setOcrLoading(false);
        })
        .catch(err => {
          console.error(err);
          setOcrLoading(false);
        });
    }
  };

  const handleExportExcel = () => {
    if (!executiveData?.generators) return;
    
    // Format data for export
    const exportData = executiveData.generators.map(g => ({
      ID: g.id,
      Name: g.name,
      Building: g.building_name || 'N/A',
      Status: g.status,
      Capacity_KVA: g.capacity_kva,
      Current_Fuel_Liters: g.current_fuel,
      Expected_L_per_H: g.expected_fuel_consumption_per_hour,
      Health_Score: g.health_score + '%'
    }));

    exportToExcel(exportData, 'Generators_Fleet_Status');
  };

  if (execLoading || aiLoading) {
    return (
      <div className="flex-1 p-8 flex items-center justify-center h-full bg-background">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  const generators = executiveData?.generators || [];
  const chartData = executiveData?.chart || [];

  // Calculate global totals from the chart (last 30 days) or generators
  const totalFuelConsumed = chartData.reduce((acc, curr) => acc + parseFloat(curr.total_fuel_used || 0), 0);
  const totalCost = chartData.reduce((acc, curr) => acc + parseFloat(curr.total_cost || 0), 0);
  const totalKwh = chartData.reduce((acc, curr) => acc + parseFloat(curr.total_kwh || 0), 0);
  const currentFuelGlobal = generators.reduce((acc, curr) => acc + parseFloat(curr.current_fuel || 0), 0);
  
  // Averages
  const avgLKwh = totalKwh > 0 ? (totalFuelConsumed / totalKwh).toFixed(2) : 0;

  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      {/* Main Scrollable Content */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0 print:overflow-visible">
        
        {/* Header & Actions */}
        <div className="flex justify-between items-center mb-8 print:mb-4">
          <div>
            <h1 className="text-3xl font-bold text-white print:text-black">{t('energy.title')}</h1>
            <p className="text-muted mt-1 print:text-gray-600">{t('energy.subtitle')}</p>
          </div>
          <div className="flex items-center gap-3 print:hidden">
            <button onClick={() => setShowReportModal(true)} className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30">
              <Plus size={18} /><span>{t('energy.add_reading')}</span>
            </button>
            <button onClick={handleExportExcel} className="bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400 border border-emerald-500/30 px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors">
              <FileSpreadsheet size={18} /><span>{t('energy.export_excel')}</span>
            </button>
            <button onClick={printToPDF} className="bg-slate-800 hover:bg-slate-700 text-white border border-slate-700 px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors">
              <Printer size={18} /><span>{t('energy.print_pdf')}</span>
            </button>
          </div>
        </div>

        {/* Top KPI Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="glass-card p-6 relative overflow-hidden group print:border-gray-300 print:bg-white">
            <div className="absolute top-0 right-0 w-24 h-24 bg-primary/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform"></div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-muted font-medium print:text-gray-600">{t('energy.total_fuel')}</h3>
              <div className="bg-primary/20 p-2 rounded-lg text-primary print:hidden"><Droplet size={20} /></div>
            </div>
            <p className="text-3xl font-bold text-white print:text-black">{Math.round(totalFuelConsumed).toLocaleString()} L</p>
            <p className="text-sm text-muted mt-2">{t('energy.last_30')}</p>
          </div>

          <div className="glass-card p-6 relative overflow-hidden group border border-danger/20 print:border-gray-300 print:bg-white">
            <div className="absolute top-0 right-0 w-24 h-24 bg-danger/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform"></div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-muted font-medium print:text-gray-600">{t('energy.total_cost')}</h3>
              <div className="bg-danger/20 p-2 rounded-lg text-danger print:hidden"><DollarSign size={20} /></div>
            </div>
            <p className="text-3xl font-bold text-white print:text-black">CFA {Math.round(totalCost).toLocaleString()}</p>
            <p className="text-sm text-danger mt-2">Estimated (30 Days)</p>
          </div>

          <div className="glass-card p-6 relative overflow-hidden group border border-success/20 print:border-gray-300 print:bg-white">
            <div className="absolute top-0 right-0 w-24 h-24 bg-success/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform"></div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-muted font-medium print:text-gray-600">{t('energy.total_energy')}</h3>
              <div className="bg-success/20 p-2 rounded-lg text-success print:hidden"><Activity size={20} /></div>
            </div>
            <p className="text-3xl font-bold text-white print:text-black">{Math.round(totalKwh).toLocaleString()} kWh</p>
            <p className="text-sm text-success mt-2">Avg {avgLKwh} L/kWh</p>
          </div>

          <div className="glass-card p-6 relative overflow-hidden group print:border-gray-300 print:bg-white">
            <div className="absolute top-0 right-0 w-24 h-24 bg-blue-500/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform"></div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-muted font-medium print:text-gray-600">{t('energy.current_fleet')}</h3>
              <div className="bg-blue-500/20 p-2 rounded-lg text-blue-400 print:hidden"><Droplet size={20} /></div>
            </div>
            <p className="text-3xl font-bold text-white print:text-black">{Math.round(currentFuelGlobal).toLocaleString()} L</p>
            <p className="text-sm text-blue-400 mt-2">Across {generators.length} Generators</p>
          </div>
        </div>

        {/* Middle Section: Fleet Overview & Calendar */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-8">
          
          {/* Fleet Status List */}
          <div className="xl:col-span-1 glass-card p-6 flex flex-col max-h-[500px]">
            <h3 className="text-lg font-bold text-white mb-4 print:text-black">{t('energy.fleet_status')}</h3>
            <div className="flex-1 overflow-y-auto hide-scrollbar space-y-3 pr-2">
              {generators.map(g => (
                <div key={g.id} className="bg-slate-800/50 p-4 rounded-xl border border-slate-700 hover:border-primary/50 transition-colors print:border-gray-300 print:bg-white">
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-bold text-white print:text-black">{g.name}</h4>
                    <span className={`text-xs px-2 py-0.5 rounded font-bold ${
                      g.status === 'Running' ? 'bg-success/20 text-success' :
                      g.status === 'Maintenance' ? 'bg-warning/20 text-warning' : 'bg-slate-700 text-slate-300'
                    }`}>
                      {g.status}
                    </span>
                  </div>
                  <div className="flex justify-between text-sm mt-3">
                    <span className="text-muted">Fuel: <span className="text-blue-300 font-medium">{Math.round(g.current_fuel)} L</span></span>
                    <span className="text-muted">Health: <span className={g.health_score > 80 ? 'text-success' : 'text-warning'}>{g.health_score}%</span></span>
                  </div>
                  <div className="w-full bg-slate-900 rounded-full h-1.5 mt-2 print:hidden">
                    <div className="bg-blue-500 h-1.5 rounded-full" style={{ width: `${Math.min(100, (g.current_fuel / (g.fuel_capacity || 1000)) * 100)}%` }}></div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Calendar */}
          <div className="xl:col-span-2 glass-card p-6 flex items-center justify-center bg-slate-900/30">
            <GeneratorCalendar events={calendarEvents} />
          </div>

        </div>

        {/* Charts Section */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
          <div className="glass-card p-6 print:border-gray-300 print:bg-white">
            <h3 className="text-lg font-bold text-white mb-6 print:text-black">Fleet Fuel Consumption (30 Days)</h3>
            <div className="w-full h-72">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" vertical={false} />
                  <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <RechartsTooltip contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }} />
                  <Bar dataKey="total_fuel_used" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Fuel Used (L)" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          <div className="glass-card p-6 print:border-gray-300 print:bg-white">
            <h3 className="text-lg font-bold text-white mb-6 print:text-black">Fleet Energy Production (30 Days)</h3>
            <div className="w-full h-72">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" vertical={false} />
                  <XAxis dataKey="date" stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <YAxis stroke="#94a3b8" fontSize={12} tickLine={false} axisLine={false} />
                  <RechartsTooltip contentStyle={{ backgroundColor: '#1e293b', border: 'none', borderRadius: '8px', color: '#fff' }} />
                  <Line type="monotone" dataKey="total_kwh" stroke="#10b981" strokeWidth={3} dot={{ r: 0 }} activeDot={{ r: 6 }} name="Energy (kWh)" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

      </div>

      {/* Right Panel: AI Summaries */}
      <div className="hidden xl:flex w-96 glass-panel flex-col border-l border-slate-800 print:hidden z-10">
        <div className="p-6 border-b border-slate-800 bg-slate-900/50 backdrop-blur-md sticky top-0">
          <div className="flex items-center gap-3">
            <div className="bg-primary/20 p-2.5 rounded-xl text-primary animate-pulse">
              <Bot size={26} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white tracking-wide">{t('energy.ai_engine')}</h2>
              <p className="text-xs text-indigo-300 uppercase tracking-widest font-bold mt-1">{t('energy.live_analysis')}</p>
            </div>
          </div>
        </div>
        
        <div className="p-6 overflow-y-auto hide-scrollbar space-y-6">
          {/* Daily AI Summary */}
          <div className="relative p-5 rounded-2xl bg-gradient-to-br from-indigo-500/10 to-blue-600/5 border border-indigo-500/20 shadow-lg group hover:border-indigo-500/40 transition-colors">
            <div className="absolute top-0 right-0 w-32 h-32 bg-indigo-500/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform blur-xl"></div>
            <h3 className="text-indigo-300 text-sm font-bold uppercase tracking-wider mb-3 flex items-center gap-2">
              <Zap size={16} /> Daily Briefing
            </h3>
            <div className="text-sm text-slate-200 leading-relaxed whitespace-pre-wrap">
              {aiSummaries?.daily_summary || "Generating daily summary..."}
            </div>
          </div>

          {/* Weekly AI Summary */}
          <div className="relative p-5 rounded-2xl bg-gradient-to-br from-emerald-500/10 to-teal-600/5 border border-emerald-500/20 shadow-lg group hover:border-emerald-500/40 transition-colors">
             <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/10 rounded-bl-full -z-10 group-hover:scale-110 transition-transform blur-xl"></div>
            <h3 className="text-emerald-400 text-sm font-bold uppercase tracking-wider mb-3 flex items-center gap-2">
              <Activity size={16} /> Weekly Report
            </h3>
            <div className="text-sm text-slate-200 leading-relaxed whitespace-pre-wrap font-mono bg-slate-900/50 p-4 rounded-xl border border-slate-800">
              {aiSummaries?.weekly_summary || "Generating weekly report..."}
            </div>
          </div>
        </div>
      </div>

      {/* AIChatAssistant Component (Floating) */}
      <AIChatAssistant onTriggerExport={handleExportExcel} />

      {/* Daily Report Modal Form */}
      {showReportModal && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-[100] p-4">
          <div className="glass-card w-full max-w-2xl p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-2xl font-bold text-white">{t('energy.add_reading')}</h2>
              <button onClick={() => setShowReportModal(false)} className="p-2 text-muted hover:text-white rounded-lg hover:bg-slate-800 transition-colors"><X size={20}/></button>
            </div>
            
            <div className="grid grid-cols-2 gap-5">
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1.5">Date</label>
                <input type="date" className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2.5 text-white focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all" 
                  value={reportForm.date} onChange={e => setReportForm({...reportForm, date: e.target.value})} />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1.5">Generator</label>
                <select className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2.5 text-white focus:border-primary focus:ring-1 focus:ring-primary outline-none transition-all"
                  value={reportForm.generator_id} onChange={e => setReportForm({...reportForm, generator_id: e.target.value})}>
                  <option value="">{t('energy.select_generator')}</option>
                  {generators.map(g => (
                    <option key={g.id} value={g.id}>{g.name} ({g.building_name || 'No Building'})</option>
                  ))}
                </select>
              </div>

              <div className="col-span-2">
                 <div className="p-4 bg-primary/5 border border-primary/20 rounded-xl">
                   <label className="block text-sm font-medium text-indigo-300 mb-2">Smart OCR: Upload Photo of Meter (Optional)</label>
                   <div className="flex items-center gap-3">
                    <input type="file" accept="image/*" className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white file:mr-4 file:py-1.5 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-bold file:bg-primary file:text-white hover:file:bg-indigo-600 transition-colors" 
                      onChange={handlePhotoUpload} />
                    {ocrLoading && <span className="text-sm font-bold text-primary animate-pulse whitespace-nowrap bg-primary/10 px-3 py-1.5 rounded-lg border border-primary/20">Scanning...</span>}
                  </div>
                 </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1.5">{t('energy.current_hours')}</label>
                <input type="number" step="0.01" className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2.5 text-white focus:border-primary outline-none transition-all" 
                  value={reportForm.meter_hours} onChange={e => setReportForm({...reportForm, meter_hours: e.target.value})} placeholder="e.g. 1450.5" />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-300 mb-1.5">Current Meter (kWh)</label>
                <input type="number" step="0.1" className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-2.5 text-white focus:border-primary outline-none transition-all" 
                  value={reportForm.current_kwh} onChange={e => setReportForm({...reportForm, current_kwh: e.target.value})} placeholder="e.g. 56000" />
              </div>
              
              <div className="col-span-2">
                <label className="block text-sm font-medium text-slate-300 mb-1.5">{t('energy.notes')}</label>
                <textarea className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-primary outline-none transition-all" rows="2"
                  value={reportForm.notes} onChange={e => setReportForm({...reportForm, notes: e.target.value})} placeholder="Any maintenance done or issues noticed..."></textarea>
              </div>
            </div>
            
            <div className="flex justify-end gap-3 mt-8">
              <button onClick={() => setShowReportModal(false)} className="px-6 py-2.5 rounded-xl text-white hover:bg-slate-800 font-medium transition-colors">{t('generator.cancel')}</button>
              <button 
                onClick={() => reportMutation.mutate(reportForm)}
                className="px-6 py-2.5 bg-primary hover:bg-indigo-600 text-white font-bold rounded-xl shadow-lg shadow-primary/30 transition-all active:scale-95 flex items-center justify-center min-w-[140px]"
                disabled={reportMutation.isLoading || !reportForm.generator_id}
              >
                {reportMutation.isLoading ? <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div> : 'Submit Reading'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default EnergyManagement;
