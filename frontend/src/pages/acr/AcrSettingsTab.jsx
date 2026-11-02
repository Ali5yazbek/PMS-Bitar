import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Settings2, Save, Bell, Clock, Zap, Shield, ToggleLeft } from 'lucide-react';
import api from '../../api/axios';

const SETTINGS_CONFIG = [
  {
    category: 'notifications',
    label: '🔔 Notifications',
    settings: [
      { key:'notify_critical_count',  label:'Notify managers when critical issues ≥',  type:'number', placeholder:'3' },
      { key:'notify_unresolved_days', label:'Alert Super Admin when issues unresolved for ≥ days', type:'number', placeholder:'30' },
    ],
  },
  {
    category: 'sla',
    label: '⏱️ SLA Thresholds',
    settings: [
      { key:'sla_critical_hours', label:'SLA hours for Critical issues', type:'number', placeholder:'24' },
      { key:'sla_warning_hours',  label:'SLA hours for Warning issues',  type:'number', placeholder:'72' },
    ],
  },
  {
    category: 'scheduler',
    label: '📅 Scheduler',
    settings: [
      { key:'daily_scan_enabled',  label:'Enable Daily Audit Scan',        type:'toggle' },
      { key:'daily_scan_time',     label:'Daily scan time',                type:'time', placeholder:'02:00' },
      { key:'weekly_scan_day',     label:'Weekly scan day (0=Sunday…6=Sat)',type:'number', placeholder:'0' },
    ],
  },
  {
    category: 'integrity',
    label: '🔍 Data Integrity',
    settings: [
      { key:'duplicate_scan_enabled',  label:'Enable Duplicate Detection',     type:'toggle' },
      { key:'financial_scan_enabled',  label:'Enable Financial Audit',         type:'toggle' },
    ],
  },
  {
    category: 'autofix',
    label: '⚡ Auto-Fix',
    settings: [
      { key:'auto_fix_enabled', label:'Enable Auto-Fix Suggestions', type:'toggle' },
    ],
  },
];

