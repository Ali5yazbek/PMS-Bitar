import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Calendar, Download, Printer, ChevronDown, ChevronUp, Eye, Building2, TrendingUp, Wallet, AlertCircle, X } from 'lucide-react';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import api from '../api/axios';
import InteractiveCurrency from '../components/common/InteractiveCurrency';

const FinancialBuildingReport = () => {
  const { t } = useTranslation();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expandedBuildings, setExpandedBuildings] = useState({});
  const [viewModalData, setViewModalData] = useState(null);
  const [printingBuildingId, setPrintingBuildingId] = useState(null);
  const [printMode, setPrintMode] = useState(null);
  const [printInvoice, setPrintInvoice] = useState(null);
  
  // Default to current month
  const today = new Date();
  const firstDay = new Date(today.getFullYear(), today.getMonth(), 1).toISOString().split('T')[0];
  const lastDay = new Date(today.getFullYear(), today.getMonth() + 1, 0).toISOString().split('T')[0];
  
  const [dateRange, setDateRange] = useState({ start: firstDay, end: lastDay });
  
  const [modalDateRange, setModalDateRange] = useState({ start: firstDay, end: lastDay });
  const [modalInvoices, setModalInvoices] = useState([]);
  const [loadingModalInvoices, setLoadingModalInvoices] = useState(false);

  useEffect(() => {
    fetchReportData();
  }, [dateRange]);

  useEffect(() => {
    const afterPrint = () => setPrintingBuildingId(null);
    window.addEventListener('afterprint', afterPrint);
    return () => window.removeEventListener('afterprint', afterPrint);
  }, []);

  useEffect(() => {
    if (printMode) {
      setTimeout(() => {
        window.print();
        setPrintMode(null);
        setPrintInvoice(null);
      }, 300);
    }
  }, [printMode]);

  const fetchReportData = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/reports/detailed-financial-buildings?start_date=${dateRange.start}&end_date=${dateRange.end}`);
      setData(res.data);
      
      // Auto-expand all buildings by default
      const expands = {};
      res.data.buildings.forEach(b => { expands[b.id] = true; });
      setExpandedBuildings(expands);
    } catch (error) {
      console.error("Error fetching financial report:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleDateChange = (e, field) => {
    setDateRange(prev => ({ ...prev, [field]: e.target.value }));
  };

  const toggleBuilding = (id) => {
    setExpandedBuildings(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const handleExportExcel = async () => {
    if (!data) return;
    
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Financial Report');

    // Title Row
    sheet.mergeCells('A1:D1');
    const titleRow = sheet.getCell('A1');
    titleRow.value = `Financial Report (${dateRange.start} to ${dateRange.end})`;
    titleRow.font = { size: 16, bold: true };
    titleRow.alignment = { horizontal: 'center' };
    
    sheet.addRow([]);

    // Headers
    const headers = sheet.addRow(['Building / Apartment', 'Total Income', 'Total Received', 'Remaining Unpaid']);
    headers.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headers.eachCell(cell => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4F46E5' } }; // Indigo-600
      cell.alignment = { horizontal: 'center' };
    });

    sheet.columns = [
      { key: 'name', width: 30 },
      { key: 'income', width: 20 },
      { key: 'received', width: 20 },
      { key: 'remaining', width: 20 },
    ];

    // Global Totals
    const globalRow = sheet.addRow([
      'GLOBAL TOTAL ALL BUILDINGS',
      data.global.total_income,
      data.global.total_received,
      data.global.total_remaining
    ]);
    globalRow.font = { bold: true };
    globalRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF3F4F6' } };
    
    sheet.addRow([]);

    // Buildings & Apartments
    data.buildings.forEach(b => {
      const bRow = sheet.addRow([
        `Building: ${b.name}`,
        b.total_income,
        b.total_received,
        b.total_remaining
      ]);
      bRow.font = { bold: true, color: { argb: 'FF1F2937' } };
      bRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE5E7EB' } };

      b.apartments.forEach(a => {
        sheet.addRow([
          `   Apartment ${a.code}`,
          a.total_income,
          a.total_received,
          a.total_remaining
        ]);
      });
      sheet.addRow([]); // Spacing
    });

    // Format currency columns
    sheet.getColumn('B').numFmt = '#,##0.00';
    sheet.getColumn('C').numFmt = '#,##0.00';
    sheet.getColumn('D').numFmt = '#,##0.00';

    const buffer = await workbook.xlsx.writeBuffer();
    saveAs(new Blob([buffer]), `Financial_Building_Report_${dateRange.start}_${dateRange.end}.xlsx`);
  };

  const handlePrint = () => {
    window.print();
  };

  const handlePrintBuilding = (e, id) => {
    e.stopPropagation();
    setPrintingBuildingId(id);
    setTimeout(() => {
      window.print();
    }, 100);
  };

  const formatCurrency = (amount) => {
    return <InteractiveCurrency amountCFA={amount || 0} />;
  };

  if (loading && !data) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  const renderReceipt = (invoice, aptData) => {
    const remain = Number(invoice.amount) - Number(invoice.paid_amount || 0);
    return (
      <div className="max-w-2xl mx-auto border border-gray-200 rounded-2xl p-10 shadow-sm mb-8 print:shadow-none print:border-none print:mb-0" style={{ pageBreakAfter: 'always' }}>
        <div className="flex justify-between items-start border-b border-gray-100 pb-8 mb-8">
          <div className="flex items-center space-x-4">
            <div className="w-14 h-14 bg-indigo-600 rounded-2xl text-white font-bold text-3xl flex items-center justify-center">P</div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Payment Receipt</h1>
              <p className="text-gray-500">Rent Invoice</p>
            </div>
          </div>
          <div className="text-right">
            <h2 className="text-xl font-bold text-gray-900">{invoice.invoice_number}</h2>
            <p className="text-gray-500 text-sm mt-1">{new Date().toLocaleDateString()}</p>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-8 mb-8 border-b border-gray-100 pb-8">
          <div>
            <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Apartment</h3>
            <p className="text-lg font-bold text-gray-900">Apt {aptData.code}</p>
            <p className="text-gray-600 mt-1">Building: {aptData.buildingName}</p>
          </div>
          <div className="text-right">
            <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Invoice Date</h3>
            <p className="text-gray-900 font-medium">{invoice.due_date}</p>
            <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1 mt-4">Status</h3>
            <p className="text-gray-900 font-bold">{invoice.status}</p>
          </div>
        </div>

        <div className="bg-gray-50 rounded-xl p-6 mb-8 print:bg-transparent print:border print:border-gray-200">
          <div className="flex justify-between items-center mb-3">
            <span className="text-gray-600">Total Amount</span>
            <span className="font-medium text-gray-900">{formatCurrency(invoice.amount)}</span>
          </div>
          <div className="flex justify-between items-center mb-3">
            <span className="text-gray-600">Amount Paid</span>
            <span className="font-bold text-emerald-600">{formatCurrency(invoice.paid_amount || 0)}</span>
          </div>
          <div className="flex justify-between items-center pt-3 border-t border-gray-200">
            <span className="font-bold text-gray-900">Remaining Balance</span>
            <span className="font-bold text-rose-600 text-xl">{formatCurrency(remain)}</span>
          </div>
        </div>

        <div className="text-center text-sm text-gray-500 mt-12">
          <p>Thank you for your payment!</p>
        </div>
      </div>
    );
  };

  if (printMode === 'receipt' && printInvoice && viewModalData) {
    return (
      <div className="absolute top-0 left-0 w-full min-h-screen bg-white z-[200] p-8 text-black print:block print:p-0">
        {renderReceipt(printInvoice, viewModalData)}
      </div>
    );
  }

  if (printMode === 'receipt_all' && viewModalData) {
    return (
      <div className="absolute top-0 left-0 w-full min-h-screen bg-white z-[200] p-8 text-black print:block print:p-0">
        {modalInvoices.map((inv, idx) => (
          <div key={idx}>
            {renderReceipt(inv, viewModalData)}
          </div>
        ))}
      </div>
    );
  }

  return (
    <div className={`p-6 max-w-7xl mx-auto space-y-6 animate-fade-in print:p-0 print:m-0 ${printMode ? 'hidden print:hidden' : 'block print:block'}`}>
      
      {/* Header Section */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-white/80 backdrop-blur-md p-6 rounded-2xl shadow-sm border border-gray-100 print:hidden">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
            Financial Building Report
          </h1>
          <p className="text-gray-500 mt-1">Comprehensive income & payment breakdown per building.</p>
        </div>
        
        <div className="mt-4 md:mt-0 flex flex-wrap gap-4 items-center">
          <div className="flex items-center space-x-2 bg-gray-50 p-2 rounded-lg border border-gray-200">
            <Calendar className="w-5 h-5 text-gray-500" />
            <input 
              type="date" 
              value={dateRange.start} 
              onChange={(e) => handleDateChange(e, 'start')}
              className="bg-transparent border-none text-sm focus:ring-0 cursor-pointer"
            />
            <span className="text-gray-400">to</span>
            <input 
              type="date" 
              value={dateRange.end} 
              onChange={(e) => handleDateChange(e, 'end')}
              className="bg-transparent border-none text-sm focus:ring-0 cursor-pointer"
            />
          </div>
          
          <button 
            onClick={handleExportExcel}
            className="flex items-center space-x-2 bg-green-50 text-green-700 px-4 py-2 rounded-lg font-medium hover:bg-green-100 transition-colors border border-green-200"
          >
            <Download className="w-4 h-4" />
            <span>Excel</span>
          </button>
          
          <button 
            onClick={handlePrint}
            className="flex items-center space-x-2 bg-indigo-50 text-indigo-700 px-4 py-2 rounded-lg font-medium hover:bg-indigo-100 transition-colors border border-indigo-200"
          >
            <Printer className="w-4 h-4" />
            <span>Print</span>
          </button>
        </div>
      </div>

      {/* Global Summary Cards */}
      {data && (
        <div className={`grid grid-cols-1 md:grid-cols-3 gap-6 ${printingBuildingId ? 'print:hidden' : ''}`}>
          <div className="bg-gradient-to-br from-indigo-500 to-indigo-600 p-6 rounded-2xl shadow-lg text-white transform hover:scale-[1.02] transition-transform duration-200 print:break-inside-avoid print:shadow-none print:border print:text-black print:bg-white">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-indigo-100 font-medium print:text-gray-600">Total Income (All)</h3>
              <div className="p-2 bg-white/20 rounded-lg print:hidden">
                <TrendingUp className="w-6 h-6 text-white" />
              </div>
            </div>
            <p className="text-3xl font-bold">{formatCurrency(data.global.total_income)}</p>
          </div>
          
          <div className="bg-gradient-to-br from-emerald-500 to-emerald-600 p-6 rounded-2xl shadow-lg text-white transform hover:scale-[1.02] transition-transform duration-200 print:break-inside-avoid print:shadow-none print:border print:text-black print:bg-white">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-emerald-100 font-medium print:text-gray-600">Total Received</h3>
              <div className="p-2 bg-white/20 rounded-lg print:hidden">
                <Wallet className="w-6 h-6 text-white" />
              </div>
            </div>
            <p className="text-3xl font-bold">{formatCurrency(data.global.total_received)}</p>
          </div>
          
          <div className="bg-gradient-to-br from-rose-500 to-rose-600 p-6 rounded-2xl shadow-lg text-white transform hover:scale-[1.02] transition-transform duration-200 print:break-inside-avoid print:shadow-none print:border print:text-black print:bg-white">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-rose-100 font-medium print:text-gray-600">Total Remain Unpaid</h3>
              <div className="p-2 bg-white/20 rounded-lg print:hidden">
                <AlertCircle className="w-6 h-6 text-white" />
              </div>
            </div>
            <p className="text-3xl font-bold">{formatCurrency(data.global.total_remaining)}</p>
          </div>
        </div>
      )}

      {/* Buildings Breakdown */}
      {data && (
        <div className="space-y-6">
          {data.buildings.map((building) => (
            <div 
              key={building.id} 
              className={`bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden print:shadow-none print:mb-8 ${printingBuildingId && printingBuildingId !== building.id ? 'print:hidden' : ''}`}
            >
              
              {/* Building Header */}
              <div 
                className="bg-gray-50/80 p-5 flex flex-col md:flex-row print:flex-row justify-between items-start md:items-center print:items-center cursor-pointer hover:bg-gray-100 transition-colors"
                onClick={() => toggleBuilding(building.id)}
              >
                <div className="flex items-center space-x-4 mb-4 md:mb-0 print:mb-0">
                  <div className="p-3 bg-white rounded-xl shadow-sm border border-gray-100 print:hidden">
                    <Building2 className="w-6 h-6 text-indigo-600" />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-gray-800">{building.name}</h2>
                    <p className="text-sm text-gray-500">{building.apartments.length} Apartments</p>
                  </div>
                </div>

                <div className="flex items-center space-x-6 w-full md:w-auto print:w-auto overflow-x-auto pb-2 md:pb-0 print:pb-0">
                  <div className="text-right">
                    <p className="text-xs text-gray-500 uppercase font-semibold">Income</p>
                    <p className="font-bold text-gray-800">{formatCurrency(building.total_income)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-emerald-500 uppercase font-semibold">Received</p>
                    <p className="font-bold text-emerald-600">{formatCurrency(building.total_received)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-rose-500 uppercase font-semibold">Remaining</p>
                    <p className="font-bold text-rose-600">{formatCurrency(building.total_remaining)}</p>
                  </div>
                  <div className="pl-4 border-l border-gray-200 text-gray-400 print:hidden flex items-center space-x-2">
                    <button 
                      onClick={(e) => handlePrintBuilding(e, building.id)}
                      className="p-2 hover:bg-gray-200 rounded-lg transition-colors text-gray-500 hover:text-indigo-600"
                      title="Print this building only"
                    >
                      <Printer className="w-5 h-5" />
                    </button>
                    {expandedBuildings[building.id] ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
                  </div>
                </div>
              </div>

              {/* Apartments Table */}
              {(expandedBuildings[building.id] || printingBuildingId === building.id) && (
                <div className="border-t border-gray-100 p-0 overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-white border-b border-gray-100">
                        <th className="py-4 px-6 text-sm font-medium text-gray-500">Apartment</th>
                        <th className="py-4 px-6 text-sm font-medium text-gray-500">Tenant Name(s)</th>
                        <th className="py-4 px-6 text-sm font-medium text-gray-500 text-right">Income</th>
                        <th className="py-4 px-6 text-sm font-medium text-gray-500 text-right">Received</th>
                        <th className="py-4 px-6 text-sm font-medium text-gray-500 text-right">Remaining Unpaid</th>
                        <th className="py-4 px-6 text-sm font-medium text-gray-500 text-center print:hidden">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-50">
                      {building.apartments.map((apt) => (
                        <tr key={apt.id} className="hover:bg-gray-50/50 transition-colors print:break-inside-avoid">
                          <td className="py-4 px-6">
                            <span className="font-semibold text-gray-700 bg-gray-100 px-3 py-1 rounded-md">Apt {apt.code}</span>
                          </td>
                          <td className="py-4 px-6 text-sm text-gray-600">
                            {apt.tenant_names_str || 'N/A'}
                          </td>
                          <td className="py-4 px-6 text-right font-medium text-gray-700">
                            {formatCurrency(apt.total_income)}
                          </td>
                          <td className="py-4 px-6 text-right font-medium text-emerald-600 print:text-black">
                            {formatCurrency(apt.total_received)}
                          </td>
                          <td className="py-4 px-6 text-right font-medium text-rose-600 print:text-black">
                            {formatCurrency(apt.total_remaining)}
                          </td>
                          <td className="py-4 px-6 text-center print:hidden">
                            <button 
                              onClick={() => {
                                setViewModalData({ ...apt, buildingName: building.name });
                                setModalDateRange(dateRange);
                                setModalInvoices(apt.invoices || []);
                              }}
                              className="inline-flex items-center space-x-1 text-sm text-indigo-600 hover:text-indigo-800 bg-indigo-50 px-3 py-1.5 rounded-lg transition-colors"
                            >
                              <Eye className="w-4 h-4" />
                              <span>View</span>
                            </button>
                          </td>
                        </tr>
                      ))}
                      {building.apartments.length === 0 && (
                        <tr>
                          <td colSpan="5" className="py-8 text-center text-gray-400 italic">No apartments found for this building.</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* View Details Modal */}
      {viewModalData && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 z-50 print:hidden animate-fade-in">
          <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] flex flex-col overflow-hidden">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50/80">
              <div>
                <h2 className="text-xl font-bold text-gray-800">Apartment {viewModalData.code} Details</h2>
                <p className="text-sm text-gray-500 mt-1">{viewModalData.buildingName}</p>
              </div>
              <button 
                onClick={() => setViewModalData(null)}
                className="p-2 hover:bg-gray-200 rounded-lg transition-colors text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 bg-white">
              <div className="flex justify-between items-center mb-4">
                <div className="flex items-center space-x-3">
                  <h3 className="text-xs font-bold text-gray-500 uppercase tracking-wider">
                    Invoices
                  </h3>
                  <div className="flex items-center space-x-2 bg-gray-50 p-1 rounded border border-gray-200">
                    <input 
                      type="date" 
                      value={modalDateRange.start} 
                      onChange={async (e) => {
                         const newStart = e.target.value;
                         setModalDateRange(prev => ({...prev, start: newStart}));
                         setLoadingModalInvoices(true);
                         try {
                           const res = await api.get(`/apartments/${viewModalData.id}/rent-invoices?start_date=${newStart}&end_date=${modalDateRange.end}`);
                           setModalInvoices(res.data);
                         } catch(err) { console.error(err); }
                         setLoadingModalInvoices(false);
                      }} 
                      className="bg-transparent border-none text-xs focus:ring-0 p-1 w-28" 
                    />
                    <span className="text-gray-400 text-xs">to</span>
                    <input 
                      type="date" 
                      value={modalDateRange.end} 
                      onChange={async (e) => {
                         const newEnd = e.target.value;
                         setModalDateRange(prev => ({...prev, end: newEnd}));
                         setLoadingModalInvoices(true);
                         try {
                           const res = await api.get(`/apartments/${viewModalData.id}/rent-invoices?start_date=${modalDateRange.start}&end_date=${newEnd}`);
                           setModalInvoices(res.data);
                         } catch(err) { console.error(err); }
                         setLoadingModalInvoices(false);
                      }} 
                      className="bg-transparent border-none text-xs focus:ring-0 p-1 w-28" 
                    />
                  </div>
                </div>
                <button 
                  onClick={() => setPrintMode('receipt_all')}
                  className="flex items-center space-x-2 px-3 py-1.5 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 rounded-lg transition-colors font-medium text-xs"
                >
                  <Printer className="w-4 h-4" />
                  <span>Print All</span>
                </button>
              </div>
              
              <div className="space-y-4">
                {loadingModalInvoices ? (
                  <p className="text-center text-gray-400 py-8 italic">Loading invoices...</p>
                ) : modalInvoices.length === 0 ? (
                  <p className="text-center text-gray-400 py-8 italic">No invoices found for this period.</p>
                ) : (
                  modalInvoices.map((inv) => (
                    <div key={inv.invoice_id} className="p-4 rounded-xl border border-gray-100 bg-gray-50 flex justify-between items-center group">
                      <div>
                        <p className="font-medium text-gray-800">{inv.invoice_number}</p>
                        <p className="text-xs text-gray-500 mt-1">Due: {inv.due_date}</p>
                      </div>
                      <div className="text-right flex flex-col items-end">
                        <div className="flex items-center space-x-4 mb-1">
                          <p className="text-sm text-gray-400 line-through decoration-rose-300">{formatCurrency(inv.amount)}</p>
                          <button 
                            onClick={() => {
                              setPrintInvoice(inv);
                              setPrintMode('receipt');
                            }}
                            className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-100 rounded-md transition-colors opacity-0 group-hover:opacity-100"
                            title="Print this receipt"
                          >
                            <Printer className="w-4 h-4" />
                          </button>
                        </div>
                        <p className="font-bold text-emerald-600 mb-2">+ {formatCurrency(inv.paid_amount || 0)}</p>
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                          inv.status === 'Paid' ? 'bg-emerald-100 text-emerald-700' :
                          inv.status === 'Partial' ? 'bg-amber-100 text-amber-700' :
                          'bg-rose-100 text-rose-700'
                        }`}>
                          {inv.status}
                        </span>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            <div className="p-6 border-t border-gray-100 bg-gray-50/80 flex justify-end">
              <button 
                onClick={() => setViewModalData(null)}
                className="px-6 py-2 bg-white border border-gray-200 text-gray-700 hover:bg-gray-50 font-medium rounded-xl transition-colors shadow-sm"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FinancialBuildingReport;
