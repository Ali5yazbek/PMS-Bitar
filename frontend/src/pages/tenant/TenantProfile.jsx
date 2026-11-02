import React, { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../api/axios';
import {
  User, Upload, CheckCircle2, XCircle, Clock, AlertCircle,
  Paperclip, ExternalLink, RotateCcw, Folder, Home
} from 'lucide-react';

// ── Document type config ────────────────────────────────────────────────────
const DOC_CONFIG = [
  {
    key: 'passport',
    label: 'Passport',
    icon: '🛂',
    hint: 'Upload a clear scan or photo of your passport (photo page).',
    accentBorder: 'border-l-indigo-500',
    accentBg: 'bg-indigo-500/10',
    accentText: 'text-indigo-400',
  },
  {
    key: 'national_id',
    label: 'National ID',
    icon: '🪪',
    hint: 'Upload both sides of your national identity card.',
    accentBorder: 'border-l-teal-500',
    accentBg: 'bg-teal-500/10',
    accentText: 'text-teal-400',
  },
  {
    key: 'work_contract',
    label: 'Work Details / Contract',
    icon: '💼',
    hint: 'Upload your employment contract or a work-details letter.',
    accentBorder: 'border-l-purple-500',
    accentBg: 'bg-purple-500/10',
    accentText: 'text-purple-400',
  },
];

// ── Status badge helper ─────────────────────────────────────────────────────
const StatusBadge = ({ status }) => {
  const map = {
    Uploaded:  { cls: 'bg-blue-500/20 text-blue-400 border-blue-500/30',           label: '📤 Uploaded',   icon: <Upload size={11} /> },
    Verified:  { cls: 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',   label: '✅ Verified',   icon: <CheckCircle2 size={11} /> },
    Pending:   { cls: 'bg-amber-500/20 text-amber-400 border-amber-500/30',         label: '⏳ Pending',    icon: <Clock size={11} /> },
    Missing:   { cls: 'bg-slate-600/40 text-slate-400 border-slate-600/40',         label: '❌ Missing',    icon: <XCircle size={11} /> },
    Requested: { cls: 'bg-red-500/20 text-red-400 border-red-500/30 animate-pulse', label: '⚠️ Re-upload Required', icon: <AlertCircle size={11} /> },
  };
  const s = map[status] || map['Missing'];
  return (
    <span className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1 rounded-full border ${s.cls}`}>
      {s.icon} {s.label}
    </span>
  );
};

// ── Main Component ──────────────────────────────────────────────────────────
const TenantProfile = () => {
  const queryClient = useQueryClient();
  const [uploadingType, setUploadingType] = useState(null);
  const fileRefs = useRef({});

  // ── Fetch tenant info from dashboard ────────────────────────────────────
  const { data: dashData, isLoading: loadingDash } = useQuery({
    queryKey: ['tenant-dashboard'],
    queryFn: async () => (await api.get('/tenant-portal/dashboard')).data,
  });

  // ── Fetch tenant documents ───────────────────────────────────────────────
  const { data: docs, isLoading: loadingDocs } = useQuery({
    queryKey: ['my-tenant-documents'],
    queryFn: async () => (await api.get('/tenant-portal/documents')).data,
  });

  // ── Upload mutation ──────────────────────────────────────────────────────
  const uploadMutation = useMutation({
    mutationFn: async ({ docType, file }) => {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('document_type', docType);
      return api.post('/tenant-portal/documents/upload', formData);
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['my-tenant-documents']);
      setUploadingType(null);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Upload failed. Please try again.');
      setUploadingType(null);
    },
  });

  const contracts = dashData?.contracts || [];
  const hasRequestedDocs = docs && Object.values(docs).some(d => d?.status === 'Requested');

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar space-y-8">

        {/* ── Page Header ──────────────────────────────────────────────────── */}
        <div>
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <User className="text-primary" size={32} /> My Profile
          </h1>
          <p className="text-slate-400 mt-1">Your personal information and required KYC documents.</p>
        </div>

        {/* ── Alert: Document(s) Requested ─────────────────────────────────── */}
        {hasRequestedDocs && (
          <div className="flex items-start gap-3 bg-red-500/10 border border-red-500/30 rounded-2xl px-5 py-4 animate-in fade-in">
            <AlertCircle className="text-red-400 flex-shrink-0 mt-0.5" size={20} />
            <div>
              <div className="text-red-400 font-bold mb-0.5">Action Required</div>
              <p className="text-slate-300 text-sm">
                Management has requested you to re-upload one or more documents below.
                Please upload a clearer copy as soon as possible.
              </p>
            </div>
          </div>
        )}

        {/* ── Personal Information Cards (one per apartment) ─────────────── */}
        {loadingDash ? (
          <div className="glass-card p-8 text-center text-slate-400">Loading profile...</div>
        ) : contracts.length > 0 ? (
          <div className="space-y-4">
            <h2 className="text-xl font-bold text-white flex items-center gap-3">
              <User className="text-primary" size={22} /> Personal Information
              {contracts.length > 1 && (
                <span className="text-xs bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 px-3 py-1 rounded-full font-semibold">
                  {contracts.length} Apartments
                </span>
              )}
            </h2>
            <div className={`grid gap-5 ${contracts.length > 1 ? 'grid-cols-1 lg:grid-cols-2' : 'grid-cols-1'}`}>
              {contracts.map((contract, idx) => {
                const isActive = contract.status === 'Active' || contract.status === 'Approved';
                return (
                  <div key={contract.id} className="glass-card p-6 border border-slate-700/50">
                    <div className="flex items-center justify-between mb-5 pb-4 border-b border-slate-700/40">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-primary/20 flex items-center justify-center">
                          <Home size={18} className="text-primary" />
                        </div>
                        <div>
                          <div className="font-bold text-white">{contract.building_name} — Apt {contract.apartment_code}</div>
                          <div className="text-xs text-slate-500">Contract #{contract.id}</div>
                        </div>
                      </div>
                      <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-bold border ${
                        isActive
                          ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'
                          : 'bg-amber-500/20 text-amber-400 border-amber-500/30'
                      }`}>
                        {contract.status?.replace(/_/g, ' ') || 'N/A'}
                      </span>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      {[
                        { label: 'Full Name',    value: contract.full_name || 'N/A' },
                        { label: 'Monthly Rent', value: `${Number(contract.monthly_rent || 0).toLocaleString()} CFA` },
                        { label: 'Lease Start',  value: contract.start_date || 'N/A' },
                        { label: 'Lease End',    value: contract.end_date   || 'N/A' },
                      ].map(({ label, value }) => (
                        <div key={label}>
                          <span className="text-xs text-slate-500 uppercase tracking-wider font-semibold block mb-1">{label}</span>
                          <span className="text-base text-white font-medium">{value}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        ) : (
          <div className="glass-card p-8 text-center text-slate-400">No active contract found.</div>
        )}

        {/* ── Document Upload Section ────────────────────────────────────── */}
        <div>
          <h2 className="text-xl font-bold text-white mb-5 flex items-center gap-3">
            <Folder className="text-indigo-400" size={22} /> My Documents
            <span className="text-xs text-slate-400 font-normal">
              (Accepted: JPG, PNG, WEBP, PDF · Max 10 MB)
            </span>
          </h2>

          {loadingDocs ? (
            <div className="glass-card p-8 text-center text-slate-400">Loading documents...</div>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
              {DOC_CONFIG.map(({ key, label, icon, hint, accentBorder, accentBg, accentText }) => {
                const doc         = docs?.[key];
                const status      = doc?.status || 'Missing';
                const isRequested = status === 'Requested';
                const isVerified  = status === 'Verified';
                const isUploading = uploadingType === key && uploadMutation.isPending;

                return (
                  <div
                    key={key}
                    className={`glass-card border-l-4 ${accentBorder} overflow-hidden transition-all ${
                      isRequested ? 'ring-1 ring-red-500/30 shadow-lg shadow-red-500/10' : ''
                    }`}
                  >
                    {/* Card header */}
                    <div className={`p-5 ${accentBg} border-b border-slate-700/50`}>
                      <div className="flex items-center justify-between mb-3">
                        <div className="flex items-center gap-3">
                          <span className="text-2xl">{icon}</span>
                          <span className="font-bold text-white">{label}</span>
                        </div>
                        <StatusBadge status={status} />
                      </div>

                      {/* Requested alert */}
                      {isRequested && (
                        <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/30 rounded-lg px-3 py-2 text-xs text-red-400">
                          <AlertCircle size={13} />
                          Management has requested this document. Please re-upload.
                        </div>
                      )}

                      {/* Verified confirmation */}
                      {isVerified && (
                        <div className="flex items-center gap-2 bg-emerald-500/10 border border-emerald-500/20 rounded-lg px-3 py-2 text-xs text-emerald-400">
                          <CheckCircle2 size={13} />
                          This document has been verified by management. ✓
                        </div>
                      )}
                    </div>

                    {/* Card body */}
                    <div className="p-5 space-y-4">
                      {/* Hint */}
                      <p className="text-xs text-slate-500 leading-relaxed">{hint}</p>

                      {/* File info */}
                      {doc?.file_url ? (
                        <div className="space-y-1">
                          <div className="flex items-center gap-2 text-sm">
                            <Paperclip size={14} className="text-slate-400 flex-shrink-0" />
                            <span className="text-slate-300 truncate" title={doc.original_filename}>
                              {doc.original_filename || 'Uploaded file'}
                            </span>
                          </div>
                          {doc.uploaded_at && (
                            <div className="text-xs text-slate-500">
                              Uploaded: {new Date(doc.uploaded_at).toLocaleDateString('default', { day: '2-digit', month: 'short', year: 'numeric' })}
                            </div>
                          )}
                          <a
                            href={`${(api.defaults.baseURL || '').replace(/\/api\/?$/, '')}/${doc.file_url}`}
                            target="_blank"
                            rel="noopener noreferrer"
                            className={`inline-flex items-center gap-1.5 text-xs font-semibold ${accentText} hover:underline`}
                          >
                            <ExternalLink size={12} /> View Uploaded File
                          </a>
                        </div>
                      ) : (
                        <div className="text-sm text-slate-500 italic">No document uploaded yet.</div>
                      )}

                      {/* Upload button — hidden if verified and not requested */}
                      {(!isVerified || isRequested) && (
                        <label className={`flex items-center justify-center gap-2 border text-sm font-medium px-4 py-2.5 rounded-xl cursor-pointer transition-all ${
                          isRequested
                            ? 'bg-red-500/20 hover:bg-red-500/30 text-red-400 border-red-500/30'
                            : 'bg-slate-800 hover:bg-slate-700 text-white border-slate-700'
                        } ${isUploading ? 'opacity-60 pointer-events-none' : ''}`}>
                          <Upload size={15} />
                          {isUploading ? 'Uploading...' : (doc?.file_url ? 'Re-upload' : 'Upload File')}
                          <input
                            ref={el => (fileRefs.current[key] = el)}
                            type="file"
                            className="hidden"
                            accept=".jpg,.jpeg,.png,.webp,.pdf"
                            onChange={e => {
                              const file = e.target.files?.[0];
                              if (file) {
                                setUploadingType(key);
                                uploadMutation.mutate({ docType: key, file });
                              }
                              e.target.value = '';
                            }}
                          />
                        </label>
                      )}

                      {/* Already verified — locked message */}
                      {isVerified && !isRequested && (
                        <div className="flex items-center gap-2 text-xs text-slate-500 bg-slate-800/40 border border-slate-700/40 rounded-xl px-4 py-2.5">
                          <RotateCcw size={13} />
                          Verified documents are locked. Contact management to update.
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

      </div>
    </div>
  );
};

export default TenantProfile;
