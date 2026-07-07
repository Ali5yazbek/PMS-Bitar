import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Users, Plus, Trash2, Edit2, Eye, ArrowLeft, Search, Filter, Upload, AlertCircle, RefreshCw, Home, X } from 'lucide-react';

const Tenants = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building');
  
  const [showAdd, setShowAdd] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [renewModal, setRenewModal] = useState(null);
  
  const [formData, setFormData] = useState({
    user_id: '',
    apartment_id: '', 
    start_date: '', 
    end_date: '',
    monthly_rent: '',
    monthly_insurance: '',
    contract_file: null
  });

  const { data: tenants, isLoading } = useQuery({ queryKey: ['tenants'], queryFn: async () => (await api.get('/tenants')).data });
  const { data: buildings } = useQuery({ queryKey: ['buildings'], queryFn: async () => (await api.get('/buildings')).data });
  const { data: users } = useQuery({ queryKey: ['users'], queryFn: async () => (await api.get('/users')).data });
  
  // Only users who are tenants
  const tenantUsers = users?.filter(u => u.role === 'tenant') || [];

  // Fetch vacant apartments for the dropdown
  const { data: vacantApartments } = useQuery({ 
    queryKey: ['apartments', 'vacant'], 
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
      setShowAdd(false);
      setFormData({ user_id: '', apartment_id: '', start_date: '', end_date: '', monthly_rent: '', monthly_insurance: '', contract_file: null });
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

  if (isLoading) return <div className="p-8 text-muted">Loading tenants...</div>;

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
    const date = new Date(nextBillingDate);
    if (frequency === 'Yearly') date.setFullYear(date.getFullYear() - 1);
    else if (frequency === 'Quarterly') date.setMonth(date.getMonth() - 3);
    else if (frequency === 'Weekly') date.setDate(date.getDate() - 7);
    else date.setMonth(date.getMonth() - 1); // default Monthly
    return date.toISOString().split('T')[0];
  };

  const displayedTenants = tenants?.filter(tenant => {
    const isBuildingMatch = buildingId ? String(tenant.building_id) === String(buildingId) : true;
    const matchesSearch = tenant.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          tenant.national_id?.includes(searchTerm) ||
                          tenant.phone?.includes(searchTerm);
    const isActive = tenant.contract_status === 'Active' || tenant.contract_status === 'Approved';
    const matchesStatus = statusFilter === 'All' || 
                          (statusFilter === 'Active' ? isActive : !isActive);
    
    return isBuildingMatch && matchesSearch && matchesStatus;
  });

  const handleApartmentChange = (e) => {
    const aptId = e.target.value;
    const apt = vacantApartments?.find(a => String(a.id) === String(aptId));
    setFormData({
      ...formData,
      apartment_id: aptId,
      monthly_rent: apt ? apt.monthly_rent : '',
      monthly_insurance: apt ? apt.monthly_insurance : ''
    });
  };

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
              Tenants Directory
            </h1>
            <p className="text-muted mt-2">Manage all registered tenants and contracts</p>
          </div>
          <button 
            onClick={() => setShowAdd(!showAdd)}
            className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors shadow-lg shadow-primary/20"
          >
            <Plus size={20} />
            <span>Add Tenant</span>
          </button>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4 border-l-4 border-l-primary">
            <h3 className="text-xl font-bold text-white mb-6">Assign Tenant to Contract</h3>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="col-span-1 md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-2">Select Registered Tenant User</label>
                <select 
                  className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                  value={formData.user_id} 
                  onChange={e => setFormData({...formData, user_id: e.target.value})}
                >
                  <option value="">Search and select a tenant user...</option>
                  {tenantUsers.map(u => (
                    <option key={u.id} value={u.id}>{u.name} (ID: {u.national_id || 'N/A'}, Phone: {u.phone || 'N/A'})</option>
                  ))}
                </select>
                <p className="text-xs text-muted mt-2">Note: To create a new tenant, go to User Management and create a user with the 'Tenant' role.</p>
                {selectedUser && (
                  <div className="mt-3 bg-slate-900/50 p-4 rounded-xl border border-slate-700">
                    <h4 className="text-xs font-semibold text-indigo-400 mb-2 uppercase tracking-wider flex items-center gap-2">
                      <Users size={12} /> Selected Tenant Details
                    </h4>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Full Name</p>
                        <p className="text-slate-300 font-medium">{selectedUser.name}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">National ID</p>
                        <p className="text-slate-300 font-medium">{selectedUser.national_id || '—'}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Phone</p>
                        <p className="text-slate-300 font-medium">{selectedUser.phone || '—'}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Email</p>
                        <p className="text-slate-300 font-medium">{selectedUser.email || '—'}</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">Assign to Apartment</label>
                <select 
                  className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                  value={formData.apartment_id} 
                  onChange={handleApartmentChange}
                >
                  <option value="">Select Apartment...</option>
                  {vacantApartments?.map(a => <option key={a.id} value={a.id}>{a.building_name} - {a.code} (Default: CFA {a.monthly_rent}/mo)</option>)}
                </select>
                {buildingId && vacantApartments?.length === 0 && (
                  <p className="text-xs text-warning mt-2">No vacant apartments available in this building.</p>
                )}
                {selectedApt && (
                  <div className="mt-3 bg-slate-900/50 p-4 rounded-xl border border-slate-700">
                    <h4 className="text-xs font-semibold text-indigo-400 mb-2 uppercase tracking-wider flex items-center gap-2">
                      <Home size={12} /> Selected Apartment Details
                    </h4>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Building</p>
                        <p className="text-slate-300 font-medium">{selectedApt.building_name}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Code</p>
                        <p className="text-slate-300 font-medium">{selectedApt.code}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Default Rent</p>
                        <p className="text-green-400 font-medium">CFA {selectedApt.monthly_rent}/mo</p>
                      </div>
                      <div>
                        <p className="text-slate-500 text-[10px] uppercase tracking-wider">Rooms</p>
                        <p className="text-slate-300 font-medium">{selectedApt.rooms || '—'}</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
              
              {formData.apartment_id && (
                <>
                  <div className="col-span-1 md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-2">Contract Start Date</label>
                      <input type="date" className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={formData.start_date} onChange={e => setFormData({...formData, start_date: e.target.value})} />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-2">Contract End Date</label>
                      <input type="date" className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={formData.end_date} onChange={e => setFormData({...formData, end_date: e.target.value})} />
                    </div>
                  </div>

                  <div className="col-span-1 md:col-span-2 grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-2">Fixed Monthly Rent (CFA)</label>
                      <input type="number" className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={formData.monthly_rent} onChange={e => setFormData({...formData, monthly_rent: e.target.value})} placeholder="Override default rent" />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-400 mb-2">Fixed Insurance/Deposit (CFA)</label>
                      <input type="number" className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={formData.monthly_insurance} onChange={e => setFormData({...formData, monthly_insurance: e.target.value})} placeholder="Override default insurance" />
                    </div>
                  </div>

                  <div className="col-span-1 md:col-span-2">
                    <label className="block text-sm font-medium text-slate-400 mb-2">Upload Signed Contract (PDF)</label>
                    <div className="relative">
                      <input 
                        type="file" 
                        accept=".pdf,.jpg,.jpeg,.png"
                        onChange={e => setFormData({...formData, contract_file: e.target.files[0]})} 
                        className="hidden" 
                        id="contract-upload"
                      />
                      <label htmlFor="contract-upload" className="w-full flex items-center justify-center gap-3 bg-slate-900/50 border-2 border-dashed border-slate-600 rounded-xl px-4 py-8 text-slate-300 hover:border-primary hover:text-primary transition-colors cursor-pointer">
                        <Upload size={24} />
                        {formData.contract_file ? formData.contract_file.name : "Click to browse and upload physical contract"}
                      </label>
                    </div>
                  </div>
                </>
              )}
            </div>
            
            <div className="flex justify-end gap-3 mt-6">
              <button onClick={() => setShowAdd(false)} className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-lg transition-colors">Cancel</button>
              <button 
                onClick={() => addMutation.mutate(formData)} 
                disabled={!formData.user_id || !formData.apartment_id || !formData.start_date || !formData.end_date || addMutation.isLoading}
                className="bg-success hover:bg-green-600 disabled:opacity-50 text-white px-8 py-2 rounded-lg transition-colors font-medium"
              >
                {addMutation.isLoading ? "Registering..." : "Register & Notify Tenant"}
              </button>
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
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="text-muted" size={18} />
              <select 
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary text-sm"
              >
                <option value="All">{t('tenants.filter_all')}</option>
                <option value="Active">{t('tenants.filter_active')}</option>
                <option value="Inactive">{t('tenants.filter_inactive')}</option>
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
                        {tenant.full_name.charAt(0)}
                      </div>
                      <div className="ms-4">
                        <div className="text-sm font-medium text-white">{tenant.full_name}</div>
                        <div className="text-sm text-slate-400">{tenant.phone}</div>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm text-slate-300">{tenant.national_id}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    {(tenant.contract_status === 'Active' || tenant.contract_status === 'Approved') ? (
                      <div>
                        <div className="text-sm font-medium text-white">{tenant.building_name} - {tenant.apartment_code}</div>
                        <div className="text-xs text-slate-400 mt-0.5 flex items-center gap-2">
                          <span title="Contract Dates">{tenant.start_date} &rarr; {tenant.end_date}</span>
                          {isExpiringSoon(tenant.end_date) && (
                            <span className="text-warning flex items-center gap-1 font-semibold" title="Expiring within 10 days">
                              <AlertCircle size={12} /> Expiring soon
                            </span>
                          )}
                        </div>
                        {tenant.next_billing_date && (
                          <div className="text-xs font-medium text-indigo-300 bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20 inline-flex items-center mt-1.5" title="Rent Cycle Dates">
                            Rent: {getRentCycleStart(tenant.next_billing_date, tenant.billing_frequency)} &rarr; {tenant.next_billing_date}
                          </div>
                        )}
                      </div>
                    ) : (
                      <span className="text-sm text-slate-500 italic">{t('tenants.no_apt')}</span>
                    )}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${
                      tenant.rent_status === 'Ended' ? 'bg-red-500/20 text-red-400' :
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
                    No tenants found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
          {/* Renew Modal */}
          {renewModal && (
            <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
              <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in zoom-in-95">
                <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/30">
                  <h3 className="text-xl font-bold text-white flex items-center gap-2">
                    <RefreshCw className="text-success" size={24} /> 
                    Renew Contract
                  </h3>
                  <button onClick={() => setRenewModal(null)} className="text-slate-400 hover:text-white transition-colors">
                    <X size={24} />
                  </button>
                </div>
                <div className="p-6 space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-2">New Start Date</label>
                    <input 
                      type="date" 
                      className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                      value={renewModal.start_date} 
                      onChange={e => setRenewModal({...renewModal, start_date: e.target.value})} 
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-2">New End Date</label>
                    <input 
                      type="date" 
                      className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                      value={renewModal.end_date} 
                      onChange={e => setRenewModal({...renewModal, end_date: e.target.value})} 
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
      </div>
    </div>
  );
};

export default Tenants;
