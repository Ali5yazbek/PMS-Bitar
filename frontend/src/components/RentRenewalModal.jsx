import React, { useState, useEffect } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { X, Calendar, DollarSign, PauseCircle, PlayCircle, SkipForward, XCircle } from 'lucide-react';

const RentRenewalModal = ({ isOpen, onClose, profileId, tenantName, onComplete }) => {
  const queryClient = useQueryClient();
  const [action, setAction] = useState('renew_same');
  const [newAmount, setNewAmount] = useState('');

  const renewMutation = useMutation({
    mutationFn: async (payload) => {
      const res = await api.post(`/rent-profiles/${profileId}/renew`, payload);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['dashboardStats']);
      queryClient.invalidateQueries(['tenantRentProfile']);
      queryClient.invalidateQueries(['expiringItems']);
      if (onComplete) onComplete();
      onClose();
    }
  });

  const updateProfileMutation = useMutation({
    mutationFn: async (payload) => {
      const res = await api.put(`/rent-profiles/${profileId}`, payload);
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['dashboardStats']);
      queryClient.invalidateQueries(['tenantRentProfile']);
      if (onComplete) onComplete();
      onClose();
    }
  });

  const handleSubmit = () => {
    if (action === 'renew_same' || action === 'skip') {
      renewMutation.mutate({ action });
    } else if (action === 'renew_new') {
      renewMutation.mutate({ action, new_amount: newAmount });
    } else if (action === 'pause') {
      updateProfileMutation.mutate({ status: 'Paused' });
    } else if (action === 'resume') {
      updateProfileMutation.mutate({ status: 'Active' });
    } else if (action === 'end') {
      updateProfileMutation.mutate({ status: 'Ended' });
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden">
        <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/50">
          <h2 className="text-xl font-bold text-white">Rent Renewal Decision</h2>
          <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
            <X size={24} />
          </button>
        </div>
        
        <div className="p-6">
          <p className="text-slate-300 mb-6">
            The rent period for <strong className="text-white">{tenantName}</strong> has ended. What would you like to do?
          </p>

          <div className="space-y-3">
            <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${action === 'renew_same' ? 'border-primary bg-primary/10' : 'border-slate-700 hover:border-slate-500'}`}>
              <input type="radio" name="action" value="renew_same" checked={action === 'renew_same'} onChange={() => setAction('renew_same')} className="sr-only" />
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-emerald-500/20 flex items-center justify-center text-emerald-500 mr-4">
                <Calendar size={20} />
              </div>
              <div>
                <p className="font-semibold text-white">Renew with same amount</p>
                <p className="text-xs text-slate-400">Generates the next invoice with the current rent amount.</p>
              </div>
            </label>

            <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${action === 'renew_new' ? 'border-primary bg-primary/10' : 'border-slate-700 hover:border-slate-500'}`}>
              <input type="radio" name="action" value="renew_new" checked={action === 'renew_new'} onChange={() => setAction('renew_new')} className="sr-only" />
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-500 mr-4">
                <DollarSign size={20} />
              </div>
              <div className="flex-1">
                <p className="font-semibold text-white">Renew with new amount</p>
                <p className="text-xs text-slate-400 mb-2">Change the monthly rent for this and future cycles.</p>
                {action === 'renew_new' && (
                  <input 
                    type="number" 
                    placeholder="Enter new amount" 
                    value={newAmount}
                    onChange={(e) => setNewAmount(e.target.value)}
                    className="w-full bg-slate-950 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm focus:outline-none focus:border-primary"
                    onClick={(e) => e.stopPropagation()}
                  />
                )}
              </div>
            </label>

            <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${action === 'skip' ? 'border-primary bg-primary/10' : 'border-slate-700 hover:border-slate-500'}`}>
              <input type="radio" name="action" value="skip" checked={action === 'skip'} onChange={() => setAction('skip')} className="sr-only" />
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-purple-500/20 flex items-center justify-center text-purple-500 mr-4">
                <SkipForward size={20} />
              </div>
              <div>
                <p className="font-semibold text-white">Skip this billing cycle</p>
                <p className="text-xs text-slate-400">Advances the billing date without creating an invoice.</p>
              </div>
            </label>

            <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${action === 'pause' ? 'border-primary bg-primary/10' : 'border-slate-700 hover:border-slate-500'}`}>
              <input type="radio" name="action" value="pause" checked={action === 'pause'} onChange={() => setAction('pause')} className="sr-only" />
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-orange-500/20 flex items-center justify-center text-orange-500 mr-4">
                <PauseCircle size={20} />
              </div>
              <div>
                <p className="font-semibold text-white">Pause rent</p>
                <p className="text-xs text-slate-400">Suspend future billing until manually resumed.</p>
              </div>
            </label>

            <label className={`flex items-center p-4 border rounded-xl cursor-pointer transition-all ${action === 'end' ? 'border-primary bg-primary/10' : 'border-slate-700 hover:border-slate-500'}`}>
              <input type="radio" name="action" value="end" checked={action === 'end'} onChange={() => setAction('end')} className="sr-only" />
              <div className="flex-shrink-0 w-10 h-10 rounded-full bg-red-500/20 flex items-center justify-center text-red-500 mr-4">
                <XCircle size={20} />
              </div>
              <div>
                <p className="font-semibold text-white">End rent</p>
                <p className="text-xs text-slate-400">Stop rent billing permanently.</p>
              </div>
            </label>
          </div>
        </div>

        <div className="p-6 border-t border-slate-800 flex justify-end space-x-3 bg-slate-950/50">
          <button onClick={onClose} className="px-5 py-2.5 rounded-xl font-medium bg-slate-800 text-white hover:bg-slate-700 transition-colors">
            Cancel
          </button>
          <button 
            onClick={handleSubmit} 
            disabled={renewMutation.isLoading || updateProfileMutation.isLoading || (action === 'renew_new' && !newAmount)}
            className="px-5 py-2.5 rounded-xl font-medium bg-primary text-white hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {renewMutation.isLoading || updateProfileMutation.isLoading ? 'Processing...' : 'Confirm Decision'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default RentRenewalModal;
