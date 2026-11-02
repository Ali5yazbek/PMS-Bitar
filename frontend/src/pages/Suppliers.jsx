import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { Search, Plus, Phone, Truck, FileText, CheckCircle, Clock, DollarSign, Printer, Receipt, FileSpreadsheet, AlertTriangle } from 'lucide-react';
import SupplierPrintLayout from '../components/SupplierPrintLayout';

const Suppliers = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [newSupplier, setNewSupplier] = useState({ 
    name: '', contact_info: '', supplier_type: ['Construction'],
    credit_limit: '', payment_terms_days: 30, opening_balance: '', opening_balance_date: ''
  });
  
  const [selectedSupplierId, setSelectedSupplierId] = useState(null);
  const [activeTab, setActiveTab] = useState('Overview');
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [selectedPO, setSelectedPO] = useState(null);
  const [paymentData, setPaymentData] = useState({ 
    amount: '', payment_date: new Date().toISOString().split('T')[0], 
    payment_method: 'Bank Transfer', reference_number: '', bank_name: '', notes: '' 
  });

  const [ledgerStartDate, setLedgerStartDate] = useState('');
  const [ledgerEndDate, setLedgerEndDate] = useState('');

  // Queries
  const { data: dashboardStats } = useQuery({
    queryKey: ['supplierDashboard'],
    queryFn: async () => {
      const res = await axios.get('/suppliers/dashboard');
      return res.data;
    }
  });

  const { data: suppliers, isLoading } = useQuery({
    queryKey: ['suppliers'],
    queryFn: async () => {
      const res = await axios.get('/suppliers');
      return res.data;
    }
  });

  const { data: supplierDetails } = useQuery({
    queryKey: ['supplier', selectedSupplierId],
    queryFn: async () => {
      const res = await axios.get(`/suppliers/${selectedSupplierId}`);
      return res.data;
    },
    enabled: !!selectedSupplierId
  });

  // Mutations
  const addMutation = useMutation({
    mutationFn: (data) => axios.post('/suppliers', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['suppliers']);
      setShowAdd(false);
      setNewSupplier({ name: '', contact_info: '', supplier_type: ['Construction'], credit_limit: '', payment_terms_days: 30, opening_balance: '', opening_balance_date: '' });
    }
  });

  const paymentMutation = useMutation({
    mutationFn: (data) => axios.post(`/suppliers/${selectedSupplierId}/payments`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['supplier', selectedSupplierId]);
      queryClient.invalidateQueries(['supplierDashboard']);
      setShowPaymentModal(false);
      setSelectedPO(null);
      setPaymentData({ amount: '', payment_date: new Date().toISOString().split('T')[0], payment_method: 'Bank Transfer', reference_number: '', bank_name: '', notes: '' });
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to record payment');
    }
  });

  const handleOpenPaymentModal = (po = null) => {
    setSelectedPO(po);
    const maxAmt = po ? Number(po.remaining_balance || 0) : Number(supplierDetails?.summary?.currentBalance || 0);
    setPaymentData({ 
      amount: maxAmt > 0 ? maxAmt : '', 
      payment_date: new Date().toISOString().split('T')[0], 
      payment_method: 'Bank Transfer', 
      reference_number: '', 
      bank_name: '', 
      notes: po ? `Payment for Invoice #${po.po_number}` : '' 
    });
    setShowPaymentModal(true);
  };

  const handleConfirmPayment = () => {
    const payload = {
      ...paymentData,
      purchase_order_id: selectedPO ? selectedPO.id : undefined
    };
    paymentMutation.mutate(payload);
  };

  const filtered = suppliers?.filter(s => s.name.toLowerCase().includes(searchTerm.toLowerCase()));

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="flex h-full w-full gap-6 p-6 print:block print:p-0 print:h-auto">
      <div className="flex-1 flex flex-col glass-panel p-6 overflow-hidden print:hidden">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-white flex items-center gap-2">
            <Truck className="text-primary" /> {t('suppliers.suppliers_accounts', { defaultValue: `Suppliers Accounts` })}
          </h1>
          <div className="flex gap-4">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input type="text" placeholder={t('suppliers.search', { defaultValue: `Search...` })} value={searchTerm} onChange={e => setSearchTerm(e.target.value)} className="pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white" />
            </div>
            <button onClick={() => setShowAdd(!showAdd)} className="bg-primary hover:bg-indigo-600 px-4 py-2 rounded-lg text-white flex items-center gap-2">
              <Plus size={18} /> {t('suppliers.add_supplier', { defaultValue: `Add Supplier` })}
            </button>
          </div>
        </div>

        {/* Global Dashboard Cards */}
        {!selectedSupplierId && dashboardStats && (
          <div className="grid grid-cols-4 gap-4 mb-6">
            <div className="glass-card p-4 border-l-4 border-emerald-500">
              <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('suppliers.today_s_purchases', { defaultValue: `Today's Purchases` })}</div>
              <div className="text-xl font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(dashboardStats.stats.todayPurchases).toLocaleString()}</div>
            </div>
            <div className="glass-card p-4 border-l-4 border-blue-500">
              <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('suppliers.today_s_payments', { defaultValue: `Today's Payments` })}</div>
              <div className="text-xl font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(dashboardStats.stats.todayPayments).toLocaleString()}</div>
            </div>
            <div className="glass-card p-4 border-l-4 border-amber-500">
              <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('suppliers.monthly_purchases', { defaultValue: `Monthly Purchases` })}</div>
              <div className="text-xl font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(dashboardStats.stats.monthlyPurchases).toLocaleString()}</div>
            </div>
            <div className="glass-card p-4 border-l-4 border-red-500">
              <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('suppliers.total_supplier_debt', { defaultValue: `Total Supplier Debt` })}</div>
              <div className="text-xl font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(dashboardStats.stats.totalDebt).toLocaleString()}</div>
            </div>
          </div>
        )}

        {showAdd && (
          <div className="glass-card p-6 mb-6">
            <h3 className="text-lg font-bold text-white mb-4">{t('suppliers.new_supplier_account', { defaultValue: `New Supplier Account` })}</h3>
            <div className="grid grid-cols-3 gap-4 mb-4">
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.name', { defaultValue: `Name` })}</label>
                <input type="text" value={newSupplier.name} onChange={e => setNewSupplier({...newSupplier, name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.contact_phone', { defaultValue: `Contact Phone` })}</label>
                <input type="text" value={newSupplier.contact_info} onChange={e => setNewSupplier({...newSupplier, contact_info: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.payment_terms_days', { defaultValue: `Payment Terms (Days)` })}</label>
                <input type="number" value={newSupplier.payment_terms_days} onChange={e => setNewSupplier({...newSupplier, payment_terms_days: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.credit_limit', { defaultValue: `Credit Limit (CFA)` })}</label>
                <input type="number" value={newSupplier.credit_limit} onChange={e => setNewSupplier({...newSupplier, credit_limit: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.opening_balance_debt', { defaultValue: `Opening Balance (Debt)` })}</label>
                <input type="number" value={newSupplier.opening_balance} onChange={e => setNewSupplier({...newSupplier, opening_balance: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
              <div>
                <label className="block text-xs text-muted mb-1">{t('suppliers.opening_balance_date', { defaultValue: `Opening Balance Date` })}</label>
                <input type="date" value={newSupplier.opening_balance_date} onChange={e => setNewSupplier({...newSupplier, opening_balance_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
              </div>
            </div>
            <div className="flex justify-end gap-2">
              <button onClick={() => setShowAdd(false)} className="px-4 py-2 bg-slate-700 text-white rounded-lg">{t('suppliers.cancel', { defaultValue: `Cancel` })}</button>
              <button onClick={() => addMutation.mutate(newSupplier)} className="px-4 py-2 bg-success text-white rounded-lg">{t('suppliers.save', { defaultValue: `Save` })}</button>
            </div>
          </div>
        )}

        <div className="flex-1 overflow-y-auto pr-2 space-y-3 custom-scrollbar">
          {isLoading ? <div className="text-muted">{t('suppliers.loading', { defaultValue: `Loading...` })}</div> : filtered?.map(sup => (
            <div key={sup.id} onClick={() => setSelectedSupplierId(sup.id)} className={`glass-card p-4 cursor-pointer transition-all hover:border-primary ${selectedSupplierId === sup.id ? 'border-primary bg-slate-800/80' : 'border-slate-700'}`}>
              <div className="flex justify-between items-center">
                <div>
                  <h3 className="font-bold text-lg text-white">{sup.name}</h3>
                  <div className="flex items-center text-sm text-muted mt-1 gap-4">
                    <span className="flex items-center gap-1"><Phone size={14} /> {sup.contact_info || 'N/A'}</span>
                    <span className="bg-slate-700 px-2 py-0.5 rounded text-xs">{sup.supplier_type}</span>
                  </div>
                </div>
                <div className="text-right">
                   <div className="text-xs text-muted mb-1">{t('suppliers.current_balance', { defaultValue: `Current Balance` })}</div>
                   {/* We might want to show balance here, but we'd need it in the index API. For now, it's ok */}
                   <span className="text-white font-bold">{t('suppliers.view_ledger', { defaultValue: `View Ledger →` })}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {supplierDetails && (
        <div className="w-[800px] glass-panel flex flex-col overflow-hidden print:hidden">
          {/* Supplier Header */}
          <div className="p-6 border-b border-slate-800 flex justify-between items-start">
            <div>
              <h2 className="text-2xl font-bold text-white flex items-center gap-3">
                {supplierDetails.supplier.name}
                {Number(supplierDetails.summary.currentBalance) > Number(supplierDetails.supplier.credit_limit || 99999999) && (
                  <span className="bg-red-500/20 text-red-500 text-xs px-2 py-1 rounded flex items-center gap-1">
                    <AlertTriangle size={12} /> {t('suppliers.credit_limit_exceeded', { defaultValue: `Credit Limit Exceeded` })}
                  </span>
                )}
              </h2>
              <div className="text-muted text-sm mt-1 flex gap-4">
                 <span>{t('suppliers.credit_limit_cfa', { defaultValue: `Credit Limit: CFA` })} {Number(supplierDetails.supplier.credit_limit || 0).toLocaleString()}</span>
                 <span>{t('suppliers.terms', { defaultValue: `Terms:` })} {supplierDetails.supplier.payment_terms_days || 30} {t('suppliers.days', { defaultValue: `Days` })}</span>
              </div>
            </div>
            <div className="flex gap-2">
              {Number(supplierDetails.summary.currentBalance || 0) <= 0 ? (
                <div className="bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 px-4 py-2 rounded-lg flex items-center gap-2 text-sm font-semibold">
                  <CheckCircle size={18} /> {t('suppliers.fully_paid', { defaultValue: `Fully Paid` })}
                </div>
              ) : (
                <button onClick={() => handleOpenPaymentModal(null)} className="bg-success hover:bg-emerald-600 px-4 py-2 rounded-lg text-white flex items-center gap-2 font-medium transition-colors shadow-lg shadow-emerald-950/20">
                  <DollarSign size={18} /> {t('suppliers.record_payment', { defaultValue: `Record Payment` })}
                </button>
              )}
              <button onClick={handlePrint} className="bg-slate-700 hover:bg-slate-600 px-4 py-2 rounded-lg text-white flex items-center gap-2">
                <Printer size={18} /> {t('suppliers.print_statement', { defaultValue: `Print Statement` })}
              </button>
            </div>
          </div>

          {/* Tabs Navigation */}
          <div className="flex px-6 pt-4 border-b border-slate-800 gap-6">
            {['Overview', 'Invoices', 'Payments', 'Account Statement'].map(tab => (
              <button 
                key={tab}
                onClick={() => setActiveTab(tab)} 
                className={`pb-3 font-medium transition-colors border-b-2 ${activeTab === tab ? 'text-primary border-primary' : 'text-slate-400 border-transparent hover:text-white'}`}
              >
                {tab}
              </button>
            ))}
            <button onClick={() => setSelectedSupplierId(null)} className="ml-auto text-slate-500 hover:text-white pb-3">✕</button>
          </div>

          {/* Tab Content */}
          <div className="flex-1 overflow-y-auto p-6 custom-scrollbar">
            
            {activeTab === 'Overview' && (
              <div className="space-y-6">
                <div className="grid grid-cols-3 gap-4">
                  <div className="glass-card p-4">
                    <div className="text-xs text-muted uppercase mb-1">{t('suppliers.total_purchases', { defaultValue: `Total Purchases` })}</div>
                    <div className="text-2xl font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.summary.totalPurchases).toLocaleString()}</div>
                  </div>
                  <div className="glass-card p-4">
                    <div className="text-xs text-muted uppercase mb-1">{t('suppliers.total_paid', { defaultValue: `Total Paid` })}</div>
                    <div className="text-2xl font-bold text-emerald-400">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.summary.totalPaid).toLocaleString()}</div>
                  </div>
                  <div className="glass-card p-4">
                    <div className="text-xs text-muted uppercase mb-1">{t('suppliers.outstanding_balance', { defaultValue: `Outstanding Balance` })}</div>
                    <div className={`text-2xl font-bold ${supplierDetails.summary.currentBalance > 0 ? 'text-amber-400' : 'text-white'}`}>
                      {t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.summary.currentBalance).toLocaleString()}
                    </div>
                  </div>
                </div>

                {/* Aging Report */}
                <div className="glass-card p-6">
                  <h3 className="text-white font-bold mb-4 flex items-center gap-2"><Clock size={18} className="text-amber-500" /> {t('suppliers.aging_report_overdue_invoices', { defaultValue: `Aging Report (Overdue Invoices)` })}</h3>
                  <div className="grid grid-cols-4 gap-4">
                    <div className="border border-slate-700 rounded p-3 text-center">
                      <div className="text-xs text-muted mb-1">{t('suppliers.0_30_days', { defaultValue: `0 - 30 Days` })}</div>
                      <div className="text-lg font-bold text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.aging['0_30']).toLocaleString()}</div>
                    </div>
                    <div className="border border-slate-700 rounded p-3 text-center">
                      <div className="text-xs text-amber-500/70 mb-1">{t('suppliers.31_60_days', { defaultValue: `31 - 60 Days` })}</div>
                      <div className="text-lg font-bold text-amber-500">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.aging['31_60']).toLocaleString()}</div>
                    </div>
                    <div className="border border-slate-700 rounded p-3 text-center">
                      <div className="text-xs text-orange-500/70 mb-1">{t('suppliers.61_90_days', { defaultValue: `61 - 90 Days` })}</div>
                      <div className="text-lg font-bold text-orange-500">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.aging['61_90']).toLocaleString()}</div>
                    </div>
                    <div className="border border-red-500/30 bg-red-500/5 rounded p-3 text-center">
                      <div className="text-xs text-red-500/70 mb-1">{t('suppliers.90_days', { defaultValue: `90+ Days` })}</div>
                      <div className="text-lg font-bold text-red-500">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(supplierDetails.aging['90_plus']).toLocaleString()}</div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'Invoices' && (
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-700 text-slate-400">
                    <th className="py-3 font-medium">{t('suppliers.inv', { defaultValue: `Inv #` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.date', { defaultValue: `Date` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.due_date', { defaultValue: `Due Date` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.amount', { defaultValue: `Amount` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.paid', { defaultValue: `Paid` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.remaining', { defaultValue: `Remaining` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.status', { defaultValue: `Status` })}</th>
                    <th className="py-3 font-medium text-right">{t('suppliers.action', { defaultValue: `Action` })}</th>
                  </tr>
                </thead>
                <tbody>
                  {supplierDetails.purchases.map(po => {
                    const isOverdue = Number(po.remaining_balance) > 0 && po.due_date && new Date(po.due_date) < new Date();
                    const isFullyPaid = po.payment_status === 'Paid' || Number(po.remaining_balance) <= 0;
                    return (
                    <tr key={po.id} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                      <td className="py-3 text-white font-medium">{po.po_number}</td>
                      <td className="py-3 text-slate-300">{po.invoice_date}</td>
                      <td className={`py-3 ${isOverdue ? 'text-red-400 font-bold' : 'text-slate-300'}`}>{po.due_date}</td>
                      <td className="py-3 text-white">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(po.total_price).toLocaleString()}</td>
                      <td className="py-3 text-emerald-400">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(po.amount_paid || 0).toLocaleString()}</td>
                      <td className="py-3 text-amber-400">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(po.remaining_balance).toLocaleString()}</td>
                      <td className="py-3">
                         <span className={`px-2 py-1 rounded text-[10px] uppercase font-bold ${isFullyPaid ? 'bg-emerald-500/20 text-emerald-400' : isOverdue ? 'bg-red-500/20 text-red-400' : 'bg-amber-500/20 text-amber-400'}`}>
                           {isFullyPaid ? 'Paid' : isOverdue ? 'Overdue' : po.payment_status}
                         </span>
                      </td>
                      <td className="py-3 text-right">
                        {isFullyPaid ? (
                          <span className="inline-flex items-center gap-1 text-emerald-400 text-xs font-semibold">
                            <CheckCircle size={14} /> Paid
                          </span>
                        ) : (
                          <button
                            onClick={() => handleOpenPaymentModal(po)}
                            className="px-2.5 py-1 bg-emerald-600/20 hover:bg-emerald-600/40 text-emerald-300 border border-emerald-500/30 rounded text-xs font-medium transition-colors"
                          >
                            Pay Invoice
                          </button>
                        )}
                      </td>
                    </tr>
                    );
                  })}
                </tbody>
              </table>
            )}

            {activeTab === 'Payments' && (
              <table className="w-full text-left border-collapse text-sm">
                <thead>
                  <tr className="border-b border-slate-700 text-slate-400">
                    <th className="py-3 font-medium">{t('suppliers.date', { defaultValue: `Date` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.amount', { defaultValue: `Amount` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.method', { defaultValue: `Method` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.ref_number', { defaultValue: `Ref Number` })}</th>
                    <th className="py-3 font-medium">{t('suppliers.bank', { defaultValue: `Bank` })}</th>
                  </tr>
                </thead>
                <tbody>
                  {supplierDetails.payments.map(pay => (
                    <tr key={pay.id} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                      <td className="py-3 text-slate-300">{pay.payment_date}</td>
                      <td className="py-3 text-emerald-400 font-bold">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(pay.amount).toLocaleString()}</td>
                      <td className="py-3 text-slate-300">{pay.payment_method}</td>
                      <td className="py-3 text-slate-300">{pay.reference_number || '-'}</td>
                      <td className="py-3 text-slate-300">{pay.bank_name || '-'}</td>
                    </tr>
                  ))}
                  {supplierDetails.payments.length === 0 && <tr><td colSpan="5" className="py-4 text-center text-muted">{t('suppliers.no_payments_recorded', { defaultValue: `No payments recorded` })}</td></tr>}
                </tbody>
              </table>
            )}

            {activeTab === 'Account Statement' && (
              <div className="glass-card rounded-lg overflow-hidden border border-slate-700">
                <div className="p-4 bg-slate-800/50 border-b border-slate-700 flex items-center gap-4">
                  <div className="text-sm text-slate-300 font-medium">{t('suppliers.filter_by_date', { defaultValue: `Filter by Date:` })}</div>
                  <input 
                    type="date" 
                    value={ledgerStartDate} 
                    onChange={e => setLedgerStartDate(e.target.value)}
                    className="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-sm text-white" 
                  />
                  <span className="text-slate-500">{t('suppliers.to', { defaultValue: `to` })}</span>
                  <input 
                    type="date" 
                    value={ledgerEndDate} 
                    onChange={e => setLedgerEndDate(e.target.value)}
                    className="bg-slate-900 border border-slate-600 rounded px-2 py-1 text-sm text-white" 
                  />
                  {(ledgerStartDate || ledgerEndDate) && (
                    <button 
                      onClick={() => { setLedgerStartDate(''); setLedgerEndDate(''); }}
                      className="ml-auto text-xs text-slate-400 hover:text-white"
                    >
                      {t('suppliers.clear_filter', { defaultValue: `Clear Filter` })}
                    </button>
                  )}
                </div>
                <table className="w-full text-left border-collapse text-sm">
                  <thead>
                    <tr className="bg-slate-800 text-slate-300">
                      <th className="py-3 px-4 font-medium">{t('suppliers.date', { defaultValue: `Date` })}</th>
                      <th className="py-3 px-4 font-medium">{t('suppliers.reference', { defaultValue: `Reference` })}</th>
                      <th className="py-3 px-4 font-medium">{t('suppliers.type', { defaultValue: `Type` })}</th>
                      <th className="py-3 px-4 font-medium text-right">{t('suppliers.debit', { defaultValue: `Debit` })}</th>
                      <th className="py-3 px-4 font-medium text-right">{t('suppliers.credit', { defaultValue: `Credit` })}</th>
                      <th className="py-3 px-4 font-medium text-right bg-slate-900">{t('suppliers.balance', { defaultValue: `Balance` })}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {supplierDetails.transactions.filter(tx => {
                       if (ledgerStartDate && tx.transaction_date < ledgerStartDate) return false;
                       if (ledgerEndDate && tx.transaction_date > ledgerEndDate) return false;
                       return true;
                    }).map(tx => {
                       const isDebit = ['Purchase', 'Opening Balance'].includes(tx.type) || tx.amount > 0;
                       const debitAmt = isDebit ? Math.abs(tx.amount) : 0;
                       const creditAmt = !isDebit ? Math.abs(tx.amount) : 0;
                       
                       return (
                        <tr key={tx.id} className="border-b border-slate-800/50 hover:bg-slate-800/30">
                          <td className="py-3 px-4 text-slate-300">{tx.transaction_date}</td>
                          <td className="py-3 px-4 text-white font-medium">{tx.reference_id}</td>
                          <td className="py-3 px-4 text-slate-400">{tx.type}</td>
                          <td className="py-3 px-4 text-right text-red-400">{debitAmt > 0 ? `CFA ${Number(debitAmt).toLocaleString()}` : '-'}</td>
                          <td className="py-3 px-4 text-right text-emerald-400">{creditAmt > 0 ? `CFA ${Number(creditAmt).toLocaleString()}` : '-'}</td>
                          <td className="py-3 px-4 text-right font-bold text-white bg-slate-900/50">{t('suppliers.cfa', { defaultValue: `CFA` })} {Number(tx.balance_after).toLocaleString()}</td>
                        </tr>
                       );
                    })}
                  </tbody>
                </table>
              </div>
            )}

          </div>
        </div>
      )}

      {showPaymentModal && (() => {
        const maxPayable = selectedPO ? Number(selectedPO.remaining_balance || 0) : Number(supplierDetails?.summary?.currentBalance || 0);
        const isOverpaying = Number(paymentData.amount) > maxPayable;

        return (
            <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
              <div className="glass-panel w-full max-w-md p-6">
                <div className="flex justify-between items-center mb-4">
                  <h2 className="text-xl font-bold text-white">
                    {selectedPO ? `Pay Invoice #${selectedPO.po_number}` : t('suppliers.record_payment', { defaultValue: `Record Payment` })}
                  </h2>
                  <button onClick={() => { setShowPaymentModal(false); setSelectedPO(null); }} className="text-slate-400 hover:text-white">✕</button>
                </div>

                {selectedPO ? (
                  <div className="p-3 bg-indigo-500/15 border border-indigo-500/30 rounded-lg text-xs text-indigo-300 flex justify-between items-center mb-4">
                    <div>
                      <span className="font-bold text-white">Target Invoice: #{selectedPO.po_number}</span> ({selectedPO.item_name})
                      <div className="text-muted text-[11px] mt-0.5">Total: CFA {Number(selectedPO.total_price).toLocaleString()} • Paid: CFA {Number(selectedPO.amount_paid || 0).toLocaleString()}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-amber-400 font-bold text-sm">CFA {Number(selectedPO.remaining_balance).toLocaleString()}</div>
                      <div className="text-[10px] text-muted">Remaining Balance</div>
                    </div>
                  </div>
                ) : (
                  <div className="p-3 bg-indigo-500/15 border border-indigo-500/30 rounded-lg text-xs text-indigo-300 flex justify-between items-center mb-4">
                    <div>
                      <span className="font-bold text-white">General Payment (FIFO Allocation)</span>
                      <div className="text-muted text-[11px] mt-0.5">Automatically pays oldest unpaid invoices first</div>
                    </div>
                    <div className="text-right">
                      <div className="text-amber-400 font-bold text-sm">CFA {Number(supplierDetails.summary.currentBalance).toLocaleString()}</div>
                      <div className="text-[10px] text-muted">Total Outstanding</div>
                    </div>
                  </div>
                )}
                
                <div className="space-y-4 mb-6">
                  <div>
                    <div className="flex justify-between items-center mb-1">
                      <label className="text-muted text-sm">{t('suppliers.amount', { defaultValue: `Amount` })} (CFA)</label>
                      {maxPayable > 0 && (
                        <button 
                          type="button" 
                          onClick={() => setPaymentData({...paymentData, amount: maxPayable})}
                          className="text-xs text-primary hover:text-indigo-400 font-medium underline"
                        >
                          Pay Full (CFA {Number(maxPayable).toLocaleString()})
                        </button>
                      )}
                    </div>
                    <input 
                      type="number" 
                      max={maxPayable}
                      value={paymentData.amount} 
                      onChange={e => setPaymentData({...paymentData, amount: e.target.value})} 
                      className={`w-full bg-slate-800 border ${isOverpaying ? 'border-red-500 focus:border-red-500' : 'border-slate-700 focus:border-primary'} rounded-lg px-3 py-2 text-white`} 
                    />
                    {isOverpaying && (
                      <p className="text-xs text-red-400 mt-1 flex items-center gap-1">
                        <AlertTriangle size={12} /> Amount cannot exceed remaining balance of CFA {Number(maxPayable).toLocaleString()}
                      </p>
                    )}
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-muted text-xs mb-1">{t('suppliers.date', { defaultValue: `Date` })}</label>
                      <input type="date" value={paymentData.payment_date} onChange={e => setPaymentData({...paymentData, payment_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                    </div>
                    <div>
                      <label className="block text-muted text-xs mb-1">{t('suppliers.method', { defaultValue: `Method` })}</label>
                      <select value={paymentData.payment_method} onChange={e => setPaymentData({...paymentData, payment_method: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm">
                        <option>Bank Transfer</option>
                        <option>Cash</option>
                        <option>Check</option>
                      </select>
                    </div>
                  </div>
                  {paymentData.payment_method !== 'Cash' && (
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-muted text-xs mb-1">{t('suppliers.bank_name', { defaultValue: `Bank Name` })}</label>
                        <input type="text" value={paymentData.bank_name} onChange={e => setPaymentData({...paymentData, bank_name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                      </div>
                      <div>
                        <label className="block text-muted text-xs mb-1">{t('suppliers.ref_check', { defaultValue: `Ref / Check #` })}</label>
                        <input type="text" value={paymentData.reference_number} onChange={e => setPaymentData({...paymentData, reference_number: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                      </div>
                    </div>
                  )}
                  {paymentData.payment_method === 'Cash' && (
                    <div>
                      <label className="block text-muted text-xs mb-1">{t('suppliers.ref_check', { defaultValue: `Ref / Check #` })}</label>
                      <input type="text" value={paymentData.reference_number} onChange={e => setPaymentData({...paymentData, reference_number: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                    </div>
                  )}
                  <div>
                    <label className="block text-muted text-xs mb-1">{t('suppliers.notes', { defaultValue: `Notes` })}</label>
                    <textarea value={paymentData.notes} onChange={e => setPaymentData({...paymentData, notes: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white h-16 text-sm" />
                  </div>
                </div>

                <div className="flex justify-end gap-3">
                  <button onClick={() => { setShowPaymentModal(false); setSelectedPO(null); }} className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-sm transition-colors">{t('suppliers.cancel', { defaultValue: `Cancel` })}</button>
                  <button 
                    onClick={handleConfirmPayment} 
                    disabled={paymentMutation.isPending || !paymentData.amount || Number(paymentData.amount) <= 0 || isOverpaying || maxPayable <= 0} 
                    className="px-4 py-2 bg-success hover:bg-emerald-600 text-white rounded-lg disabled:opacity-50 flex items-center gap-2 text-sm font-medium transition-colors"
                  >
                    {paymentMutation.isPending ? 'Processing...' : 'Confirm Payment'}
                  </button>
                </div>
              </div>
            </div>
          );
        })()}

      <SupplierPrintLayout supplierDetails={supplierDetails} />
    </div>
  );
};

export default Suppliers;
