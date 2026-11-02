import React, { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { X, Save, Building, Home, CreditCard, RotateCcw, AlertTriangle, Printer, Trash2, Plus, Minus, History, Edit2, Clock, CheckCircle } from 'lucide-react';
import PrintLogo from '../components/PrintLogo';

// ----------------------------------------------------------------------
// View Invoice Modal (with Timeline)
// ----------------------------------------------------------------------
export const InvoiceViewModal = ({ invoice, onClose }) => {
  const { data: timeline } = useQuery({
    queryKey: ['salesTimeline', invoice.id],
    queryFn: async () => (await api.get(`/sales/timeline/${invoice.id}`)).data
  });

  const { data: returns } = useQuery({
    queryKey: ['salesReturns', invoice.id],
    queryFn: async () => (await api.get(`/sales/returns/${invoice.id}`)).data
  });

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="glass-card w-full max-w-5xl h-[90vh] flex flex-col border border-slate-700 animate-in zoom-in-95" onClick={e=>e.stopPropagation()}>
        <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            Invoice #{invoice.invoice_number}
            <span className={`px-2 py-0.5 text-xs rounded border ${
              invoice.status === 'Returned' ? 'border-danger text-danger bg-danger/10' :
              invoice.status === 'Partial Return' ? 'border-warning text-warning bg-warning/10' :
              'border-success text-success bg-success/10'
            }`}>{invoice.status}</span>
          </h2>
          <div className="flex gap-2">
            <button onClick={handlePrint} className="p-2 bg-slate-700 hover:bg-slate-600 rounded text-white flex gap-2 items-center"><Printer size={18} /> Print</button>
            <button onClick={onClose} className="p-2 bg-slate-700 hover:bg-slate-600 rounded text-slate-300"><X size={18} /></button>
          </div>
        </div>

        <div className="flex-1 overflow-hidden flex flex-col md:flex-row print:hidden">
          
          <div className="flex-1 overflow-y-auto p-6 space-y-6 hide-scrollbar border-r border-slate-700/50">
            {/* Invoice Info */}
            <div className="grid grid-cols-2 gap-4">
              <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                <p className="text-sm text-slate-400 mb-1">Entity / Client</p>
                <p className="font-bold text-white">{invoice.customer_name || 'Walk-In Customer'} ({invoice.customer_type})</p>
                <p className="text-sm text-slate-400 mt-2">Date & Time</p>
                <p className="font-medium text-white">{invoice.date} {invoice.invoice_time}</p>
                <p className="text-sm text-slate-400 mt-2">Payment</p>
                <p className="font-medium text-white">{invoice.payment_type}</p>
              </div>
              <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50 flex flex-col justify-center items-end">
                <p className="text-sm text-slate-400 mb-1">Final Amount</p>
                <p className="text-2xl font-bold text-emerald-400">CFA {Number(invoice.final_amount).toLocaleString()}</p>
                {Number(invoice.returned_amount) > 0 && (
                  <p className="text-sm text-danger mt-1">Returned: CFA {Number(invoice.returned_amount).toLocaleString()}</p>
                )}
                {Number(invoice.discount) > 0 && (
                  <p className="text-sm text-warning mt-1">Discount: CFA {Number(invoice.discount).toLocaleString()}</p>
                )}
                {Number(invoice.tax) > 0 && (
                  <p className="text-sm text-slate-300 mt-1">Tax: CFA {Number(invoice.tax).toLocaleString()}</p>
                )}
              </div>
            </div>

            {/* Items Table */}
            <div className="border border-slate-700 rounded-xl overflow-hidden">
              <table className="w-full text-left">
                <thead className="bg-slate-800/50 border-b border-slate-700">
                  <tr>
                    <th className="px-4 py-2 text-xs text-slate-400 font-semibold">Item</th>
                    <th className="px-4 py-2 text-xs text-slate-400 font-semibold text-center">Qty</th>
                    <th className="px-4 py-2 text-xs text-slate-400 font-semibold text-right">Unit Price</th>
                    <th className="px-4 py-2 text-xs text-slate-400 font-semibold text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {invoice.items?.map((item, idx) => (
                    <tr key={idx}>
                      <td className="px-4 py-3 text-sm text-white">{item.product_name}</td>
                      <td className="px-4 py-3 text-sm text-white text-center font-bold">{item.available_qty}</td>
                      <td className="px-4 py-3 text-sm text-slate-300 text-right">CFA {Number(item.price || (item.total_price / item.quantity)).toLocaleString()}</td>
                      <td className="px-4 py-3 text-sm text-white font-medium text-right">CFA {Number(item.total_price || (item.price * item.quantity)).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Returns History */}
            {returns && returns.length > 0 && (
              <div>
                <h3 className="text-lg font-bold text-white mb-3 flex items-center gap-2"><RotateCcw size={18} className="text-warning"/> Return History</h3>
                <div className="space-y-3">
                  {returns.map(ret => (
                    <div key={ret.id} className="bg-amber-900/10 border border-amber-700/30 p-4 rounded-xl">
                      <div className="flex justify-between items-start mb-2">
                        <p className="text-sm font-bold text-amber-400">
                           {ret.refund_method} Return - CFA {Number(ret.total_refunded).toLocaleString()}
                        </p>
                        <p className="text-xs text-slate-400">{new Date(ret.created_at).toLocaleString()}</p>
                      </div>
                      <p className="text-sm text-slate-300 mb-1">Status: <span className="font-bold">{ret.status}</span></p>
                      <p className="text-sm text-slate-300 mb-2">Processed by {ret.created_by_name}</p>
                      {ret.reason && <p className="text-sm text-slate-400 italic">"{ret.reason}"</p>}
                      {ret.photo && (
                          <div className="mt-2">
                              <img src={`${process.env.REACT_APP_API_URL || ''}${ret.photo}`} alt="Return Condition" className="h-20 rounded border border-slate-600" />
                          </div>
                      )}
                    </div>
                  ))}
                </div>
              </div>
            )}
            
            {invoice.notes && (
                <div className="bg-slate-800/30 p-4 border border-slate-700 rounded-xl">
                    <h4 className="text-sm text-slate-400 font-bold mb-1">Invoice Notes</h4>
                    <p className="text-white text-sm">{invoice.notes}</p>
                </div>
            )}
          </div>

          <div className="w-full md:w-80 overflow-y-auto bg-slate-900/50 p-6 hide-scrollbar relative">
            <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2 sticky top-0 bg-slate-900 pb-2"><Clock size={18} className="text-indigo-400"/> Activity Timeline</h3>
            <div className="space-y-6 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-700 before:to-transparent">
                {timeline?.map((event, idx) => (
                    <div key={idx} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                        <div className="flex items-center justify-center w-10 h-10 rounded-full border border-white bg-slate-800 group-[.is-active]:bg-indigo-500 text-slate-500 group-[.is-active]:text-indigo-50 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2">
                            {event.action === 'CREATED' ? <CheckCircle size={16} className="text-white" /> : 
                             event.action === 'EDIT' ? <Edit2 size={16} className="text-white" /> : 
                             event.action === 'CONVERT' ? <RotateCcw size={16} className="text-white" /> :
                             event.action === 'RETURN' ? <RotateCcw size={16} className="text-white" /> :
                             <History size={16} className="text-white" />}
                        </div>
                        <div className="w-[calc(100%-4rem)] md:w-[calc(50%-2.5rem)] glass-card p-4 rounded-xl border border-slate-700 shadow">
                            <div className="flex items-center justify-between mb-1">
                                <div className="font-bold text-slate-200 text-sm capitalize">{event.action.toLowerCase()}</div>
                                <time className="text-xs font-medium text-slate-500">{new Date(event.timestamp).toLocaleString()}</time>
                            </div>
                            <div className="text-slate-400 text-xs mt-1">
                                {event.details && typeof event.details === 'string' && event.details.startsWith('{') 
                                    ? <pre className="whitespace-pre-wrap font-sans mt-1 text-[10px] text-slate-300 bg-slate-800 p-2 rounded">{JSON.stringify(JSON.parse(event.details), null, 2)}</pre> 
                                    : event.details}
                            </div>
                        </div>
                    </div>
                ))}
            </div>
          </div>
        </div>

        {/* Print Only Layout */}
        <div className="hidden print:block p-8 font-mono text-black w-full" dir="ltr">
          <div className="text-center mb-6 border-b-2 border-black pb-4">
            <PrintLogo />
            <h1 className="text-3xl font-bold mb-2">INVOICE / RECEIPT</h1>
          </div>
          <div className="mb-6 flex justify-between">
            <div>
              <p><strong>Invoice #:</strong> {invoice.invoice_number}</p>
              <p><strong>Date:</strong> {invoice.date} {invoice.invoice_time}</p>
              <p><strong>Status:</strong> {invoice.status}</p>
              <p><strong>Payment:</strong> {invoice.payment_type}</p>
            </div>
            <div className="text-right">
              <p><strong>Target:</strong> {invoice.customer_type}</p>
              <p><strong>Client:</strong> {invoice.customer_name || 'Walk-In Customer'}</p>
            </div>
          </div>
          <table className="w-full text-left border-collapse mb-6">
            <thead>
              <tr className="border-b border-black">
                <th className="py-2">Item Description</th>
                <th className="py-2 text-center">Qty</th>
                <th className="py-2 text-right">Unit Price</th>
                <th className="py-2 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {invoice.items?.map((item, idx) => (
                <tr key={idx} className="border-b border-gray-300">
                  <td className="py-2">{item.product_name}</td>
                  <td className="py-2 text-center">{item.quantity}</td>
                  <td className="py-2 text-right">CFA {Number(item.price || (item.total_price / item.quantity)).toLocaleString()}</td>
                  <td className="py-2 text-right">CFA {Number(item.total_price || (item.price * item.quantity)).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="text-right border-t-2 border-black pt-4">
            {Number(invoice.discount) > 0 && <p className="mb-1 text-sm">Discount: CFA {Number(invoice.discount).toLocaleString()}</p>}
            {Number(invoice.tax) > 0 && <p className="mb-1 text-sm">Tax: CFA {Number(invoice.tax).toLocaleString()}</p>}
            <h2 className="text-xl font-bold">TOTAL: CFA {parseFloat(invoice.final_amount).toLocaleString()}</h2>
            {Number(invoice.returned_amount) > 0 && (
              <h2 className="text-lg font-bold text-red-600 mt-1">RETURNED: CFA {parseFloat(invoice.returned_amount).toLocaleString()}</h2>
            )}
          </div>
          {invoice.notes && (
              <div className="mt-8 border-t border-gray-300 pt-4 text-sm">
                  <strong>Notes:</strong> {invoice.notes}
              </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Convert Sale Modal
// ----------------------------------------------------------------------
export const ConvertModal = ({ invoice, onClose, onConvert }) => {
  const [targetType, setTargetType] = useState('Building');
  const [targetId, setTargetId] = useState('');

  const { data: buildings } = useQuery({
    queryKey: ['buildingsList'],
    queryFn: async () => (await api.get('/buildings')).data,
    enabled: targetType === 'Building' || targetType === 'Apartment'
  });

  const { data: apartments } = useQuery({
    queryKey: ['apartmentsList'],
    queryFn: async () => (await api.get('/apartments')).data,
    enabled: targetType === 'Apartment'
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!targetId) return alert('Please select a target entity');
    onConvert({ new_type: targetType, new_entity_id: targetId });
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="glass-card w-full max-w-md border border-slate-700 animate-in zoom-in-95" onClick={e=>e.stopPropagation()}>
        <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30 rounded-t-xl">
          <h2 className="text-xl font-bold text-white">Convert Sale to Entity</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white"><X size={20}/></button>
        </div>
        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div className="p-4 bg-primary/10 border border-primary/20 rounded-lg text-sm text-primary mb-4">
            Convert this Walk-In sale into a Building, Apartment, or Construction cost.
          </div>
          
          <div>
            <label className="block text-sm text-slate-400 mb-1">Target Type</label>
            <select value={targetType} onChange={(e) => {setTargetType(e.target.value); setTargetId('');}} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white">
              <option value="Building">Building</option>
              <option value="Apartment">Apartment</option>
              <option value="Construction">Construction</option>
            </select>
          </div>

          <div>
            <label className="block text-sm text-slate-400 mb-1">Select {targetType}</label>
            <select value={targetId} onChange={(e) => setTargetId(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white">
              <option value="">-- Select --</option>
              {targetType === 'Building' && buildings?.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
              {targetType === 'Apartment' && apartments?.map(a => <option key={a.id} value={a.id}>{a.building_name} - Apt {a.apartment_number}</option>)}
              {targetType === 'Construction' && <option value="" disabled>Load constructions query here</option>}
            </select>
          </div>

          <div className="pt-4 flex justify-end gap-3">
            <button type="button" onClick={onClose} className="px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700">Cancel</button>
            <button type="submit" disabled={!targetId} className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-indigo-600 disabled:opacity-50 flex items-center gap-2">
              <Save size={18}/> Convert Sale
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Return Modal (With Photo, Manager Approval logic, Condition)
// ----------------------------------------------------------------------
export const ReturnModal = ({ invoice, onClose, onSave }) => {
  const [returnType, setReturnType] = useState('full');
  const [reason, setReason] = useState('');
  const [refundMethod, setRefundMethod] = useState('Cash');
  const [photoPreview, setPhotoPreview] = useState(null);
  const fileInputRef = useRef(null);
  
  // For partial return
  const [returnItems, setReturnItems] = useState(
    invoice.items
      ?.map(i => ({
        ...i,
        product_id: i.product_id,
        available_qty: i.quantity - (i.returned_qty || 0),
        quantity: i.quantity - (i.returned_qty || 0),
        return_qty: 0,
        condition: 'Good',
        price: i.price || (i.total_price / i.quantity) 
      }))
      .filter(i => i.available_qty > 0) || []
  );

  const mutation = useMutation({
    mutationFn: (data) => api.post('/sales/returns', data),
    onSuccess: () => {
      alert('Return processed successfully');
      onSave();
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to process return');
    }
  });

  const handleReturnQtyChange = (idx, qty) => {
    const maxQty = returnItems[idx].available_qty;
    const cleanQty = Math.max(0, Math.min(maxQty, Number(qty)));
    const newItems = [...returnItems];
    newItems[idx].return_qty = cleanQty;
    setReturnItems(newItems);
  };

  const handleConditionChange = (idx, cond) => {
      const newItems = [...returnItems];
      newItems[idx].condition = cond;
      setReturnItems(newItems);
  };

  const calculatePartialTotal = () => {
    return returnItems.reduce((sum, item) => sum + (item.return_qty * item.price), 0);
  };

  const handleFileChange = (e) => {
      const file = e.target.files[0];
      if (file) {
          const reader = new FileReader();
          reader.onloadend = () => setPhotoPreview(reader.result);
          reader.readAsDataURL(file);
      }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!reason.trim()) return alert('Reason is required');

    let payload = {
      invoice_id: invoice.id,
      reason: reason,
      refund_method: refundMethod,
      photo: photoPreview,
      status: 'Completed' // Could require 'Pending' based on logic
    };

    if (returnType === 'partial') {
      const itemsToReturn = returnItems.filter(i => i.return_qty > 0).map(i => ({
        product_id: i.product_id,
        quantity: i.return_qty,
        price: i.price,
        condition: i.condition
      }));
      if (itemsToReturn.length === 0) return alert('Select at least one item to return');
      payload.items = itemsToReturn;
    } else {
      payload.items = returnItems.map(i => ({
          product_id: i.product_id,
          quantity: i.available_qty,
          price: i.price,
          condition: i.condition
      }));
    }

    mutation.mutate(payload);
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="glass-card w-full max-w-3xl border border-slate-700 animate-in zoom-in-95 flex flex-col max-h-[90vh]" onClick={e=>e.stopPropagation()}>
        <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30 rounded-t-xl">
          <h2 className="text-xl font-bold text-white flex items-center gap-2"><RotateCcw size={20} className="text-warning"/> Process Return - {invoice.invoice_number}</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white"><X size={20}/></button>
        </div>
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6 hide-scrollbar">
          
          <div className="flex gap-4">
            <button type="button" onClick={() => setReturnType('full')} className={`flex-1 py-3 rounded-lg border-2 font-bold transition-all ${returnType === 'full' ? 'border-primary bg-primary/20 text-primary' : 'border-slate-700 bg-slate-800/50 text-slate-400 hover:border-slate-600'}`}>
              Full Return
            </button>
            <button type="button" onClick={() => setReturnType('partial')} className={`flex-1 py-3 rounded-lg border-2 font-bold transition-all ${returnType === 'partial' ? 'border-primary bg-primary/20 text-primary' : 'border-slate-700 bg-slate-800/50 text-slate-400 hover:border-slate-600'}`}>
              Partial Return
            </button>
          </div>

          <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm text-slate-400 mb-1">Reason for Return</label>
                <textarea 
                  value={reason} 
                  onChange={e => setReason(e.target.value)} 
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-primary focus:outline-none"
                  rows={3}
                  placeholder="Enter reason..."
                  required
                />
              </div>
              <div className="space-y-4">
                  <div>
                      <label className="block text-sm text-slate-400 mb-1">Refund Method</label>
                      <select value={refundMethod} onChange={e => setRefundMethod(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white">
                          <option value="Cash">Cash</option>
                          <option value="Card">Card</option>
                          <option value="Bank">Bank</option>
                          <option value="Store Credit">Store Credit</option>
                      </select>
                  </div>
                  <div>
                      <label className="block text-sm text-slate-400 mb-1">Upload Photo (Optional)</label>
                      <input type="file" accept="image/*" ref={fileInputRef} onChange={handleFileChange} className="hidden" />
                      <div className="flex gap-2 items-center">
                          <button type="button" onClick={() => fileInputRef.current?.click()} className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white hover:bg-slate-700 text-sm">
                              {photoPreview ? 'Change Photo' : 'Choose Photo'}
                          </button>
                          {photoPreview && <img src={photoPreview} alt="Preview" className="h-10 w-10 object-cover rounded border border-slate-600" />}
                      </div>
                  </div>
              </div>
          </div>

          {returnType === 'partial' && (
            <div className="border border-slate-700 rounded-xl overflow-hidden">
              <table className="w-full text-left">
                <thead className="bg-slate-800/50">
                  <tr>
                    <th className="px-4 py-2 text-xs text-slate-400">Item</th>
                    <th className="px-4 py-2 text-xs text-slate-400 text-center">Purchased</th>
                    <th className="px-4 py-2 text-xs text-slate-400 text-center">Return Qty</th>
                    <th className="px-4 py-2 text-xs text-slate-400">Condition</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {returnItems.map((item, idx) => (
                    <tr key={idx}>
                      <td className="px-4 py-3 text-sm text-white">{item.product_name}</td>
                      <td className="px-4 py-3 text-sm text-center text-slate-400">{item.quantity}</td>
                      <td className="px-4 py-3 flex justify-center">
                        <input 
                          type="number" 
                          min="0" 
                          max={item.available_qty}
                          value={item.return_qty}
                          onChange={e => handleReturnQtyChange(idx, e.target.value)}
                          className="w-16 bg-slate-900 border border-slate-600 rounded px-2 py-1 text-center text-white outline-none focus:border-primary"
                        />
                      </td>
                      <td className="px-4 py-3">
                          <select value={item.condition} onChange={e => handleConditionChange(idx, e.target.value)} className="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-white text-sm outline-none">
                              <option value="Good">Good (Restock)</option>
                              <option value="Damaged">Damaged</option>
                              <option value="Defective">Defective</option>
                          </select>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="p-4 bg-slate-800/30 border-t border-slate-700 flex justify-between items-center">
                <span className="text-sm font-medium text-slate-400">Partial Return Amount</span>
                <span className="text-xl font-bold text-warning">CFA {Number(calculatePartialTotal()).toLocaleString()}</span>
              </div>
            </div>
          )}

          {returnType === 'full' && (
            <div className="space-y-4">
                <div className="border border-slate-700 rounded-xl overflow-hidden">
                    <table className="w-full text-left">
                        <thead className="bg-slate-800/50">
                        <tr>
                            <th className="px-4 py-2 text-xs text-slate-400">Item</th>
                            <th className="px-4 py-2 text-xs text-slate-400">Condition</th>
                        </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-700/50">
                        {returnItems.map((item, idx) => (
                            <tr key={idx}>
                            <td className="px-4 py-3 text-sm text-white">{item.product_name}</td>
                            <td className="px-4 py-3">
                                <select value={item.condition} onChange={e => handleConditionChange(idx, e.target.value)} className="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-white text-sm outline-none">
                                    <option value="Good">Good (Restock)</option>
                                    <option value="Damaged">Damaged</option>
                                    <option value="Defective">Defective</option>
                                </select>
                            </td>
                            </tr>
                        ))}
                        </tbody>
                    </table>
                </div>
                <div className="p-4 bg-amber-900/20 border border-amber-700/50 rounded-xl flex justify-between items-center">
                <span className="font-medium text-amber-400">Full Return Amount</span>
                <span className="text-2xl font-bold text-warning">CFA {Number(invoice.final_amount).toLocaleString()}</span>
                </div>
            </div>
          )}

          <div className="pt-4 flex justify-end gap-3 border-t border-slate-700/50">
            <button type="button" onClick={onClose} className="px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700">Cancel</button>
            <button type="submit" disabled={mutation.isPending} className="px-4 py-2 bg-warning text-slate-900 font-bold rounded-lg hover:bg-yellow-500 disabled:opacity-50 flex items-center gap-2">
              <RotateCcw size={18}/> Process {returnType === 'full' ? 'Full' : 'Partial'} Return
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

// ----------------------------------------------------------------------
// Invoice Edit Modal (Comprehensive)
// ----------------------------------------------------------------------
export const InvoiceEditModal = ({ invoice, onClose, onSave }) => {
  const [items, setItems] = useState(invoice.items?.map(i => ({...i, price: i.price || (i.total_price / i.quantity)})) || []);
  const [formData, setFormData] = useState({
      customer_name: invoice.customer_name || '',
      customer_type: invoice.customer_type || 'Walk-In',
      payment_type: invoice.payment_type || 'Cash',
      date: invoice.date || '',
      invoice_time: invoice.invoice_time || '',
      discount: Number(invoice.discount) || 0,
      tax: Number(invoice.tax) || 0,
      notes: invoice.notes || '',
      reason: ''
  });

  const mutation = useMutation({
    mutationFn: (data) => api.post('/sales/edit', data),
    onSuccess: () => {
      alert('Invoice updated successfully');
      onSave();
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to update invoice');
    }
  });

  const handleQtyChange = (idx, newQty) => {
    const qty = Math.max(1, Number(newQty));
    const newItems = [...items];
    newItems[idx].quantity = qty;
    newItems[idx].total_price = qty * newItems[idx].price;
    setItems(newItems);
  };

  const handlePriceChange = (idx, newPrice) => {
      const price = Math.max(0, Number(newPrice));
      const newItems = [...items];
      newItems[idx].price = price;
      newItems[idx].total_price = price * newItems[idx].quantity;
      setItems(newItems);
  };

  const calculateSubtotal = () => items.reduce((sum, i) => sum + Number(i.total_price), 0);
  const calculateTotal = () => Math.max(0, calculateSubtotal() - formData.discount + formData.tax);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!formData.reason.trim()) return alert("Audit Reason is required for editing invoices.");
    
    mutation.mutate({
      invoice_id: invoice.id,
      items: items,
      ...formData
    });
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4" onClick={onClose}>
      <div className="glass-card w-full max-w-5xl border border-slate-700 animate-in zoom-in-95 flex flex-col max-h-[90vh]" onClick={e=>e.stopPropagation()}>
        <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30 rounded-t-xl">
          <h2 className="text-xl font-bold text-white flex items-center gap-2"><Edit2 size={20} className="text-primary"/> Comprehensive Edit - {invoice.invoice_number}</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white"><X size={20}/></button>
        </div>
        <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6 space-y-6 hide-scrollbar flex flex-col md:flex-row gap-6">
          
          <div className="flex-1 space-y-6">
              {/* Info Edit */}
              <div className="grid grid-cols-2 gap-4">
                  <div>
                      <label className="block text-sm text-slate-400 mb-1">Customer Name</label>
                      <input type="text" value={formData.customer_name} onChange={e => setFormData({...formData, customer_name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
                  </div>
                  <div>
                      <label className="block text-sm text-slate-400 mb-1">Customer Type</label>
                      <select value={formData.customer_type} onChange={e => setFormData({...formData, customer_type: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                          <option value="Walk-In">Walk-In</option>
                          <option value="Building">Building</option>
                          <option value="Apartment">Apartment</option>
                          <option value="Construction">Construction</option>
                          <option value="Account">Account</option>
                      </select>
                  </div>
                  <div>
                      <label className="block text-sm text-slate-400 mb-1">Payment Type</label>
                      <select value={formData.payment_type} onChange={e => setFormData({...formData, payment_type: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                          <option value="Cash">Cash</option>
                          <option value="Card">Card</option>
                          <option value="Bank">Bank</option>
                          <option value="Transfer">Transfer</option>
                          <option value="Mixed">Mixed</option>
                      </select>
                  </div>
                  <div className="flex gap-2">
                      <div className="flex-1">
                          <label className="block text-sm text-slate-400 mb-1">Date</label>
                          <input type="date" value={formData.date} onChange={e => setFormData({...formData, date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div className="flex-1">
                          <label className="block text-sm text-slate-400 mb-1">Time</label>
                          <input type="time" value={formData.invoice_time} onChange={e => setFormData({...formData, invoice_time: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                  </div>
              </div>

              {/* Items Edit */}
              <div className="border border-slate-700 rounded-xl overflow-hidden">
                <table className="w-full text-left">
                  <thead className="bg-slate-800/50">
                    <tr>
                      <th className="px-4 py-2 text-xs text-slate-400">Item</th>
                      <th className="px-4 py-2 text-xs text-slate-400 text-center">Qty</th>
                      <th className="px-4 py-2 text-xs text-slate-400 text-right">Unit Price</th>
                      <th className="px-4 py-2 text-xs text-slate-400 text-right">Total</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {items.map((item, idx) => (
                      <tr key={idx}>
                        <td className="px-4 py-3 text-sm text-white">{item.product_name}</td>
                        <td className="px-4 py-3 flex justify-center">
                          <input 
                            type="number" 
                            min="1" 
                            value={item.quantity}
                            onChange={e => handleQtyChange(idx, e.target.value)}
                            className="w-16 bg-slate-900 border border-slate-600 rounded px-2 py-1 text-center text-white outline-none focus:border-primary"
                          />
                        </td>
                        <td className="px-4 py-3 text-right">
                          <input 
                            type="number" 
                            min="0" 
                            value={item.price}
                            onChange={e => handlePriceChange(idx, e.target.value)}
                            className="w-24 bg-slate-900 border border-slate-600 rounded px-2 py-1 text-right text-white outline-none focus:border-primary inline-block"
                          />
                        </td>
                        <td className="px-4 py-3 text-sm text-white font-medium text-right">CFA {Number(item.total_price).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
          </div>

          <div className="w-full md:w-80 flex flex-col gap-4">
              <div className="bg-slate-800/30 border border-slate-700 p-4 rounded-xl space-y-3">
                <div className="flex justify-between items-center text-slate-300">
                  <span>Subtotal</span>
                  <span>CFA {calculateSubtotal().toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center text-slate-300">
                  <span>Discount (-)</span>
                  <div className="flex items-center gap-2">
                    CFA <input type="number" value={formData.discount} onChange={e => setFormData({...formData, discount: Number(e.target.value)})} className="w-20 bg-slate-900 border border-slate-600 rounded px-2 py-1 text-right outline-none focus:border-primary text-white" />
                  </div>
                </div>
                <div className="flex justify-between items-center text-slate-300">
                  <span>Tax (+)</span>
                  <div className="flex items-center gap-2">
                    CFA <input type="number" value={formData.tax} onChange={e => setFormData({...formData, tax: Number(e.target.value)})} className="w-20 bg-slate-900 border border-slate-600 rounded px-2 py-1 text-right outline-none focus:border-primary text-white" />
                  </div>
                </div>
                <div className="border-t border-slate-700 pt-3 flex justify-between items-center font-bold text-lg text-white">
                  <span>Final Total</span>
                  <span className="text-emerald-400">CFA {calculateTotal().toLocaleString()}</span>
                </div>
              </div>

              <div>
                  <label className="block text-sm text-slate-400 mb-1">Invoice Notes</label>
                  <textarea rows="2" value={formData.notes} onChange={e => setFormData({...formData, notes: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white"></textarea>
              </div>
              
              <div>
                  <label className="block text-sm text-slate-400 mb-1 text-warning font-bold flex items-center gap-1"><AlertTriangle size={14}/> Audit Reason (Required)</label>
                  <textarea rows="2" value={formData.reason} onChange={e => setFormData({...formData, reason: e.target.value})} placeholder="Why are you editing this invoice?" className="w-full bg-slate-800 border border-warning/50 rounded-lg px-3 py-2 text-white focus:border-warning outline-none" required></textarea>
              </div>

              <div className="mt-auto pt-4 flex justify-end gap-3 border-t border-slate-700/50">
                <button type="button" onClick={onClose} className="px-4 py-2 bg-slate-800 text-white rounded-lg hover:bg-slate-700">Cancel</button>
                <button type="submit" disabled={mutation.isPending || !formData.reason.trim()} className="px-4 py-2 bg-primary text-white rounded-lg hover:bg-indigo-600 disabled:opacity-50 flex items-center gap-2">
                  <Save size={18}/> Commit Edit
                </button>
              </div>
          </div>
        </form>
      </div>
    </div>
  );
};
