import React, { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import PrintLogo from '../components/PrintLogo';
import { Activity, Search, Calendar, Filter, FileText, Package, RotateCcw, DollarSign } from 'lucide-react';
import { ReturnModal } from './SalesModals';
import SalesSummary from './SalesSummary';
import CashierSummary from './CashierSummary';
import Returns from './Returns';

const SalesHistory = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [dateRange, setDateRange] = useState({ start_date: new Date().toISOString().split('T')[0], end_date: new Date().toISOString().split('T')[0] });
  const [customerType, setCustomerType] = useState('All');
  const [selectedInvoice, setSelectedInvoice] = useState(null);
  const [activeTab, setActiveTab] = useState('overview'); // overview | products
  const [returningItem, setReturningItem] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');

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

  const { data: purchasedProducts = [], isLoading: productsLoading } = useQuery({
    queryKey: ['purchasedProducts', dateRange.start_date, dateRange.end_date, customerType],
    queryFn: async () => {
      const res = await axios.get(`/sales/purchased-products?start_date=${dateRange.start_date}&end_date=${dateRange.end_date}&customer_type=${customerType}`);
      return res.data;
    },
    enabled: activeTab === 'products'
  });

  const handleReturnItem = (product) => {
    const fakeInvoice = {
      id: product.invoice_id,
      invoice_number: product.invoice_number,
      items: [{
        ...product,
        product_id: product.product_id,
        quantity: product.quantity,
        returned_qty: product.returned_qty,
        price: product.price,
        total_price: product.total_price
      }]
    };
    setReturningItem(fakeInvoice);
  };



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

  const filteredSales = sales?.filter(s => 
    s.invoice_number?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    (s.customer_name || '').toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  const filteredProducts = purchasedProducts?.filter(p => 
    p.invoice_number?.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.product_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.customer_name || '').toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  return (
    <>
      {/* Print Templates */}
      {selectedInvoice ? (
        <div className="hidden print:block p-8 font-mono text-black">
          <div className="text-center mb-6 border-b-2 border-black pb-4">
            <PrintLogo />
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
                  <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Category</th>
                  <th className="py-2 px-3 text-sm font-bold text-black text-right">Amount</th>
                </tr>
              </thead>
              <tbody>
                {(() => {
                  const totals = {
                    'Walk-In': 0,
                    'Building': 0,
                    'Apartment': 0,
                    'Construction': 0,
                    'GrossTotal': 0,
                    'Returns': 0,
                    'NetTotal': 0
                  };
                  sales?.forEach(sale => {
                    const amount = parseFloat(sale.final_amount || 0);
                    const returns = parseFloat(sale.returned_amount || 0);
                    
                    if (totals[sale.customer_type] !== undefined) {
                      totals[sale.customer_type] += amount;
                    } else if (sale.customer_type === 'Walk-In Customer' || sale.customer_type === 'Walk-In') {
                      totals['Walk-In'] += amount;
                    }
                    totals['GrossTotal'] += amount;
                    totals['Returns'] += returns;
                    totals['NetTotal'] += (amount - returns);
                  });
                  return (
                    <>
                      <tr className="border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-medium text-sm text-black">Walk-In (Cash)</td>
                        <td className="py-2 px-3 text-right text-sm text-black font-medium">CFA {totals['Walk-In'].toLocaleString()}</td>
                      </tr>
                      <tr className="border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-medium text-sm text-black">Apartments</td>
                        <td className="py-2 px-3 text-right text-sm text-black font-medium">CFA {totals['Apartment'].toLocaleString()}</td>
                      </tr>
                      <tr className="border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-medium text-sm text-black">Buildings</td>
                        <td className="py-2 px-3 text-right text-sm text-black font-medium">CFA {totals['Building'].toLocaleString()}</td>
                      </tr>
                      <tr className="border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-medium text-sm text-black">Construction</td>
                        <td className="py-2 px-3 text-right text-sm text-black font-medium">CFA {totals['Construction'].toLocaleString()}</td>
                      </tr>
                      <tr className="border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-bold text-sm text-black">Gross Sales</td>
                        <td className="py-2 px-3 text-right font-bold text-sm text-black">CFA {totals['GrossTotal'].toLocaleString()}</td>
                      </tr>
                      <tr className="border-b border-gray-300 bg-red-50">
                        <td className="py-2 px-3 border-r border-gray-300 font-bold text-red-600 text-sm">Returns</td>
                        <td className="py-2 px-3 font-bold text-red-600 text-right text-sm">- CFA {totals['Returns'].toLocaleString()}</td>
                      </tr>
                      <tr className="bg-gray-100 border-b border-gray-300">
                        <td className="py-2 px-3 border-r border-gray-300 font-bold text-black uppercase text-sm">Net Total</td>
                        <td className="py-2 px-3 font-bold text-black text-right text-base">CFA {totals['NetTotal'].toLocaleString()}</td>
                      </tr>
                    </>
                  );
                })()}
              </tbody>
            </table>
          </div>
        </div>
      )}

      <div className="flex flex-col h-full bg-background print:hidden">
        {/* Top Navigation Tabs */}
        <div className="px-8 pt-6 pb-0 border-b border-slate-800 bg-slate-900/30">
          <div className="flex space-x-1">
            <button 
              onClick={() => setActiveTab('overview')} 
              className={`px-6 py-3 rounded-t-lg text-sm font-bold transition-all flex items-center gap-2 border-b-2 ${activeTab === 'overview' ? 'bg-slate-800 border-primary text-white' : 'border-transparent text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
            >
              <FileText size={16}/> Sales Overview
            </button>
            <button 
              onClick={() => setActiveTab('products')} 
              className={`px-6 py-3 rounded-t-lg text-sm font-bold transition-all flex items-center gap-2 border-b-2 ${activeTab === 'products' ? 'bg-slate-800 border-primary text-white' : 'border-transparent text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
            >
              <Package size={16}/> Purchased Products
            </button>
            <button 
              onClick={() => setActiveTab('sales_summary')} 
              className={`px-6 py-3 rounded-t-lg text-sm font-bold transition-all flex items-center gap-2 border-b-2 ${activeTab === 'sales_summary' ? 'bg-slate-800 border-primary text-white' : 'border-transparent text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
            >
              <Activity size={16}/> Sales Summary
            </button>
            <button 
              onClick={() => setActiveTab('cashier_summary')} 
              className={`px-6 py-3 rounded-t-lg text-sm font-bold transition-all flex items-center gap-2 border-b-2 ${activeTab === 'cashier_summary' ? 'bg-slate-800 border-primary text-white' : 'border-transparent text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
            >
              <DollarSign size={16}/> Cashier Summary
            </button>
            <button 
              onClick={() => setActiveTab('returns')} 
              className={`px-6 py-3 rounded-t-lg text-sm font-bold transition-all flex items-center gap-2 border-b-2 ${activeTab === 'returns' ? 'bg-slate-800 border-primary text-white' : 'border-transparent text-slate-400 hover:text-white hover:bg-slate-800/50'}`}
            >
              <RotateCcw size={16}/> Returns
            </button>
          </div>
        </div>

        {/* Main Content Area */}
        <div className="flex-1 overflow-y-auto hide-scrollbar relative">
          {(activeTab === 'overview' || activeTab === 'products') ? (
            <div className="p-8">
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
            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg px-3 py-1 border border-slate-700 flex-1 min-w-[200px]">
              <Search size={16} className="text-muted" />
              <input 
                type="text" 
                placeholder="Search invoices or products..." 
                value={searchTerm} 
                onChange={e => setSearchTerm(e.target.value)} 
                className="bg-transparent text-white text-sm outline-none w-full" 
              />
            </div>
          </div>



          {activeTab === 'overview' ? (() => {
            const totalAmount = filteredSales?.reduce((sum, sale) => sum + parseFloat(sale.final_amount || 0), 0) || 0;
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
                   <tr><td colSpan="7" className="p-8 text-center text-muted">Loading sales...</td></tr>
                ) : filteredSales.length > 0 ? filteredSales.map((sale) => (
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
                    <td className="p-4 text-sm font-bold text-end">
                      <div className="text-success">{t('common.currency')} {parseFloat(sale.final_amount).toLocaleString()}</div>
                      {Number(sale.returned_amount) > 0 && (
                        <div className="text-xs text-danger mt-1 font-normal">- {t('common.currency')} {Number(sale.returned_amount).toLocaleString()}</div>
                      )}
                    </td>
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
          );})() : (() => {
            const totalProductValue = filteredProducts?.reduce((sum, p) => sum + parseFloat(p.total_price || 0), 0) || 0;
            return (
              <div className="glass-card overflow-hidden">
                <table className="w-full text-start border-collapse">
                  <thead>
                    <tr className="border-b border-slate-700/50 bg-slate-800/30">
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-start">Date</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-start">Invoice #</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-start">Product</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-start">Customer</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-center">Qty</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-center">Returned</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-end">Total</th>
                      <th className="p-4 text-xs font-semibold text-muted uppercase text-center">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {productsLoading ? (
                       <tr><td colSpan="8" className="p-8 text-center text-muted">Loading products...</td></tr>
                    ) : filteredProducts.length > 0 ? filteredProducts.map((p) => {
                      const availableQty = p.quantity - (p.returned_qty || 0);
                      return (
                        <tr key={p.id} className="hover:bg-slate-800/30 transition-colors">
                          <td className="p-4 text-sm text-slate-300">{p.invoice_date}</td>
                          <td className="p-4 text-sm text-indigo-300 font-medium">{p.invoice_number}</td>
                          <td className="p-4 text-sm text-white font-medium">{p.product_name}</td>
                          <td className="p-4 text-sm text-slate-300">{p.customer_name || p.customer_type}</td>
                          <td className="p-4 text-sm text-center font-bold text-white">{p.quantity}</td>
                          <td className="p-4 text-sm text-center font-bold text-warning">{p.returned_qty || 0}</td>
                          <td className="p-4 text-sm font-bold text-end text-success">{t('common.currency')} {parseFloat(p.total_price).toLocaleString()}</td>
                          <td className="p-4 text-sm text-center">
                            {availableQty > 0 ? (
                              <button 
                                onClick={() => handleReturnItem(p)} 
                                className="text-warning hover:text-white px-3 py-1 bg-warning/10 hover:bg-warning/30 rounded transition-colors flex items-center justify-center gap-1 mx-auto"
                                title="Return Item"
                              >
                                <RotateCcw size={14} /> Return
                              </button>
                            ) : (
                              <span className="text-xs text-slate-500 bg-slate-800 px-2 py-1 rounded">Returned</span>
                            )}
                          </td>
                        </tr>
                      );
                    }) : (
                      <tr>
                        <td colSpan="8" className="p-8 text-center text-muted">No products found</td>
                      </tr>
                    )}
                  </tbody>
                  <tfoot>
                    <tr className="border-t-2 border-slate-700 bg-slate-800/50">
                      <td colSpan="6" className="p-4 text-sm font-bold text-end text-white uppercase">{t('sales.col_total') || 'Total'}:</td>
                      <td className="p-4 text-sm font-bold text-end text-success">{t('common.currency')} {totalProductValue.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</td>
                      <td></td>
                    </tr>
                  </tfoot>
                </table>
              </div>
            );
          })()}
            </div>
          ) : activeTab === 'sales_summary' ? (
            <SalesSummary />
          ) : activeTab === 'cashier_summary' ? (
            <CashierSummary />
          ) : activeTab === 'returns' ? (
            <Returns />
          ) : null}
        </div>
      </div>
    {returningItem && <ReturnModal invoice={returningItem} onClose={() => setReturningItem(null)} onSave={() => { queryClient.invalidateQueries(['purchasedProducts']); queryClient.invalidateQueries(['sales']); setReturningItem(null); }} />}
    </>
  );
};

export default SalesHistory;
