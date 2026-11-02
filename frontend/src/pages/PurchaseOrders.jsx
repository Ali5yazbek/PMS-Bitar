import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { 
  FileText, Plus, CheckCircle, Package, Truck, AlertCircle, Trash2, 
  Building2, Layers, Calendar, DollarSign, Sparkles, X, Info, Check 
} from 'lucide-react';
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

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === 'Escape' && showAdd) {
        setShowAdd(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [showAdd]);

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
            <button 
              onClick={() => {
                setNewPO({ supplier_id: '', construction_id: '', item_name: '', quantity: '', unit_price: '', tva: 0, expected_delivery_date: '', status: 'Approved' });
                setShowAdd(true);
              }} 
              className="bg-primary hover:bg-indigo-600 px-4 py-2 rounded-lg text-white flex items-center gap-2 shadow-lg shadow-primary/20 transition-all font-medium text-sm"
            >
              <Plus size={18} /> Create PO
            </button>
          </div>
        </div>

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

      {/* Create Purchase Order - Futuristic Big Display Pop Modal */}
      {showAdd && (() => {
        const selectedSupplier = suppliers?.find(s => String(s.id) === String(newPO.supplier_id));
        const selectedProject = constructions?.find(c => String(c.id) === String(newPO.construction_id));
        const selectedMaterial = materials?.find(m => m.item_name.toLowerCase() === (newPO.item_name || '').toLowerCase());
        const detectedUnit = selectedMaterial?.unit || '';

        const poQuantity = parseFloat(newPO.quantity) || 0;
        const poUnitPrice = parseFloat(newPO.unit_price) || 0;
        const poTotal = poQuantity * poUnitPrice;

        const isFormValid = Boolean(newPO.supplier_id && newPO.construction_id && newPO.item_name?.trim() && poQuantity > 0 && poUnitPrice > 0);

        // Popular materials quick pick chips
        const popularMaterials = materials?.slice(0, 6) || [];

        return (
          <div 
            className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-slate-950/85 backdrop-blur-md animate-fadeIn"
            onClick={(e) => {
              if (e.target === e.currentTarget) setShowAdd(false);
            }}
          >
            <div className="relative w-full max-w-4xl bg-slate-900/95 border border-slate-700/80 rounded-2xl shadow-2xl shadow-indigo-950/50 flex flex-col overflow-hidden max-h-[92vh] backdrop-blur-xl">
              {/* Futuristic Top Glowing Accent Line */}
              <div className="h-1.5 w-full bg-gradient-to-r from-indigo-500 via-primary to-emerald-400"></div>

              {/* Modal Header */}
              <div className="p-5 sm:p-6 border-b border-slate-800 bg-slate-900/80 flex items-center justify-between">
                <div className="flex items-center gap-3.5">
                  <div className="p-2.5 rounded-xl bg-gradient-to-br from-indigo-500/20 to-primary/20 border border-primary/30 text-indigo-400 shadow-lg shadow-indigo-950/50">
                    <Package size={22} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <h2 className="text-xl font-bold text-white tracking-tight">Create Purchase Order</h2>
                      <span className="px-2 py-0.5 text-[10px] uppercase font-bold tracking-wider rounded-full bg-primary/20 text-indigo-300 border border-primary/30">
                        Procurement Studio
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 mt-0.5">
                      Generate official procurement contracts, link jobsite allocations, and track material logistics.
                    </p>
                  </div>
                </div>
                <button
                  onClick={() => setShowAdd(false)}
                  className="w-9 h-9 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white flex items-center justify-center transition-colors border border-slate-700/50"
                  title="Close (Esc)"
                >
                  <X size={18} />
                </button>
              </div>

              {/* Modal Scrollable Body */}
              <div className="p-5 sm:p-6 overflow-y-auto custom-scrollbar flex-1 grid grid-cols-1 lg:grid-cols-12 gap-6">
                {/* Form Inputs (7 Cols) */}
                <div className="lg:col-span-7 space-y-4">
                  {/* Step 1: Destination & Supplier */}
                  <div className="glass-card p-4 border border-slate-800 space-y-3.5">
                    <div className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                      <span className="w-5 h-5 rounded-full bg-primary/20 text-primary flex items-center justify-center text-[11px] font-bold">1</span>
                      Assignment & Entities
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
                          <Building2 size={13} className="text-primary" /> Supplier <span className="text-red-400">*</span>
                        </label>
                        <select
                          value={newPO.supplier_id}
                          onChange={e => setNewPO({...newPO, supplier_id: e.target.value})}
                          className="w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg px-3 py-2 text-white text-sm outline-none transition-colors"
                        >
                          <option value="">Select Supplier...</option>
                          {suppliers?.map(s => (
                            <option key={s.id} value={s.id}>{s.name}</option>
                          ))}
                        </select>
                        {selectedSupplier && (
                          <div className="text-[11px] text-slate-400 mt-1 flex items-center gap-2">
                            <span className="text-indigo-400 font-medium">Terms: {selectedSupplier.payment_terms_days || 30} Days</span>
                            {selectedSupplier.supplier_type && <span>• {selectedSupplier.supplier_type}</span>}
                          </div>
                        )}
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
                          <Layers size={13} className="text-primary" /> Project / Site <span className="text-red-400">*</span>
                        </label>
                        <select
                          value={newPO.construction_id}
                          onChange={e => setNewPO({...newPO, construction_id: e.target.value})}
                          className="w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg px-3 py-2 text-white text-sm outline-none transition-colors"
                        >
                          <option value="">Select Project...</option>
                          {constructions?.map(c => (
                            <option key={c.id} value={c.id}>{c.name}</option>
                          ))}
                        </select>
                        {selectedProject && (
                          <div className="text-[11px] text-emerald-400 mt-1 flex items-center gap-1">
                            <CheckCircle size={11} /> Active Construction Site
                          </div>
                        )}
                      </div>
                    </div>

                    <div>
                      <label className="block text-xs font-semibold text-slate-300 mb-1.5 flex items-center gap-1.5">
                        <Calendar size={13} className="text-primary" /> Expected Delivery Date
                      </label>
                      <input
                        type="date"
                        value={newPO.expected_delivery_date}
                        onChange={e => setNewPO({...newPO, expected_delivery_date: e.target.value})}
                        className="w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg px-3 py-2 text-white text-sm outline-none transition-colors"
                      />
                    </div>
                  </div>

                  {/* Step 2: Material & Pricing */}
                  <div className="glass-card p-4 border border-slate-800 space-y-3.5">
                    <div className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                      <span className="w-5 h-5 rounded-full bg-primary/20 text-primary flex items-center justify-center text-[11px] font-bold">2</span>
                      Material & Pricing
                    </div>

                    <div>
                      <div className="flex justify-between items-center mb-1.5">
                        <label className="text-xs font-semibold text-slate-300 flex items-center gap-1.5">
                          <Package size={13} className="text-primary" /> Material Name <span className="text-red-400">*</span>
                        </label>
                        {detectedUnit && (
                          <span className="text-[11px] bg-slate-800 text-slate-300 px-2 py-0.5 rounded border border-slate-700">
                            Unit: <strong className="text-indigo-400">{detectedUnit}</strong>
                          </span>
                        )}
                      </div>
                      <input
                        type="text"
                        list="materialsList"
                        placeholder="e.g. Portland Cement, Sand, Steel Rebar..."
                        value={newPO.item_name}
                        onChange={e => setNewPO({...newPO, item_name: e.target.value})}
                        className="w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg px-3 py-2 text-white text-sm outline-none transition-colors"
                      />
                      <datalist id="materialsList">
                        {materials?.map((m, idx) => (
                          <option key={idx} value={m.item_name} label={`${m.item_name} (${m.unit})`}>
                            {m.item_name} ({m.unit})
                          </option>
                        ))}
                      </datalist>

                      {/* Quick chips for popular materials */}
                      {popularMaterials.length > 0 && (
                        <div className="flex items-center gap-1.5 flex-wrap mt-2">
                          <span className="text-[10px] text-muted font-medium">Suggestions:</span>
                          {popularMaterials.map((mat, i) => (
                            <button
                              key={i}
                              type="button"
                              onClick={() => setNewPO({...newPO, item_name: mat.item_name})}
                              className={`text-[11px] px-2.5 py-0.5 rounded-full transition-colors border ${newPO.item_name?.toLowerCase() === mat.item_name.toLowerCase() ? 'bg-primary/30 border-primary text-white font-bold' : 'bg-slate-800/80 border-slate-700 text-slate-300 hover:bg-slate-700'}`}
                            >
                              {mat.item_name}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                          Quantity {detectedUnit && `(${detectedUnit})`} <span className="text-red-400">*</span>
                        </label>
                        <div className="relative">
                          <input
                            type="number"
                            min="0.01"
                            step="any"
                            placeholder="0.00"
                            value={newPO.quantity}
                            onChange={e => setNewPO({...newPO, quantity: e.target.value})}
                            className={`w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg pl-3 py-2 text-white text-sm outline-none transition-colors ${detectedUnit ? 'pr-16' : 'pr-3'}`}
                          />
                          {detectedUnit && (
                            <span className="absolute right-3 top-2.5 text-xs text-slate-400 font-semibold pointer-events-none">
                              {detectedUnit}
                            </span>
                          )}
                        </div>
                      </div>

                      <div>
                        <label className="block text-xs font-semibold text-slate-300 mb-1.5">
                          Unit Price (CFA) {detectedUnit && `per ${detectedUnit}`} <span className="text-red-400">*</span>
                        </label>
                        <div className="relative">
                          <input
                            type="number"
                            min="0"
                            step="any"
                            placeholder="0"
                            value={newPO.unit_price}
                            onChange={e => setNewPO({...newPO, unit_price: e.target.value})}
                            className="w-full bg-slate-800/90 border border-slate-700 focus:border-primary rounded-lg pl-3 pr-12 py-2 text-white text-sm outline-none transition-colors"
                          />
                          <span className="absolute right-3 top-2.5 text-xs text-slate-400 font-semibold pointer-events-none">
                            CFA
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Step 3: Fulfillment Status Selection */}
                  <div className="glass-card p-4 border border-slate-800 space-y-3">
                    <div className="text-xs font-bold text-slate-400 uppercase tracking-wider flex items-center gap-2">
                      <span className="w-5 h-5 rounded-full bg-primary/20 text-primary flex items-center justify-center text-[11px] font-bold">3</span>
                      Fulfillment Mode
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <button
                        type="button"
                        onClick={() => setNewPO({...newPO, status: 'Approved'})}
                        className={`p-3 rounded-xl border text-left transition-all flex items-start gap-3 ${newPO.status !== 'Delivered' ? 'bg-indigo-500/15 border-primary shadow-lg shadow-primary/10' : 'bg-slate-800/40 border-slate-700 hover:bg-slate-800/70'}`}
                      >
                        <div className={`p-2 rounded-lg ${newPO.status !== 'Delivered' ? 'bg-primary text-white' : 'bg-slate-800 text-slate-400'}`}>
                          <Truck size={18} />
                        </div>
                        <div>
                          <div className="text-sm font-bold text-white flex items-center gap-1.5">
                            On the Way
                            {newPO.status !== 'Delivered' && <span className="w-2 h-2 rounded-full bg-primary animate-ping"></span>}
                          </div>
                          <div className="text-xs text-slate-400 mt-0.5">Dispatches order to supplier; delivery to be verified.</div>
                        </div>
                      </button>

                      <button
                        type="button"
                        onClick={() => setNewPO({...newPO, status: 'Delivered'})}
                        className={`p-3 rounded-xl border text-left transition-all flex items-start gap-3 ${newPO.status === 'Delivered' ? 'bg-emerald-500/15 border-emerald-500 shadow-lg shadow-emerald-950/20' : 'bg-slate-800/40 border-slate-700 hover:bg-slate-800/70'}`}
                      >
                        <div className={`p-2 rounded-lg ${newPO.status === 'Delivered' ? 'bg-emerald-500 text-white' : 'bg-slate-800 text-slate-400'}`}>
                          <CheckCircle size={18} />
                        </div>
                        <div>
                          <div className="text-sm font-bold text-white flex items-center gap-1.5">
                            Immediate Delivery
                            {newPO.status === 'Delivered' && <span className="w-2 h-2 rounded-full bg-emerald-400"></span>}
                          </div>
                          <div className="text-xs text-slate-400 mt-0.5">Goods already received; immediately logs site stock.</div>
                        </div>
                      </button>
                    </div>
                  </div>
                </div>

                {/* Right: Futuristic Live HUD & Estimation Panel (5 Cols) */}
                <div className="lg:col-span-5 flex flex-col justify-between">
                  <div className="glass-card p-5 border border-slate-800 bg-slate-950/70 relative overflow-hidden flex-1 flex flex-col justify-between">
                    <div className="absolute -right-8 -top-8 w-36 h-36 bg-primary/10 rounded-full blur-2xl pointer-events-none"></div>

                    <div>
                      <div className="flex items-center justify-between text-xs font-bold text-slate-400 uppercase tracking-wider mb-4 pb-3 border-b border-slate-800/80">
                        <span className="flex items-center gap-1.5">
                          <Sparkles size={14} className="text-primary animate-pulse" /> Live Valuation HUD
                        </span>
                        <span className="px-2 py-0.5 rounded text-[10px] bg-slate-800 text-slate-300 font-mono">
                          ESTIMATION
                        </span>
                      </div>

                      {/* Giant Price Block */}
                      <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-4 mb-4 text-center shadow-inner">
                        <div className="text-xs text-slate-400 uppercase tracking-wider mb-1 font-semibold">Total Order Value</div>
                        <div className="text-3xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-emerald-500">
                          CFA {poTotal.toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 2 })}
                        </div>
                        <div className="text-xs text-slate-400 mt-1.5 font-mono">
                          {poQuantity > 0 && poUnitPrice > 0
                            ? `${Number(poQuantity).toLocaleString()} ${detectedUnit || 'units'} × CFA ${Number(poUnitPrice).toLocaleString()}`
                            : 'Enter quantity & unit price to calculate'}
                        </div>
                      </div>

                      {/* Specs Telemetry */}
                      <div className="space-y-2.5 text-xs">
                        <div className="flex justify-between items-center py-1.5 border-b border-slate-800/60">
                          <span className="text-slate-400">Supplier:</span>
                          <span className="font-semibold text-white truncate max-w-[180px]">
                            {selectedSupplier?.name || <em className="text-slate-500">Not selected</em>}
                          </span>
                        </div>
                        <div className="flex justify-between items-center py-1.5 border-b border-slate-800/60">
                          <span className="text-slate-400">Project / Site:</span>
                          <span className="font-semibold text-white truncate max-w-[180px]">
                            {selectedProject?.name || <em className="text-slate-500">Not selected</em>}
                          </span>
                        </div>
                        <div className="flex justify-between items-center py-1.5 border-b border-slate-800/60">
                          <span className="text-slate-400">Material:</span>
                          <span className="font-semibold text-indigo-300 truncate max-w-[180px]">
                            {newPO.item_name || <em className="text-slate-500">Not entered</em>}
                          </span>
                        </div>
                        <div className="flex justify-between items-center py-1.5 border-b border-slate-800/60">
                          <span className="text-slate-400">Initial Status:</span>
                          <span className={`px-2 py-0.5 rounded text-[10px] uppercase font-bold ${newPO.status === 'Delivered' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-primary/20 text-indigo-300'}`}>
                            {newPO.status === 'Delivered' ? 'Delivered' : 'On the Way'}
                          </span>
                        </div>
                        <div className="flex justify-between items-center py-1.5 border-b border-slate-800/60">
                          <span className="text-slate-400">Expected Delivery:</span>
                          <span className="font-semibold text-slate-300">
                            {newPO.expected_delivery_date || 'Standard'}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Readiness Checklist */}
                    <div className="mt-5 pt-4 border-t border-slate-800/80">
                      <div className="text-[11px] font-bold text-slate-400 uppercase tracking-wider mb-2">Order Readiness</div>
                      <div className="space-y-1.5 text-xs">
                        <div className={`flex items-center gap-2 ${newPO.supplier_id ? 'text-emerald-400' : 'text-slate-500'}`}>
                          <Check size={14} className={newPO.supplier_id ? 'text-emerald-400' : 'text-slate-600'} />
                          <span>Supplier selected</span>
                        </div>
                        <div className={`flex items-center gap-2 ${newPO.construction_id ? 'text-emerald-400' : 'text-slate-500'}`}>
                          <Check size={14} className={newPO.construction_id ? 'text-emerald-400' : 'text-slate-600'} />
                          <span>Construction site designated</span>
                        </div>
                        <div className={`flex items-center gap-2 ${newPO.item_name?.trim() ? 'text-emerald-400' : 'text-slate-500'}`}>
                          <Check size={14} className={newPO.item_name?.trim() ? 'text-emerald-400' : 'text-slate-600'} />
                          <span>Material specified</span>
                        </div>
                        <div className={`flex items-center gap-2 ${poQuantity > 0 && poUnitPrice > 0 ? 'text-emerald-400' : 'text-slate-500'}`}>
                          <Check size={14} className={poQuantity > 0 && poUnitPrice > 0 ? 'text-emerald-400' : 'text-slate-600'} />
                          <span>Quantity & pricing populated</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Modal Footer Action Bar */}
              <div className="p-4 sm:p-5 border-t border-slate-800 bg-slate-900/95 flex flex-col sm:flex-row justify-between items-center gap-3">
                <div className="text-xs text-slate-400 flex items-center gap-2">
                  <Info size={15} className="text-primary shrink-0" />
                  <span>Automatically logs supplier debt, transaction history, and procurement tracking.</span>
                </div>
                <div className="flex items-center gap-3 w-full sm:w-auto justify-end">
                  <button
                    type="button"
                    onClick={() => setShowAdd(false)}
                    className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 hover:text-white rounded-lg text-sm font-medium transition-colors border border-slate-700/50"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    disabled={!isFormValid || addMutation.isPending}
                    onClick={() => {
                      if (!isFormValid) {
                        alert('Please fill all required fields: Supplier, Project, Material, Quantity, and Unit Price.');
                        return;
                      }
                      addMutation.mutate({...newPO, status: newPO.status || 'Approved'});
                    }}
                    className="px-5 py-2.5 bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white rounded-lg font-semibold text-sm shadow-lg shadow-emerald-950/30 flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                  >
                    <Plus size={16} />
                    {addMutation.isPending ? 'Generating PO...' : 'Create Purchase Order'}
                  </button>
                </div>
              </div>
            </div>
          </div>
        );
      })()}
    </div>
  );
};

export default PurchaseOrders;
