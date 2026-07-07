import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { CreditCard, Plus, Calendar, Printer, FileSpreadsheet } from 'lucide-react';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';

const Expenses = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [dateRange, setDateRange] = useState({ start_date: new Date(new Date().setDate(new Date().getDate() - 30)).toISOString().split('T')[0], end_date: new Date().toISOString().split('T')[0] });
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [showAdd, setShowAdd] = useState(false);
  
  const [newExpense, setNewExpense] = useState({
    category: 'Other', entity_type: '', entity_id: '', amount: '', date: new Date().toISOString().split('T')[0], notes: ''
  });

  const { data: expenses = [], isLoading: expLoading } = useQuery({
    queryKey: ['expenses', dateRange.start_date, dateRange.end_date, categoryFilter],
    queryFn: async () => {
      const res = await axios.get(`/expenses?start_date=${dateRange.start_date}&end_date=${dateRange.end_date}&category=${categoryFilter}`);
      return res.data;
    }
  });

  const { data: dashboard = null, isLoading: dashLoading } = useQuery({
    queryKey: ['expenseDashboard'],
    queryFn: async () => {
      const res = await axios.get('/expenses/dashboard');
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (expData) => axios.post('/expenses', expData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['expenses'] });
      queryClient.invalidateQueries({ queryKey: ['expenseDashboard'] });
      setShowAdd(false);
      setNewExpense({ category: 'Other', entity_type: '', entity_id: '', amount: '', date: new Date().toISOString().split('T')[0], notes: '' });
    }
  });

  const categories = ['All', 'Construction', 'Apartment', 'Building', 'Warehouse', 'Office', 'Transport', 'Maintenance', 'Labor', 'Utilities', 'Other'];

  // Quick Date Filters
  const setQuickDate = (mode) => {
    const end = new Date();
    const start = new Date();
    if (mode === 'today') {
      start.setDate(end.getDate());
    } else if (mode === 'month') {
      start.setDate(1); // First of the month
    } else if (mode === 'year') {
      start.setMonth(0, 1); // Jan 1st of the year
    }
    setDateRange({ start_date: start.toISOString().split('T')[0], end_date: end.toISOString().split('T')[0] });
  };

  const handlePrint = () => {
    window.print();
  };

  const handleExportExcel = async () => {
    if (expenses.length === 0) {
      alert("No expenses to export!");
      return;
    }

    // 1. Calculate the most expensive apartment
    const aptTotals = {};
    expenses.forEach(exp => {
      // Sometimes it's categorized as Apartment, or just has "Apt" in the notes/entity name
      if (exp.category === 'Apartment' || exp.entity_type === 'Apartment') {
        const key = exp.entity_name || exp.notes || 'Unknown Apartment';
        if (!aptTotals[key]) aptTotals[key] = 0;
        aptTotals[key] += parseFloat(exp.amount);
      }
    });

    let highestApt = null;
    let maxAptCost = -1;
    for (const [apt, total] of Object.entries(aptTotals)) {
      if (total > maxAptCost) {
        maxAptCost = total;
        highestApt = apt;
      }
    }

    // 2. Setup Excel Workbook
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Expenses Report');

    // 3. Add Professional Header
    worksheet.columns = [
      { header: 'Date', key: 'date', width: 15 },
      { header: 'Category', key: 'category', width: 20 },
      { header: 'Notes / Details', key: 'notes', width: 40 },
      { header: 'Reference', key: 'reference', width: 20 },
      { header: 'User', key: 'user', width: 20 },
      { header: 'Amount (CFA)', key: 'amount', width: 20 }
    ];

    const headerRow = worksheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF1E293B' } // Dark blue/slate
    };
    headerRow.alignment = { vertical: 'middle', horizontal: 'center' };

    // 4. Sort and Add Rows
    const sortedExpenses = [...expenses].sort((a, b) => {
      if (a.category < b.category) return -1;
      if (a.category > b.category) return 1;
      return new Date(a.date) - new Date(b.date);
    });

    let totalApartment = 0;
    let totalConstruction = 0;
    let grandTotal = 0;

    sortedExpenses.forEach(exp => {
      const amount = parseFloat(exp.amount);
      grandTotal += amount;
      
      if (exp.category === 'Apartment' || exp.entity_type === 'Apartment') totalApartment += amount;
      if (exp.category === 'Construction' || exp.entity_type === 'Construction') totalConstruction += amount;

      const combinedNotes = exp.entity_name ? `[${exp.entity_name}] ${exp.notes || ''}` : (exp.notes || 'N/A');

      const rowData = {
        date: exp.date,
        category: exp.category,
        notes: combinedNotes,
        reference: exp.reference_id || '-',
        user: exp.user_name || 'System',
        amount: amount
      };

      const row = worksheet.addRow(rowData);
      row.getCell('amount').numFmt = '#,##0.00'; // Format as number with commas

      // Highlight if this row belongs to the highest costing apartment
      const isApartmentExpense = exp.category === 'Apartment' || exp.entity_type === 'Apartment';
      const isTargetApt = highestApt && (exp.entity_name === highestApt || exp.notes === highestApt);

      if (isApartmentExpense && isTargetApt) {
        row.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFFFCCCC' } // Light Red Highlight
        };
        row.font = { color: { argb: 'FF990000' }, bold: true }; // Dark Red Text
      }
    });

    // 5. Add Summary Totals at the bottom
    worksheet.addRow([]); // Empty row for spacing
    
    const summaryHeader = worksheet.addRow(['', '', 'SUMMARY', '', '', '']);
    summaryHeader.font = { bold: true, size: 14 };
    worksheet.mergeCells(`C${summaryHeader.number}:F${summaryHeader.number}`);

    const addSummaryRow = (label, total) => {
      const row = worksheet.addRow(['', '', label, '', '', total]);
      row.getCell(6).numFmt = '#,##0.00';
      row.getCell(3).font = { bold: true };
      row.getCell(6).font = { bold: true };
      return row;
    };

    addSummaryRow('Total Apartment Expenses:', totalApartment);
    addSummaryRow('Total Construction Expenses:', totalConstruction);
    
    const grandRow = addSummaryRow('GRAND TOTAL:', grandTotal);
    grandRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2E8F0' } };

    // Write file
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    saveAs(blob, `Expenses_Report_${dateRange.start_date}_to_${dateRange.end_date}.xlsx`);
  };

  // Calculate dynamic total for print/display
  const totalAmount = expenses.reduce((sum, exp) => sum + parseFloat(exp.amount), 0);

  return (
    <div className="flex h-full bg-background print:bg-white print:text-black">
      {/* Main Content */}
      <div className="flex-1 flex flex-col h-full overflow-hidden print:overflow-visible">
        <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0">
          
          {/* Print Header */}
          <div className="hidden print:block mb-6 border-b-2 border-black pb-4">
            <h1 className="text-3xl font-bold mb-2">Expenses Report</h1>
            <p className="text-sm">Period: {dateRange.start_date} to {dateRange.end_date}</p>
            <p className="text-sm">Category Filter: {categoryFilter}</p>
            <h2 className="text-xl font-bold mt-4">Total Amount: CFA {totalAmount.toLocaleString()}</h2>
          </div>

          <div className="flex justify-between items-end mb-8 print:hidden">
            <div>
              <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
                <CreditCard className="me-3 text-danger" size={32} /> {t('expenses.title')}
              </h1>
              <p className="text-muted">{t('expenses.subtitle')}</p>
            </div>
            <div className="flex items-center space-x-3">
              <button 
                onClick={handlePrint}
                className="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl flex items-center transition-colors border border-slate-700"
              >
                <Printer size={18} className="me-2" /> {t('expenses.print_btn')}
              </button>
              <button 
                onClick={handleExportExcel}
                className="bg-green-600 hover:bg-green-500 text-white px-4 py-2 rounded-xl flex items-center transition-colors shadow-lg shadow-green-600/20 font-medium"
              >
                <FileSpreadsheet size={18} className="me-2" /> {t('expenses.export_btn')}
              </button>
              <button 
                onClick={() => setShowAdd(!showAdd)}
                className="bg-danger hover:bg-red-600 text-white px-4 py-2 rounded-xl flex items-center font-medium transition-colors shadow-lg shadow-danger/20"
              >
                <Plus size={18} className="me-2" /> {t('expenses.log_btn')}
              </button>
            </div>
          </div>

          {showAdd && (
            <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4 max-w-4xl mx-auto border-danger/30 print:hidden">
              <h3 className="text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-2">{t('expenses.new_title')}</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-6">
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">{t('expenses.cat_label')}</label>
                  <select value={newExpense.category} onChange={e => setNewExpense({...newExpense, category: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm">
                    {categories.filter(c => c !== 'All').map(c => <option key={c} value={c}>{c}</option>)}
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">{t('expenses.amt_label')}</label>
                  <input type="number" value={newExpense.amount} onChange={e => setNewExpense({...newExpense, amount: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                </div>
                <div>
                  <label className="block text-xs font-medium text-muted mb-1">{t('expenses.date_label')}</label>
                  <input type="date" value={newExpense.date} onChange={e => setNewExpense({...newExpense, date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" style={{ colorScheme: 'dark' }} />
                </div>
                <div className="col-span-2 md:col-span-1">
                  <label className="block text-xs font-medium text-muted mb-1">{t('expenses.notes_label')}</label>
                  <input type="text" value={newExpense.notes} onChange={e => setNewExpense({...newExpense, notes: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
                </div>
              </div>
              <div className="flex justify-end space-x-3 mt-4 pt-4 border-t border-slate-700/50">
                <button onClick={() => setShowAdd(false)} className="px-6 py-2 bg-slate-700 text-white rounded-lg transition-colors hover:bg-slate-600">{t('expenses.cancel')}</button>
                <button onClick={() => addMutation.mutate(newExpense)} disabled={!newExpense.amount || addMutation.isPending} className="px-6 py-2 bg-danger hover:bg-red-600 text-white rounded-lg transition-colors shadow-lg shadow-danger/20 font-medium">{t('expenses.save')}</button>
              </div>
            </div>
          )}

          <div className="flex flex-wrap items-center justify-between gap-4 mb-6 print:hidden">
            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg p-1 border border-slate-700">
              {categories.map(cat => (
                <button
                  key={cat}
                  onClick={() => setCategoryFilter(cat)}
                  className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${categoryFilter === cat ? 'bg-danger text-white' : 'text-slate-400 hover:text-white'}`}
                >
                  {cat}
                </button>
              ))}
            </div>
            
            <div className="flex items-center space-x-4">
              {/* Quick Date Filters */}
              <div className="flex items-center space-x-1 bg-slate-800 rounded-lg p-1 border border-slate-700">
                <button onClick={() => setQuickDate('today')} className="px-3 py-1.5 rounded-md text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-700 transition-colors">{t('expenses.filter_daily')}</button>
                <button onClick={() => setQuickDate('month')} className="px-3 py-1.5 rounded-md text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-700 transition-colors">{t('expenses.filter_monthly')}</button>
                <button onClick={() => setQuickDate('year')} className="px-3 py-1.5 rounded-md text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-700 transition-colors">{t('expenses.filter_yearly')}</button>
              </div>

              {/* Date Pickers */}
              <div className="flex items-center space-x-2 bg-slate-800 rounded-lg px-3 py-1 border border-slate-700 h-9">
                <Calendar size={16} className="text-muted" />
                <input type="date" value={dateRange.start_date} onChange={e => setDateRange({...dateRange, start_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
                <span className="text-muted">{t('expenses.filter_to')}</span>
                <input type="date" value={dateRange.end_date} onChange={e => setDateRange({...dateRange, end_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
              </div>
            </div>
          </div>

          <div className="glass-card overflow-hidden print:border-0 print:shadow-none">
            <table className="w-full text-start border-collapse print:text-sm">
              <thead>
                <tr className="border-b border-slate-700/50 bg-slate-800/30 print:bg-transparent print:border-black">
                  <th className="p-4 text-xs font-semibold text-muted uppercase print:text-black text-start">{t('expenses.col_date')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase print:text-black text-start">{t('expenses.col_cat')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase print:text-black text-start">{t('expenses.col_notes')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase print:text-black text-start">{t('expenses.col_ref')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase print:text-black text-start">{t('expenses.col_user')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-end print:text-black">{t('expenses.col_amount')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50 print:divide-black">
                {expLoading ? (
                   <tr><td colSpan="6" className="p-8 text-center text-muted">Loading expenses...</td></tr>
                ) : expenses.length > 0 ? expenses.map((exp) => (
                  <tr key={exp.id} className="hover:bg-slate-800/30 transition-colors print:hover:bg-transparent">
                    <td className="p-4 text-sm text-slate-300 print:text-black">{exp.date}</td>
                    <td className="p-4 text-sm text-slate-300 print:text-black">
                      <span className="px-2 py-1 rounded bg-slate-800 border border-slate-700 text-xs print:bg-transparent print:border-0 print:p-0">
                        {exp.category}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-white print:text-black">
                      {exp.entity_name && <div className="font-semibold text-indigo-300 print:text-indigo-800 mb-1">{exp.entity_name}</div>}
                      <div className="text-slate-300 print:text-black">{exp.notes || '-'}</div>
                    </td>
                    <td className="p-4 text-sm text-indigo-300 print:text-black">{exp.reference_id || '-'}</td>
                    <td className="p-4 text-sm text-slate-400 print:text-black">{exp.user_name || 'System'}</td>
                    <td className="p-4 text-sm text-danger font-bold text-end print:text-black">{t('common.currency')} {parseFloat(exp.amount).toLocaleString()}</td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan="6" className="p-8 text-center text-muted">{t('expenses.no_data')}</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Right Dashboard */}
      <div className="hidden xl:block w-80 glass-panel p-6 overflow-y-auto z-10 shrink-0 border-s border-slate-800 print:hidden">
        <h2 className="text-xl font-bold text-white mb-6">{t('expenses.dash_title')}</h2>
        {dashLoading ? (
          <div className="animate-pulse flex space-x-4"><div className="flex-1 space-y-6 py-1"><div className="h-2 bg-slate-700 rounded"></div><div className="space-y-3"><div className="grid grid-cols-3 gap-4"><div className="h-2 bg-slate-700 rounded col-span-2"></div><div className="h-2 bg-slate-700 rounded col-span-1"></div></div><div className="h-2 bg-slate-700 rounded"></div></div></div></div>
        ) : dashboard && (
          <div className="space-y-6">
            <div className="p-5 glass-card relative overflow-hidden border-danger/30">
              <div className="absolute top-0 right-0 w-24 h-24 bg-danger/10 blur-2xl rounded-full"></div>
              <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-2">{t('expenses.dash_total')}</h3>
              <div className="text-3xl font-bold text-white">{t('common.currency')} {parseFloat(dashboard.todayTotal).toLocaleString()}</div>
            </div>

            <div className="p-5 glass-card">
              <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('expenses.dash_cat')}</h3>
              <div className="space-y-3">
                {dashboard.categoryBreakdown.length > 0 ? dashboard.categoryBreakdown.map((cat, i) => (
                  <div key={i} className="flex justify-between items-center border-b border-slate-700/50 pb-2 last:border-0 last:pb-0">
                    <span className="text-slate-300">{cat.category}</span>
                    <span className="text-white font-medium">{t('common.currency')} {parseFloat(cat.total).toLocaleString()}</span>
                  </div>
                )) : <div className="text-muted text-sm">{t('expenses.dash_no_exp')}</div>}
              </div>
            </div>

            <div className="p-5 glass-card">
              <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('expenses.dash_ent')}</h3>
              <div className="space-y-3">
                {dashboard.entityBreakdown.length > 0 ? dashboard.entityBreakdown.map((ent, i) => (
                  <div key={i} className="flex justify-between items-center border-b border-slate-700/50 pb-2 last:border-0 last:pb-0">
                    <span className="text-slate-300 text-sm">{ent.name}</span>
                    <span className="text-white font-medium">{t('common.currency')} {parseFloat(ent.total).toLocaleString()}</span>
                  </div>
                )) : <div className="text-muted text-sm">{t('expenses.dash_no_ent')}</div>}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Expenses;
