import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Download, Printer, ChevronDown, ChevronUp, AlertTriangle, Eye, Building2, TrendingUp, Wallet, AlertCircle, X, Filter } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import ExcelJS from 'exceljs';
import { saveAs } from 'file-saver';
import api from '../api/axios';
import ApartmentInvoicesModal from './ApartmentInvoicesModal';
import { useCurrency } from '../contexts/CurrencyContext';

const GeneratorSubscriptionReport = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { formatAmount } = useCurrency();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [expandedBuildings, setExpandedBuildings] = useState({});
  const [printingBuildingId, setPrintingBuildingId] = useState(null);
  const [buildingFilter, setBuildingFilter] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [buildingsList, setBuildingsList] = useState([]);
  
  const [expiringAlerts, setExpiringAlerts] = useState([]);
  const [showExpiringModal, setShowExpiringModal] = useState(false);
  
  const [selectedApartment, setSelectedApartment] = useState(null);

  useEffect(() => {
    fetchBuildingsList();
  }, []);

  useEffect(() => {
    fetchReportData();
  }, [buildingFilter, startDate, endDate]);

  useEffect(() => {
    const afterPrint = () => setPrintingBuildingId(null);
    window.addEventListener('afterprint', afterPrint);
    return () => window.removeEventListener('afterprint', afterPrint);
  }, []);

  const fetchBuildingsList = async () => {
    try {
      const res = await api.get('/buildings');
      setBuildingsList(res.data);
    } catch (error) {
      console.error("Error fetching buildings list:", error);
    }
  };

  const fetchReportData = async () => {
    setLoading(true);
    try {
      let url = '/reports/generator-subscriptions?';
      const params = new URLSearchParams();
      if (buildingFilter) params.append('building_id', buildingFilter);
      if (startDate) params.append('start_date', startDate);
      if (endDate) params.append('end_date', endDate);
      
      url += params.toString();
      
      const res = await api.get(url);
      setData(res.data);
      
      // Auto-expand all buildings by default
      const expands = {};
      let expiring = [];
      
      res.data.buildings.forEach(b => { 
        expands[b.id] = true; 
        
        b.apartments.forEach(a => {
          if (a.days_remaining !== null && a.days_remaining <= 7) {
            expiring.push({
              buildingName: b.name,
              apartmentName: a.name,
              tenantName: a.tenant_name,
              daysRemaining: a.days_remaining
            });
          }
        });
      });
      setExpandedBuildings(expands);

      if (expiring.length > 0) {
        setExpiringAlerts(expiring);
        setShowExpiringModal(true);
      }
      
    } catch (error) {
      console.error("Error fetching generator subscription report:", error);
    } finally {
      setLoading(false);
    }
  };

  const toggleBuilding = (id) => {
    setExpandedBuildings(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const handleExportExcel = async () => {
    if (!data) return;
    
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Generator Subscriptions');

    // Title Row
    sheet.mergeCells('A1:E1');
    const titleRow = sheet.getCell('A1');
    titleRow.value = `Generator Subscription Report`;
    titleRow.font = { size: 16, bold: true };
    titleRow.alignment = { horizontal: 'center' };
    
    sheet.addRow([]);

    // Headers
    const headers = sheet.addRow(['Apartment', 'Tenant Name', 'Income', 'Paid', 'Remaining Unpaid']);
    headers.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headers.eachCell(cell => {
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF4F46E5' } }; 
      cell.alignment = { horizontal: 'center' };
    });

    sheet.columns = [
      { key: 'name', width: 20 },
      { key: 'tenant', width: 30 },
      { key: 'income', width: 20 },
      { key: 'paid', width: 20 },
      { key: 'remaining', width: 20 },
    ];

    // Track global total formula cells
    let globalIncomeCells = [];
    let globalPaidCells = [];
    let globalRemainCells = [];

    // Global Totals Row - We will insert it later or update its formulas
    const globalRow = sheet.addRow([
      'GLOBAL TOTAL ALL BUILDINGS',
      '',
      0,
      0,
      0
    ]);
    globalRow.font = { bold: true };
    globalRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF3F4F6' } };
    
    sheet.addRow([]);

    // Buildings & Apartments
    data.buildings.forEach(b => {
      // Add building header (we will set formulas after we know the rows)
      const bRow = sheet.addRow([
        `Building: ${b.name}`,
        '',
        0,
        0,
        0
      ]);
      bRow.font = { bold: true, color: { argb: 'FF1F2937' } };
      bRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE5E7EB' } };

      const startRow = sheet.rowCount + 1;

      b.apartments.forEach(a => {
        sheet.addRow([
          `${a.name}`,
          `${a.tenant_name}`,
          a.total_income,
          a.total_received,
          a.total_remaining
        ]);
      });
      
      const endRow = sheet.rowCount;

      // Set formulas for building header
      if (endRow >= startRow) {
        bRow.getCell(3).value = { formula: `SUM(C${startRow}:C${endRow})` };
        bRow.getCell(4).value = { formula: `SUM(D${startRow}:D${endRow})` };
        bRow.getCell(5).value = { formula: `SUM(E${startRow}:E${endRow})` };
      }

      globalIncomeCells.push(`C${bRow.number}`);
      globalPaidCells.push(`D${bRow.number}`);
      globalRemainCells.push(`E${bRow.number}`);

      // Spacing
      sheet.addRow([]);
    });

    // Update global row formulas
    if (globalIncomeCells.length > 0) {
      globalRow.getCell(3).value = { formula: globalIncomeCells.join('+') };
      globalRow.getCell(4).value = { formula: globalPaidCells.join('+') };
      globalRow.getCell(5).value = { formula: globalRemainCells.join('+') };
    }

    // Format currency columns
    sheet.getColumn('C').numFmt = '#,##0.00';
    sheet.getColumn('D').numFmt = '#,##0.00';
    sheet.getColumn('E').numFmt = '#,##0.00';

    const buffer = await workbook.xlsx.writeBuffer();
    saveAs(new Blob([buffer]), `Generator_Subscription_Report.xlsx`);
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
    return formatAmount(amount || 0);
  };

  if (loading && !data) {
    return (
      <div className="flex justify-center items-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6 animate-fade-in print:p-0 print:m-0">
      
      {/* Header Section */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center bg-white/80 backdrop-blur-md p-6 rounded-2xl shadow-sm border border-gray-100 print:hidden">
        <div>
          <h1 className="text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent">
            Generator Subscription Report
          </h1>
          <p className="text-gray-500 mt-1">Overview of all generator subscriptions and balances.</p>
        </div>
        
        <div className="mt-4 md:mt-0 flex flex-wrap gap-4 items-center">
          <div className="flex items-center space-x-2 bg-gray-50 p-2 rounded-lg border border-gray-200">
            <Filter className="w-5 h-5 text-gray-500" />
            <select 
              value={buildingFilter}
              onChange={(e) => setBuildingFilter(e.target.value)}
              className="bg-transparent border-none text-sm focus:ring-0 cursor-pointer outline-none"
            >
              <option value="">All Buildings</option>
              {buildingsList.map(b => (
                <option key={b.id} value={b.id}>{b.name}</option>
              ))}
            </select>
          </div>

          <div className="flex items-center space-x-2 bg-gray-50 p-2 rounded-lg border border-gray-200">
            <span className="text-sm text-gray-500 font-medium ml-1">From:</span>
            <input 
              type="date" 
              value={startDate}
              onChange={(e) => setStartDate(e.target.value)}
              className="bg-transparent border-none text-sm focus:ring-0 cursor-pointer outline-none"
            />
          </div>

          <div className="flex items-center space-x-2 bg-gray-50 p-2 rounded-lg border border-gray-200">
            <span className="text-sm text-gray-500 font-medium ml-1">To:</span>
            <input 
              type="date" 
              value={endDate}
              onChange={(e) => setEndDate(e.target.value)}
              className="bg-transparent border-none text-sm focus:ring-0 cursor-pointer outline-none"
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
              <h3 className="text-emerald-100 font-medium print:text-gray-600">Total Paid</h3>
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
                <div className="flex items-center space-x-3 mb-4 md:mb-0 print:mb-0">
                  <div className="p-2 bg-indigo-100 rounded-lg text-indigo-600 print:hidden">
                    <Building2 className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-gray-800">Building: {building.name}</h2>
                    <p className="text-sm text-gray-500 print:hidden">{building.apartments.length} Subscriptions</p>
                  </div>
                </div>

                <div className="flex flex-col md:flex-row print:flex-row items-end md:items-center print:items-center space-y-2 md:space-y-0 print:space-y-0 space-x-0 md:space-x-6 print:space-x-6 w-full md:w-auto">
                  <div className="text-right">
                    <p className="text-sm text-gray-500">Income</p>
                    <p className="font-semibold text-gray-800">{formatCurrency(building.total_income)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-500">Paid</p>
                    <p className="font-semibold text-emerald-600">{formatCurrency(building.total_received)}</p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-500">Remain</p>
                    <p className="font-semibold text-rose-600">{formatCurrency(building.total_remaining)}</p>
                  </div>
                  
                  <div className="flex items-center space-x-2 pt-2 md:pt-0 print:hidden">
                    <button 
                      onClick={(e) => handlePrintBuilding(e, building.id)}
                      className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                      title="Print only this building"
                    >
                      <Printer className="w-5 h-5" />
                    </button>
                    <div className="p-2 text-gray-400">
                      {expandedBuildings[building.id] ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
                    </div>
                  </div>
                </div>
              </div>

              {/* Apartments Table */}
              {expandedBuildings[building.id] && (
                <div className="border-t border-gray-100 print:block">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse">
                      <thead>
                        <tr className="bg-gray-50 text-gray-500 text-sm uppercase tracking-wider">
                          <th className="px-6 py-4 font-medium">Apartment</th>
                          <th className="px-6 py-4 font-medium">Tenant</th>
                          <th className="px-6 py-4 font-medium text-right">Income</th>
                          <th className="px-6 py-4 font-medium text-right">Paid</th>
                          <th className="px-6 py-4 font-medium text-right">Remain</th>
                          <th className="px-6 py-4 font-medium text-right print:hidden">Action</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-100 text-sm">
                        {building.apartments.map((apt) => (
                          <tr key={apt.id} className="hover:bg-gray-50/50 transition-colors print:break-inside-avoid">
                            <td className="px-6 py-4">
                              <div className="font-medium text-gray-800">{apt.name}</div>
                              {apt.days_remaining !== null && apt.days_remaining <= 7 && (
                                <span className="inline-flex items-center px-2 py-0.5 mt-1 rounded text-xs font-medium bg-red-100 text-red-800 print:hidden">
                                  Expiring soon
                                </span>
                              )}
                            </td>
                            <td className="px-6 py-4 text-gray-600">
                              {apt.tenant_name}
                            </td>
                            <td className="px-6 py-4 text-right font-medium text-gray-800">
                              {formatCurrency(apt.total_income)}
                            </td>
                            <td className="px-6 py-4 text-right text-emerald-600 print:text-black">
                              {formatCurrency(apt.total_received)}
                            </td>
                            <td className="px-6 py-4 text-right text-rose-600 font-medium print:text-black">
                              {formatCurrency(apt.total_remaining)}
                            </td>
                            <td className="px-6 py-4 text-right print:hidden">
                              <button 
                                onClick={() => setSelectedApartment({
                                  ...apt,
                                  building_name: building.name
                                })}
                                className="inline-flex items-center space-x-1 px-3 py-1.5 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 rounded-lg transition-colors text-sm font-medium"
                              >
                                <Eye className="w-4 h-4" />
                                <span>View</span>
                              </button>
                            </td>
                          </tr>
                        ))}
                        {building.apartments.length === 0 && (
                          <tr>
                            <td colSpan="6" className="px-6 py-8 text-center text-gray-400">
                              No generator subscriptions found for this building.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Expiring Subscriptions Modal */}
      {showExpiringModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm print:hidden animate-fade-in">
          <div className="bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden flex flex-col max-h-[80vh]">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-red-50">
              <div className="flex items-center space-x-3 text-red-600">
                <AlertTriangle className="w-6 h-6" />
                <h3 className="text-lg font-bold">Expiring Subscriptions Alert</h3>
              </div>
              <button 
                onClick={() => setShowExpiringModal(false)}
                className="text-red-400 hover:text-red-600 transition-colors p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto space-y-4 bg-gray-50 flex-1">
              {expiringAlerts.map((alert, idx) => (
                <div key={idx} className="bg-white border border-red-100 rounded-xl p-4 shadow-sm flex items-center justify-between">
                  <div>
                    <h4 className="font-bold text-gray-800">
                      Building: {alert.buildingName} - Apt: {alert.apartmentName}
                    </h4>
                    <p className="text-sm text-gray-500 mt-1">Tenant: {alert.tenantName}</p>
                    <p className="text-sm text-red-600 font-medium mt-1">
                      {alert.daysRemaining < 0 
                        ? `Expired ${Math.abs(alert.daysRemaining)} days ago` 
                        : `Expires in ${alert.daysRemaining} days`}
                    </p>
                  </div>
                  <button 
                    onClick={() => {
                      setBuildingFilter(buildingsList.find(b => b.name === alert.buildingName)?.id || '');
                      setShowExpiringModal(false);
                    }}
                    className="flex items-center space-x-1 text-sm bg-red-50 text-red-600 px-3 py-1.5 rounded-lg hover:bg-red-100 transition-colors font-medium"
                  >
                    <Eye className="w-4 h-4" />
                    <span>View</span>
                  </button>
                </div>
              ))}
            </div>

            <div className="p-4 border-t border-gray-100 bg-white flex justify-end">
              <button
                onClick={() => setShowExpiringModal(false)}
                className="px-6 py-2 bg-gray-100 text-gray-700 font-medium rounded-xl hover:bg-gray-200 transition-colors"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {selectedApartment && (
        <ApartmentInvoicesModal 
          apartment={selectedApartment} 
          onClose={() => setSelectedApartment(null)}
          onPaymentSuccess={fetchReportData}
        />
      )}
    </div>
  );
};

export default GeneratorSubscriptionReport;
