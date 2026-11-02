import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Plus, GitBranch, CheckCircle2, XCircle, Clock, Trash2, ChevronDown, ChevronRight, ArrowRight, ThumbsUp, ThumbsDown } from 'lucide-react';
import api from '../../api/axios';

const ACTION_TYPES = [
  'delete_tenant','delete_apartment','update_contract','update_rent','export_financial',
  'bulk_operation','permission_change','access_building','approve_payment'
];

// ── Chain Flow Diagram ─────────────────────────────────────────────────────────
const ChainFlow = ({ chain }) => {
  return (
    <div className="flex flex-wrap items-center gap-2 mt-3">
      <div className="bg-blue-500/20 border border-blue-500/30 rounded-lg px-3 py-1.5 text-xs text-blue-400 font-semibold">Requester</div>
      {(chain.steps || []).map((step, i) => (
        <React.Fragment key={step.id}>
          <ArrowRight size={14} className="text-slate-500" />
          <div className="bg-indigo-500/20 border border-indigo-500/30 rounded-lg px-3 py-1.5 text-xs text-indigo-300 font-medium">
            {step.step_label} <span className="text-slate-500">({step.approver_role || 'Specific User'})</span>
          </div>
        </React.Fragment>
      ))}
      <ArrowRight size={14} className="text-slate-500" />
      <div className="bg-emerald-500/20 border border-emerald-500/30 rounded-lg px-3 py-1.5 text-xs text-emerald-400 font-semibold">✅ Done</div>
    </div>
  );
};

