import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import axios from '../api/axios';
import { ArrowLeft, Briefcase, DollarSign, Calendar, Activity, Hammer, Users, Printer, Search, AlertTriangle, Check, RotateCcw } from 'lucide-react';
import { useQueryClient, useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

const StockCard = ({ stock, project_id }) => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [action, setAction] = useState(null); // 'consume', 'waste', 'return'
  const [qty, setQty] = useState('');
  const [notes, setNotes] = useState('');

  const moveMutation = useMutation({
    mutationFn: (data) => axios.post('/construction/site-stock/movement', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['constructionDetails', project_id]);
      setAction(null);
      setQty('');
      setNotes('');
    }
  });

  const handleAction = (type) => {
    moveMutation.mutate({
      construction_id: project_id,
      item_name: stock.item_name,
      type: type,
      quantity: qty,
      notes: notes
    });
  };

  return (
    <div className="glass-card p-4 border-indigo-500/20">
      <div className="flex justify-between items-center mb-4">
        <h3 className="font-bold text-white text-lg">{t(`workshop.items.${stock.item_name}`, { defaultValue: stock.item_name })}</h3>
        <span className="bg-indigo-500/20 text-indigo-300 px-2 py-1 rounded text-sm font-bold">{stock.quantity} {stock.unit}</span>
      </div>
      
      {!action ? (
        <div className="flex flex-col gap-2">
          <button onClick={() => setAction('Site_To_Consumption')} className="w-full bg-emerald-500/20 text-emerald-400 hover:bg-emerald-500/30 px-3 py-2 rounded text-sm font-medium flex items-center justify-center gap-2 transition-colors"><Check size={16}/> Consume Material</button>
          <div className="flex gap-2">
            <button onClick={() => setAction('Site_To_Waste')} className="flex-1 bg-red-500/20 text-red-400 hover:bg-red-500/30 px-3 py-2 rounded text-xs font-medium flex items-center justify-center gap-1 transition-colors"><AlertTriangle size={14}/> Mark Waste</button>
            <button onClick={() => setAction('Site_To_Warehouse')} className="flex-1 bg-slate-700/50 text-slate-300 hover:bg-slate-700 px-3 py-2 rounded text-xs font-medium flex items-center justify-center gap-1 transition-colors"><RotateCcw size={14}/> Return</button>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-xs text-muted uppercase font-medium">{action.split('_')[2]} Material</span>
            <button onClick={() => setAction(null)} className="text-muted hover:text-white text-xs">Cancel</button>
          </div>
          <input type="number" placeholder="Quantity" value={qty} onChange={e => setQty(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-white text-sm" />
          {action === 'Site_To_Waste' && <input type="text" placeholder="Reason (e.g. Broken)" value={notes} onChange={e => setNotes(e.target.value)} className="w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-white text-sm" />}
          <button onClick={() => handleAction(action)} disabled={!qty} className="w-full bg-primary hover:bg-indigo-600 text-white px-3 py-2 rounded text-sm font-medium transition-colors">Confirm</button>
        </div>
      )}
    </div>
  );
};

const ConstructionDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();

  const [dateRange, setDateRange] = useState({ start_date: '', end_date: '' });

  const { data, isLoading, error } = useQuery({
    queryKey: ['constructionDetails', id],
    queryFn: async () => {
      const res = await axios.get(`/constructions/${id}`);
      return res.data;
    }
  });

  if (isLoading) return <div className="p-8 text-white">Loading...</div>;
  if (error) return <div className="p-8 text-danger">Error loading construction project.</div>;

  const { project, expenses, ledger, materials } = data;
  
  // Filter expenses by date
  const filteredExpenses = expenses.filter(exp => {
    if (dateRange.start_date && exp.date < dateRange.start_date) return false;
    if (dateRange.end_date && exp.date > dateRange.end_date) return false;
    return true;
  });

  const budget = parseFloat(project.budget || 0);
  const spent = parseFloat(ledger.total || 0);
  const remaining = budget - spent;
  const completionPercent = budget > 0 ? Math.min((spent / budget) * 100, 100).toFixed(0) : 0;

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="flex h-full bg-background print:bg-white print:text-black">
      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0 print:overflow-visible">
        <button onClick={() => navigate('/constructions')} className="text-muted hover:text-white flex items-center mb-6 transition-colors print:hidden">
          <ArrowLeft size={16} className="mr-2" /> Back to Constructions
        </button>

        <div className="flex justify-between items-start mb-8 print:mb-2">
          <div>
            <h1 className="text-3xl font-bold text-white print:text-black mb-2 print:mb-0 print:text-lg">{project.name}</h1>
            <div className="flex items-center gap-4">
              <p className="text-muted print:text-slate-600 flex items-center print:text-xs">
                <Briefcase size={16} className="mr-2"/> Project Ledger & Expense History
              </p>
              {project.workshop_id && (
                 <button onClick={() => navigate(`/workshop/${project.workshop_id}`)} className="text-indigo-400 hover:text-indigo-300 text-sm bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20 transition-colors">
                   View Workshop Blueprint
                 </button>
              )}
            </div>
          </div>
          <div className="flex flex-col items-end gap-2">
            <span className="px-4 py-1 rounded-full bg-primary/20 text-primary border border-primary/30 font-medium print:border-black print:text-black print:px-2 print:py-0 print:text-xs">
              {project.status}
            </span>
            <button onClick={handlePrint} className="flex items-center text-sm bg-slate-800 hover:bg-slate-700 text-white px-3 py-1.5 rounded-lg transition-colors print:hidden">
              <Printer size={16} className="mr-2"/> Print Ledger
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8 print:grid-cols-4 print:gap-2 print:mb-2">
          <div className="glass-card p-6 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">Estimated Cost</h3>
            <div className="text-2xl print:text-sm font-bold text-white print:text-black">CFA {parseFloat(project.estimated_cost || budget).toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 border-warning/30 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">Actual Cost</h3>
            <div className="text-2xl print:text-sm font-bold text-warning print:text-black">CFA {spent.toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 border-success/30 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">Remaining</h3>
            <div className="text-2xl print:text-sm font-bold text-success print:text-black">CFA {remaining.toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 border-indigo-500/30 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">Completion</h3>
            <div className="flex items-center">
              <div className="text-2xl print:text-sm font-bold text-indigo-400 print:text-black mr-4 print:mr-2">{completionPercent}%</div>
              <div className="flex-1 bg-slate-800 print:bg-slate-200 rounded-full h-2 print:h-1">
                <div className="bg-indigo-500 print:bg-black h-2 print:h-1 rounded-full" style={{ width: `${completionPercent}%` }}></div>
              </div>
            </div>
          </div>
        </div>

        {materials && materials.length > 0 && (
          <div className="mb-8">
            <h2 className="text-xl font-bold text-white mb-4">Smart Material Comparison</h2>
            <div className="glass-card overflow-hidden">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-800/30 border-b border-slate-700/50">
                    <th className="p-4 text-xs font-semibold text-muted uppercase">Material</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-right">Estimated</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-right">Used</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-right">Site Stock</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-right">Wasted</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-right">Difference (Rem)</th>
                    <th className="p-4 text-xs font-semibold text-muted uppercase text-center">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {materials.map(mat => {
                    const est = parseFloat(mat.estimated_quantity);
                    const used = parseFloat(mat.used_quantity);
                    const wasted = parseFloat(mat.wasted_quantity || 0);
                    const stockItem = data.site_stock?.find(s => s.item_name.toLowerCase() === mat.item_name.toLowerCase());
                    const siteStockQty = stockItem ? parseFloat(stockItem.quantity) : 0;
                    
                    const remaining = est - used - wasted;
                    
                    let statusIcon = "🟢 Within Budget";
                    let statusText = "text-success";
                    let diffText = `+${remaining}`;
                    let diffColor = "text-success";

                    if (used + wasted > est) {
                      statusIcon = "🔴 Over Budget";
                      statusText = "text-danger";
                      diffText = `${remaining}`; // negative
                      diffColor = "text-danger";
                    } else if (used + wasted === est) {
                      statusIcon = "🟠 Limit Reached";
                      statusText = "text-warning";
                      diffText = "0";
                      diffColor = "text-slate-400";
                    } else if (used + wasted > est * 0.8) {
                      statusIcon = "🟡 Warning (80%)";
                      statusText = "text-warning";
                    }

                    return (
                      <tr key={mat.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="p-4 text-sm font-bold text-white">{t(`workshop.items.${mat.item_name}`, { defaultValue: mat.item_name })}</td>
                        <td className="p-4 text-sm text-slate-300 text-right">{est} {mat.unit}</td>
                        <td className={`p-4 text-sm font-bold text-right ${statusText}`}>{used} {mat.unit}</td>
                        <td className="p-4 text-sm font-bold text-indigo-400 text-right">{siteStockQty} {mat.unit}</td>
                        <td className="p-4 text-sm font-bold text-red-400 text-right">{wasted} {mat.unit}</td>
                        <td className={`p-4 text-sm font-bold text-right ${diffColor}`}>{diffText} {mat.unit}</td>
                        <td className="p-4 text-sm text-center font-medium">{statusIcon}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
            
            {/* Site Stock Management */}
            {data.site_stock && data.site_stock.length > 0 && (
              <div className="mt-8">
                <h2 className="text-xl font-bold text-white mb-4">Construction Site Stock</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {data.site_stock.map(stock => (
                    <StockCard key={stock.id} stock={stock} project_id={project.id} queryClient={window.queryClient} />
                  ))}
                </div>
              </div>
            )}
            
            {materials.some(m => parseFloat(m.used_quantity) > parseFloat(m.estimated_quantity)) && (
              <div className="mt-4 p-4 rounded-lg bg-danger/10 border border-danger/30 text-danger font-medium flex flex-col gap-1">
                 <div className="flex items-center gap-2"><span className="text-xl">🔴</span> Warning: Material consumption exceeded the workshop estimate.</div>
                 <div className="text-sm opacity-80 mt-1 pl-8">Possible reasons: Design modifications, material waste, construction errors, or missing inventory.</div>
              </div>
            )}
            {spent > parseFloat(project.estimated_cost || budget) && (
               <div className="mt-4 p-4 rounded-lg bg-danger/10 border border-danger/30 text-danger font-medium flex items-center gap-2">
                 <span className="text-xl">🔴</span> Warning: Project Actual Cost (CFA {spent.toLocaleString()}) has exceeded the Workshop Estimated Cost (CFA {parseFloat(project.estimated_cost || budget).toLocaleString()}).
              </div>
            )}
          </div>
        )}

        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold text-white print:text-black">Cost History (Ledger)</h2>
          
          <div className="flex items-center space-x-2 bg-slate-800 rounded-lg px-3 py-1 border border-slate-700 print:hidden">
            <Calendar size={16} className="text-muted" />
            <input type="date" value={dateRange.start_date} onChange={e => setDateRange({...dateRange, start_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
            <span className="text-muted">to</span>
            <input type="date" value={dateRange.end_date} onChange={e => setDateRange({...dateRange, end_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
          </div>
        </div>

        <div className="glass-card overflow-hidden print:border print:border-black print:shadow-none">
          <table className="w-full text-left border-collapse print:text-[10px] print:leading-tight">
            <thead>
              <tr className="border-b border-slate-700/50 bg-slate-800/30 print:bg-slate-100 print:border-black">
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">Date</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">Category</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">Notes / Items</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">Reference</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">User</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase text-right">Cost</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 print:divide-black">
              {filteredExpenses.length > 0 ? filteredExpenses.map((exp) => (
                <tr key={exp.id} className="hover:bg-slate-800/30 transition-colors print:hover:bg-transparent">
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-slate-300 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">{exp.date}</td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-slate-300 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">
                    <span className="px-2 py-1 rounded bg-slate-800 border border-slate-700 text-xs print:text-[10px] print:bg-transparent print:border-0 print:p-0 print:text-black">
                      {exp.category}
                    </span>
                  </td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-white print:text-black align-top border-r border-transparent print:border-black">
                    <div>{exp.notes || 'N/A'}</div>
                    {exp.items && exp.items.length > 0 && (
                      <div className="mt-1 space-y-0.5 pl-2 border-l-2 border-indigo-500/30 print:border-black">
                        {exp.items.map((item, idx) => (
                          <div key={idx} className="text-xs print:text-[9px] text-muted print:text-slate-700 flex justify-between">
                            <span>- {item.product_name} <span className="font-bold text-slate-400 print:text-black">x{item.quantity}</span></span>
                            <span className="text-indigo-400 print:text-black">CFA {parseFloat(item.total_price).toLocaleString()}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-indigo-300 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">{exp.reference_id || '-'}</td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-slate-400 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">{exp.user_name || 'System'}</td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-warning font-bold text-right print:text-black align-top whitespace-nowrap">CFA {parseFloat(exp.amount).toLocaleString()}</td>
                </tr>
              )) : (
                <tr>
                  <td colSpan="6" className="p-8 print:p-2 text-center text-muted print:text-black print:text-[10px]">No expenses recorded for this project yet.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Right Account Summary */}
      <div className="hidden xl:block w-80 glass-panel p-6 overflow-y-auto z-10 shrink-0 print:hidden">
        <h2 className="text-xl font-bold text-white mb-6">Account Summary</h2>
        <div className="space-y-6">
          <div className="p-5 glass-card relative overflow-hidden">
            <div className="absolute top-0 right-0 w-24 h-24 bg-primary/20 blur-2xl rounded-full"></div>
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">Expense Breakdown</h3>
            
            <div className="space-y-4">
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-slate-300 flex items-center"><Hammer size={14} className="mr-2"/> Materials</span>
                <span className="text-white font-bold">CFA {parseFloat(ledger.materials).toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-slate-300 flex items-center"><Users size={14} className="mr-2"/> Labor</span>
                <span className="text-white font-bold">CFA {parseFloat(ledger.labor).toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                <span className="text-slate-300 flex items-center"><Activity size={14} className="mr-2"/> Other</span>
                <span className="text-white font-bold">CFA {parseFloat(ledger.other).toLocaleString()}</span>
              </div>
              <div className="flex justify-between items-center pt-2">
                <span className="text-warning font-bold">Total Expenses</span>
                <span className="text-warning font-bold text-lg">CFA {parseFloat(ledger.total).toLocaleString()}</span>
              </div>
            </div>
          </div>
          
          <div className="p-5 glass-card">
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-3">Project Info</h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between"><span className="text-muted">Start Date:</span> <span className="text-white">{project.start_date || 'N/A'}</span></div>
              <div className="flex justify-between"><span className="text-muted">End Date:</span> <span className="text-white">{project.end_date || 'N/A'}</span></div>
              <div className="flex justify-between"><span className="text-muted">Manager:</span> <span className="text-white">{project.manager || 'N/A'}</span></div>
              <div className="flex justify-between"><span className="text-muted">Owner:</span> <span className="text-white">{project.owner || 'N/A'}</span></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ConstructionDetails;
