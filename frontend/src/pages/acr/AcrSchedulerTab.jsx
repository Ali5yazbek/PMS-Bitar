import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CalendarClock, Play, CheckCircle2, Clock, Calendar, RefreshCw } from 'lucide-react';
import api from '../../api/axios';

const JOB_CONFIGS = [
  {
    id: 'daily_scan',
    label: 'Daily Audit Scan',
    icon: '🕐',
    description: 'Scans all modules for data quality issues',
    scheduleKey: 'daily_scan_time',
    enabledKey: 'daily_scan_enabled',
    triggerEndpoint: '/action-control/run-audit',
    defaultTime: '02:00',
  },
  {
    id: 'integrity_scan',
    label: 'Integrity Scan',
    icon: '🔍',
    description: 'Detects duplicates, orphans, and broken relationships',
    scheduleKey: 'integrity_scan_time',
    enabledKey: 'duplicate_scan_enabled',
    triggerEndpoint: '/integrity/run',
    defaultTime: '03:00',
  },
  {
    id: 'financial_scan',
    label: 'Financial Audit',
    icon: '💰',
    description: 'Validates payments, invoices, and financial integrity',
    scheduleKey: 'financial_scan_time',
    enabledKey: 'financial_scan_enabled',
    triggerEndpoint: '/integrity/run',
    defaultTime: '04:00',
  },
];

