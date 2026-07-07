import { useTranslation } from 'react-i18next';
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { FileText, Check, X, FileCheck2, Download, Trash2 } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const PendingContracts = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const navigate = useNavigate();

  const { data: contracts, isLoading } = useQuery({
    queryKey: ['pending-contracts'],
    queryFn: async () => (await api.get('/contracts/pending')).data
  });

  const updateStatusMutation = useMutation({
    mutationFn: (data) => api.put(`/contracts/${data.id}/status`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['pending-contracts']);
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => api.delete(`/contracts/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['pending-contracts']);
      queryClient.invalidateQueries(['contracts']);
    }
  });

  const getStatusBadge = (status) => {
    const styles = {
      'Draft': 'bg-slate-700 text-slate-300',
      'Pending_Signature': 'bg-warning/20 text-warning border border-warning/30',
      'Signed': 'bg-info/20 text-info border border-info/30',
      'Approved': 'bg-success/20 text-success border border-success/30',
      'Rejected': 'bg-danger/20 text-danger border border-danger/30',
      'Expired': 'bg-slate-800 text-slate-500',
      'Renewal_Pending': 'bg-purple-500/20 text-purple-400 border border-purple-500/30'
    };
    return <span className={`px-3 py-1 rounded-full text-xs font-semibold ${styles[status] || styles['Draft']}`}>{status.replace('_', ' ')}</span>;
  };

  const generatePDF = (contract) => {
    const printWindow = window.open('', '', 'width=800,height=900');
    printWindow.document.write(`
      <html>
        <head>
          <title>Rental Contract - ${contract.tenant_name}</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 40px; color: #333; line-height: 1.6; }
            h1 { text-align: center; border-bottom: 2px solid #333; padding-bottom: 10px; }
            h2 { color: #4f46e5; margin-top: 30px; }
            .section { margin-bottom: 25px; }
            .label { font-weight: bold; width: 150px; display: inline-block; }
            .footer { margin-top: 50px; display: flex; justify-content: space-between; }
            .signature-box { border-top: 1px solid #333; width: 250px; text-align: center; padding-top: 10px; margin-top: 60px; }
          </style>
        </head>
        <body>
          <h1>Property Rental Agreement</h1>
          <hr />
          <div class="section">
            <h2>Property Details</h2>
            <div><span class="label">Building:</span> CFA ${contract.building_name}</div>
            <div><span class="label">Apartment Number:</span> CFA ${contract.apartment_code}</div>
          </div>
          <div class="section">
            <h2>Tenant Details</h2>
            <div><span class="label">Full Name:</span> CFA ${contract.tenant_name}</div>
          </div>
          <div class="section">
            <h2>Contract Terms</h2>
            <div><span class="label">Start Date:</span> CFA ${contract.start_date}</div>
            <div><span class="label">End Date:</span> CFA ${contract.end_date}</div>
            <div><span class="label">Monthly Rent:</span> CFA ${contract.monthly_rent}</div>
            <div><span class="label">Security Deposit:</span> CFA ${contract.monthly_insurance}</div>
          </div>
          <div class="section">
            <h2>Payment Terms</h2>
            <p>CFA ${contract.payment_terms || 'Standard payment terms apply.'}</p>
          </div>
          <div class="footer">
            <div class="signature-box">Landlord Signature</div>
            <div class="signature-box">Tenant Signature</div>
          </div>
          <script>
            window.onload = () => { window.print(); window.close(); }
          </script>
        </body>
      </html>
    `);
    printWindow.document.close();
  };

  if (isLoading) return <div className="p-8 text-muted">{t('pendingcontracts.loading_pending_contracts', { defaultValue: `Loading pending contracts...` })}</div>;

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <FileCheck2 className="text-warning" size={26} /> {t('pendingcontracts.pending_actions', { defaultValue: `Pending Actions` })}
          </h2>
          <p className="text-muted mt-1">{t('pendingcontracts.contracts_awaiting_signature_o', { defaultValue: `Contracts awaiting signature or approval.` })}</p>
        </div>
      </div>

        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('pendingcontracts.id_info', { defaultValue: `ID & Info` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('pendingcontracts.tenant', { defaultValue: `Tenant` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('pendingcontracts.dates', { defaultValue: `Dates` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('pendingcontracts.rent_ins', { defaultValue: `Rent / Ins.` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('pendingcontracts.status', { defaultValue: `Status` })}</th>
                <th className="px-6 py-4 text-end text-xs font-semibold text-muted uppercase tracking-wider">{t('pendingcontracts.actions', { defaultValue: `Actions` })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {contracts?.map(contract => (
                <tr key={contract.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="text-xs text-slate-400 mb-1">#{contract.id}</div>
                    <div className="font-medium text-white">{contract.building_name}</div>
                    <div className="text-sm text-slate-400">{t('pendingcontracts.apt', { defaultValue: `Apt` })} {contract.apartment_code}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div 
                      className="text-white hover:text-primary cursor-pointer font-medium"
                      onClick={() => navigate(`/tenants/${contract.tenant_id}`)}
                    >
                      {contract.tenant_name}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-300">
                    <div>{contract.start_date}</div>
                    <div className="text-slate-500">{t('pendingcontracts.to', { defaultValue: `to` })} {contract.end_date}</div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-300">
                    <div>{t('pendingcontracts.cfa', { defaultValue: `CFA` })} {contract.monthly_rent}</div>
                    <div className="text-slate-500 text-xs">{t('pendingcontracts.ins_cfa', { defaultValue: `Ins: CFA` })} {contract.monthly_insurance}</div>
                  </td>
                  <td className="px-6 py-4">
                    {getStatusBadge(contract.status)}
                  </td>
                  <td className="px-6 py-4 text-end text-sm">
                    <div className="flex justify-end gap-2">
                      <button onClick={() => generatePDF(contract)} className="text-indigo-400 hover:text-indigo-300 p-2 transition-colors rounded-lg hover:bg-slate-800" title={t('pendingcontracts.view_download_contract', { defaultValue: `View/Download Contract` })}>
                        <Download size={18} />
                      </button>

                      {(contract.status === 'Signed' || contract.status === 'Renewal_Pending') && (
                        <>
                          <button onClick={() => updateStatusMutation.mutate({id: contract.id, status: 'Approved'})} className="text-success hover:text-green-400 p-2 transition-colors rounded-lg hover:bg-slate-800" title={t('pendingcontracts.approve', { defaultValue: `Approve` })}>
                            <Check size={18} />
                          </button>
                          <button onClick={() => updateStatusMutation.mutate({id: contract.id, status: 'Rejected'})} className="text-danger hover:text-red-400 p-2 transition-colors rounded-lg hover:bg-slate-800" title={t('pendingcontracts.reject', { defaultValue: `Reject` })}>
                            <X size={18} />
                          </button>
                        </>
                      )}
                      
                      <button 
                        onClick={() => { if(window.confirm('Are you sure you want to permanently delete this pending contract?')) deleteMutation.mutate(contract.id); }} 
                        className="text-danger hover:text-red-400 p-2 transition-colors rounded-lg hover:bg-slate-800" 
                        title={t('pendingcontracts.delete_contract', { defaultValue: `Delete Contract` })}
                      >
                        <Trash2 size={18} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {contracts?.length === 0 && (
            <div className="p-12 text-center">
              <div className="bg-success/10 text-success p-4 rounded-full inline-block mb-4">
                <Check size={32} />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">{t('pendingcontracts.all_caught_up', { defaultValue: `All Caught Up!` })}</h3>
              <p className="text-muted">{t('pendingcontracts.there_are_no_pending_contracts', { defaultValue: `There are no pending contracts requiring action.` })}</p>
            </div>
          )}
        </div>
    </div>
  );
};

export default PendingContracts;
