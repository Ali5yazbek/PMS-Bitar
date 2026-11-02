import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, Grid3X3, CheckCircle2, XCircle } from 'lucide-react';
import api from '../../api/axios';

const ROLES = ['admin','manager','cashier','agent','maintenance'];

const MATRIX_ROWS = [
  { group:'Dashboard',   rows:[ ['dashboard','view'],['dashboard','edit'] ] },
  { group:'Tenants',     rows:[ ['tenants','view'],['tenants','add'],['tenants','edit'],['tenants','delete'],['tenants','print'],['tenants','export'] ] },
  { group:'Apartments',  rows:[ ['apartments','view'],['apartments','add'],['apartments','edit'],['apartments','delete'],['apartments','export'] ] },
  { group:'Contracts',   rows:[ ['contracts','view'],['contracts','add'],['contracts','edit'],['contracts','delete'],['contracts','print'] ] },
  { group:'Rent',        rows:[ ['rent','view'],['rent','add'],['rent','edit'] ] },
  { group:'Workshop',    rows:[ ['workshop','view'],['workshop','add'],['workshop','edit'],['workshop','delete'] ] },
  { group:'Warehouse',   rows:[ ['warehouse','view'],['warehouse','add'],['warehouse','edit'] ] },
  { group:'Accounting',  rows:[ ['expenses','view'],['expenses','add'],['expenses','edit'] ] },
  { group:'Reports',     rows:[ ['reports','view'],['reports','export'],['reports','print'] ] },
  { group:'Users',       rows:[ ['users','view'],['users','add'],['users','edit'],['users','delete'] ] },
  { group:'Settings',    rows:[ ['settings','view'],['settings','edit'] ] },
];

const ACTION_KEY_MAP = { view:'can_view', add:'can_add', edit:'can_edit', delete:'can_delete', print:'can_print', export:'can_export', approve:'can_approve' };

