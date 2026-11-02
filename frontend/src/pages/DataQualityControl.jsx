import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../api/axios';
import { 
  ShieldAlert, User, CheckCircle, AlertTriangle, AlertCircle, XCircle, 
  BarChart2, Search, Filter, Printer, Clock, FileText, ChevronRight 
} from 'lucide-react';

const DataQualityControl = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [selectedEmployee, setSelectedEmployee] = useState(null);
  const [showErrorModal, setShowErrorModal] = useState(false);
  const [selectedError, setSelectedError] = useState(null);
  const [toastMsg, setToastMsg] = useState(null);
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);

  // Queries
  const { data: employees = [], isLoading: loadingEmps } = useQuery({
    queryKey: ['quality_employees', selectedDate],
    queryFn: async () => {
      const res = await api.get(`/quality/employees?date=${selectedDate}`);
      return res.data;
    }
  });

  const { data: errors = [], isLoading: loadingErrors } = useQuery({
    queryKey: ['quality_errors', selectedEmployee?.employee_id, selectedDate],
    queryFn: async () => {
      const url = selectedEmployee 
        ? `/quality/errors?employee_id=${selectedEmployee.employee_id}&date=${selectedDate}`
        : `/quality/errors?date=${selectedDate}`;
      const res = await api.get(url);
      return res.data;
    },
    enabled: !!showErrorModal
  });

  const { data: activities = [], isLoading: loadingActivities } = useQuery({
    queryKey: ['quality_activities', selectedEmployee?.employee_id, selectedDate],
    queryFn: async () => {
      if (!selectedEmployee) return [];
      const res = await api.get(`/quality/activities?employee_id=${selectedEmployee.employee_id}&date=${selectedDate}`);
      return res.data;
    },
    enabled: !!showErrorModal && !!selectedEmployee
  });

  const { data: analytics } = useQuery({
    queryKey: ['quality_analytics', selectedDate],
    queryFn: async () => {
      const res = await api.get(`/quality/analytics?date=${selectedDate}`);
      return res.data;
    }
  });

  const { data: history = [] } = useQuery({
    queryKey: ['quality_error_history', selectedError?.id],
    queryFn: async () => {
      const res = await api.get(`/quality/errors/${selectedError.id}/history`);
      return res.data;
    },
    enabled: !!selectedError
  });

  const scanMutation = useMutation({
    mutationFn: () => api.post('/quality/scan'),
    onSuccess: () => {
      setToastMsg({ message: 'System Scan Completed', type: 'success' });
      setTimeout(() => setToastMsg(null), 3000);
      queryClient.invalidateQueries(['quality_employees']);
      queryClient.invalidateQueries(['quality_analytics']);
    }
  });

  const actionMutation = useMutation({
    mutationFn: ({ id, action, comment }) => api.post(`/quality/errors/${id}/action`, { action, comment }),
    onSuccess: () => {
      setToastMsg({ message: 'Action applied', type: 'success' });
      setTimeout(() => setToastMsg(null), 3000);
      queryClient.invalidateQueries(['quality_errors']);
      queryClient.invalidateQueries(['quality_error_history']);
      setSelectedError(null);
    }
  });

  const fixMutation = useMutation({
    mutationFn: ({ id, new_value, comment, file }) => {
      if (file) {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('comment', comment);
        formData.append('apply_to_record', true);
        return api.post(`/quality/errors/${id}/fix`, formData, { headers: { 'Content-Type': 'multipart/form-data' } });
      }
      return api.post(`/quality/errors/${id}/fix`, { new_value, comment, apply_to_record: true });
    },
    onSuccess: () => {
      setToastMsg({ message: 'Fix submitted', type: 'success' });
      setTimeout(() => setToastMsg(null), 3000);
      queryClient.invalidateQueries(['quality_errors']);
      queryClient.invalidateQueries(['quality_error_history']);
      setSelectedError(null);
    }
  });

  // Print Employee Report
  // Print Employee Report
  const handlePrint = async (emp) => {
    try {
      setToastMsg({ message: 'Generating report...', type: 'success' });
      const res = await api.get(`/quality/errors?employee_id=${emp.employee_id}&date=${selectedDate}`);
      const empErrors = res.data;
      
      const printWindow = window.open('', '_blank');
      printWindow.document.write(`
        <html>
          <head>
            <title>Data Quality Report - ${emp.name}</title>
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px; color: #333; }
              table { width: 100%; border-collapse: collapse; font-size: 14px; }
              th, td { border: 1px solid #e2e8f0; padding: 12px; text-align: left; }
              th { background-color: #f8fafc; color: #475569; font-weight: 600; text-transform: uppercase; font-size: 12px; }
              tr:nth-child(even) { background-color: #f8fafc; }
              .header { text-align: center; margin-bottom: 40px; padding-bottom: 20px; border-bottom: 2px solid #e2e8f0; }
              .company-name { font-size: 28px; font-weight: bold; color: #1e293b; margin-bottom: 8px; text-transform: uppercase; letter-spacing: 1px; }
              .report-title { font-size: 18px; color: #64748b; }
              .emp-info { display: flex; justify-content: space-between; margin-bottom: 30px; background: #f8fafc; padding: 20px; border-radius: 8px; border: 1px solid #e2e8f0; }
              .emp-info div { line-height: 1.6; }
              .severity-critical { color: #dc2626; font-weight: 600; text-transform: capitalize; }
              .severity-high { color: #ea580c; font-weight: 600; text-transform: capitalize; }
              .severity-medium { color: #ca8a04; font-weight: 600; text-transform: capitalize; }
              .severity-low { color: #16a34a; font-weight: 600; text-transform: capitalize; }
              
              .record-block { margin-bottom: 40px; page-break-inside: avoid; border: 1px solid #e2e8f0; border-radius: 8px; overflow: hidden; }
              .record-header { background-color: #f8fafc; padding: 15px; border-bottom: 1px solid #e2e8f0; }
              .record-header h3 { margin: 0 0 8px 0; color: #1e293b; font-size: 16px; }
              .record-header .meta { font-size: 14px; color: #475569; }
              .record-block table { margin-top: 0; border: none; }
              .record-block th { border-top: none; }
              .record-block th:first-child, .record-block td:first-child { border-left: none; }
              .record-block th:last-child, .record-block td:last-child { border-right: none; }
              .record-block tr:last-child td { border-bottom: none; }
              
              @media print {
                @page { size: landscape; margin: 1cm; }
                body { padding: 0; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
                .no-print { display: none; }
              }
            </style>
          </head>
          <body>
            <div class="header">
              <div class="company-name">BITAR</div>
              <div class="report-title">Employee Data Quality Audit Report</div>
            </div>
            
            <div class="emp-info">
              <div>
                <strong>Employee Name:</strong> ${emp.name} <br/>
                <strong>Role:</strong> <span style="text-transform: capitalize;">${emp.role}</span> <br/>
                <strong>Department:</strong> ${emp.department}
              </div>
              <div style="text-align: right;">
                <strong>Audit Date:</strong> ${selectedDate} <br/>
                <strong>Accuracy Score:</strong> ${emp.accuracy}% <br/>
                <strong>Total Issues:</strong> ${emp.total_errors}
              </div>
            </div>
            
            <div class="records-container">
              ${empErrors.length > 0 ? empErrors.map(err => {
                let headers = '';
                let rowData = '';
                if (err.full_record_json) {
                  try {
                    const record = JSON.parse(err.full_record_json);
                    const entries = Object.entries(record).filter(([k]) => k !== 'id' && k !== 'created_at' && k !== 'updated_at');
                    
                    headers = entries.map(([k]) => {
                      const isTarget = k === err.field_name;
                      return `<th style="text-transform: capitalize; ${isTarget ? 'color: #dc2626; border-bottom: 2px solid #dc2626;' : ''}">${k.replace(/_/g, ' ')}</th>`;
                    }).join('');
                    
                    rowData = entries.map(([k, v]) => {
                      const isMissing = v === null || v === '';
                      const isTarget = k === err.field_name;
                      const tdStyle = isTarget ? 'background-color: #fee2e2; font-weight: bold; color: #dc2626;' : (isMissing ? 'color: #ef4444; font-style: italic; font-weight: 500;' : '');
                      const valDisplay = isMissing ? 'Missing' : String(v);
                      return `<td style="${tdStyle}">${valDisplay}</td>`;
                    }).join('');
                  } catch (e) {
                    headers = '<th>Error</th>';
                    rowData = '<td>Failed to parse record data</td>';
                  }
                }

                return `
                  <div class="record-block">
                    <div class="record-header">
                      <h3>Module: ${err.module_name} <span style="color: #4f46e5; margin-left: 8px;">#${err.record_id}</span></h3>
                      <div class="meta">
                        <strong>Issue:</strong> ${err.problem_type} - <span style="color: #dc2626; font-weight: 600;">${err.field_name}</span>
                        <span style="margin-left: 20px;"><strong>Severity:</strong> <span class="severity-${err.severity.toLowerCase()}">${err.severity}</span></span>
                        <span style="margin-left: 20px;"><strong>Status:</strong> ${err.status}</span>
                      </div>
                    </div>
                    <div style="overflow-x: auto; padding-bottom: 10px;">
                      <table style="font-size: 11px; white-space: nowrap;">
                        <thead>
                          <tr>
                            ${headers}
                          </tr>
                        </thead>
                        <tbody>
                          <tr>
                            ${rowData}
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                `;
              }).join('') : '<div style="text-align:center; padding: 40px; color: #64748b; border: 1px dashed #cbd5e1; border-radius: 8px; background: #f8fafc;">No data quality issues found for this date.</div>'}
            </div>
            
            <div style="margin-top: 50px; text-align: center; font-size: 12px; color: #94a3b8;">
              Generated by BITAR Enterprise System on ${new Date().toLocaleString()}
            </div>
          </body>
        </html>
      `);
      printWindow.document.close();
      printWindow.focus();
      
      setTimeout(() => {
        setToastMsg(null);
        printWindow.print();
        printWindow.close();
      }, 500);
      
    } catch (error) {
      console.error("Error generating print report", error);
      setToastMsg({ message: 'Failed to generate print report', type: 'error' });
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      <div className="flex justify-between items-center bg-white p-4 rounded-xl shadow-sm border border-gray-100">
        <div>
          <h1 className="text-2xl font-bold text-gray-800 flex items-center gap-2">
            <ShieldAlert className="w-8 h-8 text-indigo-600" />
            Enterprise Data Quality Control
          </h1>
          <p className="text-gray-500 mt-1">Audit and validate records across all modules</p>
        </div>
        <div className="flex gap-3">
          <input 
            type="date" 
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="px-4 py-2 border border-gray-200 rounded-lg text-gray-700 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
          <button 
            onClick={() => scanMutation.mutate()}
            disabled={scanMutation.isLoading}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 flex items-center gap-2 disabled:opacity-50"
          >
            <Search className="w-4 h-4" />
            {scanMutation.isLoading ? 'Scanning...' : 'Run Audit Now'}
          </button>
        </div>
      </div>

      {/* Analytics Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-gray-500 text-sm font-medium">Total Issues Found</h3>
          <p className="text-3xl font-bold text-gray-800 mt-2">{analytics?.total_errors || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-gray-500 text-sm font-medium">Open Issues</h3>
          <p className="text-3xl font-bold text-red-600 mt-2">{analytics?.open_errors || 0}</p>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100">
          <h3 className="text-gray-500 text-sm font-medium">Resolved Issues</h3>
          <p className="text-3xl font-bold text-green-600 mt-2">{analytics?.resolved_errors || 0}</p>
        </div>
      </div>

      {/* Employee Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {employees.map(emp => (
          <div key={emp.employee_id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow">
            <div className="p-6">
              <div className="flex items-center gap-4 mb-4">
                <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-full flex items-center justify-center">
                  <User className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="font-bold text-lg text-gray-800">{emp.name}</h3>
                  <p className="text-sm text-gray-500 capitalize">{emp.role} • {emp.department}</p>
                </div>
              </div>

              <div className="space-y-4">
                {emp.open_errors > 0 ? (
                  <div className="flex items-center gap-2 text-red-600 bg-red-50 p-2 rounded-lg">
                    <AlertTriangle className="w-5 h-5" />
                    <span className="font-medium">{emp.open_errors} Open Data Errors</span>
                  </div>
                ) : (
                  <div className="flex items-center gap-2 text-green-600 bg-green-50 p-2 rounded-lg">
                    <CheckCircle className="w-5 h-5" />
                    <span className="font-medium">No Errors Found</span>
                  </div>
                )}

                <div className="bg-gray-50 p-3 rounded-lg">
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Data Accuracy Score</span>
                    <span className="font-bold text-gray-800">{emp.accuracy}%</span>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2 mb-2">
                    <div 
                      className={`h-2 rounded-full ${emp.accuracy >= 95 ? 'bg-green-500' : emp.accuracy >= 80 ? 'bg-yellow-500' : 'bg-red-500'}`} 
                      style={{ width: `${emp.accuracy}%` }}
                    ></div>
                  </div>
                  <p className="text-xs text-gray-500 text-center">
                    {emp.total_submitted} Submitted • {emp.correct_records} Correct • {emp.total_errors} Issues
                  </p>
                </div>

                <div className="text-xs text-gray-400 flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  Last Submission: {emp.last_submission || 'N/A'}
                </div>
              </div>
            </div>
            
            <div className="border-t border-gray-100 bg-gray-50 p-4 flex gap-2">
              <button 
                onClick={() => {
                  setSelectedEmployee(emp);
                  setShowErrorModal(true);
                }}
                className="flex-1 bg-white border border-gray-200 text-gray-700 py-2 rounded-lg text-sm font-medium hover:bg-gray-100 transition-colors"
              >
                View Errors
              </button>
              <button 
                onClick={() => handlePrint(emp)}
                className="px-3 bg-white border border-gray-200 text-gray-700 rounded-lg hover:bg-gray-100 transition-colors"
                title="Print Report"
              >
                <Printer className="w-4 h-4" />
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Errors Modal */}
      {showErrorModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
          <div className="bg-white rounded-2xl w-full max-w-6xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
              <div>
                <h2 className="text-2xl font-bold text-gray-800">
                  {selectedEmployee ? `Audit Report: ${selectedEmployee.name}` : 'All Audit Reports'}
                </h2>
                {selectedEmployee && (
                  <p className="text-sm text-gray-500 mt-1">Role: {selectedEmployee.role} • Dept: {selectedEmployee.department}</p>
                )}
              </div>
              <button onClick={() => { setShowErrorModal(false); setSelectedEmployee(null); }} className="text-gray-400 hover:text-gray-600">
                <XCircle className="w-8 h-8" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-6">
              {loadingErrors ? (
                <div className="flex justify-center p-12"><div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div></div>
              ) : (
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-gray-50 text-gray-500 text-sm border-b border-gray-200">
                      <th className="p-3 font-medium">Module</th>
                      <th className="p-3 font-medium">Record ID</th>
                      <th className="p-3 font-medium">Missing Field</th>
                      <th className="p-3 font-medium">Problem</th>
                      <th className="p-3 font-medium">Severity</th>
                      <th className="p-3 font-medium">Status</th>
                      <th className="p-3 font-medium">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-100 text-sm">
                    {errors.map(err => (
                      <tr key={err.id} className="hover:bg-gray-50">
                        <td className="p-3 font-medium text-gray-800">{err.module_name}</td>
                        <td className="p-3 text-indigo-600">#{err.record_id}</td>
                        <td className="p-3">{err.field_name}</td>
                        <td className="p-3">
                          <span className="bg-red-50 text-red-700 px-2 py-1 rounded-md text-xs font-medium">
                            {err.problem_type}
                          </span>
                        </td>
                        <td className="p-3 capitalize">{err.severity}</td>
                        <td className="p-3">
                           <span className={`px-2 py-1 rounded-md text-xs font-medium ${
                            err.status === 'Resolved' ? 'bg-green-100 text-green-700' : 
                            err.status === 'Pending Review' ? 'bg-yellow-100 text-yellow-700' : 'bg-red-100 text-red-700'
                           }`}>
                            {err.status}
                          </span>
                        </td>
                        <td className="p-3">
                          <button 
                            onClick={() => setSelectedError(err)}
                            className="text-indigo-600 hover:text-indigo-800 font-medium text-sm flex items-center gap-1"
                          >
                            Details <ChevronRight className="w-4 h-4" />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {errors.length === 0 && (
                      <tr><td colSpan="7" className="text-center p-8 text-gray-500">No errors found.</td></tr>
                    )}
                  </tbody>
                </table>
              )}
            </div>

            {/* Activities Section */}
            <div className="mt-8">
              <h4 className="text-lg font-bold text-gray-800 mb-4 flex items-center gap-2">
                <CheckCircle className="w-5 h-5 text-green-500" />
                Completed Activities
              </h4>
              <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
                {loadingActivities ? (
                  <div className="p-8 text-center text-gray-500">Loading activities...</div>
                ) : activities.length === 0 ? (
                  <div className="p-8 text-center text-gray-500">No activities found for this date.</div>
                ) : (
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="bg-gray-50 text-gray-500 text-sm border-b border-gray-200">
                        <th className="p-3 font-medium">Time</th>
                        <th className="p-3 font-medium">Action</th>
                        <th className="p-3 font-medium">Module</th>
                        <th className="p-3 font-medium">Details</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-gray-100 text-sm">
                      {activities.map(act => (
                        <tr key={act.id} className="hover:bg-gray-50">
                          <td className="p-3 text-gray-500 whitespace-nowrap">
                            {new Date(act.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </td>
                          <td className="p-3 font-medium text-green-600">{act.action}</td>
                          <td className="p-3 text-gray-500">{act.entity_type}</td>
                          <td className="p-3 text-gray-600">{act.details}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                )}
              </div>
            </div>

          </div>
        </div>
      )}

      {/* Error Details Sidebar / Modal */}
      {selectedError && (
        <div className="fixed inset-y-0 right-0 z-[60] w-full max-w-md bg-white shadow-2xl flex flex-col border-l border-gray-200 transform transition-transform duration-300">
          <div className="p-6 border-b border-gray-100 flex justify-between items-center bg-gray-50">
            <h3 className="text-xl font-bold text-gray-800">Error Details</h3>
            <button onClick={() => setSelectedError(null)} className="text-gray-400 hover:text-gray-600">
              <XCircle className="w-6 h-6" />
            </button>
          </div>
          
          <div className="flex-1 overflow-y-auto p-6 space-y-6">
            <div className="bg-red-50 text-red-800 p-4 rounded-xl border border-red-100">
              <h4 className="font-bold flex items-center gap-2"><AlertCircle className="w-5 h-5"/> {selectedError.problem_type}</h4>
              <p className="text-sm mt-1">{selectedError.description}</p>
            </div>

            <div className="grid grid-cols-2 gap-4 text-sm">
              <div className="bg-gray-50 p-3 rounded-lg border border-gray-100">
                <span className="text-gray-500 block text-xs">Module</span>
                <span className="font-medium text-gray-800">{selectedError.module_name}</span>
              </div>
              <div className="bg-gray-50 p-3 rounded-lg border border-gray-100">
                <span className="text-gray-500 block text-xs">Record ID</span>
                <span className="font-medium text-indigo-600">#{selectedError.record_id}</span>
              </div>
            </div>

            {/* Whole Record View */}
            <div>
              <h4 className="font-bold text-gray-800 mb-3">Record Completion</h4>
              <div className="border border-gray-200 rounded-xl overflow-hidden">
                <table className="w-full text-left text-sm">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="p-2 border-b">Field</th>
                      <th className="p-2 border-b">Value</th>
                      <th className="p-2 border-b">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedError.full_record_json && Object.entries(JSON.parse(selectedError.full_record_json)).map(([k, v]) => {
                      // Skip internal IDs
                      if(k === 'id' || k === 'created_at' || k === 'updated_at') return null;
                      const isMissing = v === null || v === '';
                      const isTarget = k === selectedError.field_name;
                      return (
                        <tr key={k} className={`border-b last:border-0 ${isTarget ? 'bg-red-50' : ''}`}>
                          <td className="p-2 font-medium capitalize text-gray-600">{k.replace(/_/g, ' ')}</td>
                          <td className={`p-2 ${isMissing ? 'text-gray-400 italic' : 'text-gray-800'}`}>
                            {isMissing ? '(Empty)' : String(v)}
                          </td>
                          <td className="p-2 text-center">
                            {isMissing ? <XCircle className="w-4 h-4 text-red-500 mx-auto"/> : <CheckCircle className="w-4 h-4 text-green-500 mx-auto"/>}
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </div>

            {/* History Trail */}
            <div>
               <h4 className="font-bold text-gray-800 mb-3">Fix History</h4>
               <div className="space-y-4 relative before:absolute before:inset-0 before:ml-5 before:-translate-x-px md:before:mx-auto md:before:translate-x-0 before:h-full before:w-0.5 before:bg-gradient-to-b before:from-transparent before:via-slate-300 before:to-transparent">
                  {history.map((item, idx) => (
                    <div key={idx} className="relative flex items-center justify-between md:justify-normal md:odd:flex-row-reverse group is-active">
                        <div className="flex items-center justify-center w-10 h-10 rounded-full border border-white bg-slate-300 text-slate-500 shadow shrink-0 md:order-1 md:group-odd:-translate-x-1/2 md:group-even:translate-x-1/2">
                            <User className="w-4 h-4" />
                        </div>
                        <div className="w-[calc(100%-4rem)] md:w-[calc(50%-2.5rem)] bg-white p-3 rounded shadow-sm border border-slate-200">
                            <div className="flex items-center justify-between space-x-2 mb-1">
                                <div className="font-bold text-slate-900 text-xs">{item.action}</div>
                                <time className="font-caveat font-medium text-indigo-500 text-xs">{new Date(item.created_at).toLocaleString()}</time>
                            </div>
                            <div className="text-slate-500 text-xs">{item.user_name}: {item.comment}</div>
                        </div>
                    </div>
                  ))}
                  {history.length === 0 && <p className="text-sm text-gray-500 italic pl-12">No actions recorded yet.</p>}
               </div>
            </div>

          </div>
          
          <div className="p-6 border-t border-gray-100 bg-gray-50">
             {selectedError.status === 'Open' || selectedError.status === 'Rejected' ? (
               <form onSubmit={(e) => {
                 e.preventDefault();
                 const isFileField = selectedError.field_name?.endsWith('_url') || selectedError.field_name?.endsWith('_file');
                 const file = isFileField ? e.target.file?.files[0] : null;
                 const new_value = !isFileField ? e.target.new_value?.value : '';
                 
                 fixMutation.mutate({
                   id: selectedError.id,
                   new_value: new_value,
                   comment: e.target.comment.value,
                   file: file
                 });
               }} className="space-y-3">
                  {selectedError.field_name?.endsWith('_url') || selectedError.field_name?.endsWith('_file') ? (
                    <input type="file" name="file" className="w-full p-2 border border-gray-300 rounded text-sm bg-white" required />
                  ) : (
                    <input type="text" name="new_value" placeholder="Enter missing value..." className="w-full p-2 border border-gray-300 rounded text-sm" required />
                  )}
                  <input name="comment" placeholder="Add note..." className="w-full p-2 border border-gray-300 rounded text-sm" />
                  <button type="submit" disabled={fixMutation.isLoading} className="w-full bg-indigo-600 text-white py-2 rounded font-medium hover:bg-indigo-700 disabled:opacity-50 text-sm">
                    Submit Fix
                  </button>
               </form>
             ) : selectedError.status === 'Pending Review' ? (
               <div className="flex gap-2">
                 <button onClick={() => actionMutation.mutate({id: selectedError.id, action: 'approve', comment: 'Approved'})} className="flex-1 bg-green-600 text-white py-2 rounded font-medium hover:bg-green-700 text-sm">Approve</button>
                 <button onClick={() => actionMutation.mutate({id: selectedError.id, action: 'reject', comment: 'Rejected'})} className="flex-1 bg-red-600 text-white py-2 rounded font-medium hover:bg-red-700 text-sm">Reject</button>
               </div>
             ) : (
                <div className="text-center text-green-600 font-medium p-2 bg-green-50 rounded-lg">
                  This issue is Resolved.
                </div>
             )}
          </div>
        </div>
      )}

      {/* Toast Notification */}
      {toastMsg && (
        <div className={`fixed bottom-4 right-4 text-white px-6 py-3 rounded-lg shadow-2xl z-50 animate-bounce ${toastMsg.type === 'error' ? 'bg-danger' : 'bg-emerald-600'}`}>
          {toastMsg.message}
        </div>
      )}

    </div>
  );
};

export default DataQualityControl;
