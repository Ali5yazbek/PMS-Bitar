import React, { useState } from 'react';
import axios from 'axios';
import { useQuery } from '@tanstack/react-query';
import { Camera, Search, AlertCircle, FileText, CheckCircle2, Building, Eye, Clock } from 'lucide-react';

const DailyReportsDashboard = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedReport, setSelectedReport] = useState(null);

  const formatDate = (dateString) => {
    const options = { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' };
    return new Date(dateString).toLocaleDateString('en-US', options);
  };
  
  const formatTime = (dateString) => {
    return new Date(dateString).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' });
  };

  const { data, isLoading } = useQuery({
    queryKey: ['daily_reports_dashboard'],
    queryFn: async () => {
      const res = await axios.get('/daily-reports/dashboard');
      return res.data;
    },
    refetchInterval: 60000 // Refetch every minute to check missing reports
  });

  const reports = data?.reports || [];
  const missingAgents = data?.missing_agents || [];

  const filteredReports = reports.filter(r => 
    r.agent_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    r.building_name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6 mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3 mb-2">
              <FileText className="text-primary" /> Daily Reports Dashboard
            </h1>
            <p className="text-slate-400">Review agent tasks and verify photo evidence.</p>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="relative w-64">
              <input
                type="text"
                placeholder="Search agent or building..."
                className="w-full bg-slate-800 border border-slate-700 rounded-xl pl-10 pr-4 py-2 text-white focus:outline-none focus:border-primary"
                value={searchTerm}
                onChange={e => setSearchTerm(e.target.value)}
              />
              <Search className="absolute left-3 top-2.5 text-slate-400" size={18} />
            </div>
          </div>
        </div>

        {/* Missing Reports Alerts */}
        {(missingAgents.length > 0 || reports.some(r => r.status === 'Missing Photos')) && (
          <div className="mb-8 space-y-3">
            {missingAgents.map(agent => (
              <div key={`missing-${agent.id}`} className="bg-danger/10 border border-danger/20 text-danger px-4 py-3 rounded-lg flex items-center gap-3 font-medium">
                <span className="w-2 h-2 rounded-full bg-danger animate-pulse"></span>
                🔴 Agent {agent.name} has not submitted today's report.
              </div>
            ))}
            {reports.filter(r => r.status === 'Missing Photos').map(report => (
              <div key={`nophoto-${report.id}`} className="bg-warning/10 border border-warning/20 text-warning px-4 py-3 rounded-lg flex items-center gap-3 font-medium">
                <span className="w-2 h-2 rounded-full bg-warning animate-pulse"></span>
                🔴 Agent {report.agent_name} submitted a report without photo evidence.
              </div>
            ))}
          </div>
        )}

        <div className="glass-card overflow-hidden">
          {isLoading ? (
            <div className="p-12 text-center text-slate-400">Loading daily reports...</div>
          ) : (
            <table className="min-w-full divide-y divide-slate-700/50 text-left">
              <thead>
                <tr className="bg-slate-800/20">
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Agent</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Building</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Tasks Completed</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Photos</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Submitted At</th>
                  <th className="px-6 py-4 text-xs font-semibold text-slate-400 uppercase tracking-wider">Status</th>
                  <th className="px-6 py-4 text-right text-xs font-semibold text-slate-400 uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {filteredReports.map(report => {
                  const photos = report.photos ? JSON.parse(report.photos) : [];
                  const photoCount = photos.length;
                  return (
                    <tr key={report.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="px-6 py-4 text-white font-bold flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-primary/20 text-primary flex items-center justify-center font-bold text-xs border border-primary/30">
                          {report.agent_name.charAt(0)}
                        </div>
                        {report.agent_name}
                      </td>
                      <td className="px-6 py-4 text-slate-300 font-medium">
                        <div className="flex items-center gap-2"><Building size={14} className="text-slate-500"/> {report.building_name}</div>
                      </td>
                      <td className="px-6 py-4 text-white font-medium">{report.tasks_completed}</td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-1 text-slate-300">
                          <Camera size={14} className={photoCount > 0 ? "text-primary" : "text-slate-500"} /> 
                          {photoCount}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-slate-400 text-sm">
                        {formatTime(report.created_at)}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${
                          report.status === 'Completed' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'
                        }`}>
                          {report.status}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right">
                        <button 
                          onClick={() => setSelectedReport(report)}
                          className="bg-slate-800 hover:bg-slate-700 text-white px-3 py-1.5 rounded-lg text-sm transition-colors border border-slate-700 flex items-center gap-2 ml-auto"
                        >
                          <Eye size={14} /> View
                        </button>
                      </td>
                    </tr>
                  )
                })}
                {filteredReports.length === 0 && (
                  <tr>
                    <td colSpan="7" className="px-6 py-12 text-center text-slate-500">
                      No reports found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          )}
        </div>
      </div>

      {/* Report Modal */}
      {selectedReport && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-4xl max-h-[90vh] flex flex-col shadow-2xl animate-in zoom-in-95">
            <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/50 rounded-t-2xl">
              <div>
                <h3 className="text-xl font-bold text-white mb-1">Report Details: {selectedReport.agent_name}</h3>
                <p className="text-sm text-slate-400 flex items-center gap-2">
                  <Building size={14} /> {selectedReport.building_name} | {formatDate(selectedReport.created_at)}
                </p>
              </div>
              <button onClick={() => setSelectedReport(null)} className="text-slate-400 hover:text-white transition-colors">
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
              </button>
            </div>
            
            <div className="p-6 overflow-y-auto flex-1 custom-scrollbar">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
                <div className="bg-slate-800/50 p-5 rounded-xl border border-slate-700/50">
                  <div className="text-sm text-slate-400 mb-1">Time Spent</div>
                  <div className="text-lg text-white font-medium flex items-center gap-2"><Clock size={16} className="text-primary"/> {selectedReport.start_time} - {selectedReport.end_time}</div>
                </div>
                <div className="bg-slate-800/50 p-5 rounded-xl border border-slate-700/50">
                  <div className="text-sm text-slate-400 mb-1">Apartments Visited</div>
                  <div className="text-lg text-white font-medium">{selectedReport.apartments_visited || 'None'}</div>
                </div>
                <div className="bg-slate-800/50 p-5 rounded-xl border border-slate-700/50 md:col-span-2">
                  <div className="text-sm text-slate-400 mb-2">Issues Found</div>
                  <div className="text-white bg-slate-900 p-4 rounded-lg border border-slate-700 min-h-[80px]">
                    {selectedReport.issues_found || 'No issues reported.'}
                  </div>
                </div>
                <div className="bg-slate-800/50 p-5 rounded-xl border border-slate-700/50 md:col-span-2">
                  <div className="text-sm text-slate-400 mb-2">Notes</div>
                  <div className="text-white bg-slate-900 p-4 rounded-lg border border-slate-700 min-h-[80px]">
                    {selectedReport.notes || 'No notes provided.'}
                  </div>
                </div>
              </div>

              <h4 className="text-lg font-bold text-white mb-4 flex items-center gap-2"><Camera className="text-primary"/> Photo Evidence</h4>
              {selectedReport.photos && JSON.parse(selectedReport.photos).length > 0 ? (
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                  {JSON.parse(selectedReport.photos).map((photo, index) => (
                    <a key={index} href={`${axios.defaults.baseURL.replace('/api', '')}/${photo}`} target="_blank" rel="noreferrer" className="block relative group overflow-hidden rounded-xl border border-slate-700 aspect-square bg-slate-800">
                      <img src={`${axios.defaults.baseURL.replace('/api', '')}/${photo}`} alt={`Evidence ${index + 1}`} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                      <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                        <Eye className="text-white" size={24} />
                      </div>
                    </a>
                  ))}
                </div>
              ) : (
                <div className="bg-warning/10 border border-warning/20 text-warning p-6 rounded-xl text-center">
                  <AlertCircle className="mx-auto mb-2" size={32} />
                  <p>No photos were uploaded with this report.</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DailyReportsDashboard;
