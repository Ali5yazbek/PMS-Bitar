import React, { useState, useEffect } from 'react';
import ReactMarkdown from 'react-markdown';
import { generatorApi } from '../../api/generatorApi';

function MetricCard({ label, value, sub, color = 'slate' }) {
    const colors = {
        blue:   'bg-blue-50 dark:bg-blue-900/20 border-blue-100 dark:border-blue-800 text-blue-600 dark:text-blue-400 text-blue-900 dark:text-blue-100',
        purple: 'bg-purple-50 dark:bg-purple-900/20 border-purple-100 dark:border-purple-800 text-purple-600 dark:text-purple-400 text-purple-900 dark:text-purple-100',
        green:  'bg-green-50 dark:bg-green-900/20 border-green-100 dark:border-green-800 text-green-600 dark:text-green-400 text-green-900 dark:text-green-100',
        red:    'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 text-red-900 dark:text-red-100',
        amber:  'bg-amber-50 dark:bg-amber-900/20 border-amber-200 dark:border-amber-800 text-amber-600 dark:text-amber-400 text-amber-900 dark:text-amber-100',
        slate:  'bg-gray-50 dark:bg-gray-800 border-gray-100 dark:border-gray-700 text-gray-500 dark:text-gray-400 text-gray-900 dark:text-white',
    };
    const parts = colors[color].split(' ');
    const bgBorder = parts.slice(0, 2).join(' ');
    const labelCls = parts.slice(2, 4).join(' ');
    const valueCls = parts.slice(4).join(' ');
    return (
        <div className={`p-4 rounded-xl border ${bgBorder} transition-all duration-500`}>
            <div className={`text-sm mb-1 ${labelCls}`}>{label}</div>
            <div className={`text-2xl font-bold ${valueCls}`}>{value}</div>
            {sub && <div className="text-xs text-gray-400 mt-0.5">{sub}</div>}
        </div>
    );
}