// ── Create Chain Modal ─────────────────────────────────────────────────────────
const CreateChainForm = ({ onClose, onCreated }) => {
  const [form, setForm] = useState({ name:'', action_type:'', description:'', steps:[] });
  const mut = useMutation({ mutationFn: () => api.post('/approvals/chains', form), onSuccess: onCreated });

  const addStep = () => setForm(f => ({ ...f, steps: [...f.steps, { step_label:'', approver_role:'manager', can_reject:1 }] }));
  const removeStep = i => setForm(f => ({ ...f, steps: f.steps.filter((_,idx)=>idx!==i) }));
  const updateStep = (i, key, val) => setForm(f => { const s = [...f.steps]; s[i]={...s[i],[key]:val}; return {...f,steps:s}; });

  return (
    <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50 p-4">
      <div className="bg-slate-800 border border-slate-700 rounded-2xl w-full max-w-xl shadow-2xl">
        <div className="flex items-center justify-between p-5 border-b border-slate-700/50">
          <h3 className="font-bold text-white flex items-center gap-2"><GitBranch size={18} className="text-indigo-400" />Create Approval Chain</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-white"><XCircle size={20} /></button>
        </div>
        <div className="p-5 space-y-4">
          <input type="text" placeholder="Chain name" value={form.name} onChange={e => setForm(f=>({...f,name:e.target.value}))}
            className="w-full bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500" />
          <select value={form.action_type} onChange={e => setForm(f=>({...f,action_type:e.target.value}))}
            className="w-full bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500">
            <option value="">Select action type…</option>
            {ACTION_TYPES.map(t => <option key={t} value={t}>{t.replace(/_/g,' ')}</option>)}
          </select>
          <textarea placeholder="Description…" rows={2} value={form.description} onChange={e => setForm(f=>({...f,description:e.target.value}))}
            className="w-full bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 resize-none" />

          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Approval Steps</p>
              <button onClick={addStep} className="flex items-center gap-1 text-xs text-indigo-400 hover:text-indigo-300">
                <Plus size={12} />Add Step
              </button>
            </div>
            {form.steps.map((step, i) => (
              <div key={i} className="flex gap-2 items-center bg-slate-900/50 rounded-xl p-2">
                <span className="text-xs text-slate-500 w-4">{i+1}.</span>
                <input type="text" placeholder="Step label" value={step.step_label} onChange={e => updateStep(i,'step_label',e.target.value)}
                  className="flex-1 bg-slate-700 border border-slate-600 text-white rounded-lg px-2 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500" />
                <select value={step.approver_role} onChange={e => updateStep(i,'approver_role',e.target.value)}
                  className="bg-slate-700 border border-slate-600 text-white rounded-lg px-2 py-1.5 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500">
                  <option value="manager">Manager</option>
                  <option value="admin">Admin</option>
                  <option value="cashier">Cashier</option>
                </select>
                <button onClick={() => removeStep(i)} className="text-red-400 hover:text-red-300 p-1"><Trash2 size={12} /></button>
              </div>
            ))}
            {form.steps.length === 0 && <p className="text-xs text-slate-600 text-center py-2">Add at least one step</p>}
          </div>
        </div>
        <div className="flex gap-2 justify-end px-5 pb-5">
          <button onClick={onClose} className="px-4 py-2 bg-slate-700 hover:bg-slate-600 text-white rounded-xl text-sm">Cancel</button>
          <button onClick={() => mut.mutate()} disabled={!form.name || !form.action_type || form.steps.length === 0 || mut.isPending}
            className="px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold disabled:opacity-40">
            {mut.isPending ? 'Creating…' : 'Create Chain'}
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Request card ───────────────────────────────────────────────────────────────
const RequestCard = ({ req, onApprove, onReject, isAdmin }) => {
  const [expanded, setExpanded] = useState(false);
  const [comment, setComment]   = useState('');
  const statusCfg = {
    pending:  { bg:'bg-amber-500/20', text:'text-amber-400', label:'⏳ Pending' },
    approved: { bg:'bg-emerald-500/20', text:'text-emerald-400', label:'✅ Approved' },
    rejected: { bg:'bg-red-500/20', text:'text-red-400', label:'❌ Rejected' },
    cancelled:{ bg:'bg-slate-600/50', text:'text-slate-400', label:'Cancelled' },
  };
  const sc = statusCfg[req.status] || statusCfg.pending;
  return (
    <div className="bg-slate-800/50 border border-slate-700/40 rounded-xl overflow-hidden">
      <div className="flex items-center gap-3 p-4 cursor-pointer hover:bg-slate-700/20" onClick={() => setExpanded(!expanded)}>
        <div className="w-8 h-8 rounded-full bg-indigo-600/40 flex items-center justify-center text-indigo-300 text-xs font-bold shrink-0">
          {req.requester_name?.[0]?.toUpperCase()}
        </div>
        <div className="flex-1 min-w-0">
          <div className="font-semibold text-white text-sm truncate">{req.title}</div>
          <div className="text-xs text-slate-400 mt-0.5">by {req.requester_name} • {req.chain_name}</div>
        </div>
        <span className={`text-xs font-bold px-2.5 py-1 rounded-full ${sc.bg} ${sc.text} shrink-0`}>{sc.label}</span>
        {req.current_step_label && <span className="text-xs text-slate-500 hidden sm:block shrink-0">Step: {req.current_step_label}</span>}
        {expanded ? <ChevronDown size={14} className="text-slate-500 shrink-0" /> : <ChevronRight size={14} className="text-slate-500 shrink-0" />}
      </div>
      {expanded && (
        <div className="px-4 pb-4 border-t border-slate-700/30 pt-3 space-y-3">
          {req.reason && <p className="text-sm text-slate-300 bg-slate-900/40 rounded-lg p-3">📝 {req.reason}</p>}
          <div className="text-xs text-slate-500">Created: {new Date(req.created_at).toLocaleString()}</div>

          {req.status === 'pending' && isAdmin && (
            <div className="space-y-2">
              <textarea placeholder="Comment (optional)…" value={comment} onChange={e => setComment(e.target.value)} rows={2}
                className="w-full bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500 resize-none" />
              <div className="flex gap-2">
                <button onClick={() => onApprove(req.id, comment)}
                  className="flex items-center gap-1.5 px-4 py-1.5 bg-emerald-600 hover:bg-emerald-500 text-white rounded-lg text-xs font-semibold">
                  <ThumbsUp size={13} />Approve
                </button>
                <button onClick={() => onReject(req.id, comment)}
                  className="flex items-center gap-1.5 px-4 py-1.5 bg-red-600/80 hover:bg-red-500 text-white rounded-lg text-xs font-semibold">
                  <ThumbsDown size={13} />Reject
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};

// ── Main ──────────────────────────────────────────────────────────────────────
export default function AcrApprovalTab({ isAdmin, pendingCount }) {
  const queryClient = useQueryClient();
  const [view, setView]           = useState('requests'); // requests | chains | my-actions
  const [statusFilter, setStatus] = useState('pending');
  const [showCreate, setShowCreate] = useState(false);

  const { data: chains } = useQuery({ queryKey:['approval-chains'], queryFn: async () => (await api.get('/approvals/chains')).data });
  const { data: requests, isLoading } = useQuery({
    queryKey: ['approval-requests', statusFilter],
    queryFn: async () => (await api.get(`/approvals/requests?status=${statusFilter === 'all' ? '' : statusFilter}`)).data,
    refetchInterval: 15000,
  });
  const { data: myActions } = useQuery({ queryKey:['acr-my-actions'], queryFn: async () => (await api.get('/approvals/my-actions')).data, refetchInterval:15000 });

  const approveMut = useMutation({ mutationFn: ({id,c}) => api.put(`/approvals/requests/${id}/approve`, {comment:c}), onSuccess: () => queryClient.invalidateQueries(['approval-requests']) });
  const rejectMut  = useMutation({ mutationFn: ({id,c}) => api.put(`/approvals/requests/${id}/reject`, {comment:c}),  onSuccess: () => queryClient.invalidateQueries(['approval-requests']) });
  const deleteMut  = useMutation({ mutationFn: (id) => api.delete(`/approvals/chains/${id}`), onSuccess: () => queryClient.invalidateQueries(['approval-chains']) });

  return (
    <div className="space-y-4">
      {showCreate && <CreateChainForm onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); queryClient.invalidateQueries(['approval-chains']); }} />}

      {/* Sub-nav */}
      <div className="flex gap-2 flex-wrap items-center">
        {[
          { id:'requests', label:'📋 Requests' },
          { id:'my-actions', label:`⚡ My Actions ${(myActions?.length||0)>0?`(${myActions.length})` : ''}` },
          { id:'chains', label:'🔗 Chains' },
        ].map(v => (
          <button key={v.id} onClick={() => setView(v.id)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition-all ${view===v.id?'bg-indigo-600 text-white shadow-lg shadow-indigo-500/20':'bg-slate-700/60 text-slate-300 hover:bg-slate-700'}`}>
            {v.label}
          </button>
        ))}
        {view === 'chains' && isAdmin && (
          <button onClick={() => setShowCreate(true)}
            className="ml-auto flex items-center gap-2 px-4 py-2 bg-emerald-600/80 hover:bg-emerald-500 text-white rounded-xl text-sm font-semibold">
            <Plus size={15} />Create Chain
          </button>
        )}
        {view === 'requests' && (
          <div className="ml-auto flex gap-1">
            {['pending','approved','rejected','all'].map(s => (
              <button key={s} onClick={() => setStatus(s)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition-all ${statusFilter===s?'bg-slate-600 text-white':'text-slate-400 hover:text-white'}`}>
                {s}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Content */}
      {view === 'requests' && (
        <div className="space-y-2">
          {isLoading ? (
            [1,2,3].map(i => <div key={i} className="h-16 bg-slate-800/40 rounded-xl animate-pulse border border-slate-700/30" />)
          ) : requests?.length ? requests.map(r => (
            <RequestCard key={r.id} req={r} isAdmin={isAdmin}
              onApprove={(id, c) => approveMut.mutate({id, c})}
              onReject={(id, c)  => rejectMut.mutate({id, c})} />
          )) : (
            <div className="flex flex-col items-center py-12 bg-slate-800/40 rounded-2xl border border-slate-700/30">
              <CheckCircle2 size={36} className="text-emerald-500 mb-3" />
              <p className="text-slate-400">No {statusFilter} requests</p>
            </div>
          )}
        </div>
      )}

      {view === 'my-actions' && (
        <div className="space-y-2">
          {(myActions||[]).length > 0 ? myActions.map(r => (
            <RequestCard key={r.id} req={r} isAdmin={true}
              onApprove={(id, c) => approveMut.mutate({id,c})}
              onReject={(id, c)  => rejectMut.mutate({id, c})} />
          )) : (
            <div className="flex flex-col items-center py-12 bg-slate-800/40 rounded-2xl border border-slate-700/30">
              <CheckCircle2 size={36} className="text-emerald-500 mb-3" />
              <p className="text-slate-400">No actions waiting for you</p>
            </div>
          )}
        </div>
      )}

      {view === 'chains' && (
        <div className="space-y-3">
          {(chains||[]).map(chain => (
            <ChainDetail key={chain.id} chain={chain} isAdmin={isAdmin} onDelete={() => deleteMut.mutate(chain.id)} />
          ))}
          {!chains?.length && (
            <div className="flex flex-col items-center py-12 bg-slate-800/40 rounded-2xl border border-slate-700/30">
              <GitBranch size={36} className="text-slate-600 mb-3" />
              <p className="text-slate-400">No approval chains configured</p>
              {isAdmin && <button onClick={() => setShowCreate(true)} className="mt-3 px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl text-sm font-semibold">Create First Chain</button>}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function ChainDetail({ chain, onDelete, isAdmin }) {
  const [exp, setExp] = useState(false);
  const { data: detail } = useQuery({ queryKey:['chain-detail', chain.id], queryFn: async () => (await api.get(`/approvals/chains/${chain.id}`)).data, enabled: exp });
  return (
    <div className="bg-slate-800/50 border border-slate-700/40 rounded-xl overflow-hidden">
      <div className="flex items-center gap-3 p-4 cursor-pointer hover:bg-slate-700/20" onClick={() => setExp(!exp)}>
        <GitBranch size={16} className="text-indigo-400 shrink-0" />
        <div className="flex-1 min-w-0">
          <div className="font-semibold text-white text-sm">{chain.name}</div>
          <div className="text-xs text-slate-400">{chain.action_type?.replace(/_/g,' ')} • {chain.step_count} steps</div>
        </div>
        <span className={`text-xs px-2 py-0.5 rounded-full font-semibold ${chain.is_active ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-600/50 text-slate-500'}`}>
          {chain.is_active ? 'Active' : 'Inactive'}
        </span>
        {isAdmin && <button onClick={e=>{e.stopPropagation();onDelete();}} className="p-1 text-red-400 hover:text-red-300"><Trash2 size={13} /></button>}
      </div>
      {exp && detail && <div className="px-4 pb-4 border-t border-slate-700/30 pt-3"><ChainFlow chain={detail} /></div>}
    </div>
  );
}

