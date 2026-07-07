import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../../api/axios';
import { FileText, Download, Upload, CheckCircle2 } from 'lucide-react';

const TenantContract = () => {
  const { t } = useTranslation();

  const queryClient = useQueryClient();
  const fileInputRef = React.useRef(null);
  const [signatureDataUrl] = useState(''); // Would be a canvas or base64 input in reality

  const { data, isLoading } = useQuery({ 
    queryKey: ['tenant-dashboard'], 
    queryFn: async () => (await api.get('/tenant-portal/dashboard')).data 
  });

  const signMutation = useMutation({
    mutationFn: (payload) => api.post('/tenant-portal/contract/sign', payload),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenant-dashboard']);
      alert('Contract signed and uploaded successfully! Pending admin approval.');
    }
  });

  const renewMutation = useMutation({
    mutationFn: (payload) => api.post('/tenant-portal/renewal/request', payload),
    onSuccess: () => alert('Renewal requested!')
  });

  const declineMutation = useMutation({
    mutationFn: (payload) => api.post('/tenant-portal/renewal/decline', payload),
    onSuccess: () => alert('Renewal declined.')
  });

  if (isLoading) return <div className="p-8 text-muted">{t('tenantcontract.loading', { defaultValue: `Loading...` })}</div>;

  const contracts = data?.contracts || [];

  const generatePDF = (contract) => {
    const printWindow = window.open('', '', 'width=800,height=900');
    printWindow.document.write(`
      <html>
        <head>
          <title>Rental Contract - ${contract.building_name} Apt CFA ${contract.apartment_code}</title>
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

  const handleSign = (contract_id) => {
    // In a real app, user would draw signature and it would be converted to base64.
    const fakeBase64 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
    signMutation.mutate({ contract_id: contract_id, document_url: fakeBase64 });
  };

  const handleFileUpload = (e, contract_id) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        signMutation.mutate({ contract_id: contract_id, document_url: reader.result });
      };
      reader.readAsDataURL(file);
    }
  };

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
            <FileText className="me-3 text-primary" size={32} />
            {t('tenantcontract.my_contract', { defaultValue: `My Contract` })}
          </h1>
          <p className="text-muted">{t('tenantcontract.review_sign_and_manage_your_re', { defaultValue: `Review, sign, and manage your rental contract.` })}</p>
        </div>

        {contracts.length > 0 ? (
          <div className="space-y-12 max-w-4xl">
            {contracts.map(contract => (
              <div key={contract.id} className="space-y-6 pb-12 border-b border-slate-800/50 last:border-0">
            <div className="glass-card p-8 text-center text-white border-2 border-dashed border-slate-700">
              <FileText className="mx-auto mb-4 text-slate-400" size={64} />
              <h3 className="text-xl font-bold mb-2">{t('tenantcontract.rental_agreement', { defaultValue: `Rental Agreement -` })} {contract.building_name} {t('tenantcontract.apt', { defaultValue: `Apt` })} {contract.apartment_code}</h3>
              <p className="text-muted mb-6">{t('tenantcontract.start_date', { defaultValue: `Start Date:` })} {contract.start_date} {t('tenantcontract.end_date', { defaultValue: `| End Date:` })} {contract.end_date}</p>
              
              <div className="flex justify-center gap-4">
                <button onClick={() => generatePDF(contract)} className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-xl flex items-center gap-2 transition-colors">
                  <Download size={20} />
                  <span>{t('tenantcontract.download_pdf', { defaultValue: `Download PDF` })}</span>
                </button>
              </div>
            </div>

            {contract.status === 'Pending_Signature' && (
              <div className="glass-card p-8 animate-in fade-in">
                <h3 className="text-xl font-bold text-white mb-4">{t('tenantcontract.digital_signature_required', { defaultValue: `Digital Signature Required` })}</h3>
                <p className="text-muted mb-6">{t('tenantcontract.please_sign_below_to_accept_th', { defaultValue: `Please sign below to accept the terms and conditions of your rental agreement.` })}</p>
                
                {/* Fake canvas area */}
                <div className="w-full h-48 bg-white/5 border border-slate-600 rounded-xl mb-4 flex items-center justify-center text-slate-500">
                  {t('tenantcontract.signature_canvas_area', { defaultValue: `[ Signature Canvas Area ]` })}
                </div>
                
                <div className="flex justify-end gap-4 mt-6">
                  <input 
                    type="file" 
                    accept="image/*,.pdf" 
                    className="hidden" 
                    ref={fileInputRef} 
                    onChange={(e) => handleFileUpload(e, contract.id)} 
                  />
                  <button onClick={() => fileInputRef.current.click()} className="bg-slate-800 hover:bg-slate-700 text-white px-6 py-2 rounded-xl border border-slate-700 transition-colors flex items-center gap-2">
                    <Upload size={18} /> {t('tenantcontract.upload_scanned_document', { defaultValue: `Upload Scanned Document` })}
                  </button>
                  <button onClick={() => handleSign(contract.id)} className="bg-primary hover:bg-indigo-600 text-white px-6 py-2 rounded-xl transition-colors shadow-lg shadow-primary/20">
                    {t('tenantcontract.submit_signature', { defaultValue: `Submit Signature` })}
                  </button>
                </div>
              </div>
            )}

            {(contract.status === 'Signed' || contract.status === 'Approved') && (
              <div className="glass-card p-6 border border-success/30 bg-success/5">
                <div className="flex items-center gap-3">
                  <CheckCircle2 className="text-success" size={24} />
                  <div>
                    <h3 className="text-lg font-bold text-success">{t('tenantcontract.contract_signed', { defaultValue: `Contract Signed` })}</h3>
                    <p className="text-sm text-success/80">
                      {contract.status === 'Signed' ? 'Your contract has been signed and is pending final manager approval.' : 'Your contract is fully approved and active!'}
                    </p>
                  </div>
                </div>
              </div>
            )}

            {/* Renewal Options if expiring soon */}
            {contract.status === 'Active' && (
              <div className="glass-card p-6 mt-8">
                <h3 className="text-xl font-bold text-white mb-4">{t('tenantcontract.contract_renewal', { defaultValue: `Contract Renewal` })}</h3>
                <p className="text-muted mb-4">{t('tenantcontract.if_your_contract_is_nearing_it', { defaultValue: `If your contract is nearing its end date, you can request a renewal or submit a notice of non-renewal.` })}</p>
                <div className="flex gap-4">
                  <button onClick={() => renewMutation.mutate({ contract_id: contract.id })} className="bg-indigo-500 hover:bg-indigo-600 text-white px-6 py-2 rounded-lg transition-colors">
                    {t('tenantcontract.request_renewal', { defaultValue: `Request Renewal` })}
                  </button>
                  <button onClick={() => declineMutation.mutate({ contract_id: contract.id })} className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-lg transition-colors">
                    {t('tenantcontract.decline_renewal', { defaultValue: `Decline Renewal` })}
                  </button>
                </div>
              </div>
            )}
              </div>
            ))}
          </div>
        ) : (
          <div className="glass-card p-8 text-center text-muted">
            <p>{t('tenantcontract.you_do_not_have_any_active_ren', { defaultValue: `You do not have any active rental contracts.` })}</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default TenantContract;
