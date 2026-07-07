import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { DollarSign, AlertCircle, RefreshCw, ArrowLeft, Search, Filter, FileText } from 'lucide-react';

const Rent = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building');
  const initialSearch = searchParams.get('search') || '';
  const [paymentModal, setPaymentModal] = useState(null); // { invoice_id, max_amount, account_id, insurance_balance }
  const [payAmount, setPayAmount] = useState('');
  const [searchTerm, setSearchTerm] = useState(initialSearch);
  const [statusFilter, setStatusFilter] = useState('All');

  const { data: invoices, isLoading } = useQuery({
    queryKey: ['rentInvoices'],
    queryFn: async () => {
      const res = await api.get('/rent/invoices');
      return res.data;
    }
  });

  const generateMutation = useMutation({
    mutationFn: () => api.post('/rent/generate'),
    onSuccess: () => {
      queryClient.invalidateQueries(['rentInvoices']);
      alert('Invoices generated successfully');
    }
  });

  const payMutation = useMutation({
    mutationFn: (data) => api.post('/rent/payment', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['rentInvoices']);
      setPaymentModal(null);
      setPayAmount('');
    }
  });

  const payFromInsuranceMutation = useMutation({
    mutationFn: (data) => api.post('/insurance/transaction', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['rentInvoices']);
      setPaymentModal(null);
      setPayAmount('');
      alert('Paid from insurance successfully');
    },
    onError: (err) => {
      alert('Failed to pay from insurance: ' + (err.response?.data?.error || err.message));
    }
  });

  const getStatusColor = (status) => {
    switch(status) {
      case 'Paid': return 'bg-success/20 text-success border border-success/30';
      case 'Unpaid': return 'bg-danger/20 text-danger border border-danger/30';
      case 'Partial': return 'bg-warning/20 text-warning border border-warning/30';
      case 'Overdue': return 'bg-danger text-white font-bold border border-danger shadow-lg shadow-danger/20';
      default: return 'bg-slate-800 text-slate-300 border border-slate-600';
    }
  };

  if (isLoading) return <div className="p-8 text-muted">{t('rent.loading_invoices', { defaultValue: `Loading invoices...` })}</div>;

  const displayedInvoices = invoices?.filter(inv => {
    const isBuildingMatch = buildingId ? inv.building_id == buildingId : true;
    const matchesSearch = inv.tenant_name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          inv.invoice_number?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          inv.apartment_code?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = statusFilter === 'All' || inv.status === statusFilter;
    
    return isBuildingMatch && matchesSearch && matchesStatus;
  });

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        {buildingId && (
          <button 
            onClick={() => navigate(`/buildings/${buildingId}`)}
            className="flex items-center gap-2 text-indigo-400 hover:text-white transition-colors font-medium mb-6"
          >
            <ArrowLeft size={20} />
            {t('rent.back_to_building', { defaultValue: `Back to Building` })}
          </button>
        )}
        
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <FileText className="mr-3 text-primary" size={32} />
              {t('rent.rent_management', { defaultValue: `Rent Management` })}
            </h1>
            <p className="text-muted mt-2">{t('rent.track_monthly_rent_invoices_du', { defaultValue: `Track monthly rent invoices, due dates, and payments` })}</p>
          </div>
          <button 
            onClick={() => generateMutation.mutate()}
            className="bg-primary/20 hover:bg-primary/30 text-indigo-300 border border-primary/30 px-4 py-2 rounded-xl flex items-center gap-2 font-medium transition-colors"
          >
            <RefreshCw size={18} className={generateMutation.isLoading ? "animate-spin" : ""} />
            <span>{t('rent.generate_missing_monthly_invoi', { defaultValue: `Generate Missing Monthly Invoices` })}</span>
          </button>
        </div>

        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 glass-card p-4 mb-6">
          <div className="flex-1 flex gap-4 w-full">
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
              <input 
                type="text" 
                placeholder={t('rent.search_by_tenant_invoice_or_ap', { defaultValue: `Search by tenant, invoice #, or apartment...` })} 
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"
              />
            </div>
            <div className="flex items-center gap-2">
              <Filter className="text-muted" size={18} />
              <select 
                value={statusFilter}
                onChange={e => setStatusFilter(e.target.value)}
                className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary text-sm"
              >
                <option value="All">{t('rent.all_statuses', { defaultValue: `All Statuses` })}</option>
                <option value="Paid">{t('rent.paid', { defaultValue: `Paid` })}</option>
                <option value="Partial">{t('rent.partial', { defaultValue: `Partial` })}</option>
                <option value="Unpaid">{t('rent.unpaid', { defaultValue: `Unpaid` })}</option>
              </select>
            </div>
          </div>
        </div>

        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-left">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.invoice', { defaultValue: `Invoice` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.apartment', { defaultValue: `Apartment` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.tenant', { defaultValue: `Tenant` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.due_date', { defaultValue: `Due Date` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.amount', { defaultValue: `Amount` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.status', { defaultValue: `Status` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.debt', { defaultValue: `Debt` })}</th>
                <th className="px-6 py-4 text-right text-xs font-semibold text-muted uppercase tracking-wider">{t('rent.action', { defaultValue: `Action` })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {displayedInvoices?.map(inv => (
                <tr key={inv.id} className={`hover:bg-slate-800/30 transition-colors ${Number(inv.outstanding_debt) > 0 ? "bg-danger/5" : ""}`}>
                  <td className="px-6 py-4 font-medium text-white">{inv.invoice_number}</td>
                  <td className="px-6 py-4 text-sm text-slate-300">{inv.building_name} - {inv.apartment_code}</td>
                  <td className="px-6 py-4">
                    <div className="text-sm font-medium text-white">{inv.tenant_name}</div>
                    <div className="text-xs text-slate-400">{inv.tenant_phone}</div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-300">{inv.due_date}</td>
                  <td className="px-6 py-4 text-sm font-medium text-white">{t('rent.cfa', { defaultValue: `CFA` })} {Number(inv.amount).toLocaleString()}</td>
                  <td className="px-6 py-4">
                    <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${getStatusColor(inv.status)}`}>
                      {inv.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-bold text-danger text-sm flex items-center h-full pt-[1.2rem]">
                    {Number(inv.outstanding_debt) > 0 ? `CFA ${Number(inv.outstanding_debt).toLocaleString()}` : '-'}
                    {Number(inv.outstanding_debt) > 0 && <AlertCircle size={14} className="ml-1" />}
                  </td>
                  <td className="px-6 py-4 text-right text-sm">
                    {Number(inv.outstanding_debt) > 0 && (
                      <button 
                        onClick={() => { 
                          setPaymentModal({ 
                            invoice_id: inv.id, 
                            max_amount: inv.outstanding_debt,
                            account_id: inv.insurance_account_id,
                            insurance_balance: inv.insurance_balance
                          }); 
                          setPayAmount(inv.outstanding_debt); 
                        }}
                        className="bg-success/20 text-success hover:bg-success/30 px-3 py-1.5 rounded-lg font-medium flex items-center gap-1 ml-auto transition-colors border border-success/20"
                      >
                        <DollarSign size={16} /> {t('rent.pay', { defaultValue: `Pay` })}
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {displayedInvoices?.length === 0 && <div className="p-8 text-center text-muted">{t('rent.no_invoices_found', { defaultValue: `No invoices found.` })}</div>}
        </div>

        {paymentModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="glass-card p-6 w-96 border border-slate-700 animate-in zoom-in-95 duration-200">
              <h3 className="text-xl font-bold mb-4 text-white">{t('rent.record_payment', { defaultValue: `Record Payment` })}</h3>
              <div className="mb-6">
                <label className="block text-sm font-medium text-muted mb-2">{t('rent.amount_to_pay_cfa', { defaultValue: `Amount to Pay (CFA)` })}</label>
                <input 
                  type="number" 
                  max={paymentModal.max_amount}
                  value={payAmount}
                  onChange={e => setPayAmount(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary text-lg font-bold"
                  autoFocus
                />
                <p className="text-sm text-warning mt-2">{t('rent.outstanding_debt_cfa', { defaultValue: `Outstanding debt: CFA` })} {Number(paymentModal.max_amount).toLocaleString()}</p>
                {Number(paymentModal.insurance_balance) > 0 && (
                  <p className="text-sm text-indigo-400 mt-1">{t('rent.available_insurance_balance_cf', { defaultValue: `Available Insurance Balance: CFA` })} {Number(paymentModal.insurance_balance).toLocaleString()}</p>
                )}
              </div>
              <div className="flex flex-col gap-3">
                <div className="flex gap-3">
                  <button onClick={() => setPaymentModal(null)} className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg transition-colors flex-1">{t('rent.cancel', { defaultValue: `Cancel` })}</button>
                  <button onClick={() => payMutation.mutate({ invoice_id: paymentModal.invoice_id, amount: payAmount })} className="bg-success hover:bg-green-600 text-white px-4 py-2 rounded-lg transition-colors flex-1 font-medium shadow-lg shadow-success/20">{t('rent.pay_cash', { defaultValue: `Pay Cash` })}</button>
                </div>
                {Number(paymentModal.insurance_balance) > 0 && (
                  <button 
                    onClick={() => {
                      if(Number(payAmount) > Number(paymentModal.insurance_balance)) {
                        alert("Amount exceeds available insurance balance!");
                        return;
                      }
                      payFromInsuranceMutation.mutate({ 
                        account_id: paymentModal.account_id,
                        type: 'Apply_To_Rent',
                        amount: payAmount,
                        invoice_id: paymentModal.invoice_id,
                        notes: 'Applied from Insurance to Rent'
                      });
                    }} 
                    className="bg-indigo-600 hover:bg-indigo-500 text-white px-4 py-2 rounded-lg transition-colors w-full font-medium shadow-lg shadow-indigo-600/20"
                  >
                    {t('rent.pay_from_insurance', { defaultValue: `Pay from Insurance` })}
                  </button>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Rent;
