import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../api/axios';
import {
  Wrench, PlusCircle, Send, Clock, RotateCcw, CheckCircle2,
  XCircle, X, ChevronDown, ChevronUp, MessageSquare, AlertCircle
} from 'lucide-react';

const STATUS_CONFIG = {
  'Open':        { color: 'bg-blue-500/20 text-blue-400 border-blue-500/30',         icon: <Clock size={12} /> },
  'In Progress': { color: 'bg-amber-500/20 text-amber-400 border-amber-500/30',       icon: <RotateCcw size={12} /> },
  'Resolved':    { color: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30', icon: <CheckCircle2 size={12} /> },
  'Rejected':    { color: 'bg-red-500/20 text-red-400 border-red-500/30',             icon: <XCircle size={12} /> },
  'Closed':      { color: 'bg-slate-600/40 text-slate-400 border-slate-600/40',       icon: <X size={12} /> },
};

const PRIORITY_CONFIG = {
  'Low':    'bg-slate-600/40 text-slate-400',
  'Medium': 'bg-blue-500/20 text-blue-400',
  'High':   'bg-amber-500/20 text-amber-400',
  'Urgent': 'bg-red-500/20 text-red-400 font-bold',
};

const TenantMaintenance = () => {
  const queryClient = useQueryClient();

  const [showForm, setShowForm]       = useState(false);
  const [expandedId, setExpandedId]   = useState(null);
  const [form, setForm] = useState({ title: '', description: '', category: '', priority: 'Medium', apartment_id: '' });

  // ── Fetch apartments ──────────────────────────────────────────────────────────
  const { data: myApartments } = useQuery({
    queryKey: ['my-apartments'],
    queryFn: async () => (await api.get('/tenant-portal/apartments')).data,
  });

  // ── Fetch tickets ───────────────────────────────────────────────────────────
  const { data: tickets, isLoading } = useQuery({
    queryKey: ['my-maintenance-tickets'],
    queryFn: async () => (await api.get('/tenant-portal/maintenance-tickets')).data,
  });

  // ── Submit new ticket ────────────────────────────────────────────────────────
  const submitMutation = useMutation({
    mutationFn: (data) => api.post('/tenant-portal/maintenance-tickets', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['my-maintenance-tickets']);
      setShowForm(false);
      setForm({ title: '', description: '', category: '', priority: 'Medium', apartment_id: '' });
    },
    onError: (err) => alert(err.response?.data?.error || 'Failed to submit ticket'),
  });

  // Default the apartment_id if they only have one
  React.useEffect(() => {
    if (myApartments?.length === 1 && !form.apartment_id) {
      setForm(prev => ({ ...prev, apartment_id: myApartments[0].id }));
    }
  }, [myApartments, form.apartment_id]);

  const openCount      = tickets?.filter(t => t.status === 'Open').length      || 0;
  const inProgressCount = tickets?.filter(t => t.status === 'In Progress').length || 0;
  const resolvedCount  = tickets?.filter(t => t.status === 'Resolved').length  || 0;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar space-y-6">

        {/* ── Page Header ──────────────────────────────────────────────── */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <Wrench className="text-orange-400" size={32} /> Maintenance Requests
            </h1>
            <p className="text-slate-400 mt-1">Report an issue in your apartment and track its status.</p>
          </div>
          <button
            onClick={() => setShowForm(v => !v)}
            className="flex items-center gap-2 bg-orange-500/20 hover:bg-orange-500/30 text-orange-400 border border-orange-500/30 px-5 py-2.5 rounded-xl font-medium transition-all"
          >
            <PlusCircle size={18} />
            {showForm ? 'Cancel' : 'New Request'}
          </button>
        </div>

        {/* ── Stats ────────────────────────────────────────────────────── */}
        <div className="grid grid-cols-3 gap-4">
          {[
            { label: 'Open',       count: openCount,       border: 'border-l-blue-500',    bg: 'bg-blue-500/10',    text: 'text-blue-400' },
            { label: 'In Progress', count: inProgressCount, border: 'border-l-amber-500',   bg: 'bg-amber-500/10',   text: 'text-amber-400' },
            { label: 'Resolved',   count: resolvedCount,   border: 'border-l-emerald-500', bg: 'bg-emerald-500/10', text: 'text-emerald-400' },
          ].map(s => (
            <div key={s.label} className={`glass-card p-5 border-l-4 ${s.border} ${s.bg}`}>
              <div className={`text-3xl font-black ${s.text}`}>{s.count}</div>
              <div className="text-sm text-slate-400 font-medium mt-1">{s.label}</div>
            </div>
          ))}
        </div>

        {/* ── Submit Form ───────────────────────────────────────────────── */}
        {showForm && (
          <div className="glass-card p-6 border-l-4 border-l-orange-500 border border-orange-500/20 animate-in slide-in-from-top-2 duration-200">
            <h3 className="text-lg font-bold text-white mb-5 flex items-center gap-2">
              <MessageSquare className="text-orange-400" size={20} /> Describe Your Issue
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-2">
                  Issue Title <span className="text-red-400">*</span>
                </label>
                <input
                  type="text"
                  value={form.title}
                  onChange={e => setForm({ ...form, title: e.target.value })}
                  placeholder="e.g. AC in my room isn't working properly, need repairman"
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-orange-500/60 transition-colors"
                />
              </div>
              
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-2">
                  Select Apartment <span className="text-red-400">*</span>
                </label>
                <select
                  value={form.apartment_id}
                  onChange={e => setForm({ ...form, apartment_id: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-orange-500/60 transition-colors"
                >
                  <option value="">-- Choose your apartment --</option>
                  {myApartments?.map(apt => (
                    <option key={apt.id} value={apt.id}>
                      {apt.building_name} – Apartment {apt.apartment_code}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">Category</label>
                <select
                  value={form.category}
                  onChange={e => setForm({ ...form, category: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-orange-500/60 transition-colors"
                >
                  <option value="">Select category...</option>
                  <option value="AC / HVAC">AC / HVAC</option>
                  <option value="Plumbing">Plumbing</option>
                  <option value="Electrical">Electrical</option>
                  <option value="Appliances">Appliances</option>
                  <option value="Structural">Structural</option>
                  <option value="Cleaning">Cleaning</option>
                  <option value="Security">Security</option>
                  <option value="Other">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">Priority</label>
                <select
                  value={form.priority}
                  onChange={e => setForm({ ...form, priority: e.target.value })}
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-orange-500/60 transition-colors"
                >
                  <option value="Low">Low</option>
                  <option value="Medium">Medium</option>
                  <option value="High">High</option>
                  <option value="Urgent">Urgent — needs immediate attention</option>
                </select>
              </div>
              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-2">
                  Description <span className="text-red-400">*</span>
                </label>
                <textarea
                  rows={4}
                  value={form.description}
                  onChange={e => setForm({ ...form, description: e.target.value })}
                  placeholder="Please describe the problem in detail. When did it start? What have you already tried?"
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white placeholder-slate-500 focus:outline-none focus:border-orange-500/60 transition-colors resize-none"
                />
              </div>
            </div>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowForm(false)}
                className="px-5 py-2.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => submitMutation.mutate(form)}
                disabled={!form.title || !form.description || !form.apartment_id || submitMutation.isPending}
                className="flex items-center gap-2 bg-orange-500 hover:bg-orange-600 disabled:opacity-50 text-white px-6 py-2.5 rounded-xl font-bold transition-all shadow-lg shadow-orange-500/20"
              >
                <Send size={16} />
                {submitMutation.isPending ? 'Submitting...' : 'Submit Request'}
              </button>
            </div>
          </div>
        )}

        {/* ── Ticket List ───────────────────────────────────────────────── */}
        {isLoading ? (
          <div className="glass-card p-8 text-center text-slate-400">Loading your requests...</div>
        ) : !tickets?.length ? (
          <div className="glass-card p-14 text-center border-l-4 border-l-orange-500/30">
            <Wrench className="text-orange-500/30 mx-auto mb-4" size={52} />
            <h3 className="text-xl font-bold text-white mb-2">No Requests Yet</h3>
            <p className="text-slate-400">Use the "New Request" button above to report any issues in your apartment.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {tickets.map(ticket => {
              const cfg = STATUS_CONFIG[ticket.status] || STATUS_CONFIG['Open'];
              const isExpanded = expandedId === ticket.id;
              return (
                <div key={ticket.id} className="glass-card overflow-hidden border border-slate-700/50 hover:border-slate-600/50 transition-colors">
                  <div
                    className="flex items-center gap-4 p-5 cursor-pointer select-none"
                    onClick={() => setExpandedId(isExpanded ? null : ticket.id)}
                  >
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-3 flex-wrap">
                        <span className="font-semibold text-white">{ticket.title}</span>
                        {ticket.category && (
                          <span className="text-xs text-slate-400 bg-slate-800 border border-slate-700 px-2 py-0.5 rounded-full">
                            {ticket.category}
                          </span>
                        )}
                        <span className={`text-xs px-2 py-0.5 rounded-full font-bold ${PRIORITY_CONFIG[ticket.priority]}`}>
                          {ticket.priority}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 mt-1.5 text-xs text-slate-500">
                        <span>#{ticket.id}</span>
                        <span>·</span>
                        <span>{new Date(ticket.created_at).toLocaleDateString('default', { day: '2-digit', month: 'short', year: 'numeric' })}</span>
                        {ticket.apartment_code && (
                          <>
                            <span>·</span>
                            <span className="text-slate-400">{ticket.building_name} – Apt {ticket.apartment_code}</span>
                          </>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-3 flex-shrink-0">
                      <span className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1 rounded-full border ${cfg.color}`}>
                        {cfg.icon} {ticket.status}
                      </span>
                      {isExpanded ? <ChevronUp size={16} className="text-slate-400" /> : <ChevronDown size={16} className="text-slate-400" />}
                    </div>
                  </div>

                  {isExpanded && (
                    <div className="border-t border-slate-700/50 px-5 py-4 bg-slate-800/20 space-y-3 animate-in slide-in-from-top-1">
                      <div>
                        <div className="text-xs text-slate-500 font-semibold uppercase tracking-wider mb-1">Your Description</div>
                        <p className="text-slate-300 text-sm leading-relaxed whitespace-pre-wrap">{ticket.description}</p>
                      </div>
                      {ticket.admin_notes && (
                        <div className="bg-indigo-500/10 border border-indigo-500/30 rounded-xl p-4">
                          <div className="text-xs text-indigo-400 font-semibold uppercase tracking-wider mb-1 flex items-center gap-1.5">
                            <MessageSquare size={12} /> Note from Management
                          </div>
                          <p className="text-slate-300 text-sm">{ticket.admin_notes}</p>
                        </div>
                      )}
                      {ticket.resolved_at && (
                        <div className="text-xs text-emerald-400/80">
                          ✅ Resolved on {new Date(ticket.resolved_at).toLocaleDateString('default', { day: '2-digit', month: 'short', year: 'numeric' })}
                        </div>
                      )}
                      {ticket.status === 'Rejected' && !ticket.admin_notes && (
                        <div className="flex items-center gap-2 text-xs text-red-400/80 bg-red-500/10 border border-red-500/20 rounded-lg px-3 py-2">
                          <AlertCircle size={13} /> Your request was reviewed and rejected. Contact management for details.
                        </div>
                      )}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

      </div>
    </div>
  );
};

export default TenantMaintenance;