export default function AcrSettingsTab({ isAdmin }) {
  const queryClient = useQueryClient();
  const [localSettings, setLocalSettings] = useState({});
  const [saved, setSaved] = useState(false);

  const { data: settings } = useQuery({
    queryKey: ['enterprise-settings'],
    queryFn: async () => (await api.get('/system-health/settings')).data,
  });

  const settingsMap = {};
  (settings || []).forEach(s => { settingsMap[s.setting_key] = s.value; });

  const effective = { ...settingsMap, ...localSettings };

  const saveMutation = useMutation({
    mutationFn: (body) => api.put('/system-health/settings', body),
    onSuccess: () => {
      queryClient.invalidateQueries(['enterprise-settings']);
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
      setLocalSettings({});
    },
  });

  const handleChange = (key, value) => {
    setLocalSettings(prev => ({ ...prev, [key]: value }));
  };

  const handleSaveAll = () => {
    const updates = Object.entries({ ...settingsMap, ...localSettings }).map(([k, v]) => ({
      setting_key: k, value: String(v)
    }));
    saveMutation.mutate(updates);
  };

  const hasChanges = Object.keys(localSettings).length > 0;

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div className="flex items-center gap-2">
          <Settings2 size={20} className="text-indigo-400" />
          <h3 className="font-bold text-white">Enterprise Control Settings</h3>
          {hasChanges && (
            <span className="bg-amber-500/20 text-amber-400 text-xs px-2 py-0.5 rounded-full border border-amber-500/20">
              {Object.keys(localSettings).length} unsaved changes
            </span>
          )}
        </div>
        {isAdmin && (
          <button onClick={handleSaveAll} disabled={!hasChanges || saveMutation.isPending}
            className="flex items-center gap-2 px-5 py-2 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg disabled:opacity-40">
            <Save size={15} />{saveMutation.isPending ? 'Saving…' : 'Save All Settings'}
          </button>
        )}
      </div>

      {saved && (
        <div className="bg-emerald-900/40 border border-emerald-500/30 rounded-xl px-4 py-3 text-emerald-400 text-sm font-semibold flex items-center gap-2">
          ✅ Settings saved successfully
        </div>
      )}

      {/* Settings sections */}
      {SETTINGS_CONFIG.map(section => (
        <div key={section.category} className="bg-slate-800/60 border border-slate-700/50 rounded-2xl overflow-hidden">
          <div className="px-5 py-3 bg-slate-800/80 border-b border-slate-700/40">
            <h4 className="font-bold text-white text-sm">{section.label}</h4>
          </div>
          <div className="p-5 space-y-4">
            {section.settings.map(setting => {
              const currentVal = effective[setting.key] ?? '';
              return (
                <div key={setting.key} className="flex items-center gap-4 flex-wrap">
                  <label className="text-sm text-slate-300 flex-1 min-w-[200px]">{setting.label}</label>
                  <div className="shrink-0">
                    {setting.type === 'toggle' ? (
                      <div className="flex items-center gap-3">
                        <div
                          onClick={() => isAdmin && handleChange(setting.key, currentVal === '1' ? '0' : '1')}
                          className={`w-12 h-6 rounded-full transition-colors relative ${isAdmin ? 'cursor-pointer' : 'cursor-not-allowed opacity-60'} ${currentVal === '1' ? 'bg-indigo-600' : 'bg-slate-600'}`}>
                          <div className={`absolute top-1 left-1 w-4 h-4 rounded-full bg-white transition-transform ${currentVal === '1' ? 'translate-x-6' : ''}`} />
                        </div>
                        <span className={`text-sm font-semibold ${currentVal === '1' ? 'text-emerald-400' : 'text-slate-500'}`}>
                          {currentVal === '1' ? 'Enabled' : 'Disabled'}
                        </span>
                      </div>
                    ) : setting.type === 'time' ? (
                      <input type="time" value={currentVal} disabled={!isAdmin}
                        onChange={e => handleChange(setting.key, e.target.value)}
                        className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 disabled:opacity-50 w-36" />
                    ) : (
                      <input type="number" value={currentVal} disabled={!isAdmin}
                        placeholder={setting.placeholder}
                        onChange={e => handleChange(setting.key, e.target.value)}
                        className="bg-slate-700 border border-slate-600 text-white rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 disabled:opacity-50 w-28 text-center" />
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      ))}

      {/* Notification preview */}
      <div className="bg-slate-900/60 border border-slate-700/40 rounded-2xl p-5">
        <h4 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Bell size={16} className="text-amber-400" />Notification Preview</h4>
        <div className="space-y-3">
          <div className="bg-amber-950/30 border border-amber-500/20 rounded-xl p-3 text-xs text-amber-300">
            <strong>Manager Notification:</strong> "You have {effective.notify_critical_count || 3}+ critical problems that require immediate attention."
          </div>
          <div className="bg-red-950/30 border border-red-500/20 rounded-xl p-3 text-xs text-red-300">
            <strong>Director Alert:</strong> "3 Critical Problems waiting for approval."
          </div>
          <div className="bg-purple-950/30 border border-purple-500/20 rounded-xl p-3 text-xs text-purple-300">
            <strong>Super Admin Alert:</strong> "Issues unresolved for {effective.notify_unresolved_days || 30}+ days require escalation."
          </div>
        </div>
      </div>

      {/* SLA visualization */}
      <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-5">
        <h4 className="font-bold text-white text-sm mb-4 flex items-center gap-2"><Clock size={16} className="text-blue-400" />SLA Timeline</h4>
        <div className="space-y-3">
          {[
            { label:'Critical issue detected', time:0, color:'text-red-400' },
            { label:'SLA deadline for critical', time:parseInt(effective.sla_critical_hours||24), color:'text-amber-400' },
            { label:'SLA deadline for warnings', time:parseInt(effective.sla_warning_hours||72), color:'text-yellow-400' },
            { label:'Super Admin escalation', time:parseInt(effective.notify_unresolved_days||30)*24, color:'text-purple-400' },
          ].map((item, i) => (
            <div key={i} className="flex items-center gap-3 text-sm">
              <div className={`font-bold w-20 text-right shrink-0 ${item.color}`}>
                {item.time === 0 ? 'Now' : item.time < 48 ? `${item.time}h` : `${Math.round(item.time/24)}d`}
              </div>
              <div className="w-3 h-3 rounded-full bg-slate-600 border-2 border-current shrink-0" style={{ borderColor: 'currentColor' }} />
              <span className="text-slate-300">{item.label}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
