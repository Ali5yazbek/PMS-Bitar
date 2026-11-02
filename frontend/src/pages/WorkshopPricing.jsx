import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { 
  Settings, Save, RefreshCw, HardHat, DollarSign, Plus, Trash2, 
  Edit3, X, Check, Search, Package, Wrench, Layers, Tag, Filter 
} from 'lucide-react';

const WorkshopPricing = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [isSaving, setIsSaving] = useState(false);
  const [toastMsg, setToastMsg] = useState(null);

  // Search & Filter state for market rates
  const [rateSearch, setRateSearch] = useState('');
  const [activeCategory, setActiveCategory] = useState('All');
  const [editingId, setEditingId] = useState(null);
  const [editForm, setEditForm] = useState({ item_name: '', unit: '', default_price: '' });
  const [showAddRate, setShowAddRate] = useState(false);
  const [addForm, setAddForm] = useState({ category: 'Material', item_name: '', unit: '', default_price: '' });

  // Base parameters state
  const [formData, setFormData] = useState({
    workshop_cement_base: '10000',
    workshop_sand_base: '500',
    workshop_steel_base: '50',
    workshop_blocks_base: '150000',
    workshop_base_area: '3200',
    workshop_cost_per_sqm: '150000'
  });

  // Queries
  const { data: settings, isLoading: isSettingsLoading } = useQuery({
    queryKey: ['globalSettings'],
    queryFn: async () => {
      const res = await api.get('/global-settings');
      return res.data;
    }
  });

  const { data: rates, isLoading: isRatesLoading } = useQuery({
    queryKey: ['settingsRates'],
    queryFn: async () => {
      const res = await api.get('/settings/rates');
      return res.data;
    }
  });

  useEffect(() => {
    if (settings) {
      setFormData(prev => ({
        workshop_cement_base: settings.workshop_cement_base || prev.workshop_cement_base,
        workshop_sand_base: settings.workshop_sand_base || prev.workshop_sand_base,
        workshop_steel_base: settings.workshop_steel_base || prev.workshop_steel_base,
        workshop_blocks_base: settings.workshop_blocks_base || prev.workshop_blocks_base,
        workshop_base_area: settings.workshop_base_area || prev.workshop_base_area,
        workshop_cost_per_sqm: settings.workshop_cost_per_sqm || prev.workshop_cost_per_sqm,
      }));
    }
  }, [settings]);

  // Mutations
  const updateBaseMutation = useMutation({
    mutationFn: (data) => api.post(`/global-settings/bulk`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['globalSettings']);
      setIsSaving(false);
      showToast('Base parameters updated successfully!', 'success');
    },
    onError: () => {
      setIsSaving(false);
      showToast('Failed to update base parameters.', 'error');
    }
  });

  const updateRateMutation = useMutation({
    mutationFn: (vars) => api.put(`/settings/rates/${vars.id}`, vars.data),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
      setEditingId(null);
      showToast('Market rate updated successfully!', 'success');
    },
    onError: (err) => {
      showToast(err.response?.data?.error || 'Failed to update rate', 'error');
    }
  });

  const addRateMutation = useMutation({
    mutationFn: (data) => api.post('/settings/rates', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
      setShowAddRate(false);
      setAddForm({ category: 'Material', item_name: '', unit: '', default_price: '' });
      showToast('New item added successfully!', 'success');
    },
    onError: (err) => {
      showToast(err.response?.data?.error || 'Failed to add item', 'error');
    }
  });

  const deleteRateMutation = useMutation({
    mutationFn: (id) => api.delete(`/settings/rates/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['settingsRates']);
      showToast('Item deleted successfully!', 'success');
    },
    onError: (err) => {
      showToast(err.response?.data?.error || 'Failed to delete item', 'error');
    }
  });

  const showToast = (message, type = 'success') => {
    setToastMsg({ message, type });
    setTimeout(() => setToastMsg(null), 3000);
  };

  const handleSaveBase = () => {
    setIsSaving(true);
    updateBaseMutation.mutate(formData);
  };

  const startEditing = (rate) => {
    setEditingId(rate.id);
    setEditForm({
      item_name: rate.item_name,
      unit: rate.unit,
      default_price: rate.default_price
    });
  };

  const handleSaveEdit = (rateId) => {
    if (!editForm.item_name || editForm.default_price === '') {
      showToast('Item name and price are required', 'error');
      return;
    }
    updateRateMutation.mutate({
      id: rateId,
      data: {
        item_name: editForm.item_name,
        unit: editForm.unit,
        default_price: parseFloat(editForm.default_price) || 0
      }
    });
  };

  const handleAddSubmit = (e) => {
    e.preventDefault();
    if (!addForm.item_name || addForm.default_price === '') {
      showToast('Please fill in Item Name and Default Price', 'error');
      return;
    }
    addRateMutation.mutate({
      ...addForm,
      default_price: parseFloat(addForm.default_price) || 0
    });
  };

  const categories = ['Material', 'Labor', 'Equipment', 'Other'];

  const filteredRates = rates?.filter(r => {
    const matchesCategory = activeCategory === 'All' || r.category === activeCategory;
    const matchesSearch = !rateSearch || 
      r.item_name?.toLowerCase().includes(rateSearch.toLowerCase()) || 
      r.unit?.toLowerCase().includes(rateSearch.toLowerCase()) ||
      r.category?.toLowerCase().includes(rateSearch.toLowerCase());
    return matchesCategory && matchesSearch;
  }) || [];

  const groupedRates = filteredRates.reduce((acc, rate) => {
    acc[rate.category] = acc[rate.category] || [];
    acc[rate.category].push(rate);
    return acc;
  }, {});

  const getCategoryIcon = (cat) => {
    switch (cat) {
      case 'Material': return <Package size={18} className="text-primary" />;
      case 'Labor': return <HardHat size={18} className="text-amber-400" />;
      case 'Equipment': return <Wrench size={18} className="text-emerald-400" />;
      default: return <Tag size={18} className="text-indigo-400" />;
    }
  };

  if (isSettingsLoading && isRatesLoading) {
    return <div className="p-8 text-muted">Loading workshop pricing data...</div>;
  }

  return (
    <div className="flex h-full w-full bg-background overflow-hidden animate-in fade-in duration-300">
      <div className="flex-1 overflow-y-auto p-6 md:p-8 hide-scrollbar">
        
        {/* Toast Notification */}
        {toastMsg && (
          <div className={`fixed top-4 right-4 z-50 px-6 py-3 rounded-xl shadow-2xl animate-in fade-in slide-in-from-top-2 flex items-center space-x-2 border ${
            toastMsg.type === 'error' ? 'bg-red-500/90 text-white border-red-400' : 'bg-emerald-600/90 text-white border-emerald-400'
          }`}>
            <span className="font-medium text-sm">{toastMsg.message}</span>
          </div>
        )}

        {/* Top Header */}
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <HardHat className="text-primary" size={32} />
              Workshop Pricing & Estimation
            </h1>
            <p className="text-muted mt-1 text-sm">
              Manage base metrics, material ratios, and default market rates for materials, labor, and equipment.
            </p>
          </div>

          <button
            onClick={() => setShowAddRate(!showAddRate)}
            className="bg-primary hover:bg-indigo-600 text-white px-4 py-2.5 rounded-xl font-medium flex items-center gap-2 transition-all shadow-lg shadow-primary/25 text-sm"
          >
            <Plus size={18} />
            <span>Add Rate Item</span>
          </button>
        </div>

        {/* Add Item Form (Expandable) */}
        {showAddRate && (
          <div className="glass-card p-6 mb-8 border border-primary/40 animate-in fade-in slide-in-from-top-4 max-w-5xl shadow-2xl">
            <div className="flex justify-between items-center mb-4 pb-2 border-b border-slate-700/50">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Plus size={18} className="text-primary" /> Add New Item Price
              </h3>
              <button onClick={() => setShowAddRate(false)} className="text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleAddSubmit} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
                <div>
                  <label className="block text-muted text-xs font-semibold mb-1">Category</label>
                  <select 
                    value={addForm.category} 
                    onChange={e => setAddForm({...addForm, category: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                  >
                    {categories.map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-muted text-xs font-semibold mb-1">Item Name</label>
                  <input 
                    type="text" 
                    placeholder="e.g. White Marble, Welder..." 
                    value={addForm.item_name} 
                    onChange={e => setAddForm({...addForm, item_name: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    required
                  />
                </div>
                <div>
                  <label className="block text-muted text-xs font-semibold mb-1">Unit</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Bag, Ton, Piece, m2, Day..." 
                    value={addForm.unit} 
                    onChange={e => setAddForm({...addForm, unit: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    required
                  />
                </div>
                <div>
                  <label className="block text-muted text-xs font-semibold mb-1">Default Price (CFA)</label>
                  <input 
                    type="number" 
                    step="any"
                    placeholder="0.00" 
                    value={addForm.default_price} 
                    onChange={e => setAddForm({...addForm, default_price: e.target.value})}
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary"
                    required
                  />
                </div>
              </div>

              <div className="flex justify-end gap-3 pt-2">
                <button 
                  type="button" 
                  onClick={() => setShowAddRate(false)} 
                  className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-sm"
                >
                  Cancel
                </button>
                <button 
                  type="submit" 
                  disabled={addRateMutation.isPending}
                  className="px-5 py-2 bg-success hover:bg-emerald-600 text-white rounded-lg text-sm font-semibold flex items-center gap-1.5 transition-colors shadow-lg shadow-emerald-950/30"
                >
                  {addRateMutation.isPending ? <RefreshCw className="animate-spin" size={16} /> : <Check size={16} />}
                  <span>Save Item</span>
                </button>
              </div>
            </form>
          </div>
        )}

        {/* Section 1: Base Parameters & Ratio Metrics */}
        <div className="max-w-5xl mb-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="glass-card p-6">
              <h2 className="text-lg font-semibold text-white border-b border-slate-700/50 pb-3 mb-5 flex items-center gap-2">
                <Settings className="text-primary" size={20} />
                Base Parameters
              </h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1.5">Base Reference Area (m²)</label>
                  <input
                    type="number"
                    className="w-full bg-slate-900/60 border border-slate-700 rounded-xl px-4 py-2.5 text-white focus:border-primary focus:ring-1 focus:ring-primary transition-all text-sm outline-none"
                    value={formData.workshop_base_area}
                    onChange={(e) => setFormData({ ...formData, workshop_base_area: e.target.value })}
                  />
                  <p className="text-xs text-slate-500 mt-1">The standard area used for metric ratios (default is 3200 m²).</p>
                </div>

                <div>
                  <label className="block text-sm font-medium text-muted mb-1.5">Estimated Cost Per m²</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <DollarSign size={16} className="text-slate-400" />
                    </div>
                    <input
                      type="number"
                      className="w-full bg-slate-900/60 border border-slate-700 rounded-xl pl-9 pr-4 py-2.5 text-white focus:border-primary focus:ring-1 focus:ring-primary transition-all text-sm outline-none"
                      value={formData.workshop_cost_per_sqm}
                      onChange={(e) => setFormData({ ...formData, workshop_cost_per_sqm: e.target.value })}
                    />
                  </div>
                  <p className="text-xs text-slate-500 mt-1">Cost multiplier per square meter of construction.</p>
                </div>
              </div>
            </div>

            <div className="glass-card p-6">
              <h2 className="text-lg font-semibold text-white border-b border-slate-700/50 pb-3 mb-5 flex items-center gap-2">
                <Layers className="text-emerald-400" size={20} />
                Material Requirements (per Base Area)
              </h2>
              
              <div className="space-y-3.5">
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Cement Base Quantity (Bags)</label>
                  <input
                    type="number"
                    className="w-full bg-slate-900/60 border border-slate-700 rounded-xl px-4 py-2 text-white focus:border-primary transition-all text-sm outline-none"
                    value={formData.workshop_cement_base}
                    onChange={(e) => setFormData({ ...formData, workshop_cement_base: e.target.value })}
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Sand Base Quantity (Tons)</label>
                  <input
                    type="number"
                    className="w-full bg-slate-900/60 border border-slate-700 rounded-xl px-4 py-2 text-white focus:border-primary transition-all text-sm outline-none"
                    value={formData.workshop_sand_base}
                    onChange={(e) => setFormData({ ...formData, workshop_sand_base: e.target.value })}
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Steel Base Quantity (Tons)</label>
                  <input
                    type="number"
                    className="w-full bg-slate-900/60 border border-slate-700 rounded-xl px-4 py-2 text-white focus:border-primary transition-all text-sm outline-none"
                    value={formData.workshop_steel_base}
                    onChange={(e) => setFormData({ ...formData, workshop_steel_base: e.target.value })}
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-muted mb-1">Blocks Base Quantity (Pieces)</label>
                  <input
                    type="number"
                    className="w-full bg-slate-900/60 border border-slate-700 rounded-xl px-4 py-2 text-white focus:border-primary transition-all text-sm outline-none"
                    value={formData.workshop_blocks_base}
                    onChange={(e) => setFormData({ ...formData, workshop_blocks_base: e.target.value })}
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="mt-4 flex justify-end">
            <button
              onClick={handleSaveBase}
              disabled={isSaving}
              className="bg-primary hover:bg-indigo-600 text-white px-5 py-2 rounded-xl font-medium flex items-center gap-2 transition-all shadow-lg shadow-primary/20 disabled:opacity-50 text-sm"
            >
              {isSaving ? <RefreshCw className="animate-spin" size={16} /> : <Save size={16} />}
              Save Base Parameters
            </button>
          </div>
        </div>

        {/* Section 2: All Market Rates & Item Prices */}
        <div className="max-w-5xl space-y-6">
          <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 border-b border-slate-800 pb-4">
            <div>
              <h2 className="text-xl font-bold text-white flex items-center gap-2">
                <Tag className="text-primary" size={22} />
                Market Rates & Unit Pricing
              </h2>
              <p className="text-muted text-xs mt-0.5">
                Full catalog of unit prices used to calculate estimates. Click any price to edit and update.
              </p>
            </div>

            {/* Search Box */}
            <div className="relative w-full sm:w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={16} />
              <input
                type="text"
                placeholder="Search items or units..."
                value={rateSearch}
                onChange={e => setRateSearch(e.target.value)}
                className="w-full pl-9 pr-4 py-1.5 bg-slate-900/80 border border-slate-700 rounded-lg text-white text-xs outline-none focus:border-primary"
              />
              {rateSearch && (
                <button onClick={() => setRateSearch('')} className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 hover:text-white">
                  <X size={14} />
                </button>
              )}
            </div>
          </div>

          {/* Category Filter Pills */}
          <div className="flex gap-2 flex-wrap text-xs">
            <button
              onClick={() => setActiveCategory('All')}
              className={`px-3 py-1.5 rounded-lg font-medium transition-colors border ${
                activeCategory === 'All' 
                  ? 'bg-primary text-white border-primary shadow' 
                  : 'bg-slate-900/60 text-slate-400 border-slate-800 hover:text-white'
              }`}
            >
              All Items ({rates?.length || 0})
            </button>
            {categories.map(cat => {
              const count = rates?.filter(r => r.category === cat).length || 0;
              return (
                <button
                  key={cat}
                  onClick={() => setActiveCategory(cat)}
                  className={`px-3 py-1.5 rounded-lg font-medium transition-colors border ${
                    activeCategory === cat 
                      ? 'bg-primary text-white border-primary shadow' 
                      : 'bg-slate-900/60 text-slate-400 border-slate-800 hover:text-white'
                  }`}
                >
                  {cat} ({count})
                </button>
              );
            })}
          </div>

          {/* Grouped Category Tables */}
          {categories.map(cat => {
            const catRates = groupedRates[cat];
            if (!catRates || catRates.length === 0) return null;

            return (
              <div key={cat} className="glass-card overflow-hidden border border-slate-800 shadow-xl">
                <div className="bg-slate-800/60 px-6 py-3.5 border-b border-slate-700/50 flex justify-between items-center">
                  <h3 className="font-bold text-white text-sm flex items-center gap-2">
                    {getCategoryIcon(cat)}
                    <span>{cat} Rates</span>
                    <span className="text-xs text-muted font-normal">({catRates.length} {catRates.length === 1 ? 'item' : 'items'})</span>
                  </h3>
                </div>

                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm border-collapse">
                    <thead>
                      <tr className="border-b border-slate-700/60 text-slate-400 text-xs uppercase tracking-wider">
                        <th className="px-6 py-3 font-semibold">Item</th>
                        <th className="px-6 py-3 font-semibold">Unit</th>
                        <th className="px-6 py-3 font-semibold text-right">Default Unit Price</th>
                        <th className="px-6 py-3 font-semibold text-center w-28">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800/70">
                      {catRates.map(rate => {
                        const isEditing = editingId === rate.id;

                        if (isEditing) {
                          return (
                            <tr key={rate.id} className="bg-primary/10">
                              <td className="px-6 py-2.5">
                                <input
                                  type="text"
                                  value={editForm.item_name}
                                  onChange={e => setEditForm({...editForm, item_name: e.target.value})}
                                  className="w-full bg-slate-900 border border-primary/50 rounded px-2.5 py-1 text-white text-sm outline-none"
                                  autoFocus
                                />
                              </td>
                              <td className="px-6 py-2.5">
                                <input
                                  type="text"
                                  value={editForm.unit}
                                  onChange={e => setEditForm({...editForm, unit: e.target.value})}
                                  className="w-28 bg-slate-900 border border-primary/50 rounded px-2.5 py-1 text-white text-sm outline-none"
                                />
                              </td>
                              <td className="px-6 py-2.5 text-right">
                                <div className="inline-flex items-center gap-1 justify-end">
                                  <span className="text-xs text-slate-400">CFA</span>
                                  <input
                                    type="number"
                                    step="any"
                                    value={editForm.default_price}
                                    onChange={e => setEditForm({...editForm, default_price: e.target.value})}
                                    onKeyDown={e => {
                                      if (e.key === 'Enter') handleSaveEdit(rate.id);
                                      if (e.key === 'Escape') setEditingId(null);
                                    }}
                                    className="w-32 bg-slate-900 border border-primary/50 rounded px-2.5 py-1 text-white text-sm text-right outline-none font-bold text-emerald-400"
                                  />
                                </div>
                              </td>
                              <td className="px-6 py-2.5 text-center">
                                <div className="flex items-center justify-center gap-2">
                                  <button
                                    onClick={() => handleSaveEdit(rate.id)}
                                    className="p-1.5 rounded-lg bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 transition-colors"
                                    title="Save (Enter)"
                                  >
                                    <Check size={16} />
                                  </button>
                                  <button
                                    onClick={() => setEditingId(null)}
                                    className="p-1.5 rounded-lg bg-slate-800 text-slate-400 hover:text-white transition-colors"
                                    title="Cancel (Esc)"
                                  >
                                    <X size={16} />
                                  </button>
                                </div>
                              </td>
                            </tr>
                          );
                        }

                        return (
                          <tr key={rate.id} className="hover:bg-slate-800/30 transition-colors group">
                            <td className="px-6 py-3 font-medium text-white flex items-center gap-2">
                              {rate.item_name}
                            </td>
                            <td className="px-6 py-3 text-slate-400">
                              <span className="px-2.5 py-0.5 rounded text-xs bg-slate-800 text-slate-300 border border-slate-700/60">
                                {rate.unit}
                              </span>
                            </td>
                            <td className="px-6 py-3 text-right">
                              <span className="font-bold text-emerald-400 text-sm">
                                CFA {Number(rate.default_price).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 })}
                              </span>
                            </td>
                            <td className="px-6 py-3 text-center">
                              <div className="flex items-center justify-center gap-1.5 opacity-80 group-hover:opacity-100 transition-opacity">
                                <button
                                  onClick={() => startEditing(rate)}
                                  className="p-1.5 rounded-lg hover:bg-slate-800 text-slate-400 hover:text-primary transition-colors"
                                  title="Change Price"
                                >
                                  <Edit3 size={15} />
                                </button>
                                <button
                                  onClick={() => {
                                    if (window.confirm(`Are you sure you want to delete "${rate.item_name}"?`)) {
                                      deleteRateMutation.mutate(rate.id);
                                    }
                                  }}
                                  className="p-1.5 rounded-lg hover:bg-red-500/10 text-slate-400 hover:text-red-400 transition-colors"
                                  title="Delete Item"
                                >
                                  <Trash2 size={15} />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            );
          })}

          {filteredRates.length === 0 && (
            <div className="glass-card p-12 text-center text-muted">
              <Package size={36} className="mx-auto mb-2 opacity-30" />
              <p className="text-sm">No items found matching your filter.</p>
              {rateSearch && (
                <button onClick={() => setRateSearch('')} className="mt-2 text-xs text-primary hover:underline">
                  Clear search filter
                </button>
              )}
            </div>
          )}
        </div>

      </div>
    </div>
  );
};

export default WorkshopPricing;
