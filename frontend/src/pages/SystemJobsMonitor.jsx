import React, { useState, useEffect } from 'react';
import { PlayCircle, RefreshCw, Power } from 'lucide-react';
import api from '../api/axios';

export default function SystemJobsMonitor() {
  const [jobs, setJobs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);

  const fetchJobs = async () => {
    setLoading(true);
    try {
      const response = await api.get('/jobs');
      if (response.data.status === 'success') {
        setJobs(response.data.data);
      }
    } catch (error) {
      showMessage('Failed to fetch jobs', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchJobs();
  }, []);

  const showMessage = (msg, type = 'success') => {
    setMessage({ text: msg, type });
    setTimeout(() => setMessage(null), 3000);
  };

  const handleToggle = async (id, currentStatus) => {
    try {
      const enable = currentStatus === 'Disabled';
      await api.post(`/jobs/${id}/toggle`, { enable });
      showMessage('Job status updated');
      fetchJobs();
    } catch (error) {
      showMessage('Failed to update status', 'error');
    }
  };

  const handleRun = async (id) => {
    try {
      await api.post(`/jobs/${id}/run`);
      showMessage('Job execution triggered');
      fetchJobs();
    } catch (error) {
      showMessage('Failed to run job', 'error');
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">System Jobs Monitor</h2>
        <button 
          onClick={fetchJobs} 
          className="flex items-center bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-4 py-2 rounded-lg shadow-sm transition-colors"
        >
          <RefreshCw size={16} className="mr-2" />
          Refresh
        </button>
      </div>

      {message && (
        <div className={`mb-4 p-4 rounded-lg ${message.type === 'error' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
          {message.text}
        </div>
      )}

      <div className="bg-white rounded-lg shadow border border-gray-100 overflow-x-auto">
        <table className="w-full text-left text-sm text-gray-500">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50">
            <tr>
              <th className="px-6 py-3">Job Name</th>
              <th className="px-6 py-3">Status</th>
              <th className="px-6 py-3">Last Run</th>
              <th className="px-6 py-3">Duration (s)</th>
              <th className="px-6 py-3">Records Processed</th>
              <th className="px-6 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr>
                <td colSpan="6" className="px-6 py-8 text-center text-gray-500">
                  <div className="flex justify-center items-center">
                    <RefreshCw className="animate-spin mr-2" /> Loading...
                  </div>
                </td>
              </tr>
            ) : jobs.length === 0 ? (
              <tr>
                <td colSpan="6" className="px-6 py-4 text-center text-gray-500">No scheduled jobs found.</td>
              </tr>
            ) : (
              jobs.map((job) => (
                <tr key={job.id} className="bg-white border-b hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium text-gray-900">{job.job_name}</td>
                  <td className="px-6 py-4">
                    <span className={`text-xs font-medium px-2.5 py-0.5 rounded ${
                      job.status === 'Success' ? 'bg-green-100 text-green-800' : 
                      job.status === 'Failed' ? 'bg-red-100 text-red-800' : 
                      job.status === 'Disabled' ? 'bg-gray-100 text-gray-800' : 
                      'bg-blue-100 text-blue-800'
                    }`}>
                      {job.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">{job.last_run || 'Never'}</td>
                  <td className="px-6 py-4">{job.duration_seconds}</td>
                  <td className="px-6 py-4">{job.records_processed}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-3">
                      <button 
                        onClick={() => handleToggle(job.id, job.status)}
                        className={`p-2 rounded-full transition-colors ${job.status !== 'Disabled' ? 'text-green-600 bg-green-50 hover:bg-green-100' : 'text-gray-400 bg-gray-50 hover:bg-gray-100'}`}
                        title={job.status !== 'Disabled' ? "Disable Job" : "Enable Job"}
                      >
                        <Power size={18} />
                      </button>
                      <button 
                        onClick={() => handleRun(job.id)}
                        disabled={job.status === 'Disabled'}
                        className={`flex items-center px-3 py-1.5 rounded-lg transition-colors ${job.status === 'Disabled' ? 'bg-gray-100 text-gray-400 cursor-not-allowed' : 'bg-primary text-white hover:bg-primary/90 shadow-sm'}`}
                      >
                        <PlayCircle size={16} className="mr-1.5" />
                        Run Now
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
