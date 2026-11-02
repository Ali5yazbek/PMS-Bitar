import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, Shield, Eye, EyeOff, Edit, Edit2, ToggleLeft, ToggleRight, Clock, Plus, Trash2 } from 'lucide-react';
import api from '../../api/axios';
import MenuBuilder from './MenuBuilder';

const ROLES = ['admin','manager','cashier','agent','maintenance','tenant'];

const PAGE_ACTIONS = ['can_view','can_add','can_edit','can_delete','can_print','can_export','can_approve'];
const ACTION_LABELS = { can_view:'View', can_add:'Add', can_edit:'Edit', can_delete:'Delete', can_print:'Print', can_export:'Export', can_approve:'Approve' };

const ENTITIES = [
  { key:'tenants',    label:'Tenants',    fields:['full_name','national_id','phone','email','passport_number','passport_expiry','date_of_birth','notes','contract_file'] },
  { key:'apartments', label:'Apartments', fields:['code','apartment_number','floor','monthly_rent','owner_id','status','notes'] },
  { key:'contracts',  label:'Contracts',  fields:['start_date','end_date','rent_amount','deposit','contract_file','payment_method','notes'] },
  { key:'workshops',  label:'Workshops',  fields:['name','license_number','license_expiry','vat_number','manager_name','phone','email'] },
];

const Toggle = ({ value, onChange, color = 'indigo' }) => {
  const colors = { indigo:'bg-indigo-600', emerald:'bg-emerald-600', amber:'bg-amber-600' };
  return (
    <div onClick={onChange} className={`w-9 h-5 rounded-full cursor-pointer transition-colors relative shrink-0 ${value ? colors[color] : 'bg-slate-600'}`}>
      <div className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-transform ${value ? 'translate-x-4' : ''}`} />
    </div>
  );
};

// ── Page Permissions ──────────────────────────────────────────────────────────
const PagePermSection = ({ role, data, onChange, onRowChange, onSave, saving, globalMenus }) => {
  const pageMap = {};
  (data || []).forEach(p => { pageMap[p.page_key] = p; });

  return (
    <div>
      <div className="overflow-x-auto rounded-xl border border-slate-700/50">
        <table className="w-full text-xs">
          <thead className="bg-slate-800/80">
            <tr>
              <th className="text-left px-4 py-3 text-slate-400 font-semibold min-w-[140px]">Page</th>
              {PAGE_ACTIONS.map(a => (
                <th key={a} className="text-center px-2 py-3 text-slate-400 font-semibold whitespace-nowrap">{ACTION_LABELS[a]}</th>
              ))}
              <th className="text-center px-2 py-3 text-slate-400 font-semibold border-l border-slate-700/50">All</th>
            </tr>
          </thead>
          <tbody>
            {globalMenus.filter(m => m.path !== '#').map((page, i) => {
              const perm = pageMap[page.menu_key] || {};
              const allOn = PAGE_ACTIONS.every(a => Number(perm[a]) === 1);
              return (
                <tr key={page.menu_key} className={`border-t border-slate-700/30 ${i % 2 === 0 ? 'bg-slate-800/20' : ''} hover:bg-slate-700/20 transition-colors`}>
                  <td className="px-4 py-2.5 text-slate-200 font-medium">{page.label}</td>
                  {PAGE_ACTIONS.map(a => (
                    <td key={a} className="text-center px-2 py-2.5">
                      <div className="flex justify-center">
                        <Toggle
                          value={Number(perm[a]) === 1}
                          onChange={() => onChange(page.menu_key, a, Number(perm[a]) !== 1)}
                          color={a === 'can_delete' ? 'amber' : a === 'can_approve' ? 'emerald' : 'indigo'}
                        />
                      </div>
                    </td>
                  ))}
                  <td className="text-center px-2 py-2.5 bg-slate-900/30 border-l border-slate-700/50">
                    <div className="flex justify-center" title={allOn ? "Turn all off" : "Turn all on"}>
                      <Toggle
                        value={allOn}
                        onChange={() => onRowChange(page.menu_key, !allOn)}
                        color="emerald"
                      />
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
      <button onClick={onSave} disabled={saving}
        className="mt-4 flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition-all disabled:opacity-50">
        <Save size={15} />{saving ? 'Saving…' : 'Save Page Permissions'}
      </button>
    </div>
  );
};

// ── Field Permissions ─────────────────────────────────────────────────────────
const FieldPermSection = ({ role, data, onChange, onSave, saving }) => {
  const [entity, setEntity] = useState('tenants');
  const entityConfig = ENTITIES.find(e => e.key === entity);
  const fieldMap = {};
  (data || []).filter(f => f.entity === entity).forEach(f => { fieldMap[f.field_name] = f; });

  return (
    <div className="space-y-4">
      <div className="flex gap-2 flex-wrap">
        {ENTITIES.map(e => (
          <button key={e.key} onClick={() => setEntity(e.key)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${entity === e.key ? 'bg-indigo-600 text-white' : 'bg-slate-700/60 text-slate-300 hover:bg-slate-700'}`}>
            {e.label}
          </button>
        ))}
      </div>
      <div className="space-y-2">
        {entityConfig?.fields.map(field => {
          const fp = fieldMap[field] || { is_visible: 0, is_editable: 0 };
          return (
            <div key={field} className="flex items-center gap-4 px-4 py-3 rounded-xl bg-slate-800/40 border border-slate-700/30 hover:bg-slate-700/30 transition-colors">
              <span className="text-slate-200 text-sm font-medium flex-1 capitalize">{field.replace(/_/g,' ')}</span>
              <div className="flex items-center gap-3">
                <label className="flex items-center gap-2 text-xs text-slate-400 cursor-pointer">
                  <Toggle value={Number(fp.is_visible) === 1} onChange={() => onChange(entity, field, 'is_visible', Number(fp.is_visible) !== 1)} />
                  <Eye size={13} />Visible
                </label>
                <label className={`flex items-center gap-2 text-xs cursor-pointer ${Number(fp.is_visible) === 1 ? 'text-slate-400' : 'text-slate-600 opacity-50'}`}>
                  <Toggle value={Number(fp.is_editable) === 1 && Number(fp.is_visible) === 1} onChange={() => Number(fp.is_visible) === 1 && onChange(entity, field, 'is_editable', Number(fp.is_editable) !== 1)} color="emerald" />
                  <Edit size={13} />Editable
                </label>
              </div>
            </div>
          );
        })}
      </div>
      <button onClick={onSave} disabled={saving}
        className="flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition-all disabled:opacity-50">
        <Save size={15} />{saving ? 'Saving…' : 'Save Field Permissions'}
      </button>
    </div>
  );
};

