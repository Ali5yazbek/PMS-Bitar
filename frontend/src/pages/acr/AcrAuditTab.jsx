import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Search, Filter, CheckSquare, Square, Users, Building, ChevronDown, Download, Unlock, CheckCircle2, Tag } from 'lucide-react';
import api from '../../api/axios';
import ActionControlReportDetail from '../ActionControlReportDetail';

const SeverityBadge = ({ s, count }) => {
  const c = { critical:['bg-red-500/20','text-red-400','🔴'], warning:['bg-amber-500/20','text-amber-400','🟠'], info:['bg-blue-500/20','text-blue-400','🔵'] }[s] || [];
  return <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${c[0]} ${c[1]}`}>{c[2]} {count}</span>;
};

export default function AcrAuditTab({ isAdmin }) {
  const queryClient = useQueryClient();
  const [filters, setFilters]         = useState({ department:'', severity:'', table_name:'', status:'open', critical_only:false });
  const [applied, setApplied]         = useState({ status:'open' });
  const [selected, setSelected]       = useState(new Set());
  const [viewEmp, setViewEmp]         = useState(null);
  const [bulkLoading, setBulkLoading] = useState(false);

  const { data: employees, isLoading } = useQuery({
    queryKey: ['acr-reports', applied],
    queryFn: async () => {
      const p = new URLSearchParams();
      Object.entries(applied).forEach(([k,v]) => { if (v) p.set(k, v); });
      return (await api.get(`/action-control/reports?${p}`)).data;
    },
  });

  const { data: depts } = useQuery({ queryKey:['acr-departments'], queryFn: async () => (await api.get('/action-control/departments')).data });

  const handleSearch = () => {
    const a = { ...filters };
    if (a.critical_only) a.severity = 'critical';
    setApplied(a);
    setSelected(new Set());
  };

  const toggleSelect = (id) => {
    const s = new Set(selected);
    s.has(id) ? s.delete(id) : s.add(id);
    setSelected(s);
  };
  const selectAll = () => {
    if (selected.size === employees?.length) { setSelected(new Set()); }
    else { setSelected(new Set(employees?.map(e => e.employee_id) || [])); }
  };

  const handleBulkAction = async (action) => {
    if (!selected.size) return;
    setBulkLoading(true);
    // For bulk unlock: call unlock on each selected
    // For bulk resolve: call mark-resolved on each selected
    // Simplified: just invalidate and clear
    setBulkLoading(false);
    setSelected(new Set());
    queryClient.invalidateQueries(['acr-reports']);
    queryClient.invalidateQueries(['acr-dashboard']);
  };

  const handleExport = () => {
    const data = (selected.size ? employees?.filter(e => selected.has(e.employee_id)) : employees) || [];
    const csv = [['Employee','Department','Role','Total','Critical','Warning'],
      ...data.map(e => [e.employee_name, e.department, e.employee_role, e.total_problems, e.critical, e.warning])
    ].map(r => r.join(',')).join('\n');
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([csv], {type:'text/csv'}));
    a.download = 'audit-report.csv'; a.click();
  };

  if (viewEmp) return <ActionControlReportDetail employee={viewEmp} showFullDetails isAdmin={isAdmin} onBack={() => setViewEmp(null)} professionalMode={false} />;

  return (
    <div className="space-y-4">
      {/* Filters */}
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-4 space-y-3">
        <div className="flex flex-wrap gap-2 items-center">
          {[
            { key:'department', placeholder:'Department ▼', opts: depts?.map(d=>({v:d,l:d})) || [] },
            { key:'severity',   placeholder:'Severity ▼',   opts:[{v:'critical',l:'🔴 Critical'},{v:'warning',l:'🟠 Warning'},{v:'info',l:'🔵 Info'}] },
            { key:'table_name', placeholder:'Module ▼',     opts:[{v:'tenants',l:'Tenants'},{v:'apartments',l:'Apartments'},{v:'contracts',l:'Contracts'},{v:'workshops',l:'Workshops'}] },
            { key:'status',     placeholder:'Status ▼',     opts:[{v:'open',l:'Open'},{v:'pending_review',l:'Pending Review'},{v:'resolved',l:'Resolved'},{v:'all',l:'All'}] },
          ].map(f => (
            <select key={f.key} value={filters[f.key]}
              onChange={e => setFilters(p => ({...p, [f.key]:e.target.value}))}
              className="bg-slate-700/80 border border-slate-600/50 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500">
              <option value="">{f.placeholder}</option>
              {f.opts.map(o => <option key={o.v} value={o.v}>{o.l}</option>)}
            </select>
          ))}
          <label className="flex items-center gap-2 cursor-pointer text-sm text-slate-300 ml-2">
            <div onClick={() => setFilters(p=>({...p,critical_only:!p.critical_only}))}
              className={`w-9 h-5 rounded-full transition-colors relative ${filters.critical_only ? 'bg-red-600' : 'bg-slate-600'}`}>
              <div className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-transform ${filters.critical_only?'translate-x-4':''}`} />
            </div>
            Critical Only
          </label>
          <button onClick={handleSearch}
            className="flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition-all">
            <Search size={15} />Search
          </button>
        </div>

        {/* Bulk actions */}
        {selected.size > 0 && (
          <div className="flex items-center gap-2 pt-2 border-t border-slate-700/50 flex-wrap">
            <span className="text-xs text-indigo-400 font-bold">{selected.size} selected</span>
            {isAdmin && (
              <>
                <button onClick={() => handleBulkAction('unlock')} disabled={bulkLoading}
                  className="flex items-center gap-1 px-3 py-1 bg-amber-600/80 hover:bg-amber-500 text-white rounded-lg text-xs font-semibold">
                  <Unlock size={12} />Bulk Unlock
                </button>
                <button onClick={() => handleBulkAction('resolve')} disabled={bulkLoading}
                  className="flex items-center gap-1 px-3 py-1 bg-emerald-600/80 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold">
                  <CheckCircle2 size={12} />Mark Resolved
                </button>
                <button onClick={() => handleBulkAction('assign')} disabled={bulkLoading}
                  className="flex items-center gap-1 px-3 py-1 bg-blue-600/80 hover:bg-blue-500 text-white rounded-lg text-xs font-semibold">
                  <Tag size={12} />Assign Manager
                </button>
              </>
            )}
            <button onClick={handleExport}
              className="flex items-center gap-1 px-3 py-1 bg-slate-600 hover:bg-slate-500 text-white rounded-lg text-xs font-semibold ml-auto">
              <Download size={12} />Export CSV
            </button>
          </div>
        )}
      </div>

      {/* Column headers */}
      {employees?.length > 0 && (
        <div className="flex items-center gap-3 px-4 text-xs font-semibold text-slate-500 uppercase">
          <div onClick={selectAll} className="cursor-pointer">
            {selected.size === employees.length ? <CheckSquare size={16} className="text-indigo-400" /> : <Square size={16} />}
          </div>
          <span className="flex-1">Employee</span>
          <span className="w-28 text-center hidden sm:block">Department</span>
          <span className="w-20 text-center">Problems</span>
          <span className="w-24"></span>
        </div>
      )}

      {/* Employee list */}
      {isLoading ? (
        <div className="space-y-2">
          {[1,2,3,4].map(i => <div key={i} className="h-16 bg-slate-800/40 rounded-xl animate-pulse border border-slate-700/30" />)}
        </div>
      ) : employees?.length ? (
        <div className="space-y-2">
          {employees.map((emp, i) => {
            const isSel = selected.has(emp.employee_id);
            const hasCrit = (emp.critical||0) > 0;
            const init = (emp.employee_name||'?').split(' ').map(n=>n[0]).join('').toUpperCase().slice(0,2);
            return (
              <div key={emp.employee_id ?? i}
                className={`flex items-center gap-3 p-3 rounded-xl border transition-all cursor-pointer
                  ${isSel ? 'border-indigo-500/50 bg-indigo-950/30' : hasCrit ? 'border-red-500/20 bg-red-950/20 hover:bg-red-950/30' : 'border-slate-700/40 bg-slate-800/40 hover:bg-slate-700/40'}`}>
                <div onClick={() => toggleSelect(emp.employee_id)} className="shrink-0">
                  {isSel ? <CheckSquare size={16} className="text-indigo-400" /> : <Square size={16} className="text-slate-500" />}
                </div>
                <div onClick={() => setViewEmp(emp)} className="flex items-center gap-3 flex-1 min-w-0">
                  <div className={`w-9 h-9 rounded-xl flex items-center justify-center text-sm font-black text-white shrink-0
                    ${hasCrit ? 'bg-gradient-to-br from-red-500 to-pink-600' : 'bg-gradient-to-br from-indigo-500 to-purple-600'}`}>
                    {init}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="font-semibold text-white text-sm truncate">{emp.employee_name || 'Unknown'}</div>
                    <div className="text-xs text-slate-400 truncate capitalize">{emp.employee_role}</div>
                  </div>
                  <span className="text-xs text-slate-500 hidden sm:block w-28 text-center">{emp.department || '—'}</span>
                  <div className="flex gap-1.5 w-20 justify-center">
                    {(emp.critical||0)>0 && <SeverityBadge s="critical" count={emp.critical} />}
                    {(emp.warning||0)>0  && <SeverityBadge s="warning"  count={emp.warning} />}
                  </div>
                </div>
                <button onClick={() => setViewEmp(emp)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-bold text-white shrink-0 transition-all
                    ${hasCrit ? 'bg-red-600 hover:bg-red-500' : 'bg-indigo-600 hover:bg-indigo-500'}`}>
                  View →
                </button>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="flex flex-col items-center py-16 bg-slate-800/40 rounded-2xl border border-slate-700/30">
          <CheckCircle2 size={40} className="text-emerald-500 mb-3" />
          <p className="text-white font-bold">No Problems Found</p>
          <p className="text-slate-400 text-sm mt-1">All records look clean with current filters.</p>
        </div>
      )}
    </div>
  );
}
