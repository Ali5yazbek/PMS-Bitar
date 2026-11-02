import React, { useState, useEffect } from 'react';
import { TrendingUp, AlertCircle, ShieldCheck, TrendingDown, CheckCircle } from 'lucide-react';
import api from '../api/axios';

export default function EnterpriseOperationsDashboard() {
  const [metrics, setMetrics] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMetrics();
  }, []);

  const fetchMetrics = async () => {
    try {
      const response = await api.get('/dashboard/executive');
      if (response.data.status === 'success') {
        setMetrics(response.data.data);
      }
    } catch (error) {
      console.error('Failed to fetch executive metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-[calc(100vh-80px)] items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <div className="p-6 bg-gray-50 min-h-screen">
      <h2 className="text-2xl font-bold mb-6 text-gray-800">Executive Operations Dashboard</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div className="bg-white rounded-lg shadow p-6 border border-gray-100">
          <div className="flex items-center text-green-600 mb-2">
            <TrendingUp size={24} className="mr-2" />
            <h3 className="text-sm font-semibold text-gray-500">Revenue Today (CFA)</h3>
          </div>
          <p className="text-2xl font-bold text-gray-900">{Number(metrics?.revenue_today || 0).toLocaleString()}</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6 border border-gray-100">
          <div className="flex items-center text-yellow-500 mb-2">
            <AlertCircle size={24} className="mr-2" />
            <h3 className="text-sm font-semibold text-gray-500">Expected Revenue (Pending)</h3>
          </div>
          <p className="text-2xl font-bold text-gray-900">{Number(metrics?.expected_revenue || 0).toLocaleString()}</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6 border border-gray-100">
          <div className="flex items-center text-blue-500 mb-2">
            <ShieldCheck size={24} className="mr-2" />
            <h3 className="text-sm font-semibold text-gray-500">Occupancy Rate</h3>
          </div>
          <p className="text-2xl font-bold text-gray-900">{metrics?.occupancy_rate || 0}%</p>
        </div>

        <div className="bg-white rounded-lg shadow p-6 border border-gray-100">
          <div className="flex items-center text-red-500 mb-2">
            <TrendingDown size={24} className="mr-2" />
            <h3 className="text-sm font-semibold text-gray-500">Overdue Rent</h3>
          </div>
          <p className="text-2xl font-bold text-gray-900">{Number(metrics?.overdue_rent || 0).toLocaleString()}</p>
        </div>
      </div>

      <div className="mt-8 bg-white rounded-lg shadow border border-gray-100">
        <div className="p-6 border-b border-gray-100">
          <h3 className="text-lg font-bold flex items-center text-gray-800">
            <CheckCircle className="mr-2 text-blue-500" size={24} />
            Work Analytics & Employee Productivity Ranking
          </h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-gray-500">
            <thead className="text-xs text-gray-700 uppercase bg-gray-50">
              <tr>
                <th className="px-6 py-3">Employee</th>
                <th className="px-6 py-3">Role</th>
                <th className="px-6 py-3">Tasks Assigned</th>
                <th className="px-6 py-3">Tasks Completed</th>
                <th className="px-6 py-3">Productivity</th>
              </tr>
            </thead>
            <tbody>
              {metrics?.employee_rankings?.map((emp) => (
                <tr key={emp.id} className="bg-white border-b hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium text-gray-900">{emp.full_name}</td>
                  <td className="px-6 py-4">
                    <span className="bg-blue-100 text-blue-800 text-xs font-medium mr-2 px-2.5 py-0.5 rounded">{emp.role}</span>
                  </td>
                  <td className="px-6 py-4">{emp.total_assigned}</td>
                  <td className="px-6 py-4">{emp.total_completed}</td>
                  <td className="px-6 py-4">
                    <span className={`font-bold ${emp.productivity >= 90 ? 'text-green-600' : emp.productivity >= 70 ? 'text-yellow-500' : 'text-red-600'}`}>
                      {emp.productivity}%
                    </span>
                  </td>
                </tr>
              ))}
              {(!metrics?.employee_rankings || metrics.employee_rankings.length === 0) && (
                <tr>
                  <td colSpan="5" className="px-6 py-4 text-center text-gray-500">No productivity data available for today.</td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