// ── Menu Permissions ──────────────────────────────────────────────────────────
const MenuPermSection = ({ role, data, onChange, onSave, saving, globalMenus }) => {
  const menuMap = {};
  (data || []).forEach(m => { menuMap[m.menu_key] = m; });
  return (
    <div className="space-y-3">
      {globalMenus.map(item => {
        const mp = menuMap[item.menu_key] || { is_visible: 0 };
        return (
          <div key={item.menu_key} className="flex items-center gap-4 px-4 py-3 rounded-xl bg-slate-800/40 border border-slate-700/30">
            <span className="text-slate-200 flex-1">{item.label}</span>
            <Toggle value={Number(mp.is_visible) === 1} onChange={() => onChange(item.menu_key, Number(mp.is_visible) !== 1)} />
            <span className={`text-xs font-semibold ${Number(mp.is_visible) === 1 ? 'text-emerald-400' : 'text-slate-500'}`}>{Number(mp.is_visible) === 1 ? '✓ Visible' : '✗ Hidden'}</span>
          </div>
        );
      })}
      <button onClick={onSave} disabled={saving}
        className="flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold transition-all disabled:opacity-50">
        <Save size={15} />{saving ? 'Saving…' : 'Save Menu Permissions'}
      </button>
    </div>
  );
};

