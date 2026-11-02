import React, { useState, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Receipt, Search, Download, RefreshCw, Printer } from 'lucide-react';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import PrintableDailyCollection from '../../components/agent/PrintableDailyCollection';

const AgentCollectionHistory = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [dateFilter, setDateFilter] = useState('');

  const { data: historyData = [], isLoading } = useQuery({
    queryKey: ['agent_rent_history'],
    queryFn: async () => {
      const res = await axios.get('/agent/rent/history');
      return res.data?.data || [];
    },
  });

  const filteredHistory = historyData.filter(item => {
    const matchesSearch = item.building_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          item.tenant_name?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesDate = dateFilter ? item.date === dateFilter : true;
    return matchesSearch && matchesDate;
  });

  const totalCollected = filteredHistory.reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);

  const handlePrint = () => {
    window.print();
  };

  const formattedForPrint = filteredHistory.map(item => ({
    building: item.building_name,
    apartment: item.apartment_number,
    tenant: item.tenant_name,
    amount: parseFloat(item.amount || 0),
    method: item.payment_method,
  }));

  const handleExportExcel = async () => {
    if (filteredHistory.length === 0) return;

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Collection History');

    // Title Row
    sheet.mergeCells('A1:G1');
    const titleRow = sheet.getCell('A1');
    titleRow.value = `Rent Collection History`;
    titleRow.font = { size: 16, bold: true };
    titleRow.alignment = { horizontal: 'center' };
    
    sheet.addRow([]);

    // Headers
    const headers = sheet.addRow(['Date', 'Building', 'Apartment', 'Tenant Name', 'Amount', 'Payment Method', 'Status']);
    headers.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headers.eachCell(cell => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4F46E5' } }; 
      cell.alignment = { horizontal: 'center' };
    });

    sheet.columns = [
      { key: 'date', width: 15 },
      { key: 'building', width: 25 },
      { key: 'apartment', width: 15 },
      { key: 'tenant', width: 30 },
      { key: 'amount', width: 15 },
      { key: 'method', width: 20 },
      { key: 'status', width: 15 },
    ];

    filteredHistory.forEach(item => {
      const isFull = parseFloat(item.remaining) === 0;
      sheet.addRow([
        new Date(item.date).toLocaleDateString(),
        item.building_name,
        item.apartment_number,
        item.tenant_name,
        parseFloat(item.amount || 0),
        item.payment_method,
        isFull ? 'Paid in Full' : 'Partial'
      ]);
    });

    // Format currency column
    sheet.getColumn('E').numFmt = '$#,##0.00';

    // Add total row at the end
    sheet.addRow([]);
    const totalRow = sheet.addRow(['', '', '', 'Total Collected:', totalCollected, '', '']);
    totalRow.font = { bold: true };
    totalRow.getCell(5).numFmt = '$#,##0.00';

    const buffer = await workbook.xlsx.writeBuffer();
    saveAs(new Blob([buffer]), `Agent_Collection_History.xlsx`);
  };

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Collection History</h1>
          <p className="text-slate-400">Review your past rent collections and receipts.</p>
        </div>
        <div className="flex items-center gap-4">
          <div className="bg-[#1E293B] border border-slate-700 rounded-xl px-6 py-3 flex flex-col items-end">
            <span className="text-xs text-slate-400 uppercase font-bold tracking-wider">Total Collected</span>
            <span className="text-2xl font-bold text-emerald-400">
              ${totalCollected.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
            </span>
          </div>
          <button 
            onClick={handlePrint}
            className="flex h-[72px] items-center gap-2 px-6 bg-slate-800 text-white hover:bg-slate-700 font-bold rounded-xl transition-colors border border-slate-700"
          >
            <Printer size={18} />
            Print PDF
          </button>
          <button 
            onClick={handleExportExcel}
            className="flex h-[72px] items-center gap-2 px-6 bg-indigo-500/20 text-indigo-400 hover:bg-indigo-500/30 font-bold rounded-xl transition-colors border border-indigo-500/30"
          >
            <Download size={18} />
            Export
          </button>
        </div>
      </div>

      <div className="mb-6 flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" size={20} />
          <input 
            type="text"
            placeholder="Search by building or tenant..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full bg-[#1E293B] border border-slate-700 text-white rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
          />
        </div>
        <div className="w-48 relative">
          <input 
            type="date"
            value={dateFilter}
            onChange={(e) => setDateFilter(e.target.value)}
            className="w-full bg-[#1E293B] border border-slate-700 text-slate-300 rounded-xl px-4 py-3 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 style-color-scheme-dark"
            style={{ colorScheme: 'dark' }}
          />
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center p-12">
          <RefreshCw className="animate-spin text-primary" size={32} />
        </div>
      ) : filteredHistory.length === 0 ? (
        <div className="flex flex-col items-center justify-center p-12 bg-[#1E293B] rounded-2xl border border-slate-700">
          <Receipt size={48} className="text-slate-500 mb-4" />
          <h2 className="text-xl font-bold text-white mb-2">No History Found</h2>
          <p className="text-slate-400">You haven't collected any rent payments yet.</p>
        </div>
      ) : (
        <div className="bg-[#1E293B] rounded-2xl border border-slate-700 overflow-hidden">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-[#0F172A] border-b border-slate-700">
                <th className="p-4 text-slate-400 font-semibold text-sm">Date</th>
                <th className="p-4 text-slate-400 font-semibold text-sm">Building / Apt</th>
                <th className="p-4 text-slate-400 font-semibold text-sm">Tenant</th>
                <th className="p-4 text-slate-400 font-semibold text-sm">Amount</th>
                <th className="p-4 text-slate-400 font-semibold text-sm">Method</th>
                <th className="p-4 text-slate-400 font-semibold text-sm">Status</th>
              </tr>
            </thead>
            <tbody>
              {filteredHistory.map((item, i) => {
                const isFull = parseFloat(item.remaining) === 0;
                return (
                  <tr key={i} className="border-b border-slate-700 hover:bg-[#0F172A]/50 transition-colors">
                    <td className="p-4 text-white text-sm">
                      {new Date(item.date).toLocaleDateString()}
                    </td>
                    <td className="p-4">
                      <p className="text-white font-semibold">{item.building_name}</p>
                      <p className="text-xs text-slate-400">Apt {item.apartment_number}</p>
                    </td>
                    <td className="p-4 text-white text-sm">{item.tenant_name}</td>
                    <td className="p-4">
                      <p className="text-success font-bold">${item.amount}</p>
                    </td>
                    <td className="p-4 text-slate-300 text-sm">{item.payment_method}</td>
                    <td className="p-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                        isFull ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'
                      }`}>
                        {isFull ? 'Paid in Full' : 'Partial'}
                      </span>
                      {!isFull && <p className="text-xs text-warning mt-1">Rem: ${item.remaining}</p>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Hidden Print Component */}
      <div className="absolute opacity-0 pointer-events-none -z-50 print-target">
        <PrintableDailyCollection 
          collections={formattedForPrint}
          agentName={(() => { try { return JSON.parse(localStorage.getItem('user'))?.name || 'Agent'; } catch { return 'Agent'; } })()}
          date={dateFilter || new Date().toLocaleDateString()}
          totalCollected={totalCollected}
        />
      </div>
    </div>
  );
};

export default AgentCollectionHistory;
