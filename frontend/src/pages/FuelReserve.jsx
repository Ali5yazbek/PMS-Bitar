import React, { useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import {
  Droplet, Zap, AlertTriangle, ArrowRightLeft, Bot, FileSpreadsheet,
  Printer, TrendingDown, Gauge, Building, CheckCircle, XCircle,
  ChevronUp, ChevronDown, RefreshCw, Info, Calendar, BarChart3
} from 'lucide-react';
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RTooltip,
  ResponsiveContainer, Cell, PieChart, Pie, Legend, LineChart, Line
} from 'recharts';
import { exportToExcel } from '../utils/ExportUtils';

// ─── Status config ──────────────────────────────────────────────────────────
const STATUS_CONFIG = {
  Normal:    { color: 'text-emerald-400',  bg: 'bg-emerald-500/15',  border: 'border-emerald-500/30',  dot: 'bg-emerald-400' },
  Low:       { color: 'text-amber-400',    bg: 'bg-amber-500/15',    border: 'border-amber-500/30',    dot: 'bg-amber-400' },
  Critical:  { color: 'text-red-400',      bg: 'bg-red-500/15',      border: 'border-red-500/30',      dot: 'bg-red-500 animate-ping' },
  Overfilled:{ color: 'text-violet-400',   bg: 'bg-violet-500/15',   border: 'border-violet-500/30',   dot: 'bg-violet-400' },
  'Near Full':{ color: 'text-blue-400',    bg: 'bg-blue-500/15',     border: 'border-blue-500/30',     dot: 'bg-blue-400' },
};

const CHART_COLORS = [
  '#6366f1','#10b981','#f59e0b','#ef4444','#3b82f6',
  '#8b5cf6','#06b6d4','#ec4899','#84cc16','#f97316',
  '#14b8a6','#a855f7',
];

// ─── Utility helpers ─────────────────────────────────────────────────────────
const fmtNum = (n, dec = 0) => n == null ? '—' : Number(n).toLocaleString('en-US', { minimumFractionDigits: dec, maximumFractionDigits: dec });
const fmtDate = (d) => d ? new Date(d).toLocaleDateString() : '—';

const StatusBadge = ({ status }) => {
  const { t } = useTranslation();
  const cfg = STATUS_CONFIG[status] || STATUS_CONFIG.Normal;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold border ${cfg.bg} ${cfg.border} ${cfg.color}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
      {status}
    </span>
  );
};

// ─── Fuel bar ────────────────────────────────────────────────────────────────
const FuelBar = ({ pct }) => {
  const clamped = Math.max(0, Math.min(110, pct));
  const color =
    pct > 100 ? 'bg-violet-500' :
    pct > 75  ? 'bg-emerald-500' :
    pct > 40  ? 'bg-amber-400' :
    pct > 15  ? 'bg-orange-500' : 'bg-red-500';
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 bg-slate-800 rounded-full h-2">
        <div className={`${color} h-2 rounded-full transition-all duration-700`} style={{ width: `${Math.min(100, clamped)}%` }} />
      </div>
      <span className={`text-xs font-bold w-12 text-right ${pct > 100 ? 'text-violet-400' : pct < 15 ? 'text-red-400' : 'text-slate-300'}`}>
        {fmtNum(pct, 1)}%
      </span>
    </div>
  );
};

// ─── KPI Card ────────────────────────────────────────────────────────────────
const KpiCard = ({ icon: Icon, label, value, unit, color, accentColor, subtitle }) => (
  <div className={`glass-card p-5 relative overflow-hidden group hover:border-opacity-60 transition-all duration-300 border border-slate-700/50`}>
    <div className={`absolute top-0 right-0 w-20 h-20 rounded-bl-full -z-10 group-hover:scale-125 transition-transform duration-500 ${accentColor || 'bg-primary/10'}`} />
    <div className="flex items-start justify-between mb-3">
      <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">{label}</p>
      <div className={`p-2 rounded-lg ${accentColor || 'bg-primary/20'}`}>
        <Icon size={16} className={color || 'text-primary'} />
      </div>
    </div>
    <p className={`text-2xl font-extrabold ${color || 'text-white'}`}>{value}<span className="text-sm font-medium text-slate-400 ml-1">{unit}</span></p>
    {subtitle && <p className="text-xs text-slate-500 mt-1">{subtitle}</p>}
  </div>
);

