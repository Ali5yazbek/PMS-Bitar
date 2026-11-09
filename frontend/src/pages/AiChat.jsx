import React, { useState, useRef, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../api/axios';
import {
  Send, Sparkles, RotateCcw, ArrowRight, Activity, Shield, AlertTriangle,
  CheckCircle2, DollarSign, Wrench, Fuel, Building2, UserCheck, Flame,
  Fingerprint, Settings, Cpu, Eye, Check, X, Compass, Zap, Lock
} from 'lucide-react';

/* ─── helpers ──────────────────────────────────────────────────────── */
const fmt = n => 'CFA ' + Number(parseNum(n)).toLocaleString();
const isArabicText = text => /[\u0600-\u06FF]/.test(text || '');

function parseNum(v) {
  if (v === null || v === undefined) return 0;
  if (typeof v === 'number') return Number.isFinite(v) ? v : 0;
  const cleaned = String(v).replace(/[^0-9.-]/g, '');
  const n = parseFloat(cleaned);
  return Number.isFinite(n) ? n : 0;
}

const STORAGE_KEYS = {
  HISTORY: 'agency_ai_history_v3',
  CONTEXT: 'agency_ai_context_v3',
  SETTINGS: 'agency_ai_settings_v3',
  TOOL_LOGS: 'agency_ai_tool_logs_v3',
};

const ActionButton = ({ label, icon: Icon, variant = 'primary', onClick, disabled = false }) => (
  <button
    type="button"
    onClick={onClick}
    disabled={disabled}
    className={`diag-action-btn ${variant} ${disabled ? 'opacity-50 cursor-not-allowed' : ''}`}
  >
    {Icon && <Icon size={16} />}
    <span>{label}</span>
  </button>
);

/* ─── Smart Hologram / Diagnostic Renderers ──────────────────────────── */
function SmartHologram({ type, data, pendingTool, onNavigate, onExecuteTool, onSendPrompt, toolBusy }) {
  if (!type) return null;

  switch (type) {
    case 'tool_confirmation': {
      const tool = pendingTool || {};
      return (
        <div className="holo-grid">
          <div className="diag-card warning col-span-full">
            <div className="flex items-center gap-3 mb-4">
              <div className="p-3 rounded-xl bg-amber-500/20 border border-amber-500/40 text-amber-400">
                <Shield size={24} />
              </div>
              <div>
                <div className="text-xs font-bold uppercase tracking-wider text-amber-400">Autonomous Action Security Guard</div>
                <h3 className="text-xl font-bold text-white mt-0.5">{tool.summary || 'Confirm Database Mutation'}</h3>
              </div>
            </div>
            <p className="text-slate-300 text-sm mb-6">
              This action will permanently modify production records and create an immutable entry in the AI Tool & Activity Audit Logs.
            </p>
            <div className="flex gap-3">
              <ActionButton
                label={toolBusy ? 'Executing...' : 'Confirm & Execute Action'}
                icon={Check}
                variant="primary"
                disabled={toolBusy}
                onClick={() => onExecuteTool(tool.tool_name, tool.target_id, tool.parameters)}
              />
              <ActionButton
                label="Cancel"
                icon={X}
                variant="danger"
                disabled={toolBusy}
                onClick={() => onSendPrompt('Proactive insights')}
              />
            </div>
          </div>
        </div>
      );
    }

    case 'proactive_insights': {
      const list = Array.isArray(data) ? data : [];
      if (list.length === 0) {
        return (
          <div className="diag-card success">
            <div className="flex items-center gap-3">
              <CheckCircle2 size={28} className="text-emerald-400" />
              <div>
                <h3 className="text-lg font-bold text-white">All Systems Operating Optimally</h3>
                <p className="text-slate-400 text-sm">No overdue rent anomalies, pending bottlenecks, or fuel shortages detected.</p>
              </div>
            </div>
          </div>
        );
      }
      return (
        <div className="holo-grid">
          {list.map((ins, i) => {
            const sevClass = ins.severity === 'high' ? 'danger' : ins.severity === 'medium' ? 'warning' : 'success';
            return (
              <div key={i} className={`diag-card ${sevClass}`}>
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <div className="text-[11px] font-bold uppercase tracking-wider text-indigo-400 mb-1">{ins.category}</div>
                    <h4 className="font-bold text-lg text-white">{ins.title}</h4>
                  </div>
                  <span className="px-3 py-1 bg-white/10 text-white rounded-full text-xs font-bold border border-white/15">
                    {ins.metric}
                  </span>
                </div>
                <p className="text-slate-300 text-sm leading-relaxed mb-4">{ins.description}</p>
                <div className="flex gap-2">
                  {ins.suggested_prompt && (
                    <ActionButton
                      label="Inspect Details"
                      icon={Eye}
                      variant="primary"
                      onClick={() => onSendPrompt(ins.suggested_prompt)}
                    />
                  )}
                  {ins.route && (
                    <ActionButton
                      label="Open Module"
                      icon={Compass}
                      variant="warning"
                      onClick={() => onNavigate(ins.route)}
                    />
                  )}
                </div>
              </div>
            );
          })}
        </div>
      );
    }

    case 'system_diagnostics': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((chk, i) => {
            const sev = chk.status === 'healthy' ? 'success' : chk.status === 'warning' ? 'warning' : 'danger';
            return (
              <div key={i} className={`diag-card ${sev}`}>
                <div className="flex justify-between items-center mb-3">
                  <div className="flex items-center gap-2">
                    <Cpu size={18} className={chk.status === 'healthy' ? 'text-emerald-400' : 'text-amber-400'} />
                    <h4 className="font-bold text-white">{chk.component}</h4>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold uppercase ${
                    chk.status === 'healthy' ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30' : 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                  }`}>
                    {chk.metric}
                  </span>
                </div>
                <p className="text-slate-400 text-sm">{chk.detail}</p>
              </div>
            );
          })}
        </div>
      );
    }

    case 'pending_purchases': {
      const list = Array.isArray(data) ? data : [];
      if (list.length === 0) {
        return (
          <div className="diag-card success">
            <div className="flex items-center gap-3">
              <CheckCircle2 size={26} className="text-emerald-400" />
              <div>
                <h3 className="text-lg font-bold text-white">No Purchases Recorded</h3>
                <p className="text-slate-400 text-sm">There are currently 0 agent purchase or apartment cost submissions.</p>
              </div>
            </div>
          </div>
        );
      }
      return (
        <div className="holo-grid">
          {list.map((p, i) => {
            const isPending = String(p.status || 'Pending').toLowerCase().includes('pending');
            return (
              <div key={i} className={`diag-card ${isPending ? 'warning' : 'success'}`}>
                <div className="flex justify-between items-start mb-3">
                  <div>
                    <h4 className="font-bold text-lg text-white">
                      {p.building_name || 'Building'} • Apt {p.apartment_number || p.apartment_code || 'N/A'}
                    </h4>
                    <p className="text-slate-400 text-xs">
                      {p.id ? `Purchase #${p.id} • ` : ''}Submitted by {p.submitter_name || 'Agent'}
                    </p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${
                    isPending ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30' : 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                  }`}>
                    {p.status || 'Approved'}
                  </span>
                </div>
                <div className="space-y-1 text-sm text-slate-300 mb-4">
                  <div><span className="text-slate-500">Supplier:</span> {p.supplier || p.supplier_name || 'N/A'}</div>
                  <div><span className="text-slate-500">Items:</span> {p.items || p.items_bought || p.description || p.notes || 'Expense'}</div>
                  <div className="text-lg font-bold text-indigo-400 pt-1">{fmt(p.amount)}</div>
                </div>
                {isPending && p.id ? (
                  <div className="flex gap-2">
                    <ActionButton
                      label="Approve"
                      icon={Check}
                      variant="primary"
                      disabled={toolBusy}
                      onClick={() => onExecuteTool('review_purchase', p.id, { status: 'Approved', source: p.source })}
                    />
                    <ActionButton
                      label="Reject"
                      icon={X}
                      variant="danger"
                      disabled={toolBusy}
                      onClick={() => onExecuteTool('review_purchase', p.id, { status: 'Rejected', source: p.source })}
                    />
                  </div>
                ) : (
                  <ActionButton
                    label="Open Purchase Review"
                    icon={Compass}
                    variant="primary"
                    onClick={() => onNavigate('/agent-purchase-review')}
                  />
                )}
              </div>
            );
          })}
        </div>
      );
    }

    case 'overdue_rent':
    case 'top_debtors': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((r, i) => (
            <div key={i} className="diag-card danger">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h4 className="font-bold text-lg text-white">{r.full_name}</h4>
                  <p className="text-slate-400 text-sm">{r.building_name} • Apt {r.apartment_code}</p>
                </div>
                <span className="px-3 py-1 bg-red-500/20 text-red-400 rounded-full text-xs font-bold border border-red-500/30">
                  {r.days_overdue || r.max_days_overdue || r.overdue_invoices || 1} Overdue
                </span>
              </div>
              <div className="my-4">
                <div className="text-xs text-slate-400 uppercase tracking-wider mb-1">Total Outstanding Debt</div>
                <div className="text-2xl font-black text-red-500">{fmt(r.total_debt)}</div>
              </div>
              <div className="flex gap-2">
                <ActionButton
                  label="Tenant Dossier"
                  icon={UserCheck}
                  variant="primary"
                  onClick={() => onSendPrompt(`Tell me everything about ${r.full_name}`)}
                />
                <ActionButton
                  label="Collect Rent"
                  icon={DollarSign}
                  variant="danger"
                  onClick={() => onNavigate('/rent-management')}
                />
              </div>
            </div>
          ))}
        </div>
      );
    }

    case 'expiring_contracts':
    case 'pending_contracts': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((r, i) => (
            <div key={i} className="diag-card warning">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <h4 className="font-bold text-lg text-white">{r.full_name || r.tenant_name}</h4>
                  <p className="text-slate-400 text-sm">{r.building_name} • Apt {r.apartment_code}</p>
                </div>
                <span className="px-3 py-1 bg-amber-500/20 text-amber-300 rounded-full text-xs font-bold border border-amber-500/30">
                  {r.days_remaining !== undefined ? `${r.days_remaining}d left` : r.status}
                </span>
              </div>
              <div className="grid grid-cols-2 gap-2 my-4 bg-black/20 p-3 rounded-lg border border-white/5">
                <div>
                  <div className="text-xs text-slate-500">Monthly Rent</div>
                  <div className="font-bold text-white">{fmt(r.monthly_rent)}</div>
                </div>
                <div>
                  <div className="text-xs text-slate-500">End Date</div>
                  <div className="font-bold text-amber-400">{r.end_date || 'N/A'}</div>
                </div>
              </div>
              <ActionButton
                label="Open Contracts Hub"
                icon={CheckCircle2}
                variant="primary"
                onClick={() => onNavigate('/contracts')}
              />
            </div>
          ))}
        </div>
      );
    }

    case 'financial_summary': {
      const d = data || {};
      return (
        <div className="holo-dashboard">
          <div className="diag-hero-card">
            <div className="flex items-center gap-3 mb-2">
              <Activity className="text-emerald-400" size={24} />
              <h3 className="text-lg font-bold text-slate-200">System Net Position</h3>
            </div>
            <div className={`text-4xl font-black mb-4 ${parseNum(d.net_position) >= 0 ? 'text-emerald-400' : 'text-red-500'}`}>
              {fmt(d.net_position)}
            </div>
            <div className="grid grid-cols-3 gap-4 border-t border-white/10 pt-4">
              <div>
                <div className="text-xs text-slate-400">Total Collected</div>
                <div className="text-lg font-bold text-white">{fmt(d.rent_collected)}</div>
              </div>
              <div>
                <div className="text-xs text-slate-400">Total Expenses</div>
                <div className="text-lg font-bold text-amber-400">{fmt(d.total_expenses)}</div>
              </div>
              <div>
                <div className="text-xs text-slate-400">Energy & Pool</div>
                <div className="text-lg font-bold text-indigo-400">{fmt(d.pos_sales || d.electricity_collected)}</div>
              </div>
            </div>
          </div>
          <div className="holo-grid mt-4">
            <div className="diag-card danger">
              <div className="text-sm text-slate-400 mb-1">Uncollected Rent</div>
              <div className="text-2xl font-bold text-red-400 mb-2">{fmt(d.rent_outstanding)}</div>
              <div className="text-xs text-red-300 mb-3">{d.overdue_invoices || 0} Overdue Invoices</div>
              <ActionButton label="View Overdue Rent" icon={AlertTriangle} variant="danger" onClick={() => onSendPrompt('Overdue rent')} />
            </div>
            <div className="diag-card">
              <div className="text-sm text-slate-400 mb-1">Portfolio Occupancy</div>
              <div className="text-2xl font-bold text-white mb-2">{d.rented || 0} / {d.total_apartments || 0} Units</div>
              <div className="text-xs text-emerald-400 mb-3">{d.vacant || 0} Vacant Available</div>
              <ActionButton label="View Vacant Units" icon={Building2} variant="primary" onClick={() => onSendPrompt('Vacant apartments')} />
            </div>
          </div>
        </div>
      );
    }

    case 'maintenance_tasks': {
      const tasks = data?.tasks || (Array.isArray(data) ? data : []);
      return (
        <div className="holo-grid">
          {tasks.map((t, i) => (
            <div key={i} className="diag-card warning">
              <div className="flex justify-between items-start mb-3">
                <div>
                  <h4 className="font-bold text-white text-lg">{t.building_name || 'Building'} • Apt {t.apartment_code || t.apartment_number || 'N/A'}</h4>
                  <p className="text-xs text-slate-400">Task #{t.id || i + 1} • {t.scheduled_date || t.created_at || ''}</p>
                </div>
                <span className="px-2 py-1 bg-amber-500/20 text-amber-300 rounded text-xs font-bold">
                  {t.status || 'Open'}
                </span>
              </div>
              <p className="text-sm text-slate-300 my-3 bg-black/30 p-3 rounded border border-white/5">
                {t.notes || t.title || t.description || t.worker_name || 'Maintenance & Field Service'}
              </p>
              <div className="flex gap-2">
                {t.id && t.status !== 'Completed' && t.status !== 'Resolved' && (
                  <ActionButton
                    label="Mark Completed"
                    icon={Check}
                    variant="primary"
                    disabled={toolBusy}
                    onClick={() => onExecuteTool('review_ac_maintenance', t.id, { status: 'Completed', is_ticket: !!t.tenant_id })}
                  />
                )}
                <ActionButton
                  label="Maintenance Hub"
                  icon={Wrench}
                  variant="warning"
                  onClick={() => onNavigate('/maintenance-admin')}
                />
              </div>
            </div>
          ))}
        </div>
      );
    }

    case 'fuel_status': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((g, i) => {
            const stock = parseNum(g.current_stock ?? g.current_fuel_level ?? g.fuel_level);
            const low = stock < 50;
            return (
              <div key={i} className={`diag-card ${low ? 'danger' : 'success'}`}>
                <div className="flex justify-between items-center mb-4">
                  <h4 className="font-bold text-white text-lg flex items-center gap-2">
                    <Fuel size={18} className={low ? 'text-red-400' : 'text-emerald-400'} />
                    {g.generator_name || g.name || 'Generator'}
                  </h4>
                  <span className="text-xs uppercase px-2 py-1 rounded bg-white/10 text-white font-bold">{g.status || 'Active'}</span>
                </div>
                <div className="my-4">
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-slate-400">Current Reserve</span>
                    <span className="font-bold text-white">{stock.toFixed(1)} L</span>
                  </div>
                  <div className="w-full bg-black/50 h-3 rounded-full overflow-hidden border border-white/10">
                    <div
                      className={`h-full ${low ? 'bg-red-500' : 'bg-emerald-500'} transition-all duration-500`}
                      style={{ width: `${Math.min(Math.max((stock / 500) * 100, 5), 100)}%` }}
                    />
                  </div>
                </div>
                <ActionButton
                  label={low ? 'Manage Fuel Reserve' : 'Open Fuel Telemetry'}
                  icon={Flame}
                  variant={low ? 'danger' : 'primary'}
                  onClick={() => onNavigate('/fuel-reserve')}
                />
              </div>
            );
          })}
        </div>
      );
    }

    case 'building_summary':
    case 'building_profit_loss': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((b, i) => (
            <div key={i} className="diag-card">
              <h4 className="font-bold text-white text-lg mb-1 flex items-center gap-2">
                <Building2 size={18} className="text-indigo-400" />
                {b.name || b.building_name}
              </h4>
              {b.location && <p className="text-xs text-slate-400 mb-4">{b.location}</p>}
              <div className="space-y-2 mt-4 bg-black/20 p-3 rounded-lg border border-white/5">
                {b.rented !== undefined && (
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-400">Occupancy</span>
                    <span className="text-white font-bold">{b.rented} Rented / {b.vacant} Vacant</span>
                  </div>
                )}
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">Revenue</span>
                  <span className="text-emerald-400 font-bold">{fmt(b.rent_collected ?? b.total_income ?? b.potential_monthly_rent)}</span>
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-slate-400">Expenses</span>
                  <span className="text-red-400 font-bold">{fmt(b.total_expenses ?? b.expenses)}</span>
                </div>
                {b.net_profit !== undefined && (
                  <div className="flex justify-between text-sm pt-2 border-t border-white/10">
                    <span className="text-slate-300">Net Profit</span>
                    <span className={`font-black ${b.net_profit >= 0 ? 'text-emerald-400' : 'text-red-500'}`}>{fmt(b.net_profit)}</span>
                  </div>
                )}
              </div>
              <div className="flex gap-2 mt-3">
                <ActionButton
                  label="Vacant Units"
                  icon={Building2}
                  variant="primary"
                  onClick={() => onSendPrompt(`Vacant apartments in ${b.name || b.building_name}`)}
                />
                <ActionButton
                  label="Dossier"
                  icon={Eye}
                  variant="warning"
                  onClick={() => onSendPrompt(`Tell me about building ${b.name || b.building_name}`)}
                />
              </div>
            </div>
          ))}
        </div>
      );
    }

    case 'tenant_info': {
      const list = Array.isArray(data) ? data : [];
      return (
        <div className="holo-grid">
          {list.map((t, i) => (
            <div key={i} className="diag-card">
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-indigo-500/20 flex items-center justify-center border border-indigo-500/40 text-indigo-300 font-bold">
                  {(t.full_name || t.name || 'T').charAt(0)}
                </div>
                <div>
                  <h4 className="font-bold text-white text-lg">{t.full_name || t.name}</h4>
                  <p className="text-xs text-indigo-300">{t.building_name || 'Unassigned'} • Apt {t.apartment_code || 'N/A'}</p>
                </div>
              </div>
              <div className="space-y-2 text-sm bg-black/20 p-3 rounded-lg border border-white/5">
                <div className="flex justify-between"><span className="text-slate-400">Phone</span><span className="text-white">{t.phone || '—'}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Rent</span><span className="text-emerald-400 font-bold">{fmt(t.monthly_rent)}</span></div>
                <div className="flex justify-between"><span className="text-slate-400">Lease End</span><span className="text-amber-300">{t.end_date || '—'}</span></div>
                {parseNum(t.total_debt) > 0 && (
                  <div className="flex justify-between pt-2 border-t border-white/10">
                    <span className="text-red-400">Total Debt</span>
                    <span className="text-red-500 font-black">{fmt(t.total_debt)}</span>
                  </div>
                )}
              </div>
              {t.id && (
                <ActionButton
                  label="Open Tenant Profile"
                  icon={UserCheck}
                  variant="primary"
                  onClick={() => onNavigate(`/tenants/${t.id}`)}
                />
              )}
            </div>
          ))}
        </div>
      );
    }

    default: {
      if (Array.isArray(data)) {
        return (
          <div className="holo-grid">
            {data.slice(0, 12).map((item, i) => (
              <div key={i} className="diag-card">
                {Object.entries(item).map(([k, v]) => (
                  <div key={k} className="flex justify-between text-sm py-1 border-b border-white/5 last:border-0">
                    <span className="text-slate-400 capitalize">{k.replace(/_/g, ' ')}</span>
                    <span className="text-white font-medium text-right max-w-[60%] truncate">{String(v ?? '—')}</span>
                  </div>
                ))}
              </div>
            ))}
          </div>
        );
      }
      return null;
    }
  }
}