export default function AIAnalysisModal({ isOpen, onClose, analysisData, logId, onRefresh }) {
    const [currentData, setCurrentData]     = useState(analysisData);
    const [actualFuel, setActualFuel]       = useState('');
    const [updating, setUpdating]           = useState(false);
    const [updateSuccess, setUpdateSuccess] = useState(false);
    const [updateError, setUpdateError]     = useState('');

    // Sync when parent opens modal with fresh data
    useEffect(() => {
        setCurrentData(analysisData);
        if (analysisData?.metrics?.admin_actual_fuel !== undefined && analysisData.metrics.admin_actual_fuel !== null) {
            setActualFuel(analysisData.metrics.admin_actual_fuel.toString());
        } else {
            setActualFuel('');
        }
    }, [analysisData]);

    if (!isOpen || !currentData) return null;

    const { metrics, ai_report } = currentData;
    const hasVol    = metrics.vol_theft_alert === true;
    const hasActual = metrics.actual_fuel_spent !== null && metrics.actual_fuel_spent !== undefined;
    const hasLoss   = metrics.financial_loss_cfa > 0;

    const handleUpdateFuel = async (e) => {
        e.preventDefault();
        setUpdating(true);
        setUpdateSuccess(false);
        setUpdateError('');
        try {
            const result = await generatorApi.updateActualFuel(logId, parseFloat(actualFuel));
            // Real-time update: swap modal data with the fresh AI result
            if (result && result.metrics) {
                setCurrentData({ metrics: result.metrics, ai_report: result.ai_report, logId });
                if (result.metrics.admin_actual_fuel !== undefined && result.metrics.admin_actual_fuel !== null) {
                    setActualFuel(result.metrics.admin_actual_fuel.toString());
                }
            }
            setUpdateSuccess(true);
            setTimeout(() => setUpdateSuccess(false), 4000);
            if (onRefresh) onRefresh(logId);
        } catch (error) {
            console.error('Failed to update fuel', error);
            setUpdateError(error.message || 'Update failed. Please try again.');
        } finally {
            setUpdating(false);
        }
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60 backdrop-blur-md p-4">
            <div className="relative bg-white dark:bg-gray-900 rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">

                {/* Header */}
                <div className={`px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center text-white transition-all duration-500 ${hasVol ? 'bg-gradient-to-r from-red-700 to-red-900' : 'bg-gradient-to-r from-blue-600 to-indigo-700'}`}>
                    <h2 className="text-xl font-bold flex items-center gap-2">
                        {hasVol
                            ? <><span className="animate-pulse">🚨</span> VOL ALERT — Theft Anomaly Detected</>
                            : <><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M13 10V3L4 14h7v7l9-11h-7z" /></svg> AI Diagnostic Report</>
                        }
                    </h2>
                    <button onClick={onClose} className="text-white hover:text-gray-200">
                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                {/* Full-modal Re-analyzing overlay */}
                {updating && (
                    <div className="absolute inset-0 z-20 flex flex-col items-center justify-center bg-gray-900/80 backdrop-blur-sm rounded-2xl gap-5">
                        <div className="w-16 h-16 rounded-full border-4 border-indigo-400 border-t-transparent animate-spin" />
                        <p className="text-white text-xl font-bold animate-pulse">Re-analyzing with AI...</p>
                        <p className="text-gray-300 text-sm">Updating baseline & running VOL variance check</p>
                    </div>
                )}

                <div className="overflow-y-auto flex-1 p-6 space-y-6">

                    {/* VOL Banner */}
                    {hasVol && (
                        <div className="flex items-center gap-3 p-4 bg-red-100 dark:bg-red-900/30 border border-red-400 dark:border-red-700 rounded-xl">
                            <span className="text-3xl">🚨</span>
                            <div>
                                <div className="font-bold text-red-800 dark:text-red-200 text-lg">VOL — Fuel Theft / Anomaly Detected</div>
                                <div className="text-sm text-red-700 dark:text-red-300">Actual consumption exceeds factory rate by more than 5%. Immediate investigation required.</div>
                            </div>
                        </div>
                    )}

                    {/* Success banner after calibration */}
                    {updateSuccess && (
                        <div className="flex items-center gap-3 p-4 bg-green-100 dark:bg-green-900/30 border border-green-400 dark:border-green-700 rounded-xl">
                            <span className="text-2xl">✅</span>
                            <div className="font-semibold text-green-800 dark:text-green-200">
                                Baseline updated! The AI has recalculated all metrics with your new fuel reading.
                            </div>
                        </div>
                    )}

                    {/* Core Metrics Row */}
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                        <MetricCard label="Engine Run Time"         value={`${(metrics.hours_worked_today       ?? 0).toFixed(2)}h`} color="slate"  />
                        <MetricCard label="Factory Expected Burn"   value={`${(metrics.expected_fuel_burn_factory ?? 0).toFixed(2)} L`} color="blue" />
                        <MetricCard label="Estimated Tank Remaining" value={`${(metrics.predicted_remaining_fuel  ?? 0).toFixed(2)} L`} color="green" />
                        <MetricCard
                            label="ML Predicted Burn"
                            value={metrics.ml_predicted_fuel_burn !== null && metrics.ml_predicted_fuel_burn !== undefined
                                ? `${metrics.ml_predicted_fuel_burn.toFixed(2)} L`
                                : 'Insufficient Data'}
                            color="purple"
                        />
                    </div>

                    {/* Actuals Row — only if agent reported tank */}
                    {hasActual && (
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                            <MetricCard label="Actual Fuel Spent"    value={`${(metrics.actual_fuel_spent       ?? 0).toFixed(2)} L`}   color={hasVol ? 'red' : 'slate'} />
                            <MetricCard label="Actual Burn Rate"     value={`${(metrics.actual_consumption_rate ?? 0).toFixed(2)} L/h`} color={hasVol ? 'red' : 'slate'} />
                            <MetricCard
                                label="Missing Fuel Variance"
                                value={`${(metrics.missing_fuel_variance ?? 0).toFixed(2)} L`}
                                color={(metrics.missing_fuel_variance ?? 0) > 0 ? 'red' : 'green'}
                            />
                            <MetricCard
                                label="Financial Loss"
                                value={hasLoss ? `${(metrics.financial_loss_cfa ?? 0).toLocaleString()} CFA` : '0 CFA'}
                                sub={hasLoss ? 'Unaccounted fuel cost' : 'No loss detected'}
                                color={hasLoss ? 'red' : 'green'}
                            />
                        </div>
                    )}

                    {/* AI Narrative Report */}
                    <div className="bg-white dark:bg-gray-800 rounded-xl p-6 border border-gray-200 dark:border-gray-700 shadow-sm">
                        <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4 border-b pb-2">Analysis Details</h3>
                        <div className="prose dark:prose-invert max-w-none prose-blue text-sm">
                            <ReactMarkdown>{ai_report}</ReactMarkdown>
                        </div>
                    </div>

                    {/* Calibration & Override */}
                    <div className="bg-amber-50 dark:bg-amber-900/20 rounded-xl p-6 border border-amber-200 dark:border-amber-800">
                        <h3 className="text-lg font-semibold text-amber-900 dark:text-amber-100 mb-2">Calibration & Override</h3>
                        <p className="text-sm text-amber-700 dark:text-amber-300 mb-4">
                            If a physical inspection was performed, enter the actual fuel remaining to update the AI baseline and run a VOL variance check.
                        </p>
                        <form onSubmit={handleUpdateFuel} className="flex gap-3 items-end flex-wrap">
                            <div className="flex-1 min-w-[200px] max-w-xs">
                                <label className="block text-sm font-medium text-amber-900 dark:text-amber-200 mb-1">Actual Fuel Remaining (Liters)</label>
                                <input
                                    type="number" step="0.01" required
                                    value={actualFuel}
                                    onChange={e => setActualFuel(e.target.value)}
                                    className="w-full px-4 py-2 rounded-lg border border-amber-300 dark:border-amber-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-amber-500 outline-none transition-shadow"
                                    placeholder="e.g. 1050"
                                />
                            </div>
                            <button
                                type="submit"
                                disabled={updating || !actualFuel}
                                className="px-5 py-2 rounded-lg font-medium text-white bg-amber-600 hover:bg-amber-700 disabled:opacity-50 transition-colors shadow-md flex items-center gap-2"
                            >
                                {updating
                                    ? <><span className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin inline-block" /> Re-Analyzing...</>
                                    : '⚡ Update Baseline'
                                }
                            </button>
                        </form>
                        {updateError && <p className="mt-3 text-sm text-red-600 dark:text-red-400 font-medium">⚠ {updateError}</p>}
                    </div>

                </div>
            </div>
        </div>
    );
}
