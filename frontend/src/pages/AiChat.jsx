import React, { useState, useRef, useEffect, useCallback } from 'react';
import axios from '../api/axios';
import { 
  Bot, Send, Sparkles, X, RotateCcw, ChevronRight, 
  Building2, Users, Home, DollarSign, AlertTriangle, 
  Wrench, Zap, Fuel, Shield, ShoppingCart, HardHat,
  FileText, TrendingUp, TrendingDown, CheckCircle, Clock,
  Phone, Mail, Calendar, Copy, Loader2, Activity,
  ArrowRight, ShieldAlert, ZapOff, Fingerprint, Eye
} from 'lucide-react';

// ─── Format Helpers ────────────────────────────────────────────────────────
const fmt = (n) => 'CFA ' + Number(n || 0).toLocaleString();
const fmtNum = (n) => Number(n || 0).toLocaleString();
const fmtDate = (d) => d ? new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';
const daysColor = (days) => days <= 7 ? '#ef4444' : days <= 30 ? '#f59e0b' : '#22c55e';
const getStatusClass = (days) => days <= 7 ? 'danger' : days <= 30 ? 'warning' : 'success';

// ─── Diagnostics Renderers (Main Stage) ────────────────────────────────────

const ActionButton = ({ icon: Icon, label, onClick, variant = 'primary' }) => (
  <button className={`diag-action-btn ${variant}`} onClick={onClick}>
    {Icon && <Icon size={14} />} {label}
  </button>
);

const ExpiringContractsWidget = ({ data }) => (
  <div className="diag-grid">
    {data.map((item, i) => (
      <div key={i} className={`diag-card ${getStatusClass(item.days_left)}`}>
        <div className="ai-card-header">
          <span className="ai-card-title text-lg">{item.full_name}</span>
          <span className="ai-badge" style={{ background: daysColor(item.days_left) + '22', color: daysColor(item.days_left), border: `1px solid ${daysColor(item.days_left)}55` }}>
            {item.days_left} days left
          </span>
        </div>
        <div className="ai-card-row"><Building2 size={12}/> {item.building_name} — Apt {item.apartment_code}</div>
        <div className="ai-card-row"><Calendar size={12}/> Expires {fmtDate(item.end_date)}</div>
        <div className="ai-card-row"><DollarSign size={12}/> {fmt(item.monthly_rent)}/mo</div>
        <ActionButton icon={FileText} label="Initiate Renewal" />
      </div>
    ))}
  </div>
);

const OverdueRentWidget = ({ data }) => (
  <div className="diag-grid">
    {data.map((item, i) => (
      <div key={i} className="diag-card danger">
        <div className="ai-card-header">
          <span className="ai-card-title text-lg">{item.full_name}</span>
          <span className="ai-badge ai-badge-danger">{item.days_overdue}d overdue</span>
        </div>
        <div className="ai-card-row"><Building2 size={12}/> {item.building_name} — Apt {item.apartment_code}</div>
        <div className="ai-card-row text-red-400 font-bold mt-2">
          Outstanding: {fmt(item.outstanding)}
        </div>
        <div className="flex gap-2 mt-2">
          <ActionButton icon={Phone} label="Call" variant="primary" />
          <ActionButton icon={ShieldAlert} label="Eviction Notice" variant="danger" />
        </div>
      </div>
    ))}
  </div>
);

