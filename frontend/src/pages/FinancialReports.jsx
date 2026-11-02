import React, { useState, useRef, useMemo, useEffect, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import PrintLogo from '../components/PrintLogo';
import {
  FileText, Building, Home, Users, DollarSign, Shield, Zap,
  Activity, Package, ChevronDown, Search, Filter, Download,
  Printer, AlertCircle, Check, CheckSquare, Square, TrendingUp,
  TrendingDown, BarChart2, Calendar, Eye, FileSpreadsheet
} from 'lucide-react';

/* ─────────────────────────────── helpers ──────────────────────────────── */
const fmt = (n) =>
  Number(n || 0).toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 });

const CATEGORIES = [
  { id: 'rent',        label: 'Rental Payments',           icon: DollarSign,  color: 'text-green-400',  bg: 'bg-green-500/10',  border: 'border-green-500/30' },
  { id: 'insurance',   label: 'Insurance',                 icon: Shield,      color: 'text-purple-400', bg: 'bg-purple-500/10', border: 'border-purple-500/30' },
  { id: 'electricity', label: 'Electricity Subscription',  icon: Zap,         color: 'text-yellow-400', bg: 'bg-yellow-500/10', border: 'border-yellow-500/30' },
  { id: 'expenses',    label: 'Apartment Expenses',        icon: Package,     color: 'text-red-400',    bg: 'bg-red-500/10',    border: 'border-red-500/30' },
  { id: 'summary',     label: 'Financial Summary',         icon: BarChart2,   color: 'text-indigo-400', bg: 'bg-indigo-500/10', border: 'border-indigo-500/30' },
];