// ─── Main Component ──────────────────────────────────────────────────────────
const FuelReserve = () => {
  const qc = useQueryClient();
  const [tab, setTab] = useState('dashboard');
  const [sortKey, setSortKey] = useState('building_name');
  const [sortDir, setSortDir] = useState('asc');
  const [transferForm, setTransferForm] = useState({
    from_generator_id: '', to_generator_id: '', amount: '', notes: '',
    date: new Date().toISOString().slice(0, 16),
  });
  const [transferError, setTransferError] = useState('');
  const [transferSuccess, setTransferSuccess] = useState('');

  // ── Queries ────────────────────────────────────────────────────────────────
  const { data: dashboard, isLoading: dashLoading, refetch: refetchDash } = useQuery({
    queryKey: ['fuelReserveDashboard'],
    queryFn: async () => (await api.get('/fuel/reserve/dashboard')).data,
    refetchInterval: 60000,
  });

  const { data: aiData, isLoading: aiLoading } = useQuery({
    queryKey: ['fuelAIAnalysis'],
    queryFn: async () => (await api.get('/fuel/reserve/ai-analysis')).data,
    enabled: tab === 'ai',
  });

  const { data: transfers, isLoading: transfersLoading } = useQuery({
    queryKey: ['fuelTransferHistory'],
    queryFn: async () => (await api.get('/fuel/reserve/transfers')).data,
    enabled: tab === 'transfers',
  });

  const { data: forecast, isLoading: forecastLoading } = useQuery({
    queryKey: ['fuelForecast'],
    queryFn: async () => (await api.get('/fuel/reserve/forecast')).data,
    enabled: tab === 'ai' || tab === 'reports',
  });

  // ── Transfer mutation ──────────────────────────────────────────────────────
  const transferMutation = useMutation({
    mutationFn: (data) => api.post('/fuel/reserve/transfer', data),
    onSuccess: (res) => {
      setTransferSuccess(res.data.message || 'Transfer successful!');
      setTransferError('');
      setTransferForm({ from_generator_id: '', to_generator_id: '', amount: '', notes: '', date: new Date().toISOString().slice(0, 16) });
      qc.invalidateQueries(['fuelReserveDashboard']);
      qc.invalidateQueries(['fuelTransferHistory']);
      qc.invalidateQueries(['fuelAIAnalysis']);
      qc.invalidateQueries(['fuelForecast']);
    },
    onError: (err) => {
      setTransferError(err?.response?.data?.error || 'Transfer failed. Please check the values.');
      setTransferSuccess('');
    },
  });

  // ── Sorting ────────────────────────────────────────────────────────────────
  const toggleSort = (key) => {
    if (sortKey === key) setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    else { setSortKey(key); setSortDir('asc'); }
  };

  const sortedBuildings = useMemo(() => {
    if (!dashboard?.buildings) return [];
    return [...dashboard.buildings].sort((a, b) => {
      const av = a[sortKey] ?? '';
      const bv = b[sortKey] ?? '';
      if (typeof av === 'string') return sortDir === 'asc' ? av.localeCompare(bv) : bv.localeCompare(av);
      return sortDir === 'asc' ? av - bv : bv - av;
    });
  }, [dashboard?.buildings, sortKey, sortDir]);

  const SortIcon = ({ k }) => sortKey === k ? (sortDir === 'asc' ? <ChevronUp size={12} /> : <ChevronDown size={12} />) : null;

  // ── Export ─────────────────────────────────────────────────────────────────
  const handleExport = () => {
    if (!sortedBuildings.length) return;
    exportToExcel(sortedBuildings.map(b => ({
      Building: b.building_name,
      Generator: b.name,
      KVA: b.capacity_kva,
      Tank_Capacity_L: b.tank_capacity,
      Current_Fuel_L: b.current_fuel,
      Free_Capacity_L: b.free_capacity,
      Fuel_Pct: b.fuel_percentage + '%',
      Status: b.status,
      Remaining_Days: b.remaining_days ?? 'N/A',
    })), 'Fuel_Reserve_Report');
  };

  const handleExportForecast = () => {
    if (!forecast?.length) return;
    exportToExcel(forecast.map(f => ({
      Building: f.building_name,
      Generator: f.name,
      Current_Fuel_L: f.current_fuel,
      Avg_Daily_L: f.avg_daily_fuel,
      Remaining_Days: f.remaining_days ?? 'N/A',
      Depletion_Date: f.depletion_date ?? 'N/A',
      Monthly_Estimate_L: f.monthly_estimate,
    })), 'Fuel_Forecast_Report');
  };

  // ── Summary ────────────────────────────────────────────────────────────────
  const s = dashboard?.summary || {};
  const alerts = dashboard?.alerts || [];
  const buildings = dashboard?.buildings || [];

  // ── Chart data ─────────────────────────────────────────────────────────────
  const chartStock = sortedBuildings.map((b, i) => ({
    name: b.building_name || b.name,
    fuel: b.current_fuel,
    capacity: b.tank_capacity,
    fill: CHART_COLORS[i % CHART_COLORS.length],
  }));

  const chartPct = sortedBuildings.map((b, i) => ({
    name: b.building_name || b.name,
    pct: b.fuel_percentage,
    fill: b.fuel_percentage < 15 ? '#ef4444' : b.fuel_percentage < 30 ? '#f59e0b' : CHART_COLORS[i % CHART_COLORS.length],
  }));

  const TABS = [
    { id: 'dashboard', label: 'Dashboard', icon: BarChart3 },
    { id: 'transfers', label: 'Fuel Transfers', icon: ArrowRightLeft },
    { id: 'ai', label: 'AI Analysis', icon: Bot },
    { id: 'reports', label: 'Reports & Export', icon: FileSpreadsheet },
  ];

  if (dashLoading) return (
    <div className="flex-1 flex items-center justify-center h-full bg-background">
      <div className="text-center">
        <div className="animate-spin rounded-full h-14 w-14 border-b-2 border-primary mx-auto mb-4" />
        <p className="text-muted text-sm">Loading Fuel Reserve Data...</p>
      </div>
    </div>
  );

  return (
    <div className="flex h-full w-full overflow-hidden bg-background">
      <div className="flex-1 overflow-y-auto p-6 hide-scrollbar print:p-0">

        {/* ── Header ─────────────────────────────────────────────────────── */}
        <div className="flex flex-wrap gap-3 justify-between items-center mb-6 print:mb-4">
          <div>
            <h1 className="text-2xl font-extrabold text-white tracking-tight">
              ⛽ Fuel Reserve Simulation
            </h1>
            <p className="text-slate-400 text-sm mt-0.5">Real-time diesel stock across all building generators</p>
          </div>
          <div className="flex items-center gap-2 print:hidden">
            <button onClick={() => { refetchDash(); }} className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors" title="Refresh">
              <RefreshCw size={18} />
            </button>
            <button onClick={handleExport} className="flex items-center gap-2 bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border border-emerald-600/30 px-4 py-2 rounded-xl text-sm font-semibold transition-colors">
              <FileSpreadsheet size={16} /> Export Excel
            </button>
            <button onClick={() => window.print()} className="flex items-center gap-2 bg-slate-800 hover:bg-slate-700 text-white border border-slate-700 px-4 py-2 rounded-xl text-sm font-semibold transition-colors">
              <Printer size={16} /> Print PDF
            </button>
          </div>
        </div>

        {/* ── Alert strip ────────────────────────────────────────────────── */}
        {alerts.length > 0 && (
          <div className="mb-6 space-y-2 print:hidden">
            {alerts.map((a, i) => (
              <div key={i} className={`flex items-start gap-3 p-3 rounded-xl border text-sm font-medium ${a.level === 'danger' ? 'bg-red-500/10 border-red-500/30 text-red-300' : 'bg-amber-500/10 border-amber-500/30 text-amber-300'}`}>
                <AlertTriangle size={16} className="mt-0.5 shrink-0" />
                <span>{a.icon} {a.message}</span>
              </div>
            ))}
          </div>
        )}

        {/* ── Tabs ───────────────────────────────────────────────────────── */}
        <div className="flex gap-1 bg-slate-900/60 p-1 rounded-xl mb-6 print:hidden border border-slate-800 w-fit">
          {TABS.map(t => {
            const Icon = t.icon;
            return (
              <button key={t.id} onClick={() => setTab(t.id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all duration-200 ${tab === t.id ? 'bg-primary text-white shadow-lg shadow-primary/30' : 'text-slate-400 hover:text-white hover:bg-slate-800'}`}>
                <Icon size={15} /> {t.label}
              </button>
            );
          })}
        </div>

        {/* ══════════════════════════════════════════════════════════════════
            TAB: DASHBOARD
        ══════════════════════════════════════════════════════════════════ */}
        {tab === 'dashboard' && (
          <>
            {/* KPI Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
              <KpiCard icon={Droplet}       label="Total Tank Capacity"   value={fmtNum(s.total_capacity)}      unit="L"   color="text-blue-400"    accentColor="bg-blue-500/10"    subtitle="All generators combined" />
              <KpiCard icon={Gauge}         label="Total Fuel Stock"       value={fmtNum(s.total_fuel)}           unit="L"   color="text-emerald-400" accentColor="bg-emerald-500/10" subtitle={`${fmtNum(s.total_fuel / (s.total_capacity || 1) * 100, 1)}% of total capacity`} />
              <KpiCard icon={TrendingDown}  label="Total Free Capacity"    value={fmtNum(s.total_free)}           unit="L"   color="text-indigo-400"  accentColor="bg-indigo-500/10"  subtitle="Available storage space" />
              <KpiCard icon={Zap}           label="Consumed Today"         value={fmtNum(s.total_consumed_today, 2)} unit="L" color="text-orange-400"  accentColor="bg-orange-500/10"  subtitle={`${fmtNum(s.total_hours_today, 2)} hours operated`} />
              <KpiCard icon={ArrowRightLeft} label="Total Transferred"     value={fmtNum(s.total_transferred)}    unit="L"   color="text-cyan-400"    accentColor="bg-cyan-500/10"    subtitle="Inter-building transfers" />
              <KpiCard icon={Building}      label="Generator Hours Today"  value={fmtNum(s.total_hours_today, 2)} unit="h"   color="text-purple-400"  accentColor="bg-purple-500/10"  subtitle="Fleet total runtime" />
              <KpiCard icon={AlertTriangle} label="Low / Critical Fuel"    value={s.low_fuel_buildings}           unit=""    color="text-red-400"     accentColor="bg-red-500/10"     subtitle="Buildings requiring refill" />
              <KpiCard icon={CheckCircle}   label="Near Full"              value={s.near_full_buildings}          unit=""    color="text-violet-400"  accentColor="bg-violet-500/10"  subtitle="Tanks above 95% capacity" />
            </div>

            {/* ── Fleet Table ─────────────────────────────────────────────── */}
            <div className="glass-card overflow-hidden mb-6">
              <div className="p-5 border-b border-slate-700/50">
                <h2 className="text-lg font-bold text-white flex items-center gap-2"><Building size={18} className="text-primary" /> Building Fuel Fleet</h2>
                <p className="text-xs text-slate-500 mt-0.5">Click column headers to sort</p>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-sm">
                  <thead className="bg-slate-800/60">
                    <tr className="text-xs text-slate-400 uppercase tracking-wider border-b border-slate-700/50">
                      {[
                        { k: 'building_name', l: 'Building' },
                        { k: 'capacity_kva', l: 'KVA' },
                        { k: 'tank_capacity', l: 'Tank Cap (L)' },
                        { k: 'current_fuel', l: 'Fuel (L)' },
                        { k: 'free_capacity', l: 'Free (L)' },
                        { k: 'fuel_percentage', l: 'Level' },
                        { k: 'remaining_days', l: 'Days Left' },
                        { k: 'status', l: 'Status' },
                      ].map(col => (
                        <th key={col.k}
                          className="px-4 py-3 font-semibold cursor-pointer hover:text-white transition-colors select-none"
                          onClick={() => toggleSort(col.k)}
                        >
                          <span className="flex items-center gap-1">{col.l} <SortIcon k={col.k} /></span>
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/50">
                    {sortedBuildings.map((b) => (
                      <tr key={b.id}
                        className={`hover:bg-slate-800/40 transition-colors ${b.status === 'Critical' ? 'bg-red-900/10' : b.status === 'Overfilled' ? 'bg-violet-900/10' : ''}`}
                      >
                        <td className="px-4 py-3 font-bold text-white">{b.building_name || b.name}</td>
                        <td className="px-4 py-3 text-slate-300">{b.capacity_kva}</td>
                        <td className="px-4 py-3 text-slate-300">{fmtNum(b.tank_capacity)}</td>
                        <td className="px-4 py-3 font-semibold text-emerald-300">{fmtNum(b.current_fuel, 1)}</td>
                        <td className={`px-4 py-3 font-semibold ${b.free_capacity < 0 ? 'text-violet-400' : 'text-slate-300'}`}>
                          {b.free_capacity < 0 ? `−${fmtNum(Math.abs(b.free_capacity), 1)}` : fmtNum(b.free_capacity, 1)}
                        </td>
                        <td className="px-4 py-3 min-w-[140px]"><FuelBar pct={b.fuel_percentage} /></td>
                        <td className="px-4 py-3">
                          {b.remaining_days !== null
                            ? <span className={b.remaining_days <= 2 ? 'text-red-400 font-bold' : b.remaining_days <= 5 ? 'text-amber-400 font-semibold' : 'text-slate-300'}>{b.remaining_days}d</span>
                            : <span className="text-slate-500">—</span>}
                        </td>
                        <td className="px-4 py-3"><StatusBadge status={b.status} /></td>
                      </tr>
                    ))}
                    {sortedBuildings.length === 0 && (
                      <tr><td colSpan={8} className="px-4 py-12 text-center text-slate-500 italic">No generator data found.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* ── Charts ──────────────────────────────────────────────────── */}
            <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
              {/* Fuel Stock by Building */}
              <div className="glass-card p-5">
                <h3 className="text-base font-bold text-white mb-4">Fuel Stock by Building</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartStock} margin={{ left: -10 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                      <XAxis dataKey="name" stroke="#64748b" fontSize={10} tickLine={false} axisLine={false} angle={-30} textAnchor="end" height={50} />
                      <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                      <RTooltip contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #334155', borderRadius: '8px', color: '#fff' }} />
                      <Bar dataKey="fuel" radius={[4, 4, 0, 0]} name="Current Fuel (L)">
                        {chartStock.map((entry, i) => <Cell key={i} fill={entry.fill} />)}
                      </Bar>
                      <Bar dataKey="capacity" radius={[4, 4, 0, 0]} name="Tank Capacity (L)" fill="#1e293b" />
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              {/* Fuel % by Building */}
              <div className="glass-card p-5">
                <h3 className="text-base font-bold text-white mb-4">Fuel Level % by Building</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartPct} layout="vertical" margin={{ left: 10, right: 20 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" horizontal={false} />
                      <XAxis type="number" domain={[0, 100]} stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                      <YAxis dataKey="name" type="category" stroke="#64748b" fontSize={10} tickLine={false} axisLine={false} width={80} />
                      <RTooltip contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(v) => [`${v}%`, 'Fuel Level']} />
                      <Bar dataKey="pct" radius={[0, 4, 4, 0]} name="Fuel %">
                        {chartPct.map((entry, i) => <Cell key={i} fill={entry.fill} />)}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>
          </>
        )}

        {/* ══════════════════════════════════════════════════════════════════
            TAB: TRANSFERS
        ══════════════════════════════════════════════════════════════════ */}
        {tab === 'transfers' && (
          <div className="grid grid-cols-1 xl:grid-cols-3 gap-6">
            {/* Transfer Form */}
            <div className="xl:col-span-1">
              <div className="glass-card p-6 sticky top-6">
                <h2 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
                  <ArrowRightLeft size={18} className="text-primary" /> Fuel Transfer
                </h2>

                {transferSuccess && (
                  <div className="mb-4 p-3 bg-emerald-500/15 border border-emerald-500/30 rounded-xl text-emerald-300 text-sm flex items-start gap-2">
                    <CheckCircle size={16} className="mt-0.5 shrink-0" />
                    <span>{transferSuccess}</span>
                  </div>
                )}
                {transferError && (
                  <div className="mb-4 p-3 bg-red-500/15 border border-red-500/30 rounded-xl text-red-300 text-sm flex items-start gap-2">
                    <XCircle size={16} className="mt-0.5 shrink-0" />
                    <span>{transferError}</span>
                  </div>
                )}

                <div className="space-y-4">
                  <div>
                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5 block">Transfer Date & Time</label>
                    <input type="datetime-local" className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-primary outline-none transition-all"
                      value={transferForm.date} onChange={e => setTransferForm({...transferForm, date: e.target.value})} />
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5 block">From Building (Source)</label>
                    <select className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-primary outline-none transition-all"
                      value={transferForm.from_generator_id} onChange={e => setTransferForm({...transferForm, from_generator_id: e.target.value})}>
                      <option value="">Select source...</option>
                      {buildings.map(b => (
                        <option key={b.id} value={b.id}>{b.building_name || b.name} — {fmtNum(b.current_fuel, 1)} L available</option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5 block">To Building (Destination)</label>
                    <select className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-primary outline-none transition-all"
                      value={transferForm.to_generator_id} onChange={e => setTransferForm({...transferForm, to_generator_id: e.target.value})}>
                      <option value="">Select destination...</option>
                      {buildings.filter(b => b.id.toString() !== transferForm.from_generator_id).map(b => (
                        <option key={b.id} value={b.id}>{b.building_name || b.name} — {fmtNum(b.free_capacity, 1)} L free</option>
                      ))}
                    </select>
                  </div>

                  {/* Live preview */}
                  {transferForm.from_generator_id && transferForm.to_generator_id && (
                    <div className="p-3 bg-primary/10 border border-primary/20 rounded-xl text-xs text-indigo-200 space-y-1">
                      {(() => {
                        const src = buildings.find(b => b.id.toString() === transferForm.from_generator_id);
                        const dst = buildings.find(b => b.id.toString() === transferForm.to_generator_id);
                        const amt = parseFloat(transferForm.amount) || 0;
                        if (!src || !dst) return null;
                        return (
                          <>
                            <p><span className="text-slate-400">Source after:</span> <strong className="text-white">{fmtNum(src.current_fuel - amt, 1)} L</strong> ({fmtNum(dst.tank_capacity > 0 ? (src.current_fuel - amt) / src.tank_capacity * 100 : 0, 1)}%)</p>
                            <p><span className="text-slate-400">Dest after:</span> <strong className="text-white">{fmtNum(Math.min(dst.tank_capacity, dst.current_fuel + amt), 1)} L</strong></p>
                          </>
                        );
                      })()}
                    </div>
                  )}

                  <div>
                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5 block">Quantity (Liters)</label>
                    <input type="number" min="1" step="0.1" placeholder="e.g. 200"
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-primary outline-none transition-all"
                      value={transferForm.amount} onChange={e => setTransferForm({...transferForm, amount: e.target.value})} />
                  </div>
                  <div>
                    <label className="text-xs font-semibold text-slate-400 uppercase tracking-wider mb-1.5 block">Notes (Optional)</label>
                    <textarea rows={2} placeholder="Reason for transfer..."
                      className="w-full bg-slate-900 border border-slate-700 rounded-xl px-4 py-2.5 text-white text-sm focus:border-primary outline-none transition-all resize-none"
                      value={transferForm.notes} onChange={e => setTransferForm({...transferForm, notes: e.target.value})} />
                  </div>
                  <button
                    onClick={() => {
                      setTransferError(''); setTransferSuccess('');
                      transferMutation.mutate({ ...transferForm, amount: parseFloat(transferForm.amount) });
                    }}
                    disabled={transferMutation.isLoading || !transferForm.from_generator_id || !transferForm.to_generator_id || !transferForm.amount}
                    className="w-full py-3 bg-primary hover:bg-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed text-white font-bold rounded-xl shadow-lg shadow-primary/30 transition-all active:scale-95 flex items-center justify-center gap-2"
                  >
                    {transferMutation.isLoading
                      ? <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      : <><ArrowRightLeft size={16} /> Execute Transfer</>}
                  </button>
                </div>
              </div>
            </div>

            {/* Transfer History */}
            <div className="xl:col-span-2 glass-card overflow-hidden">
              <div className="p-5 border-b border-slate-700/50 flex justify-between items-center">
                <h2 className="text-lg font-bold text-white flex items-center gap-2"><Calendar size={18} className="text-primary" /> Transfer History</h2>
                {transfers && (
                  <button onClick={() => exportToExcel(
                    transfers.map(t => ({ Date: new Date(t.date).toLocaleString(), Building: t.building_name, Generator: t.generator_name, Type: t.type, Amount_L: t.amount, Notes: t.notes, User: t.user_name })),
                    'Transfer_History'
                  )} className="text-xs text-emerald-400 hover:underline flex items-center gap-1">
                    <FileSpreadsheet size={14} /> Export
                  </button>
                )}
              </div>
              <div className="overflow-x-auto">
                {transfersLoading ? (
                  <div className="p-8 text-center text-slate-500">Loading transfers...</div>
                ) : (
                  <table className="w-full text-sm text-left">
                    <thead className="bg-slate-800/60">
                      <tr className="text-xs text-slate-400 uppercase tracking-wider border-b border-slate-700/50">
                        <th className="px-4 py-3">Date</th>
                        <th className="px-4 py-3">Building</th>
                        <th className="px-4 py-3">Type</th>
                        <th className="px-4 py-3">Amount (L)</th>
                        <th className="px-4 py-3">Notes</th>
                        <th className="px-4 py-3">User</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50">
                      {(transfers || []).map(t => (
                        <tr key={t.id} className="hover:bg-slate-800/30 transition-colors">
                          <td className="px-4 py-3 text-slate-300 whitespace-nowrap">{new Date(t.date).toLocaleString()}</td>
                          <td className="px-4 py-3 text-white font-medium">{t.building_name}</td>
                          <td className="px-4 py-3">
                            <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${t.type === 'Transfer_In' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-orange-500/20 text-orange-400'}`}>
                              {t.type === 'Transfer_In' ? '↓ In' : '↑ Out'}
                            </span>
                          </td>
                          <td className="px-4 py-3 font-bold text-white">{fmtNum(t.amount, 1)} L</td>
                          <td className="px-4 py-3 text-slate-400 max-w-[200px] truncate">{t.notes || '—'}</td>
                          <td className="px-4 py-3 text-slate-400">{t.user_name || 'System'}</td>
                        </tr>
                      ))}
                      {(!transfers || transfers.length === 0) && (
                        <tr><td colSpan={6} className="px-4 py-10 text-center text-slate-500 italic">No transfer records found.</td></tr>
                      )}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        )}

        {/* ══════════════════════════════════════════════════════════════════
            TAB: AI ANALYSIS
        ══════════════════════════════════════════════════════════════════ */}
        {tab === 'ai' && (
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
            {/* AI Messages */}
            <div className="glass-card p-6">
              <div className="flex items-center gap-3 mb-5">
                <div className="bg-primary/20 p-2.5 rounded-xl text-primary"><Bot size={22} /></div>
                <div>
                  <h2 className="text-lg font-bold text-white">AI Fleet Intelligence</h2>
                  <p className="text-xs text-indigo-300">Live analysis of your fuel reserves</p>
                </div>
              </div>
              {aiLoading ? (
                <div className="space-y-3">
                  {[...Array(5)].map((_, i) => <div key={i} className="h-4 bg-slate-800 rounded animate-pulse" />)}
                </div>
              ) : (
                <div className="space-y-3">
                  {(aiData?.messages || []).map((msg, i) => (
                    <div key={i} className="flex items-start gap-3 p-3 bg-slate-800/50 rounded-xl border border-slate-700/50">
                      <div className="w-6 h-6 rounded-full bg-primary/30 flex items-center justify-center text-primary shrink-0 mt-0.5 text-xs font-bold">{i + 1}</div>
                      <p className="text-sm text-slate-200 leading-relaxed">{msg}</p>
                    </div>
                  ))}
                  {(!aiData?.messages || aiData.messages.length === 0) && (
                    <p className="text-slate-500 italic text-sm text-center py-8">No analysis available yet.</p>
                  )}
                </div>
              )}
            </div>

            {/* Forecast Table */}
            <div className="glass-card overflow-hidden">
              <div className="p-5 border-b border-slate-700/50 flex justify-between items-center">
                <h2 className="text-lg font-bold text-white flex items-center gap-2"><TrendingDown size={18} className="text-amber-400" /> Fuel Forecast</h2>
                <button onClick={handleExportForecast} className="text-xs text-emerald-400 hover:underline flex items-center gap-1"><FileSpreadsheet size={14} /> Export</button>
              </div>
              {forecastLoading ? (
                <div className="p-8 text-center text-slate-500">Calculating forecast...</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-sm text-left">
                    <thead className="bg-slate-800/60">
                      <tr className="text-xs text-slate-400 uppercase border-b border-slate-700/50">
                        <th className="px-4 py-3">Building</th>
                        <th className="px-4 py-3">Fuel (L)</th>
                        <th className="px-4 py-3">Avg/Day (L)</th>
                        <th className="px-4 py-3">Days Left</th>
                        <th className="px-4 py-3">Est. Depletion</th>
                        <th className="px-4 py-3">Monthly Need</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/50">
                      {(forecast || []).map(f => (
                        <tr key={f.id} className={`hover:bg-slate-800/30 transition-colors ${f.remaining_days !== null && f.remaining_days <= 2 ? 'bg-red-900/10' : f.remaining_days !== null && f.remaining_days <= 5 ? 'bg-amber-900/10' : ''}`}>
                          <td className="px-4 py-3 font-bold text-white">{f.building_name || f.name}</td>
                          <td className="px-4 py-3 text-emerald-300 font-semibold">{fmtNum(f.current_fuel, 1)}</td>
                          <td className="px-4 py-3 text-slate-300">{f.avg_daily_fuel > 0 ? fmtNum(f.avg_daily_fuel, 1) : <span className="text-slate-600 text-xs">No data</span>}</td>
                          <td className="px-4 py-3">
                            {f.remaining_days !== null
                              ? <span className={`font-bold ${f.remaining_days <= 2 ? 'text-red-400' : f.remaining_days <= 5 ? 'text-amber-400' : 'text-emerald-400'}`}>{f.remaining_days}d</span>
                              : <span className="text-slate-600 text-xs">N/A</span>}
                          </td>
                          <td className="px-4 py-3 text-slate-400 text-xs">{f.depletion_date ? fmtDate(f.depletion_date) : '—'}</td>
                          <td className="px-4 py-3 text-indigo-300">{f.monthly_estimate > 0 ? fmtNum(f.monthly_estimate) + ' L' : '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Forecast Chart */}
            {forecast && forecast.length > 0 && (
              <div className="xl:col-span-2 glass-card p-5">
                <h3 className="text-base font-bold text-white mb-4">Estimated Days of Fuel Remaining by Building</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={forecast.filter(f => f.remaining_days !== null).sort((a,b) => a.remaining_days - b.remaining_days)} margin={{ left: -10 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                      <XAxis dataKey="building_name" stroke="#64748b" fontSize={10} tickLine={false} axisLine={false} angle={-20} textAnchor="end" height={50} />
                      <YAxis stroke="#64748b" fontSize={11} tickLine={false} axisLine={false} />
                      <RTooltip contentStyle={{ backgroundColor: '#0f172a', border: '1px solid #334155', borderRadius: '8px', color: '#fff' }}
                        formatter={(v) => [`${v} days`, 'Fuel Remaining']} />
                      <Bar dataKey="remaining_days" radius={[4, 4, 0, 0]} name="Days Remaining">
                        {forecast.filter(f => f.remaining_days !== null).sort((a,b) => a.remaining_days - b.remaining_days).map((entry, i) => (
                          <Cell key={i} fill={entry.remaining_days <= 2 ? '#ef4444' : entry.remaining_days <= 5 ? '#f59e0b' : '#10b981'} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ══════════════════════════════════════════════════════════════════
            TAB: REPORTS
        ══════════════════════════════════════════════════════════════════ */}
        {tab === 'reports' && (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {[
              {
                title: 'Fuel Reserve Report',
                desc: 'Complete fleet status including fuel levels, capacities, and status classification.',
                icon: Gauge, color: 'text-blue-400', accent: 'bg-blue-500/10',
                action: handleExport,
                actions: [{ label: 'Export Excel', fn: handleExport, cls: 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border-emerald-600/30' },
                           { label: 'Print PDF', fn: () => window.print(), cls: 'bg-slate-700 hover:bg-slate-600 text-white border-slate-600' }],
              },
              {
                title: 'Fuel Forecast Report',
                desc: 'Per-building predicted depletion dates and monthly consumption estimates.',
                icon: TrendingDown, color: 'text-amber-400', accent: 'bg-amber-500/10',
                actions: [{ label: 'Export Excel', fn: handleExportForecast, cls: 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border-emerald-600/30' }],
              },
              {
                title: 'Transfer History Report',
                desc: 'Full log of all inter-building fuel movements.',
                icon: ArrowRightLeft, color: 'text-indigo-400', accent: 'bg-indigo-500/10',
                actions: [{
                  label: 'Export Excel', fn: () => {
                    if (transfers?.length) exportToExcel(transfers.map(t => ({
                      Date: new Date(t.date).toLocaleString(),
                      Building: t.building_name, Generator: t.generator_name,
                      Type: t.type, Amount_L: t.amount, Notes: t.notes, User: t.user_name,
                    })), 'Transfer_History');
                  }, cls: 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border-emerald-600/30',
                }],
              },
              {
                title: 'Low Fuel Alert Report',
                desc: 'List of all buildings currently below 25% fuel capacity.',
                icon: AlertTriangle, color: 'text-red-400', accent: 'bg-red-500/10',
                actions: [{
                  label: 'Export Excel', fn: () => {
                    const lowBuildings = sortedBuildings.filter(b => b.fuel_percentage < 25);
                    if (lowBuildings.length) exportToExcel(lowBuildings.map(b => ({
                      Building: b.building_name, Fuel_L: b.current_fuel,
                      Tank_L: b.tank_capacity, Pct: b.fuel_percentage + '%',
                      Days_Left: b.remaining_days ?? 'N/A', Status: b.status,
                    })), 'Low_Fuel_Alert');
                  }, cls: 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border-emerald-600/30',
                }],
              },
              {
                title: 'AI Summary Report',
                desc: 'AI-generated natural-language analysis of fleet fuel status.',
                icon: Bot, color: 'text-purple-400', accent: 'bg-purple-500/10',
                actions: [{
                  label: 'Export Excel', fn: () => {
                    if (aiData?.messages?.length) exportToExcel(
                      aiData.messages.map((m, i) => ({ No: i + 1, AI_Analysis: m })),
                      'AI_Fuel_Summary'
                    );
                  }, cls: 'bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-400 border-emerald-600/30',
                }],
              },
              {
                title: 'Print Fleet Summary',
                desc: 'Professional print layout with all generator status information.',
                icon: Printer, color: 'text-cyan-400', accent: 'bg-cyan-500/10',
                actions: [{ label: 'Print Now', fn: () => window.print(), cls: 'bg-slate-700 hover:bg-slate-600 text-white border-slate-600' }],
              },
            ].map((card, i) => {
              const Icon = card.icon;
              return (
                <div key={i} className="glass-card p-5 flex flex-col gap-4 hover:border-slate-600/60 transition-all border border-slate-700/50">
                  <div className="flex items-center gap-3">
                    <div className={`p-2.5 rounded-xl ${card.accent}`}><Icon size={20} className={card.color} /></div>
                    <h3 className="font-bold text-white">{card.title}</h3>
                  </div>
                  <p className="text-xs text-slate-400 leading-relaxed flex-1">{card.desc}</p>
                  <div className="flex flex-wrap gap-2">
                    {card.actions.map((a, j) => (
                      <button key={j} onClick={a.fn} className={`flex items-center gap-1.5 px-3 py-2 rounded-lg text-xs font-bold border transition-colors ${a.cls}`}>
                        {a.label}
                      </button>
                    ))}
                  </div>
                </div>
              );
            })}
          </div>
        )}

      </div>
    </div>
  );
};

export default FuelReserve;
