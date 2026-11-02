import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import axios from '../../api/axios';
import InteractiveCurrency from '../../components/common/InteractiveCurrency';
import {
  Zap, Building2, Home, User, Calendar, Clock, Camera, Check,
  AlertCircle, ChevronRight, FileText, RotateCcw, CheckCircle2,
  XCircle, ArrowLeft, Upload, Eye, DollarSign, ListTodo, CheckCircle
} from 'lucide-react';

// ─── Helpers ─────────────────────────────────────────────────────────────────
const formatDate = (d) => {
  if (!d) return 'N/A';
  return new Date(d).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
};

const DaysBadge = ({ days }) => {
  if (days === undefined || days === null) return null;
  const d = parseInt(days);
  if (d < 0) return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-danger text-white animate-pulse">Expired</span>;
  if (d === 0) return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-danger text-white animate-pulse">Due Today</span>;
  if (d <= 5) return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-danger/20 text-danger border border-danger/40">⚡ {d}d left</span>;
  if (d <= 10) return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-orange-500/20 text-orange-400 border border-orange-400/30">🔥 {d}d left</span>;
  if (d <= 20) return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-warning/20 text-warning border border-warning/30">⏰ {d}d left</span>;
  return <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-slate-700/50 text-slate-400 border border-slate-600/40">📅 {d}d left</span>;
};

const StatusBadge = ({ status }) => {
  switch (status) {
    case 'Pending':
      return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-warning/20 text-warning border border-warning/30 flex items-center gap-1 w-max"><Clock size={11} /> Pending Review</span>;
    case 'Accepted':
      return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-success/20 text-success border border-success/30 flex items-center gap-1 w-max"><CheckCircle2 size={11} /> Accepted ✓</span>;
    case 'Rejected':
      return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-danger/20 text-danger border border-danger/30 flex items-center gap-1 w-max"><XCircle size={11} /> Rejected</span>;
    default:
      return <span className="px-2.5 py-1 rounded-full text-xs font-bold bg-slate-700 text-slate-300 w-max">—</span>;
  }
};

