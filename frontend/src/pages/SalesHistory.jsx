import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Activity, Search, Calendar, Filter, FileText } from 'lucide-react';

const SalesHistory = () => {
  const { t } = useTranslation();
  const [dateRange, setDateRange] = useState({ start_date: new Date().toISOString().split('T')[0], end_date: new Date().toISOString().split('T')[0] });
  const [customerType, setCustomerType] = useState('All');
  const [selectedInvoice, setSelectedInvoice] = useState(null);

  const handlePrint = (sale) => {
    setSelectedInvoice(sale);
    setTimeout(() => {
      window.print();
    }, 200);
  };

  const { data: sales = [], isLoading: salesLoading } = useQuery({
    queryKey: ['sales', dateRange.start_date, dateRange.end_date, customerType],
    queryFn: async () => {
      const res = await axios.get(`/sales?start_date=${dateRange.start_date}&end_date=${dateRange.end_date}&customer_type=${customerType}`);
      return res.data;
    }
  });

  const { data: dashboard = null, isLoading: dashLoading } = useQuery({
    queryKey: ['salesDashboard'],
    queryFn: async () => {
      const res = await axios.get('/sales/dashboard');
      return res.data;
    }
  });

  const customerTypes = ['All', 'Walk-In', 'Building', 'Apartment', 'Construction'];

  // Quick Date Filters
  const setQuickDate = (daysAgo) => {
    const end = new Date();
    const start = new Date();
    start.setDate(start.getDate() - daysAgo);
    setDateRange({ start_date: start.toISOString().split('T')[0], end_date: end.toISOString().split('T')[0] });
  };

  const setToday = () => setQuickDate(0);
  const setYesterday = () => {
    const yest = new Date();
    yest.setDate(yest.getDate() - 1);
    const dateStr = yest.toISOString().split('T')[0];
    setDateRange({ start_date: dateStr, end_date: dateStr });
  };

  return (
    <>
      {/* Print Templates */}
      {selectedInvoice ? (
        <div className="hidden print:block p-8 font-mono text-black">
          <div className="text-center mb-6 border-b-2 border-black pb-4">
            <h1 className="text-3xl font-bold mb-2">INVOICE / RECEIPT</h1>
            <p className="text-sm">Bitar Group Ltd</p>
            <p className="text-sm">Central Africa</p>
          </div>
          <div className="mb-6 flex justify-between">
            <div>
              <p><strong>Invoice #:</strong> {selectedInvoice.invoice_number}</p>
              <p><strong>Date:</strong> {selectedInvoice.date}</p>
            </div>
            <div className="text-right">
              <p><strong>Target:</strong> {selectedInvoice.customer_type}</p>
              <p><strong>Client / Entity:</strong> {selectedInvoice.customer_name || 'Walk-In Customer'}</p>
            </div>
          </div>
          <table className="w-full text-left border-collapse mb-6">
            <thead>
              <tr className="border-b border-black">
                <th className="py-2">Item Description</th>
                <th className="py-2 text-center">Qty</th>
                <th className="py-2 text-right">Unit Price</th>
                <th className="py-2 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {selectedInvoice.items && selectedInvoice.items.map((item, idx) => (
                <tr key={idx} className="border-b border-gray-300">
                  <td className="py-2">{item.product_name}</td>
                  <td className="py-2 text-center">{item.quantity}</td>
                  <td className="py-2 text-right">CFA {Number(item.total_price / item.quantity).toLocaleString()}</td>
                  <td className="py-2 text-right">CFA {Number(item.total_price).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="text-right border-t-2 border-black pt-4">
            <h2 className="text-xl font-bold">TOTAL: CFA {parseFloat(selectedInvoice.final_amount).toLocaleString()}</h2>
          </div>
          <div className="mt-12 text-center text-xs text-gray-500">
            <p>Thank you for your business!</p>
          </div>
        </div>
      ) : (
        <div className="hidden print:block w-full text-black">
          <div className="mb-8 border-b-2 border-black pb-4">
            <h2 className="text-3xl font-bold mb-1">Sales Report</h2>
            <p className="text-gray-700">Reporting Period: <span className="font-bold">{dateRange.start_date}</span> to <span className="font-bold">{dateRange.end_date}</span></p>
          </div>

          <div className="mb-8">
            <h3 className="text-xl font-bold mb-3 border-b border-gray-300 pb-2">Category Summary</h3>
            <table className="w-full text-left border-collapse border border-gray-300">
              <thead>
                <tr className="bg-gray-100 border-b border-gray-300">
                  <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Walk-In (Cash)</th>
                  <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Apartments</th>
                  <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Buildings</th>
                  <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Construction</th>
                  <th className="py-2 px-3 text-sm font-bold text-black bg-gray-200 text-right">Total</th>
                </tr>
              </thead>
              <tbody>
                {(() => {
                  const totals = {
                    'Walk-In': 0,
                    'Building': 0,
                    'Apartment': 0,
                    'Construction': 0,
                    'Total': 0
                  };
                  sales?.forEach(sale => {
                    const amount = parseFloat(sale.final_amount || 0);
                    if (totals[sale.customer_type] !== undefined) {
                      totals[sale.customer_type] += amount;
                    } else if (sale.customer_type === 'Walk-In Customer') {
                      totals['Walk-In'] += amount;
                    }
                    totals['Total'] += amount;
                  });
                  return (
                    <tr>
                      <td className="py-2 px-3 border-r border-gray-300">CFA {totals['Walk-In'].toLocaleString()}</td>
                      <td className="py-2 px-3 border-r border-gray-300">CFA {totals['Apartment'].toLocaleString()}</td>
                      <td className="py-2 px-3 border-r border-gray-300">CFA {totals['Building'].toLocaleString()}</td>
                      <td className="py-2 px-3 border-r border-gray-300">CFA {totals['Construction'].toLocaleString()}</td>
                      <td className="py-2 px-3 font-bold bg-gray-100 text-right">CFA {totals['Total'].toLocaleString()}</td>
                    </tr>
                  );
                })()}
              </tbody>
            </table>
          </div>

          <h3 className="text-xl font-bold mb-3 border-b border-gray-300 pb-2 mt-8">Detailed Transactions</h3>
          <table className="w-full text-left border-collapse border border-gray-300">
            <thead>
              <tr className="bg-gray-100 border-b border-gray-300">
                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Invoice #</th>
                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Date</th>
                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Type</th>
                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Customer / Entity</th>
                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Items</th>
                <th className="py-2 px-3 text-sm font-bold text-black bg-gray-200 text-right">Total</th>
              </tr>
            </thead>
            <tbody>
              {sales?.map((sale) => (
                <tr key={sale.id} className="border-b border-gray-300">
                  <td className="py-2 px-3 border-r border-gray-300 text-sm">{sale.invoice_number}</td>
                  <td className="py-2 px-3 border-r border-gray-300 text-sm">{sale.date}</td>
                  <td className="py-2 px-3 border-r border-gray-300 text-sm">{sale.customer_type === 'Walk-In' ? 'Walk-In' : sale.customer_type}</td>
                  <td className="py-2 px-3 border-r border-gray-300 text-sm font-medium">{sale.customer_name || 'Walk-In Customer'}</td>
                  <td className="py-2 px-3 border-r border-gray-300 text-sm">{sale.items?.length || 0}</td>
                  <td className="py-2 px-3 text-sm font-bold text-right bg-gray-50">CFA {parseFloat(sale.final_amount).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <div className="flex flex-col xl:flex-row h-full bg-background print:hidden">
        {/* Main Content */}
        <div className="flex-1 flex flex-col h-full overflow-hidden">
          <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
          <div className="flex justify-between items-end mb-8">
            <div>
              <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
                <Activity className="me-3 text-success" size={32} /> {t('sales.title')}
              </h1>
              <p className="text-muted">{t('sales.subtitle')}</p>
            </div>
            
            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg p-1 border border-slate-700">
              <button onClick={setToday} className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors text-slate-400 hover:text-white hover:bg-slate-700">{t('sales.filter_today')}</button>
              <button onClick={setYesterday} className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors text-slate-400 hover:text-white hover:bg-slate-700">{t('sales.filter_yesterday')}</button>
              <button onClick={() => setQuickDate(7)} className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors text-slate-400 hover:text-white hover:bg-slate-700">{t('sales.filter_7days')}</button>
              <button onClick={() => setQuickDate(30)} className="px-3 py-1.5 rounded-md text-sm font-medium transition-colors text-slate-400 hover:text-white hover:bg-slate-700">{t('sales.filter_30days')}</button>
              <button onClick={() => { setSelectedInvoice(null); setTimeout(() => window.print(), 200); }} className="px-3 py-1.5 rounded-md text-sm font-bold transition-colors text-white bg-indigo-500 hover:bg-indigo-600 ml-4 flex items-center gap-2">
                <FileText size={16} /> Print Report
              </button>
            </div>
          </div>

          <div className="flex flex-wrap gap-4 mb-6">
            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg p-1 border border-slate-700">
              {customerTypes.map(cat => (
                <button
                  key={cat}
                  onClick={() => setCustomerType(cat)}
                  className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${customerType === cat ? 'bg-success text-white' : 'text-slate-400 hover:text-white'}`}
                >
                  {cat}
                </button>
              ))}
            </div>
            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg px-3 py-1 border border-slate-700">
              <Calendar size={16} className="text-muted" />
              <input type="date" value={dateRange.start_date} onChange={e => setDateRange({...dateRange, start_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
              <span className="text-muted">{t('sales.filter_to')}</span>
              <input type="date" value={dateRange.end_date} onChange={e => setDateRange({...dateRange, end_date: e.target.value})} className="bg-transparent text-white text-sm outline-none" style={{ colorScheme: 'dark' }} />
            </div>
          </div>

          {(() => {
            const totalAmount = sales?.reduce((sum, sale) => sum + parseFloat(sale.final_amount || 0), 0) || 0;
            return (
          <div className="glass-card overflow-hidden">
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="border-b border-slate-700/50 bg-slate-800/30">
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-start">{t('sales.col_invoice')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-start">{t('sales.col_date')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-start">{t('sales.col_type')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-start">{t('sales.col_customer')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-start">{t('sales.col_items')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-end">{t('sales.col_total')}</th>
                  <th className="p-4 text-xs font-semibold text-muted uppercase text-center">{t('sales.col_action')}</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {salesLoading ? (
                   <tr><td colSpan="6" className="p-8 text-center text-muted">Loading sales...</td></tr>
                ) : sales.length > 0 ? sales.map((sale) => (
                  <tr key={sale.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="p-4 text-sm text-indigo-300 font-medium">
                      <div className="flex items-center">
                        <FileText size={14} className="me-2 opacity-50" />
                        {sale.invoice_number}
                      </div>
                    </td>
                    <td className="p-4 text-sm text-slate-300">{sale.date}</td>
                    <td className="p-4 text-sm text-slate-300">
                      <span className={`px-2 py-1 rounded text-xs border ${
                        sale.customer_type === 'Walk-In' ? 'bg-slate-800 border-slate-700' : 'bg-primary/20 border-primary/30 text-primary'
                      }`}>
                        {sale.customer_type === 'Walk-In' ? t('sales.walk_in') : sale.customer_type}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-white font-medium">{sale.customer_name || t('sales.walk_in')}</td>
                    <td className="p-4 text-sm text-slate-400">
                      {sale.items?.length || 0} {t('sales.items_count')}
                    </td>
                    <td className="p-4 text-sm text-success font-bold text-end">{t('common.currency')} {parseFloat(sale.final_amount).toLocaleString()}</td>
                    <td className="p-4 text-sm text-center">
                      <button 
                        onClick={() => handlePrint(sale)} 
                        className="text-indigo-400 hover:text-white px-3 py-1 bg-indigo-500/10 hover:bg-indigo-500/30 rounded transition-colors"
                      >
                        {t('sales.btn_print')}
                      </button>
                    </td>
                  </tr>
                )) : (
                  <tr>
                    <td colSpan="7" className="p-8 text-center text-muted">{t('sales.no_data') || 'No sales found'}</td>
                  </tr>
                )}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-slate-700 bg-slate-800/50">
                  <td colSpan="5" className="p-4 text-sm font-bold text-end text-white uppercase">{t('sales.col_total') || 'Total'}:</td>
                  <td className="p-4 text-sm font-bold text-end text-success">{t('common.currency')} {totalAmount.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                  <td></td>
                </tr>
              </tfoot>
            </table>
          </div>
          );})()}
        </div>
      </div>

      {/* Right Dashboard */}
      <div className="w-full xl:w-80 glass-panel p-6 overflow-y-auto z-10 shrink-0 border-t xl:border-t-0 xl:border-s border-slate-800">
        <h2 className="text-xl font-bold text-white mb-6">{t('sales.dash_title')}</h2>
        {dashLoading ? (
          <div className="animate-pulse flex space-x-4"><div className="flex-1 space-y-6 py-1"><div className="h-2 bg-slate-700 rounded"></div><div className="space-y-3"><div className="grid grid-cols-3 gap-4"><div className="h-2 bg-slate-700 rounded col-span-2"></div><div className="h-2 bg-slate-700 rounded col-span-1"></div></div></div></div></div>
        ) : dashboard && (
          <div className="space-y-6">
            <div className="p-5 glass-card relative overflow-hidden border-success/30">
              <div className="absolute top-0 right-0 w-24 h-24 bg-success/10 blur-2xl rounded-full"></div>
              <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-2">{t('sales.dash_total')}</h3>
              <div className="text-3xl font-bold text-white">{t('common.currency')} {parseFloat(dashboard['Total']).toLocaleString()}</div>
            </div>

            <div className="p-5 glass-card">
              <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('sales.dash_breakdown')}</h3>
              <div className="space-y-4">
                <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                  <span className="text-slate-300">Construction</span>
                  <span className="text-white font-medium">{t('common.currency')} {parseFloat(dashboard['Construction']).toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                  <span className="text-slate-300">Apartments</span>
                  <span className="text-white font-medium">{t('common.currency')} {parseFloat(dashboard['Apartment']).toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center border-b border-slate-700/50 pb-2">
                  <span className="text-slate-300">Buildings</span>
                  <span className="text-white font-medium">{t('common.currency')} {parseFloat(dashboard['Building']).toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center pt-3 border-t-2 border-slate-700 mt-2">
                  <span className="text-success font-bold flex items-center gap-2">
                    Walk-In (Actual Cash)
                  </span>
                  <span className="text-success font-bold text-lg">{t('common.currency')} {parseFloat(dashboard['Walk-In'] || 0).toLocaleString()}</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
    </>
  );
};

export default SalesHistory;
