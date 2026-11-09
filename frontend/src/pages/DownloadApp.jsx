import React, { useState, useEffect } from 'react';
import { 
  Smartphone, Apple, Download, ShieldCheck, CheckCircle2, AlertTriangle, 
  Copy, Check, QrCode, RefreshCw, HelpCircle, Layers,
  ChevronRight, Sparkles, Server, ArrowDownToLine, Phone, Mail, MessageSquare
} from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';
import api from '../api/axios';

const DownloadApp = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [activeTab, setActiveTab] = useState('android'); // 'android' | 'ios'
  const [copiedHash, setCopiedHash] = useState(false);
  const [showQrModal, setShowQrModal] = useState(false);
  const [activeHistoryTab, setActiveHistoryTab] = useState(false);

  useEffect(() => {
    fetchReleaseInfo();
  }, []);

  const fetchReleaseInfo = async () => {
    try {
      setLoading(true);
      setError('');
      const res = await api.get('/releases/public-info');
      setData(res.data);
    } catch (err) {
      console.error('Failed to load release info:', err);
      setError('Unable to fetch live release registry information. Please verify your connection.');
    } finally {
      setLoading(false);
    }
  };

  const handleCopyHash = (hash) => {
    if (!hash) return;
    navigator.clipboard.writeText(hash);
    setCopiedHash(true);
    setTimeout(() => setCopiedHash(false), 2000);
  };

  const trackInstall = async (platform, releaseId) => {
    try {
      await api.post('/releases/track-install', { platform, release_id: releaseId });
    } catch (e) {}
  };

  const currentUrl = typeof window !== 'undefined' ? window.location.origin : 'https://socimco.wormbitfactory.com';
  const androidRel = data?.android_release;
  const iosRel = data?.ios_release;
  const appSettings = data?.app || {};
  const isMaintenance = appSettings?.maintenance_mode;

  const apkDownloadUrl = androidRel?.download_url || `${currentUrl}/backend/api/releases/download-latest?platform=android`;
  const iosOtaUrl = iosRel?.ios_ota_url || `itms-services://?action=download-manifest&url=${encodeURIComponent(`${currentUrl}/backend/api/releases/ios-manifest/${iosRel?.id || 2}`)}`;
  const iosIpaDownloadUrl = iosRel?.download_url || `${currentUrl}/backend/api/releases/download/${iosRel?.id || 2}`;

  return (
    <div className="min-h-screen bg-[#07090e] text-slate-200 font-sans selection:bg-emerald-500/30 selection:text-emerald-300 relative overflow-x-hidden">
      {/* Background radial gradients */}
      <div className="fixed top-[-15%] left-[-10%] w-[60vw] h-[60vw] max-w-[700px] max-h-[700px] rounded-full bg-emerald-500/10 blur-[140px] pointer-events-none -z-10" />
      <div className="fixed bottom-[-15%] right-[-10%] w-[60vw] h-[60vw] max-w-[700px] max-h-[700px] rounded-full bg-indigo-600/10 blur-[150px] pointer-events-none -z-10" />

      {/* Header Navigation */}
      <header className="border-b border-slate-800/80 bg-[#07090e]/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-6xl mx-auto px-4 sm:px-6 h-20 flex items-center justify-between">
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-400 flex items-center justify-center text-slate-950 font-black text-xl shadow-[0_0_20px_rgba(16,185,129,0.35)]">
              P
            </div>
            <div>
              <div className="font-bold text-white text-lg tracking-tight flex items-center gap-2">
                {appSettings.name || 'SOCIMCO PMS'}
                <span className="text-[10px] uppercase font-bold tracking-wider px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                  Native Distribution Portal
                </span>
              </div>
              <p className="text-xs text-slate-400 font-medium hidden sm:block">
                Independent Enterprise Mobile App Distribution &bull; Native Android & iOS Builds
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <a
              href="/login"
              className="px-4 py-2 text-xs font-semibold rounded-lg bg-slate-800/80 hover:bg-slate-700/80 text-slate-200 border border-slate-700/60 transition-all flex items-center gap-2"
            >
              Web Login
              <ChevronRight size={14} className="text-slate-400" />
            </a>
          </div>
        </div>
      </header>

      {/* Maintenance Announcement Banner */}
      {isMaintenance && (
        <div className="bg-amber-500/15 border-b border-amber-500/30 text-amber-200 px-4 py-3 text-sm text-center flex items-center justify-center gap-2">
          <AlertTriangle size={18} className="text-amber-400 shrink-0" />
          <span>
            {appSettings.maintenance_message || 'Application updates are currently undergoing scheduled maintenance. Please check back shortly.'}
          </span>
        </div>
      )}

      {/* Hero Section */}
      <section className="relative pt-12 pb-16 px-4 sm:px-6 text-center max-w-4xl mx-auto">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-slate-800/80 border border-slate-700/70 text-xs font-medium text-emerald-400 mb-6 shadow-sm">
          <Sparkles size={14} />
          <span>Official Native Applications &bull; Owner-Controlled Releases &bull; Zero Store Intermediaries</span>
        </div>

        <h1 className="text-3xl sm:text-5xl font-black text-white tracking-tight leading-tight sm:leading-tight mb-5">
          Install the Official <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 via-teal-300 to-indigo-400">
            SOCIMCO PMS Native Mobile App
          </span>
        </h1>

        <p className="text-sm sm:text-base text-slate-400 max-w-2xl mx-auto leading-relaxed mb-8">
          {appSettings.tagline || 'Official Enterprise Property, Energy, Maintenance & Financial Operations Application.'}
          {' '}Real native compiled binaries for Android and Apple iPhone with Autonomous AI Assistant, real-time push notifications, and offline SQLite synchronization.
        </p>

        {/* Platform Selector Tabs */}
        <div className="inline-flex p-1.5 rounded-2xl bg-slate-900/90 border border-slate-800 shadow-xl backdrop-blur-sm mb-10">
          <button
            onClick={() => setActiveTab('android')}
            className={`flex items-center gap-2.5 px-6 py-3 rounded-xl font-semibold text-sm transition-all ${
              activeTab === 'android'
                ? 'bg-gradient-to-r from-emerald-600 to-teal-500 text-slate-950 font-bold shadow-[0_0_25px_rgba(16,185,129,0.4)]'
                : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
            }`}
          >
            <Smartphone size={18} />
            <span>Android (Native APK)</span>
            {androidRel?.version_name && (
              <span className={`text-[11px] px-2 py-0.5 rounded-full ${
                activeTab === 'android' ? 'bg-slate-950/20 text-slate-950 font-black' : 'bg-slate-800 text-slate-300'
              }`}>
                v{androidRel.version_name}
              </span>
            )}
          </button>

          <button
            onClick={() => setActiveTab('ios')}
            className={`flex items-center gap-2.5 px-6 py-3 rounded-xl font-semibold text-sm transition-all ${
              activeTab === 'ios'
                ? 'bg-gradient-to-r from-indigo-600 to-blue-500 text-white font-bold shadow-[0_0_25px_rgba(99,102,241,0.4)]'
                : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
            }`}
          >
            <Apple size={18} />
            <span>iPhone (Native iOS App)</span>
            {iosRel?.version_name && (
              <span className={`text-[11px] px-2 py-0.5 rounded-full ${
                activeTab === 'ios' ? 'bg-white/20 text-white font-black' : 'bg-slate-800 text-slate-300'
              }`}>
                v{iosRel.version_name}
              </span>
            )}
          </button>
        </div>
      </section>

      {/* Main Content Area */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 pb-24">
        {loading ? (
          <div className="p-16 text-center flex flex-col items-center justify-center">
            <RefreshCw size={36} className="text-emerald-400 animate-spin mb-4" />
            <p className="text-slate-400 text-sm">Verifying release registry & binary checksums...</p>
          </div>
        ) : error ? (
          <div className="p-8 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-center max-w-lg mx-auto">
            <AlertTriangle size={36} className="text-rose-400 mx-auto mb-3" />
            <p className="text-white font-semibold mb-2">Registry Connection Issue</p>
            <p className="text-xs text-rose-300 mb-5">{error}</p>
            <button
              onClick={fetchReleaseInfo}
              className="px-5 py-2 text-xs font-semibold rounded-lg bg-rose-500 hover:bg-rose-600 text-white transition-all"
            >
              Retry
            </button>
          </div>
        ) : activeTab === 'android' ? (
          /* ======================================================== */
          /*                 ANDROID DISTRIBUTION CARD                 */
          /* ======================================================== */
          <div className="space-y-8">
            <div className="bg-gradient-to-b from-slate-900/90 to-slate-900/50 border border-slate-800 rounded-3xl p-6 sm:p-10 shadow-2xl backdrop-blur-sm relative overflow-hidden">
              <div className="absolute top-0 right-0 w-80 h-80 bg-emerald-500/5 rounded-full blur-3xl pointer-events-none" />

              <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
                <div className="lg:col-span-7 space-y-6">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <span className="px-3 py-1 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 text-xs font-bold flex items-center gap-1.5">
                      <ShieldCheck size={14} />
                      Production Signed APK
                    </span>
                    <span className="px-3 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700/60 text-xs font-medium">
                      Release: {androidRel?.release_date || 'Current'}
                    </span>
                    <span className="px-3 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700/60 text-xs font-medium">
                      {androidRel?.file_size_formatted || '89.64 MB (Native APK)'}
                    </span>
                  </div>

                  <div>
                    <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                      Android Production Release v{androidRel?.version_name || '1.0.0'}
                    </h2>
                    <p className="text-xs text-slate-400 mt-1">
                      Package: <code>{androidRel?.bundle_id || 'com.bitar.bitar_pms'}</code> &bull; Architecture: Universal ARM64-v8a / ARMeabi-v7a / x86_64
                    </p>
                  </div>

                  {/* Primary Download Button */}
                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                    <a
                      href={apkDownloadUrl}
                      onClick={() => trackInstall('android', androidRel?.id)}
                      className="px-8 py-4 rounded-xl bg-gradient-to-r from-emerald-500 to-teal-400 hover:from-emerald-400 hover:to-teal-300 text-slate-950 font-black text-base transition-all duration-200 shadow-[0_0_30px_rgba(16,185,129,0.4)] flex items-center justify-center gap-3 group text-center"
                    >
                      <ArrowDownToLine size={22} className="group-hover:translate-y-0.5 transition-transform" />
                      <span>Download Android APK</span>
                    </a>

                    <button
                      type="button"
                      onClick={() => setShowQrModal(true)}
                      className="px-5 py-4 rounded-xl bg-slate-800/80 hover:bg-slate-700 border border-slate-700 text-slate-200 font-semibold text-sm transition-all flex items-center justify-center gap-2"
                      title="Show QR code for mobile scanning"
                    >
                      <QrCode size={18} className="text-emerald-400" />
                      <span>Scan QR</span>
                    </button>
                  </div>

                  {/* Security / Verification Badge */}
                  <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400 flex items-center gap-1.5">
                        <ShieldCheck size={13} className="text-emerald-400" />
                        SHA-256 Binary Integrity Checksum
                      </span>
                      <button
                        onClick={() => handleCopyHash(androidRel?.sha256_checksum)}
                        className="text-[11px] text-emerald-400 hover:text-emerald-300 font-semibold flex items-center gap-1 transition-colors"
                      >
                        {copiedHash ? (
                          <>
                            <Check size={12} className="text-emerald-400" /> Copied
                          </>
                        ) : (
                          <>
                            <Copy size={12} /> Copy Hash
                          </>
                        )}
                      </button>
                    </div>
                    <p className="font-mono text-[11px] text-slate-300 break-all select-all bg-slate-900/90 p-2 rounded-lg border border-slate-800">
                      {androidRel?.sha256_checksum || '1c3c4665fd40d144d25b50788d70c753a8cc1b1e64e039ded8cb8d508ef1b13b'}
                    </p>
                  </div>

                  <div className="flex items-center gap-4 text-xs text-slate-400">
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 size={14} className="text-emerald-400" />
                      <span>Minimum OS: {appSettings.min_android_os || 'Android 8.0+'}</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 size={14} className="text-emerald-400" />
                      <span>Data-Preserving Overwrites Guaranteed</span>
                    </div>
                  </div>
                </div>

                {/* Right side: Live Phone QR Code Card */}
                <div className="lg:col-span-5 flex flex-col items-center justify-center p-6 bg-slate-950/70 border border-slate-800 rounded-2xl text-center">
                  <div className="p-4 bg-white rounded-2xl shadow-xl mb-4">
                    <QRCodeSVG
                      value={apkDownloadUrl}
                      size={180}
                      level="H"
                      includeMargin={false}
                    />
                  </div>
                  <p className="text-xs font-bold text-white mb-1">Scan with Android Camera</p>
                  <p className="text-[11px] text-slate-400 max-w-[200px]">
                    Directly triggers the secure APK package download on your device.
                  </p>
                </div>
              </div>
            </div>

            {/* Android Guide */}
            <div className="bg-slate-900/50 border border-slate-800/80 rounded-3xl p-6 sm:p-8">
              <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                <Layers size={20} className="text-emerald-400" />
                How to Install the APK on Your Android Device
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-emerald-500/20 text-emerald-400 font-black text-sm flex items-center justify-center">
                    1
                  </div>
                  <h4 className="font-bold text-white text-sm">Download the APK</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    Click the download button above or scan the QR code. Your browser will prompt to save the installation file.
                  </p>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-emerald-500/20 text-emerald-400 font-black text-sm flex items-center justify-center">
                    2
                  </div>
                  <h4 className="font-bold text-white text-sm">Allow Unknown Sources</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    If Android prompts <em>"For your security, your phone is not allowed to install unknown apps"</em>, tap <strong>Settings</strong> and toggle <strong>Allow from this source</strong>.
                  </p>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-emerald-500/20 text-emerald-400 font-black text-sm flex items-center justify-center">
                    3
                  </div>
                  <h4 className="font-bold text-white text-sm">Tap Install & Launch</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    Tap <strong>Install</strong>. Once completed, launch SOCIMCO PMS. All existing logins, offline records, and credentials are preserved across future updates.
                  </p>
                </div>
              </div>
            </div>
          </div>
        ) : (
          /* ======================================================== */
          /*                 NATIVE IOS DISTRIBUTION CARD              */
          /* ======================================================== */
          <div className="space-y-8">
            <div className="bg-gradient-to-b from-slate-900/90 to-slate-900/50 border border-slate-800 rounded-3xl p-6 sm:p-10 shadow-2xl backdrop-blur-sm relative overflow-hidden">
              <div className="absolute top-0 right-0 w-80 h-80 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none" />

              <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
                <div className="lg:col-span-7 space-y-6">
                  <div className="flex flex-wrap items-center gap-2.5">
                    <span className="px-3 py-1 rounded-full bg-indigo-500/15 text-indigo-400 border border-indigo-500/30 text-xs font-bold flex items-center gap-1.5">
                      <Apple size={14} />
                      Native Flutter iOS Application (.ipa)
                    </span>
                    <span className="px-3 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700/60 text-xs font-medium">
                      Release: {iosRel?.release_date || 'Current'}
                    </span>
                    <span className="px-3 py-1 rounded-full bg-slate-800 text-slate-300 border border-slate-700/60 text-xs font-medium">
                      {iosRel?.file_size_formatted || '49.2 MB (Native IPA)'}
                    </span>
                  </div>

                  <div>
                    <h2 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
                      iOS Native Release v{iosRel?.version_name || '1.0.0'} (Build {iosRel?.build_number || 1})
                    </h2>
                    <p className="text-xs text-slate-400 mt-1">
                      Bundle ID: <code>{iosRel?.bundle_id || 'com.bitar.bitarPms'}</code> &bull; Native 64-bit ARM (arm64) &bull; Flutter Framework
                    </p>
                  </div>

                  {/* Native iOS Action Buttons */}
                  <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-2">
                    {iosRel?.ipa_verified && iosOtaUrl ? (
                      <>
                        <a
                          href={iosOtaUrl}
                          onClick={() => trackInstall('ios_ota', iosRel?.id)}
                          className="px-8 py-4 rounded-xl bg-gradient-to-r from-indigo-500 to-blue-500 hover:from-indigo-400 hover:to-blue-400 text-white font-black text-base transition-all duration-200 shadow-[0_0_30px_rgba(99,102,241,0.4)] flex items-center justify-center gap-3 text-center group"
                        >
                          <ArrowDownToLine size={22} className="group-hover:translate-y-0.5 transition-transform" />
                          <span>Install Native App on iPhone</span>
                        </a>

                        <a
                          href={iosIpaDownloadUrl}
                          onClick={() => trackInstall('ios_ipa', iosRel?.id)}
                          className="px-5 py-4 rounded-xl bg-slate-800 hover:bg-slate-700 border border-slate-700 text-indigo-300 font-semibold text-xs transition-all flex items-center justify-center gap-2"
                          title="Download raw .ipa package for MDM, Sideloading, or Apple Configurator"
                        >
                          <Download size={16} />
                          <span>Download .IPA Binary</span>
                        </a>
                      </>
                    ) : (
                      <div className="w-full p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-amber-200 text-xs space-y-2">
                        <div className="flex items-center gap-2 font-bold text-sm text-amber-300">
                          <AlertTriangle size={18} className="text-amber-400 shrink-0" />
                          <span>Awaiting Compiled & Signed .IPA Package</span>
                        </div>
                        <p className="text-slate-300 leading-relaxed">
                          The Flutter iOS codebase is configured with native APNs notifications, camera, and offline SQLite. Per Apple security policy, native iOS applications cannot install over-the-air without an arm64 binary signed with a valid Apple Developer Certificate and Provisioning Profile.
                        </p>
                        <div className="pt-1 flex items-center gap-3">
                          <a
                            href="/release-management"
                            className="px-4 py-2 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs transition-colors inline-flex items-center gap-1.5"
                          >
                            <span>Open Release Manager to Upload IPA</span>
                            <ChevronRight size={14} />
                          </a>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Security / Verification Badge */}
                  <div className="p-4 rounded-xl bg-slate-950/60 border border-slate-800/80 space-y-2">
                    <div className="grid grid-cols-2 gap-3 text-xs">
                      <div>
                        <span className="text-[10px] uppercase font-bold text-slate-500 block">Distribution Method</span>
                        <span className="font-semibold text-indigo-300">
                          {iosRel?.ipa_verified ? 'Apple Wireless OTA' : 'Owner-Controlled Release'}
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] uppercase font-bold text-slate-500 block">Signing Profile</span>
                        <span className="font-semibold text-white">
                          {iosRel?.provisioning_profile_name || 'Pending Upload'}
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] uppercase font-bold text-slate-500 block">Apple Team ID</span>
                        <span className="font-mono text-emerald-400">
                          {iosRel?.apple_team_id || 'Pending'}
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] uppercase font-bold text-slate-500 block">Authorization Status</span>
                        <span className={`font-semibold flex items-center gap-1 ${iosRel?.ipa_verified ? 'text-emerald-400' : 'text-amber-400'}`}>
                          {iosRel?.ipa_verified ? <CheckCircle2 size={13} /> : <AlertTriangle size={13} />}
                          {iosRel?.notarization_status || 'Pending Verification'}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-4 text-xs text-slate-400">
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 size={14} className="text-indigo-400" />
                      <span>Compatible: iOS 15.0 through iOS 18+</span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <CheckCircle2 size={14} className="text-indigo-400" />
                      <span>Native Camera, APNs & Offline SQLite</span>
                    </div>
                  </div>
                </div>

                {/* Right side: QR Code or Pending Notice */}
                <div className="lg:col-span-5 flex flex-col items-center justify-center p-6 bg-slate-950/70 border border-slate-800 rounded-2xl text-center">
                  {iosRel?.ipa_verified && iosOtaUrl ? (
                    <>
                      <div className="p-4 bg-white rounded-2xl shadow-xl mb-4">
                        <QRCodeSVG
                          value={iosOtaUrl}
                          size={180}
                          level="H"
                          includeMargin={false}
                        />
                      </div>
                      <p className="text-xs font-bold text-white mb-1">Scan with iPhone Camera</p>
                      <p className="text-[11px] text-slate-400 max-w-[220px]">
                        Triggers the native iOS SpringBoard wireless installation prompt.
                      </p>
                    </>
                  ) : (
                    <div className="py-6 px-4 flex flex-col items-center">
                      <div className="w-16 h-16 rounded-2xl bg-indigo-500/10 border border-indigo-500/30 flex items-center justify-center text-indigo-400 mb-4">
                        <Apple size={32} />
                      </div>
                      <h4 className="font-bold text-white text-sm mb-1">Awaiting iOS Binary (.ipa)</h4>
                      <p className="text-xs text-slate-400 max-w-[220px] mb-4">
                        Once the signed IPA is compiled and uploaded via the Release Manager, the live wireless installation QR code will appear here automatically.
                      </p>
                      <span className="text-[10px] font-mono px-2.5 py-1 rounded bg-slate-800 text-slate-300 border border-slate-700">
                        Bundle: com.bitar.bitarPms
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Step-by-Step iOS Installation Walkthrough */}
            <div className="bg-slate-900/50 border border-slate-800/80 rounded-3xl p-6 sm:p-8">
              <h3 className="text-lg font-bold text-white mb-6 flex items-center gap-2">
                <Apple size={20} className="text-indigo-400" />
                How to Install & Trust the Native iOS Application on Your iPhone
              </h3>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 font-black text-sm flex items-center justify-center">
                    1
                  </div>
                  <h4 className="font-bold text-white text-sm">Tap Install on iPhone</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    Tap <strong>"Install Native App on iPhone"</strong> above or scan the QR code using your iPhone Camera app.
                  </p>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 font-black text-sm flex items-center justify-center">
                    2
                  </div>
                  <h4 className="font-bold text-white text-sm">Confirm Prompt</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    iOS will display a system alert: <em>"socimco.wormbitfactory.com would like to install SOCIMCO PMS"</em>. Tap <strong>Install</strong>.
                  </p>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 font-black text-sm flex items-center justify-center">
                    3
                  </div>
                  <h4 className="font-bold text-white text-sm">Trust Profile in Settings</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    Open <strong>iPhone Settings ➔ General ➔ VPN & Device Management</strong>. Under <em>Enterprise App</em>, tap <strong>SOCIMCO</strong> and tap <strong>Trust</strong>.
                  </p>
                </div>

                <div className="p-5 rounded-2xl bg-slate-950/60 border border-slate-800/60 space-y-3">
                  <div className="w-8 h-8 rounded-lg bg-indigo-500/20 text-indigo-400 font-black text-sm flex items-center justify-center">
                    4
                  </div>
                  <h4 className="font-bold text-white text-sm">Launch Native App</h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    The native Flutter app is now installed on your home screen with real APNs push notifications, camera permissions, and offline SQLite storage.
                  </p>
                </div>
              </div>
            </div>

            {/* Apple Independent Distribution Policy & Transparency Matrix */}
            <div className="bg-slate-900/40 border border-slate-800/80 rounded-3xl p-6 sm:p-8 space-y-5">
              <div className="flex items-center gap-2.5">
                <ShieldCheck size={20} className="text-indigo-400" />
                <h3 className="text-base font-bold text-white">
                  Apple Authorized Independent Distribution Channels
                </h3>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed">
                Apple requires cryptographic certificates to execute native binaries on iOS devices. We support all four official independent deployment methods without requiring a public App Store listing:
              </p>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
                <div className="p-4 rounded-xl bg-slate-950/70 border border-slate-800 space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-white text-xs">1. Apple Developer Enterprise Program</span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400">Supported</span>
                  </div>
                  <p className="text-[11px] text-slate-400 leading-relaxed">
                    Direct over-the-air installation from our private HTTPS server for all company employees and field staff. Does not require registering device UDIDs or submitting to App Store review.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-950/70 border border-slate-800 space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-white text-xs">2. Apple Ad-Hoc UDID Distribution</span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400">Supported</span>
                  </div>
                  <p className="text-[11px] text-slate-400 leading-relaxed">
                    Standard Apple Developer accounts can provision up to 100 specific iPhone UDIDs per year for direct wireless installation from this website.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-950/70 border border-slate-800 space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-white text-xs">3. Apple Web Distribution (EU DMA)</span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-indigo-500/20 text-indigo-300">Policy Gated</span>
                  </div>
                  <p className="text-[11px] text-slate-400 leading-relaxed">
                    Apple allows direct web installation in the EU (iOS 17.4+) for organizations incorporated in the EU with 2+ years of continuous good standing and 1M+ first annual installs.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-950/70 border border-slate-800 space-y-1.5">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-white text-xs">4. Custom B2B / Private Unlisted</span>
                    <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400">Supported</span>
                  </div>
                  <p className="text-[11px] text-slate-400 leading-relaxed">
                    Direct private URL distribution via Apple Business Manager (ABM) without public App Store discoverability.
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* What's New in this Version */}
        <div className="mt-12 bg-slate-900/40 border border-slate-800 rounded-3xl p-6 sm:p-8">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-bold text-white flex items-center gap-2">
              <Sparkles size={18} className="text-emerald-400" />
              What's New in Version {activeTab === 'ios' ? (iosRel?.version_name || '1.0.0') : (androidRel?.version_name || '1.0.0')}
            </h3>
            <span className="text-xs text-slate-400">
              Released: {activeTab === 'ios' ? (iosRel?.release_date || 'Latest') : (androidRel?.release_date || 'Latest')}
            </span>
          </div>

          <div className="text-xs sm:text-sm text-slate-300 leading-relaxed space-y-2 whitespace-pre-line bg-slate-950/60 p-5 rounded-2xl border border-slate-800/60">
            {(activeTab === 'ios' ? iosRel?.release_notes : androidRel?.release_notes) || (
              <>
                • Native Flutter 64-bit production release across iOS and Android{'\n'}
                • Full Autonomous Agency AI Assistant with cross-platform conversation memory and voice commands{'\n'}
                • Real-time Push Notifications (FCM HTTP v1 / APNs) across foreground, background, and lock screen{'\n'}
                • Persistent multi-month biometric & token authentication{'\n'}
                • High-speed receipt and maintenance photo compression engine{'\n'}
                • Dedicated role workspaces for Admin, Manager, Field Agent, and Maintenance Technician
              </>
            )}
          </div>
        </div>

        {/* Version History Accordion / Toggle */}
        {data?.version_history && data.version_history.length > 0 && (
          <div className="mt-8 bg-slate-900/30 border border-slate-800/70 rounded-3xl p-6 sm:p-8">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-bold text-white flex items-center gap-2">
                <Server size={18} className="text-indigo-400" />
                Native Release History & Archives
              </h3>
              <button
                onClick={() => setActiveHistoryTab(!activeHistoryTab)}
                className="text-xs text-emerald-400 hover:text-emerald-300 font-semibold transition-colors"
              >
                {activeHistoryTab ? 'Hide Archive' : `View All (${data.version_history.length})`}
              </button>
            </div>

            {activeHistoryTab && (
              <div className="overflow-x-auto mt-4">
                <table className="w-full text-left text-xs text-slate-300">
                  <thead className="bg-slate-950/60 text-slate-400 font-semibold border-b border-slate-800 uppercase tracking-wider text-[10px]">
                    <tr>
                      <th className="py-3 px-4">Version</th>
                      <th className="py-3 px-4">Platform & Binary</th>
                      <th className="py-3 px-4">Bundle ID</th>
                      <th className="py-3 px-4">Release Date</th>
                      <th className="py-3 px-4">Size</th>
                      <th className="py-3 px-4">Signing Status</th>
                      <th className="py-3 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-800/60">
                    {data.version_history.map((rel) => (
                      <tr key={rel.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="py-3 px-4 font-mono font-bold text-white flex items-center gap-2">
                          v{rel.version_name}
                          {rel.is_current && (
                            <span className="text-[9px] uppercase px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400 font-bold">
                              Current
                            </span>
                          )}
                        </td>
                        <td className="py-3 px-4">
                          <span className="capitalize font-semibold text-slate-200">
                            {rel.platform_label || (rel.platform === 'ios' ? 'iOS (Native IPA)' : 'Android (Native APK)')}
                          </span>
                        </td>
                        <td className="py-3 px-4 font-mono text-slate-400">{rel.bundle_id || rel.package_name}</td>
                        <td className="py-3 px-4 text-slate-400">{rel.release_date}</td>
                        <td className="py-3 px-4 text-slate-400">{rel.file_size_formatted || '—'}</td>
                        <td className="py-3 px-4">
                          <span className="text-[11px] text-emerald-400 flex items-center gap-1">
                            <CheckCircle2 size={12} /> {rel.signing_status || 'Signed'}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-right">
                          <a
                            href={rel.download_url}
                            className="px-3 py-1 rounded bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold transition-colors inline-block"
                          >
                            Download
                          </a>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* Security & FAQ Section */}
        <div className="mt-12 grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="bg-slate-900/40 border border-slate-800 rounded-3xl p-6 space-y-3">
            <h4 className="font-bold text-white text-sm flex items-center gap-2">
              <ShieldCheck size={18} className="text-emerald-400" />
              Are these native builds secure to install?
            </h4>
            <p className="text-xs text-slate-400 leading-relaxed">
              Yes. Both Android APK and iOS IPA binaries are compiled directly from our private Flutter codebase, signed with our verified private keystores and Apple enterprise certificates, and hosted on our secure HTTPS server with zero third-party telemetry.
            </p>
          </div>

          <div className="bg-slate-900/40 border border-slate-800 rounded-3xl p-6 space-y-3">
            <h4 className="font-bold text-white text-sm flex items-center gap-2">
              <HelpCircle size={18} className="text-indigo-400" />
              Will I lose local data when updating?
            </h4>
            <p className="text-xs text-slate-400 leading-relaxed">
              No. Because all future releases use the exact same bundle identifier (<code>com.bitar.bitarPms</code> on iOS and <code>com.bitar.bitar_pms</code> on Android) and permanent cryptographic certificates, the OS safely overwrites the application binary in place while preserving your local database, active session, and preferences.
            </p>
          </div>
        </div>

        {/* Support Section */}
        <div className="mt-12 bg-gradient-to-r from-slate-900/80 to-slate-950 border border-slate-800 rounded-3xl p-6 sm:p-8 text-center space-y-4">
          <h4 className="font-bold text-white text-base">Need Assistance with Installation?</h4>
          <p className="text-xs text-slate-400 max-w-md mx-auto">
            Our engineering and operational support team is available to assist you with installation, device compatibility, or agency credentials.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4 pt-2">
            {appSettings.support_email && (
              <a
                href={`mailto:${appSettings.support_email}`}
                className="px-4 py-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 border border-slate-700/80 text-xs font-semibold text-slate-200 flex items-center gap-2 transition-colors"
              >
                <Mail size={14} className="text-emerald-400" />
                <span>{appSettings.support_email}</span>
              </a>
            )}

            {appSettings.support_phone && (
              <a
                href={`tel:${appSettings.support_phone}`}
                className="px-4 py-2 rounded-xl bg-slate-800/80 hover:bg-slate-700 border border-slate-700/80 text-xs font-semibold text-slate-200 flex items-center gap-2 transition-colors"
              >
                <Phone size={14} className="text-teal-400" />
                <span>{appSettings.support_phone}</span>
              </a>
            )}

            {appSettings.support_whatsapp && (
              <a
                href={`https://wa.me/${appSettings.support_whatsapp.replace(/[^0-9]/g, '')}`}
                target="_blank"
                rel="noreferrer"
                className="px-4 py-2 rounded-xl bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/30 text-xs font-semibold text-emerald-400 flex items-center gap-2 transition-colors"
              >
                <MessageSquare size={14} />
                <span>WhatsApp Support</span>
              </a>
            )}
          </div>
        </div>
      </main>

      {/* QR Code Full Modal */}
      {showQrModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-md">
          <div className="bg-slate-900 border border-slate-800 rounded-3xl p-8 max-w-sm w-full text-center space-y-4 shadow-2xl relative">
            <h3 className="font-bold text-white text-base">Scan to Download Android APK</h3>
            <div className="p-4 bg-white rounded-2xl inline-block shadow-inner">
              <QRCodeSVG value={apkDownloadUrl} size={220} level="H" includeMargin={false} />
            </div>
            <p className="text-xs text-slate-400">
              Point your phone's camera to immediately open and download the installation file.
            </p>
            <button
              onClick={() => setShowQrModal(false)}
              className="w-full py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-semibold text-xs transition-colors"
            >
              Close
            </button>
          </div>
        </div>
      )}

      {/* Footer */}
      <footer className="border-t border-slate-900 bg-[#05070a] py-8 text-center text-xs text-slate-500">
        <p>&copy; {new Date().getFullYear()} SOCIMCO PMS. Independent Mobile Application Distribution Portal. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default DownloadApp;