// ─── Reading Form Modal ───────────────────────────────────────────────────────
const ReadingFormModal = ({ task, onClose, onSuccess }) => {
  const queryClient = useQueryClient();
  const [currentReading, setCurrentReading] = useState('');
  const [notes, setNotes] = useState('');
  const [meterPhoto, setMeterPhoto] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  
  // Payment Collection State
  const [payStatus, setPayStatus] = useState('still_didnt_pay');
  const [amountCollected, setAmountCollected] = useState(task.monthly_fee || 0);

  const user = (() => { try { return JSON.parse(localStorage.getItem('user')); } catch { return null; } })();
  const isFixed = task.subscription_type === 'Fixed Amp' || task.subscription_type === 'Fixed Monthly';

  const submitMutation = useMutation({
    mutationFn: async () => {
      if (!meterPhoto) throw new Error('Meter photo is required.');
      if (!task.amps && !currentReading) throw new Error('Current reading is required for metered subscriptions.');

      const fd = new FormData();
      fd.append('apartment_id', task.apartment_id);
      fd.append('subscription_id', task.subscription_id);
      if (isFixed) {
        fd.append('current_reading', 0);
      } else {
        fd.append('current_reading', currentReading);
      }
      fd.append('previous_reading', task.previous_reading || 0);
      fd.append('notes', notes);
      fd.append('submitted_by', user?.id || 1);
      
      if (payStatus === 'collected') {
        fd.append('amount_collected', amountCollected);
      }
      
      if (meterPhoto) {
          fd.append('meter_photo', meterPhoto);
      } else if (!task.amps) {
          throw new Error('Meter photo is required for metered subscriptions.');
      }

      return axios.post('/energy/agent/subscription-reading', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['agent_subscription_tasks']);
      onSuccess();
    },
    onError: (err) => {
      alert(err.message || err.response?.data?.error || 'Failed to submit reading.');
    }
  });

  const handlePhotoChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setMeterPhoto(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const consumption = currentReading && task.previous_reading
    ? Math.max(0, parseFloat(currentReading) - parseFloat(task.previous_reading))
    : null;

  const isResubmit = task.latest_submission_status === 'Rejected';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm">
      <div className="glass-card w-full max-w-lg overflow-y-auto max-h-[95vh] rounded-2xl shadow-2xl">
        {/* Header */}
        <div className="p-6 border-b border-slate-700/50 flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2 text-xs text-slate-400 mb-1">
              <Building2 size={13} />
              <span>{task.building_name}</span>
              <ChevronRight size={13} />
              <Home size={13} />
              <span>Apt {task.apartment_code}</span>
              <ChevronRight size={13} />
              <User size={13} />
              <span>{task.tenant_name || 'N/A'}</span>
            </div>
            <h2 className="text-xl font-bold text-white">
              {isResubmit ? '🔁 Resubmit Meter Reading' : '📋 Submit Meter Reading'}
            </h2>
            <p className="text-sm text-muted mt-0.5">
              Subscription: {formatDate(task.start_date)} → {formatDate(task.end_date)}
            </p>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white p-1 rounded-lg transition-colors">
            <ArrowLeft size={20} />
          </button>
        </div>

        {/* Rejection notice */}
        {isResubmit && task.rejection_reason && (
          <div className="mx-6 mt-4 p-4 bg-danger/10 border border-danger/30 rounded-xl flex gap-3">
            <AlertCircle size={18} className="text-danger shrink-0 mt-0.5" />
            <div>
              <p className="text-danger font-bold text-sm">Reading was rejected</p>
              <p className="text-sm text-slate-300 mt-1">{task.rejection_reason}</p>
              <p className="text-xs text-slate-400 mt-1">Please correct and resubmit below.</p>
            </div>
          </div>
        )}

        <div className="p-6 space-y-5">
          {/* Fixed Subscription Notice */}
          {isFixed && (
            <div className="bg-info/10 border border-info/30 rounded-xl p-4 flex items-start gap-3">
              <Zap size={20} className="text-info shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-bold text-info">Fixed Subscription ({task.amps} Amps)</p>
                <p className="text-sm text-slate-300 mt-1">
                  This subscription uses a fixed monthly fee. No meter reading is required. 
                  You can optionally provide notes or a photo, and then submit to request renewal.
                </p>
              </div>
            </div>
          )}

          {/* Previous Reading Card (Hidden for Fixed) */}
          {!isFixed && (
            <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex justify-between items-center">
              {task.previous_reading === null || task.previous_reading === '' ? (
                <div className="w-full text-center py-2">
                  <p className="text-sm font-bold text-slate-300">🆕 First Meter Reading</p>
                  <p className="text-xs text-slate-500 mt-1">No previous records exist for this apartment.</p>
                </div>
              ) : (
                <>
                  <div>
                    <p className="text-xs text-slate-400 mb-1 uppercase tracking-wider">Previous Reading</p>
                    <p className="text-2xl font-bold text-white">{task.previous_reading} <span className="text-sm font-normal text-slate-400">kWh</span></p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs text-slate-400 mb-1 uppercase tracking-wider">Last Recorded</p>
                    <p className="text-sm text-white">{formatDate(task.previous_reading_date)}</p>
                  </div>
                </>
              )}
            </div>
          )}

          {/* Current Reading Input (Hidden for Fixed) */}
          {!isFixed && (
            <div>
              <label className="block text-sm font-medium text-muted mb-2">
                New Current Reading (kWh) <span className="text-danger">*</span>
              </label>
              <input
                type="number"
                step="0.01"
                value={currentReading}
                onChange={e => setCurrentReading(e.target.value)}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-4 text-2xl font-bold text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-all"
                placeholder="Enter current meter value..."
              />
              {consumption !== null && task.previous_reading !== null && task.previous_reading !== '' && (
                <div className="mt-2 flex items-center gap-2">
                  <span className="text-sm text-slate-400">Consumption this period:</span>
                  <span className={`text-sm font-bold ${consumption > 0 ? 'text-info' : 'text-warning'}`}>
                    {consumption.toFixed(2)} kWh
                  </span>
                </div>
              )}
              {(task.previous_reading === null || task.previous_reading === '') && currentReading && (
                <div className="mt-2 flex items-center gap-2">
                  <span className="text-sm text-slate-400">Initial meter value recorded:</span>
                  <span className="text-sm font-bold text-info">{currentReading} kWh</span>
                </div>
              )}
            </div>
          )}

          {/* Photo Upload */}
          <div>
            <p className="text-sm font-medium text-muted mb-3">
              Meter Photo {!isFixed && <span className="text-danger">*</span>}
            </p>
            {previewUrl ? (
              <div className="relative rounded-xl overflow-hidden border border-success/30 group">
                <img src={previewUrl} alt="Meter" className="w-full h-44 object-contain bg-slate-900" />
                <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  <label htmlFor="meter-photo-sub" className="cursor-pointer bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg flex items-center gap-2 backdrop-blur-sm">
                    <Camera size={16} /> Change Photo
                  </label>
                </div>
                <div className="absolute top-2 right-2 bg-success text-white rounded-full p-1">
                  <Check size={14} />
                </div>
              </div>
            ) : (
              <label
                htmlFor="meter-photo-sub"
                className="flex flex-col items-center justify-center w-full h-36 border-2 border-dashed border-slate-600 hover:border-primary rounded-xl cursor-pointer transition-colors hover:bg-primary/5 group"
              >
                <div className="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center mb-3 group-hover:bg-primary/20 transition-colors">
                  <Upload size={22} className="text-primary" />
                </div>
                <p className="text-sm font-medium text-slate-300">Click to upload meter photo</p>
                <p className="text-xs text-slate-500 mt-1">JPG, PNG, HEIC • Mandatory proof</p>
              </label>
            )}
            <input
              type="file"
              id="meter-photo-sub"
              accept="image/*"
              capture="environment"
              className="hidden"
              onChange={handlePhotoChange}
            />
          </div>

          {/* Notes */}
          <div>
            <label className="block text-sm font-medium text-muted mb-2">Notes (Optional)</label>
            <textarea
              rows={2}
              value={notes}
              onChange={e => setNotes(e.target.value)}
              className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white text-sm focus:outline-none focus:border-primary transition-colors resize-none"
              placeholder="Meter condition, anomalies, access issues..."
            />
          </div>

          {/* Payment Collection */}
          <div className="pt-2 border-t border-slate-700/50">
            <label className="block text-sm font-medium text-muted mb-3">Payment Collection</label>
            <div className="flex flex-col gap-3">
              <label className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-colors ${payStatus === 'collected' ? 'border-primary bg-primary/10' : 'border-slate-700 bg-slate-800/50 hover:border-slate-600'}`}>
                <input type="radio" name="pay_status" checked={payStatus === 'collected'} onChange={() => setPayStatus('collected')} className="hidden" />
                <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${payStatus === 'collected' ? 'border-primary' : 'border-slate-500'}`}>
                  {payStatus === 'collected' && <div className="w-2.5 h-2.5 rounded-full bg-primary" />}
                </div>
                <span className="font-medium text-white text-sm">Collected Payment</span>
              </label>
              <label className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-colors ${payStatus === 'still_didnt_pay' ? 'border-danger bg-danger/10' : 'border-slate-700 bg-slate-800/50 hover:border-slate-600'}`}>
                <input type="radio" name="pay_status" checked={payStatus === 'still_didnt_pay'} onChange={() => setPayStatus('still_didnt_pay')} className="hidden" />
                <div className={`w-4 h-4 rounded-full border flex items-center justify-center ${payStatus === 'still_didnt_pay' ? 'border-danger' : 'border-slate-500'}`}>
                  {payStatus === 'still_didnt_pay' && <div className="w-2.5 h-2.5 rounded-full bg-danger" />}
                </div>
                <span className="font-medium text-white text-sm">Still Didn't Pay</span>
              </label>
            </div>

            {payStatus === 'collected' && (
              <div className="mt-4">
                <label className="block text-xs font-medium text-muted mb-2">Amount Collected ($)</label>
                <input
                  type="number"
                  step="0.01"
                  value={amountCollected}
                  onChange={e => setAmountCollected(e.target.value)}
                  className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-lg font-bold text-white focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary/30 transition-all"
                  placeholder="Enter amount..."
                />
              </div>
            )}
          </div>

          {/* Submit Button */}
          <button
            onClick={() => submitMutation.mutate()}
            disabled={submitMutation.isLoading || (!isFixed && (!currentReading || !meterPhoto))}
            className="w-full btn-primary py-4 rounded-xl text-lg font-bold flex items-center justify-center gap-2 shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {submitMutation.isLoading ? (
              <><div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" /> Submitting...</>
            ) : (
              <><Check size={20} /> {isResubmit ? 'Resubmit for Review' : 'Submit for Admin Review'}</>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Task Card ────────────────────────────────────────────────────────────────
const TaskCard = ({ task, onSelect }) => {
  const navigate = useNavigate();
  
  const handleClick = () => {
    switch (task.action_type) {
      case 'GENERATOR_LOG':
        navigate(`/agent-generators`, { state: { preselectGeneratorId: task.entity_id } });
        break;
      case 'RENT_COLLECTION':
        navigate(`/agent-collect`, { 
          state: { 
            autoFill: true, 
            collectionType: 'RENT', 
            buildingId: task.entity_id, 
            buildingName: task.title 
          } 
        });
        break;
      case 'ELECTRICITY_COLLECTION':
        navigate(`/agent-collect`, { 
          state: { 
            autoFill: true, 
            collectionType: 'ELECTRICITY', 
            buildingId: task.entity_id, 
            buildingName: task.title 
          } 
        });
        break;
      case 'SUBSCRIPTION_REVIEW':
        onSelect(task); // Still opens the modal for quick submission
        break;
      case 'EXPIRING_CONTRACT':
        navigate(`/contracts`); 
        break;
      case 'METER_READING':
        navigate(`/agent-apartment-costs`); 
        break;
      default:
        console.warn(`Unknown action type: ${task.action_type}`);
    }
  };

  // Determine styles based on action_type
  let borderColor = 'border-slate-700/50 hover:border-slate-500/50';
  let dotColor = 'bg-slate-500 shadow-slate-500/60';
  let tagColor = 'bg-slate-500/20 text-slate-400 border-slate-500/30';
  let icon = <ListTodo size={14} />;
  
  if (task.action_type === 'GENERATOR_LOG') {
    borderColor = 'border-warning/50 hover:border-warning hover:shadow-warning/10 bg-warning/5';
    dotColor = 'bg-warning shadow-warning/60';
    tagColor = 'bg-warning/20 text-warning border-warning/30';
    icon = <AlertCircle size={14} />;
  } else if (task.action_type === 'RENT_COLLECTION') {
    borderColor = 'border-danger/50 hover:border-danger hover:shadow-danger/10 bg-danger/5';
    dotColor = 'bg-danger shadow-danger/60';
    tagColor = 'bg-danger/20 text-danger border-danger/30';
    icon = <DollarSign size={14} />;
  } else if (task.action_type === 'ELECTRICITY_COLLECTION') {
    borderColor = 'border-amber-500/50 hover:border-amber-500 hover:shadow-amber-500/10 bg-amber-500/5';
    dotColor = 'bg-amber-500 shadow-amber-500/60';
    tagColor = 'bg-amber-500/20 text-amber-500 border-amber-500/30';
    icon = <Zap size={14} />;
  } else if (task.action_type === 'SUBSCRIPTION_REVIEW') {
    borderColor = 'border-sky-500/40 hover:border-sky-500 hover:shadow-sky-500/10 bg-sky-500/5';
    dotColor = 'bg-sky-500 shadow-sky-500/60';
    tagColor = 'bg-sky-500/20 text-sky-400 border-sky-500/30';
    icon = <Zap size={14} />;
  } else if (task.action_type === 'EXPIRING_CONTRACT') {
    borderColor = 'border-purple-500/40 hover:border-purple-500 hover:shadow-purple-500/10 bg-purple-500/5';
    dotColor = 'bg-purple-500 shadow-purple-500/60';
    tagColor = 'bg-purple-500/20 text-purple-400 border-purple-500/30';
    icon = <Clock size={14} />;
  } else if (task.action_type === 'METER_READING') {
    borderColor = 'border-emerald-500/40 hover:border-emerald-500 hover:shadow-emerald-500/10 bg-emerald-500/5';
    dotColor = 'bg-emerald-500 shadow-emerald-500/60';
    tagColor = 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30';
    icon = <CheckCircle size={14} />;
  }

  return (
    <div
      role="button"
      tabIndex={0}
      onClick={handleClick}
      onKeyDown={(e) => e.key === 'Enter' && handleClick()}
      className={`relative glass-card p-5 rounded-2xl transition-all duration-200 cursor-pointer hover:scale-[1.01] active:scale-[0.99] hover:bg-slate-800/80 outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2 focus:ring-offset-slate-900 border ${borderColor}`}
    >
      {/* ── Notification Dot (top-left) ── */}
      <span className="absolute -top-1.5 -left-1.5 flex h-4 w-4 z-10">
        <span className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${dotColor.split(' ')[0]}`} />
        <span className={`relative inline-flex rounded-full h-4 w-4 shadow-lg ${dotColor}`} />
      </span>

      {/* ── Tag ── */}
      <div className="flex items-center gap-2 mb-3">
        <span className={`text-xs px-2.5 py-1 rounded-md font-bold uppercase tracking-wider border flex items-center gap-1.5 ${tagColor}`}>
          {icon}
          {task.task_tag}
        </span>
      </div>

      {/* ── Title & Description ── */}
      <div className="mb-4">
        <div className="flex items-center gap-2 mb-2">
          <Building2 size={16} className={tagColor.split(' ')[1]} />
          <h3 className="text-lg font-bold text-white">{task.title}</h3>
        </div>
        <div className="flex items-start gap-2 border-b border-slate-700/50 pb-4">
          <Clock size={14} className="text-slate-400 shrink-0 mt-0.5" />
          <div className="flex flex-col gap-1">
            <div className="text-sm text-slate-300 leading-relaxed flex items-center gap-1 flex-wrap">
              {task.description ? (
                <p>{task.description}</p>
              ) : (
                <>
                  <span>{task.unpaid_count} pending {task.action_type === 'ELECTRICITY_COLLECTION' ? 'electricity ' : ''}invoices (Total: </span>
                  <InteractiveCurrency amountCFA={task.total_due} />
                  <span>)</span>
                </>
              )}
            </div>
            {task.apartments_list && (
              <p className="text-xs text-slate-400 leading-relaxed font-mono">
                <span className="font-bold text-slate-300">Apts:</span> {task.apartments_list.length > 80 ? task.apartments_list.substring(0, 80) + '...' : task.apartments_list}
              </p>
            )}
          </div>
        </div>
      </div>

      {/* ── Action Footer ── */}
      <div className="flex items-center justify-between group pt-4">
        <span className="text-sm text-warning flex items-center gap-1.5 font-bold tracking-wide">
          <AlertCircle size={14} /> {task.action_text}
        </span>
        <ChevronRight size={18} className="text-warning transition-transform group-hover:translate-x-1" />
      </div>
    </div>
  );
};

