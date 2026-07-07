import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { FileText, Plus, Check, X, FileCheck2, Eye, Download, Building, Home, Users, DollarSign, Activity, Calendar, AlertCircle, RefreshCw, Pause, StopCircle, Play, Edit } from 'lucide-react';
import { differenceInDays } from 'date-fns';

const Contracts = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [showAdd, setShowAdd] = useState(false);
  const [formData, setFormData] = useState({
    building_id: '',
    apartment_id: '',
    tenant_id: '',
    start_date: '',
    end_date: '',
    monthly_rent: '',
    monthly_insurance: '',
    payment_terms: '',
    payment_method_rule: 'Any Method'
  });
  const [rentManageModal, setRentManageModal] = useState(null);
  const [updateContractModal, setUpdateContractModal] = useState(null);
  const [updateFormData, setUpdateFormData] = useState({
    monthly_rent: '', monthly_insurance: '', start_date: '', end_date: '', payment_terms: '', payment_method_rule: 'Any Method'
  });

  const { data: contracts, isLoading } = useQuery({ 
    queryKey: ['contracts'], 
    queryFn: async () => (await api.get('/contracts')).data 
  });
  
  const { data: buildings } = useQuery({ queryKey: ['buildings'], queryFn: async () => (await api.get('/buildings')).data });
  const { data: allApartments } = useQuery({ queryKey: ['apartments'], queryFn: async () => (await api.get('/apartments')).data });
  const { data: tenants } = useQuery({ queryKey: ['tenants'], queryFn: async () => (await api.get('/tenants')).data });

  const addMutation = useMutation({
    mutationFn: (data) => api.post('/contracts', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['contracts']);
      queryClient.invalidateQueries(['apartments']);
      setShowAdd(false);
      setFormData({
        building_id: '', apartment_id: '', tenant_id: '',
        start_date: '', end_date: '', monthly_rent: '', monthly_insurance: '', payment_terms: '', payment_method_rule: 'Any Method'
      });
    }
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }) => api.put(`/contracts/${id}/status`, { status }),
    onSuccess: () => {
      queryClient.invalidateQueries(['contracts']);
      queryClient.invalidateQueries(['apartments']);
      queryClient.invalidateQueries(['dashboard']);
      alert('Status updated successfully!');
    }
  });

  const rentActionMutation = useMutation({
    mutationFn: ({ id, action }) => api.put(`/contracts/${id}/${action}`),
    onSuccess: () => {
      queryClient.invalidateQueries(['contracts']);
      setRentManageModal(null);
      alert('Rent status updated successfully!');
    }
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }) => api.put(`/contracts/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['contracts']);
      setUpdateContractModal(null);
      alert('Contract updated successfully!');
    }
  });

  const renewRentMutation = useMutation({
    mutationFn: (id) => api.post(`/contracts/${id}/renew-rent-manually`),
    onSuccess: () => {
      queryClient.invalidateQueries(['contracts']);
      setRentManageModal(null);
      alert('Rent manually renewed successfully!');
    }
  });

  const handleApartmentSelect = (aptId) => {
    const apt = allApartments?.find(a => a.id == aptId);
    if (apt) {
      setFormData({
        ...formData,
        apartment_id: aptId,
        monthly_rent: apt.monthly_rent,
        monthly_insurance: apt.monthly_insurance
      });
    }
  };

  const generatePDF = (contract) => {
    // Open a print window with the contract details
    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
      <html>
        <head>
          <title>Rental Contract - ${contract.building_name} Apt CFA ${contract.apartment_code}</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 40px; color: #333; line-height: 1.6; }
            h1 { text-align: center; color: #1e3a8a; }
            .section { margin-bottom: 20px; }
            .label { font-weight: bold; width: 200px; display: inline-block; }
            .footer { margin-top: 50px; display: flex; justify-content: space-between; }
            .signature-box { border-top: 1px solid #000; width: 200px; padding-top: 10px; text-align: center; }
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
            <div><span class="label">Phone:</span> CFA ${contract.phone || 'N/A'}</div>
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

  if (isLoading) return <div className="p-8 text-muted">Loading contracts...</div>;

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

  const vacantApartments = allApartments?.filter(a => a.status === 'Vacant' && (!formData.building_id || a.building_id == formData.building_id));

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h2 className="text-2xl font-bold text-white flex items-center gap-3">
            <FileText className="text-primary" size={26} /> Active Contracts
          </h2>
          <p className="text-muted mt-1">Manage rental contracts and approvals.</p>
        </div>
        <button 
          onClick={() => setShowAdd(!showAdd)}
          className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors shadow-lg shadow-primary/20"
        >
          <Plus size={20} />
            <span>Create Rental Contract</span>
          </button>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4">
            <h3 className="text-xl font-bold text-white mb-6">New Rental Workflow</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Select Building</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.building_id} onChange={e => setFormData({...formData, building_id: e.target.value, apartment_id: ''})}>
                  <option value="">-- All Buildings --</option>
                  {buildings?.map(b => <option key={b.id} value={b.id}>{b.name}</option>)}
                </select>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Select Apartment</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.apartment_id} onChange={e => handleApartmentSelect(e.target.value)}>
                  <option value="">-- Select Vacant Apartment --</option>
                  {vacantApartments?.map(a => <option key={a.id} value={a.id}>{a.code} (Rent: CFA {a.monthly_rent})</option>)}
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-muted mb-1">Select Tenant</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.tenant_id} onChange={e => setFormData({...formData, tenant_id: e.target.value})}>
                  <option value="">-- Select Existing Tenant --</option>
                  {tenants?.map(t => <option key={t.id} value={t.id}>{t.full_name} ({t.national_id})</option>)}
                </select>
                <p className="text-xs text-muted mt-1">Tenant must be registered in the system first.</p>
              </div>

              <div className="hidden md:block"></div> {/* Spacer */}

              <div>
                <label className="block text-sm font-medium text-muted mb-1">Contract Start Date</label>
                <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.start_date} onChange={e => setFormData({...formData, start_date: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Contract End Date</label>
                <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.end_date} onChange={e => setFormData({...formData, end_date: e.target.value})} />
              </div>

              <div>
                <label className="block text-sm font-medium text-muted mb-1">Monthly Rent Amount</label>
                <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.monthly_rent} onChange={e => setFormData({...formData, monthly_rent: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-muted mb-1">Insurance Deposit Amount</label>
                <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.monthly_insurance} onChange={e => setFormData({...formData, monthly_insurance: e.target.value})} />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-muted mb-1">Payment Method Rule</label>
                <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.payment_method_rule} onChange={e => setFormData({...formData, payment_method_rule: e.target.value})}>
                  <option value="Any Method">Any Method (Follow Tenant Default)</option>
                  <option value="Bank Transfer Only">Bank Transfer Only</option>
                  <option value="Cash Only">Cash Only</option>
                  <option value="Mobile Money Only">Mobile Money Only</option>
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-medium text-muted mb-1">Payment Terms</label>
                <textarea rows="3" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" value={formData.payment_terms} onChange={e => setFormData({...formData, payment_terms: e.target.value})} placeholder="E.g., Payment due on the 1st of every month..." />
              </div>
            </div>
            
            <div className="flex justify-end gap-3 pt-4 border-t border-slate-700/50">
              <button onClick={() => setShowAdd(false)} className="bg-slate-700 hover:bg-slate-600 text-white px-6 py-2 rounded-lg transition-colors">Cancel</button>
              <button onClick={() => addMutation.mutate(formData)} className="bg-success hover:bg-green-600 text-white px-6 py-2 rounded-lg transition-colors">Create Contract Draft</button>
            </div>
          </div>
        )}

        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Contract Info</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Tenant</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Dates</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Rent / Ins.</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Status</th>
                <th className="px-6 py-4 text-end text-xs font-semibold text-muted uppercase tracking-wider">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {contracts?.map(contract => (
                <tr key={contract.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-white">{contract.building_name}</div>
                    <div className="text-sm text-slate-400">Apt {contract.apartment_code}</div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="text-white">{contract.tenant_name}</div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-300">
                    <div>{contract.start_date}</div>
                    <div className="text-slate-500 flex items-center gap-2 mt-0.5">
                      <span>to {contract.end_date}</span>
                      {(() => {
                        if (!contract.end_date) return null;
                        const daysLeft = differenceInDays(new Date(contract.end_date), new Date());
                        if (daysLeft < 0) return <span className="bg-red-500/20 text-red-400 text-[10px] px-2 py-0.5 rounded-full font-bold tracking-wider">OVERDUE</span>;
                        if (daysLeft <= 7) return <span className="bg-orange-500/20 text-orange-400 text-[10px] px-2 py-0.5 rounded-full font-bold tracking-wider">EXP IN {daysLeft}D</span>;
                        if (daysLeft <= 30) return <span className="bg-indigo-500/20 text-indigo-400 text-[10px] px-2 py-0.5 rounded-full font-bold tracking-wider">{daysLeft}D LEFT</span>;
                        return null;
                      })()}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-sm text-slate-300">
                    <div className="font-medium text-white mb-1">CFA {contract.monthly_rent}</div>
                    <div className="text-slate-400 text-xs flex items-center justify-between">
                      <span>Ins: CFA {contract.monthly_insurance}</span>
                      <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${contract.insurance_status === 'Paid' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'}`}>
                        {contract.insurance_status || 'Pending Payment'}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-col gap-1 items-start">
                      {getStatusBadge(contract.status)}
                      {contract.status === 'Active' && (
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                          contract.rent_status === 'Active' ? 'bg-blue-500/20 text-blue-400' :
                          contract.rent_status === 'Paused' ? 'bg-yellow-500/20 text-yellow-400' :
                          'bg-slate-500/20 text-slate-400'
                        }`}>
                          Rent: {contract.rent_status}
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="px-6 py-4 text-end text-sm">
                    <div className="flex justify-end gap-2">
                      {contract.status === 'Active' && (
                        <button onClick={() => setRentManageModal(contract)} className="text-blue-400 hover:text-blue-300 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Manage Rent">
                          <DollarSign size={18} />
                        </button>
                      )}
                      <button onClick={() => generatePDF(contract)} className="text-indigo-400 hover:text-indigo-300 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Download PDF">
                        <Download size={18} />
                      </button>
                      <button onClick={() => {
                        setUpdateContractModal(contract);
                        setUpdateFormData({
                          monthly_rent: contract.monthly_rent,
                          monthly_insurance: contract.monthly_insurance,
                          start_date: contract.start_date,
                          end_date: contract.end_date,
                          payment_terms: contract.payment_terms || ''
                        });
                      }} className="text-emerald-400 hover:text-emerald-300 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Update Contract">
                        <Edit size={18} />
                      </button>

                      {contract.status === 'Draft' && (
                        <button onClick={() => updateStatusMutation.mutate({id: contract.id, status: 'Pending_Signature'})} className="text-warning hover:text-warning/80 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Request Signature">
                          <FileCheck2 size={18} />
                        </button>
                      )}
                      
                      {contract.status === 'Signed' && (
                        <>
                          <button onClick={() => updateStatusMutation.mutate({id: contract.id, status: 'Approved'})} className="text-success hover:text-green-400 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Approve">
                            <Check size={18} />
                          </button>
                          <button onClick={() => updateStatusMutation.mutate({id: contract.id, status: 'Rejected'})} className="text-danger hover:text-red-400 p-2 transition-colors rounded-lg hover:bg-slate-800" title="Reject">
                            <X size={18} />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          {contracts?.length === 0 && <div className="p-8 text-center text-muted">No contracts found.</div>}
        </div>

        {/* Rent Management Modal */}
        {rentManageModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl">
              <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/30">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <DollarSign className="text-blue-400" size={24} /> 
                  Rent Management
                </h3>
                <button onClick={() => setRentManageModal(null)} className="text-slate-400 hover:text-white transition-colors">
                  <X size={24} />
                </button>
              </div>
              <div className="p-6 space-y-6">
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700">
                  <p className="text-sm text-slate-400 mb-1">Current Rent Status</p>
                  <p className="text-lg font-bold text-white">{rentManageModal.rent_status}</p>
                </div>
                
                <div className="flex flex-col gap-3">
                  {rentManageModal.rent_status === 'Active' && (
                    <button onClick={() => rentActionMutation.mutate({ id: rentManageModal.id, action: 'pause-rent' })} className="flex items-center justify-between w-full bg-yellow-500/20 hover:bg-yellow-500/30 text-yellow-400 border border-yellow-500/30 px-4 py-3 rounded-xl transition-colors text-left">
                      <div>
                        <p className="font-bold">Pause Rent Generation</p>
                        <p className="text-xs opacity-80">Stop generating new invoices temporarily</p>
                      </div>
                      <Pause size={20} />
                    </button>
                  )}
                  {rentManageModal.rent_status === 'Paused' && (
                    <button onClick={() => rentActionMutation.mutate({ id: rentManageModal.id, action: 'resume-rent' })} className="flex items-center justify-between w-full bg-blue-500/20 hover:bg-blue-500/30 text-blue-400 border border-blue-500/30 px-4 py-3 rounded-xl transition-colors text-left">
                      <div>
                        <p className="font-bold">Resume Rent Generation</p>
                        <p className="text-xs opacity-80">Continue generating invoices normally</p>
                      </div>
                      <Play size={20} />
                    </button>
                  )}
                  {rentManageModal.rent_status !== 'Ended' && (
                    <button onClick={() => { if(window.confirm('Are you sure? Rent generation will permanently stop for this contract.')) rentActionMutation.mutate({ id: rentManageModal.id, action: 'end-rent' }) }} className="flex items-center justify-between w-full bg-red-500/20 hover:bg-red-500/30 text-red-400 border border-red-500/30 px-4 py-3 rounded-xl transition-colors text-left">
                      <div>
                        <p className="font-bold">End Rent Cycle</p>
                        <p className="text-xs opacity-80">Permanently stop rent for this contract</p>
                      </div>
                      <StopCircle size={20} />
                    </button>
                  )}
                  <button onClick={() => renewRentMutation.mutate(rentManageModal.id)} className="flex items-center justify-between w-full bg-slate-800 hover:bg-slate-700 text-white border border-slate-700 px-4 py-3 rounded-xl transition-colors text-left">
                    <div>
                      <p className="font-bold">Manually Renew Rent Now</p>
                      <p className="text-xs text-slate-400">Generate the next invoice immediately</p>
                    </div>
                    <RefreshCw size={20} className="text-slate-400" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
  );
};

export default Contracts;
