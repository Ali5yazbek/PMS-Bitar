import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../api/axios';
import { Calendar as CalendarIcon, Clock, CheckCircle, XCircle, FileText, AlertCircle, CalendarDays } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const TenantRequests = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  
  const [showDenyModal, setShowDenyModal] = useState(false);
  const [showAcceptModal, setShowAcceptModal] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState(null);
  
  const [denialReason, setDenialReason] = useState('');
  const [collectionDate, setCollectionDate] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const { data: requests, isLoading } = useQuery({
    queryKey: ['tenantRequests'],
    queryFn: async () => {
      const res = await api.get('/tenant/rent-requests');
      return res.data;
    }
  });

  const denyMutation = useMutation({
    mutationFn: async (data) => api.post('/tenant/rent-requests/deny', data),
    onSuccess: () => {
      alert(t('Request denied successfully'));
      queryClient.invalidateQueries(['tenantRequests']);
      setShowDenyModal(false);
      setDenialReason('');
    },
    onError: (err) => alert(err.response?.data?.error || t('Failed to deny request'))
  });

  const acceptMutation = useMutation({
    mutationFn: async (data) => api.post('/tenant/rent-requests/accept', data),
    onSuccess: () => {
      alert(t('Collection scheduled successfully'));
      queryClient.invalidateQueries(['tenantRequests']);
      setShowAcceptModal(false);
      setCollectionDate('');
    },
    onError: (err) => alert(err.response?.data?.error || t('Failed to schedule collection'))
  });

  const handleDeny = () => {
    if (!denialReason.trim()) {
      alert(t('Reason is required'));
      return;
    }
    setIsSubmitting(true);
    denyMutation.mutate({ request_id: selectedRequest.id, reason: denialReason }, {
      onSettled: () => setIsSubmitting(false)
    });
  };

  const handleAccept = () => {
    if (!collectionDate) {
      alert(t('Date is required'));
      return;
    }
    
    // Frontend validation
    const selected = new Date(collectionDate);
    const today = new Date();
    today.setHours(0,0,0,0);
    const end = new Date(selectedRequest.end_date);
    
    if (selected < today) {
      alert(t('Collection date cannot be in the past'));
      return;
    }
    if (selected >= end) {
      alert(t('Collection date must be before the rent expiration date'));
      return;
    }
    
    setIsSubmitting(true);
    acceptMutation.mutate({ request_id: selectedRequest.id, collection_date: collectionDate }, {
      onSettled: () => setIsSubmitting(false)
    });
  };

  const getStatusBadge = (status) => {
    switch(status) {
      case 'PENDING_RESPONSE': return <span className="px-3 py-1 bg-orange-500/20 text-orange-400 rounded-full text-sm font-medium border border-orange-500/30">Action Required</span>;
      case 'SCHEDULED': return <span className="px-3 py-1 bg-blue-500/20 text-blue-400 rounded-full text-sm font-medium border border-blue-500/30">Scheduled</span>;
      case 'DENIED': return <span className="px-3 py-1 bg-red-500/20 text-red-400 rounded-full text-sm font-medium border border-red-500/30">Denied</span>;
      case 'COLLECTED':
      case 'COMPLETED': return <span className="px-3 py-1 bg-emerald-500/20 text-emerald-400 rounded-full text-sm font-medium border border-emerald-500/30">Completed</span>;
      default: return <span className="px-3 py-1 bg-slate-500/20 text-slate-400 rounded-full text-sm font-medium border border-slate-500/30">{status}</span>;
    }
  };

  if (isLoading) return <div className="p-8 text-muted">Loading requests...</div>;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white flex items-center">
            <CalendarDays className="me-3 text-primary" size={32} />
            Rent Renewal Requests
          </h1>
          <p className="text-muted mt-2">Manage your upcoming rent renewals and schedule payment collections.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {requests?.length === 0 ? (
             <div className="col-span-full p-12 glass-card text-center text-muted flex flex-col items-center justify-center">
               <CheckCircle size={48} className="text-emerald-500/50 mb-4" />
               <p className="text-lg">You have no pending rent requests.</p>
             </div>
          ) : (
            requests?.map(req => (
              <div key={req.id} className="glass-card p-6 flex flex-col relative overflow-hidden">
                {req.status === 'PENDING_RESPONSE' && (
                  <div className="absolute top-0 right-0 w-16 h-16 bg-gradient-to-bl from-orange-500/30 to-transparent"></div>
                )}
                
                <div className="flex justify-between items-start mb-4">
                  <div>
                    <h3 className="text-xl font-bold text-white">Rent Ending Soon</h3>
                    <p className="text-muted text-sm mt-1">{req.building_name} - {req.apartment_code}</p>
                  </div>
                  {getStatusBadge(req.status)}
                </div>
                
                <div className="space-y-3 mb-6 flex-1">
                  <div className="bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
                    <div className="text-xs text-muted mb-1 uppercase tracking-wider">Current Period</div>
                    <div className="text-white font-medium flex items-center gap-2">
                      <CalendarIcon size={14} className="text-primary" />
                      {new Date(req.start_date).toLocaleDateString()} &rarr; {new Date(req.end_date).toLocaleDateString()}
                    </div>
                  </div>
                  
                  <div className="bg-slate-900/50 p-3 rounded-lg border border-slate-700/50">
                    <div className="text-xs text-muted mb-1 uppercase tracking-wider">Amount Due</div>
                    <div className="text-2xl font-bold text-indigo-400">
                      {Number(req.amount).toLocaleString()} CFA
                    </div>
                  </div>

                  {req.status === 'SCHEDULED' && (
                    <div className="bg-blue-500/10 p-3 rounded-lg border border-blue-500/30">
                      <div className="text-xs text-blue-400/70 mb-1 uppercase tracking-wider">Collection Scheduled</div>
                      <div className="text-blue-400 font-medium flex items-center gap-2">
                        <Clock size={14} />
                        {new Date(req.requested_collection_date).toLocaleDateString()}
                      </div>
                    </div>
                  )}

                  {req.status === 'DENIED' && (
                    <div className="bg-red-500/10 p-3 rounded-lg border border-red-500/30">
                      <div className="text-xs text-red-400/70 mb-1 uppercase tracking-wider">Denial Reason</div>
                      <div className="text-red-400 text-sm">
                        {req.denial_reason}
                      </div>
                    </div>
                  )}
                </div>

                {req.status === 'PENDING_RESPONSE' && (
                  <div className="grid grid-cols-2 gap-3 mt-auto">
                    <button 
                      onClick={() => { setSelectedRequest(req); setShowAcceptModal(true); }}
                      className="bg-primary hover:bg-primary/90 text-white py-2.5 rounded-xl font-medium transition-colors border border-primary"
                    >
                      Accept Renewal
                    </button>
                    <button 
                      onClick={() => { setSelectedRequest(req); setShowDenyModal(true); }}
                      className="bg-transparent hover:bg-red-500/10 text-red-400 py-2.5 rounded-xl font-medium transition-colors border border-red-500/30"
                    >
                      Deny Renewal
                    </button>
                  </div>
                )}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Deny Modal */}
      {showDenyModal && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-700/80 rounded-2xl w-full max-w-md shadow-2xl p-6">
            <h2 className="text-xl font-bold text-white mb-2 flex items-center gap-2">
              <AlertCircle className="text-red-400" />
              Why do you want to deny the renewal?
            </h2>
            <p className="text-muted text-sm mb-6">Please provide a reason for declining this rent renewal request.</p>
            
            <textarea 
              className="w-full bg-slate-800 border border-slate-700 rounded-xl p-4 text-white placeholder-slate-500 focus:border-red-500 focus:ring-1 focus:ring-red-500 outline-none transition-all resize-none h-32 mb-6"
              placeholder="e.g. I am leaving the apartment..."
              value={denialReason}
              onChange={(e) => setDenialReason(e.target.value)}
            />
            
            <div className="flex gap-3">
              <button 
                onClick={() => { setShowDenyModal(false); setDenialReason(''); }}
                className="flex-1 px-4 py-2.5 rounded-xl text-slate-300 hover:bg-slate-800 transition-colors"
                disabled={isSubmitting}
              >
                Cancel
              </button>
              <button 
                onClick={handleDeny}
                disabled={!denialReason.trim() || isSubmitting}
                className="flex-1 px-4 py-2.5 bg-red-500 hover:bg-red-600 disabled:opacity-50 disabled:hover:bg-red-500 text-white font-medium rounded-xl transition-colors"
              >
                {isSubmitting ? 'Submitting...' : 'Confirm Deny'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Accept Modal */}
      {showAcceptModal && selectedRequest && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
          <div className="bg-slate-900 border border-slate-700/80 rounded-2xl w-full max-w-md shadow-2xl p-6">
            <h2 className="text-xl font-bold text-white mb-6">Schedule Payment Collection</h2>
            
            <div className="space-y-4 mb-6">
              <div className="flex justify-between items-center pb-4 border-b border-slate-800">
                <span className="text-muted">Apartment</span>
                <span className="text-white font-medium">{selectedRequest.building_name} {selectedRequest.apartment_code}</span>
              </div>
              <div className="flex justify-between items-center pb-4 border-b border-slate-800">
                <span className="text-muted">Amount Due</span>
                <span className="text-indigo-400 font-bold">{Number(selectedRequest.amount).toLocaleString()} CFA</span>
              </div>
              <div className="flex justify-between items-center pb-4 border-b border-slate-800">
                <span className="text-muted">Rent Expires</span>
                <span className="text-white font-medium">{new Date(selectedRequest.end_date).toLocaleDateString()}</span>
              </div>
              
              <div>
                <label className="block text-sm text-slate-300 mb-2 font-medium">When would you like the agent to come and collect the rent payment?</label>
                <input 
                  type="date"
                  className="w-full bg-slate-800 border border-slate-700 rounded-xl px-4 py-3 text-white outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                  value={collectionDate}
                  min={new Date().toISOString().split('T')[0]} // Not in past
                  max={new Date(new Date(selectedRequest.end_date).getTime() - 86400000).toISOString().split('T')[0]} // Before rent end date
                  onChange={(e) => setCollectionDate(e.target.value)}
                />
              </div>
            </div>
            
            <div className="p-4 bg-primary/10 border border-primary/20 rounded-xl mb-6 flex gap-3 text-sm text-primary/90">
              <AlertCircle size={20} className="shrink-0" />
              <p>Are you sure you want to confirm this payment collection appointment?</p>
            </div>
            
            <div className="flex gap-3">
              <button 
                onClick={() => { setShowAcceptModal(false); setCollectionDate(''); }}
                className="flex-1 px-4 py-2.5 rounded-xl text-slate-300 hover:bg-slate-800 transition-colors"
                disabled={isSubmitting}
              >
                Back
              </button>
              <button 
                onClick={handleAccept}
                disabled={!collectionDate || isSubmitting}
                className="flex-1 px-4 py-2.5 bg-primary hover:bg-primary/90 disabled:opacity-50 text-white font-medium rounded-xl transition-colors"
              >
                {isSubmitting ? 'Scheduling...' : 'Yes, Confirm'}
              </button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default TenantRequests;