const MaintenanceWidget = ({ data }) => (
  <div className="w-full">
    <div className="grid grid-cols-4 gap-4 mb-6">
      {[
        {label:'Total Tasks',val:data.summary.total,color:'#6366f1'},
        {label:'Pending',val:data.summary.pending,color:'#f59e0b'},
        {label:'In Progress',val:data.summary.in_progress,color:'#3b82f6'},
        {label:'Completed',val:data.summary.completed,color:'#22c55e'},
      ].map((s,i)=>(
        <div key={i} className="bg-slate-800/50 p-4 rounded-xl border border-white/5" style={{borderLeft:`4px solid ${s.color}`}}>
          <div className="text-xs text-slate-400 font-semibold uppercase">{s.label}</div>
          <div className="text-2xl font-bold mt-1" style={{color:s.color}}>{s.val}</div>
        </div>
      ))}
    </div>
    <div className="diag-grid">
      {data.tasks.map((t,i)=>(
        <div key={i} className={`diag-card ${t.status==='Pending'?'warning':'primary'}`}>
          <div className="ai-card-header">
            <span className="ai-card-title"><Wrench size={14} className="mr-2"/>Apt {t.apartment_code}</span>
            <span className="ai-badge ai-badge-warn">{t.status}</span>
          </div>
          <div className="ai-card-row"><Building2 size={12}/> {t.building_name}</div>
          <div className="ai-card-row"><Calendar size={12}/> Scheduled: {fmtDate(t.scheduled_date)}</div>
          {t.status === 'Pending' && <ActionButton icon={CheckCircle} label="Dispatch Team" />}
        </div>
      ))}
    </div>
  </div>
);

const FuelWidget = ({ data }) => (
  <div className="diag-grid">
    {data.map((item, i) => {
      const pct = item.total_in > 0 ? Math.min((item.current_stock / item.total_in) * 100, 100) : 0;
      const barColor = pct < 20 ? '#ef4444' : pct < 50 ? '#f59e0b' : '#22c55e';
      return (
        <div key={i} className={`diag-card ${pct < 20 ? 'danger' : 'success'}`}>
          <div className="ai-card-header">
            <span className="ai-card-title text-lg"><Fuel size={16} className="mr-2"/>{item.generator_name}</span>
            <span className="ai-badge" style={{color:barColor,background:barColor+'22',border:`1px solid ${barColor}55`}}>{item.status}</span>
          </div>
          <div className="ai-card-row">{item.location}</div>
          <div className="mt-4 mb-2">
            <div className="flex justify-between text-xs mb-1">
              <span>Stock Level</span>
              <span style={{color:barColor,fontWeight:700}}>{pct.toFixed(1)}%</span>
            </div>
            <div className="h-2 bg-slate-800 rounded-full overflow-hidden">
              <div className="h-full rounded-full transition-all duration-1000" style={{width:`${pct}%`,background:barColor}}/>
            </div>
          </div>
          <div className="flex justify-between text-sm font-bold">
            <span className="text-emerald-400">In: {fmtNum(item.total_in)}L</span>
            <span className="text-white">{fmtNum(item.current_stock)}L Remaining</span>
          </div>
          {pct < 30 && <ActionButton icon={ShoppingCart} label="Order Fuel Refill" variant="warning" />}
        </div>
      );
    })}
  </div>
);

const DefaultDataDisplay = ({ data, type }) => (
  <div className="w-full bg-slate-900/50 rounded-xl p-6 border border-indigo-500/20 backdrop-blur-md">
    <div className="flex items-center gap-3 mb-4 text-indigo-400">
      <Eye size={24} />
      <h3 className="text-xl font-bold uppercase tracking-wider">{type.replace(/_/g, ' ')} DATA</h3>
    </div>
    <pre className="text-sm text-slate-300 font-mono overflow-auto max-h-[60vh] p-4 bg-slate-950/50 rounded-lg">
      {JSON.stringify(data, null, 2)}
    </pre>
  </div>
);

// ─── Widget Router ──────────────────────────────────────────────────────────
const SmartHologram = ({ type, data }) => {
  if (!data) return null;
  switch(type) {
    case 'expiring_contracts':  return <ExpiringContractsWidget data={data}/>;
    case 'overdue_rent':        return <OverdueRentWidget data={data}/>;
    case 'maintenance_tasks':   return <MaintenanceWidget data={data}/>;
    case 'fuel_status':         return <FuelWidget data={data}/>;
    default:                    return <DefaultDataDisplay data={data} type={type} />;
  }
};

