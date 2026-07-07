import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { ArrowRightLeft, Search, Plus, Trash2, Package, Send, Printer, Calendar, FileText } from 'lucide-react';

const MovementTransfer = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  
  const [activeTab, setActiveTab] = useState('new'); // 'new' or 'history'
  
  const [fromDepot, setFromDepot] = useState('');
  const [toDepot, setToDepot] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [transferItems, setTransferItems] = useState([]); // { product, quantity }
  const [notes, setNotes] = useState('');

  // History filters
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');

  const { data: depots, isLoading: isDepotsLoading } = useQuery({
    queryKey: ['depots'],
    queryFn: async () => (await axios.get('/depots')).data
  });

  const { data: products, isLoading: isProductsLoading } = useQuery({
    queryKey: ['products'],
    queryFn: async () => (await axios.get('/warehouse')).data
  });

  const { data: transfers, isLoading: isTransfersLoading } = useQuery({
    queryKey: ['transfers'],
    queryFn: async () => (await axios.get('/transfers')).data
  });

  const transferMutation = useMutation({
    mutationFn: (data) => axios.post('/transfers', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['depots'] });
      queryClient.invalidateQueries({ queryKey: ['transfers'] });
      setTransferItems([]);
      setFromDepot('');
      setToDepot('');
      setNotes('');
      alert('Transfer completed successfully!');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to complete transfer');
    }
  });

  const handleTransfer = () => {
    if (!fromDepot || !toDepot) {
      alert('Please select both source and destination depots.');
      return;
    }
    if (fromDepot === toDepot) {
      alert('Source and destination depots must be different.');
      return;
    }
    if (transferItems.length === 0) {
      alert('Please add items to transfer.');
      return;
    }
    
    // Check stock for each item in the source depot
    for (let item of transferItems) {
      const p = products.find(p => p.id === item.product.id);
      const depotStock = p.depots?.find(d => d.depot_id == fromDepot)?.quantity || 0;
      if (item.quantity > depotStock) {
        alert(`Insufficient stock for ${item.product.name} in the selected source depot. Max available: ${depotStock}`);
        return;
      }
    }

    transferMutation.mutate({
      from_depot_id: fromDepot,
      to_depot_id: toDepot,
      notes,
      items: transferItems.map(item => ({
        product_id: item.product.id,
        quantity: item.quantity
      }))
    });
  };

  const addItem = (product) => {
    if (!transferItems.find(item => item.product.id === product.id)) {
      setTransferItems([...transferItems, { product, quantity: 1 }]);
    }
  };

  const updateItemQty = (productId, qty) => {
    setTransferItems(transferItems.map(item => 
      item.product.id === productId ? { ...item, quantity: Math.max(1, qty) } : item
    ));
  };

  const removeItem = (productId) => {
    setTransferItems(transferItems.filter(item => item.product.id !== productId));
  };

  const filteredProducts = products?.filter(p => 
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.reference?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const filteredTransfers = transfers?.filter(t => {
    let keep = true;
    const tDate = new Date(t.date).getTime();
    if (dateFrom) {
      keep = keep && tDate >= new Date(dateFrom).getTime();
    }
    if (dateTo) {
      // Add one day to dateTo to include the whole day
      keep = keep && tDate <= (new Date(dateTo).getTime() + 86400000);
    }
    return keep;
  }) || [];

  const handlePrint = () => {
    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
      <html>
        <head>
          <title>Movement Transfer Report</title>
          <style>
            body { font-family: sans-serif; padding: 20px; color: #333; }
            h1 { text-align: center; margin-bottom: 20px; }
            .filters { text-align: center; margin-bottom: 30px; font-size: 14px; color: #666; }
            table { w-full; width: 100%; border-collapse: collapse; margin-bottom: 30px; }
            th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
            th { background-color: #f5f5f5; }
            .items-table { width: 100%; border: none; font-size: 13px; margin-top: 5px; }
            .items-table td { border: none; padding: 2px 0; }
          </style>
        </head>
        <body>
          <h1>Movement Transfer Report</h1>
          <div class="filters">
            ${dateFrom ? `From: ${dateFrom}` : ''} ${dateTo ? `To: ${dateTo}` : ''}
          </div>
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>Source</th>
                <th>Destination</th>
                <th>User</th>
                <th>Items Moved</th>
              </tr>
            </thead>
            <tbody>
              ${filteredTransfers.map(t => `
                <tr>
                  <td>${new Date(t.date).toLocaleString()}</td>
                  <td>${t.from_depot}</td>
                  <td>${t.to_depot}</td>
                  <td>${t.user_name || 'System'}</td>
                  <td>
                    <table class="items-table">
                      ${t.items?.map(item => `
                        <tr>
                          <td>${item.name}</td>
                          <td style="text-align: right;"><strong>${item.quantity}</strong></td>
                        </tr>
                      `).join('')}
                    </table>
                  </td>
                </tr>
              `).join('')}
            </tbody>
          </table>
          <script>
            window.onload = function() { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  return (
    <div className="flex flex-col h-full w-full bg-background">
      {/* Header & Tabs */}
      <div className="p-8 pb-0 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2">Movement Transfer</h1>
        
        <div className="flex gap-4 mt-4 border-b border-slate-700/50">
          <button 
            onClick={() => setActiveTab('new')} 
            className={`text-sm font-medium pb-3 border-b-2 transition-colors ${activeTab === 'new' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            New Transfer
          </button>
          <button 
            onClick={() => setActiveTab('history')} 
            className={`text-sm font-medium pb-3 border-b-2 transition-colors ${activeTab === 'history' ? 'text-primary border-primary' : 'text-muted border-transparent hover:text-white'}`}
          >
            Transfer History
          </button>
        </div>
      </div>

      {activeTab === 'new' ? (
      <div className="flex flex-1 overflow-hidden">
      {/* Left side: Product Selection */}
      <div className="w-1/2 p-8 border-r border-slate-700/50 flex flex-col hide-scrollbar">
        <h1 className="text-3xl font-bold text-white mb-2">Movement Transfer</h1>
        <p className="text-muted mb-8">Select products to transfer</p>

        <div className="relative mb-6">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
          <input 
            type="text" 
            placeholder="Search products to transfer..." 
            className="w-full pl-10 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-xl text-white focus:outline-none focus:border-primary transition-colors shadow-lg"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>

        <div className="flex-1 overflow-y-auto hide-scrollbar">
          <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
            {isProductsLoading ? (
              Array(6).fill(0).map((_, i) => <div key={i} className="glass-card h-32 animate-pulse bg-slate-800/50"></div>)
            ) : (
              filteredProducts?.map(product => (
                <div key={product.id} className="glass-card p-4 flex flex-col hover-card group border border-slate-700/50">
                  <div className="flex justify-between items-start mb-2">
                    <h3 className="font-semibold text-white line-clamp-2">{product.name}</h3>
                    <button 
                      onClick={() => addItem(product)}
                      className="p-1.5 bg-primary/20 text-indigo-400 hover:bg-primary hover:text-white rounded-lg transition-colors"
                    >
                      <Plus size={16} />
                    </button>
                  </div>
                  <div className="text-xs text-muted mb-2">REF: {product.reference}</div>
                  
                  <div className="mt-auto pt-2 border-t border-slate-700/30">
                    <p className="text-[10px] text-muted mb-1 uppercase tracking-wider">Available Stock</p>
                    <div className="flex flex-wrap gap-2">
                      {product.depots && product.depots.length > 0 ? (
                        product.depots.map(d => (
                          <span key={d.depot_id} className={`text-xs px-2 py-0.5 rounded ${d.is_primary ? 'bg-indigo-500/20 text-indigo-300' : 'bg-slate-800 text-slate-300'}`}>
                            {d.depot_name}: <strong className="text-white">{d.quantity}</strong>
                          </span>
                        ))
                      ) : (
                        <span className="text-xs text-warning">No stock allocated</span>
                      )}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Right side: Transfer Configuration */}
      <div className="w-1/2 flex flex-col bg-slate-900/30">
        <div className="p-8 border-b border-slate-700/50">
          <div className="flex items-center gap-4 mb-6">
            <div className="flex-1">
              <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-2">From Depot</label>
              <select 
                value={fromDepot} 
                onChange={(e) => setFromDepot(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-warning appearance-none"
              >
                <option value="">Select Source...</option>
                {depots?.map(d => <option key={d.id} value={d.id}>{d.name} {d.is_primary ? '(Primary)' : ''}</option>)}
              </select>
            </div>
            <div className="flex flex-col items-center justify-center pt-6 text-slate-500">
              <ArrowRightLeft size={24} className="text-indigo-500" />
            </div>
            <div className="flex-1">
              <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-2">To Depot</label>
              <select 
                value={toDepot} 
                onChange={(e) => setToDepot(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-success appearance-none"
              >
                <option value="">Select Destination...</option>
                {depots?.map(d => <option key={d.id} value={d.id}>{d.name} {d.is_primary ? '(Primary)' : ''}</option>)}
              </select>
            </div>
          </div>
          
          <div>
            <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-2">Transfer Notes</label>
            <input 
              type="text" 
              value={notes} 
              onChange={e => setNotes(e.target.value)} 
              placeholder="Reason for transfer..."
              className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary"
            />
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
          <h3 className="text-lg font-bold text-white mb-4 flex items-center">
            <Package className="mr-2 text-indigo-400" size={20} />
            Items to Transfer
          </h3>
          
          {transferItems.length === 0 ? (
            <div className="h-40 flex flex-col items-center justify-center border-2 border-dashed border-slate-700 rounded-xl text-muted">
              <Package size={32} className="mb-2 opacity-50" />
              <p>No items added yet</p>
            </div>
          ) : (
            <div className="space-y-3">
              {transferItems.map(item => (
                <div key={item.product.id} className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex items-center justify-between">
                  <div className="flex-1 min-w-0 pr-4">
                    <h4 className="font-bold text-white truncate">{item.product.name}</h4>
                    <p className="text-xs text-muted">REF: {item.product.reference}</p>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-muted">Qty:</span>
                      <input 
                        type="number" 
                        value={item.quantity} 
                        onChange={(e) => updateItemQty(item.product.id, parseInt(e.target.value) || 1)}
                        className="w-20 bg-slate-900 border border-slate-600 rounded-lg px-2 py-1.5 text-center text-white focus:outline-none focus:border-primary"
                        min="1"
                      />
                    </div>
                    <button 
                      onClick={() => removeItem(item.product.id)}
                      className="p-2 text-danger hover:bg-danger/20 rounded-lg transition-colors"
                    >
                      <Trash2 size={18} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="p-8 border-t border-slate-700/50 bg-slate-900/50">
          <button 
            onClick={handleTransfer}
            disabled={transferItems.length === 0 || transferMutation.isPending}
            className={`w-full py-4 rounded-xl flex items-center justify-center font-bold text-lg transition-all ${
              transferItems.length > 0 
                ? 'bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/30' 
                : 'bg-slate-800 text-slate-500 cursor-not-allowed'
            }`}
          >
            <Send size={20} className="mr-2" />
            {transferMutation.isPending ? 'Processing...' : 'Execute Transfer'}
          </button>
        </div>
      </div>
      </div>
      ) : (
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="glass-card p-6 border border-slate-700/50 mb-6">
          <div className="flex flex-col md:flex-row items-end justify-between gap-4">
            <div className="flex flex-wrap items-center gap-4">
              <div>
                <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-1">From Date</label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                  <input 
                    type="date" 
                    value={dateFrom}
                    onChange={(e) => setDateFrom(e.target.value)}
                    className="pl-9 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:border-primary focus:outline-none text-sm"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-1">To Date</label>
                <div className="relative">
                  <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
                  <input 
                    type="date" 
                    value={dateTo}
                    onChange={(e) => setDateTo(e.target.value)}
                    className="pl-9 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:border-primary focus:outline-none text-sm"
                  />
                </div>
              </div>
              <div className="pb-0.5">
                <button 
                  onClick={() => { setDateFrom(''); setDateTo(''); }}
                  className="text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
                >
                  Clear Filters
                </button>
              </div>
            </div>
            
            <button 
              onClick={handlePrint}
              disabled={filteredTransfers.length === 0}
              className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg border border-slate-600 transition-colors disabled:opacity-50"
            >
              <Printer size={18} />
              Print Report
            </button>
          </div>
        </div>

        <div className="glass-card border border-slate-700/50 overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-slate-800/50 border-b border-slate-700">
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">Date & Time</th>
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">Source Depot</th>
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">Destination Depot</th>
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">User</th>
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">Notes</th>
                  <th className="px-6 py-4 text-sm font-semibold text-slate-300">Items Moved</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {isTransfersLoading ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-8 text-center text-muted">Loading transfers...</td>
                  </tr>
                ) : filteredTransfers.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-6 py-8 text-center text-muted flex flex-col items-center">
                      <FileText size={32} className="mb-2 opacity-30" />
                      No transfers found for the selected dates.
                    </td>
                  </tr>
                ) : (
                  filteredTransfers.map(t => (
                    <tr key={t.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="px-6 py-4 text-sm text-white">
                        {new Date(t.date).toLocaleDateString()} <span className="text-muted">{new Date(t.date).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm font-medium text-warning">{t.from_depot}</span>
                      </td>
                      <td className="px-6 py-4">
                        <span className="text-sm font-medium text-success">{t.to_depot}</span>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-300">{t.user_name || 'System'}</td>
                      <td className="px-6 py-4 text-sm text-slate-400 max-w-[200px] truncate" title={t.notes}>{t.notes || '-'}</td>
                      <td className="px-6 py-4">
                        <div className="space-y-1">
                          {t.items?.map(item => (
                            <div key={item.id} className="flex justify-between items-center text-xs bg-slate-800/50 px-2 py-1 rounded">
                              <span className="text-slate-300 truncate max-w-[150px] mr-4" title={item.name}>{item.name}</span>
                              <span className="font-bold text-white">×{item.quantity}</span>
                            </div>
                          ))}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
      )}
    </div>
  );
};

export default MovementTransfer;
