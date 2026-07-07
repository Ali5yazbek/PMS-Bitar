import { useTranslation } from 'react-i18next';
import React, { useState, useRef, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { Home, DollarSign, Shield, ArrowLeft, Building, Users, Printer, Calendar, Filter, ChevronDown, Search } from 'lucide-react';

const BuildingDetails = () => {
  const { t } = useTranslation();

  const { id } = useParams();
  const navigate = useNavigate();
  const [dateRange, setDateRange] = useState({ start_date: '', end_date: '' });
  const [targetFilter, setTargetFilter] = useState('All');
  
  // Custom Select State
  const [filterOpen, setFilterOpen] = useState(false);
  const [filterSearch, setFilterSearch] = useState('');
  const filterRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (filterRef.current && !filterRef.current.contains(event.target)) {
        setFilterOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const { data, isLoading } = useQuery({
    queryKey: ['buildingDetails', id],
    queryFn: async () => {
      const res = await api.get(`/buildings/${id}`);
      if (res.data.building) {
        return res.data;
      }
      return { building: res.data, expenses: [], ledger: { total: 0, materials: 0, labor: 0, other: 0 } };
    }
  });

  if (isLoading) return <div className="p-8 text-white">{t('buildingdetails.loading', { defaultValue: `Loading...` })}</div>;

  const building = data?.building;
  const expenses = data?.expenses || [];
  const buildingApartments = data?.apartments || [];
  
  const filterOptions = [
    { value: 'All', label: 'All Costs (Building + Apts)' },
    { value: 'Building Wide', label: 'Building Wide Only' },
    ...buildingApartments.map(a => ({ value: `Apt CFA ${a.code}`, label: `Apt CFA ${a.code}` }))
  ];

  const searchedOptions = filterOptions.filter(opt => opt.label.toLowerCase().includes(filterSearch.toLowerCase()));

  // Filter expenses by date and target
  const filteredExpenses = expenses.filter(exp => {
    if (dateRange.start_date && exp.date < dateRange.start_date) return false;
    if (dateRange.end_date && exp.date > dateRange.end_date) return false;
    
    if (targetFilter !== 'All') {
      if (targetFilter === 'Building Wide' && exp.target_name !== 'Building Wide') return false;
      if (targetFilter !== 'Building Wide' && exp.target_name !== targetFilter) return false;
    }
    
    return true;
  });

  // Dynamically recalculate ledger based on filtered expenses
  const dynamicLedger = {
    total: 0,
    materials: 0,
    labor: 0,
    other: 0
  };

  filteredExpenses.forEach(exp => {
    const amt = parseFloat(exp.amount) || 0;
    dynamicLedger.total += amt;
    if (exp.category === 'Building' || exp.category === 'Apartment' || exp.category === 'Maintenance') {
      dynamicLedger.materials += amt;
    } else if (exp.category === 'Labor') {
      dynamicLedger.labor += amt;
    } else {
      dynamicLedger.other += amt;
    }
  });

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="flex h-full w-full overflow-hidden bg-background print:bg-white print:text-black">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0 print:overflow-visible">
        
        <button 
          onClick={() => navigate('/buildings')}
          className="flex items-center gap-2 text-indigo-400 hover:text-indigo-300 font-medium mb-6 transition-colors print:hidden"
        >
          <ArrowLeft size={20} />
          {t('buildingdetails.back_to_buildings', { defaultValue: `Back to Buildings` })}
        </button>

        {/* Dynamic Print Header */}
        <div className="hidden print:block mb-4 border-b-2 border-black pb-2">
          <h1 className="text-xl font-bold text-black mb-1">{t('buildingdetails.building', { defaultValue: `Building:` })} {building?.name}</h1>
          <h2 className="text-lg font-bold text-slate-700">
            {targetFilter === 'All' ? 'Complete Cost History (All Apartments)' : 
             targetFilter === 'Building Wide' ? 'Building Wide Expenses Only' : 
             `Target: CFA ${targetFilter} Cost History`}
          </h2>
          {dateRange.start_date && dateRange.end_date && (
            <p className="text-xs text-slate-600 mt-1">{t('buildingdetails.period', { defaultValue: `Period:` })} {dateRange.start_date} {t('buildingdetails.to', { defaultValue: `to` })} {dateRange.end_date}</p>
          )}
        </div>

        <div className="glass-card p-8 flex items-center justify-between mb-8 print:hidden">
          <div className="flex items-center gap-6">
            <div className="bg-indigo-500/20 p-6 rounded-full text-indigo-400">
              <Building size={48} />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-white">{building?.name}</h1>
              <p className="text-muted mt-1">{t('buildingdetails.select_an_option_below_to_mana', { defaultValue: `Select an option below to manage this building's resources.` })}</p>
            </div>
          </div>
        </div>

        {/* Management Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12 print:hidden">
          <div 
            onClick={() => navigate(`/apartments?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-blue-400/50 transition-all group"
          >
            <div className="bg-blue-500/10 text-blue-400 p-5 rounded-full mb-4 group-hover:bg-blue-500/20 transition-colors">
              <Home size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.apartments', { defaultValue: `Apartments` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_units_and_statuses', { defaultValue: `Manage units and statuses` })}</p>
          </div>

          <div 
            onClick={() => navigate(`/tenants?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-orange-400/50 transition-all group"
          >
            <div className="bg-orange-500/10 text-orange-400 p-5 rounded-full mb-4 group-hover:bg-orange-500/20 transition-colors">
              <Users size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.tenants', { defaultValue: `Tenants` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_building_residents', { defaultValue: `Manage building residents` })}</p>
          </div>

          <div 
            onClick={() => navigate(`/building-rent?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-green-400/50 transition-all group"
          >
            <div className="bg-green-500/10 text-green-400 p-5 rounded-full mb-4 group-hover:bg-green-500/20 transition-colors">
              <DollarSign size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.rent_management', { defaultValue: `Rent Management` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.track_payments_and_invoices', { defaultValue: `Track payments and invoices` })}</p>
          </div>

          <div 
            onClick={() => navigate(`/building-insurance?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-purple-400/50 transition-all group"
          >
            <div className="bg-purple-500/10 text-purple-400 p-5 rounded-full mb-4 group-hover:bg-purple-500/20 transition-colors">
              <Shield size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.insurance_management', { defaultValue: `Insurance Management` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_deposits_deductions', { defaultValue: `Manage deposits & deductions` })}</p>
          </div>
        </div>

        {/* Quick Tenant Information Cards */}
        <div className="mb-12 print:hidden">
          <h2 className="text-2xl font-bold text-white mb-6">{t('buildingdetails.apartments_tenants', { defaultValue: `Apartments & Tenants` })}</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
            {buildingApartments.map(apt => (
              <div key={apt.id} className="glass-card p-6 border-l-4 border-l-indigo-500">
                <div className="flex justify-between items-start border-b border-slate-700/50 pb-4 mb-4">
                  <div>
                    <h3 className="text-2xl font-bold text-white">{t('buildingdetails.apt', { defaultValue: `Apt` })} {apt.code}</h3>
                    <p className="text-sm text-slate-400">{apt.status}</p>
                  </div>
                  {apt.contract_status && (
                    <span className={`px-2 py-1 text-xs font-semibold rounded-full ${
                      apt.contract_status === 'Approved' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'
                    }`}>
                      {apt.contract_status.replace('_', ' ')}
                    </span>
                  )}
                </div>

                {apt.tenant_id ? (
                  <>
                    <div className="space-y-2 mb-6">
                      <div className="flex items-center text-slate-300">
                        <Users size={16} className="me-2 text-indigo-400" />
                        <span className="font-medium text-white">{apt.tenant_name}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">{t('buildingdetails.rent_due_date', { defaultValue: `Rent Due Date:` })}</span>
                        <span className="text-white">{apt.rent_due_date || 'N/A'}</span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">{t('buildingdetails.balance', { defaultValue: `Balance:` })}</span>
                        <span className={Number(apt.outstanding_balance) > 0 ? 'text-danger font-bold' : 'text-success font-bold'}>
                          {t('buildingdetails.cfa', { defaultValue: `CFA` })} {Number(apt.outstanding_balance).toFixed(2)}
                        </span>
                      </div>
                      <div className="flex justify-between text-sm">
                        <span className="text-slate-400">{t('buildingdetails.contract_ends', { defaultValue: `Contract Ends:` })}</span>
                        <span className="text-white">{apt.contract_end_date || 'N/A'}</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2 mt-auto">
                      <button 
                        onClick={() => navigate(`/tenants/${apt.tenant_id}`)}
                        className="bg-slate-800 hover:bg-slate-700 text-indigo-300 px-3 py-2 rounded-lg text-xs font-medium transition-colors text-center"
                      >
                        {t('buildingdetails.view_profile', { defaultValue: `View Profile` })}
                      </button>
                      <button 
                        onClick={() => navigate(`/building-rent?building=${id}`)}
                        className="bg-slate-800 hover:bg-slate-700 text-green-300 px-3 py-2 rounded-lg text-xs font-medium transition-colors text-center"
                      >
                        {t('buildingdetails.view_payments', { defaultValue: `View Payments` })}
                      </button>
                    </div>
                  </>
                ) : (
                  <div className="text-center py-6">
                    <p className="text-muted italic mb-4">{t('buildingdetails.no_active_tenant', { defaultValue: `No active tenant` })}</p>
                    <button 
                      onClick={() => navigate('/contracts')}
                      className="bg-primary/20 hover:bg-primary/40 text-primary px-4 py-2 rounded-lg text-sm font-medium transition-colors"
                    >
                      {t('buildingdetails.create_rental_contract', { defaultValue: `Create Rental Contract` })}
                    </button>
                  </div>
                )}
              </div>
            ))}
            
            {buildingApartments.length === 0 && (
              <div className="col-span-full p-8 text-center text-muted glass-card">
                {t('buildingdetails.no_apartments_exist_in_this_bu', { defaultValue: `No apartments exist in this building yet.` })}
              </div>
            )}
          </div>
        </div>

        {/* Expense Ledger Header */}
        <div className="flex justify-between items-center mb-6 print:hidden">
          <div>
            <h2 className="text-2xl font-bold text-white">{t('buildingdetails.cost_history_ledger', { defaultValue: `Cost History (Ledger)` })}</h2>
            <p className="text-muted text-sm">{t('buildingdetails.expenses_materials_for_this_bu', { defaultValue: `Expenses & materials for this building and its apartments.` })}</p>
          </div>
          
          <div className="flex items-center space-x-3">
            
            {/* Custom Searchable Dropdown */}
            <div className="relative" ref={filterRef}>
              <div 
                onClick={() => setFilterOpen(!filterOpen)}
                className="flex items-center space-x-2 bg-slate-800 rounded-lg px-4 py-2 border border-slate-700 cursor-pointer hover:border-slate-500 transition-colors"
              >
                <Filter size={16} className="text-muted" />
                <span className="text-white text-sm font-medium w-48 truncate">
                  {filterOptions.find(o => o.value === targetFilter)?.label || 'All Costs'}
                </span>
                <ChevronDown size={16} className="text-muted ml-auto" />
              </div>
              
              {filterOpen && (
                <div className="absolute top-full right-0 mt-2 w-64 bg-slate-800 border border-slate-700 rounded-xl shadow-xl z-50 overflow-hidden animate-in fade-in slide-in-from-top-2">
                  <div className="p-2 border-b border-slate-700 bg-slate-800/50">
                    <div className="relative">
                      <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" />
                      <input 
                        type="text" 
                        autoFocus
                        placeholder={t('buildingdetails.search_apartment', { defaultValue: `Search apartment...` })} 
                        className="w-full bg-slate-900 border border-slate-700 text-white rounded-lg pl-9 pr-3 py-2 text-sm focus:outline-none focus:border-primary"
                        value={filterSearch}
                        onChange={(e) => setFilterSearch(e.target.value)}
                      />
                    </div>
                  </div>
                  <div className="max-h-60 overflow-y-auto hide-scrollbar p-1">
                    {searchedOptions.length > 0 ? searchedOptions.map(opt => (
                      <div 
                        key={opt.value}
                        onClick={() => {
                          setTargetFilter(opt.value);
                          setFilterOpen(false);
                          setFilterSearch('');
                        }}
                        className={`px-4 py-2.5 text-sm cursor-pointer rounded-lg transition-colors ${targetFilter === opt.value ? 'bg-primary text-white font-medium' : 'text-slate-300 hover:bg-slate-700 hover:text-white'}`}
                      >
                        {opt.label}
                      </div>
                    )) : (
                      <div className="px-4 py-3 text-sm text-muted text-center">{t('buildingdetails.no_apartments_found', { defaultValue: `No apartments found.` })}</div>
                    )}
                  </div>
                </div>
              )}
            </div>

            <div className="flex items-center space-x-2 bg-slate-800 rounded-lg px-3 py-1 border border-slate-700">
              <Calendar size={16} className="text-muted" />
              <input type="date" value={dateRange.start_date} onChange={e => setDateRange({...dateRange, start_date: e.target.value})} className="bg-transparent text-white text-sm outline-none cursor-pointer py-1" style={{ colorScheme: 'dark' }} />
              <span className="text-muted">{t('buildingdetails.to', { defaultValue: `to` })}</span>
              <input type="date" value={dateRange.end_date} onChange={e => setDateRange({...dateRange, end_date: e.target.value})} className="bg-transparent text-white text-sm outline-none cursor-pointer py-1" style={{ colorScheme: 'dark' }} />
            </div>
            <button onClick={handlePrint} className="flex items-center text-sm bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg transition-colors shadow-lg shadow-primary/20">
              <Printer size={18} className="mr-2"/> {t('buildingdetails.print', { defaultValue: `Print` })}
            </button>
          </div>
        </div>

        {/* Dynamic Ledger Totals */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8 print:grid-cols-4 print:gap-2 print:mb-4">
          <div className="glass-card p-6 border-danger/30 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">{t('buildingdetails.total_spent', { defaultValue: `Total Spent` })}</h3>
            <div className="text-2xl print:text-sm font-bold text-danger print:text-black">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {dynamicLedger.total.toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">{t('buildingdetails.materials', { defaultValue: `Materials` })}</h3>
            <div className="text-2xl print:text-sm font-bold text-white print:text-black">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {dynamicLedger.materials.toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">{t('buildingdetails.labor', { defaultValue: `Labor` })}</h3>
            <div className="text-2xl print:text-sm font-bold text-white print:text-black">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {dynamicLedger.labor.toLocaleString()}</div>
          </div>
          <div className="glass-card p-6 print:border print:border-black print:bg-transparent print:shadow-none print:p-2">
            <h3 className="text-muted print:text-slate-600 text-sm print:text-[10px] uppercase tracking-wider mb-2 print:mb-1 font-medium">{t('buildingdetails.other', { defaultValue: `Other` })}</h3>
            <div className="text-2xl print:text-sm font-bold text-white print:text-black">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {dynamicLedger.other.toLocaleString()}</div>
          </div>
        </div>

        <div className="glass-card overflow-hidden print:border print:border-black print:shadow-none mb-12 print:mb-0">
          <table className="w-full text-left border-collapse print:text-[10px] print:leading-tight">
            <thead>
              <tr className="border-b border-slate-700/50 bg-slate-800/30 print:bg-slate-100 print:border-black">
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">{t('buildingdetails.date', { defaultValue: `Date` })}</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">{t('buildingdetails.target', { defaultValue: `Target` })}</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">{t('buildingdetails.category', { defaultValue: `Category` })}</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">{t('buildingdetails.notes_items', { defaultValue: `Notes / Items` })}</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase border-r border-transparent print:border-black">{t('buildingdetails.reference', { defaultValue: `Reference` })}</th>
                <th className="p-4 print:p-1 text-xs print:text-[10px] font-semibold text-muted print:text-black uppercase text-right">{t('buildingdetails.cost', { defaultValue: `Cost` })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50 print:divide-black">
              {filteredExpenses.length > 0 ? filteredExpenses.map((exp, idx) => (
                <tr key={`${exp.id}-${idx}`} className="hover:bg-slate-800/30 transition-colors print:hover:bg-transparent">
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-slate-300 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">{exp.date}</td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] font-medium text-white print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">
                    {exp.target_name}
                  </td>
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
                            <span>- {item.product_name} <span className="font-bold text-slate-400 print:text-black">{t('buildingdetails.x', { defaultValue: `x` })}{item.quantity}</span></span>
                            <span className="text-indigo-400 print:text-black">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {parseFloat(item.total_price).toLocaleString()}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-indigo-300 print:text-black align-top whitespace-nowrap border-r border-transparent print:border-black">{exp.reference_id || '-'}</td>
                  <td className="p-4 print:p-1 text-sm print:text-[10px] text-danger font-bold text-right print:text-black align-top whitespace-nowrap">{t('buildingdetails.cfa', { defaultValue: `CFA` })} {parseFloat(exp.amount).toLocaleString()}</td>
                </tr>
              )) : (
                <tr>
                  <td colSpan="6" className="p-8 print:p-2 text-center text-muted print:text-black print:text-[10px]">{t('buildingdetails.no_expenses_match_your_filters', { defaultValue: `No expenses match your filters.` })}</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

      </div>
    </div>
  );
};

export default BuildingDetails;
