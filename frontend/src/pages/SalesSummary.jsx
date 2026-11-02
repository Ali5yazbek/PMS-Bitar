import React, { useState, useEffect, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { 
  Activity, Search, Calendar, Filter, FileText, Download, 
  TrendingUp, CreditCard, RotateCcw, Building, Users, Eye, Edit2, 
  RefreshCcw, AlertTriangle, CheckCircle, Package, DollarSign
} from 'lucide-react';
import { InvoiceViewModal, InvoiceEditModal, ReturnModal, ConvertModal } from './SalesModals';

const SalesSummary = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  
  // Filters
  const [dateRange, setDateRange] = useState({ start_date: '', end_date: '' });
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  
  // Modals
  const [viewingInvoice, setViewingInvoice] = useState(null);
  const [editingInvoice, setEditingInvoice] = useState(null);
  const [convertingInvoice, setConvertingInvoice] = useState(null);
  const [returningInvoice, setReturningInvoice] = useState(null);

  // Debounce search
  useEffect(() => {
    const timer = setTimeout(() => setDebouncedSearch(searchTerm), 500);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const { data: analytics, isLoading: analyticsLoading } = useQuery({
    queryKey: ['salesAnalytics', dateRange],
    queryFn: async () => {
      const res = await api.get('/sales/analytics', { params: dateRange });
      return res.data;
    }
  });

  const { data: invoices, isLoading: invoicesLoading } = useQuery({
    queryKey: ['salesSummary', dateRange, categoryFilter, debouncedSearch],
    queryFn: async () => {
      const res = await api.get('/sales/summary', { 
        params: { 
          ...dateRange, 
          category: categoryFilter,
          search: debouncedSearch 
        } 
      });
      return res.data;
    }
  });

  const convertMutation = useMutation({
    mutationFn: (data) => api.post('/sales/convert', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['salesSummary']);
      queryClient.invalidateQueries(['salesAnalytics']);
      setConvertingInvoice(null);
      alert('Sale converted successfully');
    }
  });

  const setToday = () => {
    const today = new Date().toLocaleDateString('sv-SE');
    setDateRange({ start_date: today, end_date: today });
  };
  const setThisMonth = () => {
    const date = new Date();
    const firstDay = new Date(date.getFullYear(), date.getMonth(), 1).toLocaleDateString('sv-SE');
    const lastDay = new Date(date.getFullYear(), date.getMonth() + 1, 0).toLocaleDateString('sv-SE');
    setDateRange({ start_date: firstDay, end_date: lastDay });
  };

  return (
    <div className="flex h-full bg-background overflow-hidden">
      <div className="flex-1 flex flex-col h-full overflow-hidden p-6 md:p-8 hide-scrollbar">
        
        {/* Header & Filters */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8 animate-in slide-in-from-top-4">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center mb-2">
              <Activity className="me-3 text-primary" size={32} />
              Sales Summary Center
            </h1>
            <p className="text-slate-400">Advanced analytics and management for all POS transactions.</p>
          </div>
          
          <div className="flex flex-wrap items-center gap-3">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input 
                type="text" 
                placeholder="Search invoice #, client..." 
                className="pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:border-primary focus:outline-none w-64 transition-all"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
            </div>
            
            <select 
              value={categoryFilter} 
              onChange={e => setCategoryFilter(e.target.value)}
              className="px-4 py-2 bg-slate-800 border border-slate-700 rounded-xl text-white focus:border-primary focus:outline-none transition-all"
            >
              <option value="All">All Categories</option>
              <option value="Walk-In">Walk-In</option>
              <option value="Building">Building / Apartment</option>
              <option value="Construction">Construction</option>
            </select>

            <div className="flex items-center gap-2 bg-slate-800 border border-slate-700 rounded-xl px-2 py-1">
              <input type="date" className="bg-transparent text-white text-sm outline-none px-2 py-1" value={dateRange.start_date} onChange={e => setDateRange({...dateRange, start_date: e.target.value})} />
              <span className="text-slate-500">to</span>
              <input type="date" className="bg-transparent text-white text-sm outline-none px-2 py-1" value={dateRange.end_date} onChange={e => setDateRange({...dateRange, end_date: e.target.value})} />
            </div>

            <button onClick={setToday} className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-sm transition-colors">Today</button>
            <button onClick={setThisMonth} className="px-3 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-sm transition-colors">This Month</button>
          </div>
        </div>

        {/* Analytics Dashboard */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <div className="glass-card p-6 flex flex-col justify-between border-t-4 border-t-primary hover:-translate-y-1 transition-transform">
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="text-slate-400 font-medium text-sm">Total Revenue</p>
                <h3 className="text-2xl font-bold text-white mt-1">
                  CFA {Number(analytics?.total_revenue || 0).toLocaleString()}
                </h3>
              </div>
              <div className="p-3 bg-primary/20 rounded-xl"><DollarSign className="text-primary" size={24} /></div>
            </div>
          </div>
          <div className="glass-card p-6 flex flex-col justify-between border-t-4 border-t-indigo-500 hover:-translate-y-1 transition-transform">
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="text-slate-400 font-medium text-sm">Total Invoices</p>
                <h3 className="text-2xl font-bold text-white mt-1">{analytics?.total_invoices || 0}</h3>
              </div>
              <div className="p-3 bg-indigo-500/20 rounded-xl"><FileText className="text-indigo-400" size={24} /></div>
            </div>
          </div>
          <div className="glass-card p-6 flex flex-col justify-between border-t-4 border-t-danger hover:-translate-y-1 transition-transform">
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="text-slate-400 font-medium text-sm">Total Returns</p>
                <h3 className="text-2xl font-bold text-white mt-1">CFA {Number(analytics?.total_returns || 0).toLocaleString()}</h3>
              </div>
              <div className="p-3 bg-danger/20 rounded-xl"><RotateCcw className="text-danger" size={24} /></div>
            </div>
          </div>
          <div className="glass-card p-6 flex flex-col justify-between border-t-4 border-t-emerald-500 hover:-translate-y-1 transition-transform">
            <div className="flex justify-between items-start mb-4">
              <div>
                <p className="text-slate-400 font-medium text-sm">Net Revenue</p>
                <h3 className="text-2xl font-bold text-emerald-400 mt-1">CFA {Number((analytics?.total_revenue || 0) - (analytics?.total_returns || 0)).toLocaleString()}</h3>
              </div>
              <div className="p-3 bg-emerald-500/20 rounded-xl"><TrendingUp className="text-emerald-400" size={24} /></div>
            </div>
          </div>
        </div>

        {/* Data Table */}
        <div className="flex-1 glass-card flex flex-col overflow-hidden">
          <div className="p-4 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30">
            <h3 className="font-bold text-white">Invoice Records</h3>
          </div>
          <div className="flex-1 overflow-auto hide-scrollbar">
            <table className="w-full text-left">
              <thead className="sticky top-0 bg-slate-900 border-b border-slate-700 z-10 shadow-sm shadow-black/20">
                <tr>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Invoice #</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Type</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Entity / Client</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Amount</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-center">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {invoicesLoading ? (
                  <tr><td colSpan="7" className="p-8 text-center text-slate-400">Loading...</td></tr>
                ) : invoices?.length === 0 ? (
                  <tr><td colSpan="7" className="p-8 text-center text-slate-400">No invoices found.</td></tr>
                ) : (
                  invoices?.map(inv => (
                    <tr key={inv.id} className="hover:bg-slate-800/30 transition-colors group">
                      <td className="px-6 py-4 text-sm text-slate-300">{new Date(inv.created_at).toLocaleString()}</td>
                      <td className="px-6 py-4 text-sm font-medium text-white">{inv.invoice_number}</td>
                      <td className="px-6 py-4 text-sm">
                        <span className={`px-2 py-1 rounded-md text-xs font-medium border ${
                          inv.customer_type === 'Walk-In' ? 'bg-slate-800 border-slate-600 text-slate-300' :
                          inv.customer_type === 'Construction' ? 'bg-amber-900/30 border-amber-700/50 text-amber-400' :
                          'bg-indigo-900/30 border-indigo-700/50 text-indigo-400'
                        }`}>
                          {inv.customer_type}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm text-slate-300">{inv.customer_name || 'Walk-In Customer'}</td>
                      <td className="px-6 py-4 text-sm">
                        <span className={`flex items-center gap-1.5 ${
                          inv.status === 'Completed' ? 'text-emerald-400' :
                          inv.status === 'Returned' ? 'text-danger' : 'text-amber-400'
                        }`}>
                          {inv.status === 'Completed' && <CheckCircle size={14} />}
                          {inv.status === 'Returned' && <RotateCcw size={14} />}
                          {inv.status === 'Partial Return' && <AlertTriangle size={14} />}
                          {inv.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-sm font-bold text-white text-right">
                        CFA {Number(inv.final_amount).toLocaleString()}
                        {Number(inv.returned_amount) > 0 && (
                          <div className="text-xs text-danger mt-1 font-normal">- CFA {Number(inv.returned_amount).toLocaleString()}</div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-center">
                        <div className="flex items-center justify-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                          <button onClick={() => setViewingInvoice(inv)} className="p-1.5 bg-slate-700 hover:bg-slate-600 text-slate-300 hover:text-white rounded transition-colors" title="View"><Eye size={16}/></button>
                          <button onClick={() => setEditingInvoice(inv)} className="p-1.5 bg-slate-700 hover:bg-slate-600 text-slate-300 hover:text-white rounded transition-colors" title="Edit"><Edit2 size={16}/></button>
                          <button onClick={() => setReturningInvoice(inv)} className="p-1.5 bg-slate-700 hover:bg-slate-600 text-slate-300 hover:text-danger rounded transition-colors" title="Process Return"><RotateCcw size={16}/></button>
                          <button onClick={() => setConvertingInvoice(inv)} className="p-1.5 bg-slate-700 hover:bg-slate-600 text-slate-300 hover:text-indigo-400 rounded transition-colors" title="Convert Sale"><RefreshCcw size={16}/></button>
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
      
      {/* TODO: Modals for View, Edit, Return, Convert */}
      {viewingInvoice && <InvoiceViewModal invoice={viewingInvoice} onClose={() => setViewingInvoice(null)} />}
      {editingInvoice && <InvoiceEditModal invoice={editingInvoice} onClose={() => setEditingInvoice(null)} onSave={() => { queryClient.invalidateQueries(['salesSummary']); setEditingInvoice(null); }} />}
      {returningInvoice && <ReturnModal invoice={returningInvoice} onClose={() => setReturningInvoice(null)} onSave={() => { queryClient.invalidateQueries(['salesSummary', 'salesAnalytics']); setReturningInvoice(null); }} />}
      {convertingInvoice && <ConvertModal invoice={convertingInvoice} onClose={() => setConvertingInvoice(null)} onConvert={(data) => convertMutation.mutate({ invoice_id: convertingInvoice.id, ...data })} />}
    </div>
  );
};

export default SalesSummary;


