import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Home, Filter, Download } from 'lucide-react';

const RentManagement = () => {
  const { t } = useTranslation();
  const [month, setMonth] = useState(new Date().getMonth() + 1);
  const [year, setYear] = useState(new Date().getFullYear());

  const { data: stats, isLoading } = useQuery({ 
    queryKey: ['rent-dashboard', month, year], 
    queryFn: async () => (await api.get(`/rent/dashboard?month=${month}&year=${year}`)).data 
  });

  if (isLoading) return <div className="p-8 text-muted">Loading...</div>;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Home className="me-3 text-primary" size={32} />
              Rent Management
            </h1>
            <p className="text-muted mt-2">Displaying only rented apartments statistics.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <select value={month} onChange={e => setMonth(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary">
              {Array.from({length: 12}, (_, i) => i + 1).map(m => (
                <option key={m} value={m}>{new Date(0, m - 1).toLocaleString('default', { month: 'long' })}</option>
              ))}
            </select>
            <select value={year} onChange={e => setYear(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary">
              {[2023, 2024, 2025, 2026, 2027].map(y => (
                <option key={y} value={y}>{y}</option>
              ))}
            </select>
            <button className="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors border border-slate-700">
              <Download size={20} />
              <span>Export PDF</span>
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-6">
          {stats?.map(stat => (
            <div key={stat.building_id} className="glass-card p-6">
              <h3 className="text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-4">Building: {stat.building_name}</h3>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <div className="text-muted text-sm mb-1">Total Rented Rooms</div>
                  <div className="text-2xl font-bold text-white">{stat.total_rented_rooms}</div>
                </div>
                
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <div className="text-muted text-sm mb-1">Expected Rent This Month</div>
                  <div className="text-2xl font-bold text-indigo-400">CFA {Number(stat.expected_rent).toFixed(2)}</div>
                </div>
                
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <div className="text-muted text-sm mb-1">Total Collected This Month</div>
                  <div className="text-2xl font-bold text-success">CFA {Number(stat.total_collected).toFixed(2)}</div>
                </div>
                
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <div className="text-muted text-sm mb-1">Outstanding Balance</div>
                  <div className="text-2xl font-bold text-danger">CFA {Number(stat.outstanding_balance).toFixed(2)}</div>
                </div>
              </div>
            </div>
          ))}

          {stats?.length === 0 && (
            <div className="glass-card p-8 text-center text-muted">
              No active rentals found for the selected period.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default RentManagement;
