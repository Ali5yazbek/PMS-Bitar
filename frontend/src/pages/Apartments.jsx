import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { 
  Home, 
  Plus, 
  Trash2, 
  Edit2, 
  ArrowLeft, 
  Search, 
  Zap, 
  X, 
  Building as BuildingIcon, 
  Check, 
  Sparkles, 
  DollarSign, 
  Shield, 
  AlertCircle,
  ArrowLeftRight
} from 'lucide-react';
import InteractiveCurrency from '../components/common/InteractiveCurrency';

const Apartments = () => {
  const { t } = useTranslation();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building') || searchParams.get('buildingId');
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  
  const [showAdd, setShowAdd] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({ 
    code: '', 
    monthly_rent: '', 
    monthly_insurance: '', 
    status: 'Vacant', 
    building_id: buildingId || '' 
  });
  const [rentUSD, setRentUSD] = useState('');
  const [insuranceUSD, setInsuranceUSD] = useState('');
  const [formError, setFormError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  const { data: buildings } = useQuery({ 
    queryKey: ['buildings'], 
    queryFn: async () => (await api.get('/buildings')).data 
  });

  const { data: settings } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => (await api.get('/global-settings')).data 
  });
  const exchangeRate = settings?.usd_to_cfa ? Number(settings.usd_to_cfa) : 600;
  
  const { data: apartments, isLoading } = useQuery({
    queryKey: ['apartments', buildingId],
    queryFn: async () => {
      const url = buildingId ? `/apartments?building_id=${buildingId}` : '/apartments';
      const res = await api.get(url);
      return res.data;
    }
  });

  const handleCloseModal = () => {
    setShowAdd(false);
    setEditingId(null);
    setFormError('');
    setFormData({ 
      code: '', 
      monthly_rent: '', 
      monthly_insurance: '', 
      status: 'Vacant', 
      building_id: buildingId || '' 
    });
    setRentUSD('');
    setInsuranceUSD('');
  };

  // Close modal on Escape key press
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && showAdd) {
        handleCloseModal();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showAdd]);

  const openAddModal = () => {
    setEditingId(null);
    setFormError('');
    setFormData({ 
      code: '', 
      monthly_rent: '', 
      monthly_insurance: '', 
      status: 'Vacant', 
      building_id: buildingId || (buildings && buildings.length > 0 ? String(buildings[0].id) : '') 
    });
    setRentUSD('');
    setInsuranceUSD('');
    setShowAdd(true);
  };

  const safeRate = exchangeRate > 0 ? exchangeRate : 600;

  // Real-time Conversion Helpers
  const cfaToUsd = (cfaVal) => {
    if (cfaVal === '' || cfaVal == null) return '';
    const num = parseFloat(cfaVal);
    if (isNaN(num)) return '';
    const usd = num / safeRate;
    return Number.isInteger(usd) ? usd.toString() : usd.toFixed(2);
  };

  const usdToCfa = (usdVal) => {
    if (usdVal === '' || usdVal == null) return '';
    const num = parseFloat(usdVal);
    if (isNaN(num)) return '';
    const cfa = Math.round(num * safeRate);
    return cfa.toString();
  };

  // Re-synchronize USD when exchange rate changes from server
  useEffect(() => {
    if (formData.monthly_rent !== '') {
      setRentUSD(cfaToUsd(formData.monthly_rent));
    }
    if (formData.monthly_insurance !== '') {
      setInsuranceUSD(cfaToUsd(formData.monthly_insurance));
    }
  }, [exchangeRate]);

  const openEditModal = (apt) => {
    setEditingId(apt.id);
    setFormError('');
    const rentVal = apt.monthly_rent != null ? String(apt.monthly_rent) : '';
    const insVal = apt.monthly_insurance != null ? String(apt.monthly_insurance) : '';
    setFormData({ 
      code: apt.code || '', 
      monthly_rent: rentVal, 
      monthly_insurance: insVal, 
      status: apt.status || 'Vacant', 
      building_id: apt.building_id || buildingId || '' 
    });
    setRentUSD(cfaToUsd(rentVal));
    setInsuranceUSD(cfaToUsd(insVal));
    setShowAdd(true);
  };

  const addMutation = useMutation({
    mutationFn: (data) => api.post('/apartments', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['apartments']);
      handleCloseModal();
    },
    onError: (err) => {
      setFormError(err.response?.data?.error || err.message || 'Failed to create apartment');
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => api.put(`/apartments/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['apartments']);
      handleCloseModal();
    },
    onError: (err) => {
      setFormError(err.response?.data?.error || err.message || 'Failed to update apartment');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/apartments/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['apartments'])
  });

  // Dual Currency Handlers - 100% Connected in Real-Time
  const handleRentUSDChange = (e) => {
    const val = e.target.value;
    setRentUSD(val);
    setFormData(prev => ({ ...prev, monthly_rent: usdToCfa(val) }));
  };

  const handleRentCFAChange = (e) => {
    const val = e.target.value;
    setFormData(prev => ({ ...prev, monthly_rent: val }));
    setRentUSD(cfaToUsd(val));
  };

  const handleInsuranceUSDChange = (e) => {
    const val = e.target.value;
    setInsuranceUSD(val);
    setFormData(prev => ({ ...prev, monthly_insurance: usdToCfa(val) }));
  };

  const handleInsuranceCFAChange = (e) => {
    const val = e.target.value;
    setFormData(prev => ({ ...prev, monthly_insurance: val }));
    setInsuranceUSD(cfaToUsd(val));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setFormError('');

    const targetBuildingId = formData.building_id || buildingId;
    if (!targetBuildingId) {
      setFormError(t('apartments.error_building', { defaultValue: 'Please select a building' }));
      return;
    }

    if (!formData.code.trim()) {
      setFormError(t('apartments.error_code', { defaultValue: 'Please enter an apartment code/number' }));
      return;
    }

    if (!formData.monthly_rent || parseFloat(formData.monthly_rent) < 0) {
      setFormError(t('apartments.error_rent', { defaultValue: 'Please enter a valid monthly rent' }));
      return;
    }

    const payload = {
      ...formData,
      building_id: targetBuildingId,
      monthly_insurance: formData.monthly_insurance === '' ? '0' : formData.monthly_insurance
    };

    if (editingId) {
      updateMutation.mutate({ id: editingId, data: payload });
    } else {
      addMutation.mutate(payload);
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'Vacant': return 'bg-slate-800 border border-slate-600 text-slate-300';
      case 'Rented': return 'bg-success/20 border border-success/30 text-success';
      case 'Maintenance': return 'bg-warning/20 border border-warning/30 text-warning';
      default: return 'bg-slate-800 text-slate-300';
    }
  };

  const currentBuildingName = buildings?.find(b => String(b.id) === String(buildingId || formData.building_id))?.name;

  if (isLoading) return <div className="p-8 text-muted">Loading apartments...</div>;

  const displayedApartments = apartments?.filter(apt => {
    const matchesSearch = apt.code.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || apt.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const rentNum = parseFloat(formData.monthly_rent) || 0;
  const insuranceNum = parseFloat(formData.monthly_insurance) || 0;
  const totalCFA = rentNum + insuranceNum;
  const totalUSD = exchangeRate > 0 ? (totalCFA / exchangeRate).toFixed(2) : '0.00';
  const isSaving = addMutation.isPending || updateMutation.isPending;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        
        {buildingId && (
          <button 
            onClick={() => navigate(`/buildings/${buildingId}`)}
            className="flex items-center gap-2 text-indigo-400 hover:text-white transition-colors font-medium mb-6"
          >
            <ArrowLeft size={20} className={document.documentElement.dir === 'rtl' ? 'rotate-180' : ''} />
            {t('apartments.back')}
          </button>
        )}

        {/* Page Top Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Home className="me-3 text-primary" size={32} />
              {buildingId && buildings ? t('apartments.building_title', { building: buildings.find(b => String(b.id) === String(buildingId))?.name }) : t('apartments.all_title')}
            </h1>
            <p className="text-muted mt-2">{t('apartments.subtitle')}</p>
          </div>
          
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input 
                type="text" 
                placeholder={t('apartments.search')} 
                className="w-48 sm:w-64 pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-primary text-sm transition-all"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <select 
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-slate-800 border border-slate-700 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-primary text-sm transition-all"
            >
              <option value="All">{t('apartments.status_all')}</option>
              <option value="Vacant">{t('apartments.status_vacant')}</option>
              <option value="Rented">{t('apartments.status_rented')}</option>
              <option value="Maintenance">{t('apartments.status_maintenance')}</option>
            </select>
            <button 
              onClick={openAddModal}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-all shadow-lg shadow-primary/25 hover:shadow-primary/40 font-medium text-sm"
            >
              <Plus size={18} />
              <span>{t('apartments.add_btn')}</span>
            </button>
          </div>
        </div>

        {/* Modal Popup Window for Add / Edit */}
        {showAdd && (
          <div 
            className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-200"
            onClick={(e) => {
              if (e.target === e.currentTarget && !isSaving) handleCloseModal();
            }}
          >
            <div className="relative w-full max-w-xl bg-slate-900 border border-slate-700/80 rounded-2xl shadow-2xl shadow-indigo-950/60 flex flex-col overflow-hidden max-h-[92vh] backdrop-blur-xl animate-in zoom-in-95 duration-200">
              
              {/* Glowing Top Gradient Bar */}
              <div className="h-1.5 w-full bg-gradient-to-r from-indigo-500 via-primary to-emerald-400 shrink-0" />

              {/* Modal Header */}
              <div className="p-5 sm:p-6 border-b border-slate-800 bg-slate-900/90 flex items-center justify-between shrink-0">
                <div className="flex items-center gap-3.5">
                  <div className="p-3 rounded-xl bg-gradient-to-br from-indigo-500/20 to-primary/20 border border-primary/30 text-indigo-400 shadow-lg shadow-indigo-950/50">
                    <Home size={22} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h2 className="text-xl font-bold text-white tracking-tight">
                        {editingId ? t('apartments.edit_title') : t('apartments.add_title')}
                      </h2>
                      {editingId && formData.code && (
                        <span className="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                          {formData.code}
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-slate-400 mt-0.5">
                      {currentBuildingName 
                        ? `${currentBuildingName} • ${t('apartments.modal_subtitle')}`
                        : t('apartments.modal_subtitle')
                      }
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={handleCloseModal}
                  disabled={isSaving}
                  className="w-9 h-9 rounded-xl bg-slate-800/80 hover:bg-slate-700 text-slate-400 hover:text-white flex items-center justify-center transition-colors border border-slate-700/50 disabled:opacity-50"
                  title="Close (Esc)"
                >
                  <X size={18} />
                </button>
              </div>

              {/* Modal Scrollable Body */}
              <form onSubmit={handleSubmit} className="flex flex-col flex-1 overflow-hidden">
                <div className="p-5 sm:p-6 overflow-y-auto hide-scrollbar space-y-4 flex-1">
                  
                  {/* Error Notification */}
                  {formError && (
                    <div className="p-3.5 rounded-xl bg-danger/10 border border-danger/30 text-danger text-sm flex items-center gap-2.5 animate-in fade-in">
                      <AlertCircle size={18} className="shrink-0" />
                      <span>{formError}</span>
                    </div>
                  )}

                  {/* Building Selection / Identification */}
                  {buildingId ? (
                    <div className="p-3.5 rounded-xl bg-slate-800/50 border border-slate-700/60 flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        <div className="p-2 rounded-lg bg-primary/10 text-primary">
                          <BuildingIcon size={18} />
                        </div>
                        <div>
                          <span className="text-xs text-slate-400 block">{t('apartments.building_label')}</span>
                          <span className="text-sm font-semibold text-white">
                            {currentBuildingName || `Building #${buildingId}`}
                          </span>
                        </div>
                      </div>
                      <span className="text-xs px-2.5 py-1 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20 font-medium">
                        Active Target
                      </span>
                    </div>
                  ) : (
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                        <BuildingIcon size={14} className="text-primary" />
                        {t('apartments.building_label')} <span className="text-danger">*</span>
                      </label>
                      <select 
                        required
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all text-sm font-medium"
                        value={formData.building_id} 
                        onChange={e => setFormData({...formData, building_id: e.target.value})}
                      >
                        <option value="">{t('apartments.select_building')}</option>
                        {buildings?.map(b => (
                          <option key={b.id} value={b.id}>{b.name}</option>
                        ))}
                      </select>
                    </div>
                  )}

                  {/* Code & Status (2 Columns) */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    {/* Apartment Code */}
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                        {t('apartments.code_label')} <span className="text-danger">*</span>
                      </label>
                      <input 
                        type="text" 
                        required
                        autoFocus
                        placeholder={t('apartments.code_placeholder')}
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white placeholder-slate-500 outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all text-sm font-medium"
                        value={formData.code} 
                        onChange={e => setFormData({...formData, code: e.target.value})} 
                      />
                    </div>

                    {/* Status */}
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5">
                        {t('apartments.col_status')}
                      </label>
                      <select
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-3.5 py-2.5 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all text-sm font-medium"
                        value={formData.status}
                        onChange={e => setFormData({...formData, status: e.target.value})}
                      >
                        <option value="Vacant">{t('apartments.status_vacant')}</option>
                        <option value="Rented">{t('apartments.status_rented')}</option>
                        <option value="Maintenance">{t('apartments.status_maintenance')}</option>
                      </select>
                    </div>
                  </div>

                  {/* Monthly Rent Card with Dual Currency Synchronizer */}
                  <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/60 space-y-3">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                        <DollarSign size={14} className="text-emerald-400" />
                        <span>{t('apartments.rent_label')}</span>
                        <span className="text-danger">*</span>
                      </label>
                      <div className="flex items-center gap-1.5 text-[11px] font-medium px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                        <ArrowLeftRight size={12} className="text-primary" />
                        <span>1 USD = {safeRate.toLocaleString()} CFA</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      {/* USD Input */}
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
                            value={rentUSD}
                            onChange={handleRentUSDChange}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-8 pr-3 py-2 text-white placeholder-slate-600 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-sm font-medium"
                          />
                        </div>
                      </div>

                      {/* CFA Input (Primary) */}
                      <div>
                        <span className="text-[11px] text-slate-400 mb-1 block">In CFA (Primary)</span>
                        <div className="relative">
                          <input 
                            type="number" 
                            step="any"
                            required
                            placeholder="0"
                            value={formData.monthly_rent}
                            onChange={handleRentCFAChange}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-3 pr-12 py-2 text-white placeholder-slate-600 outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-semibold"
                          />
                          <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400 text-xs font-bold">
                            CFA
                          </div>
                        </div>
                      </div>
                    </div>
                    <p className="text-[11px] text-slate-400 flex items-center gap-1.5 pt-0.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                      Changing either CFA or USD automatically converts and updates the other.
                    </p>
                  </div>

                  {/* Monthly Insurance Card with Dual Currency Synchronizer */}
                  <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/60 space-y-3">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                        <Shield size={14} className="text-indigo-400" />
                        <span>{t('apartments.insurance_label')}</span>
                      </label>
                      <div className="flex items-center gap-1.5 text-[11px] font-medium px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                        <ArrowLeftRight size={12} className="text-primary" />
                        <span>Connected</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      {/* USD Input */}
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
                            value={insuranceUSD}
                            onChange={handleInsuranceUSDChange}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-8 pr-3 py-2 text-white placeholder-slate-600 outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-sm font-medium"
                          />
                        </div>
                      </div>

                      {/* CFA Input */}
                      <div>
                        <span className="text-[11px] text-slate-400 mb-1 block">In CFA</span>
                        <div className="relative">
                          <input 
                            type="number" 
                            step="any"
                            placeholder="0"
                            value={formData.monthly_insurance}
                            onChange={handleInsuranceCFAChange}
                            className="w-full bg-slate-900 border border-slate-700 rounded-xl pl-3 pr-12 py-2 text-white placeholder-slate-600 outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-semibold"
                          />
                          <div className="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none text-slate-400 text-xs font-bold">
                            CFA
                          </div>
                        </div>
                      </div>
                    </div>
                    <p className="text-[11px] text-slate-400 flex items-center gap-1.5 pt-0.5">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse"></span>
                      Changing either CFA or USD automatically converts and updates the other.
                    </p>
                  </div>

                  {/* Real-time Summary Card */}
                  <div className="p-4 rounded-xl bg-gradient-to-br from-indigo-950/40 via-slate-800/40 to-slate-900 border border-indigo-700/30 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-indigo-500/20 text-indigo-300">
                        <Sparkles size={18} />
                      </div>
                      <div>
                        <span className="text-xs text-slate-400 block font-medium">
                          {t('apartments.total_monthly')}
                        </span>
                        <span className="text-xs text-indigo-300 font-semibold">
                          Rent + Insurance
                        </span>
                      </div>
                    </div>
                    <div className="text-end">
                      <div className="text-lg font-bold text-white tracking-tight">
                        CFA {totalCFA.toLocaleString()}
                      </div>
                      <div className="text-xs text-slate-400">
                        ≈ ${totalUSD} USD
                      </div>
                    </div>
                  </div>

                </div>

                {/* Modal Action Footer */}
                <div className="p-4 sm:p-5 border-t border-slate-800 bg-slate-900/95 flex justify-end gap-3 shrink-0">
                  <button 
                    type="button" 
                    onClick={handleCloseModal}
                    disabled={isSaving}
                    className="px-5 py-2.5 rounded-xl text-slate-300 hover:text-white hover:bg-slate-800 transition-colors border border-slate-700/60 font-medium text-sm disabled:opacity-50"
                  >
                    {t('apartments.cancel')}
                  </button>
                  <button 
                    type="submit" 
                    disabled={isSaving || !formData.code.trim() || !formData.monthly_rent || (!buildingId && !formData.building_id)}
                    className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-primary to-indigo-600 hover:from-indigo-500 hover:to-primary text-white font-semibold text-sm shadow-lg shadow-primary/25 disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center gap-2"
                  >
                    {isSaving ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        <span>Saving...</span>
                      </>
                    ) : (
                      <>
                        <Check size={16} />
                        <span>{editingId ? t('apartments.update_btn') : t('apartments.save')}</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Apartments Table */}
        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('apartments.col_apartment')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Tenant</th>
                {!buildingId && <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('apartments.col_building')}</th>}
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('apartments.col_rent')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('apartments.col_insurance')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('apartments.col_status')}</th>
                <th className="px-6 py-4 text-end text-xs font-semibold text-muted uppercase tracking-wider">{t('apartments.col_actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {displayedApartments?.map(apt => (
                <tr key={apt.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4 font-medium text-white flex items-center gap-3">
                    <div className="bg-slate-800 p-2 rounded-lg text-indigo-400">
                      <Home size={16} />
                    </div>
                    {apt.code}
                  </td>
                  <td className="px-6 py-4 text-sm font-medium text-slate-300">
                    {apt.tenant_name || '-'}
                  </td>
                  {!buildingId && <td className="px-6 py-4 text-sm text-slate-300">{apt.building_name}</td>}
                  <td className="px-6 py-4 text-sm font-medium text-white"><InteractiveCurrency amountCFA={apt.monthly_rent} /></td>
                  <td className="px-6 py-4 text-sm font-medium text-slate-300"><InteractiveCurrency amountCFA={apt.monthly_insurance} /></td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${getStatusColor(apt.status)}`}>
                      {t(`apartments.status_${apt.status.toLowerCase()}`)}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-end text-sm">
                    <div className="flex justify-end gap-2">
                      <button 
                        onClick={() => navigate(`/apartments/${apt.id}/electricity`)}
                        className="text-slate-400 hover:text-warning p-2 transition-colors rounded-lg hover:bg-slate-800"
                        title="Electricity Management"
                      >
                        <Zap size={18} />
                      </button>
                      <button 
                        onClick={() => openEditModal(apt)}
                        className="text-slate-400 hover:text-indigo-400 p-2 transition-colors rounded-lg hover:bg-slate-800"
                        title="Edit Apartment"
                      >
                        <Edit2 size={18} />
                      </button>
                      <button 
                        onClick={() => { if(window.confirm(t('apartments.delete_confirm'))) deleteMutation.mutate(apt.id); }} 
                        className="text-slate-400 hover:text-danger p-2 transition-colors rounded-lg hover:bg-slate-800"
                        title="Delete Apartment"
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {displayedApartments?.length === 0 && (
            <div className="p-8 text-center text-muted">
              {apartments?.length === 0 ? t('apartments.no_data') : 'No matching apartments found.'}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Apartments;
