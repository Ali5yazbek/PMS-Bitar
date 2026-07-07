import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Settings as SettingsIcon, Save, Edit3, X, DollarSign, HardHat, Plus, Trash2 } from 'lucide-react';

const Settings = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState(null);
  
  const [editForm, setEditForm] = useState({ item_name: '', unit: '', default_price: '' });
  const [showAdd, setShowAdd] = useState(false);
  const [addForm, setAddForm] = useState({ category: 'Material', item_name: '', unit: '', default_price: '' });

  const { data: rates, isLoading } = useQuery({ 
    queryKey: ['settingsRates'], 
    queryFn: async () => (await api.get('/settings/rates')).data 
  });

  const updateRateMutation = useMutation({
    mutationFn: (vars) => api.put(`/settings/rates/${vars.id}`, vars.data),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
      setEditingId(null);
    }
  });

  const addRateMutation = useMutation({
    mutationFn: (data) => api.post('/settings/rates', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
      setShowAdd(false);
      setAddForm({ category: 'Material', item_name: '', unit: '', default_price: '' });
    }
  });

  const deleteRateMutation = useMutation({
    mutationFn: (id) => api.delete(`/settings/rates/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
    }
  });

  const categories = ['Material', 'Labor', 'Equipment', 'Other'];

  if (isLoading) return <div className="p-8 text-muted">{t('settings.loading')}</div>;

  const groupedRates = rates?.reduce((acc, rate) => {
    acc[rate.category] = acc[rate.category] || [];
    acc[rate.category].push(rate);
    return acc;
  }, {});

  const startEditing = (rate) => {
    setEditingId(rate.id);
    setEditForm({ item_name: rate.item_name, unit: rate.unit, default_price: rate.default_price });
  };

  return (
    <div className="flex h-full bg-background">
      <div className="flex-1 flex flex-col h-full overflow-hidden">
        <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
          
          <div className="flex justify-between items-end mb-8">
            <div>
              <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
                <HardHat className="me-3 text-warning" size={32} /> {t('settings.title')}
              </h1>
              <p className="text-muted">{t('settings.subtitle')}</p>
            </div>
            <button 
              onClick={() => setShowAdd(!showAdd)}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center transition-colors shadow-lg shadow-primary/20"
            >
              <Plus size={18} className="me-2" /> {t('settings.btn_add')}
            </button>
          </div>

          {showAdd && (
            <div className="glass-card p-6 mb-8 max-w-5xl animate-in fade-in slide-in-from-top-4">
              <h3 className="text-xl font-bold text-white mb-4">{t('settings.modal_add_title')}</h3>
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
                <div>
                  <label className="block text-sm text-muted mb-1">{t('settings.label_cat')}</label>
                  <select 
                    value={addForm.category}
                    onChange={e => setAddForm({...addForm, category: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white"
                  >
                    {categories.map(c => <option key={c} value={c}>{t('settings.categories.' + c, c)}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-sm text-muted mb-1">{t('settings.label_item')}</label>
                  <input 
                    type="text" 
                    value={addForm.item_name}
                    onChange={e => setAddForm({...addForm, item_name: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    placeholder="e.g. Red Bricks"
                  />
                </div>
                <div>
                  <label className="block text-sm text-muted mb-1">{t('settings.label_unit')}</label>
                  <input 
                    type="text" 
                    value={addForm.unit}
                    onChange={e => setAddForm({...addForm, unit: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    placeholder="e.g. Piece"
                  />
                </div>
                <div>
                  <label className="block text-sm text-muted mb-1">{t('settings.label_price')} ({t('common.currency')})</label>
                  <input 
                    type="number" 
                    value={addForm.default_price}
                    onChange={e => setAddForm({...addForm, default_price: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    placeholder="e.g. 50"
                  />
                </div>
              </div>
              <div className="flex justify-end gap-3">
                <button onClick={() => setShowAdd(false)} className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg transition-colors">{t('settings.btn_cancel')}</button>
                <button 
                  onClick={() => addRateMutation.mutate(addForm)} 
                  disabled={!addForm.item_name || !addForm.unit || !addForm.default_price}
                  className="px-4 py-2 bg-success hover:bg-green-600 text-white rounded-lg transition-colors disabled:opacity-50"
                >
                  {t('settings.btn_save_item')}
                </button>
              </div>
            </div>
          )}

          <div className="space-y-8 max-w-5xl">
            {categories.map(category => {
              if (!groupedRates?.[category]) return null;
              return (
                <div key={category} className="glass-card overflow-hidden">
                  <div className="bg-slate-800/50 p-4 border-b border-slate-700/50 flex justify-between items-center">
                    <h3 className="font-bold text-lg text-white">{t('settings.categories.' + category, category)} {t('settings.cat_market_rates')}</h3>
                  </div>
                  <table className="w-full text-start border-collapse">
                    <thead>
                      <tr className="border-b border-slate-700/50 bg-slate-800/30">
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase w-1/3 text-start">{t('settings.th_item')}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase w-1/4 text-start">{t('settings.th_unit')}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase text-end">{t('settings.th_price')} ({t('common.currency')})</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase text-center w-24">{t('settings.th_actions')}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700/50">
                      {groupedRates[category].map(rate => (
                        <tr key={rate.id} className="hover:bg-slate-800/30 transition-colors">
                          {editingId === rate.id ? (
                            <>
                              <td className="px-6 py-2">
                                <input 
                                  type="text" 
                                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-1.5 text-white focus:outline-none focus:border-primary text-sm"
                                  value={editForm.item_name}
                                  onChange={e => setEditForm({...editForm, item_name: e.target.value})}
                                />
                              </td>
                              <td className="px-6 py-2">
                                <input 
                                  type="text" 
                                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-3 py-1.5 text-white focus:outline-none focus:border-primary text-sm"
                                  value={editForm.unit}
                                  onChange={e => setEditForm({...editForm, unit: e.target.value})}
                                />
                              </td>
                              <td className="px-6 py-2">
                                <div className="flex items-center justify-end gap-2">
                                  <DollarSign size={16} className="text-muted" />
                                  <input 
                                    type="number" 
                                    className="bg-slate-800 border border-slate-600 rounded-lg px-3 py-1.5 w-32 text-end focus:outline-none focus:border-primary text-white text-sm"
                                    value={editForm.default_price}
                                    onChange={e => setEditForm({...editForm, default_price: e.target.value})}
                                  />
                                </div>
                              </td>
                              <td className="px-6 py-2">
                                <div className="flex items-center justify-center gap-1">
                                  <button onClick={() => updateRateMutation.mutate({ id: rate.id, data: editForm })} className="text-success hover:bg-success/20 p-1.5 rounded transition-colors"><Save size={18}/></button>
                                  <button onClick={() => setEditingId(null)} className="text-slate-400 hover:bg-slate-700 p-1.5 rounded transition-colors"><X size={18}/></button>
                                </div>
                              </td>
                            </>
                          ) : (
                            <>
                              <td className="px-6 py-4 text-sm font-medium text-slate-300">{t('settings.items.' + rate.item_name, rate.item_name)}</td>
                              <td className="px-6 py-4 text-sm text-slate-400">{t('settings.units.' + rate.unit, rate.unit)}</td>
                              <td className="px-6 py-4 text-sm text-end font-medium text-white">
                                <span className="text-warning">{t('common.currency')} {Number(rate.default_price).toLocaleString()}</span>
                              </td>
                              <td className="px-6 py-4 text-center">
                                <div className="flex items-center justify-center gap-2">
                                  <button 
                                    onClick={() => startEditing(rate)}
                                    className="text-slate-400 hover:text-primary transition-colors p-1"
                                    title="Edit Item"
                                  >
                                    <Edit3 size={18} />
                                  </button>
                                  <button 
                                    onClick={() => { if(window.confirm(t('settings.confirm_del'))) deleteRateMutation.mutate(rate.id); }}
                                    className="text-slate-400 hover:text-danger transition-colors p-1"
                                    title="Delete Item"
                                  >
                                    <Trash2 size={18} />
                                  </button>
                                </div>
                              </td>
                            </>
                          )}
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
