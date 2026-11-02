import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { 
  Users, 
  Plus, 
  Trash2, 
  Eye, 
  ArrowLeft, 
  Search, 
  Filter, 
  Upload, 
  AlertCircle, 
  RefreshCw, 
  Home, 
  X, 
  FileText, 
  Check, 
  Calendar, 
  DollarSign, 
  Shield, 
  Sparkles, 
  ArrowLeftRight 
} from 'lucide-react';
import InteractiveCurrency from '../components/common/InteractiveCurrency';

const Tenants = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building') || searchParams.get('buildingId');

  const [showAdd, setShowAdd] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [renewModal, setRenewModal] = useState(null);
  const [tenantSearch, setTenantSearch] = useState('');
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [formError, setFormError] = useState('');

  const [formData, setFormData] = useState({
    user_id: '',
    apartment_id: '',
    start_date: new Date().toISOString().split('T')[0],
    end_date: (() => {
      const d = new Date();
      d.setFullYear(d.getFullYear() + 1);
      return d.toISOString().split('T')[0];
    })(),
    monthly_rent: '',
    monthly_insurance: '',
    contract_file: null
  });

  const [rentUSD, setRentUSD] = useState('');
  const [insuranceUSD, setInsuranceUSD] = useState('');

  const { data: tenants, isLoading } = useQuery({ 
    queryKey: ['tenants'], 
    queryFn: async () => (await api.get('/tenants')).data 
  });
  const { data: buildings } = useQuery({ 
    queryKey: ['buildings'], 
    queryFn: async () => (await api.get('/buildings')).data 
  });
  const { data: users } = useQuery({ 
    queryKey: ['users'], 
    queryFn: async () => (await api.get('/users')).data 
  });
  const { data: settings } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => (await api.get('/global-settings')).data 
  });

  const exchangeRate = settings?.usd_to_cfa ? Number(settings.usd_to_cfa) : 600;
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

  // Close modal on Escape
  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && showAdd) {
        handleCloseModal();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showAdd]);

  // Only users who are tenants
  const tenantUsers = users?.filter(u => u.role === 'tenant') || [];

  // Fetch vacant apartments for the dropdown
  const { data: vacantApartments } = useQuery({
    queryKey: ['apartments', 'vacant', buildingId],
    queryFn: async () => {
      const res = await api.get('/apartments');
      let apts = res.data.filter(a => a.status === 'Vacant');
      if (buildingId) {
        apts = apts.filter(a => String(a.building_id) === String(buildingId));
      }
      return apts;
    }
  });

  const selectedUser = tenantUsers?.find(u => String(u.id) === String(formData.user_id));
  const selectedApt = vacantApartments?.find(a => String(a.id) === String(formData.apartment_id));

  const handleCloseModal = () => {
    setShowAdd(false);
    setFormError('');
    setFormData({ 
      user_id: '', 
      apartment_id: '', 
      start_date: new Date().toISOString().split('T')[0], 
      end_date: (() => {
        const d = new Date();
        d.setFullYear(d.getFullYear() + 1);
        return d.toISOString().split('T')[0];
      })(), 
      monthly_rent: '', 
      monthly_insurance: '', 
      contract_file: null 
    });
    setTenantSearch('');
    setRentUSD('');
    setInsuranceUSD('');
    setIsDropdownOpen(false);
  };

  const openAddModal = () => {
    setFormError('');
    setShowAdd(true);
  };

  const addMutation = useMutation({
    mutationFn: async (data) => {
      const form = new FormData();
      Object.keys(data).forEach(key => {
        if (data[key] !== null && data[key] !== undefined && data[key] !== '') {
          form.append(key, data[key]);
        }
      });
      return api.post('/tenants', form, {
        headers: {
          'Content-Type': 'multipart/form-data'
        }
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['tenants']);
      queryClient.invalidateQueries(['apartments']);
      handleCloseModal();
    },
    onError: (err) => {
      setFormError(err.response?.data?.error || err.message || 'Failed to register tenant contract');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/tenants/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['tenants'])
  });

  const renewMutation = useMutation({
    mutationFn: ({ contractId, data }) => api.post(`/contracts/${contractId}/renew`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenants']);
      queryClient.invalidateQueries(['dashboardStats']);
      queryClient.invalidateQueries(['expiringItems']);
      setRenewModal(null);
      alert('Contract renewed successfully');
    }
  });

  const handleOpenRenew = (tenant) => {
    const startDate = tenant.end_date;
    const endDate = new Date(startDate);
    endDate.setFullYear(endDate.getFullYear() + 1);

    setRenewModal({
      contractId: tenant.contract_id,
      start_date: startDate,
      end_date: endDate.toISOString().split('T')[0]
    });
  };

  const handleApartmentChange = (e) => {
    const aptId = e.target.value;
    const apt = vacantApartments?.find(a => String(a.id) === String(aptId));
    const defaultRent = apt && apt.monthly_rent != null ? String(apt.monthly_rent) : '';
    const defaultInsurance = apt && apt.monthly_insurance != null ? String(apt.monthly_insurance) : '';
    setFormData(prev => ({
      ...prev,
      apartment_id: aptId,
      monthly_rent: defaultRent,
      monthly_insurance: defaultInsurance
    }));
    setRentUSD(cfaToUsd(defaultRent));
    setInsuranceUSD(cfaToUsd(defaultInsurance));
  };

  // Connected Currency Handlers
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

    if (!formData.user_id) {
      setFormError(t('tenants.error_user', { defaultValue: 'Please select a registered tenant user' }));
      return;
    }
    if (!formData.apartment_id) {
      setFormError(t('tenants.error_apt', { defaultValue: 'Please select an apartment' }));
      return;
    }
    if (!formData.start_date) {
      setFormError(t('tenants.error_start_date', { defaultValue: 'Please specify contract start date' }));
      return;
    }
    if (!formData.end_date) {
      setFormError(t('tenants.error_end_date', { defaultValue: 'Please specify contract end date' }));
      return;
    }

    addMutation.mutate(formData);
  };

  if (isLoading) return <div className="p-8 text-muted">{t('Loading tenants...')}</div>;

  const isExpiringSoon = (endDate) => {
    if (!endDate) return false;
    const end = new Date(endDate);
    const today = new Date();
    const diffTime = end - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays >= 0 && diffDays <= 10;
  };

  const getRentCycleStart = (nextBillingDate, frequency) => {
    if (!nextBillingDate) return 'N/A';
    const parts = nextBillingDate.split('-').map(Number);
    if (parts.length !== 3) return 'N/A';
    const date = new Date(parts[0], parts[1] - 1, parts[2]);
    if (frequency === 'Yearly') date.setFullYear(date.getFullYear() - 1);
    else if (frequency === 'Quarterly') date.setMonth(date.getMonth() - 3);
    else if (frequency === 'Weekly') date.setDate(date.getDate() - 7);
    else date.setMonth(date.getMonth() - 1);
    const pad = (n) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
  };

  const displayedTenants = tenants?.filter(tenant => {
    const isBuildingMatch = buildingId ? String(tenant.building_id) === String(buildingId) : true;
    const matchesSearch = tenant.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tenant.national_id?.includes(searchTerm) ||
      tenant.phone?.includes(searchTerm);
    const isTerminated = tenant.status === 'Terminated';
    const isActive = tenant.status === 'Active' || tenant.contract_status === 'Active' || tenant.contract_status === 'Approved';
    
    let matchesStatus = true;
    if (statusFilter === 'Active') matchesStatus = isActive && !isTerminated;
    else if (statusFilter === 'Inactive') matchesStatus = !isActive && !isTerminated;
    else if (statusFilter === 'Terminated') matchesStatus = isTerminated;

    return isBuildingMatch && matchesSearch && matchesStatus;
  });

  const rentNum = parseFloat(formData.monthly_rent) || 0;
  const insuranceNum = parseFloat(formData.monthly_insurance) || 0;
  const totalCFA = rentNum + insuranceNum;
  const totalUSD = safeRate > 0 ? (totalCFA / safeRate).toFixed(2) : '0.00';
  const isSaving = addMutation.isPending || addMutation.isLoading;

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

        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Users className="me-3 text-primary" size={32} />
              {t('Tenants Directory')}
            </h1>
            <p className="text-muted mt-2">{t('Manage all registered tenants and contracts')}</p>
          </div>
          <button
            onClick={openAddModal}
            className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-all shadow-lg shadow-primary/20 hover:shadow-primary/40 font-medium text-sm"
          >
            <Plus size={20} />
            <span>{t('Add Tenant')}</span>
          </button>
        </div>

        {/* Modal Popup Window for Add Tenant / Assign Contract */}
        {showAdd && (
          <div 
            className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-slate-950/80 backdrop-blur-md animate-in fade-in duration-200"
            onClick={(e) => {
              if (e.target === e.currentTarget && !isSaving) handleCloseModal();
            }}
          >
            <div className="relative w-full max-w-2xl bg-slate-900 border border-slate-700/80 rounded-2xl shadow-2xl shadow-indigo-950/60 flex flex-col overflow-hidden max-h-[92vh] backdrop-blur-xl animate-in zoom-in-95 duration-200">
              
              {/* Glowing Top Gradient Bar */}
              <div className="h-1.5 w-full bg-gradient-to-r from-indigo-500 via-primary to-emerald-400 shrink-0" />

              {/* Modal Header */}
              <div className="p-5 sm:p-6 border-b border-slate-800 bg-slate-900/90 flex items-center justify-between shrink-0">
                <div className="flex items-center gap-3.5">
                  <div className="p-3 rounded-xl bg-gradient-to-br from-indigo-500/20 to-primary/20 border border-primary/30 text-indigo-400 shadow-lg shadow-indigo-950/50">
                    <Users size={22} />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-white tracking-tight">
                      {t('Assign Tenant to Contract')}
                    </h2>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Register a tenant contract, assign an apartment unit, and upload documents
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

              {/* Modal Scrollable Form Body */}
              <form onSubmit={handleSubmit} className="flex flex-col flex-1 overflow-hidden">
                <div className="p-5 sm:p-6 overflow-y-auto hide-scrollbar space-y-5 flex-1">
                  
                  {/* Error Alert */}
                  {formError && (
                    <div className="p-3.5 rounded-xl bg-danger/10 border border-danger/30 text-danger text-sm flex items-center gap-2.5 animate-in fade-in">
                      <AlertCircle size={18} className="shrink-0" />
                      <span>{formError}</span>
                    </div>
                  )}

                  {/* 1. Tenant User Selection */}
                  <div className="space-y-2">
                    <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      <Users size={14} className="text-primary" />
                      {t('Select Registered Tenant User')} <span className="text-danger">*</span>
                    </label>
                    <div className="relative">
                      <input
                        type="text"
                        placeholder="Search by name, ID or phone..."
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white placeholder-slate-500 outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-medium transition-all"
                        value={tenantSearch}
                        onChange={(e) => {
                          setTenantSearch(e.target.value);
                          setIsDropdownOpen(true);
                          if (formData.user_id) setFormData({ ...formData, user_id: '' });
                        }}
                        onFocus={() => setIsDropdownOpen(true)}
                      />
                      {isDropdownOpen && (
                        <div className="absolute z-20 w-full mt-1 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl max-h-56 overflow-y-auto divide-y divide-slate-700/50">
                          {tenantUsers.filter(u =>
                            u.name?.toLowerCase().includes(tenantSearch.toLowerCase()) ||
                            u.national_id?.includes(tenantSearch) ||
                            u.phone?.includes(tenantSearch)
                          ).map(u => (
                            <div
                              key={u.id}
                              className="px-4 py-3 hover:bg-primary/20 cursor-pointer text-white transition-colors"
                              onMouseDown={(e) => {
                                e.preventDefault();
                                setFormData({ ...formData, user_id: u.id });
                                setTenantSearch(`${u.name} (ID: ${u.national_id || 'N/A'}, Phone: ${u.phone || 'N/A'})`);
                                setIsDropdownOpen(false);
                              }}
                            >
                              <div className="font-medium text-white text-sm">{u.name}</div>
                              <div className="text-xs text-slate-400 mt-0.5">
                                ID: {u.national_id || 'N/A'} • Phone: {u.phone || 'N/A'} • {u.email || 'No email'}
                              </div>
                            </div>
                          ))}
                          {tenantUsers.filter(u =>
                            u.name?.toLowerCase().includes(tenantSearch.toLowerCase()) ||
                            u.national_id?.includes(tenantSearch) ||
                            u.phone?.includes(tenantSearch)
                          ).length === 0 && (
                            <div className="px-4 py-3 text-slate-400 text-sm">{t('No tenants found')}</div>
                          )}
                        </div>
                      )}
                    </div>
                    <p className="text-[11px] text-muted">
                      {t("Note: To create a new tenant, go to User Management and create a user with the 'Tenant' role.")}
                    </p>

                    {selectedUser && (
                      <div className="mt-2 bg-slate-800/40 p-3.5 rounded-xl border border-slate-700/60">
                        <h4 className="text-[11px] font-semibold text-indigo-400 mb-2 uppercase tracking-wider flex items-center gap-2">
                          <Check size={14} className="text-emerald-400" /> {t('Selected Tenant Details')}
                        </h4>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Full Name')}</p>
                            <p className="text-white font-medium text-xs truncate">{selectedUser.name}</p>
                          </div>
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('National ID')}</p>
                            <p className="text-slate-300 font-medium text-xs">{selectedUser.national_id || '—'}</p>
                          </div>
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Phone')}</p>
                            <p className="text-slate-300 font-medium text-xs">{selectedUser.phone || '—'}</p>
                          </div>
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Email')}</p>
                            <p className="text-slate-300 font-medium text-xs truncate">{selectedUser.email || '—'}</p>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* 2. Apartment Selection */}
                  <div className="space-y-2">
                    <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      <Home size={14} className="text-primary" />
                      {t('Assign to Apartment')} <span className="text-danger">*</span>
                    </label>
                    <select
                      className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-medium transition-all"
                      value={formData.apartment_id}
                      onChange={handleApartmentChange}
                      required
                    >
                      <option value="">{t('Select Apartment...')}</option>
                      {vacantApartments?.map(a => (
                        <option key={a.id} value={a.id}>
                          {a.building_name} - Unit {a.code} (Default Rent: CFA {Number(a.monthly_rent || 0).toLocaleString()}/mo)
                        </option>
                      ))}
                    </select>

                    {buildingId && vacantApartments?.length === 0 && (
                      <p className="text-xs text-warning">{t('No vacant apartments available in this building.')}</p>
                    )}

                    {selectedApt && (
                      <div className="mt-2 bg-slate-800/40 p-3.5 rounded-xl border border-slate-700/60">
                        <h4 className="text-[11px] font-semibold text-indigo-400 mb-2 uppercase tracking-wider flex items-center gap-2">
                          <Check size={14} className="text-emerald-400" /> {t('Selected Apartment Details')}
                        </h4>
                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-sm">
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Building')}</p>
                            <p className="text-white font-medium text-xs">{selectedApt.building_name}</p>
                          </div>
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Unit Code')}</p>
                            <p className="text-indigo-300 font-bold text-xs">{selectedApt.code}</p>
                          </div>
                          <div>
                            <p className="text-slate-500 text-[10px] uppercase">{t('Default Rent')}</p>
                            <p className="text-emerald-400 font-semibold text-xs">CFA {Number(selectedApt.monthly_rent || 0).toLocaleString()}</p>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* 3. Contract Period Dates (Start Date & End Date) */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                        <Calendar size={14} className="text-primary" />
                        {t('Contract Start Date')} <span className="text-danger">*</span>
                      </label>
                      <input 
                        type="date" 
                        required
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-medium transition-all" 
                        value={formData.start_date} 
                        onChange={e => setFormData({ ...formData, start_date: e.target.value })} 
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-1.5 flex items-center gap-1.5">
                        <Calendar size={14} className="text-primary" />
                        {t('Contract End Date')} <span className="text-danger">*</span>
                      </label>
                      <input 
                        type="date" 
                        required
                        className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-2.5 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary text-sm font-medium transition-all" 
                        value={formData.end_date} 
                        onChange={e => setFormData({ ...formData, end_date: e.target.value })} 
                      />
                    </div>
                  </div>

                  {/* 4. Connected Currency Rates: Monthly Rent */}
                  <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/60 space-y-3">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                        <DollarSign size={14} className="text-emerald-400" />
                        <span>Fixed Monthly Rent</span>
                        <span className="text-danger">*</span>
                      </label>
                      <div className="flex items-center gap-1.5 text-[11px] font-medium px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                        <ArrowLeftRight size={12} className="text-primary" />
                        <span>1 USD = {safeRate.toLocaleString()} CFA</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
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

                      <div>
                        <span className="text-[11px] text-slate-400 mb-1 block">In CFA (Primary)</span>
                        <div className="relative">
                          <input 
                            type="number" 
                            step="any"
                            required
                            placeholder="Override default rent"
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

                  {/* 5. Connected Currency Rates: Monthly Insurance */}
                  <div className="p-4 rounded-xl bg-slate-800/40 border border-slate-700/60 space-y-3">
                    <div className="flex items-center justify-between">
                      <label className="text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                        <Shield size={14} className="text-indigo-400" />
                        <span>Fixed Insurance / Deposit</span>
                      </label>
                      <div className="flex items-center gap-1.5 text-[11px] font-medium px-2.5 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                        <ArrowLeftRight size={12} className="text-primary" />
                        <span>Connected</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
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

                      <div>
                        <span className="text-[11px] text-slate-400 mb-1 block">In CFA</span>
                        <div className="relative">
                          <input 
                            type="number" 
                            step="any"
                            placeholder="Override default insurance"
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
                  </div>

                  {/* Real-time Summary Card */}
                  <div className="p-4 rounded-xl bg-gradient-to-br from-indigo-950/40 via-slate-800/40 to-slate-900 border border-indigo-700/30 flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="p-2 rounded-lg bg-indigo-500/20 text-indigo-300">
                        <Sparkles size={18} />
                      </div>
                      <div>
                        <span className="text-xs text-slate-400 block font-medium">Total Monthly Scheduled</span>
                        <span className="text-xs text-indigo-300 font-semibold">Rent + Insurance</span>
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

                  {/* 6. PROMINENT DOCUMENT ATTACHMENT / UPLOAD */}
                  <div className="space-y-2">
                    <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
                      <FileText size={14} className="text-primary" />
                      <span>Upload Signed Contract (Document)</span>
                    </label>

                    {formData.contract_file ? (
                      <div className="p-4 rounded-xl bg-slate-800/60 border border-indigo-500/40 flex items-center justify-between">
                        <div className="flex items-center gap-3 overflow-hidden">
                          <div className="p-2.5 rounded-lg bg-primary/20 text-indigo-300 shrink-0">
                            <FileText size={22} />
                          </div>
                          <div className="overflow-hidden">
                            <p className="text-sm font-semibold text-white truncate">
                              {formData.contract_file.name}
                            </p>
                            <p className="text-xs text-slate-400 flex items-center gap-2">
                              <span>{(formData.contract_file.size / 1024).toFixed(1)} KB</span>
                              <span className="text-emerald-400 flex items-center gap-1">
                                <Check size={12} /> Ready to upload
                              </span>
                            </p>
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => setFormData({ ...formData, contract_file: null })}
                          className="p-2 text-slate-400 hover:text-danger rounded-lg hover:bg-slate-700/50 transition-colors shrink-0"
                          title="Remove attached document"
                        >
                          <X size={18} />
                        </button>
                      </div>
                    ) : (
                      <div>
                        <input
                          type="file"
                          accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                          onChange={e => setFormData({ ...formData, contract_file: e.target.files[0] })}
                          className="hidden"
                          id="contract-upload-modal"
                        />
                        <label 
                          htmlFor="contract-upload-modal" 
                          className="w-full flex flex-col items-center justify-center gap-2 bg-slate-900/60 border-2 border-dashed border-slate-700 hover:border-primary rounded-xl p-5 text-slate-300 hover:text-white transition-all cursor-pointer group"
                        >
                          <div className="p-2.5 rounded-full bg-slate-800 text-slate-400 group-hover:text-primary group-hover:bg-primary/10 transition-colors">
                            <Upload size={20} />
                          </div>
                          <div className="text-center">
                            <span className="text-sm font-medium text-indigo-300 group-hover:underline">Click to browse</span> or drag signed contract here
                            <p className="text-xs text-slate-500 mt-0.5">Supports PDF, JPG, PNG (Contract Agreement / Lease Document)</p>
                          </div>
                        </label>
                      </div>
                    )}
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
                    {t('Cancel')}
                  </button>
                  <button 
                    type="submit" 
                    disabled={!formData.user_id || !formData.apartment_id || !formData.start_date || !formData.end_date || isSaving}
                    className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-primary to-indigo-600 hover:from-indigo-500 hover:to-primary text-white font-semibold text-sm shadow-lg shadow-primary/25 disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center gap-2"
                  >
                    {isSaving ? (
                      <>
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        <span>Registering...</span>
                      </>
                    ) : (
                      <>
                        <Check size={16} />
                        <span>Register & Notify Tenant</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 glass-card p-4 mb-6">
          <div className="flex-1 flex gap-4 w-full">
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input
                type="text"
                placeholder={t('tenants.search')}
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-primary text-sm"
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="text-muted" size={18} />
              <select
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                className="bg-slate-800 border border-slate-700 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-primary text-sm"
              >
                <option value="All">{t('tenants.filter_all', 'All')}</option>
                <option value="Active">{t('tenants.filter_active', 'Active')}</option>
                <option value="Inactive">{t('tenants.filter_inactive', 'Inactive')}</option>
                <option value="Terminated">{t('Terminated')}</option>
              </select>
            </div>
          </div>
        </div>

        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenants.col_info')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenants.col_id')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenants.col_apt')}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenants.col_status')}</th>
                <th className="px-6 py-4 text-end text-xs font-semibold text-muted uppercase tracking-wider">{t('tenants.col_actions')}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {displayedTenants?.map(tenant => (
                <tr key={tenant.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center">
                      <div className="h-10 w-10 rounded-full bg-primary/20 flex items-center justify-center text-primary font-bold">
                        {tenant.full_name?.charAt(0) || 'T'}
                      </div>
                      <div className="ms-4">
                        <div className="text-sm font-medium text-white">{tenant.full_name}</div>
                        <div className="text-sm text-slate-400">{tenant.phone}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-slate-300">{tenant.national_id || '—'}</div>
                  </td>

                  {/* APARTMENT COLUMN */}
                  <td className="px-6 py-4 whitespace-nowrap">
                    {(tenant.contract_status === 'Active' || tenant.contract_status === 'Approved') ? (
                      <div className="flex flex-col items-start">
                        <div className="text-sm font-medium text-white mb-2">
                          <span className="text-slate-400 mr-1 font-normal">{t('Apt:')}</span>{tenant.building_name} - {tenant.apartment_code}
                        </div>

                        <div className="flex flex-col gap-2">
                          <div className="flex items-center gap-2">
                            <div className="text-xs font-medium text-emerald-300 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20 inline-flex items-center w-fit" title="Contract Dates">
                              Contract: {tenant.start_date} &rarr; {tenant.end_date}
                            </div>
                            {isExpiringSoon(tenant.end_date) && (
                              <span className="text-warning flex items-center gap-1 font-semibold text-xs" title="Expiring within 10 days">
                                <AlertCircle size={12} /> {t('Expiring soon')}
                              </span>
                            )}
                          </div>

                          {tenant.next_billing_date && (
                            <div className="text-xs font-medium text-indigo-300 bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20 inline-flex items-center w-fit" title="Rent Cycle Dates">
                              Rent: {getRentCycleStart(tenant.next_billing_date, tenant.billing_frequency)} &rarr; {tenant.next_billing_date}
                            </div>
                          )}
                        </div>
                      </div>
                    ) : (
                      <span className="text-sm text-slate-500 italic">{t('tenants.no_apt')}</span>
                    )}
                  </td>

                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${tenant.rent_status === 'Ended' ? 'bg-red-500/20 text-red-400' :
                      tenant.rent_status === 'Paused' ? 'bg-warning/20 text-warning border border-warning/30' :
                        (tenant.contract_status === 'Active' || tenant.contract_status === 'Approved') ? 'bg-success/20 text-success' : 'bg-slate-800 text-slate-400'
                      }`}>
                      {tenant.rent_status === 'Ended' ? 'Ended Rent' :
                        tenant.rent_status === 'Paused' ? 'Paused Rent' :
                          (tenant.contract_status || 'Inactive')}
                    </span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-end text-sm font-medium">
                    {tenant.contract_id && (tenant.contract_status === 'Active' || tenant.contract_status === 'Approved') && (
                      <button
                        onClick={() => handleOpenRenew(tenant)}
                        className="text-success hover:text-green-400 bg-success/10 hover:bg-success/20 p-2 rounded-lg transition-colors me-2"
                        title="Renew Contract"
                      >
                        <RefreshCw size={18} />
                      </button>
                    )}
                    <button
                      onClick={() => navigate(`/tenants/${tenant.id}`)}
                      className="text-indigo-400 hover:text-indigo-300 bg-indigo-500/10 hover:bg-indigo-500/20 p-2 rounded-lg transition-colors me-2"
                      title={t('common.view')}
                    >
                      <Eye size={18} />
                    </button>
                    <button
                      onClick={() => {
                        if (window.confirm(t('tenants.confirm_del'))) {
                          deleteMutation.mutate(tenant.id);
                        }
                      }}
                      className="text-danger hover:text-red-400 bg-danger/10 hover:bg-danger/20 p-2 rounded-lg transition-colors"
                      title={t('common.delete')}
                    >
                      <Trash2 size={18} />
                    </button>
                  </td>
                </tr>
              ))}
              {(!displayedTenants || displayedTenants.length === 0) && (
                <tr>
                  <td colSpan="5" className="px-6 py-12 text-center text-muted">
                    {t('No tenants found.')}
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Renew Modal */}
      {renewModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in zoom-in-95">
            <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/30">
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <RefreshCw className="text-success" size={24} />
                {t('Renew Contract')}
              </h3>
              <button onClick={() => setRenewModal(null)} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('New Start Date')}</label>
                <input
                  type="date"
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary"
                  value={renewModal.start_date}
                  onChange={e => setRenewModal({ ...renewModal, start_date: e.target.value })}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('New End Date')}</label>
                <input
                  type="date"
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary"
                  value={renewModal.end_date}
                  onChange={e => setRenewModal({ ...renewModal, end_date: e.target.value })}
                />
              </div>
              <button
                onClick={() => renewMutation.mutate({ contractId: renewModal.contractId, data: renewModal })}
                disabled={renewMutation.isLoading}
                className="w-full bg-success hover:bg-green-600 text-white px-4 py-3 rounded-xl font-bold transition-colors mt-4"
              >
                {renewMutation.isLoading ? 'Renewing...' : 'Confirm Renewal'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default Tenants;