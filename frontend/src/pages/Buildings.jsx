import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Building, Plus, Search, Trash2, ArrowRight, Home, DollarSign, FileText } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import ApartmentCostsModal from '../components/ApartmentCostsModal';

const Buildings = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [newBuilding, setNewBuilding] = useState('');
  const [selectedBuildingCosts, setSelectedBuildingCosts] = useState(null);

  const { data: buildings, isLoading } = useQuery({
    queryKey: ['buildings'],
    queryFn: async () => {
      const res = await api.get('/buildings');
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (name) => api.post('/buildings', { name }),
    onSuccess: () => {
      queryClient.invalidateQueries(['buildings']);
      setShowAdd(false);
      setNewBuilding('');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/buildings/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['buildings'])
  });

  const filteredBuildings = buildings?.filter(b => b.name.toLowerCase().includes(searchTerm.toLowerCase()));

  // Mock stats for right panel
  const totalApartments = buildings?.reduce((sum, b) => sum + (Number(b.total_apartments) || 0), 0) || 0;
  const occupiedApartments = buildings?.reduce((sum, b) => sum + (Number(b.occupied_apartments) || 0), 0) || 0;
  const vacantApartments = totalApartments - occupiedApartments;

  return (
    <div className="flex h-full w-full overflow-hidden">
      {/* Center Content */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">{t('buildings.title')}</h1>
            <p className="text-muted mt-1">{t('buildings.subtitle')}</p>
          </div>
          <div className="flex space-x-4">
            <div className="relative w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
              <input 
                type="text" 
                placeholder={t('buildings.search')} 
                className="w-full pl-10 pr-4 py-2 bg-cards border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary transition-colors"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <button 
              onClick={() => setShowAdd(true)}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30"
            >
              <Plus size={20} />
              <span>{t('buildings.add_btn')}</span>
            </button>
          </div>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-8 flex items-end gap-4 animate-in fade-in slide-in-from-top-4">
            <div className="flex-1">
              <label className="block text-sm font-medium text-muted mb-2">{t('buildings.name_label')}</label>
              <input 
                type="text" 
                value={newBuilding}
                onChange={(e) => setNewBuilding(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 focus:ring-2 focus:ring-primary outline-none text-white"
                placeholder={t('buildings.name_placeholder')}
              />
            </div>
            <button 
              onClick={() => addMutation.mutate(newBuilding)}
              disabled={!newBuilding}
              className="bg-success hover:bg-green-600 text-white px-6 py-2 rounded-lg disabled:opacity-50 transition-colors"
            >
              {t('buildings.save')}
            </button>
            <button 
              onClick={() => setShowAdd(false)}
              className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-lg transition-colors"
            >
              {t('buildings.cancel')}
            </button>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {isLoading ? (
            Array(3).fill(0).map((_, i) => (
              <div key={i} className="glass-card h-48 animate-pulse bg-slate-800/50"></div>
            ))
          ) : (
            filteredBuildings?.map(b => (
              <div key={b.id} className="glass-card p-6 flex flex-col hover-card group relative overflow-hidden">
                <div className="absolute top-0 right-0 w-24 h-24 bg-primary/10 rounded-bl-full -z-10 blur-xl"></div>
                <div className="flex justify-between items-start mb-4">
                  <div className="flex items-center gap-4">
                    <div className="bg-primary/20 p-3 rounded-xl text-primary shadow-inner">
                      <Building size={28} strokeWidth={1.5} />
                    </div>
                    <div>
                      <h3 className="font-bold text-xl text-white">{b.name}</h3>
                      <p className="text-sm text-muted">{b.total_apartments || 0} {t('buildings.apartments')}</p>
                    </div>
                  </div>
                  <button 
                    onClick={(e) => { e.stopPropagation(); if(window.confirm(t('buildings.delete_confirm'))) deleteMutation.mutate(b.id); }}
                    className="text-danger opacity-0 group-hover:opacity-100 transition-opacity p-2 hover:bg-danger/10 rounded-lg"
                  >
                    <Trash2 size={18} />
                  </button>
                </div>
                
                <div className="flex space-x-4 mb-6">
                  <div className="flex-1 bg-slate-800/50 rounded-lg p-2 text-center">
                    <div className="text-success font-bold">{b.occupied_apartments || 0}</div>
                    <div className="text-xs text-muted">{t('buildings.occupied')}</div>
                  </div>
                  <div className="flex-1 bg-slate-800/50 rounded-lg p-2 text-center">
                    <div className="text-warning font-bold">{b.total_apartments - (b.occupied_apartments || 0) || 0}</div>
                    <div className="text-xs text-muted">{t('buildings.vacant')}</div>
                  </div>
                </div>

                <div className="mt-auto flex flex-col gap-2">
                  <div className="flex gap-2">
                    <button 
                      onClick={() => navigate(`/energy/generator/${b.id}`)}
                      className="flex-1 flex items-center justify-center gap-2 bg-slate-700/50 hover:bg-slate-700 text-white py-2 rounded-xl transition-colors font-medium border border-slate-600/50 hover:border-slate-500"
                    >
                      <span className="text-sm">{t('buildings.generator')}</span>
                    </button>
                    <button 
                      onClick={() => navigate(`/energy/buildings/${b.id}/subscriptions`)}
                      className="flex-1 flex items-center justify-center gap-2 bg-slate-700/50 hover:bg-slate-700 text-white py-2 rounded-xl transition-colors font-medium border border-slate-600/50 hover:border-slate-500"
                    >
                      <span className="text-sm">{t('buildings.subscriptions')}</span>
                    </button>
                  </div>
                  <button 
                    onClick={() => setSelectedBuildingCosts(b)}
                    className="w-full flex items-center justify-center gap-2 bg-indigo-500/20 hover:bg-indigo-500/30 text-indigo-300 py-2.5 rounded-xl transition-colors font-medium border border-indigo-500/30"
                  >
                    <FileText size={18} />
                    <span>Apartment Costs</span>
                  </button>
                  <button 
                    onClick={() => navigate(`/buildings/${b.id}`)}
                    className="w-full flex items-center justify-center gap-2 bg-primary hover:bg-indigo-600 text-white py-3 rounded-xl transition-colors font-medium shadow-lg shadow-primary/30"
                  >
                    <span>{t('buildings.open')}</span>
                    <ArrowRight size={18} className={document.documentElement.dir === 'rtl' ? 'rotate-180' : ''} />
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Right Summary Panel */}
      <div className="hidden lg:flex w-80 glass-panel p-6 flex-col overflow-y-auto hide-scrollbar z-10 shrink-0">
        <h2 className="text-xl font-bold text-white mb-6">{t('buildings.summary_title')}</h2>
        
        <div className="space-y-6">
          <div className="p-5 glass-card relative overflow-hidden">
            <div className="absolute top-0 right-0 w-20 h-20 bg-primary/20 blur-2xl rounded-full"></div>
            <h3 className="text-white font-bold text-lg mb-4">{t('buildings.all_buildings')}</h3>
            <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted flex items-center"><Building size={16} className="me-2" /> {t('buildings.total_buildings')}</span>
                <span className="text-white font-bold">{buildings?.length || 0}</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted flex items-center"><Home size={16} className="me-2" /> {t('buildings.total_apartments')}</span>
                <span className="text-white font-bold">{totalApartments}</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-muted text-sm">{t('buildings.occupied')}</span>
                <span className="text-success font-bold">{occupiedApartments}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted text-sm">{t('buildings.vacant')}</span>
                <span className="text-warning font-bold">{vacantApartments}</span>
              </div>
            </div>
          </div>

          <div className="p-5 glass-card border border-slate-700/50">
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('buildings.financial_overview')}</h3>
            <div className="space-y-4">
              <div className="bg-slate-800/50 p-4 rounded-xl">
                <div className="flex items-center text-muted mb-1 text-sm"><DollarSign size={16} className="me-1"/> {t('buildings.monthly_income')}</div>
                <div className="text-2xl font-bold text-success">{t('common.currency')} 18,000</div>
              </div>
              <div className="bg-slate-800/50 p-4 rounded-xl border border-danger/20">
                <div className="flex items-center text-muted mb-1 text-sm"><DollarSign size={16} className="me-1 text-danger"/> {t('buildings.unpaid_rent')}</div>
                <div className="text-2xl font-bold text-danger">{t('common.currency')} 3,000</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {selectedBuildingCosts && (
        <ApartmentCostsModal 
          building={selectedBuildingCosts} 
          onClose={() => setSelectedBuildingCosts(null)} 
        />
      )}
    </div>
  );
};

export default Buildings;
