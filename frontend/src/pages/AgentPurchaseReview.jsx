import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import {
  ShoppingCart, Building2, Home, Check, X, Clock, CheckCircle,
  AlertCircle, FileText, Package, User, RefreshCw,
  XCircle, ChevronRight, History,
} from 'lucide-react';
import { useNavigate } from 'react-router-dom';

// ─── Status Badge ──────────────────────────────────────────────────────────────
const StatusBadge = ({ status }) => {
  const cfg = {
    Pending:  { cls: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30', icon: Clock,       label: 'Pending Review' },
    Accepted: { cls: 'bg-green-500/20  text-green-400  border-green-500/30',  icon: CheckCircle, label: 'Accepted' },
    Rejected: { cls: 'bg-red-500/20    text-red-400    border-red-500/30',    icon: XCircle,     label: 'Rejected' },
  };
  const c = cfg[status] || cfg['Pending'];
  const Icon = c.icon;
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-xs font-semibold ${c.cls}`}>
      <Icon size={12} /> {c.label}
    </span>
  );
};

// ─── Receipt Preview ───────────────────────────────────────────────────────────
const ReceiptPreview = ({ src }) => {
  const [zoomed, setZoomed] = useState(false);
  if (!src) return <span className="text-slate-600 text-sm">No receipt</span>;
  const baseUrl = (axios.defaults.baseURL || '').replace('/api', '');
  const fullUrl = src.startsWith('http') ? src : `${baseUrl}/${src}`;
  const isPdf = src.toLowerCase().endsWith('.pdf');

  return (
    <>
      {isPdf ? (
        <a href={fullUrl} target="_blank" rel="noreferrer"
          className="inline-flex items-center gap-2 px-3 py-1.5 bg-indigo-500/20 text-indigo-400 rounded-lg text-sm hover:bg-indigo-500/30 transition-colors">
          <FileText size={14} /> View PDF
        </a>
      ) : (
        <>
          <button onClick={() => setZoomed(true)} type="button">
            <img src={fullUrl} alt="Receipt"
              className="w-20 h-20 object-cover rounded-xl border border-slate-600 hover:scale-105 transition-transform cursor-zoom-in shadow-lg" />
          </button>
          {zoomed && (
            <div
              className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm"
              onClick={() => setZoomed(false)}>
              <div className="relative max-w-2xl max-h-[90vh]" onClick={e => e.stopPropagation()}>
                <img src={fullUrl} alt="Receipt full" className="max-w-full max-h-[85vh] rounded-2xl shadow-2xl border border-slate-700" />
                <button
                  onClick={() => setZoomed(false)}
                  className="absolute -top-3 -right-3 w-8 h-8 bg-red-500 rounded-full flex items-center justify-center text-white hover:bg-red-600 transition-colors shadow-lg">
                  <X size={16} />
                </button>
              </div>
            </div>
          )}
        </>
      )}
    </>
  );
};

// ─── Reject Modal ──────────────────────────────────────────────────────────────
const RejectModal = ({ purchase, onClose, onReject, isLoading }) => {
  const [reason, setReason] = useState('');
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm p-4">
      <div className="glass-card rounded-2xl border border-slate-700/50 p-6 w-full max-w-md shadow-2xl">
        <h3 className="text-lg font-bold text-white mb-1 flex items-center gap-2">
          <XCircle size={18} className="text-red-400" /> Reject Purchase
        </h3>
        <p className="text-slate-400 text-sm mb-4">
          Rejecting the{' '}
          <span className="font-semibold text-white">${parseFloat(purchase.amount || 0).toLocaleString()}</span>
          {' '}purchase from{' '}
          <span className="font-semibold text-white">{purchase.submitter_name || 'Agent'}</span>
          {' '}for{' '}
          <span className="font-semibold text-white">Apt {purchase.apartment_code}</span>
          {' '}·{' '}{purchase.building_name}.
        </p>
        <label className="block text-xs font-bold text-slate-400 uppercase tracking-wide mb-2">
          Rejection Reason *
        </label>
        <textarea
          value={reason}
          onChange={e => setReason(e.target.value)}
          rows={3}
          placeholder="Explain why this purchase is being rejected…"
          className="w-full bg-slate-800/70 border border-slate-700 text-white rounded-xl px-4 py-3 text-sm focus:ring-2 focus:ring-red-500/50 focus:outline-none transition-all placeholder-slate-600 resize-none"
        />
        <div className="flex gap-3 mt-4">
          <button
            onClick={onClose}
            className="flex-1 py-3 bg-slate-700/50 text-slate-300 font-semibold rounded-xl hover:bg-slate-700 transition-all">
            Cancel
          </button>
          <button
            onClick={() => onReject(reason)}
            disabled={!reason.trim() || isLoading}
            className="flex-1 py-3 bg-gradient-to-r from-red-600 to-rose-600 text-white font-bold rounded-xl hover:from-red-500 hover:to-rose-500 disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-lg shadow-red-500/20 flex items-center justify-center gap-2">
            {isLoading
              ? <><div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" /> Rejecting…</>
              : <><XCircle size={16} /> Reject</>}
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Main Component ────────────────────────────────────────────────────────────
const AgentPurchaseReview = () => {
  const navigate    = useNavigate();
  const queryClient = useQueryClient();

  const user = (() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } })();

  const [tab, setTab] = useState('pending');
  const [rejectTarget, setRejectTarget] = useState(null);
  const [acceptingId, setAcceptingId] = useState(null);

  // ── Fetch pending purchases
  const { data: pending = [], isLoading: pLoading, refetch: refetchPending } = useQuery({
    queryKey: ['admin_pending_purchases'],
    queryFn: async () => {
      const res = await axios.get('/energy/agent/apartment-purchases/pending');
      return Array.isArray(res.data) ? res.data : [];
    },
    refetchInterval: 20000,
  });

  // ── Fetch all purchases (history tab)
  const { data: allPurchases = [], isLoading: aLoading, refetch: refetchAll } = useQuery({
    queryKey: ['admin_all_purchases'],
    queryFn: async () => {
      try {
        const res = await axios.get('/energy/agent/apartment-purchases');
        return Array.isArray(res.data?.history) ? res.data.history : [];
      } catch { return []; }
    },
    enabled: tab === 'all',
  });

  // ── Accept mutation
  const acceptMutation = useMutation({
    mutationFn: (id) => {
      setAcceptingId(id);
      return axios.post(`/energy/agent/apartment-purchases/${id}/verify`, {
        status: 'Accepted',
        user_id: user?.id || 1,
      });
    },
    onSuccess: () => {
      setAcceptingId(null);
      queryClient.invalidateQueries(['admin_pending_purchases']);
      queryClient.invalidateQueries(['admin_all_purchases']);
      queryClient.invalidateQueries(['apartmentCostsReport']);
    },
    onError: () => setAcceptingId(null),
  });

  // ── Reject mutation
  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }) => axios.post(`/energy/agent/apartment-purchases/${id}/verify`, {
      status: 'Rejected',
      rejection_reason: reason,
      user_id: user?.id || 1,
    }),
    onSuccess: () => {
      setRejectTarget(null);
      queryClient.invalidateQueries(['admin_pending_purchases']);
      queryClient.invalidateQueries(['admin_all_purchases']);
    },
  });

  const handleReject = (reason) => {
    if (!rejectTarget) return;
    rejectMutation.mutate({ id: rejectTarget.id, reason });
  };

  const pendingCount  = pending.length;
  const isLoading     = tab === 'pending' ? pLoading : aLoading;
  const displayList   = tab === 'pending' ? pending : allPurchases;

  return (
    <div className="p-6 max-w-5xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">

      {/* Header */}
      <div className="mb-8">
        <button onClick={() => navigate(-1)}
          className="flex items-center gap-1.5 text-slate-400 hover:text-white transition-colors mb-4 text-sm">
          <ChevronRight size={14} className="rotate-180" /> Back
        </button>
        <div className="flex items-center justify-between flex-wrap gap-3">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center shadow-lg shadow-amber-500/10 relative">
                <ShoppingCart size={22} />
                {pendingCount > 0 && (
                  <span className="absolute -top-1.5 -right-1.5 w-5 h-5 bg-yellow-500 text-black text-[10px] font-black rounded-full flex items-center justify-center animate-pulse">
                    {pendingCount}
                  </span>
                )}
              </div>
              Agent Purchase Review
            </h1>
            <p className="text-slate-400 mt-1 text-sm">
              Review, approve or reject purchase submissions from field agents.
            </p>
          </div>
          <button
            onClick={() => { refetchPending(); refetchAll(); }}
            className="p-2 rounded-lg bg-slate-800 border border-slate-700 text-slate-400 hover:text-white transition-colors">
            <RefreshCw size={16} />
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        {[
          { label: 'Pending Review',  value: pendingCount,                                              color: 'border-yellow-500', icon: Clock,         glow: pendingCount > 0 },
          { label: 'Accepted',        value: allPurchases.filter(p => p.status === 'Accepted').length,  color: 'border-green-500',  icon: CheckCircle },
          { label: 'Rejected',        value: allPurchases.filter(p => p.status === 'Rejected').length,  color: 'border-red-500',    icon: XCircle },
        ].map(s => {
          const Icon = s.icon;
          return (
            <div key={s.label} className={`glass-card p-5 border-l-4 ${s.color} rounded-2xl`}>
              <div className="flex items-center justify-between mb-2">
                <p className="text-slate-400 text-xs font-bold uppercase tracking-wide">{s.label}</p>
                <Icon size={16} className="text-slate-600" />
              </div>
              <p className={`text-3xl font-extrabold text-white ${s.glow ? 'animate-pulse' : ''}`}>
                {pLoading ? '…' : s.value}
              </p>
            </div>
          );
        })}
      </div>

      {/* Tabs */}
      <div className="flex gap-2 mb-6">
        {[
          { id: 'pending', label: `Pending Review`, icon: Clock },
          { id: 'all',     label: 'All History',    icon: History },
        ].map(t => {
          const Icon = t.icon;
          return (
            <button key={t.id} onClick={() => setTab(t.id)}
              className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-semibold text-sm transition-all ${
                tab === t.id
                  ? 'bg-amber-500/20 text-amber-400 border border-amber-500/40'
                  : 'bg-slate-800/50 text-slate-400 border border-slate-700/50 hover:text-white'
              }`}>
              <Icon size={15} />
              {t.label}
              {t.id === 'pending' && pendingCount > 0 && (
                <span className="ml-1 px-1.5 py-0.5 bg-yellow-500 text-black text-xs font-bold rounded-full leading-none">
                  {pendingCount}
                </span>
              )}
            </button>
          );
        })}
      </div>

      {/* List */}
      {isLoading ? (
        <div className="glass-card rounded-2xl p-12 text-center text-slate-400">
          <div className="w-10 h-10 border-4 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          Loading purchases…
        </div>
      ) : displayList.length === 0 ? (
        <div className="glass-card rounded-2xl p-16 text-center">
          <ShoppingCart size={48} className="mx-auto text-slate-700 mb-4" />
          <p className="text-slate-400 text-lg font-medium">
            {tab === 'pending' ? 'No pending purchases — all clear! ✅' : 'No purchase history found.'}
          </p>
          {tab === 'pending' && (
            <p className="text-slate-600 text-sm mt-1">Agent submissions will appear here for your review.</p>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          {displayList.map(item => (
            <div key={item.id}
              className={`glass-card rounded-2xl border p-5 transition-all ${
                item.status === 'Rejected' ? 'border-red-500/30 hover:border-red-500/50' :
                item.status === 'Pending'  ? 'border-yellow-500/40 hover:border-yellow-500/60' :
                                             'border-emerald-500/30 hover:border-emerald-500/50'
              }`}>
              <div className="flex flex-col sm:flex-row sm:items-start justify-between gap-4">

                {/* Left */}
                <div className="flex-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2 mb-3">
                    <StatusBadge status={item.status} />
                    <span className="text-slate-500 text-xs">
                      {item.date
                        ? new Date(item.date + 'T00:00:00').toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })
                        : '—'}
                    </span>
                    {item.created_at && (
                      <span className="text-slate-600 text-xs">
                        · Submitted {new Date(item.created_at).toLocaleString('en-GB', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                      </span>
                    )}
                  </div>

                  <div className="flex flex-wrap items-center gap-2 mb-1">
                    <Building2 size={14} className="text-primary shrink-0" />
                    <span className="text-white font-semibold text-sm">{item.building_name}</span>
                    <span className="text-slate-500">·</span>
                    <Home size={14} className="text-indigo-400 shrink-0" />
                    <span className="text-slate-300 text-sm">Apt {item.apartment_code}</span>
                  </div>

                  {item.submitter_name && (
                    <p className="text-slate-400 text-xs mt-1 flex items-center gap-1">
                      <User size={11} /> Submitted by:{' '}
                      <span className="font-semibold text-slate-300">{item.submitter_name}</span>
                    </p>
                  )}
                  {item.supplier_name && (
                    <p className="text-slate-400 text-xs mt-1 flex items-center gap-1">
                      <Package size={11} /> {item.supplier_name}
                    </p>
                  )}
                  {item.notes && (
                    <p className="text-slate-500 text-xs mt-1 italic">{item.notes}</p>
                  )}

                  {item.status === 'Rejected' && item.rejection_reason && (
                    <div className="mt-3 p-3 bg-red-500/10 border border-red-500/20 rounded-xl">
                      <p className="text-red-400 text-xs font-semibold flex items-center gap-1 mb-1">
                        <AlertCircle size={11} /> Rejection Reason:
                      </p>
                      <p className="text-red-300 text-xs">{item.rejection_reason}</p>
                    </div>
                  )}
                </div>

                {/* Right */}
                <div className="shrink-0 flex flex-col items-end gap-3">
                  <p className="text-2xl font-extrabold text-white">
                    ${parseFloat(item.amount || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                  </p>

                  {item.receipt_image && <ReceiptPreview src={item.receipt_image} />}

                  {item.status === 'Pending' && (
                    <div className="flex gap-2 mt-1">
                      <button
                        onClick={() => acceptMutation.mutate(item.id)}
                        disabled={acceptMutation.isPending && acceptingId === item.id}
                        className="flex items-center gap-1.5 px-4 py-2 bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold rounded-xl hover:from-emerald-500 hover:to-teal-500 disabled:opacity-40 transition-all shadow-md shadow-emerald-500/20 text-sm active:scale-95">
                        {acceptMutation.isPending && acceptingId === item.id
                          ? <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          : <Check size={15} />}
                        Accept
                      </button>
                      <button
                        onClick={() => setRejectTarget(item)}
                        className="flex items-center gap-1.5 px-4 py-2 bg-red-500/20 text-red-400 border border-red-500/30 font-bold rounded-xl hover:bg-red-500/30 transition-all text-sm active:scale-95">
                        <X size={15} /> Reject
                      </button>
                    </div>
                  )}

                  {item.status === 'Accepted' && (
                    <div className="flex items-center gap-1.5 text-green-400 text-xs font-semibold">
                      <CheckCircle size={14} /> Accepted & Recorded
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Reject Modal */}
      {rejectTarget && (
        <RejectModal
          purchase={rejectTarget}
          onClose={() => setRejectTarget(null)}
          onReject={handleReject}
          isLoading={rejectMutation.isPending}
        />
      )}
    </div>
  );
};

export default AgentPurchaseReview;
