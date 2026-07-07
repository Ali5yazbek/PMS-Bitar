import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Package, Search, Plus, Edit, Trash2, AlertTriangle, TrendingUp, DollarSign, HardHat, Database, Check, Printer } from 'lucide-react';

const Warehouse = () => {
  const { t, i18n } = useTranslation();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('products'); // 'products' or 'depots'
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedDepot, setSelectedDepot] = useState('all');
  const [showAdd, setShowAdd] = useState(false);
  const [showDepotModal, setShowDepotModal] = useState(false);
  const [newProduct, setNewProduct] = useState({
    name: '', name_fr: '', name_ar: '', reference: '', quantity: 0, cost_price: 0, tva: 19, minimum_quantity: 0, depot_id: ''
  });
  const [editingDepot, setEditingDepot] = useState(null);
  const [newDepot, setNewDepot] = useState({ name: '', is_primary: false });

  const addMutation = useMutation({
    mutationFn: (productData) => axios.post('/warehouse', productData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['warehouseStats'] });
      setShowAdd(false);
      setNewProduct({ name: '', name_fr: '', name_ar: '', reference: '', quantity: 0, cost_price: 0, tva: 19, minimum_quantity: 0, depot_id: '' });
    }
  });

  const { data: stats } = useQuery({
    queryKey: ['warehouseStats'],
    queryFn: async () => {
      const { data } = await axios.get('/warehouse/stats');
      return data;
    }
  });

  const { data: products, isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: async () => {
      const { data } = await axios.get('/warehouse');
      return data;
    }
  });

  const { data: depots, isLoading: isDepotsLoading } = useQuery({
    queryKey: ['depots'],
    queryFn: async () => {
      const { data } = await axios.get('/depots');
      return data;
    }
  });

  const depotMutation = useMutation({
    mutationFn: (data) => data.id ? axios.put(`/depots/${data.id}`, data) : axios.post('/depots', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['depots'] });
      setShowDepotModal(false);
      setEditingDepot(null);
      setNewDepot({ name: '', is_primary: false });
    }
  });

  const deleteDepotMutation = useMutation({
    mutationFn: (id) => axios.delete(`/depots/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['depots'] });
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to delete depot');
    }
  });

  const filteredProducts = Array.isArray(products) ? products.filter(p => {
    const matchesSearch = p.name.toLowerCase().includes(searchTerm.toLowerCase()) || p.reference?.toLowerCase().includes(searchTerm.toLowerCase());
    if (selectedDepot === 'all') return matchesSearch;
    const hasDepot = p.depots?.some(d => parseInt(d.depot_id) === parseInt(selectedDepot) && Number(d.quantity) > 0);
    return matchesSearch && hasDepot;
  }) : [];

  const depotStats = Array.isArray(depots) ? depots.map(depot => {
    let totalStockValue = 0;
    let lowStockProducts = 0;
    let outOfStockProducts = 0;
    let totalStock = 0;

    if (Array.isArray(products)) {
      products.forEach(p => {
      const d = p.depots?.find(x => parseInt(x.depot_id) === parseInt(depot.id));
      const qty = d ? Number(d.quantity) : 0;
      
      totalStock += qty;
      totalStockValue += qty * Number(p.cost_price);
      
      if (qty <= Number(p.minimum_quantity) && qty > 0) lowStockProducts++;
      if (qty === 0) outOfStockProducts++;
      });
    }

    return {
      ...depot,
      totalStock,
      totalStockValue,
      lowStockProducts,
      outOfStockProducts
    };
  }) : [];

  return (
    <div className="flex h-full w-full overflow-hidden print:bg-white">
      {/* Center Content */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">{t('warehouse.title')}</h1>
            <div className="flex gap-4 mt-2">
              <button 
                onClick={() => setActiveTab('products')} 
                className={`text-sm font-medium pb-2 border-b-2 transition-colors ${activeTab === 'products' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
              >
                Products
              </button>
              <button 
                onClick={() => setActiveTab('depots')} 
                className={`text-sm font-medium pb-2 border-b-2 transition-colors ${activeTab === 'depots' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
              >
                Depots
              </button>
            </div>
          </div>
          <div className="flex space-x-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
              <input 
                type="text" 
                placeholder={t('warehouse.search')} 
                className="pl-10 pr-4 py-2 bg-cards border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary transition-colors"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            {activeTab === 'products' && (
              <select
                value={selectedDepot}
                onChange={(e) => setSelectedDepot(e.target.value)}
                className="bg-cards border border-slate-700 rounded-lg text-white px-3 py-2 focus:outline-none focus:border-primary transition-colors"
              >
                <option value="all">All Depots</option>
                {Array.isArray(depots) && depots.map(d => (
                  <option key={d.id} value={d.id}>{d.name}</option>
                ))}
              </select>
            )}
            {activeTab === 'products' ? (
              <button 
                onClick={() => setShowAdd(true)}
                className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30"
              >
                <Plus size={20} />
                <span>{t('warehouse.add_btn')}</span>
              </button>
            ) : (
              <button 
                onClick={() => {
                  setEditingDepot(null);
                  setNewDepot({ name: '', is_primary: false });
                  setShowDepotModal(true);
                }}
                className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30"
              >
                <Plus size={20} />
                <span>Add Depot</span>
              </button>
            )}
          </div>
        </div>

        {activeTab === 'products' && showAdd && (
          <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4">
            <h3 className="text-xl font-bold text-white mb-4">{t('warehouse.new_title')}</h3>
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4 mb-4">
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.name_label')} (English)</label>
                <input type="text" value={newProduct.name} onChange={e => setNewProduct({...newProduct, name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.name_label')} (French)</label>
                <input type="text" value={newProduct.name_fr} onChange={e => setNewProduct({...newProduct, name_fr: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.name_label')} (Arabic)</label>
                <input type="text" value={newProduct.name_ar} onChange={e => setNewProduct({...newProduct, name_ar: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" dir="rtl" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.ref_label')}</label>
                <input type="text" value={newProduct.reference} onChange={e => setNewProduct({...newProduct, reference: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.cost_label')}</label>
                <input type="number" value={newProduct.cost_price} onChange={e => setNewProduct({...newProduct, cost_price: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.tva_label')}</label>
                <input type="number" value={newProduct.tva} onChange={e => setNewProduct({...newProduct, tva: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.init_qty')}</label>
                <input type="number" value={newProduct.quantity} onChange={e => setNewProduct({...newProduct, quantity: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Depot</label>
                <select 
                  value={newProduct.depot_id} 
                  onChange={e => setNewProduct({...newProduct, depot_id: e.target.value})}
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white"
                >
                  <option value="">{t('warehouse.select_depot') || 'Select Depot (Default Primary)'}</option>
                  {Array.isArray(depots) && depots.map(d => (
                    <option key={d.id} value={d.id}>{d.name} {d.is_primary ? '(Primary)' : ''}</option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">{t('warehouse.min_qty')}</label>
                <input type="number" value={newProduct.minimum_quantity} onChange={e => setNewProduct({...newProduct, minimum_quantity: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
            </div>
            <div className="flex justify-end space-x-3">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 bg-slate-700 text-white rounded-lg">{t('warehouse.cancel')}</button>
              <button onClick={() => addMutation.mutate(newProduct)} disabled={!newProduct.name || addMutation.isPending} className="px-4 py-2 bg-success hover:bg-green-600 text-white rounded-lg">{t('warehouse.save')}</button>
            </div>
          </div>
        )}

        {/* Product Grid */}
        {activeTab === 'products' && (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {isLoading ? (
            Array(8).fill(0).map((_, i) => (
              <div key={i} className="glass-card h-64 animate-pulse bg-slate-800/50"></div>
            ))
          ) : (
            filteredProducts?.map(product => {
              const displayQty = selectedDepot === 'all' 
                ? product.quantity 
                : product.depots?.find(d => parseInt(d.depot_id) === parseInt(selectedDepot))?.quantity || 0;
                
              return (
              <div key={product.id} className="glass-card p-5 flex flex-col hover-card group">
                <div className="w-full h-32 bg-slate-800 rounded-lg mb-4 flex items-center justify-center text-slate-600">
                  <Package size={48} />
                </div>
                <div className="flex justify-between items-start mb-2">
                  <h3 className="text-lg font-semibold text-white truncate">
                    {i18n.language === 'fr' && product.name_fr ? product.name_fr : (i18n.language === 'ar' && product.name_ar ? product.name_ar : product.name)}
                  </h3>
                  <span className="text-xs bg-slate-800 text-slate-300 px-2 py-1 rounded">{t('warehouse.card_ref')} {product.reference}</span>
                </div>
                <div className="space-y-1 text-sm mb-4 flex-1">
                  {selectedDepot !== 'all' ? (
                    <div className="flex justify-between">
                      <span className="text-muted">{t('warehouse.card_stock')}</span>
                      <span className={`font-medium ${displayQty <= product.minimum_quantity ? 'text-danger' : 'text-success'}`}>
                        {displayQty}
                      </span>
                    </div>
                  ) : (
                    <>
                      {product.depots?.map(d => (
                        <div key={d.depot_id} className="flex justify-between">
                          <span className="text-muted">{d.depot_name} {d.is_primary ? '(Primary)' : ''}:</span>
                          <span className={`font-medium ${d.quantity <= product.minimum_quantity ? 'text-danger' : 'text-success'}`}>
                            {d.quantity}
                          </span>
                        </div>
                      ))}
                    </>
                  )}
                  <div className="flex justify-between">
                    <span className="text-muted">{t('warehouse.card_cost')}</span>
                    <span className="text-slate-300">{t('common.currency')} {Number(product.cost_price).toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted">{t('warehouse.card_tva')}</span>
                    <span className="text-slate-300">{Number(product.tva)}%</span>
                  </div>
                  <div className="flex justify-between pt-2 border-t border-slate-700/50 mt-2">
                    <span className="text-indigo-300 font-medium">{t('warehouse.card_sell')}</span>
                    <span className="text-indigo-400 font-bold">{t('common.currency')} {Number(product.selling_price).toLocaleString()}</span>
                  </div>
                  

                </div>
                <div className="flex justify-end space-x-2 opacity-0 group-hover:opacity-100 transition-opacity mt-2">
                  <button className="p-2 bg-slate-800 text-slate-300 hover:text-white rounded-lg transition-colors"><Edit size={16} /></button>
                  <button className="p-2 bg-slate-800 text-danger hover:bg-danger/20 rounded-lg transition-colors"><Trash2 size={16} /></button>
                </div>
              </div>
            )})
          )}
        </div>
        )}

        {activeTab === 'depots' && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {isDepotsLoading ? (
              Array(3).fill(0).map((_, i) => <div key={i} className="glass-card h-40 animate-pulse bg-slate-800/50"></div>)
            ) : (
              Array.isArray(depots) && depots.map(depot => (
                <div key={depot.id} className="glass-card p-5 flex flex-col hover-card group border border-slate-700/50">
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className={`p-3 rounded-xl ${depot.is_primary ? 'bg-indigo-500/20 text-indigo-400' : 'bg-slate-800 text-slate-400'}`}>
                        <Database size={24} />
                      </div>
                      <div>
                        <h3 className="text-lg font-bold text-white">{depot.name}</h3>
                        <p className="text-xs text-muted mt-1 flex items-center gap-1">
                          {depot.is_primary ? <><Check size={12} className="text-success" /> Primary (POS)</> : 'Secondary Depot'}
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="mt-auto flex justify-end gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button 
                      onClick={() => {
                        setEditingDepot(depot);
                        setNewDepot({ name: depot.name, is_primary: !!depot.is_primary, id: depot.id });
                        setShowDepotModal(true);
                      }}
                      className="p-2 bg-slate-800 text-slate-300 hover:text-white rounded-lg transition-colors"
                    >
                      <Edit size={16} />
                    </button>
                    {!depot.is_primary && (
                      <button 
                        onClick={() => {
                          if (window.confirm('Are you sure you want to delete this depot? It cannot be deleted if it contains stock.')) {
                            deleteDepotMutation.mutate(depot.id);
                          }
                        }}
                        className="p-2 bg-slate-800 text-danger hover:bg-danger/20 rounded-lg transition-colors"
                      >
                        <Trash2 size={16} />
                      </button>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        )}

        {showDepotModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex justify-center items-center z-50 p-4">
            <div className="glass-card max-w-md w-full p-6">
              <h3 className="text-xl font-bold text-white mb-4">{editingDepot ? 'Edit Depot' : 'New Depot'}</h3>
              <div className="space-y-4 mb-6">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Depot Name</label>
                  <input 
                    type="text" 
                    value={newDepot.name} 
                    onChange={e => setNewDepot({...newDepot, name: e.target.value})} 
                    className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:border-primary focus:outline-none" 
                    placeholder="e.g., Main Depot"
                  />
                </div>
                <div className="flex items-center gap-3 bg-slate-900/50 p-3 rounded-lg border border-slate-700">
                  <input 
                    type="checkbox" 
                    id="is_primary"
                    checked={newDepot.is_primary} 
                    onChange={e => setNewDepot({...newDepot, is_primary: e.target.checked})} 
                    className="w-5 h-5 rounded border-slate-600 text-primary focus:ring-primary bg-slate-800" 
                  />
                  <label htmlFor="is_primary" className="text-sm font-medium text-white cursor-pointer">
                    Set as Primary Depot
                    <p className="text-xs text-muted font-normal mt-0.5">The POS system will only sell from the primary depot.</p>
                  </label>
                </div>
              </div>
              <div className="flex justify-end gap-3">
                <button onClick={() => {setShowDepotModal(false); setEditingDepot(null);}} className="px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700 transition-colors">Cancel</button>
                <button 
                  onClick={() => depotMutation.mutate(newDepot)} 
                  disabled={!newDepot.name || depotMutation.isPending} 
                  className="px-4 py-2 bg-primary hover:bg-indigo-600 text-white rounded-lg transition-colors"
                >
                  Save Depot
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Right Summary Panel */}
      <div className="hidden xl:flex print:flex print:w-full print:h-auto print:absolute print:inset-0 print:bg-white print:z-50 w-80 glass-panel p-6 flex-col overflow-y-auto hide-scrollbar shrink-0">
        <div className="flex justify-between items-center mb-6 print:hidden">
          <h2 className="text-xl font-bold text-white">{t('warehouse.summary_title')}</h2>
          <button onClick={() => window.print()} className="p-2 bg-slate-800 hover:bg-slate-700 rounded-lg text-slate-300 hover:text-white transition-colors" title="Print Summary">
            <Printer size={18} />
          </button>
        </div>
        
        <div className="hidden print:block mb-8 text-black border-b pb-4">
          <h1 className="text-3xl font-bold mb-2">Company Warehouse Summary</h1>
          <p className="text-gray-500">Generated on {new Date().toLocaleDateString()}</p>
        </div>

        <div className="space-y-8">
          {/* Global Financials */}
          <div>
            <h3 className="text-lg font-bold text-white print:text-black mb-4">Daily Financials</h3>
            <div className="grid grid-cols-2 gap-3 print:gap-6">
              <div className="p-3 bg-cards/50 rounded-xl border border-slate-700/50 print:border-gray-300 print:bg-gray-50">
                <div className="flex items-center space-x-2 mb-2">
                  <div className="p-1.5 bg-blue-500/20 text-blue-400 rounded-lg"><TrendingUp size={16} /></div>
                  <span className="text-muted font-medium print:text-gray-700 text-xs">{t('warehouse.stat_sales')}</span>
                </div>
                <p className="text-lg font-bold text-white print:text-black">{t('common.currency')} {Number(stats?.todaysSales || 0).toLocaleString()}</p>
              </div>

              <div className="p-3 bg-cards/50 rounded-xl border border-slate-700/50 print:border-gray-300 print:bg-gray-50">
                <div className="flex items-center space-x-2 mb-2">
                  <div className="p-1.5 bg-purple-500/20 text-purple-400 rounded-lg"><HardHat size={16} /></div>
                  <span className="text-muted font-medium print:text-gray-700 text-xs">{t('warehouse.stat_usage')}</span>
                </div>
                <p className="text-lg font-bold text-white print:text-black">{t('common.currency')} {Number(stats?.todaysMaterialUsage || 0).toLocaleString()}</p>
              </div>
            </div>
          </div>

          {/* Depot Stats */}
          {depotStats.map(depot => (
            <div key={depot.id} className="pt-6 border-t border-slate-700/50 print:border-gray-300">
              <div className="flex items-center space-x-3 mb-4">
                <div className={`p-2 rounded-lg ${depot.is_primary ? 'bg-indigo-500/20 text-indigo-400' : 'bg-slate-800 text-slate-400'}`}>
                  <Database size={20} />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white print:text-black">{depot.name}</h3>
                  {depot.is_primary && <span className="text-[10px] uppercase tracking-wider font-bold text-indigo-400 bg-indigo-500/10 px-2 py-0.5 rounded mt-1 inline-block">Primary Depot</span>}
                </div>
              </div>
              
              <div className="space-y-3">
                <div className="flex gap-3 print:gap-6">
                  <div className="flex-1 p-3 bg-cards/50 rounded-xl border border-slate-700/50 print:border-gray-300 print:bg-gray-50">
                    <span className="text-muted text-xs block mb-1 print:text-gray-600">Total Items in Stock</span>
                    <p className="text-xl font-bold text-white print:text-black">{depot.totalStock.toLocaleString()}</p>
                  </div>
                </div>
                
                <div className="p-3 bg-cards/50 rounded-xl border border-slate-700/50 print:border-gray-300 print:bg-gray-50">
                  <span className="text-muted text-xs block mb-1 print:text-gray-600">Total Stock Value</span>
                  <p className="text-xl font-bold text-success print:text-black">{t('common.currency')} {depot.totalStockValue.toLocaleString()}</p>
                </div>

                <div className="grid grid-cols-2 gap-3 print:gap-6">
                  <div className="p-3 bg-cards/50 rounded-xl border border-warning/30 print:border-gray-300 print:bg-gray-50">
                    <span className="text-warning text-xs block mb-1 print:text-gray-600">Low Stock</span>
                    <p className="text-lg font-bold text-white print:text-black">{depot.lowStockProducts}</p>
                  </div>

                  <div className="p-3 bg-cards/50 rounded-xl border border-danger/30 print:border-gray-300 print:bg-gray-50">
                    <span className="text-danger text-xs block mb-1 print:text-gray-600">Out of Stock</span>
                    <p className="text-lg font-bold text-white print:text-black">{depot.outOfStockProducts}</p>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default Warehouse;