// ─── Formatted AI Response Text ────────────────────────────────────────────
const AiText = ({ text }) => {
  const parts = text.split(/(\*\*[^*]+\*\*)/g);
  return (
    <p style={{margin:0,lineHeight:1.6}}>
      {parts.map((p, i) =>
        p.startsWith('**') ? <strong key={i} style={{color:'#f9fafb',fontWeight:700}}>{p.slice(2,-2)}</strong> : p
      )}
    </p>
  );
};

// ─── Main AI Agency Page ─────────────────────────────────────────────────────
export default function AiAgency() {
  const [messages, setMessages] = useState([
    {
      role: 'ai',
      text: "ACCESS GRANTED. **Bitar PMS Agency Core** online. I am monitoring all properties, financials, and operations. How can I assist you?",
      type: 'text',
      data: null,
      ts: new Date()
    }
  ]);
  const [latestWidget, setLatestWidget] = useState(null);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef(null);
  const inputRef = useRef(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, loading]);

  const send = useCallback(async (text) => {
    const msg = (text || input).trim();
    if (!msg || loading) return;
    
    setInput('');
    setMessages(prev => [...prev, { role: 'user', text: msg, type: 'text', ts: new Date() }]);
    setLoading(true);
    
    try {
      const res = await axios.post('/ai/chat', { message: msg });
      const d = res.data;
      
      const newMsg = {
        role: 'ai',
        text: d.reply || d.response || 'Action completed.',
        type: d.type || 'text',
        data: d.data,
        ts: new Date()
      };
      
      setMessages(prev => [...prev, newMsg]);
      
      if (d.type && d.type !== 'text' && d.data) {
        setLatestWidget({ type: d.type, data: d.data, title: d.reply });
      }
      
    } catch (e) {
      setMessages(prev => [...prev, {
        role: 'ai',
        text: 'SYSTEM ERROR: Uplink to AI Core failed. Ensure backend systems are operational.',
        type: 'text',
        ts: new Date()
      }]);
    } finally {
      setLoading(false);
      inputRef.current?.focus();
    }
  }, [input, loading]);

  const clear = () => {
    setMessages([messages[0]]);
    setLatestWidget(null);
  };

  return (
    <div className="agency-layout">
      <style>{`
        .agency-layout { display: flex; height: 100vh; background: #030712; color: #f3f4f6; font-family: 'Inter', sans-serif; overflow: hidden; position: relative; }
        .agency-bg { position: absolute; inset: 0; background: radial-gradient(circle at 50% 0%, #1e1b4b 0%, #030712 60%); z-index: 0; opacity: 0.6; }
        .agency-grid { position: absolute; inset: 0; background-image: linear-gradient(to right, #ffffff05 1px, transparent 1px), linear-gradient(to bottom, #ffffff05 1px, transparent 1px); background-size: 40px 40px; z-index: 0; }

        .agency-sidebar { width: 400px; display: flex; flex-direction: column; background: rgba(15, 23, 42, 0.75); backdrop-filter: blur(20px); border-right: 1px solid rgba(255,255,255,0.05); z-index: 10; box-shadow: 10px 0 30px rgba(0,0,0,0.5); }
        .agency-header { padding: 24px; border-bottom: 1px solid rgba(255,255,255,0.05); display: flex; align-items: center; gap: 16px; }
        .agency-logo-box { width: 48px; height: 48px; border-radius: 12px; background: linear-gradient(135deg, #0ea5e9, #6366f1); display: flex; align-items: center; justify-content: center; box-shadow: 0 0 20px rgba(99, 102, 241, 0.4); }

        .agency-main { flex: 1; display: flex; flex-direction: column; padding: 32px; z-index: 10; overflow-y: auto; position: relative; }
        
        .holo-container { width: 100%; max-width: 1400px; margin: 0 auto; animation: holoFadeIn 0.8s cubic-bezier(0.16, 1, 0.3, 1) forwards; transform-style: preserve-3d; }
        @keyframes holoFadeIn { from { opacity: 0; transform: translateY(40px) scale(0.95); } to { opacity: 1; transform: translateY(0) scale(1); } }

        .chat-scroll { flex: 1; overflow-y: auto; padding: 24px; display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth; }
        .chat-scroll::-webkit-scrollbar { width: 4px; }
        .chat-scroll::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 4px; }

        .ai-msg { display: flex; gap: 12px; animation: fadeLeft 0.3s ease; }
        .ai-msg.user { flex-direction: row-reverse; }
        @keyframes fadeLeft { from { opacity: 0; transform: translateX(-10px); } to { opacity: 1; transform: translateX(0); } }

        .ai-bubble { max-width: 85%; border-radius: 16px; padding: 14px 18px; font-size: 14px; line-height: 1.6; }
        .ai-bubble.bot { background: rgba(30, 41, 59, 0.8); border: 1px solid rgba(255,255,255,0.1); border-radius: 4px 16px 16px 16px; color: #e2e8f0; }
        .ai-bubble.user { background: linear-gradient(135deg, #3b82f6, #6366f1); color: #fff; border-radius: 16px 4px 16px 16px; box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3); }

        .diag-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 24px; width: 100%; }
        .diag-card { background: rgba(17, 24, 39, 0.7); border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; padding: 24px; backdrop-filter: blur(12px); box-shadow: 0 10px 30px rgba(0,0,0,0.5); transition: 0.3s; position: relative; overflow: hidden; }
        .diag-card:hover { transform: translateY(-5px); border-color: rgba(99, 102, 241, 0.5); box-shadow: 0 15px 40px rgba(99, 102, 241, 0.2); }
        .diag-card::before { content: ''; position: absolute; top: 0; left: 0; width: 4px; height: 100%; background: #6366f1; transition: 0.3s; }
        .diag-card.danger::before { background: #ef4444; }
        .diag-card.warning::before { background: #f59e0b; }
        .diag-card.success::before { background: #22c55e; }

        .diag-action-btn { margin-top: 16px; flex: 1; padding: 12px; font-size: 13px; border-radius: 8px; font-weight: 600; cursor: pointer; transition: 0.2s; display: flex; align-items: center; justify-content: center; gap: 8px; }
        .diag-action-btn.primary { background: rgba(99, 102, 241, 0.1); color: #818cf8; border: 1px solid rgba(99, 102, 241, 0.2); }
        .diag-action-btn.primary:hover { background: rgba(99, 102, 241, 0.25); color: #fff; border-color: rgba(99, 102, 241, 0.5); box-shadow: 0 0 15px rgba(99,102,241,0.3); }
        .diag-action-btn.danger { background: rgba(239, 68, 68, 0.1); color: #f87171; border: 1px solid rgba(239, 68, 68, 0.2); }
        .diag-action-btn.danger:hover { background: rgba(239, 68, 68, 0.25); color: #fff; border-color: rgba(239, 68, 68, 0.5); box-shadow: 0 0 15px rgba(239,68,68,0.3); }
        .diag-action-btn.warning { background: rgba(245, 158, 11, 0.1); color: #fbbf24; border: 1px solid rgba(245, 158, 11, 0.2); }
        .diag-action-btn.warning:hover { background: rgba(245, 158, 11, 0.25); color: #fff; border-color: rgba(245, 158, 11, 0.5); box-shadow: 0 0 15px rgba(245,158,11,0.3); }

        .ai-input-row { padding: 20px 24px; border-top: 1px solid rgba(255,255,255,0.05); background: rgba(15, 23, 42, 0.9); }
        .ai-input-wrapper { display: flex; gap: 12px; background: rgba(0,0,0,0.3); border: 1px solid rgba(255,255,255,0.1); border-radius: 16px; padding: 6px; transition: 0.3s; }
        .ai-input-wrapper:focus-within { border-color: rgba(99, 102, 241, 0.6); box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.15); }
        
        .ai-input { flex: 1; background: transparent; border: none; padding: 12px 16px; color: #fff; font-size: 15px; outline: none; }
        .ai-input::placeholder { color: #64748b; }
        
        .ai-send { width: 44px; height: 44px; border-radius: 12px; background: linear-gradient(135deg, #3b82f6, #6366f1); border: none; color: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: 0.2s; box-shadow: 0 4px 15px rgba(99, 102, 241, 0.3); }
        .ai-send:hover:not(:disabled) { transform: scale(1.05); box-shadow: 0 6px 20px rgba(99, 102, 241, 0.5); }
        .ai-send:disabled { opacity: 0.5; cursor: not-allowed; filter: grayscale(1); box-shadow: none; }

        .quick-actions { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 16px; }
        .quick-action-tag { background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); padding: 6px 12px; border-radius: 20px; font-size: 12px; color: #cbd5e1; cursor: pointer; transition: 0.2s; display: flex; align-items: center; gap: 6px; }
        .quick-action-tag:hover { background: rgba(99, 102, 241, 0.15); color: #fff; border-color: rgba(99, 102, 241, 0.5); }
      `}</style>
      
      <div className="agency-bg"></div>
      <div className="agency-grid"></div>

      {/* Sidebar: Chat / Uplink */}
      <div className="agency-sidebar">
        <div className="agency-header">
          <div className="agency-logo-box">
            <Fingerprint size={28} color="#fff" />
          </div>
          <div className="flex-1">
            <h1 className="text-lg font-bold text-white tracking-wide">AGENCY CORE</h1>
            <div className="flex items-center gap-2 mt-1">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
              <span className="text-xs text-emerald-400 font-medium">UPLINK SECURE</span>
            </div>
          </div>
          <button className="p-2 bg-white/5 hover:bg-white/10 rounded-lg transition-colors border border-white/10 text-slate-400 hover:text-white" onClick={clear}>
            <RotateCcw size={16} />
          </button>
        </div>

        <div className="chat-scroll">
          {messages.map((msg, i) => (
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
                <div className={`ai-bubble ${msg.role}`}>
                  <AiText text={msg.text}/>
                </div>
                <div className="text-[10px] text-slate-500 mt-2 px-1">
                  {msg.ts?.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
                </div>
              </div>
            </div>
          ))}
          {loading && (
            <div className="ai-msg">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
                <Activity size={14} color="#fff" className="animate-spin" />
              </div>
              <div className="ai-bubble bot text-indigo-300 italic flex items-center gap-2">
                Processing Query...
              </div>
            </div>
          )}
          <div ref={bottomRef}/>
        </div>

        <div className="ai-input-row">
          <div className="quick-actions mb-4">
            {["Expiring contracts", "Top debtors", "Fuel status", "Maintenance tasks"].map(s => (
              <button key={s} className="quick-action-tag" onClick={() => send(s)}>
                <ArrowRight size={10}/> {s}
              </button>
            ))}
          </div>
          <div className="ai-input-wrapper">
            <input
              ref={inputRef}
              className="ai-input"
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={e => { if(e.key==='Enter'&&!e.shiftKey){ e.preventDefault(); send(); }}}
              placeholder="Command the Agency..."
              disabled={loading}
            />
            <button className="ai-send" onClick={() => send()} disabled={loading || !input.trim()}>
              <Send size={18} />
            </button>
          </div>
        </div>
      </div>

      {/* Main Stage: Hologram Diagnostics */}
      <div className="agency-main">
        {latestWidget ? (
          <div className="holo-container">
            <div className="flex items-center gap-3 mb-8">
              <div className="p-3 bg-indigo-500/20 rounded-xl border border-indigo-500/30 text-indigo-400">
                <Activity size={24} />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white tracking-wide uppercase">{latestWidget.type.replace(/_/g, ' ')}</h2>
                <p className="text-slate-400 text-sm mt-1">Diagnostic scan complete. Results rendered below.</p>
              </div>
            </div>
            
            <SmartHologram type={latestWidget.type} data={latestWidget.data} />
          </div>
        ) : (
          <div className="flex-1 flex flex-col items-center justify-center text-slate-500 animate-pulse">
            <Shield size={64} className="mb-6 opacity-20" />
            <h2 className="text-xl tracking-widest uppercase">Standby for Orders</h2>
            <p className="text-sm mt-2 opacity-50">Query the uplink to initialize holograms</p>
          </div>
        )}
      </div>
    </div>
  );
}