// ─── History Item ─────────────────────────────────────────────────────────────
const HistoryItem = ({ item }) => {
  const isFixed = item.subscription_type === 'Fixed Amp' || item.subscription_type === 'Fixed Monthly';
  
  return (
  <div className={`glass-card p-5 rounded-2xl border transition-all ${
    item.status === 'Accepted'
      ? 'border-success/30 bg-success/5'
      : item.status === 'Rejected'
      ? 'border-danger/30 bg-danger/5'
      : 'border-warning/20'
  }`}>
    <div className="flex items-start justify-between mb-3">
      <div>
        <div className="flex items-center gap-1.5 text-xs text-slate-400 mb-1 flex-wrap">
          <Building2 size={12} className="text-indigo-400" />
          <span className="text-indigo-300">{item.building_name}</span>
          <ChevronRight size={12} />
          <Home size={12} className="text-sky-400" />
          <span className="text-sky-300">Apt {item.apartment_code}</span>
          <ChevronRight size={12} />
          <User size={12} className="text-emerald-400" />
          <span className="text-emerald-300">{item.tenant_name || 'N/A'}</span>
          
          {isFixed ? (
            <span className="ml-2 text-[10px] bg-info/20 text-info px-1.5 py-0.5 rounded border border-info/30 font-bold tracking-wide">FIXED</span>
          ) : (
            <span className="ml-2 text-[10px] bg-primary/20 text-primary px-1.5 py-0.5 rounded border border-primary/30 font-bold tracking-wide">METERED</span>
          )}
        </div>
        <div className="text-xs text-slate-500 flex items-center gap-1.5">
          <Calendar size={11} />
          Submitted {new Date(item.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
        </div>
      </div>
      <StatusBadge status={item.status} />
    </div>

    {!isFixed ? (
      <div className="grid grid-cols-3 gap-4 mt-3 pt-3 border-t border-slate-700/50">
        <div>
          <p className="text-xs text-slate-500">Prev.</p>
          <p className="text-sm font-bold text-white">{parseFloat(item.previous_reading || 0).toFixed(0)} kWh</p>
        </div>
        <div>
          <p className="text-xs text-slate-500">Current</p>
          <p className="text-sm font-bold text-primary">{parseFloat(item.current_reading || 0).toFixed(0)} kWh</p>
        </div>
        <div>
          <p className="text-xs text-slate-500">Consumed</p>
          <p className="text-sm font-bold text-info">{parseFloat(item.consumption || 0).toFixed(0)} kWh</p>
        </div>
      </div>
    ) : (
      <div className="mt-3 pt-3 border-t border-slate-700/50">
        <p className="text-sm text-info font-medium flex items-center gap-1.5">
          <Zap size={14} /> Fixed monthly payment confirmation
        </p>
        {item.notes && (
           <p className="text-xs text-slate-400 mt-1">Notes: {item.notes}</p>
        )}
      </div>
    )}

    {parseFloat(item.amount_collected || 0) > 0 && (
      <div className="mt-3 p-3 bg-primary/10 border border-primary/20 rounded-xl flex items-center justify-between">
        <p className="text-xs text-primary font-medium flex items-center gap-1.5">
          <DollarSign size={14} /> Payment Collected
        </p>
        <p className="text-sm font-bold text-white">${parseFloat(item.amount_collected).toFixed(2)}</p>
      </div>
    )}

    {item.status === 'Rejected' && item.rejection_reason && (
      <div className="mt-3 p-3 bg-danger/10 border border-danger/20 rounded-xl">
        <p className="text-xs text-danger font-medium">Rejection: {item.rejection_reason}</p>
      </div>
    )}

    {item.status === 'Accepted' && (
      <div className="mt-3 p-3 bg-success/10 border border-success/20 rounded-xl">
        <p className="text-xs text-success font-medium flex items-center gap-1">
          <CheckCircle2 size={12} /> Subscription renewed — new month activated
        </p>
      </div>
    )}

    {item.photo_path && (
      <a
        href={`${(process.env.REACT_APP_API_URL || 'http://localhost/Bitar/backend/api').replace('/backend/api', '')}/${item.photo_path}`}
        target="_blank"
        rel="noreferrer"
        className="mt-3 flex items-center gap-1.5 text-xs text-info hover:underline w-max"
      >
        <Eye size={12} /> View uploaded proof
      </a>
    )}
  </div>
  );
};

// ─── Main Page ────────────────────────────────────────────────────────────────
const AgentSubscriptions = () => {
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('tasks');
  const [selectedTask, setSelectedTask] = useState(null);
  const [successBanner, setSuccessBanner] = useState(false);

  // 1. Fetch Subscription Tasks
  const { data: subData, isLoading: subLoad } = useQuery({
    queryKey: ['agent_subscription_tasks'],
    queryFn: async () => {
      try {
        const res = await axios.get('/energy/agent/subscription-tasks');
        return res.data;
      } catch (e) {
        return { tasks: [], history: [] };
      }
    },
    refetchInterval: 30000,
  });

  // Fetch Smart Tasks (replacing manual aggregations)
  const { data: smartTasksData, isLoading: smartTasksLoad } = useQuery({
    queryKey: ['agent_smart_tasks'],
    queryFn: async () => {
      try {
        const res = await axios.get('/agent/smart-tasks');
        return res.data;
      } catch (e) {
        return { tasks: [] };
      }
    },
    refetchInterval: 30000,
  });

  const isLoading = subLoad || smartTasksLoad;
  const history = subData?.history || [];
  const allPendingTasks = smartTasksData?.tasks || [];

  const submittedTasks = history.filter(h => h.status === 'Pending');
  const acceptedHistory = history.filter(h => h.status === 'Accepted');
  const rejectedHistory = history.filter(h => h.status === 'Rejected');

  const handleSuccess = () => {
    setSelectedTask(null);
    setSuccessBanner(true);
    setTimeout(() => setSuccessBanner(false), 4000);
    queryClient.invalidateQueries(['agent_subscription_tasks']);
  };

  const tabs = [
    { id: 'tasks', label: 'All Pending Tasks', icon: ListTodo, count: allPendingTasks.length, color: 'warning' },
    { id: 'submitted', label: 'Sub. Review', icon: Clock, count: submittedTasks.length, color: 'sky' },
    { id: 'accepted', label: 'Sub. Accepted', icon: CheckCircle2, count: acceptedHistory.length, color: 'success' },
    { id: 'rejected', label: 'Sub. Rejected', icon: XCircle, count: rejectedHistory.length, color: 'danger' },
  ];

  const colorMap = {
    warning: 'bg-warning text-white shadow-warning/30',
    sky: 'bg-sky-500 text-white shadow-sky-500/30',
    success: 'bg-success text-white shadow-success/30',
    danger: 'bg-danger text-white shadow-danger/30',
  };

  return (
    <div className="p-6 md:p-8 max-w-4xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">
      {/* Reading Form Modal */}
      {selectedTask && (
        <ReadingFormModal
          task={selectedTask}
          onClose={() => setSelectedTask(null)}
          onSuccess={handleSuccess}
        />
      )}

      {/* Success Banner */}
      {successBanner && (
        <div className="fixed top-6 left-1/2 -translate-x-1/2 z-50 bg-success/90 backdrop-blur-md text-white px-6 py-3 rounded-2xl shadow-xl flex items-center gap-3 animate-pulse-once border border-success/50">
          <CheckCircle2 size={20} />
          <span className="font-medium">Reading submitted! Awaiting admin review.</span>
        </div>
      )}

      {/* Header */}
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center gap-3">
          <div className="w-10 h-10 bg-primary/20 text-primary rounded-xl flex items-center justify-center">
            <ListTodo size={22} />
          </div>
          Agent Pending Tasks
        </h1>
        <p className="text-muted text-sm">
          All your pending duties in one place — Rent Collections, Subscriptions, and Daily Generator Readings.
        </p>
      </div>

      {/* Loading */}
      {isLoading && (
        <div className="flex-1 flex items-center justify-center">
          <div className="flex flex-col items-center gap-4">
            <div className="w-12 h-12 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
            <p className="text-slate-400">Loading your tasks...</p>
          </div>
        </div>
      )}

      {!isLoading && (
        <>
          {/* Tab Navigation */}
          <div className="flex gap-2 mb-6 flex-wrap shrink-0">
            {tabs.map(tab => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium text-sm transition-all ${
                    isActive
                      ? `${colorMap[tab.color]} shadow-lg`
                      : 'bg-slate-800/50 text-slate-400 hover:bg-slate-800 hover:text-white'
                  }`}
                >
                  <Icon size={15} />
                  {tab.label}
                  {tab.count > 0 && (
                    <span className={`text-xs px-2 py-0.5 rounded-full font-bold ${
                      isActive ? 'bg-white/20' : 'bg-slate-700 text-slate-300'
                    }`}>
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Content Grid */}
          <div className="flex-1 space-y-4">
            {activeTab === 'tasks' && (
              <>
                {allPendingTasks.length === 0 ? (
                  <div className="glass-card p-12 rounded-2xl text-center flex flex-col items-center">
                    <div className="w-16 h-16 bg-success/10 rounded-full flex items-center justify-center mb-4">
                      <CheckCircle2 size={32} className="text-success" />
                    </div>
                    <h3 className="text-xl font-bold text-white mb-2">All Clear!</h3>
                    <p className="text-slate-400 text-sm max-w-xs">
                      No tasks are due right now. You are completely caught up!
                    </p>
                  </div>
                ) : (
                  allPendingTasks.map(task => (
                    <TaskCard
                      key={task.id}
                      task={task}
                      onSelect={setSelectedTask}
                    />
                  ))
                )}
              </>
            )}

            {activeTab === 'submitted' && (
              <>
                {submittedTasks.length === 0 ? (
                  <div className="glass-card p-12 rounded-2xl text-center">
                    <Clock size={40} className="mx-auto mb-3 text-slate-500 opacity-50" />
                    <p className="text-slate-400">No readings currently under review.</p>
                  </div>
                ) : (
                  submittedTasks.map(item => (
                    <HistoryItem key={item.id} item={item} />
                  ))
                )}
              </>
            )}

            {activeTab === 'accepted' && (
              <>
                {acceptedHistory.length === 0 ? (
                  <div className="glass-card p-12 rounded-2xl text-center">
                    <CheckCircle2 size={40} className="mx-auto mb-3 text-slate-500 opacity-50" />
                    <p className="text-slate-400">No accepted readings yet.</p>
                  </div>
                ) : (
                  acceptedHistory.map(item => (
                    <HistoryItem key={item.id} item={item} />
                  ))
                )}
              </>
            )}

            {activeTab === 'rejected' && (
              <>
                {rejectedHistory.length === 0 ? (
                  <div className="glass-card p-12 rounded-2xl text-center">
                    <XCircle size={40} className="mx-auto mb-3 text-slate-500 opacity-50" />
                    <p className="text-slate-400">No rejected readings. Keep up the good work!</p>
                  </div>
                ) : (
                  rejectedHistory.map(item => (
                    <HistoryItem key={item.id} item={item} />
                  ))
                )}
              </>
            )}
          </div>
        </>
      )}
    </div>
  );
};

export default AgentSubscriptions;
