import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { generatorApi } from '../../api/generatorApi';

const AiLogsTableBody = ({ generatorId, date, onAnalyze, onViewAnalysis, onVerifySuccess }) => {
  const [analyzingId, setAnalyzingId] = useState(null);

  const { data: logs = [], refetch } = useQuery({
    queryKey: ['monthLogs', generatorId, date],
    queryFn: async () => {
      if (!generatorId) return [];
      try {
        const data = await generatorApi.getMonthLogs(generatorId, date);
        if (data.status === 'success') {
          return data.data;
        }
        return [];
      } catch (err) {
        console.error(err);
        return [];
      }
    },
    enabled: !!generatorId,
    refetchInterval: 5000
  });

  if (logs.length === 0) {
    const monthName = new Date(date).toLocaleString('default', { month: 'long', year: 'numeric' });
    return <tr><td colSpan="7" className="py-4 text-center text-muted">No AI daily logs found for {monthName}.</td></tr>;
  }

  const handleAnalyzeClick = async (id) => {
    setAnalyzingId(id);
    try {
      await onAnalyze(id);
    } finally {
      setAnalyzingId(null);
    }
  };

  const handleVerifyClick = async (id) => {
    try {
      const data = await generatorApi.verifyLog(id);
      if (data.status === 'success') {
        await refetch();
        if (onVerifySuccess) onVerifySuccess();
      }
    } catch (err) {
      console.error("Failed to verify log", err);
    }
  };

  return (
    <>
      {logs.map(log => (
        <tr key={log.id} className="border-b border-slate-800/50 hover:bg-slate-800/20 transition-colors">
          <td className="py-4 text-white text-sm whitespace-nowrap">{log.date}</td>
          <td className="py-4 text-white text-sm">{log.submitted_hours}</td>
          <td className="py-4 text-white text-sm">{log.calculated_hours_worked}h</td>
          <td className="py-4 text-muted text-sm">{log.expected_factory_fuel_burn} L</td>
          <td className="py-4 text-indigo-300 font-bold text-sm">
            {log.predicted_fuel_remaining !== null ? `${log.predicted_fuel_remaining} L` : '-'}
          </td>
          <td className="py-4 text-sky-300 font-bold text-sm">
            {log.admin_actual_fuel !== null && log.admin_actual_fuel !== undefined ? `${log.admin_actual_fuel} L` : '-'}
          </td>
          <td className="py-4">
            <span className={`px-2 py-1 rounded text-xs font-bold ${
              log.status_flag === 'Verified' ? 'bg-success/20 text-success' : 
              log.status_flag === 'Normal' ? 'bg-blue-500/20 text-blue-400' : 
              log.status_flag === 'Anomaly Detected' ? 'bg-danger/20 text-danger' : 
              'bg-warning/20 text-warning'
            }`}>
              {log.status_flag || 'Pending'}
            </span>
          </td>
          <td className="py-4 flex gap-2">
            {log.status_flag !== 'Verified' && (
              <button 
                onClick={() => handleVerifyClick(log.id)} 
                className="bg-success/20 hover:bg-success/40 text-success border border-success/30 font-bold py-1 px-3 rounded shadow-lg text-sm flex items-center gap-1 transition-all"
              >
                ✅ Accept
              </button>
            )}
            {(!log.status_flag || log.status_flag === 'Pending Analysis' || log.status_flag === 'Data Entry Mismatch' || log.status_flag === 'Pending') ? (
              <button 
                onClick={() => handleAnalyzeClick(log.id)} 
                disabled={analyzingId === log.id}
                className={`bg-gradient-to-r from-blue-500 to-indigo-600 hover:from-blue-600 hover:to-indigo-700 text-white font-bold py-1 px-3 rounded shadow-lg text-sm flex items-center gap-1 transition-all ${analyzingId === log.id ? 'opacity-50 cursor-wait' : ''}`}
              >
                {analyzingId === log.id ? (
                  <>
                    <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    Analyzing...
                  </>
                ) : (
                  <>
                    <span className="text-lg">📊</span> AI Analysis
                  </>
                )}
              </button>
            ) : (
              <button 
                onClick={() => onViewAnalysis && onViewAnalysis(log)} 
                className="bg-gradient-to-r from-purple-500 to-indigo-600 hover:from-purple-600 hover:to-indigo-700 text-white font-bold py-1 px-3 rounded shadow-lg text-sm flex items-center gap-1 transition-all"
              >
                <span className="text-lg">👁</span> View Analysis
              </button>
            )}
          </td>
        </tr>
      ))}
    </>
  );
};

export default AiLogsTableBody;
