import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../api/axios';
import { FileText, Search, Calendar, Building, Home, DollarSign } from 'lucide-react';
import { format } from 'date-fns';
import { Printer } from 'lucide-react';

const ApartmentCostReport = () => {
  const { t, i18n } = useTranslation();
  
  const [dateRange, setDateRange] = useState('month'); // 'day', 'month', 'custom'
  const [startDate, setStartDate] = useState(format(new Date(new Date().getFullYear(), new Date().getMonth(), 1), 'yyyy-MM-dd'));
  const [endDate, setEndDate] = useState(format(new Date(new Date().getFullYear(), new Date().getMonth() + 1, 0), 'yyyy-MM-dd'));
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedBuildingId, setSelectedBuildingId] = useState('');
  const [selectedApartmentId, setSelectedApartmentId] = useState('');
  const [printLayout, setPrintLayout] = useState(null);

  React.useEffect(() => {
    const handleAfterPrint = () => setPrintLayout(null);
    window.addEventListener('afterprint', handleAfterPrint);
    return () => window.removeEventListener('afterprint', handleAfterPrint);
  }, []);
  
  const handleDateRangeChange = (e) => {
    const range = e.target.value;
    setDateRange(range);
    const today = new Date();
    
    if (range === 'day') {
      setStartDate(format(today, 'yyyy-MM-dd'));
      setEndDate(format(today, 'yyyy-MM-dd'));
    } else if (range === 'month') {
      setStartDate(format(new Date(today.getFullYear(), today.getMonth(), 1), 'yyyy-MM-dd'));
      setEndDate(format(new Date(today.getFullYear(), today.getMonth() + 1, 0), 'yyyy-MM-dd'));
    }
  };

  const { data: costs, isLoading } = useQuery({
    queryKey: ['apartmentCostsReport', startDate, endDate, searchTerm],
    queryFn: async () => {
      const res = await api.get('/apartment-costs/report', {
        params: { start_date: startDate, end_date: endDate, search: searchTerm }
      });
      return res.data;
    }
  });

  const { data: buildings = [] } = useQuery({
    queryKey: ['buildings'],
    queryFn: async () => (await api.get('/buildings')).data
  });

  const { data: apartments = [] } = useQuery({
    queryKey: ['apartments'],
    queryFn: async () => (await api.get('/apartments')).data
  });

  const filteredCosts = costs?.filter(cost => {
    if (selectedBuildingId && cost.building_id != selectedBuildingId && cost.building_name !== buildings.find(b => b.id == selectedBuildingId)?.name) {
      return false;
    }
    if (selectedApartmentId && cost.apartment_id != selectedApartmentId && cost.apartment_code !== apartments.find(a => a.id == selectedApartmentId)?.code) {
      return false;
    }
    return true;
  }) || [];

  const totalDeployments = filteredCosts.reduce((sum, cost) => sum + parseFloat(cost.amount || 0), 0) || 0;

  const handlePrint = (layout) => {
    setPrintLayout(layout);
    setTimeout(() => {
      window.print();
    }, 100);
  };

  const selectedApartmentData = apartments.find(a => a.id == selectedApartmentId);
  const selectedBuildingData = buildings.find(b => b.id == (selectedApartmentData?.building_id || selectedBuildingId));

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="print:hidden">
        <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
        <div>
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <FileText className="text-primary" size={32} />
            {t('sidebar.apartment_cost_report', 'Apartment Cost Report')}
          </h1>
          <p className="text-muted mt-2">
            View all apartment cost deployments across your buildings.
          </p>
        </div>
        
        <div className="flex gap-4 items-center">
          {selectedApartmentId && (
            <div className="flex gap-2">
              <button 
                onClick={() => handlePrint('a4')}
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-3 rounded-xl flex items-center gap-2 transition-colors shadow-lg"
              >
                <Printer size={20} />
                Print A4
              </button>
              <button 
                onClick={() => handlePrint('receipt')}
                className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-3 rounded-xl flex items-center gap-2 transition-colors shadow-lg border border-slate-600"
              >
                <Printer size={20} />
                Print Receipt
              </button>
            </div>
          )}
          <div className="glass-card p-4 rounded-xl flex items-center gap-4 border border-slate-700/50">
             <div className="flex flex-col">
               <span className="text-xs text-muted font-medium mb-1">
                 {selectedApartmentId ? 'Apartment Total' : selectedBuildingId ? 'Building Total' : 'Total Deployments'}
               </span>
               <span className="text-2xl font-bold text-success flex items-center">
                 <DollarSign size={20} className="mr-1" />
                 {totalDeployments.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
               </span>
             </div>
          </div>
        </div>
      </div>

      <div className="glass-card p-6 mb-8 rounded-xl border border-slate-700/50 flex flex-wrap gap-4 items-end">
        <div className="flex-1 min-w-[200px]">
          <label className="block text-sm font-medium text-muted mb-2">Search</label>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search apartment or building..."
              className="w-full bg-slate-800/50 border border-slate-700 text-white rounded-lg pl-10 pr-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-muted mb-2">Filter By</label>
          <select 
            value={dateRange}
            onChange={handleDateRangeChange}
            className="bg-slate-800/50 border border-slate-700 text-white rounded-lg px-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors"
          >
            <option value="day">Daily</option>
            <option value="month">Monthly</option>
            <option value="custom">Custom Range</option>
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-muted mb-2">Start Date</label>
          <div className="relative">
            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
            <input
              type="date"
              value={startDate}
              onChange={(e) => { setStartDate(e.target.value); setDateRange('custom'); }}
              className="bg-slate-800/50 border border-slate-700 text-white rounded-lg pl-10 pr-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors"
            />
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-muted mb-2">End Date</label>
          <div className="relative">
            <Calendar className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
            <input
              type="date"
              value={endDate}
              onChange={(e) => { setEndDate(e.target.value); setDateRange('custom'); }}
              className="bg-slate-800/50 border border-slate-700 text-white rounded-lg pl-10 pr-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors"
            />
          </div>
        </div>
        
        <div>
          <label className="block text-sm font-medium text-muted mb-2">Building</label>
          <select 
            value={selectedBuildingId}
            onChange={(e) => { setSelectedBuildingId(e.target.value); setSelectedApartmentId(''); }}
            className="bg-slate-800/50 border border-slate-700 text-white rounded-lg px-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors"
          >
            <option value="">All Buildings</option>
            {buildings.map(b => (
              <option key={b.id} value={b.id}>{b.name}</option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-sm font-medium text-muted mb-2">Apartment</label>
          <select 
            value={selectedApartmentId}
            onChange={(e) => setSelectedApartmentId(e.target.value)}
            disabled={!selectedBuildingId}
            className="bg-slate-800/50 border border-slate-700 text-white rounded-lg px-4 py-2 focus:ring-2 focus:ring-primary focus:outline-none transition-colors disabled:opacity-50"
          >
            <option value="">All Apartments</option>
            {apartments.filter(a => a.building_id == selectedBuildingId).map(a => (
              <option key={a.id} value={a.id}>Apt {a.code}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="glass-card rounded-xl border border-slate-700/50 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-slate-800/50 border-b border-slate-700/50 text-slate-300">
                <th className="p-4 font-medium">Date</th>
                <th className="p-4 font-medium">Building</th>
                <th className="p-4 font-medium">Apartment</th>
                <th className="p-4 font-medium">Supplier / Source</th>
                <th className="p-4 font-medium">Notes</th>
                <th className="p-4 font-medium text-right">Deployment Cost</th>
                <th className="p-4 font-medium text-center">Receipt</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {isLoading ? (
                <tr>
                  <td colSpan="7" className="p-8 text-center text-muted">
                    <div className="animate-pulse flex flex-col items-center">
                      <div className="h-8 w-8 border-4 border-primary border-t-transparent rounded-full animate-spin mb-4"></div>
                      Loading deployments...
                    </div>
                  </td>
                </tr>
              ) : filteredCosts.length === 0 ? (
                <tr>
                  <td colSpan="7" className="p-12 text-center">
                    <FileText size={48} className="mx-auto text-slate-600 mb-4" />
                    <p className="text-muted text-lg">No cost deployments found for this period.</p>
                  </td>
                </tr>
              ) : (
                filteredCosts.map((cost) => (
                  <tr key={cost.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="p-4 text-white">
                      {format(new Date(cost.date), 'dd MMM yyyy')}
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2 text-white">
                        <Building size={16} className="text-primary" />
                        {cost.building_name}
                      </div>
                    </td>
                    <td className="p-4">
                      <div className="flex items-center gap-2 text-white">
                        <Home size={16} className="text-indigo-400" />
                        {cost.apartment_code}
                      </div>
                    </td>
                    <td className="p-4 text-slate-300">
                      {cost.supplier_name || '-'}
                    </td>
                    <td className="p-4 text-slate-400 max-w-xs truncate" title={cost.notes}>
                      {cost.notes || '-'}
                    </td>
                    <td className="p-4 text-right">
                      <span className="font-semibold text-danger">
                        ${parseFloat(cost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                      </span>
                    </td>
                    <td className="p-4 text-center">
                      {cost.receipt_image ? (
                        <a 
                          href={`${api.defaults.baseURL.replace('/api', '')}${cost.receipt_image}`} 
                          target="_blank" 
                          rel="noreferrer"
                          className="inline-flex items-center justify-center p-2 bg-indigo-500/10 text-indigo-400 hover:bg-indigo-500/20 rounded-lg transition-colors"
                        >
                          <FileText size={18} />
                        </a>
                      ) : (
                        <span className="text-muted">-</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
      </div>
      
      {/* Invisible Print Layout - A4 */}
      {selectedApartmentData && printLayout === 'a4' && (
        <div className="hidden print:block p-8 bg-white text-black font-sans min-h-screen" dir={document.documentElement.dir}>
          <div className="flex justify-between items-start mb-10 border-b-2 border-slate-200 pb-8">
            <div>
              <h1 className="text-4xl font-bold text-slate-800 mb-2">Apartment Cost Invoice</h1>
              <p className="text-slate-500">Report generated on {format(new Date(), 'MMM dd, yyyy')}</p>
            </div>
            <div className="text-right">
              <h3 className="text-xl font-bold text-slate-800">{selectedBuildingData?.name}</h3>
              <p className="text-lg text-slate-600">Apartment {selectedApartmentData.code}</p>
            </div>
          </div>
          
          <div className="mb-6">
            <h3 className="font-bold text-lg mb-4 text-slate-700 border-b border-slate-200 pb-2">Cost Breakdown ({format(new Date(startDate), 'MMM dd')} - {format(new Date(endDate), 'MMM dd, yyyy')})</h3>
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 text-slate-700">
                  <th className="py-3 px-4 font-semibold border-b border-slate-200">Date</th>
                  <th className="py-3 px-4 font-semibold border-b border-slate-200">Source/Supplier</th>
                  <th className="py-3 px-4 font-semibold border-b border-slate-200">Notes</th>
                  <th className="py-3 px-4 font-semibold text-right border-b border-slate-200">Amount</th>
                </tr>
              </thead>
              <tbody>
                {filteredCosts.map(cost => (
                  <tr key={cost.id} className="border-b border-slate-100">
                    <td className="py-3 px-4">{format(new Date(cost.date), 'dd MMM yyyy')}</td>
                    <td className="py-3 px-4 font-medium">{cost.supplier_name || 'N/A'}</td>
                    <td className="py-3 px-4 text-slate-600 text-sm">{cost.notes || '-'}</td>
                    <td className="py-3 px-4 text-right font-semibold text-slate-800">${parseFloat(cost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}</td>
                  </tr>
                ))}
                {filteredCosts.length === 0 && (
                  <tr>
                    <td colSpan="4" className="py-8 text-center text-slate-500 italic">No costs recorded for this period.</td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
          
          <div className="mt-8 flex justify-end">
            <div className="w-1/3 bg-slate-50 p-6 rounded-xl border border-slate-200">
              <div className="flex justify-between items-center text-xl font-bold text-slate-800">
                <span>Total Costs:</span>
                <span>${totalDeployments.toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
              </div>
            </div>
          </div>
          
          <div className="mt-16 text-center text-sm text-slate-400 border-t border-slate-200 pt-8">
            <p>This is a computer generated document. No signature is required.</p>
          </div>
        </div>
      )}

      {/* Invisible Print Layout - POS Receipt */}
      {selectedApartmentData && printLayout === 'receipt' && (
        <div className="hidden print:block bg-white text-black font-mono text-sm max-w-[80mm] mx-auto p-4" dir="ltr">
          <div className="text-center mb-6">
            <h2 className="text-xl font-bold mb-1 uppercase">COST REPORT</h2>
            <p className="text-xs">Generated: {format(new Date(), 'dd/MM/yyyy HH:mm')}</p>
            <div className="border-b-2 border-dashed border-black my-2"></div>
            <p className="font-bold text-base">{selectedBuildingData?.name}</p>
            <p className="font-bold text-lg">Apt {selectedApartmentData.code}</p>
            <div className="border-b-2 border-dashed border-black my-2"></div>
            <p className="text-xs">From: {format(new Date(startDate), 'dd/MM/yyyy')}</p>
            <p className="text-xs">To: {format(new Date(endDate), 'dd/MM/yyyy')}</p>
            <div className="border-b-2 border-dashed border-black my-2"></div>
          </div>
          
          <div className="mb-4 space-y-3">
            {filteredCosts.map(cost => (
              <div key={cost.id} className="text-xs border-b border-gray-300 pb-2">
                <div className="flex justify-between font-bold">
                  <span>{format(new Date(cost.date), 'dd/MM/yy')}</span>
                  <span>${parseFloat(cost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
                </div>
                <div className="mt-1">
                  <span className="uppercase">{cost.supplier_name || 'N/A'}</span>
                </div>
                {cost.notes && (
                  <div className="text-gray-600 text-[10px] italic mt-1 leading-tight">
                    {cost.notes}
                  </div>
                )}
              </div>
            ))}
            {filteredCosts.length === 0 && (
              <div className="text-center italic py-2">No costs recorded.</div>
            )}
          </div>
          
          <div className="border-t-2 border-black pt-2 mb-8">
            <div className="flex justify-between font-bold text-base uppercase">
              <span>TOTAL</span>
              <span>${totalDeployments.toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
            </div>
          </div>
          
          <div className="text-center text-xs">
            <p>*** END OF REPORT ***</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default ApartmentCostReport;
