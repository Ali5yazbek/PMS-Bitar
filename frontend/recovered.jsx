              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const InsuranceDashboardTab = () => {
  const queryClient = useQueryClient();
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [year, setYear] = useState(new Date().getFullYear());
  const [editingId, setEditingId] = useState(null);
  const [editAmount, setEditAmount] = useState('');
  const [manageModal, setManageModal] = useState(null);
  const [txType, setTxType] = useState('Deposit');
  const [txAmount, setTxAmount] = useState('');
  const [txNotes, setTxNotes] = useState('');

  const { data: stats } = useQuery({ queryKey: ['insurance-dashboard', month, year], queryFn: async () => (await api.get(`/insurance/dashboard?month=${month}&year=${year}`)).data });
  const { data: accounts } = useQuery({ queryKey: ['insurance-accounts', month, year], queryFn: async () => (await api.get(`/insurance?month=${month}&year=${year}`)).data });

  const updateDepositMutation = useMutation({
    mutationFn: ({ id, amount }) => api.put(`/insurance/accounts/${id}/deposit`, { amount }),
    onSuccess: () => { queryClient.invalidateQueries(['insurance-accounts']); setEditingId(null); }
  });
  const txMutation = useMutation({
    mutationFn: (data) => api.post('/insurance/transaction', data),
    onSuccess: () => { queryClient.invalidateQueries(['insurance-accounts']); queryClient.invalidateQueries(['insurance-dashboard']); setManageModal(null); setTxAmount(''); setTxNotes(''); },
    onError: (err) => alert('Failed: ' + (err.response?.data?.error || err.message))
  });

  const groupedAccounts = accounts?.reduce((acc, current) => {
    if (!acc[current.building_name]) {
      acc[current.building_name] = { accounts: [], totalRequired: 0, totalHeld: 0 };
    }
    acc[current.building_name].accounts.push(current);
    acc[current.building_name].totalRequired += Number(current.monthly_insurance || 0);
    acc[current.building_name].totalHeld += Number(current.total_saved || 0);
    return acc;
  }, {});

  return (
    <div className="space-y-8 animate-in fade-in duration-500">
      <div className="flex flex-col md:flex-row justify-between md:items-center gap-4 bg-slate-800/40 p-6 rounded-2xl border border-slate-700/50 backdrop-blur-md shadow-xl">
        <div>
          <h2 className="text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-primary to-purple-400 flex items-center gap-3">
            <Shield className="text-primary" size={32} /> {t('rentinsurancehub.insurance_analytics', { defaultValue: `Insurance Analytics` })}
          </h2>
          <p className="text-slate-400 mt-2 text-sm font-medium">{t('rentinsurancehub.overview_of_all_security_depos', { defaultValue: `Overview of all security deposits and balances` })}</p>
        </div>
        <div className="flex items-center gap-3 bg-slate-900/50 p-2 rounded-xl border border-slate-700">
          <div className="flex items-center bg-slate-800 rounded-lg px-3 py-2 border border-slate-700/50 focus-within:border-primary/50 transition-colors">
            <Calendar className="text-muted mr-2" size={16} />
            <select value={month} onChange={e => setMonth(e.target.value)} className="bg-transparent text-white outline-none text-sm w-32 appearance-none">
              {Array.from({length:12},(_,i)=>i+1).map(m=><option key={m} value={m} className="bg-slate-800">{new Date(0,m-1).toLocaleString('default',{month:'long'})}</option>)}
            </select>
          </div>
          <div className="flex items-center bg-slate-800 rounded-lg px-3 py-2 border border-slate-700/50 focus-within:border-primary/50 transition-colors">
            <select value={year} onChange={e => setYear(e.target.value)} className="bg-transparent text-white outline-none text-sm appearance-none">
              {[2023,2024,2025,2026,2027].map(y=><option key={y} value={y} className="bg-slate-800">{y}</option>)}
            </select>
          </div>
        </div>
      </div>

      {/* Enterprise Summary */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-slate-800/80 to-slate-900 border border-slate-700 shadow-2xl p-8">
        <div className="absolute -top-24 -right-24 w-64 h-64 bg-primary/20 rounded-full blur-[80px] pointer-events-none" />
        <div className="absolute -bottom-24 -left-24 w-64 h-64 bg-purple-500/20 rounded-full blur-[80px] pointer-events-none" />

        <div className="relative z-10 flex flex-col mb-8 border-b border-slate-700/50 pb-6">
          <h3 className="text-2xl font-black text-white tracking-tight flex items-center gap-3">
            <Activity className="text-primary" size={24} />
            {t('rentinsurancehub.enterprise_insurance_summary', { defaultValue: `Enterprise Insurance Summary` })}
          </h3>
          <p className="text-slate-400 mt-1 font-medium">{t('rentinsurancehub.combined_security_deposit_metr', { defaultValue: `Combined security deposit metrics for all properties.` })}</p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 relative z-10">
          <div className="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 backdrop-blur-sm group hover:bg-slate-800/60 transition-colors">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-success/20 p-2.5 rounded-xl group-hover:scale-110 transition-transform"><Wallet size={20} className="text-success" /></div>
              <span className="text-xs font-bold text-slate-400 bg-slate-900/50 px-2 py-1 rounded-lg uppercase">{t('rentinsurancehub.net_collected', { defaultValue: `Net Collected` })}</span>
            </div>
            <div className="text-3xl font-black text-success mb-1"><span className="text-lg text-slate-500 mr-1">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })}</span>{Number(stats?.net_insurance||0).toLocaleString()}</div>
            <div className="text-sm font-medium text-slate-400">{t('rentinsurancehub.total_deposits', { defaultValue: `Total Deposits` })}</div>
          </div>
          
          <div className="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 backdrop-blur-sm group hover:bg-slate-800/60 transition-colors">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-warning/20 p-2.5 rounded-xl group-hover:scale-110 transition-transform"><RefreshCcw size={20} className="text-warning" /></div>
              <span className="text-xs font-bold text-slate-400 bg-slate-900/50 px-2 py-1 rounded-lg uppercase">{t('rentinsurancehub.refunded', { defaultValue: `Refunded` })}</span>
            </div>
            <div className="text-3xl font-black text-warning mb-1"><span className="text-lg text-slate-500 mr-1">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })}</span>{Number(stats?.total_refunds||0).toLocaleString()}</div>
            <div className="text-sm font-medium text-slate-400">{t('rentinsurancehub.total_cash_refunded', { defaultValue: `Total Cash Refunded` })}</div>
          </div>
          
          <div className="bg-slate-800/40 p-5 rounded-2xl border border-slate-700/50 backdrop-blur-sm group hover:bg-slate-800/60 transition-colors">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-danger/20 p-2.5 rounded-xl group-hover:scale-110 transition-transform"><AlertCircle size={20} className="text-danger" /></div>
              <span className="text-xs font-bold text-slate-400 bg-slate-900/50 px-2 py-1 rounded-lg uppercase">{t('rentinsurancehub.deducted', { defaultValue: `Deducted` })}</span>
            </div>
            <div className="text-3xl font-black text-danger mb-1"><span className="text-lg text-slate-500 mr-1">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })}</span>{Number(stats?.total_deducts||0).toLocaleString()}</div>
            <div className="text-sm font-medium text-slate-400">{t('rentinsurancehub.total_damage_deductions', { defaultValue: `Total Damage Deductions` })}</div>
          </div>
          
          <div className="bg-primary/10 p-5 rounded-2xl border border-primary/30 backdrop-blur-sm group hover:bg-primary/20 transition-colors">
            <div className="flex justify-between items-start mb-4">
              <div className="bg-primary/20 p-2.5 rounded-xl group-hover:scale-110 transition-transform"><Shield size={20} className="text-primary" /></div>
              <span className="text-xs font-bold text-primary bg-primary/20 px-2 py-1 rounded-lg uppercase">{t('rentinsurancehub.total_held', { defaultValue: `Total Held` })}</span>
            </div>
            <div className="text-3xl font-black text-white mb-1"><span className="text-lg text-primary/70 mr-1">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })}</span>{Number(stats?.current_balance||0).toLocaleString()}</div>
            <div className="text-sm font-medium text-primary/70">{t('rentinsurancehub.current_retained_balance', { defaultValue: `Current Retained Balance` })}</div>
          </div>
        </div>
      </div>

      {/* Buildings Breakdown */}
      <div className="space-y-8 mt-10">
        <h3 className="text-xl font-bold text-slate-300 flex items-center gap-2">
          <Building2 size={20} className="text-muted" /> {t('rentinsurancehub.insurance_by_property', { defaultValue: `Insurance by Property` })}
        </h3>
        
        {Object.entries(groupedAccounts || {}).map(([buildingName, data]) => {
          const heldPercent = data.totalRequired > 0 ? ((data.totalHeld / data.totalRequired) * 100).toFixed(0) : 0;
          return (
          <div key={buildingName} className="glass-card overflow-hidden rounded-3xl border border-slate-700/50 hover:border-primary/30 transition-all duration-300 shadow-xl group">
            <div className="p-6 border-b border-slate-700/50 bg-slate-800/30 flex flex-col md:flex-row justify-between md:items-center gap-4 relative overflow-hidden">
              <div className="absolute top-0 right-0 w-48 h-48 bg-primary/5 rounded-full blur-3xl pointer-events-none group-hover:bg-primary/10 transition-colors" />
              
              <div className="flex items-center gap-4 relative z-10">
                <div className="bg-slate-700/50 p-4 rounded-2xl border border-slate-600"><Building2 className="text-white" size={28} /></div>
                <div>
                  <h3 className="text-2xl font-black text-white capitalize tracking-tight">{buildingName}</h3>
                  <p className="text-sm font-medium text-slate-400">{data.accounts.length} {t('rentinsurancehub.active_accounts', { defaultValue: `Active Accounts` })}</p>
                </div>
              </div>
              
              <div className="flex flex-wrap items-center gap-6 relative z-10 bg-slate-900/50 px-6 py-3 rounded-2xl border border-slate-700/50">
                <div>
                  <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">{t('rentinsurancehub.total_required', { defaultValue: `Total Required` })}</p>
                  <p className="text-xl font-black text-white">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })} {data.totalRequired.toLocaleString()}</p>
                </div>
                <div className="w-px h-10 bg-slate-700"></div>
                <div>
                  <p className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-1">{t('rentinsurancehub.total_held', { defaultValue: `Total Held` })}</p>
                  <p className="text-xl font-black text-primary">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })} {data.totalHeld.toLocaleString()}</p>
                </div>
                <div className="bg-slate-800 px-3 py-1.5 rounded-lg border border-slate-600 flex items-center gap-2">
                  <div className={`w-2 h-2 rounded-full ${data.totalHeld < data.totalRequired ? 'bg-warning animate-pulse' : 'bg-success'}`}></div>
                  <span className="text-xs font-bold text-slate-300">{heldPercent}{t('rentinsurancehub.secured', { defaultValue: `% Secured` })}</span>
                </div>
              </div>
            </div>
            
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-slate-700/50 text-left">
                <thead>
                  <tr className="bg-slate-900/40">
                    {['Tenant / Apt', 'Required Deposit', 'Balance Held', 'Status', 'Actions'].map(h => (
                      <th key={h} className="px-6 py-4 text-xs font-black text-slate-400 uppercase tracking-wider">{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {data.accounts.map(acc => {
                    const required = Number(acc.monthly_insurance);
                    const current = Number(acc.total_saved);
                    const collected = Number(acc.collected_this_month || 0);
                    const status = collected >= required ? 'Fully Paid' : (collected > 0 ? 'Partially Paid' : 'Unpaid');
                    const isEditing = editingId === acc.id;
                    
                    return (
                      <tr key={acc.id} className="hover:bg-slate-800/40 transition-colors">
                        <td className="px-6 py-4">
                          <div className="font-bold text-white text-base">{acc.tenant_name}</div>
                          <div className="text-xs font-medium text-slate-400 bg-slate-800 inline-block px-2 py-0.5 rounded mt-1">{t('rentinsurancehub.apt', { defaultValue: `Apt` })} {acc.apartment_code}</div>
                        </td>
                        <td className="px-6 py-4">
                          {isEditing ? (
                            <input type="number" className="w-28 bg-slate-900 border border-primary rounded-lg px-3 py-2 text-white outline-none text-sm font-bold" value={editAmount} onChange={e => setEditAmount(e.target.value)} autoFocus />
                          ) : (
                            <span className="text-slate-300 font-medium">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })} {required.toLocaleString()}</span>
                          )}
                        </td>
                        <td className="px-6 py-4">
                          <span className="font-black text-white text-lg">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })} {current.toLocaleString()}</span>
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex px-3 py-1 rounded-full text-xs font-bold tracking-wide ${status === 'Fully Paid' ? 'bg-success/20 text-success border border-success/30' : status === 'Partially Paid' ? 'bg-warning/20 text-warning border border-warning/30' : 'bg-danger/20 text-danger border border-danger/30'}`}>
                            {status}
                          </span>
                        </td>
                        <td className="px-6 py-4">
                          {isEditing ? (
                            <div className="flex gap-2">
                              <button onClick={() => setEditingId(null)} className="text-slate-300 hover:text-white px-3 py-1.5 bg-slate-700 hover:bg-slate-600 rounded-lg text-xs font-bold transition-colors">{t('rentinsurancehub.cancel', { defaultValue: `Cancel` })}</button>
                              <button onClick={() => updateDepositMutation.mutate({ id: acc.id, amount: editAmount })} className="text-white bg-success hover:bg-green-600 px-3 py-1.5 rounded-lg text-xs font-bold shadow-lg shadow-success/20 transition-all">{t('rentinsurancehub.save', { defaultValue: `Save` })}</button>
                            </div>
                          ) : (
                            <div className="flex gap-2">
                              <button onClick={() => { setEditingId(acc.id); setEditAmount(acc.monthly_insurance); }} className="text-indigo-400 hover:text-white text-xs font-bold px-3 py-1.5 border border-slate-700 rounded-lg hover:bg-indigo-600 transition-colors">{t('rentinsurancehub.edit_base', { defaultValue: `Edit Base` })}</button>
                              <button onClick={() => { setManageModal({ account_id: acc.id, current_balance: current, max_deposit: Math.max(0, required - collected) }); setTxType('Deposit'); }} className="text-white bg-primary hover:bg-indigo-500 text-xs font-bold px-3 py-1.5 rounded-lg shadow-lg shadow-primary/20 transition-all">{t('rentinsurancehub.manage', { defaultValue: `Manage` })}</button>
                            </div>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )})}

        {(!accounts || accounts.length === 0) && (
          <div className="flex flex-col items-center justify-center p-16 glass-card rounded-3xl border-dashed border-2 border-slate-700 mt-8">
            <Shield size={48} className="text-slate-500 mb-4 opacity-50" />
            <h3 className="text-xl font-bold text-white mb-2">{t('rentinsurancehub.no_active_deposits', { defaultValue: `No Active Deposits` })}</h3>
            <p className="text-slate-400 text-center max-w-sm">{t('rentinsurancehub.there_are_no_insurance_account', { defaultValue: `There are no insurance accounts registered for the selected period.` })}</p>
          </div>
        )}
      </div>

      {manageModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="glass-card p-8 w-[30rem] border border-slate-700 animate-in zoom-in-95 duration-200 rounded-2xl shadow-2xl">
            <h3 className="text-2xl font-black mb-6 text-white flex items-center gap-3">
              <Shield className="text-primary" size={24} /> {t('rentinsurancehub.manage_balance', { defaultValue: `Manage Balance` })}
            </h3>
            <div className="space-y-5 mb-8">
              <div>
                <label className="block text-sm font-bold text-slate-400 mb-2 uppercase tracking-wider">{t('rentinsurancehub.transaction_type', { defaultValue: `Transaction Type` })}</label>
                <select value={txType} onChange={e => setTxType(e.target.value)} className="w-full bg-slate-900 border border-slate-600 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary font-medium">
                  <option value="Deposit">{t('rentinsurancehub.add_deposit', { defaultValue: `Add Deposit` })}</option>
                  <option value="Refund">{t('rentinsurancehub.issue_refund', { defaultValue: `Issue Refund` })}</option>
                  <option value="Deduct">{t('rentinsurancehub.deduct_for_damage', { defaultValue: `Deduct for Damage` })}</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-400 mb-2 uppercase tracking-wider">{t('rentinsurancehub.amount_cfa', { defaultValue: `Amount (CFA)` })}</label>
                <input type="number" value={txAmount} onChange={e => setTxAmount(e.target.value)} className="w-full bg-slate-900 border border-slate-600 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary text-lg font-bold" autoFocus />
                <p className="text-sm font-medium text-indigo-400 mt-2 bg-indigo-500/10 inline-block px-3 py-1 rounded-lg border border-indigo-500/20">{t('rentinsurancehub.current_balance_cfa', { defaultValue: `Current Balance: CFA` })} {Number(manageModal.current_balance).toLocaleString()}</p>
              </div>
              <div>
                <label className="block text-sm font-bold text-slate-400 mb-2 uppercase tracking-wider">{t('rentinsurancehub.notes', { defaultValue: `Notes` })}</label>
                <input type="text" value={txNotes} onChange={e => setTxNotes(e.target.value)} placeholder={txType === 'Deduct' ? 'e.g., Broken Window' : 'Optional notes'} className="w-full bg-slate-900 border border-slate-600 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary" />
              </div>
            </div>
            <div className="flex gap-4">
              <button onClick={() => setManageModal(null)} className="bg-slate-800 hover:bg-slate-700 border border-slate-600 text-white px-4 py-3 rounded-xl flex-1 font-bold transition-colors">{t('rentinsurancehub.cancel', { defaultValue: `Cancel` })}</button>
              <button onClick={() => { if(!txAmount || Number(txAmount) <= 0) { alert('Enter valid amount.'); return; } txMutation.mutate({ account_id: manageModal.account_id, type: txType, amount: txAmount, notes: txNotes, damage_reason: txType === 'Deduct' ? txNotes : null }); }} className={`px-4 py-3 rounded-xl flex-1 font-bold text-white shadow-lg transition-all ${txType === 'Deposit' ? 'bg-success hover:bg-green-600 shadow-success/20' : txType === 'Refund' ? 'bg-indigo-600 hover:bg-indigo-500 shadow-indigo-600/20' : 'bg-danger hover:bg-red-600 shadow-danger/20'}`}>{t('rentinsurancehub.confirm', { defaultValue: `Confirm` })} {txType}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const InsuranceActionsTab = () => {
  const queryClient = useQueryClient();
  const [modal, setModal] = useState(null);
  const [formData, setFormData] = useState({ amount:'', notes:'', damage_reason:'', invoice_id:'' });
  const [searchTerm, setSearchTerm] = useState('');

  const { data: accounts } = useQuery({ queryKey:['insuranceAccounts'], queryFn: async()=>(await api.get('/insurance')).data });
  const { data: invoices } = useQuery({ queryKey:['rentInvoices'], queryFn: async()=>(await api.get('/rent/invoices')).data });

  const txMutation = useMutation({
    mutationFn: (data) => api.post('/insurance/transaction', data),
    onSuccess: () => { queryClient.invalidateQueries(['insuranceAccounts']); setModal(null); setFormData({amount:'',notes:'',damage_reason:'',invoice_id:''}); }
  });

  const handleAction = (type, account) => {
    let maxAmt = Number(account.total_saved);
    if(type==='Deposit') maxAmt=Math.max(0,Number(account.monthly_insurance)-Number(account.collected_this_month||0));
    setModal({type,account_id:account.id,max_amount:maxAmt,tenant_name:account.tenant_name,contract_id:account.contract_id});
    if(type==='Refund') setFormData(f=>({...f,amount:account.total_saved}));
    else if(type==='Deposit') setFormData(f=>({...f,amount:maxAmt}));
  };

  const displayed = accounts?.filter(acc=>acc.tenant_name?.toLowerCase().includes(searchTerm.toLowerCase())||acc.apartment_code?.toLowerCase().includes(searchTerm.toLowerCase()));

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-white flex items-center gap-3"><Shield className="text-purple-400" size={26}/> {t('rentinsurancehub.insurance_deposits_actions', { defaultValue: `Insurance Deposits & Actions` })}</h2>
        <p className="text-muted mt-1">{t('rentinsurancehub.process_deposits_refunds_deduc', { defaultValue: `Process deposits, refunds, deductions and apply insurance to rent` })}</p>
      </div>
      <div className="glass-card p-4"><div className="relative max-w-md"><Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18}/><input type="text" placeholder={t('rentinsurancehub.search_by_tenant_or_apartment', { defaultValue: `Search by tenant or apartment...` })} value={searchTerm} onChange={e=>setSearchTerm(e.target.value)} className="w-full pl-10 pr-4 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary text-sm"/></div></div>
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {displayed?.map(acc=>(
          <div key={acc.id} className="glass-card p-6 flex flex-col hover:border-primary/30 transition-colors">
            <div className="flex justify-between items-start mb-5">
              <div className="flex items-center gap-3"><div className="bg-primary/20 p-3 rounded-xl text-primary shadow-inner"><Shield size={26}/></div><div><h3 className="text-base font-bold text-white">{acc.building_name} — {acc.apartment_code}</h3><p className="text-slate-400 text-sm">{acc.tenant_name}</p></div></div>
              <div className="text-right"><p className="text-xs text-slate-500 mb-1 uppercase tracking-wider font-semibold">{t('rentinsurancehub.total_saved', { defaultValue: `Total Saved` })}</p><p className="text-2xl font-bold text-primary">{t('rentinsurancehub.cfa', { defaultValue: `CFA` })} {Number(acc.total_saved).toLocaleString()}</p></div>
            </div>
            <div className="grid grid-cols-4 gap-2 border-t border-slate-700/50 pt-4">
              {[{type:'Deposit',Icon:ArrowDownCircle,label:'Add Deposit',hover:'hover:bg-primary/20 hover:text-primary',disabled:Number(acc.collected_this_month||0)>=Number(acc.monthly_insurance)},{type:'Refund',Icon:RefreshCcw,label:'Refund All',hover:'hover:bg-success/20 hover:text-success',disabled:Number(acc.total_saved)<=0},{type:'Apply_To_Rent',Icon:ArrowRightCircle,label:'To Rent',hover:'hover:bg-indigo-500/20 hover:text-indigo-400',disabled:Number(acc.total_saved)<=0},{type:'Deduct',Icon:ArrowUpCircle,label:'Deduct',hover:'hover:bg-danger/20 hover:text-danger',disabled:Number(acc.total_saved)<=0}].map(({type,Icon,label,hover,disabled})=>(
                <button key={type} onClick={()=>handleAction(type,acc)} disabled={disabled} className={`flex flex-col items-center justify-center p-3 rounded-xl bg-slate-800/50 text-slate-400 transition-colors border border-slate-700 disabled:opacity-30 ${hover}`}><Icon size={18} className="mb-1"/><span className="text-xs font-medium text-center leading-tight">{label}</span></button>
              ))}
            </div>
          </div>
        ))}
        {displayed?.length===0&&<div className="col-span-full p-8 text-center text-muted">{t('rentinsurancehub.no_active_insurance_accounts_f', { defaultValue: `No active insurance accounts found.` })}</div>}
      </div>
      {modal&&(
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="glass-card p-6 w-full max-w-md border border-slate-700 animate-in zoom-in-95 duration-200">
            <h3 className="text-xl font-bold mb-2 text-white">{modal.type==='Refund'?'Refund Insurance':modal.type==='Deposit'?'Add Monthly Insurance':modal.type==='Deduct'?'Deduct Damage':'Apply Insurance to Rent'}</h3>
            <p className="text-sm text-slate-400 mb-5">{t('rentinsurancehub.tenant', { defaultValue: `Tenant:` })} <span className="text-white font-medium">{modal.tenant_name}</span></p>
            <div className="space-y-4">
              {modal.type==='Apply_To_Rent'&&(<div><label className="block text-sm font-medium text-muted mb-2">{t('rentinsurancehub.select_unpaid_invoice', { defaultValue: `Select Unpaid Invoice` })}</label><select value={formData.invoice_id} onChange={e=>{const inv=invoices?.find(i=>i.id==e.target.value);setFormData(f=>({...f,invoice_id:e.target.value,amount:inv?Math.min(Number(inv.outstanding_debt),modal.max_amount):''}));}} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"><option value="">{t('rentinsurancehub.select_invoice', { defaultValue: `-- Select Invoice --` })}</option>{invoices?.filter(i=>i.contract_id