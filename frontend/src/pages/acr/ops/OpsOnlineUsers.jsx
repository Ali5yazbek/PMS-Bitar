import React, { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { 
  Users, Clock, AlertTriangle, Shield, CheckCircle2, Printer, 
  ChevronDown, Search, ArrowRight, UserCheck, UserMinus, AlertCircle, FileWarning, Eye, X
} from 'lucide-react';
import api from '../../../api/axios';
import ActionControlReportDetail from '../../ActionControlReportDetail';

const ROLE_COLORS = {
  admin:   'text-red-400 bg-red-500/10 border-red-500/20',
  manager: 'text-indigo-400 bg-indigo-500/10 border-indigo-500/20',
  agent:   'text-emerald-400 bg-emerald-500/10 border-emerald-500/20',
  tenant:  'text-cyan-400 bg-cyan-500/10 border-cyan-500/20',
  cashier: 'text-yellow-400 bg-yellow-500/10 border-yellow-500/20',
};

const getHealthStyle = (score) => {
  if (score === 100) return { bg: 'bg-emerald-500/10', border: 'border-emerald-500/30', text: 'text-emerald-400' };
  if (score >= 90) return { bg: 'bg-yellow-500/10', border: 'border-yellow-400/30', text: 'text-yellow-400' };
  if (score >= 75) return { bg: 'bg-orange-500/10', border: 'border-orange-500/30', text: 'text-orange-400' };
  return { bg: 'bg-red-500/10', border: 'border-red-500/30', text: 'text-red-400' };
};

const getStatusStyle = (status) => {
  switch(status) {
    case 'online':  return { bg: 'bg-emerald-500',  text: 'text-emerald-400' };
    case 'idle':    return { bg: 'bg-yellow-400',   text: 'text-yellow-400' };
    case 'editing': return { bg: 'bg-blue-500',     text: 'text-blue-400' };
    case 'offline': return { bg: 'bg-slate-500',    text: 'text-slate-400' };
    default:        return { bg: 'bg-slate-500',    text: 'text-slate-400' };
  }
};

const getInitials = (name) => {
  return (name || 'Unknown').split(' ').map(n => n[0]).join('').substring(0, 2).toUpperCase();
};

export default function OpsOnlineUsers({ isAdmin }) {
  const [selectedUserForProblems, setSelectedUserForProblems] = useState(null);
  const [selectedUserIds, setSelectedUserIds] = useState([]);
  
  const [filterMode, setFilterMode] = useState('All');
  const [filterSearch, setFilterSearch] = useState('');
  const [bulkPrintOption, setBulkPrintOption] = useState('Print Summary');

  const { data: payload, isFetching } = useQuery({
    queryKey: ['ops-online-users'],
    queryFn: async () => (await api.get('/operations/online-users')).data,
    refetchInterval: 15000,
  });

  const users = payload?.users || [];

  // Top Counters
  const totalEmployees = users.length;
  const healthyCount = users.filter(u => u.health_score === 100).length;
  const needReviewCount = users.filter(u => u.pending_reviews > 0).length;
  const criticalCount = users.filter(u => u.critical_problems > 0).length;
  const offlineCount = users.filter(u => u.status === 'offline').length;
  const onlineCount = users.filter(u => u.status !== 'offline').length;

  const filteredUsers = users.filter(u => {
    if (filterSearch && !u.user_name.toLowerCase().includes(filterSearch.toLowerCase())) return false;
    switch(filterMode) {
      case 'Healthy': return u.health_score === 100;
      case 'Has Problems': return u.total_problems > 0;
      case 'Critical': return u.critical_problems > 0;
      case 'Offline': return u.status === 'offline';
      case 'Online': return u.status !== 'offline';
      case 'Pending Review': return u.pending_reviews > 0;
      case 'All': default: return true;
    }
  });

  const handleSelectAll = (e) => {
    if (e.target.checked) setSelectedUserIds(filteredUsers.map(u => u.id));
    else setSelectedUserIds([]);
  };

  const toggleSelectUser = (id) => {
    setSelectedUserIds(prev => prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]);
  };

  const handlePrintUser = (user) => {
    setSelectedUserForProblems(user);
    setTimeout(() => window.print(), 500); 
  };

  const handleBulkPrint = () => {
    if (selectedUserIds.length === 0) return;
    window.print();
  };

  // If a single user is clicked for problems
  if (selectedUserForProblems) {
    return (
      <ActionControlReportDetail 
        employee={{ employee_id: selectedUserForProblems.id, name: selectedUserForProblems.user_name, role: selectedUserForProblems.role, department: selectedUserForProblems.department }}
        showFullDetails={true}
        professionalMode={false}
        isAdmin={isAdmin}
        onBack={() => setSelectedUserForProblems(null)}
      />
    );
  }

  return (
    <div className="relative pb-10 print:bg-white print:text-black">
      
      {/* ── Hidden Bulk Print View ───────────────────────────────────────── */}
      <div className="hidden print:block space-y-10">
         <h1 className="text-3xl font-bold border-b-2 border-black pb-4 mb-4">
            Employee Action Control Report: {bulkPrintOption}
         </h1>
         <p className="mb-8 font-bold">Total Selected Employees: {selectedUserIds.length}</p>
         
         {/* Sort Users if grouped by Role or Department */}
         {selectedUserIds.slice().sort((a, b) => {
            if (bulkPrintOption === 'Print By Role') return users.find(u=>u.id===a).role.localeCompare(users.find(u=>u.id===b).role);
            if (bulkPrintOption === 'Print By Department') return (users.find(u=>u.id===a).department||'').localeCompare(users.find(u=>u.id===b).department||'');
            return 0;
         }).map((id, index) => {
            const u = users.find(x => x.id === id);
            if (!u) return null;

            // Filter problems based on option
            let problemsToPrint = u.top_problems || [];
            if (bulkPrintOption === 'Print Missing Fields Only') {
               problemsToPrint = problemsToPrint.filter(p => p.description.toLowerCase().includes('missing'));
            } else if (bulkPrintOption === 'Print Critical Problems Only') {
               problemsToPrint = problemsToPrint.filter(p => p.severity === 'critical');
            }

            return (
              <div key={u.id} className="mb-10 page-break-after-always" style={{ pageBreakAfter: 'always' }}>
                 <div className="border border-gray-400 p-4 mb-4 bg-gray-50">
                    <h2 className="text-2xl font-bold">{u.user_name}</h2>
                    <p><strong>Role:</strong> <span className="capitalize">{u.role}</span> | <strong>Department:</strong> {u.department || 'General'}</p>
                    <p><strong>Status:</strong> {u.status} | <strong>Health Score:</strong> {u.health_score}%</p>
                 </div>

                 <div className="grid grid-cols-2 gap-4 mb-4 text-sm border-b border-gray-300 pb-4">
                    <div>
                      <p><strong>Total Problems:</strong> {u.total_problems}</p>
                      <p><strong>Critical:</strong> {u.critical_problems}</p>
                      <p><strong>Warnings:</strong> {u.warning_problems}</p>
                    </div>
                    <div>
                      <p><strong>Missing Fields:</strong> {u.missing_fields}</p>
                      <p><strong>Expired Documents:</strong> {u.expired_documents}</p>
                      <p><strong>Pending Reviews:</strong> {u.pending_reviews}</p>
                    </div>
                 </div>

                 {u.total_problems > 0 && bulkPrintOption !== 'Print Summary' ? (
                   <div>
                     <h3 className="font-bold mb-2">Detailed Problems</h3>
                     {problemsToPrint.length > 0 ? (
                       <table className="w-full text-left text-sm border-collapse">
                         <thead>
                           <tr className="bg-gray-100 border border-gray-300">
                             <th className="p-2 border border-gray-300">Module</th>
                             <th className="p-2 border border-gray-300">Field</th>
                             <th className="p-2 border border-gray-300">Description</th>
                             <th className="p-2 border border-gray-300">Severity</th>
                           </tr>
                         </thead>
                         <tbody>
                           {problemsToPrint.map((p, i) => (
                             <tr key={i} className="border border-gray-300">
                               <td className="p-2 border border-gray-300 capitalize">{p.module}</td>
                               <td className="p-2 border border-gray-300">{p.field}</td>
                               <td className="p-2 border border-gray-300">{p.description}</td>
                               <td className="p-2 border border-gray-300">{p.severity}</td>
                             </tr>
                           ))}
                         </tbody>
                       </table>
                     ) : (
                       <p className="text-sm italic">No problems match the current filter criteria for this user.</p>
                     )}
                     {u.total_problems > 5 && (
                       <p className="mt-2 text-xs italic text-gray-500">And {u.total_problems - problemsToPrint.length} more issues. View individual report for full list.</p>
                     )}
                   </div>
                 ) : (
                   u.total_problems > 0 ? (
                     <p className="text-sm italic">Summary Mode: Open user profile to print detailed problems.</p>
                   ) : (
                     <p className="text-sm text-green-600 font-bold">No Open Problems</p>
                   )
                 )}
              </div>
            );
         })}
      </div>

      <div className="print:hidden">
        
        {/* Top Counters */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4 mb-6">
          <div className="bg-slate-800/60 border border-slate-700/50 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-white">{totalEmployees}</div>
            <div className="text-xs text-slate-400 font-bold uppercase tracking-wider mt-1">Employees</div>
          </div>
          <div className="bg-emerald-900/20 border border-emerald-500/20 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-emerald-400">{healthyCount}</div>
            <div className="text-xs text-emerald-500 font-bold uppercase tracking-wider mt-1">Healthy</div>
          </div>
          <div className="bg-orange-900/20 border border-orange-500/20 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-orange-400">{needReviewCount}</div>
            <div className="text-xs text-orange-500 font-bold uppercase tracking-wider mt-1">Need Review</div>
          </div>
          <div className="bg-red-900/20 border border-red-500/20 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-red-400">{criticalCount}</div>
            <div className="text-xs text-red-500 font-bold uppercase tracking-wider mt-1">Critical</div>
          </div>
          <div className="bg-slate-800/60 border border-slate-700/50 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-slate-300">{offlineCount}</div>
            <div className="text-xs text-slate-400 font-bold uppercase tracking-wider mt-1">Offline</div>
          </div>
          <div className="bg-blue-900/20 border border-blue-500/20 rounded-xl p-4 flex flex-col items-center justify-center">
            <div className="text-2xl font-black text-blue-400">{onlineCount}</div>
            <div className="text-xs text-blue-500 font-bold uppercase tracking-wider mt-1">Online</div>
          </div>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-2 mb-6 items-center">
          {['All', 'Healthy', 'Has Problems', 'Critical', 'Offline', 'Online', 'Pending Review'].map(f => (
            <button key={f} onClick={() => setFilterMode(f)}
              className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all border ${filterMode === f ? 'bg-indigo-600 text-white border-indigo-500 shadow-[0_0_10px_rgba(99,102,241,0.5)]' : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-white'}`}>
              {f}
            </button>
          ))}
          <div className="relative flex-1 min-w-[200px] ml-auto">
            <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
            <input type="text" placeholder="Search employee..." value={filterSearch} onChange={e => setFilterSearch(e.target.value)}
              className="w-full bg-slate-800/60 border border-slate-700 text-white rounded-full pl-9 pr-4 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500 transition-all" />
          </div>
        </div>

        {/* Toolbar Selection Area */}
        <div className="flex items-center gap-4 mb-4 px-2">
          <label className="flex items-center gap-2 text-white font-bold cursor-pointer text-sm bg-slate-800/60 py-1.5 px-3 rounded-lg border border-slate-700">
            <input type="checkbox" onChange={handleSelectAll} checked={filteredUsers.length > 0 && selectedUserIds.length === filteredUsers.length} className="w-4 h-4 accent-indigo-500 rounded" />
            Select All
          </label>
        </div>

        {/* Bulk Actions Toolbar */}
        {selectedUserIds.length > 0 && (
          <div className="fixed bottom-8 left-1/2 -translate-x-1/2 bg-slate-900 text-white px-6 py-4 rounded-2xl shadow-[0_10px_40px_rgba(0,0,0,0.5)] z-50 flex items-center gap-6 animate-in slide-in-from-bottom border border-indigo-500">
            <span className="font-bold text-lg">{selectedUserIds.length} Selected</span>
            <div className="flex gap-3">
              <select value={bulkPrintOption} onChange={e => setBulkPrintOption(e.target.value)} className="bg-slate-800 border border-slate-700 text-white rounded-xl px-4 py-2 text-sm font-bold focus:outline-none focus:ring-1 focus:ring-indigo-500">
                <option value="Print Summary">Print Summary</option>
                <option value="Print Detailed">Print Detailed</option>
                <option value="Print Missing Fields Only">Print Missing Fields Only</option>
                <option value="Print Critical Problems Only">Print Critical Problems Only</option>
                <option value="Print By Role">Print By Role</option>
                <option value="Print By Department">Print By Department</option>
              </select>
              <button onClick={handleBulkPrint} className="flex items-center gap-2 bg-indigo-600 text-white px-5 py-2 rounded-xl font-bold hover:bg-indigo-500 transition-colors shadow-lg shadow-indigo-500/20">
                <Printer size={16} /> Generate PDF
              </button>
              <button onClick={() => setSelectedUserIds([])} className="p-2 text-slate-400 hover:text-white transition-colors bg-slate-800 rounded-xl hover:bg-slate-700">
                <X size={20} />
              </button>
            </div>
          </div>
        )}

        {/* User Cards Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
          {filteredUsers.map(u => {
            const st = getStatusStyle(u.status);
            const hs = getHealthStyle(u.health_score);
            const isSelected = selectedUserIds.includes(u.id);
            
            return (
              <div key={u.id} className={`relative flex flex-col rounded-2xl p-5 border transition-all ${hs.bg} ${isSelected ? 'border-indigo-500 shadow-[0_0_15px_rgba(99,102,241,0.3)] ring-1 ring-indigo-500' : hs.border} cursor-pointer hover:border-slate-500`}
                   onClick={() => toggleSelectUser(u.id)}>
                
                <input type="checkbox" checked={isSelected} readOnly className="absolute top-5 right-5 w-5 h-5 accent-indigo-500 z-10 pointer-events-none" />

                {/* Header Profile */}
                <div className="flex gap-4 items-center mb-5 border-b border-slate-700/30 pb-4">
                  <div className="relative shrink-0">
                    {u.avatar ? (
                      <img src={u.avatar} alt="Avatar" className="w-16 h-16 rounded-xl object-cover border border-slate-600" />
                    ) : (
                      <div className="w-16 h-16 rounded-xl bg-slate-800 border border-slate-700 flex items-center justify-center text-white font-bold text-2xl shadow-inner">
                        {getInitials(u.user_name)}
                      </div>
                    )}
                  </div>
                  <div className="min-w-0 flex-1">
                    <h3 className="font-bold text-white text-lg truncate">{u.user_name}</h3>
                    <div className="text-sm text-slate-400 capitalize">{u.department || 'General'} {u.role}</div>
                    <div className="flex items-center gap-1.5 mt-1">
                      <div className={`w-2.5 h-2.5 rounded-full ${st.bg}`} />
                      <span className={`text-xs font-bold capitalize ${st.text}`}>{u.status}</span>
                    </div>
                  </div>
                </div>

                <div className="flex gap-4">
                  {/* Left Column: Metrics */}
                  <div className="flex-1 space-y-3 pr-4 border-r border-slate-700/30">
                    <div className="flex justify-between items-center text-sm">
                       <span className="text-slate-400">Overall Health</span>
                       <span className={`font-black text-lg ${hs.text}`}>{u.health_score}%</span>
                    </div>
                    
                    <div className="bg-slate-900/40 rounded-lg p-3 space-y-1">
                      <div className="flex justify-between items-center text-sm mb-1 border-b border-slate-700/50 pb-1">
                         <span className="text-slate-300 font-bold">Problems</span>
                         <span className="font-bold text-white">{u.total_problems}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-500">Critical</span>
                         <span className="text-red-400 font-bold">{u.critical_problems}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-500">Warning</span>
                         <span className="text-yellow-400 font-bold">{u.warning_problems}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-500">Info</span>
                         <span className="text-blue-400 font-bold">{u.info_problems}</span>
                      </div>
                    </div>

                    <div className="space-y-1.5 pt-1">
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-400">Missing Fields</span>
                         <span className="text-white font-bold">{u.missing_fields}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-400">Expired Docs</span>
                         <span className="text-white font-bold">{u.expired_documents}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-400">Pending Reviews</span>
                         <span className="text-white font-bold">{u.pending_reviews}</span>
                      </div>
                      <div className="flex justify-between items-center text-xs">
                         <span className="text-slate-400">Completed Today</span>
                         <span className="text-emerald-400 font-bold">{u.todays_work}</span>
                      </div>
                    </div>
                  </div>

                  {/* Right Column: Mini Problem Tree */}
                  <div className="flex-1 flex flex-col pl-2">
                    <h4 className="text-xs font-bold text-slate-500 uppercase tracking-wider mb-2">Live Issue Tree</h4>
                    
                    {u.top_problems && u.top_problems.length > 0 ? (
                      <div className="space-y-3 flex-1 overflow-y-auto max-h-[220px] no-scrollbar pr-1">
                        {u.top_problems.map((p, i) => (
                          <div key={i} className="text-xs">
                             <div className="flex items-center gap-1 text-slate-400 font-bold capitalize">
                               <ArrowRight size={10} className="text-slate-600"/> {p.module}
                             </div>
                             <div className="pl-3 mt-1">
                               <div className={`p-1.5 rounded border bg-slate-900/50 ${p.severity === 'critical' ? 'border-red-500/30 text-red-300' : p.severity === 'warning' ? 'border-yellow-500/30 text-yellow-300' : 'border-slate-700 text-slate-300'}`}>
                                 <span className="font-bold">{p.field}:</span> {p.description}
                               </div>
                             </div>
                          </div>
                        ))}
                        {u.total_problems > 5 && (
                          <div className="text-xs text-center text-slate-500 font-bold mt-2 bg-slate-900/30 py-1 rounded">
                            + {u.total_problems - 5} More
                          </div>
                        )}
                      </div>
                    ) : (
                      <div className="flex-1 flex flex-col items-center justify-center opacity-40">
                         <CheckCircle2 size={32} className="text-emerald-500 mb-2"/>
                         <span className="text-xs font-bold text-emerald-500">Fully Compliant</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* Actions Footer */}
                <div className="flex gap-2 mt-5 pt-4 border-t border-slate-700/30">
                  <button onClick={(e) => { e.stopPropagation(); setSelectedUserForProblems(u); }} className="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg py-2 text-xs font-bold transition-all shadow-lg shadow-indigo-500/20 flex items-center justify-center gap-1.5">
                    <Eye size={14}/> View Report
                  </button>
                  <button onClick={(e) => { e.stopPropagation(); handlePrintUser(u); }} className="px-3 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg py-2 text-xs font-bold transition-all border border-slate-700 flex items-center justify-center gap-1.5">
                    <Printer size={14} /> Print
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