// ── Temp Permissions ──────────────────────────────────────────────────────────
const TempPermSection = () => {
  const queryClient = useQueryClient();
  const [form, setForm] = useState({ user_id:'', permission_type:'', expires_at:'', reason:'' });
  const { data: temps } = useQuery({ queryKey:['acr-temp-perms'], queryFn: async () => (await api.get('/permissions/temp')).data });
  const { data: users } = useQuery({ queryKey:['users-list'], queryFn: async () => (await api.get('/users')).data });

  const grantMutation = useMutation({
    mutationFn: () => api.post('/permissions/temp', form),
    onSuccess: () => { queryClient.invalidateQueries(['acr-temp-perms']); setForm({ user_id:'', permission_type:'', expires_at:'', reason:'' }); }
  });
  const revokeMutation = useMutation({
    mutationFn: (id) => api.delete(`/permissions/temp/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['acr-temp-perms']),
  });

  return (
    <div className="space-y-5">
      <div className="bg-amber-950/30 border border-amber-500/20 rounded-2xl p-5 space-y-3">
        <p className="text-xs font-bold text-amber-400 uppercase tracking-wider flex items-center gap-2"><Clock size={14} />Grant Temporary Permission</p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <select value={form.user_id} onChange={e => setForm(f=>({...f,user_id:e.target.value}))}
            className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-500">
            <option value="">Select User</option>
            {(users||[]).map(u => <option key={u.id} value={u.id}>{u.name} ({u.role})</option>)}
          </select>
          <input type="text" placeholder="Permission type (e.g. edit_contracts)" value={form.permission_type}
            onChange={e => setForm(f=>({...f,permission_type:e.target.value}))}
            className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-500" />
          <input type="datetime-local" value={form.expires_at} onChange={e => setForm(f=>({...f,expires_at:e.target.value}))}
            className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-500" />
          <input type="text" placeholder="Reason for granting…" value={form.reason} onChange={e => setForm(f=>({...f,reason:e.target.value}))}
            className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-amber-500" />
        </div>
        <button onClick={() => grantMutation.mutate()} disabled={!form.user_id || !form.permission_type || !form.expires_at}
          className="flex items-center gap-2 px-5 py-2 bg-amber-600 hover:bg-amber-500 text-white rounded-xl text-sm font-semibold disabled:opacity-40">
          <Plus size={15} />Grant Temp Permission
        </button>
      </div>
      <div className="space-y-2">
        {(temps||[]).map(t => (
          <div key={t.id} className="flex items-center gap-3 p-3 bg-slate-800/40 rounded-xl border border-slate-700/30">
            <div className="flex-1 min-w-0">
              <div className="text-sm text-white font-medium">{t.user_name}</div>
              <div className="text-xs text-slate-400">{t.permission_type} • Expires: {new Date(t.expires_at).toLocaleString()}</div>
              {t.reason && <div className="text-xs text-slate-500 mt-0.5">Reason: {t.reason}</div>}
            </div>
            <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${t.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-600/50 text-slate-500'}`}>
              {t.is_active ? 'Active' : 'Revoked'}
            </span>
            {t.is_active && (
              <button onClick={() => revokeMutation.mutate(t.id)}
                className="p-1.5 text-red-400 hover:text-red-300 hover:bg-red-950/30 rounded-lg transition-colors">
                <Trash2 size={14} />
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};

// ── Main ──────────────────────────────────────────────────────────────────────
const SUB_TABS = [
  { id:'pages',  label:'📋 Page Permissions' },
  { id:'fields', label:'🔍 Field Permissions' },
  { id:'menu',   label:'📌 Menu Permissions' },
  { id:'temp',   label:'⏱️ Temp Permissions' },
  { id:'builder',label:'🛠️ Menu Builder' },
];

export default function AcrPermissionTab() {
  const queryClient = useQueryClient();
  const [role,   setRole]   = useState('manager');
  const [subTab, setSubTab] = useState('pages');
  const [localPages, setLocalPages]  = useState({});
  const [localFields, setLocalFields] = useState({});
  const [localMenu, setLocalMenu]    = useState({});

  const { data: pageData }  = useQuery({ queryKey:['perm-pages',role],  queryFn: async () => (await api.get(`/permissions/pages?role=${role}`)).data });
  const { data: fieldData } = useQuery({ queryKey:['perm-fields',role], queryFn: async () => (await api.get(`/permissions/fields?role=${role}`)).data });
  const { data: menuData }  = useQuery({ queryKey:['perm-menu',role],   queryFn: async () => (await api.get(`/permissions/menu?role=${role}`)).data });
  const { data: globalMenus } = useQuery({ queryKey:['global-menus'], queryFn: async () => (await api.get('/permissions/global-menus')).data });

  const merged = (remote, local) => {
    const map = {}; 
    (remote||[]).forEach(r => { 
      const k = r.page_key || (r.entity ? `${r.entity}__${r.field_name}` : r.menu_key);
      if (k) map[k] = r; 
    });
    Object.entries(local||{}).forEach(([k,v]) => { map[k] = {...(map[k]||{}), ...v}; });
    return Object.values(map);
  };

  const pageMutation  = useMutation({ mutationFn: (body) => api.put('/permissions/pages', body), onSuccess: () => queryClient.invalidateQueries(['perm-pages',role]) });
  const fieldMutation = useMutation({ mutationFn: (body) => api.put('/permissions/fields', body), onSuccess: () => queryClient.invalidateQueries(['perm-fields',role]) });
  const menuMutation  = useMutation({ mutationFn: (body) => api.put('/permissions/menu', body), onSuccess: () => queryClient.invalidateQueries(['perm-menu',role]) });

  const handlePageChange = (pageKey, action, value) => {
    setLocalPages(p => {
      const remote = (pageData||[]).find(x => x.page_key === pageKey) || {};
      return { ...p, [pageKey]: { ...remote, ...(p[pageKey]||{}), role, page_key:pageKey, [action]:value?1:0 } };
    });
  };
  const handlePageRowChange = (pageKey, value) => {
    setLocalPages(p => {
      const remote = (pageData||[]).find(x => x.page_key === pageKey) || {};
      const newPerms = {};
      PAGE_ACTIONS.forEach(a => newPerms[a] = value ? 1 : 0);
      return { ...p, [pageKey]: { ...remote, ...(p[pageKey]||{}), role, page_key:pageKey, ...newPerms } };
    });
  };
  const handleFieldChange = (entity, field, attr, value) => {
    const k = `${entity}__${field}`;
    setLocalFields(p => {
      const remote = (fieldData||[]).find(x => x.entity === entity && x.field_name === field) || {};
      return { ...p, [k]: { ...remote, ...(p[k]||{}), role, entity, field_name:field, [attr]:value?1:0 } };
    });
  };
  const handleMenuChange = (menuKey, value) => {
    setLocalMenu(p => {
      const remote = (menuData||[]).find(x => x.menu_key === menuKey) || {};
      return { ...p, [menuKey]: { ...remote, ...(p[menuKey]||{}), role, menu_key:menuKey, is_visible:value?1:0 } };
    });
  };

  const savePages  = () => pageMutation.mutate(Object.values({ ...(pageData||[]).reduce((a,p)=>{a[p.page_key]=p;return a;},{}), ...localPages }));
  const saveFields = () => fieldMutation.mutate(Object.values({ ...(fieldData||[]).reduce((a,f)=>{a[`${f.entity}__${f.field_name}`]=f;return a;},{}), ...localFields }));
  const saveMenu   = () => menuMutation.mutate(Object.values({ ...(menuData||[]).reduce((a,m)=>{a[m.menu_key]=m;return a;},{}), ...localMenu }));

  return (
    <div className="space-y-4">
      {/* Role selector */}
      <div className="flex items-center gap-3 bg-slate-800/60 border border-slate-700/50 rounded-2xl p-4 flex-wrap">
        <Shield size={18} className="text-indigo-400 shrink-0" />
        <span className="text-sm font-semibold text-slate-300">Configure permissions for role:</span>
        <div className="flex gap-2 flex-wrap">
          {ROLES.map(r => (
            <button key={r} onClick={() => { setRole(r); setLocalPages({}); setLocalFields({}); setLocalMenu({}); }}
              className={`px-4 py-1.5 rounded-xl text-sm font-semibold capitalize transition-all
                ${role === r ? 'bg-indigo-600 text-white shadow-lg shadow-indigo-500/30' : 'bg-slate-700/60 text-slate-300 hover:bg-slate-700'}`}>
              {r}
            </button>
          ))}
        </div>
      </div>

      {/* Sub-tabs */}
      <div className="flex gap-1 bg-slate-900/40 border border-slate-700/40 rounded-xl p-1.5 flex-wrap">
        {SUB_TABS.map(st => (
          <button key={st.id} onClick={() => setSubTab(st.id)}
            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${subTab === st.id ? 'bg-slate-700 text-white' : 'text-slate-400 hover:text-white'}`}>
            {st.label}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="bg-slate-800/40 border border-slate-700/40 rounded-2xl p-5">
        {subTab === 'pages'  && <PagePermSection  role={role} data={merged(pageData, localPages)}  onChange={handlePageChange} onRowChange={handlePageRowChange} onSave={savePages}  saving={pageMutation.isPending} globalMenus={globalMenus || []} />}
        {subTab === 'fields' && <FieldPermSection role={role} data={merged(fieldData, localFields)} onChange={handleFieldChange} onSave={saveFields} saving={fieldMutation.isPending} />}
        {subTab === 'menu'   && <MenuPermSection  role={role} data={merged(menuData, localMenu)}  onChange={handleMenuChange}  onSave={saveMenu}   saving={menuMutation.isPending} globalMenus={globalMenus || []} />}
        {subTab === 'temp'   && <TempPermSection />}
        {subTab === 'builder' && <MenuBuilder />}
      </div>
    </div>
  );
}
