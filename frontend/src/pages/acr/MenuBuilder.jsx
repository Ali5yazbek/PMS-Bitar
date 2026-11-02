import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Save, Plus, Trash2, GripVertical, Folder, Link } from 'lucide-react';
import api from '../../api/axios';

export default function MenuBuilder() {
  const queryClient = useQueryClient();
  const { data: menus, isLoading } = useQuery({ 
    queryKey: ['global-menus'], 
    queryFn: async () => (await api.get('/permissions/global-menus')).data 
  });

  const [form, setForm] = useState({ menu_key:'', label:'', path:'', icon:'', parent_key:'' });
  
  const reorderMutation = useMutation({
    mutationFn: (body) => api.post('/permissions/global-menus/reorder', body),
    onSuccess: () => queryClient.invalidateQueries(['global-menus'])
  });

  const createMutation = useMutation({
    mutationFn: (body) => api.post('/permissions/global-menus', body),
    onSuccess: () => {
      queryClient.invalidateQueries(['global-menus']);
      setForm({ menu_key:'', label:'', path:'', icon:'', parent_key:'' });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/permissions/global-menus/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['global-menus'])
  });

  const [draggedIdx, setDraggedIdx] = useState(null);

  if (isLoading) return <div className="text-slate-400 p-5">Loading menus...</div>;

  const items = [...(menus || [])];
  
  const handleDragStart = (e, index) => {
    setDraggedIdx(index);
    e.dataTransfer.effectAllowed = 'move';
  };

  const handleDragOver = (e, index) => {
    e.preventDefault();
  };

  const handleDrop = (e, targetIdx) => {
    e.preventDefault();
    if (draggedIdx === null || draggedIdx === targetIdx) return;
    
    const newItems = [...items];
    const [draggedItem] = newItems.splice(draggedIdx, 1);
    newItems.splice(targetIdx, 0, draggedItem);
    
    // Update sort orders
    const payload = newItems.map((item, idx) => ({
      id: item.id,
      parent_key: item.parent_key,
      sort_order: (idx + 1) * 10
    }));
    
    reorderMutation.mutate(payload);
    setDraggedIdx(null);
  };

  return (
    <div className="space-y-6">
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5 space-y-4">
        <h3 className="text-sm font-bold text-slate-200 flex items-center gap-2">
          <Folder size={16} className="text-indigo-400"/> Create Custom Menu
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-5 gap-3">
          <input type="text" placeholder="Key (e.g. custom_link)" value={form.menu_key} onChange={e=>setForm(f=>({...f,menu_key:e.target.value}))} className="bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white" />
          <input type="text" placeholder="Label (e.g. My Link)" value={form.label} onChange={e=>setForm(f=>({...f,label:e.target.value}))} className="bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white" />
          <input type="text" placeholder="Path (e.g. /custom)" value={form.path} onChange={e=>setForm(f=>({...f,path:e.target.value}))} className="bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white" />
          <select value={form.parent_key} onChange={e=>setForm(f=>({...f,parent_key:e.target.value}))} className="bg-slate-900 border border-slate-700 rounded-xl px-3 py-2 text-sm text-white">
            <option value="">No Parent (Root)</option>
            {items.filter(i => i.path === '#').map(i => <option key={i.menu_key} value={i.menu_key}>{i.label}</option>)}
          </select>
          <button onClick={() => createMutation.mutate(form)} disabled={!form.menu_key || !form.label || !form.path} className="bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl px-4 py-2 text-sm font-semibold flex items-center justify-center gap-2 disabled:opacity-50">
            <Plus size={16} /> Add Menu
          </button>
        </div>
      </div>

      <div className="space-y-2">
        <p className="text-xs text-slate-400 font-medium mb-3">Drag and drop to reorder. Changes save automatically.</p>
        {items.map((item, idx) => (
          <div 
            key={item.id}
            draggable
            onDragStart={(e) => handleDragStart(e, idx)}
            onDragOver={(e) => handleDragOver(e, idx)}
            onDrop={(e) => handleDrop(e, idx)}
            className={`flex items-center gap-4 px-4 py-3 rounded-xl border transition-all cursor-move
              ${draggedIdx === idx ? 'bg-indigo-900/40 border-indigo-500/50 scale-[1.02]' : 'bg-slate-800/40 border-slate-700/30 hover:bg-slate-700/40'}`}
          >
            <GripVertical size={16} className="text-slate-500" />
            <div className="flex-1">
              <div className="text-sm font-medium text-slate-200 flex items-center gap-2">
                {item.path === '#' ? <Folder size={14} className="text-amber-400"/> : <Link size={14} className="text-indigo-400"/>}
                {item.label}
              </div>
              <div className="text-xs text-slate-500 font-mono mt-0.5">{item.path} • {item.parent_key ? `Parent: ${item.parent_key}` : 'Root'}</div>
            </div>
            {!!item.is_custom && (
              <button onClick={() => deleteMutation.mutate(item.id)} className="p-2 text-red-400 hover:bg-red-950/30 rounded-lg">
                <Trash2 size={16} />
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
