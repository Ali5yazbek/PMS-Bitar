import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { Printer, Calendar, DollarSign, Activity, Lock, Unlock, MinusCircle, FileText } from 'lucide-react';
import PrintLogo from '../components/PrintLogo';

const CashierSummary = () => {
  const queryClient = useQueryClient();
  const [targetDate, setTargetDate] = useState(new Date().toLocaleDateString('sv-SE'));

  // Modals state
  const [isOpening, setIsOpening] = useState(false);
  const [isClosing, setIsClosing] = useState(false);
  const [isExpensing, setIsExpensing] = useState(false);

  const [openingAmount, setOpeningAmount] = useState('');
  const [closingAmount, setClosingAmount] = useState('');
  const [expenseAmount, setExpenseAmount] = useState('');
  const [expenseReason, setExpenseReason] = useState('');

  const { data: summary, isLoading } = useQuery({
    queryKey: ['cashierSummary', targetDate],
    queryFn: async () => {
      const res = await api.get('/cashier/summary', { params: { date: targetDate } });
      return res.data;
    }
  });

  const { data: activeSession } = useQuery({
    queryKey: ['activeSession'],
    queryFn: async () => {
      const res = await api.get('/cashier/sessions');
      // Just check if the first one is open (assuming the API returns ordered by start_time DESC)
      if (res.data && res.data.length > 0 && res.data[0].status === 'Open') {
          return res.data[0];
      }
      return null;
    }
  });

  const openMutation = useMutation({
      mutationFn: (amount) => api.post('/cashier/session/open', { opening_amount: amount }),
      onSuccess: () => {
          queryClient.invalidateQueries(['activeSession']);
          setIsOpening(false);
          setOpeningAmount('');
      }
  });

  const closeMutation = useMutation({
      mutationFn: (amount) => api.post('/cashier/session/close', { closing_amount: amount }),
      onSuccess: () => {
          queryClient.invalidateQueries(['activeSession']);
          queryClient.invalidateQueries(['cashierSummary']);
          setIsClosing(false);
          setClosingAmount('');
      }
  });

  const expenseMutation = useMutation({
      mutationFn: (data) => api.post('/cashier/session/expense', data),
      onSuccess: () => {
          queryClient.invalidateQueries(['activeSession']);
          setIsExpensing(false);
          setExpenseAmount('');
          setExpenseReason('');
      }
  });

  const handlePrint = () => {
    window.print();
  };

  const getCategoryColor = (cat) => {
    switch (cat) {
      case 'Walk-In': return 'text-indigo-400 bg-indigo-400/10 border-indigo-400/20';
      case 'Building': return 'text-amber-400 bg-amber-400/10 border-amber-400/20';
      case 'Apartment': return 'text-orange-400 bg-orange-400/10 border-orange-400/20';
      case 'Construction': return 'text-rose-400 bg-rose-400/10 border-rose-400/20';
      case 'Account': return 'text-blue-400 bg-blue-400/10 border-blue-400/20';
      default: return 'text-emerald-400 bg-emerald-400/10 border-emerald-400/20'; 
    }
  };

  return (
    <div className="flex h-full bg-background overflow-hidden relative">
      <div className="flex-1 flex flex-col h-full overflow-hidden p-6 md:p-8 hide-scrollbar print:p-0">
        
        {/* Header & Controls */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-8 print:hidden animate-in slide-in-from-top-4">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center mb-2">
              <DollarSign className="me-3 text-emerald-400" size={32} />
              Cashier Summary & Drawer
            </h1>
            <p className="text-slate-400">Manage your cash drawer, expenses, and print daily closing reports.</p>
          </div>
          
          <div className="flex flex-wrap items-center gap-3">
            <div className="flex items-center gap-2 bg-slate-800 border border-slate-700 rounded-xl px-3 py-2 text-white">
              <Calendar size={18} className="text-slate-400" />
              <input 
                type="date" 
                value={targetDate} 
                onChange={(e) => setTargetDate(e.target.value)} 
                className="bg-transparent border-none outline-none text-white w-full"
              />
            </div>
            <button 
              onClick={handlePrint}
              disabled={isLoading || !summary?.categories?.length}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors disabled:opacity-50"
            >
              <Printer size={18} /> Print Closing Report
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto hide-scrollbar print:overflow-visible flex flex-col xl:flex-row gap-6">
            
            {/* Left Col: Cash Drawer Management */}
            <div className="w-full xl:w-80 space-y-6 print:hidden shrink-0">
                <div className="glass-card p-6 border-t-4 border-t-indigo-500">
                    <h3 className="font-bold text-white mb-4 flex items-center gap-2"><DollarSign size={20} className="text-indigo-400"/> Cash Drawer Session</h3>
                    
                    {activeSession ? (
                        <div className="space-y-4">
                            <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg flex items-center gap-3">
                                <Unlock className="text-emerald-400" size={24} />
                                <div>
                                    <p className="text-xs text-emerald-400 font-bold uppercase tracking-wider">Drawer Open</p>
                                    <p className="text-white text-sm">Since {new Date(activeSession.start_time).toLocaleTimeString()}</p>
                                </div>
                            </div>
                            
                            <div className="space-y-2">
                                <div className="flex justify-between text-sm text-slate-300">
                                    <span>Opening Cash</span>
                                    <span className="font-medium">CFA {Number(activeSession.opening_amount).toLocaleString()}</span>
                                </div>
                                <div className="flex justify-between text-sm text-slate-300">
                                    <span>Expenses</span>
                                    <span className="text-danger font-medium">- CFA {Number(activeSession.expenses || 0).toLocaleString()}</span>
                                </div>
                            </div>

                            <div className="grid grid-cols-2 gap-2 mt-4">
                                <button onClick={() => setIsExpensing(true)} className="py-2 px-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-sm flex items-center justify-center gap-2 transition-colors">
                                    <MinusCircle size={16} className="text-danger"/> Expense
                                </button>
                                <button onClick={() => setIsClosing(true)} className="py-2 px-3 bg-amber-500 hover:bg-amber-600 text-amber-950 font-bold rounded-lg text-sm flex items-center justify-center gap-2 transition-colors">
                                    <Lock size={16}/> Close Drawer
                                </button>
                            </div>
                        </div>
                    ) : (
                        <div className="text-center py-6">
                            <Lock className="mx-auto text-slate-500 mb-4" size={48} />
                            <p className="text-slate-400 text-sm mb-6">Drawer is currently closed. Open the session to start tracking cash.</p>
                            <button onClick={() => setIsOpening(true)} className="w-full py-3 bg-emerald-500 hover:bg-emerald-600 text-white font-bold rounded-xl flex items-center justify-center gap-2 transition-colors">
                                <Unlock size={20} /> Open Drawer
                            </button>
                        </div>
                    )}
                </div>

                <div className="glass-card p-6 border-t-4 border-t-emerald-500 print:hidden">
                  <p className="text-sm font-medium text-slate-400 uppercase tracking-wider mb-2">Total Cash Collected</p>
                  <h2 className="text-4xl font-black text-emerald-400">CFA {Number(summary?.cashToday || 0).toLocaleString()}</h2>
                  <p className="text-xs text-slate-500 mt-2">Cash sales + Partial Returns adjustments</p>
                </div>
            </div>

            {/* Right Col: Daily Summary Details */}
            <div className="flex-1 space-y-6">
                {isLoading ? (
                    <div className="flex justify-center items-center h-48 text-slate-400 print:hidden">Loading summary...</div>
                ) : !summary?.categories?.length ? (
                    <div className="flex justify-center items-center h-48 text-slate-400 print:hidden glass-card">No transactions found for this date.</div>
                ) : (
                    <div className="space-y-6">
                        <div className="glass-card p-6 border-t-4 border-t-primary print:hidden">
                            <p className="text-sm font-medium text-slate-400 uppercase tracking-wider mb-2">Grand Total (All Payment Types)</p>
                            <h2 className="text-4xl font-black text-white">CFA {Number(summary.grandTotal).toLocaleString()}</h2>
                        </div>

                        <div className="glass-card overflow-hidden">
                            <div className="bg-slate-800/50 p-4 border-b border-slate-700/50">
                            <h3 className="font-bold text-white flex items-center"><Activity size={18} className="me-2 text-primary"/> Category Breakdown</h3>
                            </div>
                            <table className="w-full text-left">
                            <thead className="bg-slate-900/50">
                                <tr>
                                <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Category</th>
                                <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-center">Invoices</th>
                                <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Gross Amount</th>
                                <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Refunds</th>
                                <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider text-right">Net Total</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-700/50">
                                {summary.categories.map((cat, idx) => (
                                <tr key={idx} className="hover:bg-slate-800/30">
                                    <td className="px-6 py-4">
                                    <span className={`px-2.5 py-1 rounded-md text-xs font-bold border ${getCategoryColor(cat.category)}`}>
                                        {cat.category}
                                    </span>
                                    </td>
                                    <td className="px-6 py-4 text-center text-slate-300 font-medium">{cat.invoices}</td>
                                    <td className="px-6 py-4 text-right text-slate-300 font-medium">CFA {Number(cat.amount).toLocaleString()}</td>
                                    <td className="px-6 py-4 text-right text-danger font-medium">{cat.refunds > 0 ? `- CFA ${Number(cat.refunds).toLocaleString()}` : '-'}</td>
                                    <td className="px-6 py-4 text-right text-white font-bold">CFA {Number(cat.net).toLocaleString()}</td>
                                </tr>
                                ))}
                            </tbody>
                            </table>
                        </div>
                    </div>
                )}
            </div>

            {/* Print Layout */}
            <div className="hidden print:block font-mono text-black w-full" dir="ltr">
              <div className="text-center border-b-2 border-black pb-6 mb-6">
                <PrintLogo />
                <h1 className="text-3xl font-bold tracking-widest mt-2 mb-1">CASHIER DAILY SUMMARY</h1>
                <p className="text-lg">Date: {targetDate}</p>
                <p className="text-sm">Generated: {new Date().toLocaleString()}</p>
              </div>

              <div className="flex justify-between mb-8 pb-4 border-b border-gray-400">
                <div>
                  <p className="text-sm font-bold uppercase mb-1">CASH COLLECTED</p>
                  <p className="text-2xl font-bold">CFA {Number(summary?.cashToday || 0).toLocaleString()}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold uppercase mb-1">GRAND TOTAL (ALL)</p>
                  <p className="text-2xl font-bold">CFA {Number(summary?.grandTotal || 0).toLocaleString()}</p>
                </div>
              </div>

              {activeSession && (
                  <div className="mb-8 p-4 border border-black">
                      <h3 className="font-bold underline mb-2">Drawer Session</h3>
                      <p>Opened: {new Date(activeSession.start_time).toLocaleString()}</p>
                      <p>Opening Amount: CFA {Number(activeSession.opening_amount).toLocaleString()}</p>
                      <p>Expenses Logged: CFA {Number(activeSession.expenses || 0).toLocaleString()}</p>
                  </div>
              )}

              {summary?.categories && summary.categories.length > 0 && (
                  <>
                      <h2 className="text-lg font-bold mb-3 border-b border-black pb-1 uppercase tracking-wider">Breakdown by Category</h2>
                      <table className="w-full text-left border-collapse">
                        <thead>
                          <tr className="border-b-2 border-black">
                            <th className="py-2 px-1">Category</th>
                            <th className="py-2 px-1 text-center">Txns</th>
                            <th className="py-2 px-1 text-right">Gross</th>
                            <th className="py-2 px-1 text-right">Refunds</th>
                            <th className="py-2 px-1 text-right">Net</th>
                          </tr>
                        </thead>
                        <tbody>
                          {summary.categories.map((cat, idx) => (
                            <tr key={idx} className="border-b border-gray-300">
                              <td className="py-2 px-1 font-bold">{cat.category}</td>
                              <td className="py-2 px-1 text-center">{cat.invoices}</td>
                              <td className="py-2 px-1 text-right">CFA {Number(cat.amount).toLocaleString()}</td>
                              <td className="py-2 px-1 text-right">{cat.refunds > 0 ? `(CFA ${Number(cat.refunds).toLocaleString()})` : '-'}</td>
                              <td className="py-2 px-1 text-right font-bold">CFA {Number(cat.net).toLocaleString()}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                  </>
              )}

              <div className="mt-16 pt-8 border-t-2 border-black flex justify-between px-10">
                <div className="text-center">
                  <p className="mb-8">___________________________</p>
                  <p className="font-bold">Cashier Signature</p>
                </div>
                <div className="text-center">
                  <p className="mb-8">___________________________</p>
                  <p className="font-bold">Manager Signature</p>
                </div>
              </div>
            </div>

        </div>
      </div>

      {/* Drawer Action Modals */}
      {isOpening && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-[100] flex items-center justify-center p-4 print:hidden">
              <div className="glass-card max-w-sm w-full p-6 animate-in zoom-in-95">
                  <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2"><Unlock className="text-emerald-400"/> Open Cash Drawer</h3>
                  <p className="text-slate-400 text-sm mb-4">Enter the starting cash amount in the drawer.</p>
                  <input type="number" min="0" value={openingAmount} onChange={e => setOpeningAmount(e.target.value)} className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:border-emerald-400 outline-none text-2xl font-bold mb-6" placeholder="0" />
                  <div className="flex gap-3 justify-end">
                      <button onClick={() => setIsOpening(false)} className="px-4 py-2 text-slate-300 hover:bg-slate-800 rounded-lg">Cancel</button>
                      <button onClick={() => openMutation.mutate(openingAmount)} disabled={!openingAmount} className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-white font-bold rounded-lg disabled:opacity-50">Open Drawer</button>
                  </div>
              </div>
          </div>
      )}

      {isClosing && activeSession && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-[100] flex items-center justify-center p-4 print:hidden">
              <div className="glass-card max-w-sm w-full p-6 animate-in zoom-in-95">
                  <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2"><Lock className="text-amber-500"/> Close Cash Drawer</h3>
                  <div className="bg-amber-500/10 border border-amber-500/20 rounded-lg p-3 mb-4 text-sm text-amber-200">
                      Expected Cash: <strong className="text-amber-400 text-lg ml-2">CFA {Number(Number(activeSession.opening_amount) + Number(summary?.cashToday || 0) - Number(activeSession.expenses || 0)).toLocaleString()}</strong>
                  </div>
                  <p className="text-slate-400 text-sm mb-4">Enter the actual counted cash amount in the drawer.</p>
                  <input type="number" min="0" value={closingAmount} onChange={e => setClosingAmount(e.target.value)} className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-3 text-white focus:border-amber-400 outline-none text-2xl font-bold mb-6" placeholder="0" />
                  <div className="flex gap-3 justify-end">
                      <button onClick={() => setIsClosing(false)} className="px-4 py-2 text-slate-300 hover:bg-slate-800 rounded-lg">Cancel</button>
                      <button onClick={() => closeMutation.mutate(closingAmount)} disabled={!closingAmount} className="px-4 py-2 bg-amber-500 hover:bg-amber-600 text-amber-950 font-bold rounded-lg disabled:opacity-50">Close Drawer</button>
                  </div>
              </div>
          </div>
      )}

      {isExpensing && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm z-[100] flex items-center justify-center p-4 print:hidden">
              <div className="glass-card max-w-sm w-full p-6 animate-in zoom-in-95">
                  <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2"><MinusCircle className="text-danger"/> Add Drawer Expense</h3>
                  <p className="text-slate-400 text-sm mb-4">Log money taken out of the drawer.</p>
                  
                  <div className="space-y-4 mb-6">
                      <div>
                          <label className="text-sm text-slate-400 block mb-1">Amount</label>
                          <input type="number" min="0" value={expenseAmount} onChange={e => setExpenseAmount(e.target.value)} className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-danger outline-none" placeholder="0" />
                      </div>
                      <div>
                          <label className="text-sm text-slate-400 block mb-1">Reason / Description</label>
                          <textarea rows="2" value={expenseReason} onChange={e => setExpenseReason(e.target.value)} className="w-full bg-slate-900 border border-slate-700 rounded-lg px-4 py-2 text-white focus:border-danger outline-none" placeholder="E.g., Office supplies"></textarea>
                      </div>
                  </div>

                  <div className="flex gap-3 justify-end">
                      <button onClick={() => setIsExpensing(false)} className="px-4 py-2 text-slate-300 hover:bg-slate-800 rounded-lg">Cancel</button>
                      <button onClick={() => expenseMutation.mutate({ amount: expenseAmount, reason: expenseReason })} disabled={!expenseAmount || !expenseReason} className="px-4 py-2 bg-danger hover:bg-red-600 text-white font-bold rounded-lg disabled:opacity-50">Save Expense</button>
                  </div>
              </div>
          </div>
      )}

    </div>
  );
};

export default CashierSummary;
