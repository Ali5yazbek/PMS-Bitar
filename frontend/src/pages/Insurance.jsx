import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Shield, ArrowDownCircle, ArrowUpCircle, RefreshCcw, ArrowLeft, Search, ArrowRightCircle } from 'lucide-react';

const Insurance = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const buildingId = searchParams.get('building');
  const [modal, setModal] = useState(null); // { type, account_id, max_amount, contract_id }
  const [formData, setFormData] = useState({ amount: '', notes: '', damage_reason: '', invoice_id: '' });
  const [searchTerm, setSearchTerm] = useState('');

  const { data: accounts, isLoading } = useQuery({ queryKey: ['insuranceAccounts'], queryFn: async () => (await api.get('/insurance')).data });
  const { data: invoices } = useQuery({ queryKey: ['rentInvoices'], queryFn: async () => (await api.get('/rent/invoices')).data });

  const transactionMutation = useMutation({
    mutationFn: (data) => api.post('/insurance/transaction', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['insuranceAccounts']);
      setModal(null);
      setFormData({ amount: '', notes: '', damage_reason: '', invoice_id: '' });
    }
  });

  const handleAction = (type, account) => {
    let maxAmt = Number(account.total_saved);
    if (type === 'Deposit') {
      const required = Number(account.monthly_insurance);
      const collected = Number(account.collected_this_month || 0);
      maxAmt = Math.max(0, required - collected);
    }
    
    setModal({ type, account_id: account.id, max_amount: maxAmt, tenant_name: account.tenant_name, contract_id: account.contract_id });
    
    // Auto-fill amount
    if (type === 'Refund') {
      setFormData({ ...formData, amount: account.total_saved });
    } else if (type === 'Deposit') {
      setFormData({ ...formData, amount: maxAmt });
    }
  };

  const submitTransaction = () => {
    transactionMutation.mutate({
      account_id: modal.account_id,
      type: modal.type,
      ...formData
    });
  };

  if (isLoading) return <div className="p-8 text-muted">{t('insurance.loading', { defaultValue: `Loading...` })}</div>;

  const displayedAccounts = accounts?.filter(acc => {
    const isBuildingMatch = buildingId ? acc.building_id == buildingId : true;
    const matchesSearch = acc.tenant_name?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          acc.apartment_code?.toLowerCase().includes(searchTerm.toLowerCase());
    return isBuildingMatch && matchesSearch;
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
            {t('insurance.back_to_building', { defaultValue: `Back to Building` })}
          </button>
        )}
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Shield className="mr-3 text-primary" size={32} />
              {t('insurance.insurance_deposits', { defaultValue: `Insurance & Deposits` })}
            </h1>
            <p className="text-muted mt-2">{t('insurance.manage_tenant_deposits_refunds', { defaultValue: `Manage tenant deposits, refunds, and damage deductions` })}</p>
          </div>
        </div>

        <div className="glass-card p-4 mb-8">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
            <input 
              type="text" 
              placeholder={t('insurance.search_by_tenant_or_apartment', { defaultValue: `Search by tenant or apartment...` })} 
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {displayedAccounts?.map(acc => (
            <div key={acc.id} className="glass-card p-6 flex flex-col hover:border-primary/30 transition-colors">
              <div className="flex justify-between items-start mb-6">
                <div className="flex items-center gap-4">
                  <div className="bg-primary/20 p-4 rounded-xl text-primary shadow-inner">
                    <Shield size={32} />
                  </div>
                  <div>
                    <h3 className="text-lg font-bold text-white">{acc.building_name} - {acc.apartment_code}</h3>
                    <p className="text-slate-400">{acc.tenant_name}</p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-sm text-slate-500 mb-1 uppercase tracking-wider font-semibold">{t('insurance.total_saved', { defaultValue: `Total Saved` })}</p>
                  <p className="text-2xl font-bold text-primary">{t('insurance.cfa', { defaultValue: `CFA` })} {Number(acc.total_saved).toLocaleString()}</p>
                </div>
              </div>

              <div className="grid grid-cols-4 gap-3 border-t border-slate-700/50 pt-4 mt-auto">
                <button 
                  onClick={() => handleAction('Deposit', acc)}
                  disabled={Number(acc.collected_this_month || 0) >= Number(acc.monthly_insurance)}
                  className="flex flex-col items-center justify-center p-3 rounded-xl bg-slate-800/50 hover:bg-primary/20 text-slate-400 hover:text-primary transition-colors border border-slate-700 hover:border-primary/50 disabled:opacity-30 disabled:hover:bg-slate-800/50 disabled:hover:text-slate-400 disabled:hover:border-slate-700"
                >
                  <ArrowDownCircle size={20} className="mb-2" />
                  <span className="text-xs font-medium">{t('insurance.add_deposit', { defaultValue: `Add Deposit` })}</span>
                </button>
                
                <button 
                  onClick={() => handleAction('Refund', acc)}
                  disabled={Number(acc.total_saved) <= 0}
                  className="flex flex-col items-center justify-center p-3 rounded-xl bg-slate-800/50 hover:bg-success/20 text-slate-400 hover:text-success transition-colors border border-slate-700 hover:border-success/50 disabled:opacity-30 disabled:hover:bg-slate-800/50 disabled:hover:text-slate-400 disabled:hover:border-slate-700"
                >
                  <RefreshCcw size={20} className="mb-2" />
                  <span className="text-xs font-medium">{t('insurance.refund_all', { defaultValue: `Refund All` })}</span>
                </button>

                <button 
                  onClick={() => handleAction('Apply_To_Rent', acc)}
                  disabled={Number(acc.total_saved) <= 0}
                  className="flex flex-col items-center justify-center p-3 rounded-xl bg-slate-800/50 hover:bg-indigo-500/20 text-slate-400 hover:text-indigo-400 transition-colors border border-slate-700 hover:border-indigo-500/50 disabled:opacity-30 disabled:hover:bg-slate-800/50 disabled:hover:text-slate-400 disabled:hover:border-slate-700"
                >
                  <ArrowRightCircle size={20} className="mb-2" />
                  <span className="text-xs font-medium text-center leading-tight">{t('insurance.apply_to_rent', { defaultValue: `Apply to Rent` })}</span>
                </button>
                
                <button 
                  onClick={() => handleAction('Deduct', acc)}
                  disabled={Number(acc.total_saved) <= 0}
                  className="flex flex-col items-center justify-center p-3 rounded-xl bg-slate-800/50 hover:bg-danger/20 text-slate-400 hover:text-danger transition-colors border border-slate-700 hover:border-danger/50 disabled:opacity-30 disabled:hover:bg-slate-800/50 disabled:hover:text-slate-400 disabled:hover:border-slate-700"
                >
                  <ArrowUpCircle size={20} className="mb-2" />
                  <span className="text-xs font-medium text-center leading-tight">{t('insurance.deduct_damage', { defaultValue: `Deduct Damage` })}</span>
                </button>
              </div>
            </div>
          ))}
          {displayedAccounts?.length === 0 && <div className="col-span-full p-8 text-center text-muted">{t('insurance.no_active_insurance_accounts_f', { defaultValue: `No active insurance accounts found for this selection.` })}</div>}
        </div>

        {modal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="glass-card p-6 w-full max-w-md border border-slate-700 animate-in zoom-in-95 duration-200">
              <h3 className="text-xl font-bold mb-2 text-white">
                {modal.type === 'Refund' && 'Refund Insurance'}
                {modal.type === 'Deposit' && 'Add Monthly Insurance Payment'}
                {modal.type === 'Deduct' && 'Deduct Damage Cost'}
                {modal.type === 'Apply_To_Rent' && 'Apply Insurance to Rent'}
              </h3>
              <p className="text-sm text-slate-400 mb-6">{t('insurance.for_tenant', { defaultValue: `For tenant:` })} <span className="text-white font-medium">{modal.tenant_name}</span></p>
              
              <div className="space-y-5">
                {modal.type === 'Apply_To_Rent' && (
                  <div>
                    <label className="block text-sm font-medium text-muted mb-2">{t('insurance.select_unpaid_rent_invoice', { defaultValue: `Select Unpaid Rent Invoice` })}</label>
                    <select 
                      value={formData.invoice_id}
                      onChange={e => {
                        const invId = e.target.value;
                        const inv = invoices?.find(i => i.id == invId);
                        const debt = inv ? Number(inv.outstanding_debt) : 0;
                        const autoAmount = Math.min(debt, modal.max_amount);
                        setFormData({...formData, invoice_id: invId, amount: invId ? autoAmount : ''});
                      }}
                      className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                    >
                      <option value="">{t('insurance.select_invoice', { defaultValue: `-- Select Invoice --` })}</option>
                      {invoices?.filter(inv => inv.contract_id === modal.contract_id && Number(inv.outstanding_debt) > 0).map(inv => (
                        <option key={inv.id} value={inv.id}>
                          {inv.invoice_number} {t('insurance.debt_cfa', { defaultValue: `(Debt: CFA` })} {inv.outstanding_debt})
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('insurance.amount_cfa', { defaultValue: `Amount (CFA)` })}</label>
                  <input 
                    type="number" 
                    max={modal.max_amount}
                    value={formData.amount}
                    onChange={e => {
                      const val = Number(e.target.value);
                      if (val > modal.max_amount) {
                         setFormData({...formData, amount: modal.max_amount});
                      } else {
                         setFormData({...formData, amount: e.target.value});
                      }
                    }}
                    className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary text-lg font-bold"
                    disabled={modal.type === 'Refund'}
                  />
                  {modal.type !== 'Deposit' && <p className="text-xs text-warning mt-2">{t('insurance.available_balance_cfa', { defaultValue: `Available balance: CFA` })} {Number(modal.max_amount).toLocaleString()}</p>}
                  {modal.type === 'Deposit' && <p className="text-xs text-warning mt-2">{t('insurance.remaining_required_for_this_mo', { defaultValue: `Remaining required for this month: CFA` })} {Number(modal.max_amount).toLocaleString()}</p>}
                </div>

                {modal.type === 'Deduct' && (
                  <div>
                    <label className="block text-sm font-medium text-muted mb-2">{t('insurance.damage_reason', { defaultValue: `Damage Reason` })}</label>
                    <textarea 
                      value={formData.damage_reason}
                      onChange={e => setFormData({...formData, damage_reason: e.target.value})}
                      className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                      rows="3"
                      placeholder={t('insurance.e_g_broken_door_painting_neede', { defaultValue: `e.g. Broken Door, Painting needed` })}
                    />
                  </div>
                )}

                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('insurance.additional_notes', { defaultValue: `Additional Notes` })}</label>
                  <input 
                    type="text" 
                    value={formData.notes}
                    onChange={e => setFormData({...formData, notes: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                    placeholder={t('insurance.optional_notes', { defaultValue: `Optional notes` })}
                  />
                </div>
              </div>

              <div className="flex gap-3 mt-8">
                <button onClick={() => { setModal(null); setFormData({amount: '', notes: '', damage_reason: '', invoice_id: ''}); }} className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg transition-colors flex-1">{t('insurance.cancel', { defaultValue: `Cancel` })}</button>
                <button 
                  onClick={submitTransaction} 
                  disabled={!formData.amount || (modal.type === 'Deduct' && !formData.damage_reason) || (modal.type === 'Apply_To_Rent' && !formData.invoice_id)}
                  className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex-1 disabled:opacity-50 transition-colors font-medium shadow-lg shadow-primary/20"
                >
                  {t('insurance.confirm', { defaultValue: `Confirm` })} {modal.type === 'Apply_To_Rent' ? 'Transfer' : modal.type}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Insurance;
