import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import { CheckCircle2, Building2, User, Home, AlertCircle, RefreshCw, X } from 'lucide-react';
import { useLocation } from 'react-router-dom';

const AgentRentCollection = () => {
  const queryClient = useQueryClient();
  const location = useLocation();
  const preselectBuildingId = location.state?.preselectBuildingId;
  const [selectedTask, setSelectedTask] = useState(null);

  const { data, isLoading } = useQuery({
    queryKey: ['agent_rent_tasks'],
    queryFn: async () => {
      const res = await axios.get('/agent/rent/tasks');
      return res.data?.data || {};
    },
  });

  const { data: requestData, isLoading: isRequestsLoading } = useQuery({
    queryKey: ['agent_tenant_requests'],
    queryFn: async () => {
      const res = await axios.get('/agent/rent-requests');
      return res.data?.data || {};
    },
  });

  useEffect(() => {
    if (data && preselectBuildingId) {
      setTimeout(() => {
        const el = document.getElementById(`building-${preselectBuildingId}`);
        if (el) el.scrollIntoView({ behavior: 'smooth' });
      }, 300);
    }
  }, [data, preselectBuildingId]);

  const collectMutation = useMutation({
    mutationFn: async (payload) => {
      const res = await axios.post('/agent/rent/collect', payload);
      return res.data;
    },
    onSuccess: (data) => {
      alert(data.message || 'Payment collected successfully');
      queryClient.invalidateQueries(['agent_rent_tasks']);
      setSelectedTask(null);
    },
    onError: (error) => {
      alert(error.response?.data?.message || 'Failed to collect payment');
    }
  });

  const handleCollect = (e) => {
    e.preventDefault();
    const formData = new FormData(e.target);
    const amount = parseFloat(formData.get('amount'));
    if (!amount || amount <= 0) {
      alert('Please enter a valid amount');
      return;
    }
    if (amount > selectedTask.remaining) {
      alert('Amount exceeds remaining balance');
      return;
    }

    collectMutation.mutate({
      invoice_id: selectedTask.invoice_id,
      task_id: selectedTask.task_id || null,
      request_id: selectedTask.request_id || null,
      amount,
      method: formData.get('method'),
      notes: formData.get('notes')
    });
  };

  if (isLoading || !data) return <div className="p-8 flex justify-center"><RefreshCw className="animate-spin text-primary" size={32} /></div>;

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <h1 className="text-3xl font-bold text-white mb-2">Rent Collection Tasks</h1>
      <p className="text-slate-400 mb-8">Collect rent from tenants with pending tasks or requests.</p>

      {/* Tenant Requests Section */}
      {requestData && Object.keys(requestData).length > 0 && (
        <div className="mb-12">
          <h2 className="text-2xl font-bold text-primary mb-6 border-b border-primary/20 pb-2">Tenant Scheduled Requests</h2>
          {Object.entries(requestData).map(([buildingName, tasks]) => (
            <div key={`req-${buildingName}`} className="mb-8">
              <h3 className="text-xl font-bold text-white mb-4 flex items-center">
                <Building2 className="me-2 text-primary" size={24} />
                {buildingName}
                <span className="ml-3 text-xs font-bold px-2 py-1 bg-primary/20 text-primary rounded-lg">
                  {tasks.length} Requests
                </span>
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {tasks.map(task => (
                  <div key={`req-${task.request_id}`} className="p-6 rounded-2xl border bg-primary/5 border-primary/30 relative overflow-hidden">
                    <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-bl from-primary/30 to-transparent"></div>
                    <div className="flex justify-between items-start mb-4">
                      <div className="flex items-center gap-3">
                        <div className="w-10 h-10 rounded-xl bg-primary/20 text-primary flex items-center justify-center font-bold">
                          {task.apartment_number}
                        </div>
                        <div>
                          <p className="text-white font-bold">{task.tenant_name || 'Unknown'}</p>
                          <p className="text-xs text-primary/70">Scheduled Request</p>
                        </div>
                      </div>
                    </div>
                    <div className="mb-6 p-3 bg-slate-900/50 rounded-xl flex justify-between items-center border border-slate-700/50">
                      <div>
                        <p className="text-xs text-slate-400">Amount Due</p>
                        <p className="text-lg font-bold text-white">${task.remaining || task.amount}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-xs text-slate-400">Requested Date</p>
                        <p className="text-sm font-bold text-primary">
                          {new Date(task.requested_collection_date).toLocaleDateString()}
                        </p>
                      </div>
                    </div>
                    <button
                      onClick={() => setSelectedTask({...task, remaining: task.remaining || task.amount})}
                      className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-bold rounded-xl transition-colors border border-primary/50"
                    >
                      Collect Payment
                    </button>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* System Tasks Section */}
      <h2 className="text-2xl font-bold text-slate-300 mb-6 border-b border-slate-700 pb-2">System Generated Tasks</h2>


      {Object.keys(data).length === 0 ? (
        <div className="flex flex-col items-center justify-center p-12 bg-[#1E293B] rounded-2xl border border-slate-700">
          <CheckCircle2 size={48} className="text-success mb-4" />
          <h2 className="text-2xl font-bold text-white mb-2">All Caught Up!</h2>
          <p className="text-slate-400">There are no pending rent collection tasks assigned to you.</p>
        </div>
      ) : (
        Object.entries(data).map(([buildingName, tasks]) => (
          <div key={buildingName} id={`building-${tasks[0]?.building_id}`} className="mb-10">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center">
              <Building2 className="me-2 text-indigo-400" size={24} />
              {buildingName}
              <span className="ml-3 text-xs font-bold px-2 py-1 bg-indigo-500/20 text-indigo-400 rounded-lg">
                {tasks.length} Tasks
              </span>
            </h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {tasks.map(task => (
                <div key={`${task.task_id}-${task.invoice_id}`} className={`p-6 rounded-2xl border ${task.task_status === 'Partial' ? 'bg-warning/10 border-warning/30' : 'bg-[#1E293B] border-slate-700'}`}>
                  <div className="flex justify-between items-start mb-4">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-xl bg-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold">
                        {task.apartment_number}
                      </div>
                      <div>
                        <p className="text-white font-bold">{task.tenant_name || 'Unknown'}</p>
                        <p className="text-xs text-slate-400">Contract #{task.contract_id}</p>
                      </div>
                    </div>
                    {task.task_status === 'Partial' && (
                      <span className="text-xs font-bold px-2 py-1 bg-warning/20 text-warning rounded-lg">Partial</span>
                    )}
                  </div>
                  <div className="mb-6 p-3 bg-[#0F172A] rounded-xl flex justify-between items-center">
                    <div>
                      <p className="text-xs text-slate-400">Amount Due</p>
                      <p className="text-lg font-bold text-white">${task.remaining}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-xs text-slate-400">Due Date</p>
                      <p className={`text-sm font-bold ${new Date(task.due_date) < new Date() ? 'text-danger' : 'text-success'}`}>
                        {new Date(task.due_date).toLocaleDateString()}
                      </p>
                    </div>
                  </div>
                  <button
                    onClick={() => setSelectedTask(task)}
                    className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-bold rounded-xl transition-colors"
                  >
                    Collect Payment
                  </button>
                </div>
              ))}
            </div>
          </div>
        ))
      )}

      {/* Collect Payment Modal */}
      {selectedTask && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm">
          <div className="bg-[#1E293B] rounded-2xl border border-slate-700 w-full max-w-md shadow-2xl">
            <div className="flex justify-between items-center p-6 border-b border-slate-700">
              <h2 className="text-xl font-bold text-white">Collect Payment</h2>
              <button onClick={() => setSelectedTask(null)} className="text-slate-400 hover:text-white"><X size={24} /></button>
            </div>
            <form onSubmit={handleCollect} className="p-6">
              <div className="flex justify-between items-center mb-6 p-4 bg-[#0F172A] rounded-xl">
                <div>
                  <p className="text-sm text-white font-bold">{selectedTask.tenant_name}</p>
                  <p className="text-xs text-slate-400">Apt {selectedTask.apartment_number} • {selectedTask.building_name}</p>
                </div>
                <div className="text-right">
                  <p className="text-xs text-slate-400">Remaining Balance</p>
                  <p className="text-xl font-bold text-success">${selectedTask.remaining}</p>
                </div>
              </div>

              <div className="mb-4">
                <label className="block text-sm font-semibold text-slate-300 mb-2">Amount Received</label>
                <div className="relative">
                  <span className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 font-bold">$</span>
                  <input
                    type="number"
                    name="amount"
                    step="0.01"
                    defaultValue={selectedTask.remaining}
                    max={selectedTask.remaining}
                    required
                    className="w-full bg-[#0F172A] border border-slate-700 rounded-xl px-10 py-3 text-white font-bold focus:border-primary focus:ring-1 focus:ring-primary outline-none"
                  />
                </div>
              </div>

              <div className="mb-4">
                <label className="block text-sm font-semibold text-slate-300 mb-2">Payment Method</label>
                <select name="method" className="w-full bg-[#0F172A] border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-primary outline-none">
                  <option value="Cash">Cash</option>
                  <option value="Bank Transfer">Bank Transfer</option>
                  <option value="Mobile Money">Mobile Money</option>
                </select>
              </div>

              <div className="mb-6">
                <label className="block text-sm font-semibold text-slate-300 mb-2">Notes (Optional)</label>
                <input
                  type="text"
                  name="notes"
                  placeholder="Receipt number or details..."
                  className="w-full bg-[#0F172A] border border-slate-700 rounded-xl px-4 py-3 text-white focus:border-primary outline-none"
                />
              </div>

              <div className="flex gap-4">
                <button
                  type="button"
                  onClick={() => setSelectedTask(null)}
                  className="flex-1 py-3 bg-[#0F172A] text-white rounded-xl font-bold hover:bg-slate-800"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={collectMutation.isLoading}
                  className="flex-1 py-3 bg-success hover:bg-success/90 text-white rounded-xl font-bold disabled:opacity-50"
                >
                  {collectMutation.isLoading ? 'Processing...' : 'Confirm Payment'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default AgentRentCollection;
