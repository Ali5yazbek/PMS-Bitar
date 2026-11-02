import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Receipt, Search, Download, RefreshCw } from 'lucide-react';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';

const AgentSubscriptionCollectionHistory = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [dateFilter, setDateFilter] = useState(new Date().toISOString().split('T')[0]);

  const { data: historyData = [], isLoading } = useQuery({
    queryKey: ['agent_subscription_history_collection'],
    queryFn: async () => {
      const res = await axios.get('/energy/agent/subscription-invoices');
      // The endpoint returns { tasks: [...], history: [...] }
      return res.data?.history || [];
    },
  });

  const filteredHistory = historyData.filter(item => {
    const matchesSearch = item.building_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          item.tenant_name?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesDate = dateFilter ? item.transaction_date === dateFilter : true;
    return matchesSearch && matchesDate;
  });

  const totalCollected = filteredHistory.reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);

  const handleExportExcel = async () => {
    if (filteredHistory.length === 0) return;

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Collection History');

    // Title Row
    sheet.mergeCells('A1:F1');
    const titleRow = sheet.getCell('A1');
    titleRow.value = `Subscription Collection History`;
    titleRow.font = { size: 16, bold: true };
    titleRow.alignment = { horizontal: 'center' };
    
    sheet.addRow([]);

    // Headers
    const headers = sheet.addRow(['Date', 'Building', 'Apartment', 'Tenant Name', 'Amount', 'Description']);
    headers.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headers.eachCell(cell => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4F46E5' } }; 
      cell.alignment = { horizontal: 'center' };
    });

    // Data
    filteredHistory.forEach(item => {
      const row = sheet.addRow([
        new Date(item.transaction_date).toLocaleDateString(),
        item.building_name || 'N/A',
        item.apartment_code || 'N/A',
        item.tenant_name || 'N/A',
        parseFloat(item.amount || 0).toFixed(2),
        item.description || ''
      ]);
      row.getCell(5).numFmt = '$#,##0.00';
    });

    // Adjust column widths
    sheet.columns.forEach(col => {
      col.width = 20;
    });

    // Total Row
    const totalRow = sheet.addRow(['', '', '', 'Total Collected:', totalCollected.toFixed(2), '']);
    totalRow.font = { bold: true };
    totalRow.getCell(5).numFmt = '$#,##0.00';

    const buffer = await workbook.xlsx.writeBuffer();
    saveAs(new Blob([buffer]), 'Agent_Subscription_Collection_History.xlsx');
  };

  return (
    <div className="p-6 md:p-8 max-w-7xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">
      {/* Header section */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 mb-8 shrink-0">
        <div>
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <div className="w-10 h-10 bg-primary/20 text-primary rounded-xl flex items-center justify-center">
              <Receipt size={22} />
            </div>
            Sub. Collection History
          </h1>
          <p className="text-slate-400 text-sm mt-2">
            Record of all subscription payments collected by you.
          </p>
        </div>

        <button 
          onClick={handleExportExcel}
          disabled={filteredHistory.length === 0}
          className="btn-primary py-2.5 px-5 rounded-xl text-sm font-bold shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <Download size={16} /> Export to Excel
        </button>
      </div>

      {/* Filters */}
      <div className="glass-card p-5 rounded-2xl mb-6 flex flex-col md:flex-row gap-4">
        <div className="flex-1 relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" />
          <input 
            type="text" 
            placeholder="Search by building or tenant..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-slate-900/50 border border-slate-700/50 focus:border-primary focus:ring-1 focus:ring-primary/50 text-white rounded-xl pl-11 pr-4 py-3 text-sm transition-all"
          />
        </div>
        <div className="w-full md:w-64">
          <input 
            type="date"
            value={dateFilter}
            onChange={(e) => setDateFilter(e.target.value)}
            className="w-full bg-slate-900/50 border border-slate-700/50 focus:border-primary focus:ring-1 focus:ring-primary/50 text-white rounded-xl px-4 py-3 text-sm transition-all cursor-text"
          />
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
         <div className="glass-card p-6 rounded-2xl border border-primary/20 bg-primary/5">
            <p className="text-sm font-medium text-primary mb-1">Total Collected (Filtered)</p>
            <p className="text-3xl font-bold text-white">${totalCollected.toFixed(2)}</p>
         </div>
         <div className="glass-card p-6 rounded-2xl border border-slate-700/50">
            <p className="text-sm font-medium text-slate-400 mb-1">Transactions Found</p>
            <p className="text-3xl font-bold text-white">{filteredHistory.length}</p>
         </div>
      </div>

      {/* Table */}
      <div className="glass-card rounded-2xl overflow-hidden flex-1 flex flex-col min-h-[400px]">
        {isLoading ? (
          <div className="flex-1 flex flex-col items-center justify-center p-12">
            <RefreshCw size={40} className="text-primary animate-spin mb-4" />
            <p className="text-slate-400">Loading collection history...</p>
          </div>
        ) : filteredHistory.length === 0 ? (
          <div className="flex-1 flex flex-col items-center justify-center p-12 text-center">
             <div className="w-16 h-16 bg-slate-800 rounded-full flex items-center justify-center mb-4">
                <Receipt size={24} className="text-slate-500" />
             </div>
             <p className="text-lg font-medium text-white">No history found</p>
             <p className="text-slate-400 text-sm mt-1 max-w-sm">
                You haven't collected any subscription payments matching the current filters.
             </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left whitespace-nowrap">
              <thead className="bg-slate-800/80 text-xs uppercase font-semibold text-slate-400">
                <tr>
                  <th className="px-6 py-4 rounded-tl-2xl">Date</th>
                  <th className="px-6 py-4">Building & Apt</th>
                  <th className="px-6 py-4">Tenant Name</th>
                  <th className="px-6 py-4">Amount</th>
                  <th className="px-6 py-4 rounded-tr-2xl">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50">
                {filteredHistory.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4">
                      <p className="text-sm text-white font-medium">
                        {new Date(item.transaction_date).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
                      </p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-medium text-white">{item.building_name}</p>
                      <p className="text-xs text-slate-400">Apt {item.apartment_code}</p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm text-slate-300">{item.tenant_name || 'N/A'}</p>
                    </td>
                    <td className="px-6 py-4">
                      <p className="text-sm font-bold text-success">${parseFloat(item.amount || 0).toFixed(2)}</p>
                    </td>
                    <td className="px-6 py-4">
                      <span className="px-2.5 py-1 rounded-full text-[10px] font-bold bg-success/20 text-success border border-success/30">
                        COLLECTED
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default AgentSubscriptionCollectionHistory;