const StatusBadge = ({ status }) => {
  const map = {
    Paid: 'bg-green-500/20 text-green-400',
    Partial: 'bg-yellow-500/20 text-yellow-400',
    Unpaid: 'bg-red-500/20 text-red-400',
    Overdue: 'bg-red-600/30 text-red-300',
  };
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${map[status] || 'bg-slate-700 text-slate-300'}`}>
      {status || '—'}
    </span>
  );
};

const SummaryCard = ({ label, value, icon: Icon, color, sub }) => (
  <div className="glass-card p-5 flex items-center gap-4">
    <div className={`p-3 rounded-xl ${color.replace('text-', 'bg-').replace('400', '500/15')}`}>
      <Icon className={color} size={22} />
    </div>
    <div>
      <p className="text-xs text-slate-400 font-medium">{label}</p>
      <p className={`text-xl font-bold ${color}`}>{value}</p>
      {sub && <p className="text-xs text-slate-500">{sub}</p>}
    </div>
  </div>
);

/* ═══════════════════════════════════════════════════════════════════════════ */
const FinancialReports = () => {
  const printRef = useRef(null);
  const today = new Date();
  const firstOfMonth = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().slice(0, 10);
  const lastOfMonth  = new Date(today.getFullYear(), today.getMonth() + 1, 0).toISOString().slice(0, 10);

  // ── filter state ──
  const [filters, setFilters] = useState({
    start_date: firstOfMonth,
    end_date: lastOfMonth,
    building_id: '',
    apartment_id: '',
    tenant_id: '',
    payment_method: '',
  });
  const [selectedCats, setSelectedCats] = useState(CATEGORIES.map(c => c.id));
  const [generated, setGenerated] = useState(false);
  const [reportData, setReportData] = useState([]);
  const [generating, setGenerating] = useState(false);
  const [aptSearch, setAptSearch] = useState('');
  const [tenantSearch, setTenantSearch] = useState('');
  const [error, setError] = useState(null);
  // tenant's full apartment history (all contracts)
  const [selectedTenantId, setSelectedTenantId] = useState(null);
  const [tenantApartments, setTenantApartments] = useState([]);
  const [showTenantApts, setShowTenantApts] = useState(false);
  const [tenantSelectedBuilding, setTenantSelectedBuilding] = useState('');

  // ── reference data ──
  const { data: buildings = [] } = useQuery({
    queryKey: ['fr_buildings'],
    queryFn: async () => {
      const res = await api.get('/buildings');
      return Array.isArray(res.data) ? res.data : [];
    }
  });

  const { data: allApartments = [] } = useQuery({
    queryKey: ['fr_apartments_all'],
    queryFn: async () => {
      const res = await api.get('/apartments');
      return Array.isArray(res.data) ? res.data : [];
    }
  });

  const { data: allTenants = [] } = useQuery({
    queryKey: ['fr_tenants'],
    queryFn: async () => {
      const res = await api.get('/tenants');
      return Array.isArray(res.data) ? res.data : (res.data?.data ?? []);
    }
  });

  // ── filtered dropdowns ──
  const filteredApartments = useMemo(() =>
    allApartments.filter(a =>
      a.code.toLowerCase().includes(aptSearch.toLowerCase()) ||
      (a.building_name || '').toLowerCase().includes(aptSearch.toLowerCase())
    ), [allApartments, aptSearch]);

  const filteredTenants = useMemo(() => {
    const uniqueTenantsMap = new Map();
    for (const t of allTenants) {
      const key = `${(t.full_name || '').toLowerCase().trim()}-${(t.phone || '').trim()}`;
      if (!uniqueTenantsMap.has(key)) {
        uniqueTenantsMap.set(key, { ...t, all_ids: [t.id] });
      } else {
        const existing = uniqueTenantsMap.get(key);
        if (!existing.all_ids.includes(t.id)) {
          existing.all_ids.push(t.id);
        }
      }
    }
    return Array.from(uniqueTenantsMap.values()).filter(t =>
      t.full_name.toLowerCase().includes(tenantSearch.toLowerCase())
    );
  }, [allTenants, tenantSearch]);

  // ── fetch all apartments ever rented by a tenant (via contracts) ──
  const fetchTenantApartments = useCallback(async (tenantIds) => {
    try {
      if (!Array.isArray(tenantIds)) tenantIds = [tenantIds];
      const promises = tenantIds.map(id => api.get(`/tenants/${id}/apartments`));
      const responses = await Promise.all(promises);
      const contracts = [];
      responses.forEach(res => {
        if (res.data) contracts.push(...res.data);
      });
      // Build unique apartment list from contracts
      const seen = new Set();
      const apts = [];
      contracts.forEach(c => {
        if (!seen.has(c.apartment_code)) {
          seen.add(c.apartment_code);
          apts.push({
            apartment_id: c.apartment_id,
            apartment_code: c.apartment_code,
            building_id: c.building_id,
            building_name: c.building_name,
            contract_status: c.contract_status,
            contract_id: c.contract_id,
            start_date: c.start_date,
            end_date: c.end_date,
          });
        }
      });
      setTenantApartments(apts);
      setShowTenantApts(apts.length > 0);
    } catch (e) {
      setTenantApartments([]);
    }
  }, []);

  // ── helpers ──
  const handleApartmentSelect = (apt) => {
    setFilters(f => ({
      ...f,
      apartment_id: String(apt.id),
      building_id: String(apt.building_id),
      tenant_id: apt.tenant_id ? String(apt.tenant_id) : filters.tenant_id,
    }));
    setAptSearch(apt.code);
    if (apt.tenant_name) setTenantSearch(apt.tenant_name);
    setShowTenantApts(false);
  };

  const handleTenantSelect = async (tenant) => {
    setSelectedTenantId(tenant.id);
    setTenantSearch(tenant.full_name);
    const idString = tenant.all_ids ? tenant.all_ids.join(',') : String(tenant.id);
    setFilters(f => ({ ...f, tenant_id: idString, apartment_id: '', building_id: '' }));
    setAptSearch('');
    setTenantSelectedBuilding('');
    // Fetch all apartments this tenant has ever rented
    await fetchTenantApartments(tenant.all_ids || [tenant.id]);
  };

  const handleTenantApartmentSelect = (apt) => {
    setFilters(f => {
      const currentIds = f.apartment_id ? f.apartment_id.split(',') : [];
      const aptIdStr = String(apt.apartment_id || apt.id);
      let newIds;
      if (currentIds.includes(aptIdStr)) {
        newIds = currentIds.filter(id => id !== aptIdStr);
      } else {
        newIds = [...currentIds, aptIdStr];
      }
      return {
        ...f,
        apartment_id: newIds.join(','),
        // If it's from tenant, we clear building filter. If it's from building, we keep building filter.
        building_id: apt.apartment_id ? '' : f.building_id,
      };
    });
    setAptSearch('');
  };

  const toggleCategory = (id) => {
    setSelectedCats(prev =>
      prev.includes(id) ? prev.filter(c => c !== id) : [...prev, id]
    );
  };

  const selectAllCats = () => setSelectedCats(CATEGORIES.map(c => c.id));
  const clearAllCats  = () => setSelectedCats([]);

  // ── AUTO-GENERATE: debounced on filters/categories change ──
  const generateReport = useCallback(async (currentFilters) => {
    if (!currentFilters.building_id && !currentFilters.apartment_id && !currentFilters.tenant_id) {
      setReportData([]);
      setGenerated(false);
      setGenerating(false);
      return;
    }

    setGenerating(true);
    setError(null);
    try {
      const params = new URLSearchParams();
      params.append('start_date', currentFilters.start_date);
      params.append('end_date',   currentFilters.end_date);
      if (currentFilters.building_id)  params.append('building_id',  currentFilters.building_id);
      if (currentFilters.apartment_id) params.append('apartment_id', currentFilters.apartment_id);
      if (currentFilters.tenant_id)    params.append('tenant_id',    currentFilters.tenant_id);
      if (currentFilters.payment_method) params.append('payment_method', currentFilters.payment_method);

      const res = await api.get(`/financial-reports/generate?${params.toString()}`);
      setReportData(res.data);
      setGenerated(true);
    } catch (e) {
      setError('Failed to generate report. Please check your filters and try again.');
    } finally {
      setGenerating(false);
    }
  }, []);

  // Debounce: wait 800ms after filters change before auto-fetching
  useEffect(() => {
    const timer = setTimeout(() => {
      generateReport(filters);
    }, 800);
    return () => clearTimeout(timer);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.start_date, filters.end_date, filters.building_id, filters.apartment_id, filters.tenant_id, filters.payment_method]);

  // Derived building apartments
  const buildingApartments = useMemo(() => {
    if (!filters.building_id || filters.tenant_id) return [];
    return allApartments.filter(a => String(a.building_id) === String(filters.building_id));
  }, [filters.building_id, filters.tenant_id, allApartments]);

  // ── aggregate totals ──
  const totals = useMemo(() => {
    const t = {
      apartments: reportData.length,
      rent_collected: 0, rent_outstanding: 0,
      insurance_deposited: 0, insurance_deducted: 0,
      electricity_collected: 0, electricity_outstanding: 0,
      generator_collected: 0, generator_outstanding: 0,
      expenses: 0, net_income: 0,
    };
    reportData.forEach(r => {
      const s = r.summary;
      t.rent_collected       += Number(s.total_rent_collected);
      t.rent_outstanding     += Number(s.total_rent_outstanding);
      t.insurance_deposited  += Number(s.total_insurance_deposited);
      t.insurance_deducted   += Number(s.total_insurance_deducted);
      t.electricity_collected+= Number(s.total_electricity_collected);
      t.electricity_outstanding += Number(s.total_electricity_outstanding);
      t.generator_collected  += Number(s.total_generator_collected);
      t.generator_outstanding+= Number(s.total_generator_outstanding);
      t.expenses             += Number(s.total_expenses);
      t.net_income           += Number(s.net_income);
    });
    return t;
  }, [reportData]);

  // ── print ──
  const handlePrint = () => window.print();

  // ── excel export ──
  const handleExcel = () => {
    if (!reportData.length) return;
    const rows = [['Apartment', 'Building', 'Tenant',
      ...(selectedCats.includes('rent')        ? ['Rent Billed','Rent Paid','Rent Outstanding'] : []),
      ...(selectedCats.includes('insurance')   ? ['Insurance Deposited','Insurance Deducted','Balance'] : []),
      ...(selectedCats.includes('electricity') ? ['Electricity Billed','Electricity Paid'] : []),
      ...(selectedCats.includes('generator')   ? ['Generator Billed','Generator Paid'] : []),
      ...(selectedCats.includes('expenses')    ? ['Total Expenses'] : []),
      ...(selectedCats.includes('summary')     ? ['Net Income'] : []),
    ]];

    reportData.forEach(r => {
      rows.push([
        r.apartment_code, r.building_name, r.tenant_name,
        ...(selectedCats.includes('rent')        ? [r.rent.total_billed, r.rent.total_paid, r.rent.total_outstanding] : []),
        ...(selectedCats.includes('insurance')   ? [r.insurance.total_deposited, r.insurance.total_deducted, r.insurance.balance] : []),
        ...(selectedCats.includes('electricity') ? [r.electricity.total_billed, r.electricity.total_paid] : []),
        ...(selectedCats.includes('generator')   ? [r.generator.total_billed, r.generator.total_paid] : []),
        ...(selectedCats.includes('expenses')    ? [r.expenses.total] : []),
        ...(selectedCats.includes('summary')     ? [r.summary.net_income] : []),
      ]);
    });

    const csv = rows.map(r => r.map(v => `"${v ?? 0}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement('a');
    a.href     = url;
    a.download = `Financial_Report_${filters.start_date}_${filters.end_date}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const user = (() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return {}; } })();

  /* ─── render ─── */
  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar" ref={printRef} id="printable-report">

        {/* ── Page Header ── */}
        <div className="flex justify-between items-start mb-8 no-print">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <BarChart2 className="text-indigo-400" size={34} />
              Financial Reports Center
            </h1>
            <p className="text-slate-400 mt-1">Generate comprehensive apartment & tenant financial reports</p>
          </div>
          {generated && (
            <div className="flex gap-2">
              <button onClick={handlePrint}
                className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl border border-slate-700 transition-all text-sm font-medium">
                <Printer size={16} /> Print
              </button>
              <button onClick={handleExcel}
                className="flex items-center gap-2 px-4 py-2 bg-green-600/20 hover:bg-green-600/30 text-green-400 rounded-xl border border-green-500/30 transition-all text-sm font-medium">
                <FileSpreadsheet size={16} /> Export CSV
              </button>
            </div>
          )}
        </div>

        {/* ═══════════════ FILTER SECTION ═══════════════ */}
        <div className="glass-card p-6 mb-6 no-print relative z-50">
          <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-widest mb-5 flex items-center gap-2">
            <Filter size={14} /> Filters
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-5">
            {/* Date From */}
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">From Date <span className="text-red-400">*</span></label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <input type="date"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 transition-colors"
                  value={filters.start_date}
                  onChange={e => setFilters(f => ({ ...f, start_date: e.target.value }))}
                />
              </div>
            </div>

            {/* Date To */}
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">To Date <span className="text-red-400">*</span></label>
              <div className="relative">
                <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <input type="date"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 transition-colors"
                  value={filters.end_date}
                  onChange={e => setFilters(f => ({ ...f, end_date: e.target.value }))}
                />
              </div>
            </div>

            {/* Building filter */}
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Building</label>
              <div className="relative">
                <Building className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <select
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 appearance-none transition-colors"
                  value={filters.building_id}
                  onChange={e => {
                    setFilters(f => ({ ...f, building_id: e.target.value, apartment_id: '', tenant_id: '' }));
                    setAptSearch(''); setTenantSearch('');
                  }}
                >
                  <option value="">All Buildings</option>
                  {buildings.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" size={15} />
              </div>
            </div>

            {/* Apartment filter */}
            <div className="relative">
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Apartment</label>
              <div className="relative">
                <Home className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <input
                  type="text"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 transition-colors"
                  placeholder="Search apartment..."
                  value={aptSearch}
                  onChange={e => { setAptSearch(e.target.value); setFilters(f => ({ ...f, apartment_id: '' })); }}
                />
              </div>
              {aptSearch && !filters.apartment_id && filteredApartments.length > 0 && (
                <div className="absolute z-50 top-full left-0 right-0 mt-1 bg-slate-800 border border-slate-700 rounded-xl shadow-xl max-h-48 overflow-y-auto">
                  {filteredApartments.slice(0, 10).map(a => (
                    <button key={a.id} onClick={() => handleApartmentSelect(a)}
                      className="w-full text-left px-4 py-2.5 hover:bg-slate-700 text-sm transition-colors">
                      <span className="text-white font-medium">{a.code}</span>
                      {a.building_name && <span className="text-slate-400 ml-2 text-xs">· {a.building_name}</span>}
                      {a.tenant_name && <span className="text-indigo-400 ml-2 text-xs">· {a.tenant_name}</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Tenant filter */}
            <div className="relative">
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Tenant</label>
              <div className="relative">
                <Users className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <input
                  type="text"
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 transition-colors"
                  placeholder="Search tenant by name..."
                  value={tenantSearch}
                  onChange={e => {
                    setTenantSearch(e.target.value);
                    setFilters(f => ({ ...f, tenant_id: '' }));
                    setSelectedTenantId(null);
                    setShowTenantApts(false);
                    setTenantApartments([]);
                    setTenantSelectedBuilding('');
                  }}
                />
              </div>
              {tenantSearch && !filters.tenant_id && filteredTenants.length > 0 && (
                <div className="absolute z-50 top-full left-0 right-0 mt-1 bg-slate-800 border border-slate-700 rounded-xl shadow-xl max-h-48 overflow-y-auto">
                  {filteredTenants.slice(0, 10).map(t => (
                    <button key={t.id} onClick={() => handleTenantSelect(t)}
                      className="w-full text-left px-4 py-2.5 hover:bg-slate-700 text-sm transition-colors">
                      <span className="text-white font-medium">{t.full_name}</span>
                      {t.phone && <span className="text-slate-400 ml-2 text-xs">· {t.phone}</span>}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Payment Method filter */}
            <div>
              <label className="block text-xs font-medium text-slate-400 mb-1.5">Payment Method</label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" size={15} />
                <select
                  className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-9 pr-3 py-2.5 text-white text-sm outline-none focus:border-indigo-500 appearance-none transition-colors"
                  value={filters.payment_method}
                  onChange={e => setFilters(f => ({ ...f, payment_method: e.target.value }))}
                >
                  <option value="">All Methods</option>
                  <option value="Cash">Cash</option>
                  <option value="Bank Transfer">Bank Transfer</option>
                  <option value="Mobile Money">Mobile Money</option>
                  <option value="Cheque">Cheque</option>
                  <option value="Other">Other</option>
                </select>
                <ChevronDown className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 pointer-events-none" size={15} />
              </div>
            </div>

            {/* Clear filters */}
            <div className="flex items-end gap-2">
              <button
                onClick={() => {
                  setFilters({ start_date: firstOfMonth, end_date: lastOfMonth, building_id: '', apartment_id: '', tenant_id: '', payment_method: '' });
                  setAptSearch(''); setTenantSearch('');
                  setSelectedTenantId(null); setTenantApartments([]); setShowTenantApts(false); setTenantSelectedBuilding('');
                }}
                className="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-400 rounded-xl border border-slate-700 text-sm transition-colors w-full"
              >
                Clear Filters
              </button>
            </div>
          </div>

          {/* ── Tenant's apartment history picker ── */}
          {showTenantApts && tenantApartments.length > 0 && (
            <div className="mt-4 pt-4 border-t border-slate-700/50">
              <p className="text-xs font-semibold text-indigo-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                <Building size={12} /> Select Building for <span className="text-white normal-case">{tenantSearch}</span>
              </p>
              
              <div className="flex flex-wrap gap-2 mb-4">
                <button
                  onClick={() => {
                    setTenantSelectedBuilding('');
                    setFilters(f => ({ ...f, building_id: '', apartment_id: '' }));
                  }}
                  className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all ${
                    !tenantSelectedBuilding
                      ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                      : 'bg-slate-800 border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  All Buildings
                </button>
                {Array.from(new Map(tenantApartments.filter(a => a.building_id).map(a => [a.building_id, a.building_name])).entries()).map(([bId, bName]) => {
                  const isSelected = tenantSelectedBuilding === String(bId);
                  return (
                    <button
                      key={bId}
                      onClick={() => {
                        setTenantSelectedBuilding(String(bId));
                        setFilters(f => ({ ...f, building_id: String(bId), apartment_id: '' }));
                      }}
                      className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all flex items-center gap-2 ${
                        isSelected
                          ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                          : 'bg-slate-800 border-slate-700 text-slate-300 hover:border-indigo-500/40 hover:text-white'
                      }`}
                    >
                      <div className={`w-4 h-4 rounded border flex items-center justify-center ${isSelected ? 'bg-indigo-500 border-indigo-500 text-white' : 'border-slate-500'}`}>
                        {isSelected && <Check size={12} strokeWidth={3} />}
                      </div>
                      <Building size={14} className={isSelected ? 'text-indigo-400' : 'text-slate-400'} />
                      <span className="font-bold text-white text-[13px]">{bName}</span>
                    </button>
                  );
                })}
              </div>

              <p className="text-xs font-semibold text-indigo-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                <Home size={12} /> Select Apartment
              </p>

              <div className="flex flex-wrap gap-2">
                <button
                  onClick={() => {
                    setFilters(f => ({ ...f, apartment_id: '' }));
                    setAptSearch('');
                  }}
                  className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all ${
                    !filters.apartment_id
                      ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                      : 'bg-slate-800 border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  All Apartments
                </button>
                {tenantApartments.filter(apt => !tenantSelectedBuilding || String(apt.building_id) === tenantSelectedBuilding).map((apt, i) => {
                  const isSelected = filters.apartment_id ? filters.apartment_id.split(',').includes(String(apt.apartment_id)) : false;
                  return (
                    <button
                      key={i}
                      onClick={() => handleTenantApartmentSelect(apt)}
                      className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all flex items-center gap-2 ${
                        isSelected
                          ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                          : 'bg-slate-800 border-slate-700 text-slate-300 hover:border-indigo-500/40 hover:text-white'
                      }`}
                    >
                      <div className={`w-4 h-4 rounded border flex items-center justify-center ${isSelected ? 'bg-indigo-500 border-indigo-500 text-white' : 'border-slate-500'}`}>
                        {isSelected && <Check size={12} strokeWidth={3} />}
                      </div>
                      <Home size={14} className="text-slate-400" />
                      <span className="font-bold text-white text-[13px]">{apt.apartment_code}</span>
                      <span className="text-[11px] text-slate-500">- {apt.building_name}</span>
                      {apt.contract_status && (
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                          apt.contract_status === 'Active' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-700 text-slate-400'
                        }`}>{apt.contract_status}</span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          {/* ── Building's apartment picker ── */}
          {filters.building_id && !filters.tenant_id && buildingApartments.length > 0 && (
            <div className="mt-4 pt-4 border-t border-slate-700/50">
              <p className="text-xs font-semibold text-indigo-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                <Building size={12} /> Select Apartments in <span className="text-white normal-case">{buildings.find(b => b.id == filters.building_id)?.name}</span>
              </p>
              <div className="flex flex-wrap gap-2">
                {/* All apartments in building (no apartment filter) */}
                <button
                  onClick={() => {
                    setFilters(f => ({ ...f, apartment_id: '' }));
                    setAptSearch('');
                  }}
                  className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all ${
                    !filters.apartment_id
                      ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                      : 'bg-slate-800 border-slate-700 text-slate-400 hover:border-slate-600'
                  }`}
                >
                  All Apartments
                </button>
                {buildingApartments.map((apt, i) => {
                  const isSelected = filters.apartment_id ? filters.apartment_id.split(',').includes(String(apt.id)) : false;
                  return (
                    <button
                      key={i}
                      onClick={() => handleTenantApartmentSelect(apt)}
                      className={`px-4 py-2 rounded-xl border text-sm font-medium transition-all flex items-center gap-2 ${
                        isSelected
                          ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300'
                          : 'bg-slate-800 border-slate-700 text-slate-300 hover:border-indigo-500/40 hover:text-white'
                      }`}
                    >
                      <div className={`w-4 h-4 rounded border flex items-center justify-center ${isSelected ? 'bg-indigo-500 border-indigo-500 text-white' : 'border-slate-500'}`}>
                        {isSelected && <Check size={12} strokeWidth={3} />}
                      </div>
                      <Home size={14} className="text-slate-400" />
                      <span className="font-bold text-white text-[13px]">{apt.code}</span>
                      <span className="text-[11px] text-slate-500">
                        - {apt.tenant_name ? apt.tenant_name : 'Vacant'}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* ═══════════════ CATEGORY SELECTION ═══════════════ */}
        <div className="glass-card p-6 mb-6 no-print">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-semibold text-slate-400 uppercase tracking-widest flex items-center gap-2">
              <CheckSquare size={14} /> Report Categories
            </h2>
            <div className="flex gap-2">
              <button onClick={selectAllCats} className="text-xs text-indigo-400 hover:text-indigo-300 transition-colors">Select All</button>
              <span className="text-slate-600">|</span>
              <button onClick={clearAllCats} className="text-xs text-slate-500 hover:text-slate-400 transition-colors">Clear All</button>
            </div>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {CATEGORIES.map(cat => {
              const Icon = cat.icon;
              const selected = selectedCats.includes(cat.id);
              return (
                <button
                  key={cat.id}
                  onClick={() => toggleCategory(cat.id)}
                  className={`relative p-4 rounded-xl border-2 flex flex-col items-center gap-2 transition-all ${
                    selected
                      ? `${cat.bg} ${cat.border} ${cat.color}`
                      : 'bg-slate-900/50 border-slate-700 text-slate-500 hover:border-slate-600'
                  }`}
                >
                  <Icon size={20} />
                  <span className="text-xs font-medium text-center leading-tight">{cat.label}</span>
                </button>
              );
            })}
          </div>
        </div>

        {/* ═══════════════ AUTO-GENERATE STATUS ═══════════════ */}
        {generating && (
          <div className="flex justify-center items-center gap-3 mb-6 no-print">
            <div className="w-5 h-5 border-2 border-indigo-500/30 border-t-indigo-400 rounded-full animate-spin" />
            <span className="text-slate-400 text-sm">Updating report...</span>
          </div>
        )}

        {/* ═══════════════ ERROR ═══════════════ */}
        {error && (
          <div className="glass-card p-4 mb-6 border border-red-500/30 bg-red-500/10 flex items-center gap-3">
            <AlertCircle className="text-red-400" size={20} />
            <p className="text-red-300 text-sm">{error}</p>
          </div>
        )}

        {/* ═══════════════ REPORT OUTPUT ═══════════════ */}
        {!generated && !generating && (
          <div className="glass-card p-16 text-center">
            <Filter className="mx-auto text-slate-600 mb-4" size={48} />
            <h3 className="text-xl font-semibold text-slate-400">Select a Filter to Begin</h3>
            <p className="text-slate-500 mt-2">Please select a Building, Apartment, or Tenant to generate the financial report.</p>
          </div>
        )}

        {generated && (
          <>
            {reportData.length === 0 ? (
              <div className="glass-card p-16 text-center">
                <FileText className="mx-auto text-slate-600 mb-4" size={48} />
                <h3 className="text-xl font-semibold text-slate-400">No Financial Records Found</h3>
                <p className="text-slate-500 mt-2">No financial records were found for the selected period and filters.</p>
              </div>
            ) : (
              <>
                {/* ── Summary Cards ── */}
                <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-4 gap-4 mb-8">
                  <SummaryCard label="Total Apartments" value={totals.apartments} icon={Home} color="text-indigo-400" />
                  <SummaryCard label="Total Rent Collected" value={`CFA ${fmt(totals.rent_collected)}`} icon={DollarSign} color="text-green-400"
                    sub={`Outstanding: CFA ${fmt(totals.rent_outstanding)}`} />
                  <SummaryCard label="Insurance Deposited" value={`CFA ${fmt(totals.insurance_deposited)}`} icon={Shield} color="text-purple-400"
                    sub={`Deducted: CFA ${fmt(totals.insurance_deducted)}`} />
                  <SummaryCard label="Electricity Collected" value={`CFA ${fmt(totals.electricity_collected)}`} icon={Zap} color="text-yellow-400"
                    sub={`Outstanding: CFA ${fmt(totals.electricity_outstanding)}`} />
                  <SummaryCard label="Total Expenses" value={`CFA ${fmt(totals.expenses)}`} icon={Package} color="text-red-400" />
                  <SummaryCard
                    label="Net Income"
                    value={`CFA ${fmt(totals.net_income)}`}
                    icon={totals.net_income >= 0 ? TrendingUp : TrendingDown}
                    color={totals.net_income >= 0 ? 'text-green-400' : 'text-red-400'}
                    sub="Collected − Expenses"
                  />
                  <SummaryCard label="Period" value={`${filters.start_date}`} icon={Calendar} color="text-slate-400" sub={`→ ${filters.end_date}`} />
                </div>

                {/* ── Per-Apartment Report Blocks ── */}
                <div className="space-y-6">
                  {reportData.map(apt => (
                    <div key={apt.apartment_id} className="glass-card overflow-hidden">
                      {/* Header */}
                      <div className="px-6 py-4 bg-slate-800/50 border-b border-slate-700/50 flex justify-between items-center">
                        <div className="flex items-center gap-4">
                          <div className="bg-indigo-500/20 p-2.5 rounded-xl">
                            <Home className="text-indigo-400" size={20} />
                          </div>
                          <div>
                            <h3 className="text-lg font-bold text-white">
                              Apt {apt.apartment_code}
                              <span className="text-slate-400 font-normal text-sm ml-2">· {apt.building_name}</span>
                            </h3>
                            <p className="text-sm text-slate-400 flex items-center gap-1">
                              <Users size={13} />
                              {apt.tenant_name === 'Vacant'
                                ? <span className="text-slate-500 italic">Vacant</span>
                                : <span className="text-indigo-300">{apt.tenant_name}</span>
                              }
                            </p>
                          </div>
                        </div>
                        <div className="text-right flex items-center gap-4">
                          {(Number(apt.summary.total_rent_outstanding) + Number(apt.summary.total_electricity_outstanding) + Number(apt.summary.total_generator_outstanding) > 0) && (
                            <div className="text-right border-r border-slate-700/50 pr-4">
                              <p className="text-xs text-danger uppercase tracking-widest font-semibold">Unpaid</p>
                              <p className="text-lg font-bold text-danger">
                                CFA {fmt(Number(apt.summary.total_rent_outstanding) + Number(apt.summary.total_electricity_outstanding) + Number(apt.summary.total_generator_outstanding))}
                              </p>
                            </div>
                          )}
                          <div>
                            <p className="text-xs text-slate-500 uppercase tracking-widest font-semibold">Net Income</p>
                            <p className={`text-xl font-bold ${Number(apt.summary.net_income) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                              CFA {fmt(apt.summary.net_income)}
                            </p>
                          </div>
                        </div>
                      </div>

                      <div className="p-6 space-y-5">
                        {/* RENT */}
                        {selectedCats.includes('rent') && (
                          <div>
                            <h4 className="text-xs font-semibold text-green-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <DollarSign size={13} /> Rental Payments
                            </h4>
                            {apt.rent.invoices.length === 0 ? (
                              <p className="text-slate-500 text-sm italic">No rent invoices in this period</p>
                            ) : (
                              <div className="overflow-x-auto rounded-lg border border-slate-700/50">
                                <table className="w-full text-sm">
                                  <thead>
                                    <tr className="bg-slate-800/50 text-slate-400 text-xs">
                                      <th className="px-4 py-2 text-left">Invoice #</th>
                                      <th className="px-4 py-2 text-right">Amount</th>
                                      <th className="px-4 py-2 text-right">Paid</th>
                                      <th className="px-4 py-2 text-right">Outstanding</th>
                                      <th className="px-4 py-2 text-center">Due Date</th>
                                      <th className="px-4 py-2 text-center">Status</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-slate-800">
                                    {apt.rent.invoices.map(inv => (
                                      <tr key={inv.id} className="hover:bg-slate-800/30 transition-colors">
                                        <td className="px-4 py-2 font-mono text-xs text-slate-300">{inv.invoice_number}</td>
                                        <td className="px-4 py-2 text-right text-white">{fmt(inv.amount)}</td>
                                        <td className="px-4 py-2 text-right text-green-400">{fmt(inv.paid)}</td>
                                        <td className="px-4 py-2 text-right text-red-400">{fmt(inv.outstanding)}</td>
                                        <td className="px-4 py-2 text-center text-slate-400">{inv.due_date}</td>
                                        <td className="px-4 py-2 text-center"><StatusBadge status={inv.status} /></td>
                                      </tr>
                                    ))}
                                  </tbody>
                                  <tfoot>
                                    <tr className="bg-slate-800/60 font-semibold text-sm">
                                      <td className="px-4 py-2 text-slate-400">Total</td>
                                      <td className="px-4 py-2 text-right text-white">{fmt(apt.rent.total_billed)}</td>
                                      <td className="px-4 py-2 text-right text-green-400">{fmt(apt.rent.total_paid)}</td>
                                      <td className="px-4 py-2 text-right text-red-400">{fmt(apt.rent.total_outstanding)}</td>
                                      <td colSpan={2}></td>
                                    </tr>
                                  </tfoot>
                                </table>
                              </div>
                            )}
                          </div>
                        )}

                        {/* INSURANCE */}
                        {selectedCats.includes('insurance') && (
                          <div>
                            <h4 className="text-xs font-semibold text-purple-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <Shield size={13} /> Insurance
                            </h4>
                            <div className="grid grid-cols-3 gap-3 mb-3">
                              <div className="bg-slate-900/50 rounded-xl p-3 text-center">
                                <p className="text-xs text-slate-500">Deposited</p>
                                <p className="text-white font-bold">{fmt(apt.insurance.total_deposited)}</p>
                              </div>
                              <div className="bg-slate-900/50 rounded-xl p-3 text-center">
                                <p className="text-xs text-slate-500">Deducted</p>
                                <p className="text-red-400 font-bold">{fmt(apt.insurance.total_deducted)}</p>
                              </div>
                              <div className="bg-slate-900/50 rounded-xl p-3 text-center">
                                <p className="text-xs text-slate-500">Current Balance</p>
                                <p className="text-purple-400 font-bold">{fmt(apt.insurance.balance)}</p>
                              </div>
                            </div>
                            {apt.insurance.transactions.length > 0 && (
                              <div className="overflow-x-auto rounded-lg border border-slate-700/50">
                                <table className="w-full text-sm">
                                  <thead>
                                    <tr className="bg-slate-800/50 text-slate-400 text-xs">
                                      <th className="px-4 py-2 text-left">Date</th>
                                      <th className="px-4 py-2 text-left">Type</th>
                                      <th className="px-4 py-2 text-right">Amount</th>
                                      <th className="px-4 py-2 text-left">Notes</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-slate-800">
                                    {apt.insurance.transactions.map((tr, i) => (
                                      <tr key={i} className="hover:bg-slate-800/30">
                                        <td className="px-4 py-2 text-slate-400">{tr.date}</td>
                                        <td className="px-4 py-2">
                                          <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${tr.type === 'Deposit' ? 'bg-purple-500/20 text-purple-400' : 'bg-red-500/20 text-red-400'}`}>
                                            {tr.type}
                                          </span>
                                        </td>
                                        <td className="px-4 py-2 text-right text-white">{fmt(tr.amount)}</td>
                                        <td className="px-4 py-2 text-slate-400 text-xs">{tr.notes || '—'}</td>
                                      </tr>
                                    ))}
                                  </tbody>
                                </table>
                              </div>
                            )}
                            {apt.insurance.transactions.length === 0 && (
                              <p className="text-slate-500 text-sm italic">No insurance transactions in this period</p>
                            )}
                          </div>
                        )}

                        {/* ELECTRICITY */}
                        {selectedCats.includes('electricity') && (
                          <div>
                            <h4 className="text-xs font-semibold text-yellow-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <Zap size={13} /> Electricity Subscription
                            </h4>
                            {(!apt.electricity.invoices || apt.electricity.invoices.length === 0) && (!apt.electricity.subscriptions || apt.electricity.subscriptions.length === 0) ? (
                              <p className="text-slate-500 text-sm italic">No electricity subscriptions in this period</p>
                            ) : (
                              <div className="flex gap-4">
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Total Billed</p>
                                  <p className="text-white font-bold">{fmt(apt.electricity.total_billed)}</p>
                                </div>
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Collected</p>
                                  <p className="text-yellow-400 font-bold">{fmt(apt.electricity.total_paid)}</p>
                                </div>
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Outstanding</p>
                                  <p className="text-red-400 font-bold">{fmt(apt.electricity.total_outstanding)}</p>
                                </div>
                              </div>
                            )}
                          </div>
                        )}

                        {/* GENERATOR */}
                        {selectedCats.includes('generator') && (
                          <div>
                            <h4 className="text-xs font-semibold text-orange-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <Activity size={13} /> Generator Subscription
                            </h4>
                            {!apt.generator.records || apt.generator.records.length === 0 ? (
                              <p className="text-slate-500 text-sm italic">No generator subscriptions in this period</p>
                            ) : (
                              <div className="flex gap-4">
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Total Billed</p>
                                  <p className="text-white font-bold">{fmt(apt.generator.total_billed)}</p>
                                </div>
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Collected</p>
                                  <p className="text-orange-400 font-bold">{fmt(apt.generator.total_paid)}</p>
                                </div>
                                <div className="bg-slate-900/50 rounded-xl p-3 text-center flex-1">
                                  <p className="text-xs text-slate-500">Outstanding</p>
                                  <p className="text-red-400 font-bold">{fmt(apt.generator.total_outstanding)}</p>
                                </div>
                              </div>
                            )}
                          </div>
                        )}

                        {/* EXPENSES */}
                        {selectedCats.includes('expenses') && (
                          <div>
                            <h4 className="text-xs font-semibold text-red-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <Package size={13} /> Apartment Expenses
                            </h4>
                            {apt.expenses.items.length === 0 ? (
                              <p className="text-slate-500 text-sm italic">No expenses recorded in this period</p>
                            ) : (
                              <div className="overflow-x-auto rounded-lg border border-slate-700/50">
                                <table className="w-full text-sm">
                                  <thead>
                                    <tr className="bg-slate-800/50 text-slate-400 text-xs">
                                      <th className="px-4 py-2 text-left">Date</th>
                                      <th className="px-4 py-2 text-left">Category</th>
                                      <th className="px-4 py-2 text-left">Description</th>
                                      <th className="px-4 py-2 text-right">Amount</th>
                                    </tr>
                                  </thead>
                                  <tbody className="divide-y divide-slate-800">
                                    {apt.expenses.items.map((ex, i) => (
                                      <tr key={i} className="hover:bg-slate-800/30">
                                        <td className="px-4 py-2 text-slate-400">{ex.date}</td>
                                        <td className="px-4 py-2 text-slate-300">{ex.category_name || '—'}</td>
                                        <td className="px-4 py-2 text-slate-400 text-xs">{ex.description || ex.notes || '—'}</td>
                                        <td className="px-4 py-2 text-right text-red-400 font-medium">{fmt(ex.amount)}</td>
                                      </tr>
                                    ))}
                                  </tbody>
                                  <tfoot>
                                    <tr className="bg-slate-800/60 font-semibold">
                                      <td colSpan={3} className="px-4 py-2 text-slate-400">Total Expenses</td>
                                      <td className="px-4 py-2 text-right text-red-400">{fmt(apt.expenses.total)}</td>
                                    </tr>
                                  </tfoot>
                                </table>
                              </div>
                            )}
                          </div>
                        )}

                        {/* SUMMARY */}
                        {selectedCats.includes('summary') && (
                          <div>
                            <h4 className="text-xs font-semibold text-indigo-400 uppercase tracking-widest mb-3 flex items-center gap-2">
                              <BarChart2 size={13} /> Financial Summary
                            </h4>
                            <div className="overflow-x-auto rounded-lg border border-slate-700/50">
                              <table className="w-full text-sm text-left">
                                <thead className="bg-slate-800/50 text-slate-400 text-xs">
                                  <tr>
                                    <th className="px-4 py-3">Item</th>
                                    <th className="px-4 py-3 text-right">Total Cost</th>
                                    <th className="px-4 py-3 text-right">Paid</th>
                                    <th className="px-4 py-3 text-right">Remaining</th>
                                  </tr>
                                </thead>
                                <tbody className="divide-y divide-slate-800/50 text-slate-300">
                                  <tr className="hover:bg-slate-800/30">
                                    <td className="px-4 py-3 font-medium text-green-400">Apartment Rent</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_rent_billed)}</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_rent_collected)}</td>
                                    <td className="px-4 py-3 text-right text-red-400">{fmt(apt.summary.total_rent_outstanding)}</td>
                                  </tr>
                                  <tr className="hover:bg-slate-800/30">
                                    <td className="px-4 py-3 font-medium text-purple-400">Insurance</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_insurance_billed)}</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_insurance_deposited)}</td>
                                    <td className="px-4 py-3 text-right text-red-400">{fmt(apt.summary.total_insurance_billed - apt.summary.total_insurance_deposited)}</td>
                                  </tr>
                                  <tr className="hover:bg-slate-800/30">
                                    <td className="px-4 py-3 font-medium text-yellow-400">Electricity Subscription</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_electricity_billed)}</td>
                                    <td className="px-4 py-3 text-right">{fmt(apt.summary.total_electricity_collected)}</td>
                                    <td className="px-4 py-3 text-right text-red-400">{fmt(apt.summary.total_electricity_outstanding)}</td>
                                  </tr>
                                </tbody>
                              </table>
                            </div>
                            
                            <div className="mt-4 flex flex-col items-end gap-1 text-sm bg-slate-900/50 p-4 rounded-xl border border-slate-800">
                              <p className="text-slate-400 w-48 flex justify-between">
                                <span>Total Cost:</span> 
                                <span className="text-white font-medium">CFA {fmt(apt.summary.total_rent_billed + apt.summary.total_insurance_billed + apt.summary.total_generator_billed + apt.summary.total_electricity_billed)}</span>
                              </p>
                              <p className="text-slate-400 w-48 flex justify-between">
                                <span>Total Paid:</span> 
                                <span className="text-green-400 font-medium">CFA {fmt(apt.summary.total_collected)}</span>
                              </p>
                              <p className="text-slate-400 w-48 flex justify-between">
                                <span>Total Remaining:</span> 
                                <span className="text-red-400 font-medium">CFA {fmt(apt.summary.total_rent_outstanding + (apt.summary.total_insurance_billed - apt.summary.total_insurance_deposited) + apt.summary.total_generator_outstanding + apt.summary.total_electricity_outstanding)}</span>
                              </p>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </div>

      {/* ═══════════════ PRO PRINT LAYOUT (ONLY VISIBLE WHEN PRINTING) ═══════════════ */}
      {generated && reportData.length > 0 && (
        <div className="print-only text-slate-800 bg-white min-h-screen font-serif w-full absolute top-0 left-0 hidden border-l-[32px] border-[#7c97ac] py-12 px-16">
          {/* Header */}
          <div className="flex justify-between items-end border-b-2 border-[#7c97ac] pb-6 mb-10">
            <div>
              <PrintLogo className="h-16 w-auto object-contain mb-2 print:h-16 print:w-auto" />
              <h1 className="text-3xl font-black uppercase tracking-widest text-[#2c3e50] mb-1">Bitar PMS</h1>
              <h2 className="text-sm text-[#7c97ac] font-bold tracking-widest uppercase">Financial Report</h2>
            </div>
            <div className="text-right">
              <h1 className="text-2xl italic font-bold text-[#2c3e50] tracking-widest uppercase mb-3">Statement</h1>
              <p className="text-xs text-slate-500 uppercase tracking-widest">
                {filters.start_date} <span className="font-normal mx-1">to</span> {filters.end_date}
              </p>
            </div>
          </div>
            
          {/* Applied Filters Summary */}
          <div className="flex gap-16 text-sm mb-12 text-[#2c3e50]">
            {filters.building_id && (
              <div>
                <p className="text-[10px] text-[#7c97ac] uppercase tracking-widest mb-1 font-bold">Building</p>
                <p className="font-semibold text-lg">{buildings.find(b => b.id == filters.building_id)?.name}</p>
              </div>
            )}
            {filters.apartment_id && (
              <div>
                <p className="text-[10px] text-[#7c97ac] uppercase tracking-widest mb-1 font-bold">Apartment</p>
                <p className="font-semibold text-lg">{aptSearch || allApartments.find(a => a.id == filters.apartment_id)?.code}</p>
              </div>
            )}
            {filters.tenant_id && (
              <div>
                <p className="text-[10px] text-[#7c97ac] uppercase tracking-widest mb-1 font-bold">Tenant</p>
                <p className="font-semibold text-lg">{tenantSearch}</p>
              </div>
            )}
          </div>

          {/* Overall Summary Table */}
          {selectedCats.includes('summary') && (
            <div className="mb-16">
              <h3 className="text-lg font-bold text-[#2c3e50] uppercase tracking-widest mb-4">Overall Financial Summary</h3>
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-[#7c97ac]">
                    <th className="py-2 px-2 text-left font-bold text-[#7c97ac] uppercase tracking-widest text-[11px]">Item</th>
                    <th className="py-2 px-2 text-right font-bold text-[#7c97ac] uppercase tracking-widest text-[11px]">Total Cost</th>
                    <th className="py-2 px-2 text-right font-bold text-[#7c97ac] uppercase tracking-widest text-[11px]">Paid</th>
                    <th className="py-2 px-2 text-right font-bold text-[#7c97ac] uppercase tracking-widest text-[11px]">Remaining</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#e2e8f0]">
                  <tr>
                    <td className="py-3 px-2 font-medium text-[#2c3e50]">Apartment Rent</td>
                    <td className="py-3 px-2 text-right text-slate-600">{fmt(totals.rent_collected + totals.rent_outstanding)}</td>
                    <td className="py-3 px-2 text-right text-[#2c3e50] font-bold">{fmt(totals.rent_collected)}</td>
                    <td className="py-3 px-2 text-right text-red-600">{fmt(totals.rent_outstanding)}</td>
                  </tr>
                  <tr>
                    <td className="py-3 px-2 font-medium text-[#2c3e50]">Insurance</td>
                    <td className="py-3 px-2 text-right text-slate-600">{fmt(totals.insurance_deposited + totals.insurance_deducted)}</td>
                    <td className="py-3 px-2 text-right text-[#2c3e50] font-bold">{fmt(totals.insurance_deposited)}</td>
                    <td className="py-3 px-2 text-right text-red-600">{fmt((totals.insurance_deposited + totals.insurance_deducted) - totals.insurance_deposited)}</td>
                  </tr>
                  <tr>
                    <td className="py-3 px-2 font-medium text-[#2c3e50]">Electricity Subscription</td>
                    <td className="py-3 px-2 text-right text-slate-600">{fmt(totals.electricity_collected + totals.electricity_outstanding)}</td>
                    <td className="py-3 px-2 text-right text-[#2c3e50] font-bold">{fmt(totals.electricity_collected)}</td>
                    <td className="py-3 px-2 text-right text-red-600">{fmt(totals.electricity_outstanding)}</td>
                  </tr>
                  <tr>
                    <td className="py-3 px-2 font-medium text-[#2c3e50]">Expenses</td>
                    <td className="py-3 px-2 text-right text-slate-500" colSpan={3}>({fmt(totals.expenses)})</td>
                  </tr>
                </tbody>
              </table>
              <div className="mt-4 flex flex-col items-end gap-1 text-sm bg-gray-50 p-4 rounded-xl border border-[#e2e8f0]">
                <p className="text-[#2c3e50] w-64 flex justify-between">
                  <span>Total Cost:</span> 
                  <span className="font-medium">CFA {fmt((totals.rent_collected + totals.rent_outstanding) + (totals.insurance_deposited + totals.insurance_deducted) + (totals.generator_collected + totals.generator_outstanding) + (totals.electricity_collected + totals.electricity_outstanding))}</span>
                </p>
                <p className="text-[#2c3e50] w-64 flex justify-between">
                  <span>Total Paid:</span> 
                  <span className="font-bold">CFA {fmt(totals.rent_collected + totals.insurance_deposited + totals.generator_collected + totals.electricity_collected)}</span>
                </p>
                <p className="text-red-600 w-64 flex justify-between">
                  <span>Total Remaining:</span> 
                  <span className="font-bold">CFA {fmt(totals.rent_outstanding + ((totals.insurance_deposited + totals.insurance_deducted) - totals.insurance_deposited) + totals.generator_outstanding + totals.electricity_outstanding)}</span>
                </p>
              </div>
            </div>
          )}

          {/* Breakdown per Apartment */}
          {reportData.map(apt => (
            <div key={apt.apartment_id} className="mb-16" style={{ pageBreakInside: 'avoid' }}>
              <div className="mb-8">
                <h4 className="font-bold text-lg text-[#2c3e50] uppercase tracking-widest border-b border-[#7c97ac] pb-2 mb-4">
                  Apt {apt.apartment_code} <span className="text-[#7c97ac] font-normal mx-2">|</span> {apt.building_name}
                </h4>
                <div className="flex justify-between items-start text-sm mt-2">
                  <p className="text-slate-500 uppercase tracking-widest text-xs">
                    Tenant: <span className="font-bold text-[#2c3e50] text-sm ml-2">{apt.tenant_name}</span>
                  </p>
                  <div className="flex items-center gap-6">
                    {(Number(apt.summary.total_rent_outstanding) + Number(apt.summary.total_electricity_outstanding) + Number(apt.summary.total_generator_outstanding) > 0) && (
                      <p className="text-red-500 uppercase tracking-widest text-xs text-right">
                        Unpaid: <span className="font-bold text-red-600 text-sm ml-2">CFA {fmt(Number(apt.summary.total_rent_outstanding) + Number(apt.summary.total_electricity_outstanding) + Number(apt.summary.total_generator_outstanding))}</span>
                      </p>
                    )}
                    <p className="text-slate-500 uppercase tracking-widest text-xs text-right">
                      Net Income: <span className="font-bold text-[#2c3e50] text-sm ml-2">CFA {fmt(apt.summary.net_income)}</span>
                    </p>
                  </div>
                </div>
              </div>

              {selectedCats.includes('rent') && apt.rent.invoices.length > 0 && (
                <div className="mb-8 pl-4">
                  <h5 className="font-bold text-sm mb-3 uppercase tracking-widest text-[#2c3e50]">Rental Payments</h5>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-t border-b border-[#7c97ac]">
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Invoice #</th>
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Due Date</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Amount</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Amount Paid</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Remaining</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Status</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#e2e8f0]">
                      {apt.rent.invoices.map(inv => (
                        <tr key={inv.id}>
                          <td className="py-3 px-2 text-[#2c3e50] font-sans text-xs">{inv.invoice_number}</td>
                          <td className="py-3 px-2 text-slate-500">{inv.due_date}</td>
                          <td className="py-3 px-2 text-right text-slate-600">{fmt(inv.amount)}</td>
                          <td className="py-3 px-2 text-right text-slate-600">{fmt(inv.paid)}</td>
                          <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(inv.outstanding)}</td>
                          <td className="py-3 px-2 text-right text-[#7c97ac] text-[10px] uppercase tracking-widest">{inv.status}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr className="border-t border-[#7c97ac]">
                        <td className="py-3 px-2 font-bold uppercase text-[#2c3e50] text-[10px] tracking-widest" colSpan={2}>Rent Subtotal</td>
                        <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.rent.total_billed)}</td>
                        <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.rent.total_paid)}</td>
                        <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.rent.total_outstanding)}</td>
                        <td className="py-3 px-2"></td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              )}

              {selectedCats.includes('insurance') && apt.insurance.transactions.length > 0 && (
                <div className="mb-8 pl-4">
                  <h5 className="font-bold text-sm mb-3 uppercase tracking-widest text-[#2c3e50]">Insurance History</h5>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-t border-b border-[#7c97ac]">
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Date</th>
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Type</th>
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Notes</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Amount</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#e2e8f0]">
                      {apt.insurance.transactions.map((tr, i) => (
                        <tr key={i}>
                          <td className="py-3 px-2 text-slate-500">{tr.date}</td>
                          <td className="py-3 px-2 text-[#2c3e50]">{tr.type}</td>
                          <td className="py-3 px-2 text-slate-500 italic">{tr.notes || '—'}</td>
                          <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(tr.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr className="border-t border-[#7c97ac]">
                        <td className="py-3 px-2 font-bold uppercase text-[#2c3e50] text-[10px] tracking-widest" colSpan={3}>Current Balance</td>
                        <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.insurance.balance)}</td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              )}

              {/* Utility Subscriptions Block */}
              <div className="flex gap-12 pl-4">
                {selectedCats.includes('electricity') && (apt.electricity.invoices?.length > 0 || apt.electricity.subscriptions?.length > 0) && (
                  <div className="flex-1 mb-8">
                    <h5 className="font-bold text-sm mb-3 uppercase tracking-widest text-[#2c3e50]">Electricity</h5>
                    <table className="w-full text-sm">
                      <tbody className="divide-y divide-[#e2e8f0] border-t border-b border-[#7c97ac]">
                        <tr>
                          <td className="py-3 px-2 text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Total Billed</td>
                          <td className="py-3 px-2 text-right font-medium text-slate-600">{fmt(apt.electricity.total_billed)}</td>
                        </tr>
                        <tr>
                          <td className="py-3 px-2 text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Total Paid</td>
                          <td className="py-3 px-2 text-right font-medium text-slate-600">{fmt(apt.electricity.total_paid)}</td>
                        </tr>
                        <tr>
                          <td className="py-3 px-2 font-bold text-[#2c3e50] uppercase tracking-widest text-[10px]">Remaining</td>
                          <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.electricity.total_outstanding)}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                )}

                {selectedCats.includes('generator') && apt.generator.records?.length > 0 && (
                  <div className="flex-1 mb-8">
                    <h5 className="font-bold text-sm mb-3 uppercase tracking-widest text-[#2c3e50]">Generator</h5>
                    <table className="w-full text-sm">
                      <tbody className="divide-y divide-[#e2e8f0] border-t border-b border-[#7c97ac]">
                        <tr>
                          <td className="py-3 px-2 text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Total Billed</td>
                          <td className="py-3 px-2 text-right font-medium text-slate-600">{fmt(apt.generator.total_billed)}</td>
                        </tr>
                        <tr>
                          <td className="py-3 px-2 text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Total Paid</td>
                          <td className="py-3 px-2 text-right font-medium text-slate-600">{fmt(apt.generator.total_paid)}</td>
                        </tr>
                        <tr>
                          <td className="py-3 px-2 font-bold text-[#2c3e50] uppercase tracking-widest text-[10px]">Remaining</td>
                          <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.generator.total_outstanding)}</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                )}
                
                {(!selectedCats.includes('electricity') || (apt.electricity.invoices?.length === 0 && apt.electricity.subscriptions?.length === 0)) && (
                  <div className="flex-1"></div>
                )}
                {(!selectedCats.includes('generator') || apt.generator.records?.length === 0) && (
                  <div className="flex-1"></div>
                )}
              </div>

              {selectedCats.includes('expenses') && apt.expenses.items.length > 0 && (
                <div className="mb-8 pl-4">
                  <h5 className="font-bold text-sm mb-3 uppercase tracking-widest text-[#2c3e50]">Apartment Expenses</h5>
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="border-t border-b border-[#7c97ac]">
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Date</th>
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Category</th>
                        <th className="py-2 px-2 text-left text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Description</th>
                        <th className="py-2 px-2 text-right text-[#7c97ac] font-bold uppercase tracking-widest text-[10px]">Cost</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#e2e8f0]">
                      {apt.expenses.items.map((ex, i) => (
                        <tr key={i}>
                          <td className="py-3 px-2 text-slate-500">{ex.date}</td>
                          <td className="py-3 px-2 text-[#2c3e50]">{ex.category_name || '—'}</td>
                          <td className="py-3 px-2 text-slate-500 italic">{ex.description || ex.notes || '—'}</td>
                          <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(ex.amount)}</td>
                        </tr>
                      ))}
                    </tbody>
                    <tfoot>
                      <tr className="border-t border-[#7c97ac]">
                        <td className="py-3 px-2 font-bold uppercase text-[#2c3e50] text-[10px] tracking-widest" colSpan={3}>Total Expenses</td>
                        <td className="py-3 px-2 text-right font-bold text-[#2c3e50]">{fmt(apt.expenses.total)}</td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default FinancialReports;
