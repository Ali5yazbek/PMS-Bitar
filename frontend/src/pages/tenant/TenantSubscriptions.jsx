import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../api/axios';
import { Zap, AlertCircle } from 'lucide-react';

const TenantSubscriptions = () => {
  const queryClient = useQueryClient();
  const [toast, setToast] = useState(null);

  // Fetch unread notifications
  const { data: notifications, isLoading: loadingNotifs } = useQuery({
    queryKey: ['unreadNotifications'],
    queryFn: async () => (await api.get('/notifications/unread')).data
  });

  // Fetch active contracts to get apartment details
  const { data: dashboardData, isLoading: loadingDashboard } = useQuery({
    queryKey: ['tenant-dashboard'],
    queryFn: async () => (await api.get('/tenant-portal/dashboard')).data
  });

  const respondMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${data.apartmentId}/respond-renewal`, {
      notification_id: data.notificationId,
      decision: data.decision
    }),
    onSuccess: (res, variables) => {
      setToast({ message: res.data.message || `Successfully marked as ${variables.decision}`, type: 'success' });
      queryClient.invalidateQueries(['unreadNotifications']);
      setTimeout(() => setToast(null), 3000);
    },
    onError: (error) => {
      setToast({ message: error?.response?.data?.error || 'Failed to submit response', type: 'error' });
      setTimeout(() => setToast(null), 3000);
    }
  });

  if (loadingNotifs || loadingDashboard) {
    return <div className="p-8 text-muted">Loading your subscriptions...</div>;
  }

  const renewalRequests = notifications?.filter(n => n.type === 'generator_renewal_request') || [];

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center gap-3">
            <Zap className="text-primary" /> Generator Subscriptions
          </h1>
          <p className="text-muted">Manage your electricity and generator subscriptions.</p>
        </div>

        {renewalRequests.length > 0 && (
          <div className="mb-8 space-y-4">
            {renewalRequests.map(notif => {
              // reference_id is apartment_id
              const apartmentId = notif.reference_id;
              const contract = dashboardData?.contracts?.find(c => String(c.apartment_id) === String(apartmentId));
              const aptName = contract ? contract.apartment_code : 'your apartment';

              return (
                <div key={notif.id} className="glass-card p-6 border border-warning/50 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-1 h-full bg-warning"></div>
                  <div className="flex items-start gap-4">
                    <AlertCircle className="text-warning mt-1" size={24} />
                    <div className="flex-1">
                      <h3 className="text-xl font-bold text-white mb-2">{notif.title}</h3>
                      <p className="text-slate-300 mb-6">{notif.message}</p>
                      
                      <div className="flex flex-wrap gap-3">
                        <button 
                          onClick={() => respondMutation.mutate({ notificationId: notif.id, apartmentId, decision: 'Accept' })}
                          disabled={respondMutation.isLoading}
                          className="px-6 py-2 bg-success hover:bg-success/80 text-white font-bold rounded-lg transition-colors shadow-lg shadow-success/20"
                        >
                          Accept & Renew
                        </button>
                        <button 
                          onClick={() => respondMutation.mutate({ notificationId: notif.id, apartmentId, decision: 'Pause' })}
                          disabled={respondMutation.isLoading}
                          className="px-6 py-2 bg-warning hover:bg-warning/80 text-white font-bold rounded-lg transition-colors shadow-lg shadow-warning/20"
                        >
                          Pause Subscription
                        </button>
                        <button 
                          onClick={() => respondMutation.mutate({ notificationId: notif.id, apartmentId, decision: 'Reject' })}
                          disabled={respondMutation.isLoading}
                          className="px-6 py-2 bg-danger hover:bg-danger/80 text-white font-bold rounded-lg transition-colors shadow-lg shadow-danger/20"
                        >
                          Reject
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {renewalRequests.length === 0 && (
          <div className="glass-card p-8 text-center text-muted">
            <Zap className="mx-auto mb-4 text-slate-500" size={48} />
            <p>You have no pending subscription requests.</p>
          </div>
        )}

        {/* Toast Notification */}
        {toast && (
          <div className={`fixed bottom-4 right-4 text-white px-6 py-3 rounded-lg shadow-2xl z-50 animate-bounce ${toast.type === 'error' ? 'bg-danger' : 'bg-emerald-600'}`}>
            {toast.message}
          </div>
        )}
      </div>
    </div>
  );
};

export default TenantSubscriptions;
