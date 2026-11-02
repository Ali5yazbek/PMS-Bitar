import { useTranslation } from 'react-i18next';
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../../api/axios';
import { Home, Shield, AlertCircle } from 'lucide-react';
import InteractiveCurrency from '../../components/common/InteractiveCurrency';

const TenantDashboard = () => {
  const { t } = useTranslation();

  const { data, isLoading } = useQuery({ 
    queryKey: ['tenant-dashboard'], 
    queryFn: async () => (await api.get('/tenant-portal/dashboard')).data 
  });

  if (isLoading) return <div className="p-8 text-muted">{t('tenantdashboard.loading_your_dashboard', { defaultValue: `Loading your dashboard...` })}</div>;

  const contracts = data?.contracts || [];

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">{t('tenantdashboard.welcome_home', { defaultValue: `Welcome Home` })}</h1>
          <p className="text-muted">{t('tenantdashboard.here_is_an_overview_of_your_ap', { defaultValue: `Here is an overview of your apartment and contract.` })}</p>
        </div>

        {contracts.length > 0 ? (
          <div className="space-y-10">
            {contracts.map(contract => (
              <div key={contract.id} className="grid grid-cols-1 md:grid-cols-2 gap-6 pb-8 border-b border-slate-800/50 last:border-0">
            <div className="glass-card p-6">
              <h3 className="text-xl font-bold text-white flex items-center mb-4">
                <Home className="me-2 text-primary" size={24} />
                {t('tenantdashboard.my_apartment', { defaultValue: `My Apartment` })}
              </h3>
              <div className="space-y-4">
                <div>
                  <span className="text-muted text-sm block">{t('tenantdashboard.building', { defaultValue: `Building` })}</span>
                  <span className="text-white font-medium text-lg">{contract.building_name}</span>
                </div>
                <div>
                  <span className="text-muted text-sm block">{t('tenantdashboard.apartment_number', { defaultValue: `Apartment Number` })}</span>
                  <span className="text-white font-medium text-lg">{contract.apartment_code}</span>
                </div>
                <div>
                  <span className="text-muted text-sm block">{t('tenantdashboard.monthly_rent', { defaultValue: `Monthly Rent` })}</span>
                  <span className="text-white font-medium text-lg">
                    <InteractiveCurrency amountCFA={contract.monthly_rent} />
                  </span>
                </div>
              </div>
            </div>

            <div className="glass-card p-6">
              <h3 className="text-xl font-bold text-white flex items-center mb-4">
                <Shield className="me-2 text-primary" size={24} />
                {t('tenantdashboard.contract_details', { defaultValue: `Contract Details` })}
              </h3>
              <div className="space-y-4">
                <div>
                  <span className="text-muted text-sm block">{t('tenantdashboard.status', { defaultValue: `Status` })}</span>
                  <span className={`inline-flex px-3 py-1 rounded-full text-xs font-bold ${
                    contract.status === 'Approved' || contract.status === 'Active' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'
                  }`}>
                    {contract.status.replace('_', ' ')}
                  </span>
                </div>
                <div>
                  <span className="text-muted text-sm block">{t('tenantdashboard.duration', { defaultValue: `Duration` })}</span>
                  <span className="text-white font-medium">{contract.start_date} {t('tenantdashboard.to', { defaultValue: `to` })} {contract.end_date}</span>
                </div>
                {contract.status === 'Pending_Signature' && (
                  <div className="mt-4 p-4 bg-warning/10 border border-warning/20 rounded-xl">
                    <p className="text-warning text-sm flex items-start gap-2">
                      <AlertCircle size={16} className="shrink-0 mt-0.5" />
                      {t('tenantdashboard.your_contract_is_pending_signa', { defaultValue: `Your contract is pending signature. Please go to the "My Contract" page to sign it.` })}
                    </p>
                  </div>
                )}
              </div>
            </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="glass-card p-8 text-center text-muted">
            <Home className="mx-auto mb-4 text-slate-500" size={48} />
            <p>{t('tenantdashboard.you_do_not_have_any_active_ren', { defaultValue: `You do not have any active rental contracts assigned to you.` })}</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default TenantDashboard;