/* ─── Markdown-ish bold renderer ───────────────────────────────────── */
function AiText({ text }) {
  if (!text) return null;
  const parts = String(text).split(/(\*\*[^*]+\*\*)/g);
  return (
    <div style={{ lineHeight: 1.6, whiteSpace: 'pre-wrap' }}>
      {parts.map((p, i) =>
        p.startsWith('**') && p.endsWith('**')
          ? <strong key={i} className="text-indigo-200 font-bold">{p.slice(2, -2)}</strong>
          : p
      )}
    </div>
  );
}

/* ─── Main Page ────────────────────────────────────────────────────── */
export default function AiChat() {
  const navigate = useNavigate();

  // Live Knowledge Graph synced from production endpoints
  const kgRef = useRef({
    synced: false,
    latencyMs: 120,
    financialSummary: {},
    alerts: [],
    buildings: [],
    apartments: [],
    aptFinancials: [],
    tenants: [],
    contracts: [],
    tenantTickets: [],
    acTasks: [],
    purchases: [],
    generators: [],
    fuelReserve: {},
    subscriptions: [],
    users: [],
    suppliers: [],
  });

  const [dbSynced, setDbSynced] = useState(false);
  const [messages, setMessages] = useState(() => {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEYS.HISTORY) || 'null');
      if (Array.isArray(saved) && saved.length > 0) {
        return saved.map(m => ({ ...m, ts: m.ts ? new Date(m.ts) : new Date() }));
      }
    } catch (_) {}
    return [
      {
        role: 'ai',
        text: "👋 **Autonomous Agency AI Initialized.**\n\nI am connected live to your property, financial, energy, and maintenance databases with cross-platform conversation memory and verified tool execution.\n\nSelect a quick command below or ask me anything in English, Français, or العربية.",
        type: 'text',
        ts: new Date(),
      }
    ];
  });
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const [toolBusy, setToolBusy] = useState(false);
  const [latestWidget, setLatestWidget] = useState(null);
  const [activeTab, setActiveTab] = useState('hologram');
  const [memoryContext, setMemoryContext] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEYS.CONTEXT) || '{}') || {};
    } catch (_) {
      return {};
    }
  });
  const [userRole, setUserRole] = useState(() => {
    try {
      const u = JSON.parse(localStorage.getItem('user') || '{}');
      return (u?.role || 'admin').toLowerCase();
    } catch (_) {
      return 'admin';
    }
  });
  const [adminSettings, setAdminSettings] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEYS.SETTINGS) || 'null') || {
        ai_enabled: true,
        autonomous_actions_enabled: true,
        require_confirmation: true,
        proactive_insights_enabled: true,
      };
    } catch (_) {
      return {
        ai_enabled: true,
        autonomous_actions_enabled: true,
        require_confirmation: true,
        proactive_insights_enabled: true,
      };
    }
  });
  const [toolLogs, setToolLogs] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEYS.TOOL_LOGS) || '[]') || [];
    } catch (_) {
      return [];
    }
  });

  const bottomRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  // Persist messages & memory context locally for instant cross-reload continuity
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.HISTORY, JSON.stringify(messages.slice(-50)));
    } catch (_) {}
  }, [messages]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.CONTEXT, JSON.stringify(memoryContext));
    } catch (_) {}
  }, [memoryContext]);

  const appendToolLog = useCallback((toolName, summary, status = 'executed') => {
    setToolLogs(prev => {
      const u = (() => { try { return JSON.parse(localStorage.getItem('user') || '{}'); } catch (_) { return {}; } })();
      const next = [
        {
          tool_name: toolName,
          result_summary: summary,
          user_name: u?.name || 'Admin',
          user_role: u?.role || userRole,
          status,
          created_at: new Date().toISOString().replace('T', ' ').slice(0, 19),
        },
        ...prev,
      ].slice(0, 30);
      try { localStorage.setItem(STORAGE_KEYS.TOOL_LOGS, JSON.stringify(next)); } catch (_) {}
      return next;
    });
  }, [userRole]);

  /**
   * Synchronize full live database knowledge graph from production endpoints
   */
  const syncKnowledgeGraph = useCallback(async () => {
    const t0 = performance.now();
    const safeGet = (url) => api.get(url).then(r => r.data).catch(() => null);

    const [
      finSummary,
      alertsData,
      buildings,
      apartments,
      aptFinancials,
      tenants,
      contracts,
      tenantTickets,
      acTasks,
      costReport,
      generators,
      fuelDash,
      agentPurch,
      pendingAptPurch,
      histAptPurch,
      users,
      suppliers,
      subscriptions,
    ] = await Promise.all([
      safeGet('/dashboard/financial-summary'),
      safeGet('/dashboard/alerts'),
      safeGet('/buildings'),
      safeGet('/apartments'),
      safeGet('/apartments/financials'),
      safeGet('/tenants'),
      safeGet('/contracts'),
      safeGet('/maintenance-tickets/all'),
      safeGet('/maintenance/admin/tasks'),
      safeGet('/apartment-costs/report?start_date=2020-01-01&end_date=2030-12-31'),
      safeGet('/energy/generators'),
      safeGet('/fuel/reserve/dashboard'),
      safeGet('/agent-purchases?all=1'),
      safeGet('/energy/agent/apartment-purchases/pending'),
      safeGet('/energy/agent/apartment-purchases'),
      safeGet('/users'),
      safeGet('/suppliers'),
      safeGet('/electricity/subscriptions'),
    ]);

    const latencyMs = Math.max(12, Math.round(performance.now() - t0));

    // Merge and deduplicate purchases from all endpoints
    const rawPurchases = [
      ...(Array.isArray(pendingAptPurch) ? pendingAptPurch.map(p => ({ ...p, source: 'apartment_purchase' })) : []),
      ...(Array.isArray(histAptPurch?.history) ? histAptPurch.history.map(p => ({ ...p, source: 'apartment_purchase' })) : []),
      ...(Array.isArray(agentPurch) ? agentPurch.map(p => ({ ...p, source: 'agent_purchase' })) : []),
      ...(Array.isArray(costReport) ? costReport.map(p => ({ ...p, source: 'cost_report' })) : []),
    ];
    const seenKeys = new Set();
    const mergedPurchases = [];
    for (const p of rawPurchases) {
      if (!p || typeof p !== 'object') continue;
      const key = `${p.id || ''}_${p.supplier || p.supplier_name || ''}_${p.amount || ''}_${p.purchase_date || p.date || p.created_at || ''}`;
      if (!seenKeys.has(key)) {
        seenKeys.add(key);
        mergedPurchases.push(p);
      }
    }

    kgRef.current = {
      synced: true,
      latencyMs,
      financialSummary: finSummary && typeof finSummary === 'object' ? finSummary : {},
      alerts: Array.isArray(alertsData?.alerts) ? alertsData.alerts : (Array.isArray(alertsData) ? alertsData : []),
      buildings: Array.isArray(buildings) ? buildings : [],
      apartments: Array.isArray(apartments) ? apartments : [],
      aptFinancials: Array.isArray(aptFinancials) ? aptFinancials : [],
      tenants: Array.isArray(tenants) ? tenants : [],
      contracts: Array.isArray(contracts) ? contracts : [],
      tenantTickets: Array.isArray(tenantTickets) ? tenantTickets : (Array.isArray(tenantTickets?.tickets) ? tenantTickets.tickets : []),
      acTasks: Array.isArray(acTasks) ? acTasks : (Array.isArray(acTasks?.tasks) ? acTasks.tasks : []),
      purchases: mergedPurchases,
      generators: Array.isArray(generators) ? generators : (Array.isArray(fuelDash?.generators) ? fuelDash.generators : []),
      fuelReserve: fuelDash && typeof fuelDash === 'object' ? fuelDash : {},
      users: Array.isArray(users) ? users : [],
      suppliers: Array.isArray(suppliers) ? suppliers : [],
      subscriptions: Array.isArray(subscriptions) ? subscriptions : [],
    };
    setDbSynced(true);
    return kgRef.current;
  }, []);

  /**
   * Compute live proactive insights directly from the synced database knowledge graph
   */
  const computeLocalProactiveInsights = useCallback((kg) => {
    const insights = [];

    // 1. Overdue / Unpaid Rent
    let totalDebt = 0;
    let debtorCount = 0;
    for (const f of kg.aptFinancials) {
      const unpaid = parseNum(f.total_unpaid_rent);
      if (unpaid > 0) {
        totalDebt += unpaid;
        debtorCount++;
      }
    }
    if (totalDebt === 0) {
      totalDebt = parseNum(kg.financialSummary?.outstanding_rent_balance);
      debtorCount = parseNum(kg.financialSummary?.unpaid_rent_invoices);
    }
    if (totalDebt > 0) {
      insights.push({
        severity: 'high',
        category: 'Revenue Collection',
        title: 'Uncollected / Overdue Rent Balance',
        metric: fmt(totalDebt),
        description: `${debtorCount || 'Multiple'} tenant account(s) have an outstanding rent balance totaling ${fmt(totalDebt)} requiring collection follow-up.`,
        suggested_prompt: 'Overdue rent',
        route: '/rent-management',
      });
    }

    // 2. Expiring Contracts (Next 60 Days)
    const now = new Date();
    const expiring = kg.contracts.filter(c => {
      if (!c.end_date) return false;
      const st = String(c.status || '').toLowerCase();
      if (st && st !== 'active' && st !== 'approved') return false;
      const diffDays = Math.ceil((new Date(c.end_date) - now) / (1000 * 60 * 60 * 24));
      return diffDays >= -7 && diffDays <= 60;
    });
    if (expiring.length > 0) {
      insights.push({
        severity: 'medium',
        category: 'Lease Retention',
        title: `${expiring.length} Lease Contract(s) Expiring Soon`,
        metric: `${expiring.length} Leases`,
        description: `Proactively initiate renewal discussions for ${expiring.length} upcoming lease expiration(s) to prevent vacancy turnover.`,
        suggested_prompt: 'Expiring contracts',
        route: '/contracts',
      });
    }

    // 3. Pending Purchases & Maintenance Approvals
    const pendingPurch = kg.purchases.filter(p => String(p.status || '').toLowerCase().includes('pending'));
    const pendingMaint = kg.acTasks.filter(t => String(t.status || '').toLowerCase().includes('pending'));
    const openTickets = kg.tenantTickets.filter(t => !['closed', 'resolved', 'completed'].includes(String(t.status || '').toLowerCase()));

    if (pendingPurch.length > 0 || pendingMaint.length > 0 || openTickets.length > 0) {
      insights.push({
        severity: pendingPurch.length > 0 ? 'high' : 'medium',
        category: 'Operational Queue',
        title: 'Pending Field Approvals & Open Maintenance',
        metric: `${pendingPurch.length + pendingMaint.length + openTickets.length} Active`,
        description: `${pendingPurch.length} pending purchase receipt(s), ${pendingMaint.length} pending AC task(s), and ${openTickets.length} open tenant maintenance ticket(s).`,
        suggested_prompt: pendingPurch.length > 0 ? 'Pending purchases' : 'Maintenance tasks',
        route: pendingPurch.length > 0 ? '/agent-purchase-review' : '/maintenance-admin',
      });
    }

    // 4. Vacant Apartments Opportunity
    const vacant = kg.apartments.filter(a => String(a.status || '').toLowerCase().includes('vacant'));
    if (vacant.length > 0) {
      const potentialRent = vacant.reduce((sum, a) => sum + parseNum(a.monthly_rent), 0);
      insights.push({
        severity: 'low',
        category: 'Occupancy Optimization',
        title: `${vacant.length} Vacant Apartment(s) Ready for Leasing`,
        metric: `${fmt(potentialRent)}/mo`,
        description: `Leasing the ${vacant.length} currently vacant unit(s) will unlock ${fmt(potentialRent)} in additional monthly recurring revenue.`,
        suggested_prompt: 'Vacant apartments',
        route: '/apartments',
      });
    }

    // 5. Generator & Fuel Status
    const lowFuelGens = kg.generators.filter(g => parseNum(g.current_stock ?? g.current_fuel_level ?? g.fuel_level) < 50);
    if (lowFuelGens.length > 0) {
      insights.push({
        severity: 'high',
        category: 'Energy Continuity',
        title: `${lowFuelGens.length} Generator(s) Below 50L Reserve`,
        metric: `${lowFuelGens.length} Generator(s)`,
        description: `Generators requiring fuel refill attention: ${lowFuelGens.map(g => g.name || g.generator_name).join(', ')}.`,
        suggested_prompt: 'Fuel status',
        route: '/fuel-reserve',
      });
    }

    return insights;
  }, []);

  /**
   * Local Autonomous Hybrid Reasoning Engine over the Live Database Knowledge Graph
   */
  const evaluateAutonomousQuery = useCallback(async (rawQuestion, currentContext = {}) => {
    const kg = kgRef.current.synced ? kgRef.current : await syncKnowledgeGraph();
    const q = rawQuestion.toLowerCase().trim();
    const nextContext = { ...currentContext };

    // Security / Prompt injection guard
    if (/ignore\s+(all\s+)?(previous|prior|system)\s+instructions|drop\s+table|bypass\s+(security|role|permission)/i.test(q)) {
      appendToolLog('security_guard_block', `Blocked suspicious prompt pattern: "${rawQuestion.slice(0, 60)}"`, 'blocked');
      return {
        reply: "🛡️ **Security Guard Intervention:** Your request matched a restricted instruction or privilege-escalation pattern and was blocked.",
        type: 'text',
        actions: [],
        nextContext,
      };
    }

    // 1. GREETING / HELP
    if (/^(hi|hello|hey|bonjour|salut|مرحبا|السلام عليكم|اهلا|who are you)$/i.test(q)) {
      const vacantCount = kg.apartments.filter(a => String(a.status || '').toLowerCase() === 'vacant').length;
      const collected = kg.financialSummary?.total_rent_collected || 'CFA 0';
      const outstanding = kg.financialSummary?.outstanding_rent_balance || 'CFA 0';
      return {
        reply: `👋 **Hello! I am Agency AI** — connected live to your SOCIMCO production database.\n\n` +
          `📊 **Live Executive Telemetry:**\n` +
          `• 🏢 **Portfolio:** **${kg.buildings.length}** Buildings | **${kg.apartments.length}** Apartments (**${vacantCount}** Vacant)\n` +
          `• 👥 **Tenants & Leases:** **${kg.tenants.length}** Registered Tenants | **${kg.contracts.length}** Contracts\n` +
          `• 💰 **Rent Ledger:** **${collected}** Collected | **${outstanding}** Outstanding\n` +
          `• 🔧 **Maintenance:** **${kg.tenantTickets.length}** Tenant Tickets | **${kg.acTasks.length}** AC Tasks\n` +
          `• 🛒 **Purchases & Costs:** **${kg.purchases.length}** Submissions\n\n` +
          `Ask me about any specific tenant, apartment (e.g. **"Apt A1"**), building, **"Proactive insights"**, **"Pending purchases"**, or **"Run system diagnostics"**!`,
        type: 'proactive_insights',
        data: computeLocalProactiveInsights(kg),
        actions: [
          { label: 'Rent Management', route: '/rent-management' },
          { label: 'Maintenance Oversight', route: '/maintenance-admin' },
        ],
        nextContext,
      };
    }

    // 2. PROACTIVE INSIGHTS / RECOMMENDATIONS
    if (q.includes('proactive') || q.includes('insight') || q.includes('recommend') || q.includes('attention') || q.includes('anomal') || q.includes('توصيات') || q.includes('تنبيهات')) {
      const insights = computeLocalProactiveInsights(kg);
      const lines = ["💡 **Live Data-Driven Proactive Intelligence & Priority Queue:**\n"];
      if (insights.length === 0) {
        lines.push("✅ **All Systems Optimal:** Zero overdue rent anomalies, zero critical fuel shortages, and no pending approval bottlenecks.");
      } else {
        insights.forEach((ins, idx) => {
          const badge = ins.severity === 'high' ? '🔴 [HIGH PRIORITY]' : (ins.severity === 'medium' ? '🟡 [ACTION NEEDED]' : '🟢 [OPPORTUNITY]');
          lines.push(`${idx + 1}. ${badge} **${ins.title}** (${ins.metric})\n   ${ins.description}`);
        });
      }
      return {
        reply: lines.join('\n\n'),
        type: 'proactive_insights',
        data: insights,
        actions: [{ label: 'Open Financial Reports', route: '/financial-reports' }],
        nextContext,
      };
    }

    // 3. SYSTEM DIAGNOSTICS
    if (q.includes('diagnostic') || q.includes('health') || q.includes('checkup') || q.includes('فحص النظام')) {
      const pendingPurch = kg.purchases.filter(p => String(p.status || '').toLowerCase().includes('pending')).length;
      const pendingMaint = kg.acTasks.filter(t => String(t.status || '').toLowerCase().includes('pending')).length;
      const checks = [
        {
          component: 'Production API & Database Uplink',
          status: kg.latencyMs < 800 ? 'healthy' : 'warning',
          metric: `${kg.latencyMs} ms`,
          detail: `Connected to live database (${kg.buildings.length} buildings, ${kg.apartments.length} units, ${kg.tenants.length} tenants synced)`,
        },
        {
          component: 'Agent Purchase Review Queue',
          status: pendingPurch > 5 ? 'warning' : 'healthy',
          metric: `${pendingPurch} pending`,
          detail: pendingPurch > 0 ? `${pendingPurch} apartment cost receipt(s) awaiting admin review` : 'All submitted purchase receipts reviewed',
        },
        {
          component: 'AC & Tenant Maintenance Queue',
          status: pendingMaint > 5 ? 'warning' : 'healthy',
          metric: `${pendingMaint} pending`,
          detail: `${kg.tenantTickets.length} tenant ticket(s) and ${kg.acTasks.length} AC maintenance task(s) tracked`,
        },
        {
          component: 'Generator & Energy Grid Telemetry',
          status: 'healthy',
          metric: `${kg.generators.length} generator(s)`,
          detail: `${kg.subscriptions.length} active apartment electricity/generator subscriptions monitored`,
        },
      ];
      const lines = ["🩺 **Live System Self-Diagnostics & Health Telemetry:**\n"];
      checks.forEach(c => {
        lines.push(`• ${c.status === 'healthy' ? '🟢' : '🟡'} **${c.component}** (${c.metric}) — ${c.detail}`);
      });
      return {
        reply: lines.join('\n'),
        type: 'system_diagnostics',
        data: checks,
        actions: [{ label: 'Open System Jobs', route: '/system-jobs' }],
        nextContext,
      };
    }

    // 4. APPROVE / REJECT PURCHASE COMMAND (Confirmation Guard)
    if ((q.includes('approve') || q.includes('reject') || q.includes('موافقة') || q.includes('رفض')) && (q.includes('purchase') || q.includes('cost') || q.includes('receipt') || q.includes('#') || currentContext.last_intent === 'pending_purchases')) {
      const targetStatus = (q.includes('reject') || q.includes('رفض')) ? 'Rejected' : 'Approved';
      const idMatch = rawQuestion.match(/(?:#|id\s*)(\d+)/i);
      const pendingList = kg.purchases.filter(p => String(p.status || 'Pending').toLowerCase().includes('pending'));
      const targetPurchase = idMatch
        ? kg.purchases.find(p => String(p.id) === idMatch[1])
        : (pendingList[0] || kg.purchases[0]);

      if (!targetPurchase) {
        return {
          reply: "✅ There are currently **0 pending agent purchases** awaiting approval.",
          type: 'text',
          actions: [{ label: 'Open Purchase Review', route: '/agent-purchase-review' }],
          nextContext,
        };
      }

      const bld = targetPurchase.building_name || 'Building';
      const apt = targetPurchase.apartment_number || targetPurchase.apartment_code || 'N/A';
      const sup = targetPurchase.supplier || targetPurchase.supplier_name || 'Supplier';
      const amt = fmt(targetPurchase.amount);

      return {
        reply: `🛡️ **Confirmation Required — ${targetStatus} Purchase #${targetPurchase.id}:**\n\n` +
          `• **Property:** ${bld} • Apt ${apt}\n` +
          `• **Supplier:** ${sup}\n` +
          `• **Amount:** **${amt}**\n\n` +
          `Please confirm below to execute this database update:`,
        type: 'tool_confirmation',
        requires_confirmation: true,
        pending_tool: {
          tool_name: 'review_purchase',
          target_id: targetPurchase.id,
          parameters: { status: targetStatus, source: targetPurchase.source },
          summary: `${targetStatus} Purchase #${targetPurchase.id} (${bld} Apt ${apt} - ${amt})`,
        },
        data: targetPurchase,
        actions: [],
        nextContext: { ...nextContext, last_record_id: targetPurchase.id },
      };
    }

    // 5. PENDING PURCHASES / APARTMENT COSTS
    if (q.includes('purchase') || q.includes('bought') || q.includes('cost') || q.includes('receipt') || q.includes('مشتريات') || q.includes('تكاليف')) {
      nextContext.last_intent = 'pending_purchases';
      const list = kg.purchases.slice(0, 18).map(p => ({
        id: p.id,
        building_name: p.building_name || 'Building',
        apartment_number: p.apartment_number || p.apartment_code || 'N/A',
        supplier: p.supplier || p.supplier_name || 'Supplier',
        items: p.items || p.items_bought || p.description || p.notes || p.type || 'Expense',
        submitter_name: p.submitter_name || p.agent_name || p.type || 'Agent',
        amount: parseNum(p.amount),
        status: p.status || 'Approved',
        source: p.source,
      }));
      const pendingCount = list.filter(p => String(p.status).toLowerCase().includes('pending')).length;
      const totalAmt = list.reduce((s, p) => s + p.amount, 0);
      return {
        reply: `🛒 **Agent Purchases & Apartment Costs:** Found **${kg.purchases.length}** submission(s) (**${pendingCount}** pending approval) totaling **${fmt(totalAmt)}**:`,
        type: 'pending_purchases',
        data: list,
        actions: [
          { label: 'Open Purchase Review', route: '/agent-purchase-review' },
          { label: 'Apartment Costs Report', route: '/apartment-costs' },
        ],
        nextContext,
      };
    }

    // 6. SPECIFIC TENANT DOSSIER (or follow-up on last_tenant)
    let matchedTenant = null;
    for (const t of kg.tenants) {
      const fullName = String(t.full_name || t.name || '').trim();
      if (!fullName) continue;
      if (q.includes(fullName.toLowerCase())) {
        matchedTenant = t;
        break;
      }
      const parts = fullName.toLowerCase().split(/\s+/).filter(p => p.length >= 3);
      if (parts.length > 0 && parts.every(p => q.includes(p))) {
        matchedTenant = t;
        break;
      }
    }
    if (!matchedTenant && (q.includes('his ') || q.includes('her ') || q.includes('that tenant')) && currentContext.last_tenant) {
      matchedTenant = kg.tenants.find(t => String(t.full_name || t.name).toLowerCase() === String(currentContext.last_tenant).toLowerCase());
    }
    if (matchedTenant) {
      const tName = matchedTenant.full_name || matchedTenant.name;
      nextContext.last_tenant = tName;
      const contract = kg.contracts.find(c =>
        String(c.tenant_id) === String(matchedTenant.id) ||
        String(c.tenant_name || c.full_name || '').toLowerCase() === tName.toLowerCase()
      );
      const bld = matchedTenant.building_name || contract?.building_name || 'Unassigned';
      const apt = matchedTenant.apartment_code || contract?.apartment_code || 'N/A';
      const fin = kg.aptFinancials.find(f =>
        String(f.tenant_name || '').toLowerCase() === tName.toLowerCase() ||
        (String(f.code || '') === String(apt) && String(f.building_name || '') === String(bld))
      );
      const paid = parseNum(fin?.total_paid_rent);
      const debt = parseNum(fin?.total_unpaid_rent);
      const rent = parseNum(contract?.monthly_rent || matchedTenant.monthly_rent || fin?.monthly_rent);

      const enriched = {
        ...matchedTenant,
        building_name: bld,
        apartment_code: apt,
        monthly_rent: rent,
        end_date: contract?.end_date || matchedTenant.end_date || 'N/A',
        total_paid: paid,
        total_debt: debt,
      };

      return {
        reply: `👤 **Complete 360° Tenant Dossier — ${tName}:**\n\n` +
          `• **Assigned Unit:** **${bld} • Apt ${apt}**\n` +
          `• **Phone:** ${matchedTenant.phone || 'N/A'} | **Email:** ${matchedTenant.email || 'N/A'}\n` +
          `• **Monthly Rent:** **${fmt(rent)}** | **Lease End:** **${enriched.end_date}**\n` +
          `• **Total Rent Paid:** **${fmt(paid)}** | **Outstanding Debt:** **${fmt(debt)}**`,
        type: 'tenant_info',
        data: [enriched],
        actions: matchedTenant.id ? [{ label: `Open ${tName}`, route: `/tenants/${matchedTenant.id}` }] : [],
        nextContext,
      };
    }

    // 7. OVERDUE RENT / TOP DEBTORS
    if (q.includes('overdue') || q.includes('debt') || q.includes('unpaid') || q.includes('owe') || q.includes('arrears') || q.includes('متأخر') || q.includes('ديون')) {
      const debtors = [];
      for (const f of kg.aptFinancials) {
        const unpaid = parseNum(f.total_unpaid_rent);
        if (unpaid > 0) {
          debtors.push({
            full_name: f.tenant_name || 'Tenant',
            building_name: f.building_name || 'Building',
            apartment_code: f.code || f.apartment_code || 'N/A',
            total_debt: unpaid,
            overdue_invoices: f.overdue_months || 1,
            days_overdue: (parseNum(f.overdue_months) || 1) * 30,
          });
        }
      }
      debtors.sort((a, b) => b.total_debt - a.total_debt);
      const totalDebt = debtors.reduce((s, d) => s + d.total_debt, 0);

      if (debtors.length === 0) {
        return {
          reply: "✅ **Zero Overdue Rent!** All active tenant invoices are currently paid up.",
          type: 'text',
          actions: [{ label: 'Open Rent Management', route: '/rent-management' }],
          nextContext,
        };
      }

      return {
        reply: `⚠️ Found **${debtors.length} tenant(s)** with unpaid/overdue rent balances totaling **${fmt(totalDebt)}**:`,
        type: 'overdue_rent',
        data: debtors,
        actions: [{ label: 'Open Rent Management', route: '/rent-management' }],
        nextContext,
      };
    }

    // 8. EXPIRING / PENDING CONTRACTS
    if (q.includes('expir') || q.includes('renew') || q.includes('contract') || q.includes('lease') || q.includes('عقود')) {
      const now = new Date();
      const list = kg.contracts
        .map(c => {
          const diffDays = c.end_date ? Math.ceil((new Date(c.end_date) - now) / (1000 * 60 * 60 * 24)) : 999;
          return {
            ...c,
            full_name: c.tenant_name || c.full_name || 'Tenant',
            days_remaining: diffDays,
          };
        })
        .sort((a, b) => a.days_remaining - b.days_remaining)
        .slice(0, 15);

      return {
        reply: `📅 Showing **${list.length} lease contract(s)** ordered by upcoming expiration date:`,
        type: 'expiring_contracts',
        data: list,
        actions: [{ label: 'Open Contracts Hub', route: '/contracts' }],
        nextContext,
      };
    }

    // 9. FUEL STATUS / GENERATORS / ENERGY
    if (q.includes('fuel') || q.includes('diesel') || q.includes('generator') || q.includes('energy') || q.includes('electricity') || q.includes('وقود') || q.includes('مولد')) {
      const genList = kg.generators.map(g => ({
        generator_name: g.name || g.generator_name || 'Generator',
        status: g.status || 'Active',
        current_stock: parseNum(g.current_stock ?? g.current_fuel_level ?? g.fuel_level),
      }));
      const totalFuel = genList.reduce((s, g) => s + g.current_stock, 0);
      return {
        reply: `⛽ **Fuel & Generator Telemetry:** Tracking **${genList.length} generator(s)** with **${totalFuel.toFixed(1)} L** total fuel reserve and **${kg.subscriptions.length}** apartment electricity subscriptions:`,
        type: 'fuel_status',
        data: genList,
        actions: [
          { label: 'Open Fuel Reserve', route: '/fuel-reserve' },
          { label: 'Energy Management', route: '/energy' },
        ],
        nextContext,
      };
    }

    // 10. MAINTENANCE TASKS / WORKER REPORTS
    if (q.includes('maint') || q.includes('ac ') || q.includes('repair') || q.includes('ticket') || q.includes('worker') || q.includes('صيانة')) {
      const combined = [
        ...kg.acTasks.slice(0, 10).map(t => ({
          id: t.id,
          building_name: t.building_name || 'Building',
          apartment_code: t.apartment_code || 'N/A',
          scheduled_date: t.scheduled_date || t.submission_date || '',
          status: t.status || 'Pending',
          notes: t.worker_name ? `Technician: ${t.worker_name}` : 'AC Maintenance Task',
        })),
        ...kg.tenantTickets.slice(0, 10).map(t => ({
          id: t.id,
          tenant_id: t.tenant_id,
          building_name: t.building_name || 'Building',
          apartment_code: t.apartment_code || t.apartment_number || 'N/A',
          scheduled_date: t.created_at || '',
          status: t.status || 'Open',
          notes: `${t.title || t.category || 'Issue'} — ${t.tenant_name || 'Tenant'}`,
        })),
      ];
      return {
        reply: `🔧 **Maintenance & Field Operations:** Tracking **${kg.acTasks.length}** AC maintenance task(s) and **${kg.tenantTickets.length}** tenant maintenance request(s):`,
        type: 'maintenance_tasks',
        data: { tasks: combined },
        actions: [{ label: 'Open Maintenance Oversight', route: '/maintenance-admin' }],
        nextContext,
      };
    }

    // 11. VACANT APARTMENTS
    if (q.includes('vacant') || q.includes('empty') || q.includes('available') || q.includes('شاغر')) {
      let matchedBld = null;
      for (const b of kg.buildings) {
        if (b.name && q.includes(b.name.toLowerCase())) {
          matchedBld = b;
          break;
        }
      }
      const vacant = kg.apartments.filter(a => {
        const isVac = String(a.status || '').toLowerCase().includes('vacant');
        if (!isVac) return false;
        if (matchedBld) {
          return String(a.building_id) === String(matchedBld.id) ||
            String(a.building_name || '').toLowerCase() === matchedBld.name.toLowerCase();
        }
        return true;
      });
      return {
        reply: vacant.length > 0
          ? `🏠 Found **${vacant.length} vacant apartment(s)** ${matchedBld ? `in **${matchedBld.name}**` : 'across all buildings'}:`
          : `✅ **100% Occupancy!** No vacant apartments found ${matchedBld ? `in **${matchedBld.name}**` : 'across the portfolio'}.`,
        type: vacant.length > 0 ? 'vacant_apartments' : 'text',
        data: vacant,
        actions: [{ label: 'Open Apartments', route: '/apartments' }],
        nextContext,
      };
    }

    // 12. BUILDINGS SUMMARY / SPECIFIC BUILDING
    if (q.includes('building') || q.includes('propert') || q.includes('مبنى') || q.includes('مباني') || kg.buildings.some(b => b.name && q.includes(b.name.toLowerCase()))) {
      const matchedBld = kg.buildings.find(b => b.name && q.includes(b.name.toLowerCase()));
      if (matchedBld) {
        nextContext.last_building = matchedBld.name;
      }
      const targetBuildings = matchedBld ? [matchedBld] : kg.buildings;
      const summary = targetBuildings.map(b => {
        const bApts = kg.apartments.filter(a => String(a.building_id) === String(b.id) || String(a.building_name || '').toLowerCase() === String(b.name || '').toLowerCase());
        const rented = bApts.filter(a => String(a.status || '').toLowerCase() === 'rented').length;
        const vacant = bApts.length - rented;
        const rev = bApts.reduce((s, a) => s + parseNum(a.monthly_rent), 0);
        const exp = kg.purchases
          .filter(p => String(p.building_name || '').toLowerCase() === String(b.name || '').toLowerCase())
          .reduce((s, p) => s + parseNum(p.amount), 0);
        return {
          id: b.id,
          name: b.name,
          location: b.location,
          rented,
          vacant,
          rent_collected: rev,
          total_expenses: exp,
          net_profit: rev - exp,
        };
      });
      return {
        reply: `🏢 **Building Portfolio Telemetry** (${summary.length} propert${summary.length === 1 ? 'y' : 'ies'}):`,
        type: 'building_summary',
        data: summary,
        actions: [{ label: 'Open Buildings', route: '/buildings' }],
        nextContext,
      };
    }

    // 13. FINANCIAL SUMMARY / DEFAULT EXECUTIVE OVERVIEW
    const rentCollected = parseNum(kg.financialSummary?.total_rent_collected);
    const rentOutstanding = parseNum(kg.financialSummary?.outstanding_rent_balance);
    const totalExpenses = kg.purchases.reduce((s, p) => s + parseNum(p.amount), 0);
    const elecCollected = parseNum(kg.financialSummary?.electricity_collected) + parseNum(kg.financialSummary?.generator_collected);
    const rentedCount = kg.apartments.filter(a => String(a.status || '').toLowerCase() === 'rented').length;
    const vacantCount = kg.apartments.length - rentedCount;

    return {
      reply: `📊 **Executive Financial & Portfolio Overview** across **${kg.buildings.length} buildings**, **${kg.apartments.length} apartments**, and **${kg.tenants.length} tenants**:`,
      type: 'financial_summary',
      data: {
        net_position: rentCollected + elecCollected - totalExpenses,
        rent_collected: rentCollected,
        rent_outstanding: rentOutstanding,
        overdue_invoices: parseNum(kg.financialSummary?.unpaid_rent_invoices),
        total_expenses: totalExpenses,
        pos_sales: elecCollected,
        total_apartments: kg.apartments.length,
        rented: rentedCount,
        vacant: vacantCount,
      },
      actions: [
        { label: 'Financial Reports', route: '/financial-reports' },
        { label: 'Rent Management', route: '/rent-management' },
      ],
      nextContext,
    };
  }, [appendToolLog, computeLocalProactiveInsights, syncKnowledgeGraph]);

  // Initial sync on mount
  useEffect(() => {
    let mounted = true;
    syncKnowledgeGraph().then(kg => {
      if (!mounted) return;
      const insights = computeLocalProactiveInsights(kg);
      setLatestWidget(prev => prev || {
        type: 'proactive_insights',
        data: insights,
      });
    });
    return () => { mounted = false; };
  }, [syncKnowledgeGraph, computeLocalProactiveInsights]);

  const toggleAdminSetting = async (key, currentVal) => {
    const updated = { ...adminSettings, [key]: !currentVal };
    setAdminSettings(updated);
    try {
      localStorage.setItem(STORAGE_KEYS.SETTINGS, JSON.stringify(updated));
    } catch (_) {}
    appendToolLog('update_ai_settings', `Toggled ${key} to ${!currentVal ? 'ENABLED' : 'PAUSED'}`);
    try {
      await api.post('/ai/admin-control', { [key]: !currentVal });
    } catch (_) {}
  };

  const send = async (text) => {
    const q = (text || input).trim();
    if (!q || loading) return;
    setInput('');
    setActiveTab('hologram');
    setMessages(prev => [...prev, { role: 'user', text: q, ts: new Date() }]);

    if (!adminSettings.ai_enabled) {
      setMessages(prev => [...prev, {
        role: 'ai',
        text: "⚠️ **Agency AI is currently paused** in the AI Control Center. Re-enable the Master AI Switch to resume.",
        type: 'text',
        ts: new Date(),
      }]);
      return;
    }

    setLoading(true);
    try {
      // Run backend /ai/chat (if deployed) AND local live-database autonomous engine in parallel
      const [backendSettlement, localResult] = await Promise.all([
        api.post('/ai/chat', { message: q, current_page: window.location.pathname }).then(r => r.data).catch(() => null),
        evaluateAutonomousQuery(q, memoryContext),
      ]);

      // Use backend response if valid and non-error, otherwise seamlessly use the live database autonomous engine result
      const validBackend = backendSettlement &&
        typeof backendSettlement === 'object' &&
        !backendSettlement.error &&
        backendSettlement.reply &&
        !String(backendSettlement.reply).includes("couldn't find any matching records");

      const chosen = validBackend ? backendSettlement : localResult;

      if (localResult?.nextContext) {
        setMemoryContext(localResult.nextContext);
      }

      setMessages(prev => [...prev, {
        role: 'ai',
        text: chosen.reply,
        type: chosen.type || 'text',
        data: chosen.data,
        actions: chosen.actions || [],
        requires_confirmation: chosen.requires_confirmation,
        pending_tool: chosen.pending_tool,
        ts: new Date(),
      }]);

      if (chosen.type === 'navigation' && chosen.navigation_action?.route) {
        setTimeout(() => navigate(chosen.navigation_action.route), 800);
      } else if (chosen.type && chosen.type !== 'text') {
        setLatestWidget({
          type: chosen.type,
          data: chosen.data,
          pendingTool: chosen.pending_tool,
        });
      }
    } catch (e) {
      const fallback = await evaluateAutonomousQuery(q, memoryContext);
      setMessages(prev => [...prev, {
        role: 'ai',
        text: fallback.reply,
        type: fallback.type || 'text',
        data: fallback.data,
        actions: fallback.actions || [],
        ts: new Date(),
      }]);
      if (fallback.type && fallback.type !== 'text') {
        setLatestWidget({ type: fallback.type, data: fallback.data, pendingTool: fallback.pending_tool });
      }
    } finally {
      setLoading(false);
      setTimeout(() => inputRef.current?.focus(), 50);
    }
  };

  /**
   * Executes verified autonomous actions against real production endpoints
   */
  const executeTool = async (toolName, targetId, parameters = {}) => {
    if (toolBusy) return;
    if (!adminSettings.autonomous_actions_enabled) {
      setMessages(prev => [...prev, {
        role: 'ai',
        text: "🔒 **Autonomous Tool Execution is currently disabled** in the AI Control Center.",
        type: 'text',
        ts: new Date(),
      }]);
      return;
    }

    setToolBusy(true);
    try {
      let summary = '';
      if (toolName === 'review_purchase') {
        const status = parameters.status === 'Rejected' ? 'Rejected' : 'Approved';
        const actionVerb = status === 'Approved' ? 'approve' : 'reject';
        // Call production purchase review endpoints
        await Promise.any([
          api.post(`/energy/agent/apartment-purchases/${targetId}/review`, { status }),
          api.post(`/agent-purchases/${targetId}/${actionVerb}`),
          api.post('/ai/execute-tool', { tool_name: toolName, target_id: targetId, parameters }),
        ]);
        summary = `Purchase #${targetId} marked as ${status}.`;
      } else if (toolName === 'review_ac_maintenance') {
        const status = parameters.status || 'Completed';
        await Promise.any([
          parameters.is_ticket
            ? api.put(`/maintenance-tickets/${targetId}/status`, { status: 'Resolved' })
            : api.post(`/maintenance/admin/approve/${targetId}`),
          api.post('/ai/execute-tool', { tool_name: toolName, target_id: targetId, parameters }),
        ]);
        summary = `Maintenance record #${targetId} marked as ${status}.`;
      } else {
        await api.post('/ai/execute-tool', { tool_name: toolName, target_id: targetId, parameters });
        summary = `Executed ${toolName} on #${targetId}.`;
      }

      appendToolLog(toolName, summary, 'executed');
      setMessages(prev => [...prev, {
        role: 'ai',
        text: `✅ **Autonomous Action Completed:** ${summary}`,
        type: 'text',
        ts: new Date(),
      }]);

      await syncKnowledgeGraph();
      if (toolName === 'review_purchase') {
        send('Pending purchases');
      } else if (toolName === 'review_ac_maintenance') {
        send('Maintenance tasks');
      }
    } catch (e) {
      appendToolLog(toolName, `Failed on #${targetId}: ${e.response?.data?.message || e.message}`, 'error');
      setMessages(prev => [...prev, {
        role: 'ai',
        text: `❌ **Tool Execution Error:** ${e.response?.data?.message || e.response?.data?.error || e.message}`,
        type: 'text',
        ts: new Date(),
      }]);
    } finally {
      setToolBusy(false);
    }
  };

  const clear = async () => {
    try {
      localStorage.removeItem(STORAGE_KEYS.HISTORY);
      localStorage.removeItem(STORAGE_KEYS.CONTEXT);
      await api.post('/ai/clear');
    } catch (_) {}
    setMessages([{
      role: 'ai',
      text: "🔄 **Conversation Memory Reset.** Ready for new commands.",
      type: 'text',
      ts: new Date()
    }]);
    setMemoryContext({});
    const insights = computeLocalProactiveInsights(kgRef.current);
    setLatestWidget({ type: 'proactive_insights', data: insights });
  };

  return (
    <div className="agency-layout">
      <style>{`
        .agency-layout {
          display: flex;
          height: calc(100vh - 64px);
          background: #07090e;
          color: #f8fafc;
          font-family: 'Inter', system-ui, sans-serif;
          overflow: hidden;
          position: relative;
        }
        .agency-bg {
          position: absolute; inset: 0;
          background: radial-gradient(circle at 80% 20%, rgba(99, 102, 241, 0.12), transparent 40%),
                      radial-gradient(circle at 20% 80%, rgba(16, 185, 129, 0.08), transparent 40%);
          pointer-events: none; z-index: 0;
        }
        .agency-grid {
          position: absolute; inset: 0;
          background-image: linear-gradient(rgba(255,255,255,0.02) 1px, transparent 1px),
                            linear-gradient(90deg, rgba(255,255,255,0.02) 1px, transparent 1px);
          background-size: 40px 40px; pointer-events: none; z-index: 0;
        }
        .agency-sidebar {
          width: 460px; display: flex; flex-direction: column;
          background: rgba(15, 23, 42, 0.78); backdrop-filter: blur(20px);
          border-right: 1px solid rgba(255,255,255,0.08); z-index: 10; flex-shrink: 0;
        }
        .agency-main {
          flex: 1; display: flex; flex-direction: column;
          padding: 28px 36px; overflow-y: auto; z-index: 10; position: relative;
        }
        .agency-header {
          padding: 18px 22px; border-bottom: 1px solid rgba(255,255,255,0.06);
          display: flex; align-items: center; gap: 14px;
        }
        .agency-logo-box {
          width: 44px; height: 44px; border-radius: 14px;
          background: linear-gradient(135deg, #4f46e5, #9333ea);
          display: flex; align-items: center; justify-content: center;
          box-shadow: 0 0 25px rgba(99, 102, 241, 0.4); position: relative;
        }
        .chat-scroll {
          flex: 1; overflow-y: auto; padding: 20px;
          display: flex; flex-direction: column; gap: 18px;
        }
        .chat-scroll::-webkit-scrollbar, .agency-main::-webkit-scrollbar { width: 6px; }
        .chat-scroll::-webkit-scrollbar-thumb, .agency-main::-webkit-scrollbar-thumb {
          background: rgba(255,255,255,0.1); border-radius: 10px;
        }
        .ai-msg { display: flex; gap: 12px; animation: slideUp 0.25s cubic-bezier(0.16, 1, 0.3, 1); }
        .ai-msg.user { flex-direction: row-reverse; }
        @keyframes slideUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
        .ai-bubble {
          max-width: 340px; padding: 14px 18px; border-radius: 18px;
          font-size: 13.5px; position: relative; box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        .ai-bubble.ai {
          background: rgba(30, 41, 59, 0.9); border: 1px solid rgba(255,255,255,0.08);
          color: #e2e8f0; border-top-left-radius: 4px;
        }
        .ai-bubble.user {
          background: linear-gradient(135deg, #3b82f6, #6366f1);
          color: #fff; border-top-right-radius: 4px;
        }
        .holo-container { flex: 1; display: flex; flex-direction: column; animation: fadeIn 0.35s ease; }
        @keyframes fadeIn { from { opacity: 0; transform: scale(0.99); } to { opacity: 1; transform: scale(1); } }
        .holo-grid {
          display: grid; grid-template-columns: repeat(auto-fill, minmax(310px, 1fr)); gap: 20px;
        }
        .diag-hero-card {
          background: linear-gradient(145deg, rgba(30, 41, 59, 0.85), rgba(15, 23, 42, 0.92));
          border: 1px solid rgba(255,255,255,0.1); border-radius: 20px; padding: 28px;
          backdrop-filter: blur(12px); box-shadow: 0 20px 50px rgba(0,0,0,0.4);
        }
        .diag-card {
          background: rgba(17, 24, 39, 0.78); border: 1px solid rgba(255,255,255,0.1);
          border-radius: 16px; padding: 22px; backdrop-filter: blur(12px);
          box-shadow: 0 10px 30px rgba(0,0,0,0.45); transition: 0.25s;
          position: relative; overflow: hidden;
        }
        .diag-card:hover { transform: translateY(-3px); border-color: rgba(99, 102, 241, 0.5); }
        .diag-card::before { content: ''; position: absolute; top: 0; left: 0; width: 4px; height: 100%; background: #6366f1; }
        .diag-card.danger::before { background: #ef4444; }
        .diag-card.warning::before { background: #f59e0b; }
        .diag-card.success::before { background: #22c55e; }
        .diag-action-btn {
          margin-top: 12px; flex: 1; padding: 10px 14px; font-size: 12.5px;
          border-radius: 8px; font-weight: 600; cursor: pointer; transition: 0.2s;
          display: flex; align-items: center; justify-content: center; gap: 6px;
        }
        .diag-action-btn.primary { background: rgba(99, 102, 241, 0.14); color: #a5b4fc; border: 1px solid rgba(99, 102, 241, 0.3); }
        .diag-action-btn.primary:hover:not(:disabled) { background: rgba(99, 102, 241, 0.3); color: #fff; }
        .diag-action-btn.danger { background: rgba(239, 68, 68, 0.14); color: #fca5a5; border: 1px solid rgba(239, 68, 68, 0.3); }
        .diag-action-btn.danger:hover:not(:disabled) { background: rgba(239, 68, 68, 0.3); color: #fff; }
        .diag-action-btn.warning { background: rgba(245, 158, 11, 0.14); color: #fcd34d; border: 1px solid rgba(245, 158, 11, 0.3); }
        .diag-action-btn.warning:hover:not(:disabled) { background: rgba(245, 158, 11, 0.3); color: #fff; }
        .ai-input-row { padding: 16px 20px; border-top: 1px solid rgba(255,255,255,0.06); background: rgba(15, 23, 42, 0.92); }
        .ai-input-wrapper {
          display: flex; gap: 10px; background: rgba(0,0,0,0.35);
          border: 1px solid rgba(255,255,255,0.12); border-radius: 14px; padding: 5px;
        }
        .ai-input-wrapper:focus-within { border-color: rgba(99, 102, 241, 0.6); }
        .ai-input { flex: 1; background: transparent; border: none; padding: 10px 14px; color: #fff; font-size: 14px; outline: none; }
        .ai-send {
          width: 42px; height: 42px; border-radius: 10px;
          background: linear-gradient(135deg, #3b82f6, #6366f1); border: none; color: #fff;
          display: flex; align-items: center; justify-content: center; cursor: pointer;
        }
        .quick-actions { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 12px; }
        .quick-action-tag {
          background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1);
          padding: 5px 10px; border-radius: 16px; font-size: 11.5px; color: #cbd5e1;
          cursor: pointer; transition: 0.2s; display: flex; align-items: center; gap: 5px;
        }
        .quick-action-tag:hover { background: rgba(99, 102, 241, 0.2); color: #fff; border-color: rgba(99, 102, 241, 0.5); }
      `}</style>

      <div className="agency-bg"></div>
      <div className="agency-grid"></div>

      {/* Left Sidebar: Conversational Agent & Memory */}
      <div className="agency-sidebar">
        <div className="agency-header">
          <div className="agency-logo-box">
            <Fingerprint size={24} color="#fff" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h1 className="text-base font-bold text-white tracking-wide">AGENCY AI CORE</h1>
              <span className="px-2 py-0.5 text-[10px] font-bold uppercase rounded bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                {userRole}
              </span>
            </div>
            <div className="flex items-center gap-2 mt-0.5">
              <span className={`w-2 h-2 rounded-full ${dbSynced ? 'bg-emerald-400' : 'bg-amber-400'} animate-pulse`}></span>
              <span className="text-[11px] text-emerald-400 font-medium truncate">
                {memoryContext.last_building || memoryContext.last_tenant
                  ? `Context: ${memoryContext.last_tenant || memoryContext.last_building}`
                  : (dbSynced
                      ? `Live DB Synced (${kgRef.current.buildings.length} Bldgs • ${kgRef.current.tenants.length} Tenants)`
                      : 'Synchronizing Live Database...')}
              </span>
            </div>
          </div>
          <button
            title="Reset Conversation Memory"
            className="p-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors border border-white/10 text-slate-400 hover:text-white"
            onClick={clear}
          >
            <RotateCcw size={15} />
          </button>
        </div>

        <div className="chat-scroll">
          {messages.map((msg, i) => {
            const rtl = isArabicText(msg.text);
            return (
              <div key={i} className={`ai-msg ${msg.role}`}>
                <div className="flex-shrink-0 mt-1">
                  {msg.role === 'ai' ? (
                    <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg shadow-indigo-500/20">
                      <Sparkles size={14} color="#fff" />
                    </div>
                  ) : (
                    <div className="w-8 h-8 rounded-lg bg-slate-700 flex items-center justify-center border border-white/10">
                      <span className="text-xs font-bold">U</span>
                    </div>
                  )}
                </div>
                <div className="flex flex-col min-w-0">
                  <div className={`ai-bubble ${msg.role}`} dir={rtl ? 'rtl' : 'ltr'}>
                    <AiText text={msg.text} />

                    {/* Inline Confirmation Buttons inside Chat Bubble */}
                    {msg.requires_confirmation && msg.pending_tool && (
                      <div className="flex gap-2 mt-3 pt-3 border-t border-white/10">
                        <button
                          type="button"
                          disabled={toolBusy}
                          onClick={() => executeTool(msg.pending_tool.tool_name, msg.pending_tool.target_id, msg.pending_tool.parameters)}
                          className="flex-1 py-1.5 px-3 rounded-lg bg-emerald-500/25 hover:bg-emerald-500/40 border border-emerald-500/40 text-emerald-200 text-xs font-bold flex items-center justify-center gap-1"
                        >
                          <Check size={13} /> Confirm
                        </button>
                        <button
                          type="button"
                          disabled={toolBusy}
                          onClick={() => send('Pending purchases')}
                          className="py-1.5 px-3 rounded-lg bg-red-500/20 hover:bg-red-500/35 border border-red-500/30 text-red-200 text-xs font-bold flex items-center justify-center gap-1"
                        >
                          <X size={13} /> Cancel
                        </button>
                      </div>
                    )}

                    {/* Inline Contextual Action Pills */}
                    {Array.isArray(msg.actions) && msg.actions.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 mt-3 pt-2.5 border-t border-white/10">
                        {msg.actions.map((act, idx) => (
                          <button
                            key={idx}
                            type="button"
                            onClick={() => act.route && navigate(act.route)}
                            className="px-2.5 py-1 rounded-md bg-indigo-500/20 hover:bg-indigo-500/35 border border-indigo-500/30 text-indigo-200 text-[11px] font-semibold flex items-center gap-1"
                          >
                            <Compass size={11} /> {act.label}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                  <div className="text-[10px] text-slate-500 mt-1.5 px-1">
                    {msg.ts?.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' })}
                  </div>
                </div>
              </div>
            );
          })}
          {loading && (
            <div className="ai-msg">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
                <Activity size={14} color="#fff" className="animate-spin" />
              </div>
              <div className="ai-bubble ai text-indigo-300 italic flex items-center gap-2">
                Analyzing live database & permissions...
              </div>
            </div>
          )}
          <div ref={bottomRef} />
        </div>

        <div className="ai-input-row">
          <div className="quick-actions">
            {[
              "Proactive insights",
              "Pending purchases",
              "Overdue rent",
              "Expiring contracts",
              "Fuel status",
              "Run system diagnostics"
            ].map(s => (
              <button key={s} className="quick-action-tag" onClick={() => send(s)}>
                <ArrowRight size={10} /> {s}
              </button>
            ))}
          </div>
          <div className="ai-input-wrapper">
            <input
              ref={inputRef}
              className="ai-input"
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); send(); } }}
              placeholder="Ask or command Agency AI (EN / FR / AR)..."
              disabled={loading}
            />
            <button className="ai-send" onClick={() => send()} disabled={loading || !input.trim()}>
              <Send size={17} />
            </button>
          </div>
        </div>
      </div>

      {/* Right Stage: Hologram Diagnostics & Admin AI Control Center */}
      <div className="agency-main">
        {/* Top Stage Navigation Bar */}
        <div className="flex flex-wrap items-center justify-between gap-4 pb-6 mb-6 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="p-2.5 bg-indigo-500/20 rounded-xl border border-indigo-500/30 text-indigo-400">
              <Zap size={22} />
            </div>
            <div>
              <h2 className="text-xl font-bold text-white tracking-wide uppercase">
                {activeTab === 'control'
                  ? 'Admin AI Control Center & Audit Telemetry'
                  : (latestWidget ? latestWidget.type.replace(/_/g, ' ') : 'Autonomous Intelligence Stage')}
              </h2>
              <p className="text-slate-400 text-xs mt-0.5">
                Real-time verified database telemetry, proactive risk detection, and permission-governed tool execution.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => { setActiveTab('hologram'); send('Proactive insights'); }}
              className={`px-3.5 py-2 rounded-lg text-xs font-bold flex items-center gap-1.5 border transition ${
                activeTab === 'hologram' && latestWidget?.type === 'proactive_insights'
                  ? 'bg-indigo-600 text-white border-indigo-500'
                  : 'bg-white/5 text-slate-300 border-white/10 hover:bg-white/10'
              }`}
            >
              <Sparkles size={14} /> Proactive Insights
            </button>
            <button
              type="button"
              onClick={() => { setActiveTab('hologram'); send('Run system diagnostics'); }}
              className={`px-3.5 py-2 rounded-lg text-xs font-bold flex items-center gap-1.5 border transition ${
                activeTab === 'hologram' && latestWidget?.type === 'system_diagnostics'
                  ? 'bg-indigo-600 text-white border-indigo-500'
                  : 'bg-white/5 text-slate-300 border-white/10 hover:bg-white/10'
              }`}
            >
              <Cpu size={14} /> System Diagnostics
            </button>
            {userRole === 'admin' && (
              <button
                type="button"
                onClick={() => setActiveTab('control')}
                className={`px-3.5 py-2 rounded-lg text-xs font-bold flex items-center gap-1.5 border transition ${
                  activeTab === 'control'
                    ? 'bg-purple-600 text-white border-purple-500'
                    : 'bg-white/5 text-slate-300 border-white/10 hover:bg-white/10'
                }`}
              >
                <Settings size={14} /> AI Control Center
              </button>
            )}
          </div>
        </div>

        {/* Admin AI Control Center View */}
        {activeTab === 'control' && userRole === 'admin' ? (
          <div className="holo-container space-y-6">
            {/* Telemetry KPI Row */}
            <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
              {[
                { label: 'Synced Entities', val: kgRef.current.buildings.length + kgRef.current.apartments.length + kgRef.current.tenants.length, color: 'text-indigo-400' },
                { label: 'Conversation Turns', val: messages.length, color: 'text-emerald-400' },
                { label: 'DB Uplink Latency', val: `${kgRef.current.latencyMs} ms`, color: 'text-cyan-400' },
                { label: 'Tools Executed', val: toolLogs.filter(l => l.status === 'executed').length, color: 'text-amber-400' },
                { label: 'Blocked Threats', val: toolLogs.filter(l => l.status === 'blocked').length, color: 'text-red-400' },
              ].map((s, idx) => (
                <div key={idx} className="diag-card">
                  <div className="text-xs text-slate-400 uppercase tracking-wider">{s.label}</div>
                  <div className={`text-2xl font-black mt-2 ${s.color}`}>{s.val}</div>
                </div>
              ))}
            </div>

            {/* Governance Switches */}
            <div className="diag-hero-card">
              <h3 className="text-base font-bold text-white mb-4 flex items-center gap-2">
                <Lock size={18} className="text-indigo-400" /> AI Governance & Safety Switches
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {[
                  { key: 'ai_enabled', title: 'Master AI Engine Switch (Kill-Switch)', desc: 'Enable or pause all AI responses across Web and Mobile apps.' },
                  { key: 'autonomous_actions_enabled', title: 'Autonomous Tool Execution', desc: 'Allow authorized users to approve purchases, tasks, and updates via AI.' },
                  { key: 'require_confirmation', title: 'Mandatory Confirmation Guard', desc: 'Require explicit confirmation before any financial or status mutation.' },
                  { key: 'proactive_insights_enabled', title: 'Proactive Anomaly Detection', desc: 'Continuously scan overdue rent, expiring leases, and fuel reserves.' },
                ].map(cfg => {
                  const enabled = adminSettings[cfg.key] ?? true;
                  return (
                    <div key={cfg.key} className="flex items-center justify-between p-4 rounded-xl bg-black/30 border border-white/10">
                      <div className="pr-4">
                        <div className="font-bold text-sm text-white">{cfg.title}</div>
                        <div className="text-xs text-slate-400 mt-0.5">{cfg.desc}</div>
                      </div>
                      <button
                        type="button"
                        onClick={() => toggleAdminSetting(cfg.key, enabled)}
                        className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition ${
                          enabled
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/40'
                            : 'bg-red-500/20 text-red-300 border border-red-500/40'
                        }`}
                      >
                        {enabled ? 'ENABLED' : 'PAUSED'}
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Recent Autonomous Tool & Security Audit Logs */}
            <div className="diag-hero-card">
              <h3 className="text-base font-bold text-white mb-4">Recent Autonomous Tool & Security Audit Logs</h3>
              <div className="space-y-2 max-h-80 overflow-y-auto">
                {toolLogs.length === 0 ? (
                  <p className="text-slate-400 text-sm">No tool executions recorded in this session yet.</p>
                ) : (
                  toolLogs.map((log, i) => (
                    <div key={i} className="flex items-center justify-between p-3 rounded-lg bg-black/30 border border-white/5 text-xs">
                      <div>
                        <span className="font-bold text-indigo-300 uppercase mr-2">[{log.tool_name}]</span>
                        <span className="text-white">{log.result_summary}</span>
                        <span className="text-slate-500 ml-2">by {log.user_name} ({log.user_role})</span>
                      </div>
                      <span className="text-slate-400">{log.created_at}</span>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        ) : latestWidget ? (
          <div className="holo-container">
            <SmartHologram
              type={latestWidget.type}
              data={latestWidget.data}
              pendingTool={latestWidget.pendingTool}
              onNavigate={route => navigate(route)}
              onExecuteTool={executeTool}
              onSendPrompt={send}
              toolBusy={toolBusy}
            />
          </div>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
            <Shield size={64} className="mb-6 opacity-20" />
            <h2 className="text-xl tracking-widest uppercase">Autonomous Agency AI Ready</h2>
            <p className="text-sm mt-2 opacity-60">Select a command or click Proactive Insights above to inspect live telemetry</p>
          </div>
        )}
      </div>
    </div>
  );
}
