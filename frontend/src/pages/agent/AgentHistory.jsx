import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import axios from '../../api/axios';
import { FileText, Zap, Home, Clock, CheckCircle, XCircle } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const AgentHistory = () => {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('generators');

  const getFullImageUrl = (path) => {
    if (!path) return null;
    if (path.startsWith('http')) return path;
    const apiUrl = process.env.REACT_APP_API_URL || 'http://localhost/Bitar/backend/api';
    const baseUrl = apiUrl.replace('/backend/api', '');
    return `${baseUrl}/${path}`;
  };

  // Fetching history. Since we might not have the endpoints yet, we'll try catching errors.
  const { data: genHistory = [], isLoading: genLoading } = useQuery({
    queryKey: ['agent_gen_history'],
    queryFn: async () => {
      try {
        return (await axios.get('/energy/agent/history/generators')).data;
      } catch (e) {
        return [];
      }
    }
  });

  const { data: aptHistory = [], isLoading: aptLoading } = useQuery({
    queryKey: ['agent_apt_history'],
    queryFn: async () => {
      try {
        return (await axios.get('/energy/agent/history/apartments')).data;
      } catch (e) {
        return [];
      }
    }
  });

  const getStatusBadge = (status) => {
    switch (status?.toLowerCase()) {
      case 'approved':
      case 'accepted':
      case 'verified':
        return <span className="px-3 py-1 rounded-full text-xs font-medium bg-success/10 text-success border border-success/20 flex items-center w-max"><CheckCircle size={12} className="me-1" /> {status === 'Verified' || status === 'verified' ? 'Verified' : 'Accepted'}</span>;
      case 'rejected':
        return <span className="px-3 py-1 rounded-full text-xs font-medium bg-danger/10 text-danger border border-danger/20 flex items-center w-max"><XCircle size={12} className="me-1" /> Rejected</span>;
      default:
        return <span className="px-3 py-1 rounded-full text-xs font-medium bg-warning/10 text-warning border border-warning/20 flex items-center w-max"><Clock size={12} className="me-1" /> Pending</span>;
    }
  };

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
          <FileText className="me-3 text-info" /> My Reading History
        </h1>
        <p className="text-muted">Track the status of all generator and apartment readings you have submitted.</p>
      </div>

      <div className="flex gap-4 mb-6 shrink-0">
        <button
          onClick={() => setActiveTab('generators')}
          className={`flex items-center px-6 py-3 rounded-xl font-medium transition-all ${
            activeTab === 'generators' 
              ? 'bg-warning text-white shadow-lg shadow-warning/20' 
              : 'bg-slate-800/50 text-slate-400 hover:bg-slate-800 hover:text-white'
          }`}
        >
          <Zap size={18} className="me-2" /> Generator History
        </button>
        <button
          onClick={() => setActiveTab('apartments')}
          className={`flex items-center px-6 py-3 rounded-xl font-medium transition-all ${
            activeTab === 'apartments' 
              ? 'bg-primary text-white shadow-lg shadow-primary/20' 
              : 'bg-slate-800/50 text-slate-400 hover:bg-slate-800 hover:text-white'
          }`}
        >
          <Home size={18} className="me-2" /> Apartment History
        </button>
      </div>

      <div className="glass-card flex-1 overflow-hidden flex flex-col">
        {activeTab === 'generators' && (
          <div className="overflow-x-auto flex-1">
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="border-b border-slate-700/50 bg-slate-800/30">
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Date</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Building</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Reading (Counter)</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Photos</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Status</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Admin Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {genLoading ? (
                  <tr><td colSpan="6" className="p-8 text-center text-slate-500">Loading history...</td></tr>
                ) : genHistory.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="p-12 text-center text-slate-500">
                      <Zap size={48} className="mx-auto mb-4 opacity-30" />
                      No generator readings submitted yet.
                    </td>
                  </tr>
                ) : (
                  genHistory.map(item => (
                    <tr key={item.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="p-4 text-white font-medium">{item.date}</td>
                      <td className="p-4 text-slate-300">{item.building_name}</td>
                      <td className="p-4 text-slate-300">{item.generator_counter}</td>
                      <td className="p-4 text-slate-300">
                        {item.meter_photo_url && <a href={getFullImageUrl(item.meter_photo_url)} target="_blank" rel="noreferrer" className="text-info hover:underline text-sm block">Meter</a>}
                        {item.fuel_photo_url && <a href={getFullImageUrl(item.fuel_photo_url)} target="_blank" rel="noreferrer" className="text-info hover:underline text-sm block mt-1">Fuel</a>}
                      </td>
                      <td className="p-4">{getStatusBadge(item.status)}</td>
                      <td className="p-4 text-slate-400 text-sm max-w-xs truncate">{item.admin_notes || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}

        {activeTab === 'apartments' && (
          <div className="overflow-x-auto flex-1">
            <table className="w-full text-start border-collapse">
              <thead>
                <tr className="border-b border-slate-700/50 bg-slate-800/30">
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Date</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Building</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Apartment</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Reading</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Consumption</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Photo</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Status</th>
                  <th className="p-4 text-sm font-semibold text-muted uppercase tracking-wider text-start">Admin Notes</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {aptLoading ? (
                  <tr><td colSpan="8" className="p-8 text-center text-slate-500">Loading history...</td></tr>
                ) : aptHistory.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="p-12 text-center text-slate-500">
                      <Home size={48} className="mx-auto mb-4 opacity-30" />
                      No apartment readings submitted yet.
                    </td>
                  </tr>
                ) : (
                  aptHistory.map(item => (
                    <tr key={item.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="p-4 text-white font-medium">{item.date}</td>
                      <td className="p-4 text-slate-300">{item.building_name}</td>
                      <td className="p-4 text-slate-300">Apt {item.apartment_code}</td>
                      <td className="p-4 text-white font-bold">{item.current_reading} kWh</td>
                      <td className="p-4 text-info font-medium">+{item.consumption} kWh</td>
                      <td className="p-4 text-slate-300">
                        {item.meter_photo_url ? <a href={getFullImageUrl(item.meter_photo_url)} target="_blank" rel="noreferrer" className="text-primary hover:underline text-sm block">View Photo</a> : '-'}
                      </td>
                      <td className="p-4">{getStatusBadge(item.status)}</td>
                      <td className="p-4 text-slate-400 text-sm max-w-xs truncate">{item.admin_notes || '-'}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default AgentHistory;
