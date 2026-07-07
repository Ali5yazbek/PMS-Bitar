import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { Home, Plus, Trash2, Edit2, ArrowLeft, Search, Filter, Zap } from 'lucide-react';

const Apartments = () => {
  const { t } = useTranslation();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building');
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  
  const [showAdd, setShowAdd] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [formData, setFormData] = useState({ code: '', monthly_rent: '', monthly_insurance: '', status: 'Vacant', building_id: buildingId || '' });
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');

  const { data: buildings } = useQuery({ queryKey: ['buildings'], queryFn: async () => (await api.get('/buildings')).data });
  const { data: settings } = useQuery({ queryKey: ['globalSettings'], queryFn: async () => (await api.get('/global-settings')).data });
  const exchangeRate = settings?.usd_to_cfa ? Number(settings.usd_to_cfa) : 600;
  
  const { data: apartments, isLoading } = useQuery({
    queryKey: ['apartments', buildingId],
    queryFn: async () => {
      const url = buildingId ? `/apartments?building_id=${buildingId}` : '/apartments';
      const res = await api.get(url);
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (data) => api.post('/apartments', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['apartments']);
      setShowAdd(false);
      setFormData({ code: '', monthly_rent: '', monthly_insurance: '', status: 'Vacant', building_id: buildingId || '' });
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => api.put(`/apartments/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['apartments']);
      setShowAdd(false);
      setEditingId(null);
      setFormData({ code: '', monthly_rent: '', monthly_insurance: '', status: 'Vacant', building_id: buildingId || '' });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/apartments/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['apartments'])
  });

  const getStatusColor = (status) => {
    switch(status) {
      case 'Vacant': return 'bg-slate-800 border border-slate-600 text-slate-300';
      case 'Rented': return 'bg-success/20 border border-success/30 text-success';
      case 'Maintenance': return 'bg-warning/20 border border-warning/30 text-warning';
      default: return 'bg-slate-800 text-slate-300';
    }
  };

  if (isLoading) return <div className="p-8 text-muted">Loading apartments...</div>;

  const displayedApartments = apartments?.filter(apt => {
    const matchesSearch = apt.code.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || apt.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

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
              <Home className="me-3 text-primary" size={32} />
              {buildingId && buildings ? t('apartments.building_title', { building: buildings.find(b => b.id == buildingId)?.name }) : t('apartments.all_title')}
            </h1>
            <p className="text-muted mt-2">{t('apartments.subtitle')}</p>
          </div>
          
          <div className="flex items-center space-x-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input 
                type="text" 
                placeholder={t('apartments.search')} 
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <select 
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary text-sm"
            >
              <option value="All">{t('apartments.status_all')}</option>
              <option value="Vacant">{t('apartments.status_vacant')}</option>
              <option value="Rented">{t('apartments.status_rented')}</option>
              <option value="Maintenance">{t('apartments.status_maintenance')}</option>
            </select>
            <button 
              onClick={() => {
                setEditingId(null);
                setFormData({ code: '', monthly_rent: '', monthly_insurance: '', status: 'Vacant', building_id: buildingId || '' });
                setShowAdd(!showAdd);
              }}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors shadow-lg shadow-primary/20"
            >
              <Plus size={20} />
              <span>{t('apartments.add_btn')}</span>
            </button>
          </div>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-8 grid grid-cols-1 md:grid-cols-5 gap-4 items-end animate-in fade-in slide-in-from-top-4">
            {!buildingId && (
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('apartments.building_label')}</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.building_id} onChange={e => setFormData({...formData, building_id: e.target.value})}>
                  <option value="">{t('apartments.select_building')}</option>
                  {buildings?.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </div>
            )}
            <div>
              <label className="block text-sm font-medium text-muted mb-1">{t('apartments.code_label')}</label>
              <input type="text" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" placeholder={t('apartments.code_placeholder')} value={formData.code} onChange={e => setFormData({...formData, code: e.target.value})} />
            </div>
            <div>
              <label className="block text-sm font-medium text-muted mb-1 flex justify-between">
                <span>{t('apartments.rent_label')}</span>
                <span className="text-xs text-indigo-400">Rate: {exchangeRate}</span>
              </label>
              <div className="flex gap-2">
                <div className="relative w-1/3">
                  <div className="absolute inset-y-0 left-0 pl-2 flex items-center pointer-events-none"><span className="text-slate-400 text-sm">$</span></div>
                  <input type="number" className="w-full bg-slate-900 border border-slate-700 rounded-lg pl-6 pr-2 py-2 text-white outline-none focus:border-indigo-500 text-sm" placeholder="USD" 
                    onChange={e => {
                      const usd = e.target.value;
                      if(usd !== '') setFormData({...formData, monthly_rent: (parseFloat(usd) * exchangeRate).toFixed(2)});
                    }} 
                  />
                </div>
                <input type="number" className="w-full w-2/3 bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" placeholder="CFA" value={formData.monthly_rent} onChange={e => setFormData({...formData, monthly_rent: e.target.value})} />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-muted mb-1">{t('apartments.insurance_label')}</label>
              <div className="flex gap-2">
                <div className="relative w-1/3">
                  <div className="absolute inset-y-0 left-0 pl-2 flex items-center pointer-events-none"><span className="text-slate-400 text-sm">$</span></div>
                  <input type="number" className="w-full bg-slate-900 border border-slate-700 rounded-lg pl-6 pr-2 py-2 text-white outline-none focus:border-indigo-500 text-sm" placeholder="USD" 
                    onChange={e => {
                      const usd = e.target.value;
                      if(usd !== '') setFormData({...formData, monthly_insurance: (parseFloat(usd) * exchangeRate).toFixed(2)});
                    }} 
                  />
                </div>
                <input type="number" className="w-full w-2/3 bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" placeholder="CFA" value={formData.monthly_insurance} onChange={e => setFormData({...formData, monthly_insurance: e.target.value})} />
              </div>
            </div>
            <div className="flex gap-2">
              <button 
                onClick={() => {
                  if (editingId) {
                    updateMutation.mutate({ id: editingId, data: formData });
                  } else {
                    addMutation.mutate(formData);
                  }
                }} 
                className="bg-success hover:bg-green-600 text-white px-4 py-2 rounded-lg flex-1 transition-colors"
              >
                {editingId ? t('apartments.update_btn', { defaultValue: 'Update' }) : t('apartments.save')}
              </button>
              <button 
                onClick={() => {
                  setShowAdd(false);
                  setEditingId(null);
                  setFormData({ code: '', monthly_rent: '', monthly_insurance: '', status: 'Vacant', building_id: buildingId || '' });
                }} 
                className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg flex-1 transition-colors"
              >
                {t('apartments.cancel')}
              </button>
            </div>
          </div>
        )}

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
                  <td className="px-6 py-4 text-sm font-medium text-white">CFA {Number(apt.monthly_rent).toLocaleString()}</td>
                  <td className="px-6 py-4 text-sm font-medium text-slate-400">CFA {Number(apt.monthly_insurance).toLocaleString()}</td>
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
                        onClick={() => {
                          setEditingId(apt.id);
                          setFormData({ 
                            code: apt.code, 
                            monthly_rent: apt.monthly_rent, 
                            monthly_insurance: apt.monthly_insurance, 
                            status: apt.status, 
                            building_id: apt.building_id || buildingId || '' 
                          });
                          setShowAdd(true);
                        }}
                        className="text-slate-400 hover:text-indigo-400 p-2 transition-colors rounded-lg hover:bg-slate-800"
                      >
                        <Edit2 size={18} />
                      </button>
                      <button onClick={() => { if(window.confirm(t('apartments.delete_confirm'))) deleteMutation.mutate(apt.id); }} className="text-slate-400 hover:text-danger p-2 transition-colors rounded-lg hover:bg-slate-800"><Trash2 size={18} /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {apartments?.length === 0 && <div className="p-8 text-center text-muted">{t('apartments.no_data')}</div>}
        </div>
      </div>
    </div>
  );
};

export default Apartments;
