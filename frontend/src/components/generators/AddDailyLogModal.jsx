import React, { useState } from 'react';
import { generatorApi } from '../../api/generatorApi';

const INPUT_MODES = [
    { value: 'meter', label: '📟 Meter Reading', desc: 'Enter the cumulative total on the hour meter.' },
    { value: 'hours', label: '⏱ Hours Worked Today', desc: 'Enter how many hours the generator ran today.' },
    { value: 'both',  label: '✅ Both (Cross-Check)', desc: 'Enter both for automatic verification.' },
];

export default function AddDailyLogModal({ isOpen, onClose, onSuccess, generatorId: propGeneratorId }) {
    const [mode, setMode] = useState('meter');
    const [meterReading, setMeterReading] = useState('');
    const [manualHours, setManualHours] = useState('');
    const generatorId = propGeneratorId || 1;
    const [loading, setLoading] = useState(false);
    const [error,   setError]   = useState(null);
    const [result,  setResult]  = useState(null);

    if (!isOpen) return null;

    const canSubmit = () => {
        if (mode === 'meter') return meterReading !== '';
        if (mode === 'hours') return manualHours !== '';
        if (mode === 'both')  return meterReading !== '' && manualHours !== '';
        return false;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!canSubmit()) return;
        setLoading(true);
        setError(null);
        setResult(null);

        const date = new Date().toISOString().split('T')[0];
        let payload = {};
        
        if (mode === 'meter') {
            payload = { submitted_hours: parseFloat(meterReading) };
        } else if (mode === 'hours') {
            payload = { manual_hours: parseFloat(manualHours) };
        } else {
            payload = {
                submitted_hours: parseFloat(meterReading),
                manual_hours: parseFloat(manualHours),
            };
        }

        try {
            const res = await generatorApi.addDailyLog(generatorId, payload, date);
            setResult(res);
            setTimeout(() => {
                onSuccess?.();
                onClose();
                setMeterReading('');
                setManualHours('');
                setResult(null);
            }, 2000);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60 backdrop-blur-sm">
            <div className="bg-gray-900 rounded-2xl shadow-2xl w-full max-w-lg overflow-hidden border border-slate-700">

                {/* Header */}
                <div className="px-6 py-4 bg-gradient-to-r from-blue-700 to-indigo-800 flex justify-between items-center">
                    <h2 className="text-xl font-bold text-white flex items-center gap-2">
                        📟 Add Daily Generator Log
                    </h2>
                    <button onClick={onClose} className="text-white/70 hover:text-white transition-colors">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" />
                        </svg>
                    </button>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-5">
                    
                    {/* Input Mode Selector */}
                    <div>
                        <label className="block text-sm font-semibold text-slate-300 mb-3">Logging Method</label>
                        <div className="grid grid-cols-3 gap-2">
                            {INPUT_MODES.map(m => (
                                <button
                                    key={m.value}
                                    type="button"
                                    onClick={() => setMode(m.value)}
                                    className={`p-3 rounded-xl text-xs font-medium border transition-all text-left ${
                                        mode === m.value
                                            ? 'border-blue-500 bg-blue-500/20 text-blue-300'
                                            : 'border-slate-700 bg-slate-800 text-slate-400 hover:border-slate-500'
                                    }`}
                                >
                                    <div className="text-sm mb-1">{m.label}</div>
                                    <div className="text-slate-500 text-[10px] leading-tight">{m.desc}</div>
                                </button>
                            ))}
                        </div>
                    </div>

                    {/* Meter Reading Field */}
                    {(mode === 'meter' || mode === 'both') && (
                        <div>
                            <label className="block text-sm font-semibold text-slate-200 mb-3">
                                Current Meter Reading <span className="text-slate-500 font-normal">(cumulative total on gauge)</span>
                            </label>
                            <input
                                type="number" step="0.01" required={mode !== 'both' || meterReading !== ''}
                                autoFocus={mode === 'meter'}
                                className="w-full px-4 py-4 rounded-xl border border-slate-600 bg-slate-800 text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-shadow text-2xl font-mono"
                                placeholder="e.g. 1560.5"
                                value={meterReading}
                                onChange={e => setMeterReading(e.target.value)}
                            />
                        </div>
                    )}

                    {/* Manual Hours Field */}
                    {(mode === 'hours' || mode === 'both') && (
                        <div>
                            <label className="block text-sm font-semibold text-slate-200 mb-2">
                                Hours Worked Today <span className="text-slate-500 font-normal">(today only, not cumulative)</span>
                            </label>
                            <input
                                type="number" step="0.01" min="0" required={mode !== 'both' || manualHours !== ''}
                                className={`w-full px-4 py-4 rounded-xl border ${
                                    parseFloat(manualHours) > 24
                                        ? 'border-amber-500 bg-amber-900/10'
                                        : 'border-slate-600 bg-slate-800'
                                } text-white focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-shadow text-lg`}
                                placeholder="e.g. 10.5"
                                value={manualHours}
                                onChange={e => setManualHours(e.target.value)}
                            />
                            
                            {/* Smart hint */}
                            {parseFloat(manualHours) > 24 && (
                                <div className="mt-2 p-3 bg-amber-900/30 border border-amber-600 rounded-xl flex items-start gap-2">
                                    <span className="text-amber-400 text-lg mt-0.5">💡</span>
                                    <div>
                                        <div className="text-amber-300 font-semibold text-sm">Looks like a meter reading!</div>
                                        <div className="text-amber-400/80 text-xs mt-0.5">
                                            A generator can't run more than 24h in one day. If <strong>{manualHours}</strong> is the
                                            total shown on the generator gauge, switch to
                                            <button
                                                type="button"
                                                onClick={() => { setMeterReading(manualHours); setManualHours(''); setMode('meter'); }}
                                                className="ml-1 underline text-amber-300 font-bold hover:text-white"
                                            >
                                                📟 Meter Reading mode
                                            </button>
                                        </div>
                                    </div>
                                </div>
                            )}
                            {mode === 'both' && parseFloat(manualHours) <= 24 && (
                                <p className="mt-2 text-xs text-amber-400">
                                    ⚠️ If meter delta doesn't match hours worked (±0.5h), the system will flag a Data Entry Mismatch.
                                </p>
                            )}
                        </div>
                    )}

                    {/* Error */}
                    {error && (
                        <div className="p-3 bg-red-900/40 border border-red-700 text-red-300 rounded-xl text-sm">
                            ❌ {error}
                        </div>
                    )}

                    {/* Success */}
                    {result && (
                        <div className="p-3 bg-green-900/40 border border-green-700 text-green-300 rounded-xl text-sm">
                            ✅ Log submitted! Method: <strong>{result.input_method}</strong> — Hours worked: <strong>{Number(result.hours_worked).toFixed(2)}h</strong>
                            {result.mismatch && <span className="ml-2 text-amber-400 font-bold">⚠️ Mismatch flagged</span>}
                        </div>
                    )}

                    {/* Actions */}
                    <div className="flex justify-end gap-3 pt-2">
                        <button
                            type="button" onClick={onClose}
                            className="px-5 py-2.5 rounded-xl text-sm font-medium text-slate-300 bg-slate-800 border border-slate-700 hover:bg-slate-700 transition-colors"
                        >
                            Cancel
                        </button>
                        <button
                            type="submit"
                            disabled={loading || !canSubmit()}
                            className="px-6 py-2.5 rounded-xl text-sm font-bold text-white bg-blue-600 hover:bg-blue-500 disabled:opacity-40 disabled:cursor-not-allowed transition-colors shadow-lg shadow-blue-500/30"
                        >
                            {loading ? 'Submitting...' : 'Submit Log'}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
}
