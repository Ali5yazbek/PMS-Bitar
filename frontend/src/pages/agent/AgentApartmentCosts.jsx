import React, { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import {
  ShoppingCart, Building2, Home, Upload, X, Check, Clock,
  AlertCircle, ChevronRight, Camera, DollarSign, FileText,
  Calendar, Package, History, Plus, RefreshCw, Search, ChevronDown,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// ─── Status Badge ─────────────────────────────────────────────────────────────
const StatusBadge = ({ status }) => {
  const cfg = {
    Pending:  { cls: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30', icon: Clock,       label: 'Pending Review' },
    Accepted: { cls: 'bg-green-500/20  text-green-400  border-green-500/30',  icon: Check,       label: 'Accepted' },
    Rejected: { cls: 'bg-red-500/20    text-red-400    border-red-500/30',    icon: AlertCircle, label: 'Rejected' },
  };
  const c = cfg[status] || cfg['Pending'];
  const Icon = c.icon;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-xs font-semibold ${c.cls}`}>
      <Icon size={12} /> {c.label}
    </span>
  );
};

// ─── Receipt Preview ──────────────────────────────────────────────────────────
const ReceiptPreview = ({ src }) => {
  if (!src) return null;
  const baseUrl = (axios.defaults.baseURL || '').replace('/api', '');
  const fullUrl = src.startsWith('http') ? src : `${baseUrl}/${src}`;
  const isPdf   = src.toLowerCase().endsWith('.pdf');
  return isPdf ? (
    <a href={fullUrl} target="_blank" rel="noreferrer"
      className="inline-flex items-center gap-2 px-3 py-1.5 bg-indigo-500/20 text-indigo-400 rounded-lg text-sm hover:bg-indigo-500/30 transition-colors">
      <FileText size={14} /> View PDF
    </a>
  ) : (
    <a href={fullUrl} target="_blank" rel="noreferrer">
      <img src={fullUrl} alt="Receipt"
        className="w-16 h-16 object-cover rounded-xl border border-slate-600 hover:scale-105 transition-transform cursor-zoom-in shadow-lg" />
    </a>
  );
};

// ─── Searchable Select ────────────────────────────────────────────────────────
const SearchableSelect = ({ options, value, onChange, placeholder, disabled }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const wrapperRef = useRef(null);

  React.useEffect(() => {
    const handleClickOutside = (e) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target)) setIsOpen(false);
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedOpt = options.find(o => String(o.value) === String(value));
  const filtered = options.filter(o => o.label.toLowerCase().includes(search.toLowerCase()));

  return (
    <div className={`relative ${disabled ? 'opacity-40 pointer-events-none' : ''}`} ref={wrapperRef}>
      <div 
        onClick={() => setIsOpen(!isOpen)}
        className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 cursor-pointer flex justify-between items-center hover:border-slate-500 transition-colors"
      >
        <span className={selectedOpt ? 'text-white' : 'text-slate-500'}>
          {selectedOpt ? selectedOpt.label : placeholder}
        </span>
        <ChevronDown size={16} className={`text-slate-400 transition-transform ${isOpen ? 'rotate-180' : ''}`} />
      </div>
      
      {isOpen && (
        <div className="absolute z-50 top-full left-0 right-0 mt-2 bg-slate-800 border border-slate-600 rounded-xl shadow-xl overflow-hidden animate-fade-in-down">
          <div className="p-2 border-b border-slate-700 flex items-center gap-2 bg-slate-800/50">
            <Search size={14} className="text-slate-400" />
            <input 
              autoFocus
              type="text" 
              placeholder="Search..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-transparent text-white text-sm focus:outline-none placeholder-slate-500"
            />
          </div>
          <div className="max-h-60 overflow-y-auto custom-scrollbar p-1">
            {filtered.length === 0 ? (
              <div className="p-3 text-center text-sm text-slate-500">No results found</div>
            ) : (
              filtered.map(opt => (
                <div 
                  key={opt.value}
                  onClick={() => {
                    onChange(opt.value);
                    setIsOpen(false);
                    setSearch('');
                  }}
                  className={`px-3 py-2 text-sm rounded-lg cursor-pointer transition-colors ${String(value) === String(opt.value) ? 'bg-emerald-500/20 text-emerald-400' : 'text-slate-300 hover:bg-slate-700/50 hover:text-white'}`}
                >
                  {opt.label}
                </div>
              ))
            )}
          </div>
        </div>
      )}
    </div>
  );
};

// ─── Main Component ───────────────────────────────────────────────────────────
const AgentApartmentCosts = () => {
  const navigate    = useNavigate();
  const queryClient = useQueryClient();
  const fileRef     = useRef(null);

  const user = (() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } })();

  const [activeTab, setActiveTab] = useState('submit');
  const [dateFilter, setDateFilter] = useState('');
  const [selectedBuilding,   setSelectedBuilding]   = useState('');
  const [selectedApartment,  setSelectedApartment]  = useState('');
  const [form, setForm] = useState({
    supplier_name: '',
    amount:        '',
    date:          new Date().toISOString().slice(0, 10),
    notes:         '',
  });
  const [receiptFile,    setReceiptFile]    = useState(null);
  const [receiptPreview, setReceiptPreview] = useState(null);
  const [submitError,    setSubmitError]    = useState('');
  const [submitSuccess,  setSubmitSuccess]  = useState('');

  // ── Fetch buildings (proven endpoint used by ApartmentCostReport)
  const { data: buildings = [], isLoading: bLoading } = useQuery({
    queryKey: ['buildings'],
    queryFn:  async () => (await axios.get('/buildings')).data,
  });

  // ── Fetch ALL apartments, then filter by selected building on the frontend
  const { data: allApartments = [], isLoading: aLoading } = useQuery({
    queryKey: ['apartments'],
    queryFn:  async () => (await axios.get('/apartments')).data,
  });

  // ── Fetch agent purchase history
  const { data: history = [], isLoading: hLoading, refetch } = useQuery({
    queryKey: ['agent_purchase_history', user?.id],
    queryFn:  async () => {
      try {
        const res = await axios.get(`/energy/agent/apartment-purchases?user_id=${user?.id || 1}`);
        return res.data?.history || [];
      } catch {
        return [];
      }
    },
    refetchInterval: 30000,
  });

  const filteredHistory = history.filter(item => {
    if (!dateFilter) return true;
    // item.date is usually YYYY-MM-DD
    return item.date === dateFilter;
  });

  const filteredApartments = allApartments.filter(a => String(a.building_id) === String(selectedBuilding));

  // ── Submit mutation
  const submitMutation = useMutation({
    mutationFn: async () => {
      if (!selectedBuilding)  throw new Error('Please select a building');
      if (!selectedApartment) throw new Error('Please select an apartment');
      if (!form.amount || parseFloat(form.amount) <= 0) throw new Error('Please enter a valid amount');
      if (!receiptFile)  throw new Error('Receipt image is required as proof');

      const fd = new FormData();
      fd.append('apartment_id',  selectedApartment);
      fd.append('supplier_name', form.supplier_name);
      fd.append('amount',        form.amount);
      fd.append('date',          form.date);
      fd.append('notes',         form.notes);
      fd.append('submitted_by',  user?.id || 1);
      fd.append('receipt_image', receiptFile);

      const res = await axios.post('/energy/agent/apartment-purchase', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      return res.data;
    },
    onSuccess: (data) => {
      setSubmitSuccess(data.message || 'Purchase submitted successfully!');
      setSubmitError('');
      setForm({ supplier_name: '', amount: '', date: new Date().toISOString().slice(0, 10), notes: '' });
      setReceiptFile(null);
      setReceiptPreview(null);
      setSelectedApartment('');
      setSelectedBuilding('');
      queryClient.invalidateQueries(['agent_purchase_history']);
      setTimeout(() => { setSubmitSuccess(''); setActiveTab('history'); }, 2500);
    },
    onError: (err) => {
      setSubmitError(err.response?.data?.error || err.message || 'Submission failed');
    },
  });

  const handleFile = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setReceiptFile(file);
    const reader = new FileReader();
    reader.onload = (ev) => setReceiptPreview(ev.target.result);
    reader.readAsDataURL(file);
  };

  const pendingCount  = history.filter(h => h.status === 'Pending').length;
  const rejectedCount = history.filter(h => h.status === 'Rejected').length;
  const isLoading     = bLoading || aLoading;

  return (
    <div className="p-6 max-w-4xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">

      {/* ── Header ─────────────────────────────────────────────────────────── */}
      <div className="mb-8">
        <button onClick={() => navigate('/agent-dashboard')}
          className="flex items-center gap-1.5 text-slate-400 hover:text-white transition-colors mb-4 text-sm">
          <ChevronRight size={14} className="rotate-180" /> Back to Dashboard
        </button>
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-emerald-500/20 text-emerald-400 flex items-center justify-center shadow-lg shadow-emerald-500/10">
                <ShoppingCart size={22} />
              </div>
              Apartment Cost
            </h1>
            <p className="text-slate-400 mt-1 text-sm">
              Log purchases you made for apartments — upload receipt as proof.
            </p>
          </div>
          <button onClick={() => { refetch(); queryClient.invalidateQueries(['buildings']); queryClient.invalidateQueries(['apartments']); }}
            className="p-2 rounded-lg bg-slate-800 border border-slate-700 text-slate-400 hover:text-white transition-colors">
            <RefreshCw size={16} />
          </button>
        </div>
      </div>

      {/* ── Stats ──────────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {[
          { label: 'Total Submitted', value: history.length,  color: 'border-indigo-500',  icon: Package },
          { label: 'Pending Review',  value: pendingCount,    color: 'border-yellow-500',  icon: Clock,       glow: pendingCount > 0 },
          { label: 'Rejected',        value: rejectedCount,   color: 'border-red-500',     icon: AlertCircle },
        ].map(s => {
          const Icon = s.icon;
          return (
            <div key={s.label} className={`glass-card p-5 border-l-4 ${s.color} rounded-2xl`}>
              <div className="flex items-center justify-between mb-2">
                <p className="text-slate-400 text-xs font-bold uppercase tracking-wide">{s.label}</p>
                <Icon size={16} className="text-slate-600" />
              </div>
              <p className={`text-3xl font-extrabold text-white ${s.glow ? 'animate-pulse' : ''}`}>
                {hLoading ? '…' : s.value}
              </p>
            </div>
          );
        })}
      </div>

      {/* ── Tabs ───────────────────────────────────────────────────────────── */}
      <div className="flex gap-2 mb-6">
        {[
          { id: 'submit',  label: 'New Purchase',           icon: Plus    },
          { id: 'history', label: `History (${filteredHistory.length})`, icon: History },
        ].map(tab => {
          const Icon = tab.icon;
          return (
            <button key={tab.id} onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-sm transition-all ${
                activeTab === tab.id
                  ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/40'
                  : 'bg-slate-800/50 text-slate-400 border border-slate-700/50 hover:text-white'
              }`}>
              <Icon size={15} /> {tab.label}
            </button>
          );
        })}
      </div>

      {/* ── Submit Tab ─────────────────────────────────────────────────────── */}
      {activeTab === 'submit' && (
        <div className="glass-card rounded-2xl border border-slate-700/50 p-6 space-y-5">
          <h2 className="text-lg font-bold text-white flex items-center gap-2">
            <ShoppingCart size={18} className="text-emerald-400" /> Submit Purchase
          </h2>

          {/* Alerts */}
          {submitSuccess && (
            <div className="flex items-center gap-3 p-4 bg-green-500/10 border border-green-500/30 rounded-xl text-green-400 text-sm font-medium">
              <Check size={18} /> {submitSuccess}
            </div>
          )}
          {submitError && (
            <div className="flex items-center gap-3 p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 text-sm font-medium">
              <AlertCircle size={18} /> {submitError}
            </div>
          )}

          {/* Building / Apartment */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                <Building2 size={12} className="inline me-1" /> Building *
              </label>
              {isLoading ? (
                <div className="h-12 bg-slate-800/70 rounded-xl animate-pulse border border-slate-700" />
              ) : (
                <SearchableSelect
                  value={selectedBuilding}
                  onChange={(val) => { setSelectedBuilding(val); setSelectedApartment(''); }}
                  options={buildings.map(b => ({ value: b.id, label: b.name }))}
                  placeholder="— Select Building —"
                />
              )}
              {!isLoading && buildings.length === 0 && (
                <p className="text-red-400 text-xs mt-1">⚠ No buildings found. Check API connection.</p>
              )}
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                <Home size={12} className="inline me-1" /> Apartment *
              </label>
              <SearchableSelect
                value={selectedApartment}
                onChange={(val) => setSelectedApartment(val)}
                options={filteredApartments.map(a => ({ value: a.id, label: `Apt ${a.code}` }))}
                placeholder="— Select Apartment —"
                disabled={!selectedBuilding || filteredApartments.length === 0}
              />
              {selectedBuilding && filteredApartments.length === 0 && !isLoading && (
                <p className="text-yellow-400 text-xs mt-1">No apartments found for this building.</p>
              )}
            </div>
          </div>

          {/* Amount + Supplier */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                <DollarSign size={12} className="inline me-1" /> Amount Spent *
              </label>
              <input
                type="number" step="0.01" min="0"
                value={form.amount}
                onChange={e => setForm(p => ({ ...p, amount: e.target.value }))}
                placeholder="0.00"
                className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-emerald-500/50 focus:outline-none transition-all placeholder-slate-600"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                <Package size={12} className="inline me-1" /> Supplier / Store Name
              </label>
              <input
                type="text"
                value={form.supplier_name}
                onChange={e => setForm(p => ({ ...p, supplier_name: e.target.value }))}
                placeholder="e.g. ACE Hardware, Local Market…"
                className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-emerald-500/50 focus:outline-none transition-all placeholder-slate-600"
              />
            </div>
          </div>

          {/* Date + Notes */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                <Calendar size={12} className="inline me-1" /> Purchase Date *
              </label>
              <input
                type="date"
                value={form.date}
                onChange={e => setForm(p => ({ ...p, date: e.target.value }))}
                className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-emerald-500/50 focus:outline-none transition-all"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
                Notes / Items Purchased
              </label>
              <input
                type="text"
                value={form.notes}
                onChange={e => setForm(p => ({ ...p, notes: e.target.value }))}
                placeholder="e.g. Light bulbs, pipe fittings, paint…"
                className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 focus:ring-2 focus:ring-emerald-500/50 focus:outline-none transition-all placeholder-slate-600"
              />
            </div>
          </div>

          {/* Receipt Upload */}
          <div>
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
              <Camera size={12} className="inline me-1" /> Receipt Photo / Image *
            </label>
            <input ref={fileRef} type="file" accept="image/*,.pdf" className="hidden" onChange={handleFile} />

            {receiptPreview ? (
              <div className="flex items-start gap-4">
                <div className="relative">
                  <img src={receiptPreview} alt="Receipt preview"
                    className="w-36 h-36 object-cover rounded-xl border-2 border-emerald-500/50 shadow-lg shadow-emerald-500/10" />
                  <button
                    onClick={() => { setReceiptFile(null); setReceiptPreview(null); fileRef.current.value = ''; }}
                    className="absolute -top-2 -right-2 w-7 h-7 bg-red-500 text-white rounded-full flex items-center justify-center shadow-lg hover:bg-red-600 transition-colors">
                    <X size={14} />
                  </button>
                </div>
                <div className="flex flex-col justify-center gap-2">
                  <p className="text-green-400 text-sm font-semibold flex items-center gap-1"><Check size={14} /> Image ready</p>
                  <p className="text-slate-500 text-xs">{receiptFile?.name}</p>
                  <button onClick={() => fileRef.current.click()}
                    className="text-xs text-slate-400 hover:text-white transition-colors underline">
                    Change image
                  </button>
                </div>
              </div>
            ) : (
              <button onClick={() => fileRef.current.click()}
                className="w-full border-2 border-dashed border-slate-600 rounded-xl p-8 flex flex-col items-center gap-3 hover:border-emerald-500/60 hover:bg-emerald-500/5 transition-all group">
                <div className="w-14 h-14 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center group-hover:bg-emerald-500/10 group-hover:border-emerald-500/30 transition-all">
                  <Upload size={22} className="text-slate-500 group-hover:text-emerald-400 transition-colors" />
                </div>
                <div className="text-center">
                  <p className="text-white font-semibold text-sm group-hover:text-emerald-400 transition-colors">Upload Receipt</p>
                  <p className="text-slate-500 text-xs mt-0.5">JPG, PNG, WebP or PDF — required for verification</p>
                </div>
              </button>
            )}
          </div>

          {/* Submit */}
          <button
            onClick={() => { setSubmitError(''); submitMutation.mutate(); }}
            disabled={submitMutation.isPending || !selectedApartment || !form.amount || !receiptFile}
            className="w-full py-4 bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold rounded-xl hover:from-emerald-500 hover:to-teal-500 disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-lg shadow-emerald-500/20 active:scale-[0.99] flex items-center justify-center gap-2 text-base">
            {submitMutation.isPending ? (
              <><div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> Submitting…</>
            ) : (
              <><ShoppingCart size={20} /> Submit for Admin Review</>
            )}
          </button>
          <p className="text-xs text-slate-500 text-center">
            Admin will review your purchase before it is recorded in the apartment cost report.
          </p>
        </div>
      )}

      {/* ── History Tab ────────────────────────────────────────────────────── */}
      {activeTab === 'history' && (
        <div className="space-y-4">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-white flex items-center gap-2">
              <History size={18} className="text-emerald-400" /> Submitted Purchases
            </h2>
            <div className="flex items-center gap-2">
              <label className="text-slate-400 text-xs font-bold uppercase">Filter Date:</label>
              <input 
                type="date"
                value={dateFilter}
                onChange={e => setDateFilter(e.target.value)}
                className="bg-slate-800/70 border border-slate-700 text-white rounded-lg px-3 py-1.5 text-sm focus:ring-2 focus:ring-emerald-500/50 focus:outline-none transition-all"
              />
              {dateFilter && (
                <button onClick={() => setDateFilter('')} className="text-slate-400 hover:text-white" title="Clear filter">
                  <X size={14} />
                </button>
              )}
            </div>
          </div>

          {hLoading ? (
            <div className="glass-card rounded-2xl p-12 text-center text-slate-400">
              <div className="w-10 h-10 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
              Loading history…
            </div>
          ) : filteredHistory.length === 0 ? (
            <div className="glass-card rounded-2xl p-16 text-center">
              <History size={48} className="mx-auto text-slate-700 mb-4" />
              <p className="text-slate-400 text-lg font-medium">No purchases found</p>
              {dateFilter ? (
                <p className="text-slate-600 text-sm mt-1">Try selecting a different date.</p>
              ) : (
                <>
                  <p className="text-slate-600 text-sm mt-1">Use the "New Purchase" tab to submit your first one.</p>
                  <button onClick={() => setActiveTab('submit')}
                    className="mt-5 px-5 py-2.5 bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 rounded-xl text-sm font-semibold hover:bg-emerald-500/30 transition-colors">
                    Submit a Purchase
                  </button>
                </>
              )}
            </div>
          ) : (
            filteredHistory.map(item => (
              <div key={item.id}
                className={`glass-card rounded-2xl border p-5 transition-all ${
                  item.status === 'Rejected' ? 'border-red-500/30 hover:border-red-500/50' :
                  item.status === 'Pending'  ? 'border-yellow-500/30 hover:border-yellow-500/50' :
                                               'border-slate-700/50 hover:border-slate-600/50'
                }`}>
                <div className="flex items-start justify-between gap-4">
                  <div className="flex-1 min-w-0">
                    <div className="flex flex-wrap items-center gap-2 mb-3">
                      <StatusBadge status={item.status} />
                      <span className="text-slate-500 text-xs">
                        {item.date ? new Date(item.date + 'T00:00:00').toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'}
                      </span>
                    </div>
                    <div className="flex flex-wrap items-center gap-2 mb-1">
                      <Building2 size={14} className="text-primary shrink-0" />
                      <span className="text-white font-semibold text-sm">{item.building_name}</span>
                      <span className="text-slate-500">·</span>
                      <Home size={14} className="text-indigo-400 shrink-0" />
                      <span className="text-slate-300 text-sm">Apt {item.apartment_code}</span>
                    </div>
                    {item.supplier_name && (
                      <p className="text-slate-400 text-xs mt-1 flex items-center gap-1">
                        <Package size={11} /> {item.supplier_name}
                      </p>
                    )}
                    {item.notes && (
                      <p className="text-slate-500 text-xs mt-1 italic">{item.notes}</p>
                    )}
                    {item.status === 'Rejected' && item.rejection_reason && (
                      <div className="mt-3 p-3 bg-red-500/10 border border-red-500/20 rounded-xl">
                        <p className="text-red-400 text-xs font-semibold flex items-center gap-1 mb-1">
                          <AlertCircle size={11} /> Rejection Reason:
                        </p>
                        <p className="text-red-300 text-xs">{item.rejection_reason}</p>
                        <button
                          onClick={() => {
                            setSelectedBuilding('');
                            setSelectedApartment(String(item.apartment_id));
                            setForm({ supplier_name: item.supplier_name || '', amount: item.amount || '', date: item.date || new Date().toISOString().slice(0,10), notes: item.notes || '' });
                            setActiveTab('submit');
                          }}
                          className="mt-2 text-xs text-yellow-400 hover:text-yellow-300 font-semibold flex items-center gap-1 transition-colors">
                          <RefreshCw size={11} /> Resubmit
                        </button>
                      </div>
                    )}
                  </div>
                  <div className="shrink-0 flex flex-col items-end gap-3">
                    <p className="text-2xl font-extrabold text-white">
                      ${parseFloat(item.amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                    </p>
                    {item.receipt_image && <ReceiptPreview src={item.receipt_image} />}
                    {item.reviewer_name && (
                      <p className="text-xs text-slate-500">by {item.reviewer_name}</p>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}
    </div>
  );
};

export default AgentApartmentCosts;
