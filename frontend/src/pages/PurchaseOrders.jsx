import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { FileText, Plus, CheckCircle, Package, Truck, AlertCircle, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const PurchaseOrders = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [showAdd, setShowAdd] = useState(false);
  const [newPO, setNewPO] = useState({
    supplier_id: '', construction_id: '', item_name: '', quantity: '', unit_price: '', tva: 0, expected_delivery_date: ''
  });
  const [deliveryQty, setDeliveryQty] = useState('');
  const [returnQty, setReturnQty] = useState('');
  const [selectedPO, setSelectedPO] = useState(null);
  const [fromDate, setFromDate] = useState('');
  const [toDate, setToDate] = useState('');

  const { data: pos, isLoading } = useQuery({
    queryKey: ['purchaseOrders'],
    queryFn: async () => {
      const res = await axios.get('/purchase-orders');
      return res.data;
    }
  });

  const { data: suppliers } = useQuery({
    queryKey: ['suppliers'],
    queryFn: async () => {
      const res = await axios.get('/suppliers');
      return res.data;
    }
  });

  const { data: constructions } = useQuery({
    queryKey: ['constructions'],
    queryFn: async () => {
      const res = await axios.get('/constructions');
      return res.data;
    }
  });

  const { data: materials } = useQuery({
    queryKey: ['constructionMaterials'],
    queryFn: async () => {
      const res = await axios.get('/construction-materials');
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (data) => axios.post('/purchase-orders', data),
    onSuccess: (res) => {
      if (newPO.status === 'Delivered') {
        deliverMutation.mutate({ id: res.data.id, quantity: newPO.quantity });
      }
      queryClient.invalidateQueries(['purchaseOrders']);
      setShowAdd(false);
      setNewPO({ supplier_id: '', construction_id: '', item_name: '', quantity: '', unit_price: '', tva: 0, expected_delivery_date: '', status: 'Approved' });
    }
  });

  const deliverMutation = useMutation({
    mutationFn: ({ id, quantity }) => axios.post(`/purchase-orders/${id}/deliver`, { quantity }),
    onSuccess: () => {
      queryClient.invalidateQueries(['purchaseOrders']);
      setSelectedPO(null);
      setDeliveryQty('');
    }
  });

  const returnMutation = useMutation({
    mutationFn: ({ id, quantity }) => axios.post(`/purchase-orders/${id}/return`, { quantity }),
    onSuccess: () => {
      queryClient.invalidateQueries(['purchaseOrders']);
      setSelectedPO(null);
      setReturnQty('');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to return materials');
    }
  });

  const statusMutation = useMutation({
    mutationFn: ({ id, status }) => axios.put(`/purchase-orders/${id}/status`, { status }),
    onSuccess: () => queryClient.invalidateQueries(['purchaseOrders'])
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => axios.delete(`/purchase-orders/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['purchaseOrders']);
      setSelectedPO(null);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to delete PO');
    }
  });

  const getStatusColor = (status) => {
    switch(status) {
      case 'Draft': return 'bg-slate-500/20 text-slate-400';
      case 'Pending Approval': return 'bg-amber-500/20 text-amber-500';
      case 'Approved': return 'bg-indigo-500/20 text-indigo-400';
      case 'Partially Delivered': return 'bg-blue-500/20 text-blue-400';
      case 'Delivered': return 'bg-emerald-500/20 text-emerald-400';
      case 'Cancelled': return 'bg-red-500/20 text-red-400';
      default: return 'bg-slate-500/20 text-slate-400';
    }
  };

  const filteredPOs = pos?.filter(po => {
    let match = true;
    if (fromDate && new Date(po.created_at) < new Date(fromDate)) match = false;
    if (toDate && new Date(po.created_at) > new Date(toDate + 'T23:59:59')) match = false;
    return match;
  });

  const totalAmount = filteredPOs?.reduce((sum, po) => sum + parseFloat(po.total_price || 0), 0) || 0;

  return (
    <div className="flex h-full w-full gap-6 p-6 print:p-0 print:block">
      {/* Print Header */}
      <div className="hidden print:block w-full text-black mb-8 border-b-2 border-black pb-4">
        <h2 className="text-3xl font-bold mb-1">Purchase Orders Report</h2>
        <p className="text-gray-700">Reporting Period: <span className="font-bold">{fromDate || 'All Time'}</span> to <span className="font-bold">{toDate || 'Present'}</span></p>
      </div>

      <div className="flex-1 flex flex-col glass-panel p-6 overflow-hidden print:p-0 print:border-none print:shadow-none print:bg-transparent">
        <div className="flex justify-between items-center mb-6 print:hidden">
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <FileText className="text-primary" /> Purchase Orders
          </h1>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2 bg-slate-800 rounded-lg px-3 py-1">
              <span className="text-xs text-slate-400 font-bold uppercase">From</span>
              <input type="date" value={fromDate} onChange={e => setFromDate(e.target.value)} className="bg-transparent text-white text-sm outline-none" />
              <span className="text-xs text-slate-400 font-bold uppercase ml-2">To</span>
              <input type="date" value={toDate} onChange={e => setToDate(e.target.value)} className="bg-transparent text-white text-sm outline-none" />
            </div>
            <button onClick={() => window.print()} className="bg-slate-700 hover:bg-slate-600 px-4 py-2 rounded-lg text-white flex items-center gap-2 transition-colors">
              <FileText size={18} /> Print
            </button>
            <button onClick={() => setShowAdd(!showAdd)} className="bg-primary hover:bg-indigo-600 px-4 py-2 rounded-lg text-white flex items-center gap-2">
              <Plus size={18} /> Create PO
            </button>
          </div>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-6">
            <h3 className="text-lg font-bold text-white mb-4">New Purchase Order</h3>
            <div className="grid grid-cols-3 gap-4 mb-4 text-sm">
              <div>
                <label className="block text-muted mb-1">Supplier</label>
                <select value={newPO.supplier_id} onChange={e => setNewPO({...newPO, supplier_id: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                  <option value="">Select Supplier...</option>
                  {suppliers?.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-muted mb-1">Project</label>
                <select value={newPO.construction_id} onChange={e => setNewPO({...newPO, construction_id: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                  <option value="">Select Project...</option>
                  {constructions?.map(c => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              </div>
              <div>
                <label className="block text-muted mb-1">Material Name</label>
                <input type="text" list="materialsList" value={newPO.item_name} onChange={e => setNewPO({...newPO, item_name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
                <datalist id="materialsList">
                  {materials?.map((m, idx) => <option key={idx} value={m.item_name} label={`${m.item_name} (${m.unit})`}>{m.item_name} ({m.unit})</option>)}
                </datalist>
              </div>
              {(() => {
                const selectedMaterial = materials?.find(m => m.item_name.toLowerCase() === (newPO.item_name || '').toLowerCase());
                const unit = selectedMaterial ? selectedMaterial.unit : '';
                return (
                  <>
                    <div>
                      <label className="block text-muted mb-1">Quantity {unit && `(${unit})`}</label>
                      <div className="relative">
                        <input type="number" value={newPO.quantity} onChange={e => setNewPO({...newPO, quantity: e.target.value})} className={`w-full bg-slate-800 border border-slate-700 rounded-lg pl-3 py-2 text-white ${unit ? 'pr-16' : 'pr-3'}`} />
                        {unit && <span className="absolute right-3 top-2.5 text-slate-400 font-medium text-sm">{unit}</span>}
                      </div>
                    </div>
                    <div>
                      <label className="block text-muted mb-1">Unit Price (CFA) {unit && `per ${unit}`}</label>
                      <input type="number" value={newPO.unit_price} onChange={e => setNewPO({...newPO, unit_price: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
                    </div>
                  </>
                );
              })()}
              <div>
                <label className="block text-muted mb-1">Expected Delivery</label>
                <input type="date" value={newPO.expected_delivery_date} onChange={e => setNewPO({...newPO, expected_delivery_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-muted mb-1">Status</label>
                <select value={newPO.status || 'Approved'} onChange={e => setNewPO({...newPO, status: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                  <option value="Approved">On the Way</option>
                  <option value="Delivered">Delivered</option>
                </select>
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 bg-slate-700 text-white rounded-lg">Cancel</button>
              <button onClick={() => {
                if (!newPO.supplier_id || !newPO.construction_id || !newPO.item_name || !newPO.quantity) {
                  alert('Please select a Supplier, Project, Material, and Quantity.');
                  return;
                }
                addMutation.mutate({...newPO, status: newPO.status || 'Approved'});
              }} className="px-4 py-2 bg-success text-white rounded-lg">Create PO</button>
            </div>
          </div>
        )}

        <div className="flex-1 overflow-y-auto pr-2 custom-scrollbar print:overflow-visible print:pr-0">
          <table className="w-full text-left border-collapse print:border print:border-gray-300">
            <thead>
              <tr className="border-b border-slate-700 text-slate-400 text-sm print:bg-gray-100 print:text-black print:border-gray-300">
                <th className="py-3 font-medium print:px-3 print:py-2 print:border-r print:border-gray-300">PO Number</th>
                <th className="py-3 font-medium print:px-3 print:py-2 print:border-r print:border-gray-300">Project</th>
                <th className="py-3 font-medium print:px-3 print:py-2 print:border-r print:border-gray-300">Supplier</th>
                <th className="py-3 font-medium print:px-3 print:py-2 print:border-r print:border-gray-300">Material</th>
                <th className="py-3 font-medium print:px-3 print:py-2 print:border-r print:border-gray-300">Progress</th>
                <th className="py-3 font-medium print:px-3 print:py-2">Status</th>
                <th className="py-3 font-medium text-right print:hidden">Actions</th>
              </tr>
            </thead>
            <tbody>
              {isLoading ? <tr><td colSpan="7" className="text-center py-4 text-muted">Loading...</td></tr> : filteredPOs?.map(po => (
                <tr key={po.id} className="border-b border-slate-800/50 hover:bg-slate-800/30 transition-colors print:border-gray-300">
                  <td className="py-3 text-white font-medium print:text-black print:px-3 print:py-2 print:border-r print:border-gray-300">{po.po_number}</td>
                  <td className="py-3 text-slate-300 print:text-black print:px-3 print:py-2 print:border-r print:border-gray-300">{po.construction_name}</td>
                  <td className="py-3 text-slate-300 print:text-black print:px-3 print:py-2 print:border-r print:border-gray-300">{po.supplier_name}</td>
                  <td className="py-3 print:px-3 print:py-2 print:border-r print:border-gray-300">
                    <div className="text-white print:text-black print:font-bold">{po.item_name}</div>
                    <div className="text-xs text-muted print:text-gray-600">CFA {po.total_price}</div>
                  </td>
                  <td className="py-3 print:px-3 print:py-2 print:border-r print:border-gray-300">
                    <div className="text-xs text-slate-400 mb-1 print:text-black">{po.quantity_delivered} / {po.quantity_ordered} Delivered</div>
                    <div className="w-24 h-1.5 bg-slate-800 rounded-full overflow-hidden print:hidden">
                      <div className="h-full bg-primary" style={{ width: `${(po.quantity_delivered / po.quantity_ordered) * 100}%` }}></div>
                    </div>
                  </td>
                  <td className="py-3 print:px-3 print:py-2">
                    <span className={`px-2 py-1 rounded text-xs font-medium print:bg-transparent print:text-black print:p-0 ${getStatusColor(po.status)}`}>
                      {po.status}
                    </span>
                  </td>
                  <td className="py-3 text-right print:hidden">
                    <button onClick={() => setSelectedPO(po)} className="text-xs bg-slate-700 hover:bg-slate-600 text-white px-3 py-1.5 rounded transition-colors">
                      Manage
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
            <tfoot>
              <tr className="border-t-2 border-slate-700 bg-slate-800/50 print:bg-gray-100 print:border-gray-400">
                <td colSpan="3" className="py-4 px-3 font-bold text-right text-white print:text-black print:border-r print:border-gray-400">Grand Total:</td>
                <td className="py-4 px-3 font-bold text-success print:text-black print:border-r print:border-gray-400">CFA {totalAmount.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                <td colSpan="3" className="print:hidden"></td>
                <td colSpan="2" className="hidden print:table-cell"></td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>

      {selectedPO && (() => {
        const currentPO = pos?.find(p => p.id === selectedPO.id) || selectedPO;
        return (
        <div className="w-80 glass-panel p-6 flex flex-col print:hidden">
          <div className="flex justify-between items-center mb-6">
            <h2 className="text-lg font-bold text-white">Manage PO</h2>
            <button onClick={() => setSelectedPO(null)} className="text-slate-500 hover:text-white">✕</button>
          </div>
          
          <div className="space-y-4 text-sm">
            <div className="glass-card p-4">
              <div className="text-muted mb-1">Current Status</div>
              <div className={`px-3 py-2 rounded font-medium text-center ${getStatusColor(currentPO.status)}`}>{currentPO.status}</div>
              
              {parseFloat(currentPO.quantity_delivered || 0) === 0 && (
                <div className="mt-3 flex gap-2">
                  <button onClick={() => {
                    if (window.confirm('Are you sure you want to delete this PO?')) {
                      deleteMutation.mutate(currentPO.id);
                    }
                  }} className="flex-1 bg-red-500/20 text-red-500 hover:bg-red-500/30 py-2 rounded transition-colors flex justify-center items-center gap-2">
                    <Trash2 size={16} /> Delete PO
                  </button>
                </div>
              )}
              
              {currentPO.status === 'Draft' && (
                <div className="mt-3 flex gap-2">
                  <button onClick={() => statusMutation.mutate({ id: currentPO.id, status: 'Pending Approval' })} className="flex-1 bg-amber-500/20 text-amber-500 hover:bg-amber-500/30 py-2 rounded transition-colors">Request Approval</button>
                </div>
              )}
              {currentPO.status === 'Pending Approval' && (
                <div className="mt-3 flex gap-2">
                  <button onClick={() => statusMutation.mutate({ id: currentPO.id, status: 'Approved' })} className="flex-1 bg-success/20 text-success hover:bg-success/30 py-2 rounded transition-colors">Approve</button>
                  <button onClick={() => statusMutation.mutate({ id: currentPO.id, status: 'Rejected' })} className="flex-1 bg-red-500/20 text-red-500 hover:bg-red-500/30 py-2 rounded transition-colors">Reject</button>
                </div>
              )}
            </div>

            {(currentPO.status === 'Approved' || currentPO.status === 'Partially Delivered') && (
              <div className="glass-card p-4 border-primary/30">
                <h3 className="text-white font-medium mb-3 flex items-center gap-2"><Truck size={16} className="text-primary"/> Record Delivery</h3>
                <div className="mb-3 text-muted text-xs">
                  Remaining: <span className="text-white font-bold">{currentPO.quantity_remaining}</span>
                </div>
                <div className="flex gap-2">
                  <input type="number" placeholder="Qty Delivered" value={deliveryQty} onChange={e => setDeliveryQty(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded px-2 py-1.5 text-white" />
                  <button onClick={() => deliverMutation.mutate({ id: currentPO.id, quantity: deliveryQty })} disabled={!deliveryQty} className="bg-primary hover:bg-indigo-600 text-white px-3 rounded">Save</button>
                </div>
                <p className="text-[10px] text-slate-500 mt-2 flex items-start gap-1">
                  <AlertCircle size={12} className="shrink-0" />
                  Recording delivery will instantly add materials to the Construction Site Stock and log the cost.
                </p>
              </div>
            )}

            {(parseFloat(currentPO.quantity_delivered || 0) > 0) && (
              <div className="glass-card p-4 border-red-500/30 mt-4">
                <h3 className="text-white font-medium mb-3 flex items-center gap-2"><Trash2 size={16} className="text-red-400"/> Return Materials</h3>
                <div className="mb-3 text-muted text-xs">
                  Delivered: <span className="text-white font-bold">{currentPO.quantity_delivered}</span>
                </div>
                <div className="flex gap-2">
                  <input type="number" placeholder="Qty to Return" value={returnQty} onChange={e => setReturnQty(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded px-2 py-1.5 text-white" />
                  <button onClick={() => returnMutation.mutate({ id: currentPO.id, quantity: returnQty })} disabled={!returnQty} className="bg-red-500 hover:bg-red-600 text-white px-3 rounded">Return</button>
                </div>
                <p className="text-[10px] text-slate-500 mt-2 flex items-start gap-1">
                  <AlertCircle size={12} className="shrink-0" />
                  Returning materials will subtract from Construction Site Stock and deduct project expenses.
                </p>
              </div>
            )}
          </div>
        </div>
        );
      })()}
    </div>
  );
};

export default PurchaseOrders;
