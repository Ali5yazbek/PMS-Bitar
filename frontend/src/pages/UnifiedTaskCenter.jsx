import React, { useState, useEffect } from 'react';
import { RefreshCw, CheckCircle, ChevronDown, Clock, XCircle } from 'lucide-react';
import api from '../api/axios';

export default function UnifiedTaskCenter() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState(null);
  const [openDropdown, setOpenDropdown] = useState(null);

  const fetchTasks = async () => {
    setLoading(true);
    try {
      const userStr = localStorage.getItem('user');
      const user = userStr ? JSON.parse(userStr) : null;
      if (!user) return;

      const response = await api.get(`/tasks/me?user_id=${user.id}`);
      if (response.data.status === 'success') {
        setTasks(response.data.data);
      }
    } catch (error) {
      showMessage('Failed to fetch tasks', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTasks();
  }, []);

  const showMessage = (msg, type = 'success') => {
    setMessage({ text: msg, type });
    setTimeout(() => setMessage(null), 3000);
  };

  const updateStatus = async (id, status) => {
    setOpenDropdown(null);
    try {
      const userStr = localStorage.getItem('user');
      const user = userStr ? JSON.parse(userStr) : null;

      await api.post(`/tasks/${id}/status`, { status, user_id: user?.id });
      showMessage(`Task marked as ${status}`);
      fetchTasks();
    } catch (error) {
      showMessage('Failed to update task status', 'error');
    }
  };

  return (
    <div className="p-6 bg-gray-50 min-h-screen" onClick={() => setOpenDropdown(null)}>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Unified Task Center</h2>
        <button 
          onClick={fetchTasks} 
          className="flex items-center bg-white border border-gray-300 text-gray-700 hover:bg-gray-50 px-4 py-2 rounded-lg shadow-sm transition-colors"
        >
          <RefreshCw size={16} className="mr-2" />
          Refresh Inbox
        </button>
      </div>

      {message && (
        <div className={`mb-4 p-4 rounded-lg ${message.type === 'error' ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'}`}>
          {message.text}
        </div>
      )}

      <div className="bg-white rounded-lg shadow border border-gray-100 overflow-visible">
        <table className="w-full text-left text-sm text-gray-500">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50">
            <tr>
              <th className="px-6 py-3">Task Title</th>
              <th className="px-6 py-3">Type</th>
              <th className="px-6 py-3">Priority</th>
              <th className="px-6 py-3">Due Date</th>
              <th className="px-6 py-3">Status</th>
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
            ) : tasks.length === 0 ? (
              <tr>
                <td colSpan="6" className="px-6 py-8 text-center text-gray-500">
                  <div className="flex flex-col items-center">
                    <CheckCircle className="text-green-500 mb-2" size={32} />
                    <p className="text-lg font-medium text-gray-900">You're all caught up!</p>
                    <p>No tasks assigned to you right now.</p>
                  </div>
                </td>
              </tr>
            ) : (
              tasks.map((task) => (
                <tr key={task.id} className="bg-white border-b hover:bg-gray-50">
                  <td className="px-6 py-4 font-medium text-gray-900">{task.title}</td>
                  <td className="px-6 py-4">
                    <span className="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded">{task.type}</span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs font-medium px-2.5 py-0.5 rounded ${
                      task.priority === 'Urgent' ? 'bg-red-100 text-red-800' : 
                      task.priority === 'High' ? 'bg-orange-100 text-orange-800' : 
                      'bg-gray-100 text-gray-800'
                    }`}>
                      {task.priority}
                    </span>
                  </td>
                  <td className="px-6 py-4">{task.due_date}</td>
                  <td className="px-6 py-4">
                    <span className={`text-xs font-medium px-2.5 py-0.5 rounded ${
                      task.status === 'Completed' ? 'bg-green-100 text-green-800' : 
                      task.status === 'In Progress' ? 'bg-blue-100 text-blue-800' : 
                      'bg-yellow-100 text-yellow-800'
                    }`}>
                      {task.status}
                    </span>
                  </td>
                  <td className="px-6 py-4 relative">
                    <div className="relative inline-block text-left" onClick={(e) => e.stopPropagation()}>
                      <button 
                        onClick={() => setOpenDropdown(openDropdown === task.id ? null : task.id)}
                        className="flex items-center px-3 py-1.5 bg-white border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 hover:bg-gray-50 focus:outline-none"
                      >
                        Actions <ChevronDown size={16} className="ml-2" />
                      </button>
                      
                      {openDropdown === task.id && (
                        <div className="origin-top-right absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5 z-50">
                          <div className="py-1" role="menu">
                            <button 
                              onClick={() => updateStatus(task.id, 'In Progress')}
                              className="w-full text-left flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                            >
                              <Clock size={16} className="mr-2 text-blue-500" /> Mark In Progress
                            </button>
                            <button 
                              onClick={() => updateStatus(task.id, 'Completed')}
                              className="w-full text-left flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-100"
                            >
                              <CheckCircle size={16} className="mr-2 text-green-500" /> Mark Completed
                            </button>
                            <button 
                              onClick={() => updateStatus(task.id, 'Cancelled')}
                              className="w-full text-left flex items-center px-4 py-2 text-sm text-red-600 hover:bg-red-50"
                            >
                              <XCircle size={16} className="mr-2" /> Cancel Task
                            </button>
                          </div>
                        </div>
                      )}
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
