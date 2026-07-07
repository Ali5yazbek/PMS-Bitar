import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { Activity, Search, Filter } from 'lucide-react';

const AuditLogs = () => {
  const { t } = useTranslation();

  const [searchTerm, setSearchTerm] = useState('');
  const [actionFilter, setActionFilter] = useState('All');

  const { data: logs, isLoading } = useQuery({
    queryKey: ['auditLogs'],
    queryFn: async () => (await api.get('/audit')).data
  });

  if (isLoading) return <div>{t('auditlogs.loading', { defaultValue: `Loading...` })}</div>;

  const displayedLogs = logs?.filter(log => {
    const matchesSearch = log.details?.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          log.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                          log.entity_type?.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesAction = actionFilter === 'All' || log.action === actionFilter;
    
    return matchesSearch && matchesAction;
  });

  const getActionColor = (action) => {
    switch(action) {
      case 'CREATE': return 'bg-green-100 text-green-800 border-green-200';
      case 'UPDATE': return 'bg-blue-100 text-blue-800 border-blue-200';
      case 'DELETE': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-slate-100 text-slate-800 border-slate-200';
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center bg-white p-6 rounded-xl shadow-sm border border-slate-100">
        <div className="flex items-center gap-3">
          <div className="bg-indigo-100 p-3 rounded-lg text-indigo-600">
            <Activity size={24} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-800">{t('auditlogs.audit_logs', { defaultValue: `Audit Logs` })}</h1>
            <p className="text-slate-500 text-sm">{t('auditlogs.track_all_user_activity_and_sy', { defaultValue: `Track all user activity and system changes` })}</p>
          </div>
        </div>
      </div>

      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-4 rounded-xl shadow-sm border border-slate-100">
        <div className="flex-1 flex gap-4 w-full">
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
            <input 
              type="text" 
              placeholder={t('auditlogs.search_details_user_or_entity', { defaultValue: `Search details, user, or entity...` })} 
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <Filter className="text-slate-400" size={20} />
            <select 
              value={actionFilter}
              onChange={e => setActionFilter(e.target.value)}
              className="border rounded-lg px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500 bg-white"
            >
              <option value="All">{t('auditlogs.all_actions', { defaultValue: `All Actions` })}</option>
              <option value="CREATE">{t('auditlogs.created', { defaultValue: `Created` })}</option>
              <option value="UPDATE">{t('auditlogs.updated', { defaultValue: `Updated` })}</option>
              <option value="DELETE">{t('auditlogs.deleted', { defaultValue: `Deleted` })}</option>
            </select>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
        <table className="min-w-full divide-y divide-slate-200">
          <thead className="bg-slate-50">
            <tr>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{t('auditlogs.date_time', { defaultValue: `Date & Time` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{t('auditlogs.user', { defaultValue: `User` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{t('auditlogs.action', { defaultValue: `Action` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{t('auditlogs.entity', { defaultValue: `Entity` })}</th>
              <th className="px-6 py-4 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">{t('auditlogs.details', { defaultValue: `Details` })}</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-slate-200">
            {displayedLogs?.map(log => (
              <tr key={log.id} className="hover:bg-slate-50 transition-colors">
                <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-600">
                  {new Date(log.created_at).toLocaleString()}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <div className="h-8 w-8 bg-indigo-100 rounded-full flex items-center justify-center text-indigo-700 font-bold mr-3">
                      {log.user_name?.charAt(0).toUpperCase()}
                    </div>
                    <span className="font-medium text-slate-900">{log.user_name}</span>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`inline-flex px-2.5 py-0.5 rounded-full text-xs font-bold border ${getActionColor(log.action)}`}>
                    {log.action}
                  </span>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-700">
                  {log.entity_type} {log.entity_id ? `#${log.entity_id}` : ''}
                </td>
                <td className="px-6 py-4 text-sm text-slate-600">
                  {log.details}
                </td>
              </tr>
            ))}
            {displayedLogs?.length === 0 && (
              <tr>
                <td colSpan="5" className="px-6 py-12 text-center text-slate-500">
                  {t('auditlogs.no_audit_logs_found_matching_y', { defaultValue: `No audit logs found matching your search.` })}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default AuditLogs;