export default function AcrSchedulerTab({ isAdmin }) {
  const queryClient = useQueryClient();
  const [running, setRunning] = useState(null);
  const [results, setResults] = useState({});

  const { data: settings } = useQuery({
    queryKey: ['enterprise-settings'],
    queryFn: async () => (await api.get('/system-health/settings')).data,
  });
  const { data: lastScan } = useQuery({
    queryKey: ['acr-dashboard'],
    queryFn: async () => (await api.get('/action-control/dashboard')).data,
  });

  const settingsMap = {};
  (settings || []).forEach(s => { settingsMap[s.setting_key] = s.value; });

  const saveMutation = useMutation({
    mutationFn: (body) => api.put('/system-health/settings', body),
    onSuccess: () => queryClient.invalidateQueries(['enterprise-settings']),
  });

  const handleToggle = (key, currentVal) => {
    const newVal = currentVal === '1' ? '0' : '1';
    saveMutation.mutate([{ setting_key: key, value: newVal }]);
  };

  const handleTimeChange = (key, val) => {
    saveMutation.mutate([{ setting_key: key, value: val }]);
  };

  const handleRunNow = async (job) => {
    setRunning(job.id);
    try {
      const res = await api.post(job.triggerEndpoint);
      setResults(r => ({ ...r, [job.id]: res.data }));
      queryClient.invalidateQueries(['acr-dashboard']);
    } catch (e) {
      setResults(r => ({ ...r, [job.id]: { error: 'Failed' } }));
    }
    setRunning(null);
  };

  return (
    <div className="space-y-5">
      {/* Next Scheduled Scan info */}
      {lastScan?.last_scan && (
        <div className="bg-slate-800/60 border border-slate-700/50 rounded-2xl p-4 flex items-center gap-4">
          <CalendarClock size={24} className="text-indigo-400 shrink-0" />
          <div>
            <div className="text-sm font-bold text-white">Last Scan</div>
            <div className="text-xs text-slate-400 mt-0.5">
              {new Date(lastScan.last_scan.created_at).toLocaleString()} •
              Found {lastScan.last_scan.total_issues_found} issues
            </div>
          </div>
          <div className="ml-auto text-right">
            <div className="text-xs text-slate-500">Next Daily Scan</div>
            <div className="text-sm font-bold text-indigo-300">Today at {settingsMap.daily_scan_time || '02:00'}</div>
          </div>
        </div>
      )}

      {/* Job cards */}
      <div className="space-y-4">
        {JOB_CONFIGS.map(job => {
          const enabled = settingsMap[job.enabledKey] === '1';
          const time    = settingsMap[job.scheduleKey] || job.defaultTime;
          const result  = results[job.id];
          const isRunning = running === job.id;
          return (
            <div key={job.id} className={`rounded-2xl border p-5 transition-all ${enabled ? 'bg-slate-800/60 border-slate-700/50' : 'bg-slate-900/40 border-slate-800/40 opacity-70'}`}>
              <div className="flex items-start gap-4 flex-wrap">
                <div className="text-3xl shrink-0">{job.icon}</div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-3 flex-wrap">
                    <h3 className="font-bold text-white">{job.label}</h3>
                    {/* Enabled toggle */}
                    <div onClick={() => isAdmin && handleToggle(job.enabledKey, enabled ? '1' : '0')}
                      className={`w-11 h-6 rounded-full cursor-pointer transition-colors relative shrink-0 ${enabled ? 'bg-indigo-600' : 'bg-slate-600'} ${!isAdmin ? 'pointer-events-none' : ''}`}>
                      <div className={`absolute top-1 left-1 w-4 h-4 rounded-full bg-white transition-transform ${enabled ? 'translate-x-5' : ''}`} />
                    </div>
                    <span className={`text-xs font-semibold ${enabled ? 'text-emerald-400' : 'text-slate-500'}`}>{enabled ? 'Enabled' : 'Disabled'}</span>
                  </div>
                  <p className="text-xs text-slate-400 mt-1">{job.description}</p>

                  {/* Schedule times */}
                  <div className="mt-3 flex flex-wrap gap-4">
                    <div className="flex items-center gap-2">
                      <Clock size={14} className="text-slate-400" />
                      <span className="text-xs text-slate-400">Daily at</span>
                      <input type="time" value={time} disabled={!isAdmin}
                        onChange={e => handleTimeChange(job.scheduleKey, e.target.value)}
                        className="bg-slate-700 border border-slate-600 text-white rounded-lg px-2 py-1 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500 disabled:opacity-50" />
                    </div>
                    <div className="flex items-center gap-2">
                      <Calendar size={14} className="text-slate-400" />
                      <span className="text-xs text-slate-400">Weekly:</span>
                      <select disabled={!isAdmin} className="bg-slate-700 border border-slate-600 text-white rounded-lg px-2 py-1 text-xs focus:outline-none focus:ring-1 focus:ring-indigo-500 disabled:opacity-50">
                        {['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'].map(d => <option key={d}>{d}</option>)}
                      </select>
                    </div>
                  </div>
                </div>

                {/* Run Now */}
                {isAdmin && (
                  <button onClick={() => !isRunning && handleRunNow(job)} disabled={isRunning}
                    className="flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-500 hover:to-purple-500 text-white rounded-xl text-sm font-semibold transition-all shadow-lg disabled:opacity-50 shrink-0">
                    {isRunning ? <RefreshCw size={15} className="animate-spin" /> : <Play size={15} />}
                    {isRunning ? 'Running…' : 'Run Now'}
                  </button>
                )}
              </div>

              {/* Result */}
              {result && (
                <div className={`mt-3 px-4 py-2.5 rounded-xl text-sm border ${result.error ? 'bg-red-950/30 border-red-500/20 text-red-400' : 'bg-emerald-950/30 border-emerald-500/20 text-emerald-400'}`}>
                  {result.error ? `❌ ${result.error}` : (
                    result.result
                      ? `✅ Complete — Found ${result.result.total} issues (${result.result.critical} critical, ${result.result.warning} warning)`
                      : '✅ Scan complete'
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Windows Task Scheduler instructions */}
      <div className="bg-slate-900/60 border border-slate-700/40 rounded-2xl p-5">
        <h3 className="font-bold text-white text-sm mb-3 flex items-center gap-2">
          <CalendarClock size={16} className="text-amber-400" />Windows Task Scheduler Setup
        </h3>
        <p className="text-xs text-slate-400 mb-3">To automate scans, add the following to Windows Task Scheduler:</p>
        <pre className="bg-slate-800 rounded-xl p-4 text-xs text-emerald-300 overflow-x-auto">
{`Program:   php.exe
Arguments: "d:\\xamp\\htdocs\\Bitar\\backend\\cron\\audit_daily_scan.php"
Schedule:  Daily at 02:00 AM
Log file:  d:\\xamp\\htdocs\\Bitar\\backend\\cron\\audit_scan.log`}
        </pre>
      </div>
    </div>
  );
}