export default function AcrRoleMatrixTab() {
  const queryClient = useQueryClient();
  const [saving, setSaving] = useState(false);
  const [localChanges, setLocalChanges] = useState({});

  const { data: matrixData, isLoading } = useQuery({
    queryKey: ['acr-matrix'],
    queryFn: async () => (await api.get('/permissions/matrix')).data,
  });

  // Build lookup: { 'role:page:action' => boolean }
  const matrixMap = {};
  (matrixData || []).forEach(p => {
    PAGE_ACTIONS.forEach(a => {
      matrixMap[`${p.role}:${p.page_key}:${a.replace('can_','')}` ] = !!p[a];
    });
  });
  Object.entries(localChanges).forEach(([k, v]) => { matrixMap[k] = v; });

  const handleToggle = (role, page, action) => {
    const key = `${role}:${page}:${action}`;
    setLocalChanges(prev => ({ ...prev, [key]: !matrixMap[key] }));
  };

  const handleSaveAll = async () => {
    setSaving(true);
    // Rebuild full matrix from matrixMap + localChanges
    const updates = [];
    ROLES.forEach(role => {
      MATRIX_ROWS.forEach(({ rows }) => {
        rows.forEach(([page, action]) => {
          const key = `${role}:${page}:${action}`;
          const actionKey = ACTION_KEY_MAP[action] || `can_${action}`;
          // Find existing record or create
          updates.push({ role, page_key: page, [actionKey]: matrixMap[key] ? 1 : 0 });
        });
      });
    });
    // Merge updates by role+page
    const merged = {};
    updates.forEach(u => {
      const k = `${u.role}:${u.page_key}`;
      if (!merged[k]) merged[k] = { role: u.role, page_key: u.page_key };
      Object.assign(merged[k], u);
    });
    try { await api.put('/permissions/pages', Object.values(merged)); }
    catch (e) { console.error(e); }
    setLocalChanges({});
    queryClient.invalidateQueries(['acr-matrix']);
    setSaving(false);
  };

  if (isLoading) return (
    <div className="flex items-center justify-center py-20">
      <div className="w-10 h-10 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin" />
    </div>
  );

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <Grid3X3 size={20} className="text-indigo-400" />
          <h3 className="font-bold text-white">Enterprise Permission Matrix</h3>
          {Object.keys(localChanges).length > 0 && (
            <span className="bg-amber-500/20 text-amber-400 text-xs px-2 py-0.5 rounded-full border border-amber-500/20">
              {Object.keys(localChanges).length} unsaved changes
            </span>
          )}
        </div>
        <button onClick={handleSaveAll} disabled={saving}
          className="flex items-center gap-2 px-5 py-2 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg disabled:opacity-50">
          <Save size={15} />{saving ? 'Saving…' : 'Save All Changes'}
        </button>
      </div>

      {/* Matrix legend */}
      <div className="flex items-center gap-4 text-xs text-slate-400 bg-slate-800/40 rounded-xl px-4 py-2.5 border border-slate-700/30">
        <div className="flex items-center gap-1.5"><CheckCircle2 size={14} className="text-emerald-400" /><span>Allowed</span></div>
        <div className="flex items-center gap-1.5"><XCircle size={14} className="text-red-400" /><span>Denied</span></div>
        <span className="ml-2 text-slate-500">Click any cell to toggle. Save when done.</span>
      </div>

      <div className="overflow-x-auto rounded-2xl border border-slate-700/50 shadow-xl">
        <table className="w-full text-xs">
          <thead className="bg-gradient-to-r from-slate-800 to-slate-900 sticky top-0 z-10">
            <tr>
              <th className="text-left px-4 py-4 text-slate-300 font-bold min-w-[160px] rounded-tl-2xl">Page / Action</th>
              {ROLES.map((role, i) => (
                <th key={role} className={`text-center px-3 py-4 font-bold capitalize min-w-[80px] ${i === ROLES.length - 1 ? 'rounded-tr-2xl' : ''}`}>
                  <div className={`inline-block px-2.5 py-1 rounded-lg text-xs font-bold
                    ${{admin:'bg-red-500/20 text-red-300', manager:'bg-blue-500/20 text-blue-300', cashier:'bg-green-500/20 text-green-300', agent:'bg-yellow-500/20 text-yellow-300', maintenance:'bg-purple-500/20 text-purple-300'}[role] || 'bg-slate-600/50 text-slate-300'}`}>
                    {role}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {MATRIX_ROWS.map(({ group, rows }) => (
              <React.Fragment key={group}>
                <tr className="bg-slate-900/60">
                  <td colSpan={ROLES.length + 1} className="px-4 py-2 text-indigo-400 font-bold text-[11px] uppercase tracking-wider">
                    {group}
                  </td>
                </tr>
                {rows.map(([page, action], ri) => (
                  <tr key={`${page}:${action}`} className={`border-t border-slate-800/50 ${ri%2===0?'bg-slate-800/10':''} hover:bg-slate-700/20 transition-colors`}>
                    <td className="px-4 py-2.5 text-slate-400 pl-6 capitalize">{action}</td>
                    {ROLES.map(role => {
                      const key = `${role}:${page}:${action}`;
                      const allowed = matrixMap[key];
                      const changed = key in localChanges;
                      return (
                        <td key={role} className="text-center px-3 py-2.5">
                          <button onClick={() => handleToggle(role, page, action)}
                            className={`w-8 h-8 rounded-lg flex items-center justify-center mx-auto transition-all
                              ${changed ? 'ring-2 ring-amber-500/50' : ''}
                              ${allowed
                                ? 'bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-400'
                                : 'bg-slate-700/50 hover:bg-red-500/10 text-slate-600 hover:text-red-400'
                              }`}>
                            {allowed ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                          </button>
                        </td>
                      );
                    })}
                  </tr>
                ))}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

// Need PAGE_ACTIONS for local use
const PAGE_ACTIONS = ['can_view','can_add','can_edit','can_delete','can_print','can_export','can_approve'];
