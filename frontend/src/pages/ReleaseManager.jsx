import React, { useState, useEffect } from 'react';
import {
  Smartphone, Apple, Upload, RefreshCw, CheckCircle2, AlertTriangle,
  Download, ShieldCheck, Settings, History, Trash2,
  Check, Copy, FileCode, ExternalLink, Calendar,
  BarChart3, X, Layers
} from 'lucide-react';
import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis, Tooltip, CartesianGrid
} from 'recharts';
import api from '../api/axios';

const ReleaseManager = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  // Modals
  const [showUploadModal, setShowUploadModal] = useState(false);
  const [showImportModal, setShowImportModal] = useState(false);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showIosGuideModal, setShowIosGuideModal] = useState(false);
  const [selectedRelease, setSelectedRelease] = useState(null);

  // Upload Form State
  const [uploadFile, setUploadFile] = useState(null);
  const [uploadPlatform, setUploadPlatform] = useState('android'); // 'android' | 'ios'
  const [uploadVersionName, setUploadVersionName] = useState('1.0.1');
  const [uploadVersionCode, setUploadVersionCode] = useState('2');
  const [uploadBuildNumber, setUploadBuildNumber] = useState('2');
  const [uploadBundleId, setUploadBundleId] = useState('com.bitar.bitar_pms');
  const [uploadIosMethod, setUploadIosMethod] = useState('enterprise');
  const [uploadSigningStatus, setUploadSigningStatus] = useState('Signed Enterprise In-House (Direct OTA)');
  const [uploadProvisioningProfile, setUploadProvisioningProfile] = useState('SOCIMCO In-House Enterprise Profile');
  const [uploadAppleTeamId, setUploadAppleTeamId] = useState('SOCIMCO');
  const [uploadTargetEligibility, setUploadTargetEligibility] = useState('All Company Field & Operations iOS Devices (Trust Profile in Settings > General > VPN & Device Management)');
  const [uploadMinVersion, setUploadMinVersion] = useState('1.0.0');
  const [uploadIsMandatory, setUploadIsMandatory] = useState(false);
  const [uploadSetCurrent, setUploadSetCurrent] = useState(true);
  const [uploadNotes, setUploadNotes] = useState('');
  const [uploading, setUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  // Settings Form State
  const [settingsForm, setSettingsForm] = useState({});
  const [savingSettings, setSavingSettings] = useState(false);

  // Copied checksum feedback
  const [copiedId, setCopiedId] = useState(null);

  useEffect(() => {
    fetchDashboard();
  }, []);

  const fetchDashboard = async () => {
    try {
      setLoading(true);
      setError('');
      const res = await api.get('/releases/admin/dashboard');
      setData(res.data);
      setSettingsForm(res.data.settings || {});
    } catch (err) {
      console.error('Failed to load release dashboard:', err);
      setError(err.response?.data?.error || 'Failed to fetch release dashboard.');
    } finally {
      setLoading(false);
    }
  };

  const notify = (msg) => {
    setSuccessMsg(msg);
    setTimeout(() => setSuccessMsg(''), 4000);
  };

  const handleCopyHash = (id, hash) => {
    if (!hash) return;
    navigator.clipboard.writeText(hash);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const handlePlatformChange = (p) => {
    setUploadPlatform(p);
    if (p === 'ios') {
      setUploadBundleId('com.bitar.bitarPms');
      setUploadSigningStatus('Signed Enterprise In-House (Direct OTA)');
    } else {
      setUploadBundleId('com.bitar.bitar_pms');
      setUploadSigningStatus('Signed (Production Keystore)');
    }
  };

  const handleActivate = async (id, versionName, platform) => {
    if (!window.confirm(`Are you sure you want to promote ${platform.toUpperCase()} v${versionName} to the ACTIVE PRODUCTION release? Existing users will immediately receive update notifications.`)) {
      return;
    }
    try {
      await api.post(`/releases/admin/${id}/activate`);
      notify(`Native ${platform.toUpperCase()} release v${versionName} is now active.`);
      fetchDashboard();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to activate release.');
    }
  };

  const handleDelete = async (id, versionName, platform) => {
    if (!window.confirm(`Permanently delete ${platform.toUpperCase()} release v${versionName}? This removes the binary file from server storage.`)) {
      return;
    }
    try {
      await api.delete(`/releases/admin/${id}`);
      notify(`Release v${versionName} deleted.`);
      fetchDashboard();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to delete release.');
    }
  };

  const handleUploadSubmit = async (e) => {
    e.preventDefault();
    if (!uploadFile) {
      alert(`Please select a native ${uploadPlatform === 'ios' ? '.ipa' : '.apk'} binary file to upload.`);
      return;
    }
    try {
      setUploading(true);
      setUploadProgress(10);
      const formData = new FormData();
      formData.append('package_file', uploadFile);
      formData.append('platform', uploadPlatform);
      formData.append('version_name', uploadVersionName);
      formData.append('version_code', uploadVersionCode);
      formData.append('build_number', uploadBuildNumber);
      formData.append('bundle_id', uploadBundleId);
      formData.append('ios_distribution_method', uploadIosMethod);
      formData.append('signing_status', uploadSigningStatus);
      formData.append('provisioning_profile_name', uploadProvisioningProfile);
      formData.append('apple_team_id', uploadAppleTeamId);
      formData.append('target_device_eligibility', uploadTargetEligibility);
      formData.append('min_supported_version', uploadMinVersion);
      formData.append('is_mandatory', uploadIsMandatory ? '1' : '0');
      formData.append('is_current', uploadSetCurrent ? '1' : '0');
      formData.append('release_notes', uploadNotes);

      await api.post('/releases/admin/upload', formData, {
        onUploadProgress: (progressEvent) => {
          if (progressEvent.total) {
            const pct = Math.round((progressEvent.loaded * 100) / progressEvent.total);
            setUploadProgress(pct);
          }
        }
      });

      notify(`Native ${uploadPlatform.toUpperCase()} Release v${uploadVersionName} uploaded and published successfully!`);
      setShowUploadModal(false);
      setUploadFile(null);
      setUploadNotes('');
      fetchDashboard();
    } catch (err) {
      console.error(err);
      alert(err.response?.data?.error || 'Upload failed. Check file format (.apk / .ipa) and server upload limits.');
    } finally {
      setUploading(false);
      setUploadProgress(0);
    }
  };

  const handleImportLocalApk = async (e) => {
    e.preventDefault();
    try {
      setUploading(true);
      await api.post('/releases/admin/import-local-apk', {
        version_name: uploadVersionName,
        version_code: uploadVersionCode,
        min_supported_version: uploadMinVersion,
        is_mandatory: uploadIsMandatory ? 1 : 0,
        is_current: uploadSetCurrent ? 1 : 0,
        release_notes: uploadNotes,
      });

      notify(`Local Flutter APK imported as v${uploadVersionName}!`);
      setShowImportModal(false);
      setUploadNotes('');
      fetchDashboard();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to import local Flutter APK.');
    } finally {
      setUploading(false);
    }
  };

  const handleSaveSettings = async (e) => {
    e.preventDefault();
    try {
      setSavingSettings(true);
      await api.post('/releases/admin/settings', settingsForm);
      notify('Distribution settings saved successfully.');
      setShowSettingsModal(false);
      fetchDashboard();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to save settings.');
    } finally {
      setSavingSettings(false);
    }
  };

  const handleUpdateRelease = async (e) => {
    e.preventDefault();
    if (!selectedRelease) return;
    try {
      await api.put(`/releases/admin/${selectedRelease.id}`, {
        version_name: selectedRelease.version_name,
        version_code: selectedRelease.version_code,
        build_number: selectedRelease.build_number,
        bundle_id: selectedRelease.bundle_id,
        ios_distribution_method: selectedRelease.ios_distribution_method,
        signing_status: selectedRelease.signing_status,
        target_device_eligibility: selectedRelease.target_device_eligibility,
        min_supported_version: selectedRelease.min_supported_version,
        is_mandatory: selectedRelease.is_mandatory ? 1 : 0,
        release_notes: selectedRelease.release_notes,
      });
      notify(`Release v${selectedRelease.version_name} updated.`);
      setShowEditModal(false);
      fetchDashboard();
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to update release.');
    }
  };

  if (loading) {
    return (
      <div className="p-8 text-center flex flex-col items-center justify-center min-h-[60vh]">
        <RefreshCw size={36} className="text-emerald-400 animate-spin mb-4" />
        <p className="text-slate-400 text-sm">Loading Native Application Release Registry & Telemetry...</p>
      </div>
    );
  }

  const stats = data?.stats || {};
  const releases = data?.releases || [];
  const localApk = data?.local_apk || {};
  const settings = data?.settings || {};
  const auditLogs = data?.audit_logs || [];
  const appleDist = data?.apple_distribution || {};
  const dailyTrend = (data?.daily_trend || []).map(d => ({
    day: d.day ? d.day.slice(5) : '',
    downloads: parseInt(d.count, 10) || 0
  }));

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-8 font-sans text-slate-200">
      {/* Toast Notification */}
      {successMsg && (
        <div className="fixed top-6 right-6 z-50 p-4 rounded-xl bg-emerald-500/20 border border-emerald-500/40 text-emerald-300 text-sm font-semibold shadow-2xl backdrop-blur-md flex items-center gap-2 animate-in fade-in slide-in-from-top-4">
          <CheckCircle2 size={18} className="text-emerald-400" />
          <span>{successMsg}</span>
        </div>
      )}

      {error && (
        <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-sm flex items-center gap-2">
          <AlertTriangle size={18} className="text-rose-400 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-slate-800 pb-6">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-500 to-indigo-600 flex items-center justify-center text-slate-950 font-bold shadow-lg">
              <Smartphone size={22} className="text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-black text-white tracking-tight flex items-center gap-2.5">
                Application Release Manager
                <span className="text-xs uppercase font-bold px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
                  Native iOS & Android
                </span>
              </h1>
              <p className="text-xs text-slate-400 mt-0.5">
                Manage owner-controlled native APK and native iOS IPA releases, OTA manifests, signing status, and mandatory updates.
              </p>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-wrap items-center gap-2.5">
          {localApk?.available && (
            <button
              onClick={() => {
                handlePlatformChange('android');
                setShowImportModal(true);
              }}
              className="px-4 py-2 text-xs font-bold rounded-xl bg-gradient-to-r from-teal-500 to-emerald-500 hover:from-teal-400 hover:to-emerald-400 text-slate-950 transition-all flex items-center gap-2 shadow-[0_0_20px_rgba(20,184,166,0.3)]"
            >
              <FileCode size={16} />
              <span>Import Flutter APK ({localApk.size_formatted})</span>
            </button>
          )}

          <button
            onClick={() => {
              handlePlatformChange('android');
              setShowUploadModal(true);
            }}
            className="px-4 py-2 text-xs font-bold rounded-xl bg-slate-800 hover:bg-slate-700 text-white border border-slate-700 transition-all flex items-center gap-2"
          >
            <Upload size={16} className="text-emerald-400" />
            <span>Upload Native Binary (.apk / .ipa)</span>
          </button>

          <button
            onClick={() => setShowIosGuideModal(true)}
            className="px-4 py-2 text-xs font-bold rounded-xl bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/40 transition-all flex items-center gap-2"
          >
            <Apple size={16} className="text-indigo-400" />
            <span>iOS Build & CI Guide</span>
          </button>

          <button
            onClick={() => setShowSettingsModal(true)}
            className="px-4 py-2 text-xs font-bold rounded-xl bg-slate-800 hover:bg-slate-700 text-white border border-slate-700 transition-all flex items-center gap-2"
          >
            <Settings size={16} className="text-indigo-400" />
            <span>Distribution Settings</span>
          </button>

          <a
            href="/download"
            target="_blank"
            rel="noreferrer"
            className="px-3.5 py-2 text-xs font-bold rounded-xl bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 transition-all flex items-center gap-1.5"
            title="Open Public Download Page"
          >
            <ExternalLink size={14} />
            <span>Public Portal</span>
          </a>
        </div>
      </div>

      {/* Metrics Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="p-5 rounded-2xl bg-slate-900/60 border border-slate-800/80 space-y-2">
          <div className="flex items-center justify-between text-slate-400 text-xs font-semibold">
            <span>Total Native Installs</span>
            <Download size={16} className="text-emerald-400" />
          </div>
          <div className="text-3xl font-black text-white tracking-tight">
            {(stats.total_downloads || 0).toLocaleString()}
          </div>
          <p className="text-[11px] text-slate-500">Android APK & iOS OTA installs</p>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900/60 border border-slate-800/80 space-y-2">
          <div className="flex items-center justify-between text-slate-400 text-xs font-semibold">
            <span>Android APK Downloads</span>
            <Smartphone size={16} className="text-teal-400" />
          </div>
          <div className="text-3xl font-black text-white tracking-tight">
            {(stats.android_downloads || 0).toLocaleString()}
          </div>
          <p className="text-[11px] text-slate-500">Direct production APK streams</p>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900/60 border border-slate-800/80 space-y-2">
          <div className="flex items-center justify-between text-slate-400 text-xs font-semibold">
            <span>iOS Native OTA Installs</span>
            <Apple size={16} className="text-indigo-400" />
          </div>
          <div className="text-3xl font-black text-white tracking-tight">
            {(stats.ios_installs || 0).toLocaleString()}
          </div>
          <p className="text-[11px] text-slate-500">Wireless Apple OTA manifests</p>
        </div>

        <div className="p-5 rounded-2xl bg-slate-900/60 border border-slate-800/80 space-y-2">
          <div className="flex items-center justify-between text-slate-400 text-xs font-semibold">
            <span>Downloads Today</span>
            <Calendar size={16} className="text-amber-400" />
          </div>
          <div className="text-3xl font-black text-white tracking-tight">
            {(stats.today_downloads || 0).toLocaleString()}
          </div>
          <p className="text-[11px] text-slate-500">Past 24 hours</p>
        </div>
      </div>

      {/* Apple Distribution Methods Matrix */}
      <div className="p-6 rounded-3xl bg-slate-900/40 border border-slate-800/80 space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <ShieldCheck size={20} className="text-indigo-400" />
            <h3 className="text-base font-bold text-white">
              Apple Authorized Independent iOS Distribution Matrix
            </h3>
          </div>
          <span className="text-xs font-mono text-slate-400">
            Active Mode: <strong className="text-indigo-300 uppercase">{settings.ios_distribution_mode || 'Enterprise'}</strong>
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {(appleDist.methods || []).map((m) => (
            <div key={m.id} className={`p-4 rounded-2xl border ${m.active ? 'bg-indigo-950/30 border-indigo-500/50' : 'bg-slate-950/60 border-slate-800/80'} space-y-2`}>
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold text-white">{m.title}</span>
                <span className={`text-[10px] font-bold px-2 py-0.5 rounded ${m.active ? 'bg-indigo-500 text-white' : 'bg-slate-800 text-slate-400'}`}>
                  {m.status}
                </span>
              </div>
              <p className="text-[11px] text-slate-400 leading-relaxed">
                {m.eligibility}
              </p>
            </div>
          ))}
        </div>
      </div>

      {/* 14-Day Download Trend Chart */}
      {dailyTrend.length > 0 && (
        <div className="p-6 rounded-3xl bg-slate-900/40 border border-slate-800/80 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-bold text-white flex items-center gap-2">
              <BarChart3 size={18} className="text-emerald-400" />
              14-Day Distribution & Install Telemetry
            </h3>
            <span className="text-xs text-slate-400">Total: {dailyTrend.reduce((acc, d) => acc + d.downloads, 0)} events</span>
          </div>

          <div className="h-52 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={dailyTrend} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="downloadGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#10b981" stopOpacity={0.4} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" vertical={false} />
                <XAxis dataKey="day" stroke="#64748b" fontSize={11} tickLine={false} />
                <YAxis stroke="#64748b" fontSize={11} tickLine={false} allowDecimals={false} />
                <Tooltip
                  contentStyle={{
                    backgroundColor: '#0f172a',
                    borderColor: '#334155',
                    borderRadius: '0.75rem',
                    color: '#f8fafc',
                    fontSize: '12px',
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="downloads"
                  stroke="#10b981"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#downloadGradient)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Releases Registry Table */}
      <div className="p-6 rounded-3xl bg-slate-900/40 border border-slate-800/80 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-base font-bold text-white flex items-center gap-2">
              <Layers size={18} className="text-emerald-400" />
              Native Releases & Artifact Archive
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              1-click rollbacks, binary integrity checksums, and in-app mandatory version enforcement.
            </p>
          </div>
          <span className="text-xs font-semibold text-slate-400 bg-slate-800/80 px-3 py-1 rounded-full">
            {releases.length} Recorded Releases
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-300">
            <thead className="bg-slate-950/80 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
              <tr>
                <th className="py-3 px-4">Version & Build</th>
                <th className="py-3 px-4">Platform & Bundle ID</th>
                <th className="py-3 px-4">Distribution & Signing</th>
                <th className="py-3 px-4">Package Size & Checksum</th>
                <th className="py-3 px-4">Eligibility</th>
                <th className="py-3 px-4">Installs</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {releases.map((rel) => {
                const isCurrent = !!rel.is_current;
                const isMandatory = !!rel.is_mandatory;
                const isIos = rel.platform === 'ios';
                return (
                  <tr key={rel.id} className={`hover:bg-slate-800/40 transition-colors ${isCurrent ? 'bg-emerald-500/5' : ''}`}>
                    {/* Version */}
                    <td className="py-3.5 px-4">
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-bold text-white text-sm">v{rel.version_name}</span>
                        <span className="text-[10px] text-slate-400 font-mono">(Build {rel.build_number || rel.version_code})</span>
                        {isCurrent && (
                          <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 text-[9px] font-black uppercase tracking-wider">
                            Active
                          </span>
                        )}
                      </div>
                      <div className="text-[10px] text-slate-400 mt-0.5">{rel.release_date}</div>
                    </td>

                    {/* Platform & Bundle ID */}
                    <td className="py-3.5 px-4 space-y-1">
                      <span className={`capitalize px-2 py-0.5 rounded-lg text-xs font-semibold inline-flex items-center gap-1.5 ${
                        isIos ? 'bg-indigo-500/20 text-indigo-300 border border-indigo-500/30' : 'bg-teal-500/20 text-teal-300 border border-teal-500/30'
                      }`}>
                        {isIos ? <Apple size={13} /> : <Smartphone size={13} />}
                        {rel.platform_label || (isIos ? 'iOS (Native IPA)' : 'Android (Native APK)')}
                      </span>
                      <div className="font-mono text-[11px] text-slate-400">
                        {rel.bundle_id || rel.package_name}
                      </div>
                    </td>

                    {/* Distribution Method & Signing */}
                    <td className="py-3.5 px-4 space-y-1">
                      <div className="font-semibold text-white">
                        {isIos ? (rel.ipa_verified ? (rel.ios_distribution_method === 'enterprise' ? 'Apple Enterprise In-House OTA' : 'Apple Ad-Hoc OTA') : 'Awaiting IPA Package') : 'Self-Hosted APK'}
                      </div>
                      <div className={`text-[10px] flex items-center gap-1 ${rel.ipa_verified || !isIos ? 'text-emerald-400' : 'text-amber-400'}`}>
                        {rel.ipa_verified || !isIos ? <CheckCircle2 size={11} /> : <AlertTriangle size={11} />}
                        <span>{rel.signing_status || (isIos ? 'Pending Signed Build' : 'Signed Production')}</span>
                      </div>
                    </td>

                    {/* File Size & SHA256 */}
                    <td className="py-3.5 px-4 space-y-1">
                      <div className={`font-semibold ${rel.ipa_verified || !isIos ? 'text-slate-200' : 'text-amber-300'}`}>
                        {rel.file_size_formatted || (isIos ? 'Pending Signed IPA Build' : '89.6 MB (Native APK)')}
                      </div>
                      {rel.sha256_checksum ? (
                        <div className="flex items-center gap-1 text-[10px] font-mono text-slate-400">
                          <span>{rel.sha256_checksum.slice(0, 12)}...</span>
                          <button
                            onClick={() => handleCopyHash(rel.id, rel.sha256_checksum)}
                            className="text-emerald-400 hover:text-emerald-300 transition-colors"
                            title="Copy full SHA-256 Checksum"
                          >
                            {copiedId === rel.id ? <Check size={11} /> : <Copy size={11} />}
                          </button>
                        </div>
                      ) : (
                        <span className="text-[10px] text-slate-500 font-mono">No binary registered</span>
                      )}
                    </td>

                    {/* Eligibility & Mandatory */}
                    <td className="py-3.5 px-4 space-y-1 max-w-xs">
                      <div className="text-[11px] text-slate-300 truncate" title={rel.target_device_eligibility}>
                        {rel.target_device_eligibility || (isIos ? 'Requires signed .ipa package' : 'All Android Devices')}
                      </div>
                      {isMandatory ? (
                        <span className="inline-flex items-center gap-1 text-[10px] text-rose-400 font-bold bg-rose-500/10 px-2 py-0.5 rounded">
                          <AlertTriangle size={11} /> Mandatory Update
                        </span>
                      ) : (
                        <span className="text-[10px] text-slate-500">Optional Update</span>
                      )}
                    </td>

                    {/* Install count */}
                    <td className="py-3.5 px-4 font-mono font-semibold text-white">
                      {(rel.download_count || 0).toLocaleString()}
                    </td>

                    {/* Status */}
                    <td className="py-3.5 px-4">
                      {isIos && !rel.ipa_verified ? (
                        <span className="text-[11px] text-amber-400 font-semibold flex items-center gap-1">
                          <AlertTriangle size={13} /> Awaiting IPA
                        </span>
                      ) : rel.is_published ? (
                        <span className="text-[11px] text-emerald-400 flex items-center gap-1">
                          <CheckCircle2 size={13} /> Published
                        </span>
                      ) : (
                        <span className="text-[11px] text-slate-500 flex items-center gap-1">
                          Draft
                        </span>
                      )}
                    </td>

                    {/* Actions */}
                    <td className="py-3.5 px-4 text-right space-x-1.5 whitespace-nowrap">
                      {!isCurrent && (
                        <button
                          onClick={() => handleActivate(rel.id, rel.version_name, rel.platform)}
                          className="px-2.5 py-1 text-[11px] font-bold rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-300 border border-emerald-500/30 transition-colors"
                          title="Promote to active production version"
                        >
                          Activate
                        </button>
                      )}

                      <button
                        onClick={() => {
                          setSelectedRelease({ ...rel });
                          setShowEditModal(true);
                        }}
                        className="px-2.5 py-1 text-[11px] font-medium rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 transition-colors"
                      >
                        Edit
                      </button>

                      {rel.download_url && (
                        <a
                          href={rel.download_url}
                          className="px-2.5 py-1 text-[11px] font-medium rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-300 inline-block transition-colors"
                          title={`Direct binary download (${rel.binary_type?.toUpperCase() || 'FILE'})`}
                        >
                          <Download size={12} className="inline mr-1" />
                          {rel.binary_type?.toUpperCase() || 'Binary'}
                        </a>
                      )}

                      {!isCurrent && (
                        <button
                          onClick={() => handleDelete(rel.id, rel.version_name, rel.platform)}
                          className="px-2 py-1 text-[11px] font-medium rounded-lg bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 transition-colors"
                          title="Delete release"
                        >
                          <Trash2 size={12} className="inline" />
                        </button>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>

      {/* Audit Log Trail */}
      {auditLogs.length > 0 && (
        <div className="p-6 rounded-3xl bg-slate-900/30 border border-slate-800/70 space-y-4">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <History size={16} className="text-indigo-400" />
            Recent Release Operations & Audit Trail
          </h3>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-slate-300">
              <thead className="text-[10px] uppercase text-slate-500 border-b border-slate-800 font-semibold">
                <tr>
                  <th className="py-2 px-3">Timestamp</th>
                  <th className="py-2 px-3">Admin</th>
                  <th className="py-2 px-3">Action</th>
                  <th className="py-2 px-3">Target</th>
                  <th className="py-2 px-3">Details</th>
                  <th className="py-2 px-3">IP</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/50">
                {auditLogs.slice(0, 10).map((log) => (
                  <tr key={log.id} className="hover:bg-slate-800/20">
                    <td className="py-2.5 px-3 text-slate-400 font-mono text-[11px]">{log.created_at}</td>
                    <td className="py-2.5 px-3 font-medium text-white">{log.admin_name || 'Admin'}</td>
                    <td className="py-2.5 px-3">
                      <span className="font-mono text-[11px] text-emerald-400 uppercase">{log.action}</span>
                    </td>
                    <td className="py-2.5 px-3 font-mono text-slate-300">v{log.version_name || '—'}</td>
                    <td className="py-2.5 px-3 text-slate-400 max-w-xs truncate">{log.details || '—'}</td>
                    <td className="py-2.5 px-3 font-mono text-[10px] text-slate-500">{log.ip_address}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/*                       MODAL: UPLOAD BINARY FILE                           */}
      {/* ========================================================================= */}
      {showUploadModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-xl w-full space-y-6 shadow-2xl max-h-[92vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Upload size={18} className="text-emerald-400" />
                Upload Native Production Application Package
              </h3>
              <button onClick={() => setShowUploadModal(false)} className="text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleUploadSubmit} className="space-y-4 text-xs">
              {/* Platform selector */}
              <div className="grid grid-cols-2 gap-3">
                <button
                  type="button"
                  onClick={() => handlePlatformChange('android')}
                  className={`p-3 rounded-xl border text-xs font-semibold flex items-center justify-center gap-2 ${
                    uploadPlatform === 'android'
                      ? 'bg-emerald-500/20 border-emerald-500/50 text-emerald-300 shadow-[0_0_15px_rgba(16,185,129,0.2)]'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400'
                  }`}
                >
                  <Smartphone size={16} />
                  Android Native APK (.apk)
                </button>
                <button
                  type="button"
                  onClick={() => handlePlatformChange('ios')}
                  className={`p-3 rounded-xl border text-xs font-semibold flex items-center justify-center gap-2 ${
                    uploadPlatform === 'ios'
                      ? 'bg-indigo-500/20 border-indigo-500/50 text-indigo-300 shadow-[0_0_15px_rgba(99,102,241,0.2)]'
                      : 'bg-slate-800/60 border-slate-700 text-slate-400'
                  }`}
                >
                  <Apple size={16} />
                  iOS Native Flutter IPA (.ipa)
                </button>
              </div>

              {/* File input */}
              <div className="p-4 rounded-2xl border-2 border-dashed border-slate-700 bg-slate-950/60 text-center hover:border-emerald-500/50 transition-colors">
                <input
                  type="file"
                  id="package_file"
                  accept={uploadPlatform === 'ios' ? '.ipa' : '.apk'}
                  onChange={(e) => setUploadFile(e.target.files[0] || null)}
                  className="hidden"
                />
                <label htmlFor="package_file" className="cursor-pointer block space-y-2">
                  <Upload size={28} className={uploadPlatform === 'ios' ? 'text-indigo-400 mx-auto' : 'text-emerald-400 mx-auto'} />
                  <p className="font-semibold text-white">
                    {uploadFile ? uploadFile.name : `Click to select native ${uploadPlatform === 'ios' ? '.ipa' : '.apk'} package`}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    {uploadFile ? `${(uploadFile.size / (1024 * 1024)).toFixed(2)} MB` : (uploadPlatform === 'ios' ? 'Compiled Flutter iOS Native IPA with embedded.mobileprovision' : 'Signed Production Android APK')}
                  </p>
                </label>
              </div>

              {/* Version & Build Numbers */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Version Name (SemVer)</label>
                  <input
                    type="text"
                    value={uploadVersionName}
                    onChange={(e) => setUploadVersionName(e.target.value)}
                    placeholder="e.g. 1.0.1"
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Build Number</label>
                  <input
                    type="number"
                    value={uploadBuildNumber}
                    onChange={(e) => {
                      setUploadBuildNumber(e.target.value);
                      setUploadVersionCode(e.target.value);
                    }}
                    placeholder="e.g. 2"
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
              </div>

              {/* Bundle Identifier */}
              <div>
                <label className="block text-slate-400 mb-1 font-medium">
                  {uploadPlatform === 'ios' ? 'iOS Bundle Identifier' : 'Android Application ID'}
                </label>
                <input
                  type="text"
                  value={uploadBundleId}
                  onChange={(e) => setUploadBundleId(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                  required
                />
              </div>

              {/* iOS Specific Fields */}
              {uploadPlatform === 'ios' && (
                <div className="p-4 rounded-2xl bg-indigo-950/20 border border-indigo-500/30 space-y-3">
                  <span className="text-[11px] uppercase font-bold text-indigo-300 block">Apple Distribution & Signing Settings</span>
                  
                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-slate-400 mb-1 font-medium">Distribution Method</label>
                      <select
                        value={uploadIosMethod}
                        onChange={(e) => setUploadIosMethod(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-medium"
                      >
                        <option value="enterprise">Apple Developer Enterprise (In-House OTA)</option>
                        <option value="ad_hoc">Apple Ad-Hoc UDID Distribution</option>
                        <option value="web_distribution">Apple Web Distribution (EU DMA)</option>
                        <option value="custom_b2b">Custom B2B / Private Unlisted App</option>
                      </select>
                    </div>

                    <div>
                      <label className="block text-slate-400 mb-1 font-medium">Signing Profile Name</label>
                      <input
                        type="text"
                        value={uploadProvisioningProfile}
                        onChange={(e) => setUploadProvisioningProfile(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-3">
                    <div>
                      <label className="block text-slate-400 mb-1 font-medium">Apple Team ID</label>
                      <input
                        type="text"
                        value={uploadAppleTeamId}
                        onChange={(e) => setUploadAppleTeamId(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                      />
                    </div>
                    <div>
                      <label className="block text-slate-400 mb-1 font-medium">Signing Status</label>
                      <input
                        type="text"
                        value={uploadSigningStatus}
                        onChange={(e) => setUploadSigningStatus(e.target.value)}
                        className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-slate-400 mb-1 font-medium">Target Device Eligibility / Instructions</label>
                    <input
                      type="text"
                      value={uploadTargetEligibility}
                      onChange={(e) => setUploadTargetEligibility(e.target.value)}
                      className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                    />
                  </div>
                </div>
              )}

              {/* Minimum Supported Version */}
              <div>
                <label className="block text-slate-400 mb-1 font-medium">
                  Minimum Supported Version (Below this enforces mandatory update)
                </label>
                <input
                  type="text"
                  value={uploadMinVersion}
                  onChange={(e) => setUploadMinVersion(e.target.value)}
                  placeholder="e.g. 1.0.0"
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                  required
                />
              </div>

              {/* Toggles */}
              <div className="space-y-2 pt-1">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={uploadIsMandatory}
                    onChange={(e) => setUploadIsMandatory(e.target.checked)}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Mandatory Update (Lock older versions until updated)</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={uploadSetCurrent}
                    onChange={(e) => setUploadSetCurrent(e.target.checked)}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Set as Active Production Release immediately</span>
                </label>
              </div>

              {/* Release Notes */}
              <div>
                <label className="block text-slate-400 mb-1 font-medium">Release Notes / What's New</label>
                <textarea
                  rows={3}
                  value={uploadNotes}
                  onChange={(e) => setUploadNotes(e.target.value)}
                  placeholder="• Native performance upgrades&#10;• Offline SQLite sync&#10;• Push notifications"
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                />
              </div>

              {uploading && uploadProgress > 0 && (
                <div className="space-y-1">
                  <div className="flex justify-between text-[11px] text-slate-400">
                    <span>Uploading & verifying native mobile package...</span>
                    <span>{uploadProgress}%</span>
                  </div>
                  <div className="w-full h-2 rounded-full bg-slate-800 overflow-hidden">
                    <div className="h-full bg-emerald-500 transition-all duration-200" style={{ width: `${uploadProgress}%` }} />
                  </div>
                </div>
              )}

              <div className="flex items-center justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowUploadModal(false)}
                  disabled={uploading}
                  className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={uploading}
                  className="px-6 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black shadow-[0_0_20px_rgba(16,185,129,0.4)] disabled:opacity-50"
                >
                  {uploading ? 'Verifying & Saving...' : 'Publish Release'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/*               MODAL: IMPORT LOCALLY BUILT FLUTTER APK                    */}
      {/* ========================================================================= */}
      {showImportModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-lg w-full space-y-6 shadow-2xl">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <FileCode size={18} className="text-teal-400" />
                Import Locally Compiled Flutter APK
              </h3>
              <button onClick={() => setShowImportModal(false)} className="text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <div className="p-4 rounded-xl bg-teal-500/10 border border-teal-500/30 text-teal-200 text-xs space-y-1">
              <p className="font-bold flex items-center gap-1.5">
                <CheckCircle2 size={14} className="text-teal-400" />
                Compiled APK Detected on Disk
              </p>
              <p className="text-[11px] text-teal-300/80">
                Source: <code>mobile/build/app/outputs/flutter-apk/app-release.apk</code>
              </p>
              <p className="text-[11px] text-teal-300/80">
                Size: {localApk.size_formatted} &bull; Modified: {localApk.modified_at}
              </p>
            </div>

            <form onSubmit={handleImportLocalApk} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Version Name</label>
                  <input
                    type="text"
                    value={uploadVersionName}
                    onChange={(e) => setUploadVersionName(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Build Number / Code</label>
                  <input
                    type="number"
                    value={uploadVersionCode}
                    onChange={(e) => setUploadVersionCode(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Minimum Supported Version</label>
                <input
                  type="text"
                  value={uploadMinVersion}
                  onChange={(e) => setUploadMinVersion(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                  required
                />
              </div>

              <div className="space-y-2 pt-1">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={uploadIsMandatory}
                    onChange={(e) => setUploadIsMandatory(e.target.checked)}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Mandatory Update</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={uploadSetCurrent}
                    onChange={(e) => setUploadSetCurrent(e.target.checked)}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Set as Active Production Release immediately</span>
                </label>
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Release Notes</label>
                <textarea
                  rows={3}
                  value={uploadNotes}
                  onChange={(e) => setUploadNotes(e.target.value)}
                  placeholder="• Sub-second photo compression&#10;• Full Autonomous Agency AI Assistant"
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowImportModal(false)}
                  disabled={uploading}
                  className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={uploading}
                  className="px-6 py-2.5 rounded-xl bg-teal-500 hover:bg-teal-400 text-slate-950 font-black shadow-[0_0_20px_rgba(20,184,166,0.4)] disabled:opacity-50"
                >
                  {uploading ? 'Importing...' : 'Confirm Import & Publish'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/*                    MODAL: DISTRIBUTION SETTINGS                           */}
      {/* ========================================================================= */}
      {showSettingsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-xl w-full space-y-6 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <Settings size={18} className="text-indigo-400" />
                Distribution & Portal Configuration
              </h3>
              <button onClick={() => setShowSettingsModal(false)} className="text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleSaveSettings} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-4 p-4 rounded-2xl bg-slate-950/60 border border-slate-800">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settingsForm.android_downloads_enabled === '1'}
                    onChange={(e) => setSettingsForm({ ...settingsForm, android_downloads_enabled: e.target.checked ? '1' : '0' })}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Enable Android Downloads</span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settingsForm.ios_downloads_enabled === '1'}
                    onChange={(e) => setSettingsForm({ ...settingsForm, ios_downloads_enabled: e.target.checked ? '1' : '0' })}
                    className="rounded border-slate-700 text-indigo-500 focus:ring-indigo-500"
                  />
                  <span className="text-white font-medium">Enable iOS Distribution</span>
                </label>
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Default iOS Distribution Mode</label>
                <select
                  value={settingsForm.ios_distribution_mode || 'enterprise'}
                  onChange={(e) => setSettingsForm({ ...settingsForm, ios_distribution_mode: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-semibold"
                >
                  <option value="enterprise">Apple Developer Enterprise (In-House OTA)</option>
                  <option value="ad_hoc">Apple Ad-Hoc UDID Distribution</option>
                  <option value="web_distribution">Apple Web Distribution (EU DMA)</option>
                  <option value="custom_b2b">Custom B2B / Private Unlisted App</option>
                </select>
              </div>

              {/* Maintenance Mode */}
              <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 space-y-3">
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={settingsForm.maintenance_mode === '1'}
                    onChange={(e) => setSettingsForm({ ...settingsForm, maintenance_mode: e.target.checked ? '1' : '0' })}
                    className="rounded border-slate-700 text-amber-500 focus:ring-amber-500"
                  />
                  <span className="text-amber-200 font-bold">Maintenance Mode (Pause downloads with announcement)</span>
                </label>

                {settingsForm.maintenance_mode === '1' && (
                  <div>
                    <label className="block text-amber-200/80 mb-1">Maintenance Announcement Text</label>
                    <input
                      type="text"
                      value={settingsForm.maintenance_message || ''}
                      onChange={(e) => setSettingsForm({ ...settingsForm, maintenance_message: e.target.value })}
                      placeholder="Application updates are paused for scheduled maintenance."
                      className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-amber-500/40 text-amber-100"
                    />
                  </div>
                )}
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Application Display Name</label>
                <input
                  type="text"
                  value={settingsForm.app_display_name || ''}
                  onChange={(e) => setSettingsForm({ ...settingsForm, app_display_name: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                />
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Application Tagline</label>
                <input
                  type="text"
                  value={settingsForm.app_tagline || ''}
                  onChange={(e) => setSettingsForm({ ...settingsForm, app_tagline: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                />
              </div>

              {/* Support Contacts */}
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Support Email</label>
                  <input
                    type="email"
                    value={settingsForm.support_email || ''}
                    onChange={(e) => setSettingsForm({ ...settingsForm, support_email: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Support Phone</label>
                  <input
                    type="text"
                    value={settingsForm.support_phone || ''}
                    onChange={(e) => setSettingsForm({ ...settingsForm, support_phone: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">WhatsApp</label>
                  <input
                    type="text"
                    value={settingsForm.support_whatsapp || ''}
                    onChange={(e) => setSettingsForm({ ...settingsForm, support_whatsapp: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowSettingsModal(false)}
                  className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={savingSettings}
                  className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold disabled:opacity-50"
                >
                  {savingSettings ? 'Saving...' : 'Save Settings'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/*                       MODAL: EDIT RELEASE METADATA                        */}
      {/* ========================================================================= */}
      {showEditModal && selectedRelease && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-lg w-full space-y-6 shadow-2xl">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                Edit {selectedRelease.platform?.toUpperCase()} Release v{selectedRelease.version_name}
              </h3>
              <button onClick={() => setShowEditModal(false)} className="text-slate-400 hover:text-white">
                <X size={18} />
              </button>
            </div>

            <form onSubmit={handleUpdateRelease} className="space-y-4 text-xs">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Version Name</label>
                  <input
                    type="text"
                    value={selectedRelease.version_name}
                    onChange={(e) => setSelectedRelease({ ...selectedRelease, version_name: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Build Number</label>
                  <input
                    type="number"
                    value={selectedRelease.build_number || selectedRelease.version_code || 1}
                    onChange={(e) => setSelectedRelease({ ...selectedRelease, build_number: e.target.value, version_code: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                    required
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Bundle Identifier</label>
                <input
                  type="text"
                  value={selectedRelease.bundle_id || selectedRelease.package_name || ''}
                  onChange={(e) => setSelectedRelease({ ...selectedRelease, bundle_id: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                  required
                />
              </div>

              {selectedRelease.platform === 'ios' && (
                <div>
                  <label className="block text-slate-400 mb-1 font-medium">Distribution Method</label>
                  <select
                    value={selectedRelease.ios_distribution_method || 'enterprise'}
                    onChange={(e) => setSelectedRelease({ ...selectedRelease, ios_distribution_method: e.target.value })}
                    className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-semibold"
                  >
                    <option value="enterprise">Apple Developer Enterprise (In-House OTA)</option>
                    <option value="ad_hoc">Apple Ad-Hoc UDID Distribution</option>
                    <option value="web_distribution">Apple Web Distribution (EU DMA)</option>
                    <option value="custom_b2b">Custom B2B / Private Unlisted App</option>
                  </select>
                </div>
              )}

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Minimum Supported Version</label>
                <input
                  type="text"
                  value={selectedRelease.min_supported_version}
                  onChange={(e) => setSelectedRelease({ ...selectedRelease, min_supported_version: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                  required
                />
              </div>

              <div>
                <label className="flex items-center gap-2 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={!!selectedRelease.is_mandatory}
                    onChange={(e) => setSelectedRelease({ ...selectedRelease, is_mandatory: e.target.checked })}
                    className="rounded border-slate-700 text-emerald-500 focus:ring-emerald-500"
                  />
                  <span className="text-white font-medium">Mandatory Update</span>
                </label>
              </div>

              <div>
                <label className="block text-slate-400 mb-1 font-medium">Release Notes</label>
                <textarea
                  rows={4}
                  value={selectedRelease.release_notes || ''}
                  onChange={(e) => setSelectedRelease({ ...selectedRelease, release_notes: e.target.value })}
                  className="w-full px-3 py-2 rounded-xl bg-slate-950 border border-slate-800 text-white font-mono"
                />
              </div>

              <div className="flex items-center justify-end gap-3 pt-4">
                <button
                  type="button"
                  onClick={() => setShowEditModal(false)}
                  className="px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-6 py-2.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-black"
                >
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* iOS Build & Cloud CI Guide Modal */}
      {showIosGuideModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm animate-in fade-in">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 sm:p-8 max-w-3xl w-full max-h-[90vh] overflow-y-auto space-y-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-slate-800 pb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold">
                  <Apple size={22} />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white">How to Compile & Distribute Native iOS (IPA)</h3>
                  <p className="text-xs text-slate-400">Technical requirements for wireless OTA installation on real iPhones</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowIosGuideModal(false)}
                className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white"
              >
                <X size={18} />
              </button>
            </div>

            {/* Why Previous Install Did Not Work */}
            <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-200 text-xs space-y-2">
              <div className="flex items-center gap-2 font-bold text-sm text-amber-300">
                <AlertTriangle size={16} className="text-amber-400 shrink-0" />
                <span>Why iPhone Wireless Installation Requires a Real Compiled Binary</span>
              </div>
              <p className="text-slate-300 leading-relaxed">
                Apple iOS SpringBoard enforces strict kernel-level security checks before displaying an app icon on an iPhone. When downloading an OTA manifest, iOS checks:
              </p>
              <ul className="list-disc pl-5 space-y-1 text-slate-300">
                <li>A real 64-bit ARM Mach-O executable (<code className="text-amber-200">Payload/Runner.app/Runner</code>)</li>
                <li>Valid Apple cryptographic signatures in <code className="text-amber-200">_CodeSignature/CodeResources</code></li>
                <li>A valid, unexpired <code className="text-amber-200">embedded.mobileprovision</code> matching the app Bundle ID (<code className="text-amber-200">com.bitar.bitarPms</code>)</li>
              </ul>
              <p className="text-slate-300 leading-relaxed">
                Because your development workstation runs Windows, native iOS binaries cannot be compiled locally without Apple Xcode. A real compiled .ipa must be built via Cloud CI (GitHub Actions) or on a Mac.
              </p>
            </div>

            {/* Path 1: GitHub Actions Cloud CI */}
            <div className="p-5 rounded-2xl bg-slate-950/70 border border-slate-800 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-indigo-400 flex items-center gap-2">
                  <span className="w-5 h-5 rounded-full bg-indigo-500/20 text-indigo-300 flex items-center justify-center text-[10px]">1</span>
                  Path A: Automated Cloud CI with GitHub Actions (Recommended)
                </span>
                <span className="text-[10px] bg-indigo-500/20 text-indigo-300 px-2 py-0.5 rounded font-bold">No Mac Required</span>
              </div>
              <p className="text-xs text-slate-300 leading-relaxed">
                We have created an automated workflow file at <code className="text-indigo-300">.github/workflows/build_ios.yml</code>. Whenever you push to GitHub:
              </p>
              <ol className="list-decimal pl-5 space-y-1 text-xs text-slate-400">
                <li>GitHub spins up an official Apple macOS runner (<code className="text-slate-200">macos-14</code> with Xcode).</li>
                <li>It runs <code className="text-slate-200">flutter build ipa --no-codesign</code> (or signed with your Apple secrets).</li>
                <li>It outputs a downloadable <code className="text-slate-200">SOCIMCO-PMS.ipa</code> artifact.</li>
                <li>Upload that IPA directly into this Release Manager with 1 click!</li>
              </ol>
            </div>

            {/* Path 2: Physical Mac with Xcode */}
            <div className="p-5 rounded-2xl bg-slate-950/70 border border-slate-800 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-bold uppercase tracking-wider text-emerald-400 flex items-center gap-2">
                  <span className="w-5 h-5 rounded-full bg-emerald-500/20 text-emerald-300 flex items-center justify-center text-[10px]">2</span>
                  Path B: Direct macOS Compilation
                </span>
                <span className="text-[10px] bg-emerald-500/20 text-emerald-300 px-2 py-0.5 rounded font-bold">Local Mac</span>
              </div>
              <p className="text-xs text-slate-300 leading-relaxed">
                If you or a colleague have a Mac, run these commands in the project folder:
              </p>
              <pre className="bg-slate-900 p-3 rounded-xl border border-slate-800 text-[11px] font-mono text-emerald-300 overflow-x-auto">
{`cd mobile
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --release --export-options-plist=ExportOptions.plist`}
              </pre>
            </div>

            {/* Path 3: Apple Distribution Types */}
            <div className="p-5 rounded-2xl bg-slate-950/70 border border-slate-800 space-y-3">
              <div className="text-xs font-bold uppercase tracking-wider text-white">
                Apple Signing Program Options for Physical iPhones
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div className="p-3 rounded-xl bg-slate-900 border border-slate-800">
                  <div className="font-bold text-indigo-300 mb-1">Standard Dev Program ($99/yr)</div>
                  <p className="text-slate-400 text-[11px]">
                    Use <strong>Ad-Hoc Distribution</strong>. Register up to 100 iPhone UDIDs in developer.apple.com, export with Ad-Hoc profile, and wireless OTA installation works on all registered devices.
                  </p>
                </div>
                <div className="p-3 rounded-xl bg-slate-900 border border-slate-800">
                  <div className="font-bold text-emerald-300 mb-1">Enterprise Program ($299/yr)</div>
                  <p className="text-slate-400 text-[11px]">
                    Use <strong>In-House Distribution</strong>. Universal installation on ANY employee iPhone without UDID registration. Users trust the profile in Settings &gt; General &gt; VPN &amp; Device Management.
                  </p>
                </div>
              </div>
            </div>

            <div className="flex justify-end pt-2">
              <button
                type="button"
                onClick={() => setShowIosGuideModal(false)}
                className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white font-bold text-xs transition-colors"
              >
                Close Guide
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ReleaseManager;
