import React, { useState, useEffect, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Plus, Search, MapPin, Calendar, Clock, DollarSign, RefreshCw, Printer, User } from 'lucide-react';
import AddCollectionModal from '../../components/agent/AddCollectionModal';
import { useLocation, useNavigate } from 'react-router-dom';

// Mock Debounce Hook for search input
function useDebounce(value, delay) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);
    return () => clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

const AgentCollectionDashboard = () => {
  const location = useLocation();
  const navigate = useNavigate();
  // PRD: Date filter MUST default to current system date upon initial application load
  const [dateFilter, setDateFilter] = useState(() => new Date().toLocaleDateString('en-CA')); // en-CA format is YYYY-MM-DD
  const [searchInput, setSearchInput] = useState('');
  const debouncedSearch = useDebounce(searchInput, 300); // PRD: Debounce threshold of ~300ms
  
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [agentName, setAgentName] = useState('Loading...');
  const [autoFillData, setAutoFillData] = useState(null);

  useEffect(() => {
    if (location.state?.autoFill) {
      // Capture the state payload
      setAutoFillData(location.state);
      setIsModalOpen(true);
      
      // Clear the router state silently without triggering a re-render race condition
      window.history.replaceState({}, document.title);
    }
  }, [location.state]);

  useEffect(() => {
    try {
      const user = JSON.parse(localStorage.getItem('user'));
      if (user && user.name) setAgentName(user.name);
    } catch (e) {
      setAgentName('Agent');
    }
  }, []);

  // PRD: Asynchronous data fetching without blocking main thread
  const { data: collectionsData = [], isLoading, refetch, isRefetching } = useQuery({
    queryKey: ['agent_collections_daily', dateFilter],
    queryFn: async () => {
      try {
        const [rentRes, energyRes] = await Promise.all([
          axios.get('/agent/rent/history').catch(() => ({ data: { data: [] } })),
          axios.get('/energy/agent/subscription-invoices').catch(() => ({ data: { history: [] } }))
        ]);
        
        const rentHistory = (rentRes.data?.data || []).map(item => ({
          id: `rent-${item.id || Math.random()}`,
          type: 'Rent Apartment',
          building_name: item.building_name,
          apartment_number: item.apartment_number,
          tenant_name: item.tenant_name,
          amount: item.amount,
          payment_method: item.payment_method || 'Cash',
          created_at: item.date || item.created_at || new Date().toISOString()
        }));

        const energyHistory = (energyRes.data?.history || []).map(item => ({
          id: `energy-${item.id || Math.random()}`,
          type: 'Electricity Subscription',
          building_name: item.building_name,
          apartment_number: item.apartment_code || item.apartment_number,
          tenant_name: item.tenant_name,
          amount: item.amount,
          payment_method: item.payment_method || 'Cash',
          created_at: item.transaction_date || item.created_at || new Date().toISOString()
        }));

        const unified = [...rentHistory, ...energyHistory].sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

        // Filter by selected date
        return unified.filter(item => {
          const itemDate = new Date(item.created_at).toISOString().split('T')[0];
          return itemDate === dateFilter;
        });
      } catch (e) {
        console.error("Error fetching collections:", e);
        return [];
      }
    }
  });

  // PRD: execute a case-insensitive, multi-index search across tenant names, building identifiers, and specific receipt or apartment numbers
  const filteredCollections = useMemo(() => {
    if (!debouncedSearch) return collectionsData;
    const lowerSearch = debouncedSearch.toLowerCase();
    return collectionsData.filter(item => 
      (item.tenant_name && item.tenant_name.toLowerCase().includes(lowerSearch)) ||
      (item.building_name && item.building_name.toLowerCase().includes(lowerSearch)) ||
      (item.apartment_number && String(item.apartment_number).toLowerCase().includes(lowerSearch)) ||
      (item.id && String(item.id).toLowerCase().includes(lowerSearch))
    );
  }, [debouncedSearch, collectionsData]);

  // PRD: Aggregate summary card continuously and synchronously calculates the sum total
  const totalCollectedToday = useMemo(() => {
    return filteredCollections.reduce((sum, item) => sum + parseFloat(item.amount || 0), 0);
  }, [filteredCollections]);

  // Group collections by apartment for the printed receipt
  const groupedForPrint = useMemo(() => {
    const groups = {};
    filteredCollections.forEach(item => {
      const key = `${item.building_name} - Apt ${item.apartment_number}`;
      if (!groups[key]) {
        groups[key] = {
          apartment: key,
          tenant: item.tenant_name,
          rent: 0,
          subscription: 0,
          insurance: 0,
          total: 0
        };
      }
      
      const amt = parseFloat(item.amount || 0);
      groups[key].total += amt;
      
      if (item.type === 'Rent Apartment') {
        groups[key].rent += amt;
      } else if (item.type === 'Electricity Subscription') {
        groups[key].subscription += amt;
      } else if (item.type === 'Insurance') {
        groups[key].insurance += amt;
      }
    });
    return Object.values(groups).sort((a, b) => a.apartment.localeCompare(b.apartment));
  }, [filteredCollections]);

  // Handle saving new collection from modal
  const handleSaveCollection = (data) => {
    console.log("Saving collection payload to backend:", data);
    // Simulate optimistic UI update
    refetch();
  };

  // PRD: native CSS print spooling via window.print()
  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="min-h-screen bg-[#0F172A] p-4 md:p-8 font-sans">
      
      {/* Header Area (No-Print Area) */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-8 gap-4 no-print">
        <div>
          <h1 className="text-3xl font-bold text-white tracking-tight">Agent Dashboard</h1>
          <p className="text-slate-400 mt-1">Manage daily collections and financial reconciliation.</p>
        </div>
        <div className="flex items-center gap-4 w-full md:w-auto">
          {/* Temporal Filtering Mechanism */}
          <div className="bg-[#1E293B] border border-slate-700 rounded-xl px-4 py-3 flex items-center flex-1 md:flex-none">
            <Calendar size={18} className="text-primary mr-3" />
            <input 
              type="date"
              value={dateFilter}
              onChange={(e) => setDateFilter(e.target.value)}
              className="bg-transparent text-white outline-none w-full font-bold cursor-pointer [color-scheme:dark]"
            />
          </div>
          <button 
            onClick={() => setIsModalOpen(true)}
            className="bg-primary hover:bg-primary/90 text-white px-6 py-3 rounded-xl font-bold flex items-center shadow-lg shadow-primary/20 transition-all hover:scale-105 active:scale-95"
          >
            <Plus size={20} className="mr-2" />
            Add Collection
          </button>
        </div>
      </div>

      {/* Aggregate Summary Card (Screen Only) */}
      <div className="no-print glass-card bg-gradient-to-br from-indigo-900/40 to-slate-900 p-8 rounded-2xl mb-8 border border-indigo-500/30 relative overflow-hidden">
        {/* Decorative background circle */}
        <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 bg-primary/10 rounded-full blur-3xl pointer-events-none"></div>
        
        {/* Screen Layout for Summary Card */}
        <div className="relative z-10 flex flex-col md:flex-row justify-between items-start md:items-end gap-6">
          <div>
            <h2 className="text-indigo-200 text-sm font-bold tracking-widest uppercase mb-1">Daily Collection Ledger</h2>
            <p className="text-slate-400 text-sm mb-6 flex items-center">
              <User size={14} className="mr-1 inline text-slate-500" /> Agent: <span className="text-white ml-1 font-bold">{agentName}</span>
              <span className="mx-3 text-slate-600">•</span>
              <Calendar size={14} className="mr-1 inline text-slate-500" /> Date: <span className="text-white ml-1 font-bold">{new Date(dateFilter).toLocaleDateString()}</span>
            </p>
            <p className="text-sm text-slate-400 mb-1">Total Remittance</p>
            <div className="flex items-baseline">
              <span className="text-5xl font-extrabold text-white tracking-tight">${totalCollectedToday.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
              <span className="text-indigo-400 font-bold ml-2 text-xl">USD</span>
            </div>
          </div>
          <button 
            onClick={handlePrint}
            className="flex items-center bg-white/10 hover:bg-white/20 text-white px-5 py-3 rounded-xl font-bold transition-colors border border-white/10 backdrop-blur-md"
          >
            <Printer size={18} className="mr-2" />
            Print PDF Receipt
          </button>
        </div>
      </div>
        
      {/* Print-Only Layout (THE ONLY PRINT TARGET) */}
      <div className="print-target hidden print-only bg-white text-black w-full text-left p-8">
           <div className="text-center mb-8">
             <h2 className="text-2xl font-bold uppercase tracking-widest border-b-2 border-black inline-block pb-2">Daily Collection Report</h2>
           </div>
           
           <div className="flex justify-between mb-8">
              <div>
                 <p className="font-bold text-lg">Agent: {agentName}</p>
                 <p className="font-bold text-lg">Date: {new Date(dateFilter).toLocaleDateString()}</p>
              </div>
              <div className="text-right">
                 <p className="text-sm font-bold uppercase tracking-wider">Total Remittance</p>
                 <p className="text-3xl font-bold">${totalCollectedToday.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
              </div>
           </div>
           
           <table className="w-full text-left border-collapse mb-8 text-sm">
              <thead>
                <tr>
                  <th className="py-2 border-b-2 border-black">Apartment</th>
                  <th className="py-2 border-b-2 border-black">Tenant</th>
                  <th className="py-2 text-right border-b-2 border-black">Rent</th>
                  <th className="py-2 text-right border-b-2 border-black">Subscription</th>
                  <th className="py-2 text-right border-b-2 border-black">Insurance</th>
                  <th className="py-2 text-right font-bold border-b-2 border-black">Total</th>
                </tr>
              </thead>
              <tbody>
                {groupedForPrint.map((row, idx) => (
                  <tr key={idx} className="border-b border-gray-300">
                    <td className="py-3">{row.apartment}</td>
                    <td className="py-3">{row.tenant || 'N/A'}</td>
                    <td className="py-3 text-right">{row.rent > 0 ? '$' + row.rent.toLocaleString(undefined, {minimumFractionDigits: 2}) : '-'}</td>
                    <td className="py-3 text-right">{row.subscription > 0 ? '$' + row.subscription.toLocaleString(undefined, {minimumFractionDigits: 2}) : '-'}</td>
                    <td className="py-3 text-right">{row.insurance > 0 ? '$' + row.insurance.toLocaleString(undefined, {minimumFractionDigits: 2}) : '-'}</td>
                    <td className="py-3 text-right font-bold">${row.total.toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
                  </tr>
                ))}
                {groupedForPrint.length === 0 && (
                  <tr>
                    <td colSpan="6" className="py-8 text-center italic text-gray-500 border-b border-gray-300">No collections recorded for this date.</td>
                  </tr>
                )}
              </tbody>
           </table>

           <div className="mt-32 pt-8 flex justify-between">
              <div className="w-1/3">
                <div className="border-b border-black mb-2 h-12"></div>
                <p className="text-xs font-bold uppercase tracking-wider text-center">Agent Signature</p>
              </div>
              <div className="w-1/3">
                <div className="border-b border-black mb-2 h-12"></div>
                <p className="text-xs font-bold uppercase tracking-wider text-center">Manager Approval</p>
              </div>
           </div>
      </div>

      {/* Ledger Search & Data Grid (No-Print Area) */}
      <div className="no-print glass-card p-6 rounded-2xl bg-[#1E293B]">
        <div className="flex flex-col md:flex-row justify-between items-center mb-6 gap-4">
          <h3 className="text-xl font-bold text-white flex items-center">
            Ledger Transactions
            {isRefetching && <RefreshCw size={16} className="ml-3 text-primary animate-spin" />}
          </h3>
          <div className="relative w-full md:w-96">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text" 
              placeholder="Search tenant, apt, or ID..." 
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              className="w-full bg-[#0F172A] border border-slate-700 rounded-xl py-3 pl-12 pr-4 text-white focus:outline-none focus:border-primary transition-colors"
            />
          </div>
        </div>

        {isLoading ? (
          <div className="flex justify-center items-center py-20">
            <RefreshCw size={32} className="text-primary animate-spin" />
          </div>
        ) : filteredCollections.length === 0 ? (
          <div className="text-center py-20 border-2 border-dashed border-slate-700 rounded-xl bg-slate-800/30">
            <p className="text-slate-400 font-bold">No collections found matching your filters.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-700/50">
                  <th className="pb-4 text-xs font-bold text-slate-400 uppercase tracking-wider px-4">Time</th>
                  <th className="pb-4 text-xs font-bold text-slate-400 uppercase tracking-wider px-4">Tenant / Property</th>
                  <th className="pb-4 text-xs font-bold text-slate-400 uppercase tracking-wider px-4">Type</th>
                  <th className="pb-4 text-xs font-bold text-slate-400 uppercase tracking-wider px-4">Method</th>
                  <th className="pb-4 text-xs font-bold text-slate-400 uppercase tracking-wider px-4 text-right">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {filteredCollections.map(item => (
                  <tr key={item.id} className="hover:bg-white/5 transition-colors group">
                    <td className="py-4 px-4 whitespace-nowrap">
                      <p className="text-sm text-slate-300 font-medium">
                        {new Date(item.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </p>
                      <p className="text-xs text-slate-500">ID: {item.id}</p>
                    </td>
                    <td className="py-4 px-4">
                      <p className="text-sm font-bold text-white group-hover:text-primary transition-colors">{item.tenant_name}</p>
                      <p className="text-xs text-slate-400 flex items-center mt-1">
                        <MapPin size={10} className="mr-1" /> {item.building_name}, Apt {item.apartment_number}
                      </p>
                    </td>
                    <td className="py-4 px-4 whitespace-nowrap">
                      <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-slate-700 text-slate-300 border border-slate-600">
                        {item.type || 'Rent Apartment'}
                      </span>
                    </td>
                    <td className="py-4 px-4 whitespace-nowrap">
                      <span className={`text-xs font-bold ${item.payment_method === 'QR Code' ? 'text-emerald-400' : 'text-blue-400'}`}>
                        {item.payment_method}
                      </span>
                    </td>
                    <td className="py-4 px-4 text-right whitespace-nowrap">
                      <p className="text-lg font-bold text-white">${parseFloat(item.amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</p>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Multi-Step Collection Wizard */}
      <AddCollectionModal 
        isOpen={isModalOpen} 
        onClose={() => {
          setIsModalOpen(false);
          setAutoFillData(null); // Clear it on close so it doesn't auto-fill again unless re-triggered
        }} 
        onSave={handleSaveCollection}
        autoFillData={autoFillData}
      />
    </div>
  );
};

export default AgentCollectionDashboard;
