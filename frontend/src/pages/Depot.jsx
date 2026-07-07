import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { Package, Plus, Search, Archive, TrendingUp, AlertTriangle } from 'lucide-react';

const Depot = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const [modal, setModal] = useState(null); // 'new_item' or { type: 'IN', item_id } or { type: 'OUT', item_id }
  const [formData, setFormData] = useState({});
  const [searchTerm, setSearchTerm] = useState('');

  const { data: items, isLoading } = useQuery({ queryKey: ['inventoryItems'], queryFn: async () => (await api.get('/inventory')).data });
  const { data: purchaseReqs } = useQuery({ queryKey: ['purchaseRequests'], queryFn: async () => (await api.get('/inventory/purchase_requests')).data });

  const itemMutation = useMutation({
    mutationFn: (data) => api.post('/inventory', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['inventoryItems']);
      setModal(null);
      setFormData({});
    }
  });

  const txMutation = useMutation({
    mutationFn: (data) => api.post('/inventory/transaction', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['inventoryItems']);
      setModal(null);
      setFormData({});
    }
  });

  if (isLoading) return <div>{t('depot.loading', { defaultValue: `Loading...` })}</div>;

  const lowStockItems = items?.filter(item => Number(item.current_stock) <= Number(item.min_stock));
  const displayedItems = items?.filter(item => item.name.toLowerCase().includes(searchTerm.toLowerCase()));

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-100">
        <div className="flex items-center gap-3">
          <div className="bg-blue-100 p-3 rounded-lg text-blue-600">
            <Archive size={24} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-800">{t('depot.depot_inventory', { defaultValue: `Depot & Inventory` })}</h1>
            <p className="text-slate-500 text-sm">{t('depot.manage_construction_materials_', { defaultValue: `Manage construction materials and stock levels` })}</p>
          </div>
        </div>
        <button 
          onClick={() => setModal('new_item')}
          className="bg-blue-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 hover:bg-blue-700 font-medium"
        >
          <Plus size={20} /> {t('depot.add_new_material', { defaultValue: `Add New Material` })}
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-slate-500">{t('depot.total_unique_items', { defaultValue: `Total Unique Items` })}</p>
              <h3 className="text-2xl font-bold text-slate-800 mt-1">{items?.length || 0}</h3>
            </div>
            <div className="p-3 bg-blue-50 rounded-lg text-blue-600"><Package size={24} /></div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-slate-500">{t('depot.low_stock_alerts', { defaultValue: `Low Stock Alerts` })}</p>
              <h3 className="text-2xl font-bold text-slate-800 mt-1">{lowStockItems?.length || 0}</h3>
            </div>
            <div className="p-3 bg-red-50 rounded-lg text-red-600"><AlertTriangle size={24} /></div>
          </div>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
          <div className="flex justify-between items-start">
            <div>
              <p className="text-sm font-medium text-slate-500">{t('depot.pending_purchase_requests', { defaultValue: `Pending Purchase Requests` })}</p>
              <h3 className="text-2xl font-bold text-slate-800 mt-1">{purchaseReqs?.filter(pr => pr.status === 'Pending').length || 0}</h3>
            </div>
            <div className="p-3 bg-amber-50 rounded-lg text-amber-600"><TrendingUp size={24} /></div>
          </div>
        </div>
      </div>

      <div className="bg-white p-4 rounded-xl shadow-sm border border-slate-100 flex gap-4">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
          <input 
            type="text" 
            placeholder={t('depot.search_inventory_items', { defaultValue: `Search inventory items...` })} 
            value={searchTerm}
            onChange={e => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">{t('depot.item_name', { defaultValue: `Item Name` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">{t('depot.category', { defaultValue: `Category` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">{t('depot.current_stock', { defaultValue: `Current Stock` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">{t('depot.unit_cost', { defaultValue: `Unit Cost` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase">{t('depot.total_value', { defaultValue: `Total Value` })}</th>
              <th className="px-6 py-4 text-right text-xs font-semibold text-slate-500 uppercase">{t('depot.actions', { defaultValue: `Actions` })}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {displayedItems?.map(item => {
              const isLowStock = Number(item.current_stock) <= Number(item.min_stock);
              return (
                <tr key={item.id} className="hover:bg-slate-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="font-medium text-slate-900">{item.name}</div>
                    {isLowStock && <span className="inline-flex items-center gap-1 text-xs text-red-600 font-medium mt-1"><AlertTriangle size={12}/> {t('depot.low_stock', { defaultValue: `Low Stock` })}</span>}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-600">{item.category}</td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`font-bold ${isLowStock ? 'text-red-600' : 'text-slate-900'}`}>
                      {item.current_stock}
                    </span>
                    <span className="text-slate-500 ml-1 text-sm">{item.unit}</span>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-slate-600">{t('depot.cfa', { defaultValue: `CFA` })} {item.unit_cost}</td>
                  <td className="px-6 py-4 whitespace-nowrap font-medium text-slate-900">
                    {t('depot.cfa', { defaultValue: `CFA` })} {(Number(item.current_stock) * Number(item.unit_cost)).toLocaleString()}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right space-x-2">
                    <button 
                      onClick={() => setModal({ type: 'IN', item_id: item.id })}
                      className="text-green-600 bg-green-50 px-3 py-1 rounded hover:bg-green-100 font-medium text-sm"
                    >
                      {t('depot.add_stock', { defaultValue: `+ Add Stock` })}
                    </button>
                    <button 
                      onClick={() => setModal({ type: 'OUT', item_id: item.id })}
                      className="text-amber-600 bg-amber-50 px-3 py-1 rounded hover:bg-amber-100 font-medium text-sm"
                    >
                      {t('depot.deduct', { defaultValue: `- Deduct` })}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {modal === 'new_item' && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-xl shadow-xl w-full max-w-md">
            <h3 className="text-xl font-bold mb-4">{t('depot.add_new_material', { defaultValue: `Add New Material` })}</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.material_name', { defaultValue: `Material Name` })}</label>
                <input type="text" className="w-full border rounded-lg px-3 py-2" value={formData.name || ''} onChange={e => setFormData({...formData, name: e.target.value})} placeholder={t('depot.e_g_portland_cement', { defaultValue: `e.g., Portland Cement` })} />
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.category', { defaultValue: `Category` })}</label>
                  <input type="text" className="w-full border rounded-lg px-3 py-2" value={formData.category || ''} onChange={e => setFormData({...formData, category: e.target.value})} placeholder={t('depot.e_g_raw_material', { defaultValue: `e.g., Raw Material` })} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.unit', { defaultValue: `Unit` })}</label>
                  <input type="text" className="w-full border rounded-lg px-3 py-2" value={formData.unit || ''} onChange={e => setFormData({...formData, unit: e.target.value})} placeholder={t('depot.e_g_ton_bag_m2', { defaultValue: `e.g., Ton, Bag, m2` })} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.initial_stock', { defaultValue: `Initial Stock` })}</label>
                  <input type="number" className="w-full border rounded-lg px-3 py-2" value={formData.current_stock || ''} onChange={e => setFormData({...formData, current_stock: e.target.value})} />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.min_stock_alert', { defaultValue: `Min Stock Alert` })}</label>
                  <input type="number" className="w-full border rounded-lg px-3 py-2" value={formData.min_stock || ''} onChange={e => setFormData({...formData, min_stock: e.target.value})} />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.unit_cost_cfa', { defaultValue: `Unit Cost (CFA)` })}</label>
                <input type="number" className="w-full border rounded-lg px-3 py-2" value={formData.unit_cost || ''} onChange={e => setFormData({...formData, unit_cost: e.target.value})} />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => itemMutation.mutate(formData)} className="bg-blue-600 text-white px-4 py-2 rounded-lg flex-1">{t('depot.save_material', { defaultValue: `Save Material` })}</button>
              <button onClick={() => { setModal(null); setFormData({}); }} className="bg-slate-200 text-slate-800 px-4 py-2 rounded-lg">{t('depot.cancel', { defaultValue: `Cancel` })}</button>
            </div>
          </div>
        </div>
      )}

      {modal?.type && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white p-6 rounded-xl shadow-xl w-full max-w-md">
            <h3 className="text-xl font-bold mb-4">{modal.type === 'IN' ? 'Add Stock' : 'Deduct Stock'}</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.quantity', { defaultValue: `Quantity` })}</label>
                <input type="number" className="w-full border rounded-lg px-3 py-2" value={formData.quantity || ''} onChange={e => setFormData({...formData, quantity: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">{t('depot.notes_reason', { defaultValue: `Notes / Reason` })}</label>
                <input type="text" className="w-full border rounded-lg px-3 py-2" value={formData.notes || ''} onChange={e => setFormData({...formData, notes: e.target.value})} placeholder={modal.type === 'OUT' ? 'e.g., Used for Galaxy project' : 'e.g., Delivery from Supplier X'} />
              </div>
            </div>
            <div className="flex gap-3 mt-6">
              <button onClick={() => txMutation.mutate({ ...formData, type: modal.type, item_id: modal.item_id })} className="bg-blue-600 text-white px-4 py-2 rounded-lg flex-1">{t('depot.confirm', { defaultValue: `Confirm` })}</button>
              <button onClick={() => { setModal(null); setFormData({}); }} className="bg-slate-200 text-slate-800 px-4 py-2 rounded-lg">{t('depot.cancel', { defaultValue: `Cancel` })}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Depot;
