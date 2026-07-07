import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Shield, Download, Edit2, X, Check } from 'lucide-react';

const InsuranceDashboard = () => {

  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [year, setYear] = useState(new Date().getFullYear());
  const [editingId, setEditingId] = useState(null);
  const [editAmount, setEditAmount] = useState('');
  
  // Manage Balance Modal State
  const [manageModal, setManageModal] = useState(null); // { account_id, current_balance }
  const [transactionType, setTransactionType] = useState('Deposit');
  const [transactionAmount, setTransactionAmount] = useState('');
  const [transactionNotes, setTransactionNotes] = useState('');

  const { data: stats, isLoading: statsLoading } = useQuery({ 
    queryKey: ['insurance-dashboard', month, year], 
    queryFn: async () => (await api.get(`/insurance/dashboard?month=${month}&year=${year}`)).data 
  });

  const { data: accounts, isLoading: accountsLoading } = useQuery({
    queryKey: ['insurance-accounts', month, year],
    queryFn: async () => (await api.get(`/insurance?month=${month}&year=${year}`)).data
  });

  const updateDepositMutation = useMutation({
    mutationFn: ({ id, amount }) => api.put(`/insurance/accounts/${id}/deposit`, { amount }),
    onSuccess: () => {
      queryClient.invalidateQueries(['insurance-accounts']);
      queryClient.invalidateQueries(['apartments']);
      setEditingId(null);
    }
  });

  const transactionMutation = useMutation({
    mutationFn: (data) => api.post('/insurance/transaction', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['insurance-accounts']);
      queryClient.invalidateQueries(['insurance-dashboard']);
      setManageModal(null);
      setTransactionAmount('');
      setTransactionNotes('');
    },
    onError: (err) => {
      alert('Transaction failed: ' + (err.response?.data?.error || err.message));
    }
  });

  const handleEditClick = (account) => {
    setEditingId(account.id);
    setEditAmount(account.monthly_insurance);
  };

  const handleSave = (id) => {
    updateDepositMutation.mutate({ id, amount: editAmount });
  };

  if (statsLoading || accountsLoading) return <div className="p-8 text-muted">Loading...</div>;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Shield className="me-3 text-primary" size={32} />
              Insurance Management
            </h1>
            <p className="text-muted mt-2">Overview of insurance deposits and refunds.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <select value={month} onChange={e => setMonth(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary">
              {Array.from({length: 12}, (_, i) => i + 1).map(m => (
                <option key={m} value={m}>{new Date(0, m - 1).toLocaleString('default', { month: 'long' })}</option>
              ))}
            </select>
            <select value={year} onChange={e => setYear(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary">
              {[2023, 2024, 2025, 2026, 2027].map(y => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
            <button className="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors border border-slate-700">
              <Download size={20} />
              <span>Export PDF</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <div className="glass-card p-6 border-l-4 border-l-success">
            <h3 className="text-muted text-sm font-medium mb-2">Net Insurance Collected This Month</h3>
            <div className="text-3xl font-bold text-white">CFA {Number(stats?.net_insurance || 0).toFixed(2)}</div>
          </div>
          
          <div className="glass-card p-6 border-l-4 border-l-warning">
            <h3 className="text-muted text-sm font-medium mb-2">Refunded Insurance This Month</h3>
            <div className="text-3xl font-bold text-white">-${Number(stats?.total_refunds || 0).toFixed(2)}</div>
          </div>

          <div className="glass-card p-6 border-l-4 border-l-danger">
            <h3 className="text-muted text-sm font-medium mb-2">Deducted for Damage This Month</h3>
            <div className="text-3xl font-bold text-white">-${Number(stats?.total_deducts || 0).toFixed(2)}</div>
          </div>
          
          <div className="glass-card p-6 border-l-4 border-l-primary bg-primary/5">
            <h3 className="text-indigo-300 text-sm font-medium mb-2">Current Insurance Held</h3>
            <div className="text-4xl font-bold text-white">CFA {Number(stats?.current_balance || 0).toFixed(2)}</div>
          </div>
        </div>

        <div className="glass-card overflow-hidden">
          <div className="p-6 border-b border-slate-700/50">
            <h2 className="text-xl font-bold text-white">Active Insurance Accounts</h2>
            <p className="text-sm text-muted mt-1">List of tenants and their current insurance deposits.</p>
          </div>
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Tenant</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Property</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Required Deposit</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Current Balance</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Status</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-end">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {accounts?.map((account, idx) => {
                const required = Number(account.monthly_insurance);
                const current = Number(account.total_saved);
                const collected = Number(account.collected_this_month || 0);
                const status = collected >= required ? 'Fully Paid' : (collected > 0 ? 'Partially Paid' : 'Unpaid');
                const isEditing = editingId === account.id;
                
                return (
                  <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4 font-medium text-white">{account.tenant_name}</td>
                    <td className="px-6 py-4 text-sm text-slate-300">
                      <div>{account.building_name}</div>
                      <div className="text-slate-500 text-xs">Apt {account.apartment_code}</div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-300">
                      {isEditing ? (
                        <div className="flex items-center gap-2">
                          <span className="text-slate-400">CFA </span>
                          <input 
                            type="number" 
                            className="w-24 bg-slate-900 border border-primary rounded-lg px-2 py-1 text-white outline-none text-sm" 
                            value={editAmount}
                            onChange={(e) => setEditAmount(e.target.value)}
                          />
                        </div>
                      ) : (
                        `CFA ${required.toFixed(2)}`
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-white">CFA {current.toFixed(2)}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${
                        status === 'Fully Paid' ? 'bg-success/20 text-success' : 
                        status === 'Partially Paid' ? 'bg-warning/20 text-warning' : 
                        'bg-danger/20 text-danger'
                      }`}>
                        {status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-end">
                      {isEditing ? (
                        <div className="flex justify-end gap-2">
                          <button onClick={() => setEditingId(null)} className="text-slate-400 hover:text-white px-2 py-1 bg-slate-800 rounded text-xs">Cancel</button>
                          <button onClick={() => handleSave(account.id)} className="text-white bg-success hover:bg-green-600 px-2 py-1 rounded text-xs transition-colors">Save</button>
                        </div>
                      ) : (
                        <div className="flex justify-end gap-2">
                          <button onClick={() => handleEditClick(account)} className="text-indigo-400 hover:text-indigo-300 text-xs px-2 py-1 border border-slate-700 rounded hover:bg-slate-800">
                            Edit Base
                          </button>
                          <button 
                            onClick={() => { setManageModal({ account_id: account.id, current_balance: current, max_deposit: Math.max(0, required - collected) }); setTransactionType('Deposit'); }} 
                            className="text-white bg-slate-700 hover:bg-slate-600 text-xs px-2 py-1 rounded transition-colors"
                          >
                            Manage Balance
                          </button>
                        </div>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          {(!accounts || accounts.length === 0) && (
            <div className="p-8 text-center text-muted">No active insurance accounts found.</div>
          )}
        </div>

        {manageModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="glass-card p-6 w-[28rem] border border-slate-700 animate-in zoom-in-95 duration-200">
              <h3 className="text-xl font-bold mb-4 text-white">Manage Insurance Balance</h3>
              
              <div className="mb-4">
                <label className="block text-sm font-medium text-muted mb-2">Transaction Type</label>
                <select 
                  value={transactionType}
                  onChange={e => setTransactionType(e.target.value)}
                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-primary"
                >
                  <option value="Deposit">Deposit (Add Funds)</option>
                  <option value="Refund">Refund to Tenant</option>
                  <option value="Deduct">Deduct (Damages/Fees)</option>
                </select>
              </div>

              <div className="mb-4">
                <label className="block text-sm font-medium text-muted mb-2">Amount (CFA)</label>
                <input 
                  type="number" 
                  value={transactionAmount}
                  onChange={e => {
                    const val = Number(e.target.value);
                    if (transactionType === 'Deposit' && val > manageModal.max_deposit) {
                      setTransactionAmount(manageModal.max_deposit);
                    } else if (['Refund', 'Deduct'].includes(transactionType) && val > manageModal.current_balance) {
                      setTransactionAmount(manageModal.current_balance);
                    } else {
                      setTransactionAmount(e.target.value);
                    }
                  }}
                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-primary"
                  autoFocus
                />
                <p className="text-sm text-indigo-400 mt-2">Current Balance: CFA {Number(manageModal.current_balance).toFixed(2)}</p>
                {transactionType === 'Deposit' && <p className="text-sm text-warning mt-1">Remaining required for this month: CFA {Number(manageModal.max_deposit).toFixed(2)}</p>}
              </div>

              <div className="mb-6">
                <label className="block text-sm font-medium text-muted mb-2">Notes / Reason</label>
                <input 
                  type="text" 
                  value={transactionNotes}
                  onChange={e => setTransactionNotes(e.target.value)}
                  placeholder={transactionType === 'Deduct' ? "e.g., Broken Window" : "Optional notes"}
                  className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-2 text-white focus:outline-none focus:border-primary"
                />
              </div>

              <div className="flex gap-3">
                <button onClick={() => setManageModal(null)} className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg transition-colors flex-1">Cancel</button>
                <button 
                  onClick={() => {
                    if (['Refund', 'Deduct'].includes(transactionType) && Number(transactionAmount) > Number(manageModal.current_balance)) {
                      alert("Amount exceeds current balance!");
                      return;
                    }
                    if (transactionType === 'Deposit' && Number(transactionAmount) > Number(manageModal.max_deposit)) {
                      alert("Amount exceeds the required monthly deposit!");
                      return;
                    }
                    if (!transactionAmount || Number(transactionAmount) <= 0) {
                      alert("Please enter a valid amount.");
                      return;
                    }
                    transactionMutation.mutate({
                      account_id: manageModal.account_id,
                      type: transactionType,
                      amount: transactionAmount,
                      notes: transactionNotes,
                      damage_reason: transactionType === 'Deduct' ? transactionNotes : null
                    });
                  }} 
                  className={`px-4 py-2 rounded-lg transition-colors flex-1 font-medium text-white ${
                    transactionType === 'Deposit' ? 'bg-success hover:bg-green-600' :
                    transactionType === 'Refund' ? 'bg-indigo-600 hover:bg-indigo-500' :
                    'bg-danger hover:bg-red-600'
                  }`}
                >
                  Submit {transactionType}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default InsuranceDashboard;
