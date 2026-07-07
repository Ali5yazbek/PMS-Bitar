import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { ArrowLeft, User, DollarSign, Printer, PlusCircle, Edit, Zap, ChevronRight, Home, FileText, Shield, Wrench, Folder, Check, AlertCircle, RefreshCw, Calendar, X } from 'lucide-react';

const TenantDetails = () => {
  const { t } = useTranslation();

  const { id } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [activeTab, setActiveTab] = useState('Personal Information');
  
  // Modals state
  const [printSelection, setPrintSelection] = useState({ id: null, type: null });
    const [elecPayModal, setElecPayModal] = useState(null);
  const [elecPayAmount, setElecPayAmount] = useState('');
  const [meterReadingModal, setMeterReadingModal] = useState(false);
  const [meterForm, setMeterForm] = useState({ previous_reading: 0, current_reading: '', price_per_kwh: '', reading_date: new Date().toISOString().split('T')[0] });
const [rentFilter, setRentFilter] = useState('');
  const [elecFilter, setElecFilter] = useState('');
  const [paymentModal, setPaymentModal] = useState(null);
  const [showAddHistorical, setShowAddHistorical] = useState(false);
  const [showNewContract, setShowNewContract] = useState(false);
  const [renewModal, setRenewModal] = useState(null);
  const [paymentData, setPaymentData] = useState({ amount: '', notes: '', payment_method: 'Cash', bank_name: '', reference_number: '', proof_of_payment: '' });
  const [historicalData, setHistoricalData] = useState({ due_date: '', amount: '', is_paid: false });
  const [newContractData, setNewContractData] = useState({ apartment_id: '', start_date: '', end_date: '', monthly_rent: '', monthly_insurance: '' });
  const [showEditContract, setShowEditContract] = useState(false);
  const [contractData, setContractData] = useState({ start_date: '', end_date: '' });

  const { data: tenant, isLoading: loadingTenant } = useQuery({
    queryKey: ['tenant', id],
    queryFn: async () => (await api.get(`/tenants/${id}`)).data
  });

  const { data: history, isLoading: loadingHistory } = useQuery({ 
    queryKey: ['tenantHistory', id], 
    queryFn: async () => (await api.get(`/tenants/${id}/rent-history`)).data 
  });

  const { data: insuranceAccounts, isLoading: loadingInsurance } = useQuery({
    queryKey: ['tenantInsurance', id],
    queryFn: async () => (await api.get(`/insurance/by-tenant/${id}`)).data
  });

  const { data: vacantApartments } = useQuery({ 
    queryKey: ['apartments', 'vacant'], 
    queryFn: async () => {
      const res = await api.get('/apartments');
      return res.data.filter(a => a.status === 'Vacant');
    }
  });

  
  const { data: electricitySubscription } = useQuery({
    queryKey: ['electricitySubscription', tenant?.apartment_id],
    queryFn: async () => (await api.get(`/energy/apartments/${tenant.apartment_id}/subscriptions`)).data,
    enabled: !!tenant?.apartment_id
  });

  const { data: latestReading } = useQuery({
    queryKey: ['latestReading', tenant?.apartment_id],
    queryFn: async () => (await api.get(`/energy/apartments/${tenant.apartment_id}/meter-readings/latest`)).data,
    enabled: !!tenant?.apartment_id
  });
const { data: electricityInvoices } = useQuery({
    queryKey: ['electricityInvoices', tenant?.apartment_id],
    queryFn: async () => (await api.get(`/electricity/apartments/${tenant.apartment_id}/invoices`)).data,
    enabled: !!tenant?.apartment_id
  });

  const { data: rentProfile, isLoading: loadingProfile } = useQuery({
    queryKey: ['tenantRentProfile', id],
    queryFn: async () => (await api.get(`/rent-profiles/tenant/${id}`)).data
  });

  const updateRentProfileMutation = useMutation({
    mutationFn: (data) => api.put(`/rent-profiles/${rentProfile.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenantRentProfile', id]);
      queryClient.invalidateQueries(['dashboardStats']);
    }
  });

  // Queries for other tabs (Mocked or real endpoints)
  const { data: contractsData } = useQuery({
    queryKey: ['tenantContracts', id],
    queryFn: async () => (await api.get(`/contracts`)).data.filter(c => String(c.tenant_id) === String(id)),
    enabled: !!tenant
  });

  const payMutation = useMutation({
    mutationFn: (data) => api.post('/rent/payment', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenantHistory', id]);
      setPaymentModal(null);
      setPaymentData({ amount: '', notes: '' });
    }
  });


  const renewSubMutation = useMutation({
    mutationFn: () => api.post(`/energy/apartments/${tenant.apartment_id}/renew-subscription`),
    onSuccess: () => {
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
    }
  });

  const submitReadingMutation = useMutation({
    mutationFn: (data) => api.post(`/energy/apartments/${tenant.apartment_id}/meter-readings`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['latestReading', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricitySubscription', tenant?.apartment_id]);
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setMeterReadingModal(false);
    }
  });

  const payElecMutation = useMutation({
    mutationFn: ({ id, amount }) => api.put(`/electricity/invoices/${id}/pay`, { amount_paid: amount }),
    onSuccess: () => {
      queryClient.invalidateQueries(['electricityInvoices', tenant?.apartment_id]);
      setElecPayModal(null);
    }
  });


  const historicalMutation = useMutation({
    mutationFn: (data) => api.post('/rent/historical', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenantHistory', id]);
      setShowAddHistorical(false);
      setHistoricalData({ due_date: '', amount: '', is_paid: true });
    }
  });

  const updateContractMutation = useMutation({
    mutationFn: (data) => api.put(`/tenants/${id}/contract`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenant', id]);
      setShowEditContract(false);
    }
  });

  const renewMutation = useMutation({
    mutationFn: ({ contractId, data }) => api.post(`/contracts/${contractId}/renew`, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenant', id]);
      queryClient.invalidateQueries(['tenantContracts', id]);
      queryClient.invalidateQueries(['tenantHistory', id]);
      setRenewModal(null);
      alert('Contract renewed successfully');
    }
  });

  const handleOpenRenew = (contractId, endDate) => {
    const startDate = endDate;
    const end = new Date(startDate);
    end.setFullYear(end.getFullYear() + 1);
    
    setRenewModal({
      contractId: contractId,
      start_date: startDate,
      end_date: end.toISOString().split('T')[0]
    });
  };

  const generateMissingRentMutation = useMutation({
    mutationFn: (contractId) => api.post(`/contracts/${contractId}/generate-rent`),
    onSuccess: (data) => {
      queryClient.invalidateQueries(['tenantHistory', id]);
      queryClient.invalidateQueries(['dashboardStats']);
      alert(data.data.message || 'Rent detected and generated!');
    },
    onError: (error) => {
      alert(error.response?.data?.error || 'Failed to detect rent');
    }
  });

  const createContractMutation = useMutation({
    mutationFn: (data) => api.post('/contracts', { ...data, tenant_id: id }),
    onSuccess: () => {
      queryClient.invalidateQueries(['tenant', id]);
      queryClient.invalidateQueries(['tenantContracts', id]);
      queryClient.invalidateQueries(['apartments']);
      setShowNewContract(false);
      setNewContractData({ apartment_id: '', start_date: '', end_date: '', monthly_rent: '', monthly_insurance: '' });
      alert('New contract created successfully!');
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to create contract');
    }
  });

  const getStatusColor = (status) => {
    switch(status) {
      case 'Paid': return 'bg-success/20 text-success border border-success/30';
      case 'Unpaid': return 'bg-danger/20 text-danger border border-danger/30';
      case 'Partial': return 'bg-warning/20 text-warning border border-warning/30';
      case 'Overdue': return 'bg-danger text-white font-bold border border-danger shadow-lg shadow-danger/20';
      default: return 'bg-slate-800 text-slate-300 border border-slate-600';
    }
  };

  const handlePrint = (printId, type) => {
    setPrintSelection({ id: printId, type });
    setTimeout(() => window.print(), 100);
  };

  const generatePDF = (contract) => {
    const printWindow = window.open('', '', 'width=800,height=900');
    printWindow.document.write(`
      <html>
        <head>
          <title>Rental Contract - ${tenant?.full_name}</title>
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
            <div><span class="label">Full Name:</span> CFA ${tenant?.full_name}</div>
          </div>
          <div class="section">
            <h2>Contract Terms</h2>
            <div><span class="label">Start Date:</span> CFA ${contract.start_date}</div>
            <div><span class="label">End Date:</span> CFA ${contract.end_date}</div>
            <div><span class="label">Monthly Rent:</span> CFA ${contract.monthly_rent}</div>
            <div><span class="label">Security Deposit:</span> CFA ${contract.monthly_insurance}</div>
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

  if (loadingTenant || loadingHistory) return <div className="p-8 text-muted">{t('tenantdetails.loading_tenant_details', { defaultValue: `Loading tenant details...` })}</div>;

  const isExpiringSoon = (endDate) => {
    if (!endDate) return false;
    const end = new Date(endDate);
    const today = new Date();
    const diffTime = end - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays >= 0 && diffDays <= 7;
  };

  const filteredHistory = history?.filter(inv => {
    if (!rentFilter) return true;
    return inv.due_date.startsWith(rentFilter);
  });

  const filteredElectricity = electricityInvoices?.filter(inv => {
    if (!elecFilter) return true;
    return inv.due_date.startsWith(elecFilter);
  });

  const totalUnpaid = history?.reduce((acc, curr) => acc + Number(curr.outstanding_debt), 0) || 0;
  const totalPaid = history?.reduce((acc, curr) => acc + Number(curr.paid_amount), 0) || 0;

  // Print Logic Variables
  const invoicesToPrint = printSelection.type === 'rent_all'
    ? filteredHistory
    : printSelection.type === 'rent_single' 
      ? history?.filter(inv => inv.id === printSelection.id)
      : printSelection.type === 'elec_all'
        ? filteredElectricity
        : printSelection.type === 'elec_single'
          ? electricityInvoices?.filter(inv => inv.id === printSelection.id)
          : [];

  const printTotalUnpaid = printSelection.type?.startsWith('rent') 
    ? invoicesToPrint?.reduce((acc, curr) => acc + Number(curr.outstanding_debt), 0) || 0
    : invoicesToPrint?.filter(i => i.status !== 'Paid')?.reduce((acc, curr) => acc + Number(curr.amount), 0) || 0;
    
  const printTotalPaid = printSelection.type?.startsWith('rent')
    ? invoicesToPrint?.reduce((acc, curr) => acc + Number(curr.paid_amount), 0) || 0
    : invoicesToPrint?.filter(i => i.status === 'Paid')?.reduce((acc, curr) => acc + Number(curr.amount), 0) || 0;

  const tabs = [
    { id: 'Personal Information', icon: User },
    { id: 'Current Apartment', icon: Home },
    { id: 'Contracts', icon: FileText },
    { id: 'Payment History', icon: DollarSign },
    { id: 'Electricity', icon: Zap },
    { id: 'Insurance', icon: Shield },
    { id: 'Maintenance Requests', icon: Wrench },
    { id: 'Documents', icon: Folder }
  ];



  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="print:hidden">
          {/* Breadcrumbs */}
          <div className="flex items-center text-sm text-slate-400 mb-6 font-medium">
            <span className="cursor-pointer hover:text-indigo-400 transition-colors" onClick={() => navigate('/buildings')}>{t('tenantdetails.buildings', { defaultValue: `Buildings` })}</span>
            <ChevronRight size={14} className="mx-2" />
            <span className="cursor-pointer hover:text-indigo-400 transition-colors" onClick={() => navigate(`/buildings/${tenant?.building_id}`)}>{tenant?.building_name || 'Unassigned'}</span>
            <ChevronRight size={14} className="mx-2" />
            <span className="cursor-pointer hover:text-indigo-400 transition-colors">{t('tenantdetails.apt', { defaultValue: `Apt` })} {tenant?.apartment_code || 'N/A'}</span>
            <ChevronRight size={14} className="mx-2" />
            <span className="text-white">{tenant?.full_name}</span>
          </div>

          <div className="glass-card p-8 flex items-center justify-between mb-8">
            <div className="flex gap-6 items-center">
              <div className="bg-primary/20 p-5 rounded-full text-primary shadow-inner flex-shrink-0 border border-primary/20">
                <User size={48} />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-white flex items-center mb-2">
                  {tenant?.full_name}
                </h1>
                <div className="mt-2 text-sm flex items-center flex-wrap gap-2">
                  <span className={`inline-block px-3 py-1 rounded-full font-medium ${
                    tenant?.rent_status === 'Ended' ? 'bg-danger/20 text-danger border border-danger/30' :
                    tenant?.rent_status === 'Paused' ? 'bg-warning/20 text-warning border border-warning/30' :
                    (tenant?.contract_status === 'Active' || tenant?.contract_status === 'Approved') ? 'bg-success/20 text-success border border-success/30' : 
                    'bg-slate-800 text-slate-300 border border-slate-600'
                  }`}>
                    {tenant?.rent_status === 'Ended' ? 'Ended Rent' :
                     tenant?.rent_status === 'Paused' ? 'Paused Rent' :
                     (tenant?.contract_status === 'Active' || tenant?.contract_status === 'Approved') ? 'Active' : 'Inactive'}
                  </span>
                  
                  {(tenant?.contract_status === 'Active' || tenant?.contract_status === 'Approved') && tenant?.start_date && tenant?.end_date && (
                    <div className="flex items-center gap-3 ml-2">
                      <span className="text-slate-300 font-medium bg-slate-800/50 px-3 py-1 rounded-lg border border-slate-700">
                        {tenant.start_date} &rarr; {tenant.end_date}
                      </span>
                      
                      {isExpiringSoon(tenant.end_date) && (
                        <span className="text-danger flex items-center gap-1 font-bold bg-danger/10 px-3 py-1 rounded-full border border-danger/30" title={t('tenantdetails.expiring_within_7_days', { defaultValue: `Expiring within 7 days` })}>
                          <AlertCircle size={14} /> 
                          {(() => {
                            const diffDays = Math.ceil((new Date(tenant.end_date) - new Date()) / (1000 * 60 * 60 * 24));
                            return diffDays < 0 ? 'Expired' : `Ends in CFA ${diffDays} day${diffDays !== 1 ? 's' : ''}`;
                          })()}
                        </span>
                      )}

                      <button 
                        onClick={() => handleOpenRenew(tenant.contract_id, tenant.end_date)}
                        className="bg-primary/20 hover:bg-primary text-indigo-300 hover:text-white px-4 py-1 rounded-lg text-sm font-bold flex items-center gap-2 transition-all border border-primary/30 hover:border-primary"
                      >
                        <RefreshCw size={14} /> {t('tenantdetails.renew', { defaultValue: `Renew` })}
                      </button>
                    </div>
                  )}
                  {tenant?.generator_subscription === 'Active' && (
                    <span className="bg-primary/20 text-indigo-300 px-3 py-1 rounded-full border border-primary/30 flex items-center gap-1 font-medium">
                      <Zap size={14} /> {t('tenantdetails.generator_subscribed', { defaultValue: `Generator Subscribed` })}
                    </span>
                  )}
                </div>
              </div>
            </div>

            <div className="flex gap-3">
              <button 
                onClick={() => navigate('/financial-buildings-report')}
                className="bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-xl transition-colors font-medium flex items-center gap-2 border border-slate-700"
              >
                <DollarSign size={18} /> Financial Overview
              </button>
            </div>
          </div>

          {/* Tabs Navigation */}
          <div className="flex border-b border-slate-700/50 mb-8 overflow-x-auto hide-scrollbar">
            {tabs.map(tab => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 px-6 py-4 font-medium text-sm transition-all border-b-2 whitespace-nowrap ${
                    activeTab === tab.id 
                    ? 'border-primary text-primary bg-primary/5' 
                    : 'border-transparent text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
                  }`}
                >
                  <Icon size={18} />
                  {tab.id}
                </button>
              );
            })}
          </div>

          {/* Tab Content */}
          <div className="mb-8">
            {activeTab === 'Personal Information' && (
              <div className="glass-card p-8 max-w-3xl">
                <h2 className="text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-4">{t('tenantdetails.personal_information', { defaultValue: `Personal Information` })}</h2>
                <div className="grid grid-cols-2 gap-6">
                  <div>
                    <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.full_name', { defaultValue: `Full Name` })}</span>
                    <span className="text-lg text-white font-medium">{tenant?.full_name}</span>
                  </div>
                  <div>
                    <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.national_id_passport', { defaultValue: `National ID / Passport` })}</span>
                    <span className="text-lg text-white font-medium">{tenant?.national_id}</span>
                  </div>
                  <div>
                    <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.phone_number', { defaultValue: `Phone Number` })}</span>
                    <span className="text-lg text-white font-medium">{tenant?.phone}</span>
                  </div>
                  <div>
                    <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.email_address', { defaultValue: `Email Address` })}</span>
                    <span className="text-lg text-white font-medium">{tenant?.email || 'N/A'}</span>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'Current Apartment' && (
              <div className="glass-card p-8 max-w-3xl relative overflow-hidden">
                {(tenant?.contract_status === 'Active' || tenant?.contract_status === 'Approved') && isExpiringSoon(tenant?.end_date) && (
                  <div className="absolute top-0 left-0 right-0 bg-danger/20 border-b border-danger/50 text-danger px-6 py-3 flex justify-between items-center z-10">
                    <div className="flex items-center gap-2 font-semibold">
                      <AlertCircle size={18} />
                      {t('tenantdetails.this_contract_is_expiring_with', { defaultValue: `This contract is expiring within 7 days! (` })}{tenant.end_date})
                    </div>
                    <button 
                      onClick={() => handleOpenRenew(tenant.contract_id, tenant.end_date)}
                      className="bg-danger hover:bg-red-600 text-white px-4 py-1.5 rounded-lg text-sm font-bold transition-colors"
                    >
                      {t('tenantdetails.renew_contract', { defaultValue: `Renew Contract` })}
                    </button>
                  </div>
                )}
                <h2 className={`text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-4 flex items-center gap-3 ${(tenant?.contract_status === 'Active' || tenant?.contract_status === 'Approved') && isExpiringSoon(tenant?.end_date) ? 'mt-12' : ''}`}>
                  <Home className="text-primary" size={24} /> 
                  {t('tenantdetails.current_residence_details', { defaultValue: `Current Residence Details` })}
                </h2>
                {tenant?.building_name ? (
                  <div className="grid grid-cols-2 gap-6">
                    <div>
                      <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.building_name', { defaultValue: `Building Name` })}</span>
                      <span className="text-lg text-white font-medium">{tenant?.building_name}</span>
                    </div>
                    <div>
                      <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.apartment_code', { defaultValue: `Apartment Code` })}</span>
                      <span className="text-lg text-white font-medium">{tenant?.apartment_code}</span>
                    </div>
                    <div>
                      <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.monthly_rent', { defaultValue: `Monthly Rent` })}</span>
                      <span className="text-lg text-white font-medium text-success">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(tenant?.monthly_rent).toLocaleString()}</span>
                    </div>
                    <div>
                      <span className="text-sm text-slate-400 block mb-1">{t('tenantdetails.lease_period', { defaultValue: `Lease Period` })}</span>
                      <span className="text-lg text-white font-medium">{tenant?.start_date} &rarr; {tenant?.end_date}</span>
                    </div>
                  </div>
                ) : (
                  <div className="text-center py-8 text-muted">
                    {t('tenantdetails.this_tenant_is_not_currently_a', { defaultValue: `This tenant is not currently assigned to an apartment.` })}
                  </div>
                )}
              </div>
            )}

            {activeTab === 'Contracts' && (
              <div className="glass-card overflow-hidden">
                <table className="min-w-full divide-y divide-slate-700/50 text-left">
                  <thead>
                    <tr className="bg-slate-800/30">
                      <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.id', { defaultValue: `ID` })}</th>
                      <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.apartment', { defaultValue: `Apartment` })}</th>
                      <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.dates', { defaultValue: `Dates` })}</th>
                      <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.rent', { defaultValue: `Rent` })}</th>
                      <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.status', { defaultValue: `Status` })}</th>
                      <th className="px-6 py-4 text-right text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.actions', { defaultValue: `Actions` })}</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-700/50">
                    {contractsData?.map(contract => (
                      <tr key={contract.id} className="hover:bg-slate-800/30 transition-colors">
                        <td className="px-6 py-4 text-slate-300">#{contract.id}</td>
                        <td className="px-6 py-4 text-slate-300">{contract.building_name} - {contract.apartment_code}</td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          <div className="flex items-center gap-2">
                            <span>{contract.start_date} &rarr; {contract.end_date}</span>
                            {(contract.status === 'Active' || contract.status === 'Approved') && isExpiringSoon(contract.end_date) && (
                              <span className="text-danger flex items-center gap-1 font-semibold" title={t('tenantdetails.expiring_within_7_days', { defaultValue: `Expiring within 7 days` })}>
                                <AlertCircle size={12} /> {t('tenantdetails.expiring_soon', { defaultValue: `Expiring soon` })}
                              </span>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="text-white font-medium mb-1">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(contract.monthly_rent).toLocaleString()}</div>
                          <div className="text-slate-400 text-xs flex items-center justify-between">
                            <span>Ins: CFA {contract.monthly_insurance}</span>
                            <span className={`px-1.5 py-0.5 rounded text-[10px] font-bold ${contract.insurance_status === 'Paid' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'}`}>
                              {contract.insurance_status || 'Pending Payment'}
                            </span>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-col gap-1 items-start">
                            <span className="px-3 py-1 rounded-full text-xs font-semibold bg-slate-800 text-slate-300">
                              {contract.status.replace('_', ' ')}
                            </span>
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
                        <td className="px-6 py-4 text-right">
                          {(contract.status === 'Active' || contract.status === 'Approved') && (
                            <button 
                              onClick={() => handleOpenRenew(contract.id, contract.end_date)}
                              className="text-success hover:text-green-300 p-2 transition-colors rounded-lg hover:bg-slate-800 me-2" 
                              title={t('tenantdetails.renew_contract', { defaultValue: `Renew Contract` })}
                            >
                              <RefreshCw size={18} />
                            </button>
                          )}
                          <button onClick={() => generatePDF(contract)} className="text-indigo-400 hover:text-indigo-300 p-2 transition-colors rounded-lg hover:bg-slate-800" title={t('tenantdetails.print_download_pdf', { defaultValue: `Print/Download PDF` })}>
                            <FileText size={18} />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {!contractsData?.length && (
                      <tr>
                        <td colSpan="6" className="px-6 py-8 text-center text-muted">{t('tenantdetails.no_contracts_found', { defaultValue: `No contracts found.` })}</td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            )}

            {activeTab === 'Payment History' && (
              <div className="space-y-8">
                {rentProfile && (
                  <div className="glass-card p-6 border-l-4 border-l-primary relative overflow-hidden">
                    <div className="absolute top-0 right-0 p-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${rentProfile.status === 'Active' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'}`}>
                        {rentProfile.status}
                      </span>
                    </div>
                    <h3 className="text-lg font-bold text-white mb-4 flex items-center gap-2">
                      <Zap className="text-primary" size={20} /> Rent Profile Settings
                    </h3>
                    <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold mb-2">Auto Renewal</span>
                        <button 
                          onClick={() => updateRentProfileMutation.mutate({ auto_renewal: Number(rentProfile.auto_renewal) === 1 ? 0 : 1 })}
                          className={`flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors ${Number(rentProfile.auto_renewal) === 1 ? 'bg-success/20 text-success border border-success/30' : 'bg-slate-700 text-slate-300 border border-slate-600'}`}
                        >
                          <RefreshCw size={16} className={Number(rentProfile.auto_renewal) === 1 ? 'animate-spin-slow' : ''} />
                          {Number(rentProfile.auto_renewal) === 1 ? 'Enabled' : 'Disabled'}
                        </button>
                      </div>
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold mb-2">Billing Frequency</span>
                        <select 
                          value={rentProfile.billing_frequency}
                          onChange={(e) => updateRentProfileMutation.mutate({ billing_frequency: e.target.value })}
                          className="bg-slate-800 border border-slate-700 text-white text-sm rounded-lg px-4 py-2.5 w-full focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
                        >
                          <option value="Weekly">Weekly</option>
                          <option value="Monthly">Monthly</option>
                          <option value="Quarterly">Quarterly</option>
                          <option value="Yearly">Yearly</option>
                        </select>
                      </div>
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold mb-2">Next Billing Date</span>
                        <div className="bg-slate-800/50 border border-slate-700 text-white text-sm rounded-lg px-4 py-2.5 flex items-center gap-2">
                          <Calendar size={16} className="text-primary" />
                          {rentProfile.next_billing_date}
                        </div>
                      </div>
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold mb-2">Default Payment Method</span>
                        <select 
                          value={rentProfile.default_payment_method || 'Cash'}
                          onChange={(e) => updateRentProfileMutation.mutate({ default_payment_method: e.target.value })}
                          className="bg-slate-800 border border-slate-700 text-white text-sm rounded-lg px-4 py-2.5 w-full focus:ring-2 focus:ring-primary focus:border-transparent outline-none"
                        >
                          <option value="Cash">Cash</option>
                          <option value="Bank Transfer">Bank Transfer</option>
                          <option value="Mobile Money">Mobile Money</option>
                          <option value="Cheque">Cheque</option>
                          <option value="Other">Other</option>
                        </select>
                      </div>
                    </div>
                  </div>
                )}

                {/* Rent History Table */}
                <div className="glass-card overflow-hidden">
                  <div className="p-6 border-b border-slate-700/50 flex flex-col sm:flex-row sm:items-center justify-between bg-slate-800/30 gap-4">
                    <div className="flex items-center gap-3">
                      <DollarSign className="text-success" size={24} />
                      <h2 className="text-xl font-bold text-white">{t('tenantdetails.rent_history', { defaultValue: `Rent History` })}</h2>
                    </div>
                    
                    <div className="flex items-center gap-6 bg-slate-800/50 px-4 py-2 rounded-xl border border-slate-700">
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold">{t('tenantdetails.total_paid', { defaultValue: `Total Paid` })}</span>
                        <span className="text-lg font-bold text-success">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {totalPaid.toLocaleString()}</span>
                      </div>
                      <div className="w-px h-8 bg-slate-700"></div>
                      <div>
                        <span className="text-xs text-slate-400 block uppercase tracking-wider font-semibold">{t('tenantdetails.total_unpaid', { defaultValue: `Total Unpaid` })}</span>
                        <span className="text-lg font-bold text-danger">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {totalUnpaid.toLocaleString()}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3">
                      <input 
                        type="month" 
                        value={rentFilter} 
                        onChange={(e) => setRentFilter(e.target.value)}
                        className="bg-slate-800 border border-slate-700 text-white text-sm rounded-lg px-3 py-2"
                      />
                      {tenant?.contract_id && (
                        <>
                          <button 
                            onClick={() => generateMissingRentMutation.mutate(tenant.contract_id)}
                            disabled={generateMissingRentMutation.isLoading}
                            className="flex items-center gap-2 bg-indigo-500/20 text-indigo-400 hover:bg-indigo-500/30 px-4 py-2 rounded-lg font-medium transition-colors border border-indigo-500/30"
                          >
                            <Zap size={18} /> {generateMissingRentMutation.isLoading ? 'Detecting...' : 'Detect Missing Rent'}
                          </button>
                          <button 
                            onClick={() => {
                              setHistoricalData({ due_date: '', amount: tenant.monthly_rent, is_paid: true });
                              setShowAddHistorical(true);
                            }}
                            className="flex items-center gap-2 bg-success/20 text-success hover:bg-success/30 px-4 py-2 rounded-lg font-medium transition-colors border border-success/30"
                          >
                            <PlusCircle size={18} /> {t('tenantdetails.add_old_rent', { defaultValue: `Add Old Rent` })}
                          </button>
                        </>
                      )}
                      {filteredHistory?.length > 0 && (
                        <button 
                          onClick={() => handlePrint(null, 'rent_all')}
                          className="flex items-center gap-2 bg-primary/20 text-indigo-300 hover:bg-primary/30 px-4 py-2 rounded-lg font-medium transition-colors border border-primary/30"
                        >
                          <Printer size={18} /> {t('tenantdetails.print_all', { defaultValue: `Print All` })}
                        </button>
                      )}
                    </div>
                  </div>
                  <table className="min-w-full divide-y divide-slate-700/50 text-left">
                    <thead>
                      <tr className="bg-slate-800/20">
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.month_due_date', { defaultValue: `Month / Due Date` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.amount_paid', { defaultValue: `Amount Paid` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.outstanding', { defaultValue: `Outstanding` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.status', { defaultValue: `Status` })}</th>
                        <th className="px-6 py-4 text-right text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.actions', { defaultValue: `Actions` })}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700/50">
                      {filteredHistory?.map(invoice => (
                        <tr key={invoice.id} className={`hover:bg-slate-800/30 transition-colors ${Number(invoice.outstanding_debt) > 0 ? "bg-danger/5" : ""}`}>
                          <td className="px-6 py-4">
                            <div className="font-medium text-white">{new Date(invoice.due_date).toLocaleDateString('default', { month: 'long', year: 'numeric' })}</div>
                            <div className="text-xs text-slate-400 mt-1">{t('tenantdetails.due', { defaultValue: `Due:` })} {invoice.due_date}</div>
                          </td>
                          <td className="px-6 py-4 text-success font-medium">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(invoice.paid_amount).toLocaleString()}</td>
                          <td className="px-6 py-4 text-danger font-bold">{Number(invoice.outstanding_debt) > 0 ? `CFA ${Number(invoice.outstanding_debt).toLocaleString()}` : '-'}</td>
                          <td className="px-6 py-4">
                            <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${getStatusColor(invoice.status)}`}>
                              {invoice.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-right">
                            <div className="flex justify-end gap-2 items-center">
                              {Number(invoice.outstanding_debt) > 0 && (
                                <button 
                                  onClick={() => {
                                    setPaymentModal(invoice);
                                    const contract = contractsData?.find(c => c.id === invoice.contract_id);
                                    const rule = contract?.payment_method_rule || 'Any Method';
                                    const defaultMethod = rule !== 'Any Method' ? rule.replace(' Only', '') : (rentProfile?.default_payment_method || 'Cash');
                                    setPaymentData({ amount: invoice.outstanding_debt, notes: '', payment_method: defaultMethod, bank_name: '', reference_number: '', proof_of_payment: '' });
                                  }}
                                  className="bg-success/20 text-success hover:bg-success/30 px-3 py-1.5 rounded-lg font-medium text-sm transition-colors border border-success/20"
                                >
                                  {t('tenantdetails.pay', { defaultValue: `Pay` })}
                                </button>
                              )}
                              <button 
                                onClick={() => handlePrint(invoice.id, 'rent_single')}
                                className="text-slate-400 hover:text-indigo-400 p-2 transition-colors rounded-lg hover:bg-slate-800"
                              >
                                <Printer size={18} />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                      {filteredHistory?.length === 0 && (
                        <tr>
                          <td colSpan="5" className="px-6 py-8 text-center text-muted">{t('tenantdetails.no_rent_history_found', { defaultValue: `No rent history found.` })}</td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

              </div>
            )}

            {activeTab === 'Electricity' && (
              <div className="space-y-6">
                <div className="flex justify-between items-center mb-6">
                  <div className="flex items-center gap-3">
                    <Zap className="text-warning" size={32} />
                    <h2 className="text-2xl font-bold text-white">{t('tenantdetails.electricity_generator_billing', { defaultValue: `Electricity & Generator Billing` })}</h2>
                  </div>
                  <div className="flex gap-3">
                    <input 
                      type="month" 
                      value={elecFilter} 
                      onChange={(e) => setElecFilter(e.target.value)}
                      className="bg-slate-800 border border-slate-700 text-white text-sm rounded-lg px-3 py-2"
                    />
                    {filteredElectricity?.length > 0 && (
                      <button 
                        onClick={() => handlePrint(null, 'elec_all')}
                        className="flex items-center gap-2 bg-primary/20 text-indigo-300 hover:bg-primary/30 px-4 py-2 rounded-lg font-medium transition-colors border border-primary/30"
                      >
                        <Printer size={18} /> {t('tenantdetails.print_all', { defaultValue: `Print All` })}
                      </button>
                    )}
                  </div>
                </div>

                {electricitySubscription && electricitySubscription.status === 'Active' && (
                  <div className="bg-slate-800 border border-slate-700 p-6 rounded-xl mb-6">
                    <div className="flex justify-between items-center">
                      <div>
                        <h3 className="text-lg font-bold text-white flex items-center gap-2"><Zap className="text-warning" size={20}/> {t('tenantdetails.active_generator_subscription', { defaultValue: `Active Generator Subscription` })}</h3>
                        <p className="text-muted mt-1">Type: {electricitySubscription.amps > 0 ? 'Fixed Amps' : 'Metered'} | Fee: CFA {Number(electricitySubscription.monthly_fee).toLocaleString()}</p>
                        <p className="text-sm mt-1">
                          {electricitySubscription.amps > 0 ? 
                            <span className="text-indigo-300">Next Renewal Due: {electricitySubscription.next_billing_date || 'Not set'}</span> :
                            <span className="text-indigo-300">Next Reading Due: {electricitySubscription.next_billing_date || 'Not set'} (Last reading: {latestReading?.latest_reading || 0} KW)</span>
                          }
                        </p>
                      </div>
                      <div>
                        {electricitySubscription.amps > 0 ? (
                          <button onClick={() => {
                              if(window.confirm('Renew subscription and generate next invoice?')) {
                                renewSubMutation.mutate();
                              }
                            }}
                            className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg font-medium shadow-lg shadow-primary/20 transition-all flex items-center gap-2"
                          >
                            <RefreshCw size={18}/> Renew Subscription
                          </button>
                        ) : (
                          <button onClick={() => {
                              setMeterForm({...meterForm, previous_reading: latestReading?.latest_reading || 0});
                              setMeterReadingModal(true);
                            }}
                            className="bg-warning text-warning-foreground hover:bg-yellow-500 px-4 py-2 rounded-lg font-medium shadow-lg shadow-warning/20 transition-all flex items-center gap-2"
                          >
                            <PlusCircle size={18}/> Enter New Reading
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                )}
                <div className="glass-card overflow-hidden">
                  <table className="min-w-full divide-y divide-slate-700/50 text-left">
                    <thead>
                      <tr className="bg-slate-800/20">
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.due_date', { defaultValue: `Due Date` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.type', { defaultValue: `Type` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.amount_due', { defaultValue: `Amount Due` })}</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">Paid</th>
                        <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.status', { defaultValue: `Status` })}</th>
                        <th className="px-6 py-4 text-right text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.actions', { defaultValue: `Actions` })}</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700/50">
                      {filteredElectricity?.map(invoice => (
                        <tr key={invoice.id} className={`hover:bg-slate-800/30 transition-colors ${invoice.status !== 'Paid' ? "bg-warning/5" : ""}`}>
                          <td className="px-6 py-4 text-white font-medium">{invoice.due_date}</td>
                          <td className="px-6 py-4 text-slate-300">{invoice.type}</td>
                          <td className="px-6 py-4 text-white font-bold">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(invoice.amount).toLocaleString()}</td>
                          <td className="px-6 py-4 text-success font-medium">CFA {Number(invoice.amount_paid || 0).toLocaleString()}</td>
                          <td className="px-6 py-4">
                            <span className={`px-3 py-1 inline-flex text-xs font-semibold rounded-full ${invoice.status === 'Paid' ? 'bg-success/20 text-success' : 'bg-warning/20 text-warning'}`}>
                              {invoice.status}
                            </span>
                          </td>
                          <td className="px-6 py-4 text-right">
                            {invoice.status !== 'Paid' && (
                              <button 
                                onClick={() => {
                                  setElecPayModal(invoice);
                                  setElecPayAmount(invoice.amount - (invoice.amount_paid || 0));
                                }}
                                className="bg-primary/20 text-indigo-300 px-3 py-1.5 rounded-lg text-sm"
                              >
                                {t('tenantdetails.pay', { defaultValue: `Pay` })}
                              </button>
                            )}
                          </td>
                        </tr>
                      ))}
                      {!filteredElectricity?.length && (
                        <tr><td colSpan="6" className="px-6 py-8 text-center text-muted">{t('tenantdetails.no_electricity_invoices_found', { defaultValue: `No electricity invoices found.` })}</td></tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {activeTab === 'Insurance' && (
              <div className="space-y-6">
                <div className="flex items-center gap-3 mb-6">
                  <Shield className="text-purple-400" size={32} />
                  <h2 className="text-2xl font-bold text-white">{t('tenantdetails.insurance_deposit', { defaultValue: `Insurance & Deposit` })}</h2>
                </div>

                {loadingInsurance && <div className="text-center text-muted py-12">{t('tenantdetails.loading_insurance_data', { defaultValue: `Loading insurance data...` })}</div>}

                {!loadingInsurance && (!insuranceAccounts || insuranceAccounts.length === 0) && (
                  <div className="glass-card p-12 text-center border-l-4 border-l-purple-500">
                    <Shield className="text-purple-500/40 mx-auto mb-4" size={48} />
                    <h3 className="text-xl font-bold text-white mb-2">{t('tenantdetails.no_insurance_records_found', { defaultValue: `No Insurance Records Found` })}</h3>
                    <p className="text-muted">{t('tenantdetails.no_insurance_deposit_was_recor', { defaultValue: `No insurance/deposit was recorded for this tenant's contracts.` })}</p>
                  </div>
                )}

                {insuranceAccounts?.map((account) => (
                  <div key={account.id} className="glass-card overflow-hidden border-l-4 border-l-purple-500">
                    {/* Account Header */}
                    <div className="p-6 bg-purple-500/5 border-b border-slate-700/50 flex flex-wrap items-center justify-between gap-4">
                      <div>
                        <div className="flex items-center gap-3 mb-1">
                          <span className="text-white font-bold text-lg">{account.building_name} {t('tenantdetails.apt', { defaultValue: `— Apt` })} {account.apartment_code}</span>
                          <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                            account.contract_status === 'Active' || account.contract_status === 'Approved'
                              ? 'bg-success/20 text-success border border-success/30'
                              : 'bg-slate-700 text-slate-400'
                          }`}>{account.contract_status}</span>
                        </div>
                        <div className="text-sm text-slate-400">{t('tenantdetails.contract', { defaultValue: `Contract:` })} {account.start_date} → {account.end_date}</div>
                      </div>
                      <div className="flex items-center gap-6">
                        <div className="text-center">
                          <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('tenantdetails.required_deposit', { defaultValue: `Required Deposit` })}</div>
                          <div className="text-lg font-bold text-white">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(account.required_deposit || 0).toLocaleString()}</div>
                        </div>
                        <div className="text-center">
                          <div className="text-xs text-muted uppercase tracking-wider mb-1">{t('tenantdetails.total_saved', { defaultValue: `Total Saved` })}</div>
                          <div className="text-2xl font-bold text-purple-400">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(account.total_saved || 0).toLocaleString()}</div>
                          <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold mt-1 inline-block ${account.insurance_status === 'Paid' ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'}`}>
                            {account.insurance_status || 'Pending Payment'}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Transactions */}
                    {account.transactions?.length > 0 ? (
                      <table className="min-w-full divide-y divide-slate-700/50 text-left">
                        <thead>
                          <tr className="bg-slate-800/20">
                            <th className="px-6 py-3 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.date', { defaultValue: `Date` })}</th>
                            <th className="px-6 py-3 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.type', { defaultValue: `Type` })}</th>
                            <th className="px-6 py-3 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.amount', { defaultValue: `Amount` })}</th>
                            <th className="px-6 py-3 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.by', { defaultValue: `By` })}</th>
                            <th className="px-6 py-3 text-xs font-semibold text-muted uppercase tracking-wider">{t('tenantdetails.notes', { defaultValue: `Notes` })}</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-700/50">
                          {account.transactions.map(tx => (
                            <tr key={tx.id} className="hover:bg-slate-800/30 transition-colors">
                              <td className="px-6 py-3 text-slate-300 text-sm">{tx.date}</td>
                              <td className="px-6 py-3">
                                <span className={`px-2 py-0.5 rounded-full text-xs font-semibold ${
                                  tx.type === 'Deposit' ? 'bg-success/20 text-success' :
                                  tx.type === 'Refund' ? 'bg-warning/20 text-warning' :
                                  tx.type === 'Deduct' ? 'bg-danger/20 text-danger' :
                                  'bg-primary/20 text-indigo-300'
                                }`}>{tx.type}</span>
                              </td>
                              <td className={`px-6 py-3 font-bold ${
                                tx.type === 'Deposit' ? 'text-success' : 'text-danger'
                              }`}>
                                {tx.type === 'Deposit' ? '+' : '-'}{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(tx.amount).toLocaleString()}
                              </td>
                              <td className="px-6 py-3 text-slate-400 text-sm">{tx.created_by || '—'}</td>
                              <td className="px-6 py-3 text-slate-400 text-sm">{tx.notes || '—'}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    ) : (
                      <div className="px-6 py-8 text-center text-muted">{t('tenantdetails.no_transactions_recorded_for_t', { defaultValue: `No transactions recorded for this account.` })}</div>
                    )}
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'Maintenance Requests' && (
              <div className="glass-card p-12 text-center text-muted border-l-4 border-l-orange-500">
                <Wrench className="text-orange-500/50 mx-auto mb-4" size={48} />
                <h3 className="text-xl font-bold text-white mb-2">{t('tenantdetails.no_active_maintenance_requests', { defaultValue: `No Active Maintenance Requests` })}</h3>
                <p>{t('tenantdetails.the_tenant_has_not_submitted_a', { defaultValue: `The tenant has not submitted any recent maintenance issues.` })}</p>
              </div>
            )}

            {activeTab === 'Documents' && (
              <div className="glass-card p-12 text-center text-muted">
                <Folder className="text-slate-500 mx-auto mb-4" size={48} />
                <h3 className="text-xl font-bold text-white mb-2">{t('tenantdetails.document_center', { defaultValue: `Document Center` })}</h3>
                <p>{t('tenantdetails.upload_kyc_ids_or_external_doc', { defaultValue: `Upload KYC, IDs, or external documents related to this tenant here.` })}</p>
                <div className="mt-6 inline-flex bg-slate-800 border border-slate-700 rounded-xl px-6 py-3 cursor-pointer hover:bg-slate-700 transition-colors">
                  <span className="text-white font-medium">{t('tenantdetails.upload_document', { defaultValue: `Upload Document` })}</span>
                </div>
              </div>
            )}
          </div>
        </div>
        
        {/* Modals and Printing Output (Preserved) */}
        {paymentModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 print:hidden">
            <div className="glass-card p-6 w-full max-w-md border border-slate-700 animate-in zoom-in-95 duration-200">
              <h3 className="text-xl font-bold mb-4 text-white">{t('tenantdetails.process_rent_payment', { defaultValue: `Process Rent Payment` })}</h3>
              <p className="text-sm text-slate-400 mb-6 bg-slate-800/50 p-3 rounded-lg border border-slate-700">
                <span className="block mb-1">{t('tenantdetails.invoice_due', { defaultValue: `Invoice Due:` })} <strong className="text-white">{new Date(paymentModal.due_date).toLocaleDateString()}</strong></span>
                <span className="block text-warning">{t('tenantdetails.outstanding_debt', { defaultValue: `Outstanding Debt:` })} <strong>{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(paymentModal.outstanding_debt).toLocaleString()}</strong></span>
              </p>
              
              <div className="space-y-4 mb-8">
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('tenantdetails.payment_amount_cfa', { defaultValue: `Payment Amount (CFA)` })}</label>
                  <input 
                    type="number" 
                    max={paymentModal.outstanding_debt}
                    value={paymentData.amount}
                    onChange={e => setPaymentData({...paymentData, amount: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary text-lg font-bold"
                    autoFocus
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">Payment Method</label>
                  <select 
                    value={paymentData.payment_method}
                    onChange={e => setPaymentData({...paymentData, payment_method: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-600 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-primary"
                    disabled={contractsData?.find(c => c.id === paymentModal.contract_id)?.payment_method_rule && contractsData?.find(c => c.id === paymentModal.contract_id)?.payment_method_rule !== 'Any Method'}
                  >
                    <option value="Cash">Cash</option>
                    <option value="Bank Transfer">Bank Transfer</option>
                    <option value="Mobile Money">Mobile Money</option>
                    <option value="Cheque">Cheque</option>
                    <option value="Other">Other</option>
                  </select>
                </div>
                {paymentData.payment_method === 'Bank Transfer' && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-muted mb-2">Bank Name</label>
                      <input 
                        type="text" 
                        value={paymentData.bank_name}
                        onChange={e => setPaymentData({...paymentData, bank_name: e.target.value})}
                        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-muted mb-2">Reference Number</label>
                      <input 
                        type="text" 
                        value={paymentData.reference_number}
                        onChange={e => setPaymentData({...paymentData, reference_number: e.target.value})}
                        className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                      />
                    </div>
                  </div>
                )}
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('tenantdetails.notes', { defaultValue: `Notes` })}</label>
                  <input 
                    type="text" 
                    value={paymentData.notes}
                    onChange={e => setPaymentData({...paymentData, notes: e.target.value})}
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary"
                    placeholder={t('tenantdetails.optional_notes', { defaultValue: `Optional notes` })}
                  />
                </div>
              </div>

              <div className="flex gap-3">
                <button onClick={() => setPaymentModal(null)} className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg flex-1 transition-colors">{t('tenantdetails.cancel', { defaultValue: `Cancel` })}</button>
                <button 
                  onClick={() => payMutation.mutate({ invoice_id: paymentModal.id, ...paymentData })} 
                  disabled={!paymentData.amount || Number(paymentData.amount) > Number(paymentModal.outstanding_debt)}
                  className="bg-success hover:bg-green-600 text-white px-4 py-2 rounded-lg flex-1 disabled:opacity-50 transition-colors font-medium shadow-lg shadow-success/20"
                >
                  {t('tenantdetails.confirm_payment', { defaultValue: `Confirm Payment` })}
                </button>
              </div>
            </div>
          </div>
        )}

        {showAddHistorical && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 print:hidden">
            <div className="glass-card p-6 w-full max-w-md border border-slate-700 animate-in zoom-in-95 duration-200">
              <h3 className="text-xl font-bold mb-2 text-white">{t('tenantdetails.add_historical_rent', { defaultValue: `Add Historical Rent` })}</h3>
              <p className="text-sm text-slate-400 mb-6">{t('tenantdetails.manually_log_a_rent_invoice_fo', { defaultValue: `Manually log a rent invoice for a past month.` })}</p>
              <div className="space-y-4 mb-8">
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('tenantdetails.due_date', { defaultValue: `Due Date` })}</label>
                  <input type="date" value={historicalData.due_date} onChange={e => setHistoricalData({...historicalData, due_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('tenantdetails.rent_amount_cfa', { defaultValue: `Rent Amount (CFA)` })}</label>
                  <input type="number" value={historicalData.amount} onChange={e => setHistoricalData({...historicalData, amount: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-muted mb-2">{t('tenantdetails.status', { defaultValue: `Status` })}</label>
                  <select className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-primary" value={historicalData.is_paid ? 'paid' : 'unpaid'} onChange={e => setHistoricalData({...historicalData, is_paid: e.target.value === 'paid'})}>
                    <option value="paid">{t('tenantdetails.fully_paid', { defaultValue: `Fully Paid` })}</option>
                    <option value="unpaid">{t('tenantdetails.unpaid_has_debt', { defaultValue: `Unpaid / Has Debt` })}</option>
                  </select>
                </div>
              </div>
              <div className="flex gap-3">
                <button onClick={() => setShowAddHistorical(false)} className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg flex-1 transition-colors">{t('tenantdetails.cancel', { defaultValue: `Cancel` })}</button>
                <button onClick={() => historicalMutation.mutate({ contract_id: tenant.contract_id, ...historicalData })} disabled={!historicalData.due_date || !historicalData.amount} className="bg-success hover:bg-green-600 text-white px-4 py-2 rounded-lg flex-1 disabled:opacity-50 transition-colors font-medium shadow-lg shadow-success/20">{t('tenantdetails.add_record', { defaultValue: `Add Record` })}</button>
              </div>
            </div>
          </div>
        )}

        {/* PRINT ONLY SECTION */}
        <div className="hidden print:block w-full bg-white text-black">
          <div className="text-center mb-10 pb-6 border-b-2 border-black">
            <h1 className="text-5xl font-bold tracking-widest uppercase mb-2">{t('tenantdetails.socimco', { defaultValue: `SOCIMCO` })}</h1>
            <h2 className="text-2xl text-gray-700">
              {printSelection.type?.startsWith('elec') ? 'Electricity & Generator Invoice Statement' : 'Rent Invoice Statement'}
            </h2>
          </div>
          <div className="mb-8">
            <h3 className="font-bold text-2xl mb-1">{t('tenantdetails.tenant', { defaultValue: `Tenant:` })} {tenant?.full_name}</h3>
            <p className="text-lg text-gray-600">{t('tenantdetails.id', { defaultValue: `ID:` })} {tenant?.national_id} {t('tenantdetails.phone', { defaultValue: `| Phone:` })} {tenant?.phone}</p>
          </div>
          <table className="w-full text-left border-collapse mb-8">
            <thead>
              <tr className="border-b-2 border-black">
                <th className="py-3 font-bold uppercase tracking-wider text-sm">{t('tenantdetails.due_date', { defaultValue: `Due Date` })}</th>
                {printSelection.type?.startsWith('rent') && <th className="py-3 font-bold uppercase tracking-wider text-sm">{t('tenantdetails.invoice', { defaultValue: `Invoice #` })}</th>}
                <th className="py-3 font-bold uppercase tracking-wider text-sm">{printSelection.type?.startsWith('elec') ? 'Type' : 'Apartment'}</th>
                <th className="py-3 font-bold uppercase tracking-wider text-sm">{printSelection.type?.startsWith('elec') ? 'Amount Due' : 'Rent Cost'}</th>
                {printSelection.type?.startsWith('rent') && <th className="py-3 font-bold uppercase tracking-wider text-sm">{t('tenantdetails.amount_paid', { defaultValue: `Amount Paid` })}</th>}
                {printSelection.type?.startsWith('rent') && <th className="py-3 font-bold uppercase tracking-wider text-sm">{t('tenantdetails.outstanding', { defaultValue: `Outstanding` })}</th>}
                <th className="py-3 font-bold uppercase tracking-wider text-sm">{t('tenantdetails.status', { defaultValue: `Status` })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-300">
              {invoicesToPrint?.map(invoice => (
                <tr key={invoice.id}>
                  <td className="py-4 font-semibold align-top">{new Date(invoice.due_date).toLocaleDateString('default', { month: 'long', year: 'numeric' })}</td>
                  {printSelection.type?.startsWith('rent') && <td className="py-4 text-gray-600 align-top">{invoice.invoice_number}</td>}
                  <td className="py-4 font-semibold align-top">
                    {printSelection.type?.startsWith('elec') ? invoice.type : `${invoice.building_name} - ${invoice.apartment_code}`}
                  </td>
                  <td className="py-4 font-bold align-top">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(invoice.amount).toLocaleString()}</td>
                  {printSelection.type?.startsWith('rent') && <td className="py-4 text-green-700 font-bold align-top">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(invoice.paid_amount).toLocaleString()}</td>}
                  {printSelection.type?.startsWith('rent') && <td className="py-4 text-red-700 font-bold align-top">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {Number(invoice.outstanding_debt).toLocaleString()}</td>}
                  <td className="py-4 font-bold uppercase align-top">{invoice.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="flex justify-end pt-6 border-t-2 border-black mt-8">
            <div className="w-80 space-y-3">
              <div className="flex justify-between text-lg">
                <span className="font-bold text-gray-600">{t('tenantdetails.total_paid', { defaultValue: `Total Paid:` })}</span>
                <span className="font-bold text-green-700">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {printTotalPaid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
              </div>
              <div className="flex justify-between text-xl">
                <span className="font-bold text-gray-800">{t('tenantdetails.total_unpaid_debt', { defaultValue: `Total Unpaid (Debt):` })}</span>
                <span className="font-bold text-red-700">{t('tenantdetails.cfa', { defaultValue: `CFA` })} {printTotalUnpaid.toLocaleString(undefined, { minimumFractionDigits: 2 })}</span>
              </div>
            </div>
          </div>
        </div>

      </div>
      {showNewContract && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 w-full max-w-2xl shadow-2xl animate-in fade-in zoom-in-95">
            <h3 className="text-xl font-bold text-white mb-6">{t('tenantdetails.create_new_contract_for', { defaultValue: `Create New Contract for` })} {tenant?.full_name}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div className="col-span-1 md:col-span-2">
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('tenantdetails.assign_to_apartment', { defaultValue: `Assign to Apartment` })}</label>
                <select 
                  className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                  value={newContractData.apartment_id} 
                  onChange={(e) => {
                    const apt = vacantApartments?.find(a => String(a.id) === e.target.value);
                    setNewContractData({
                      ...newContractData, 
                      apartment_id: e.target.value,
                      monthly_rent: apt ? apt.monthly_rent : '',
                      monthly_insurance: apt ? apt.monthly_insurance : ''
                    });
                  }}
                >
                  <option value="">{t('tenantdetails.select_a_vacant_apartment', { defaultValue: `Select a vacant apartment...` })}</option>
                  {vacantApartments?.map(a => <option key={a.id} value={a.id}>{a.building_name} - {a.code}</option>)}
                </select>
                {vacantApartments?.length === 0 && (
                  <p className="text-xs text-warning mt-2">{t('tenantdetails.no_vacant_apartments_currently', { defaultValue: `No vacant apartments currently available.` })}</p>
                )}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('tenantdetails.start_date', { defaultValue: `Start Date` })}</label>
                <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={newContractData.start_date} onChange={e => setNewContractData({...newContractData, start_date: e.target.value})} />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('tenantdetails.end_date', { defaultValue: `End Date` })}</label>
                <input type="date" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={newContractData.end_date} onChange={e => setNewContractData({...newContractData, end_date: e.target.value})} />
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('tenantdetails.monthly_rent_cfa', { defaultValue: `Monthly Rent (CFA)` })}</label>
                <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={newContractData.monthly_rent} onChange={e => setNewContractData({...newContractData, monthly_rent: e.target.value})} placeholder={t('tenantdetails.default_rent_used_if_empty', { defaultValue: `Default rent used if empty` })} />
              </div>
              <div>
                <label className="block text-sm font-medium text-slate-400 mb-2">{t('tenantdetails.insurance_deposit_cfa', { defaultValue: `Insurance/Deposit (CFA)` })}</label>
                <input type="number" className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" value={newContractData.monthly_insurance} onChange={e => setNewContractData({...newContractData, monthly_insurance: e.target.value})} placeholder={t('tenantdetails.default_insurance_used_if_empt', { defaultValue: `Default insurance used if empty` })} />
              </div>
            </div>
            
            <div className="flex justify-end gap-3 mt-8 pt-6 border-t border-slate-800">
              <button onClick={() => setShowNewContract(false)} className="px-4 py-2 text-slate-400 hover:text-white transition-colors">{t('tenantdetails.cancel', { defaultValue: `Cancel` })}</button>
              <button 
                onClick={() => createContractMutation.mutate(newContractData)}
                disabled={!newContractData.apartment_id || !newContractData.start_date || !newContractData.end_date || createContractMutation.isLoading}
                className="bg-primary hover:bg-indigo-600 text-white px-6 py-2 rounded-lg font-medium transition-colors disabled:opacity-50"
              >
                {createContractMutation.isLoading ? 'Creating...' : 'Create Contract'}
              </button>
            </div>
          </div>
        </div>
      )}

        {/* Renew Modal */}
        {renewModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
            <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl animate-in zoom-in-95">
              <div className="p-6 border-b border-slate-800 flex justify-between items-center bg-slate-800/30">
                <h3 className="text-xl font-bold text-white flex items-center gap-2">
                  <RefreshCw className="text-success" size={24} /> 
                  Renew Contract
                </h3>
                <button onClick={() => setRenewModal(null)} className="text-slate-400 hover:text-white transition-colors">
                  <X size={24} />
                </button>
              </div>
              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-2">New Start Date</label>
                  <input 
                    type="date" 
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                    value={renewModal.start_date} 
                    onChange={e => setRenewModal({...renewModal, start_date: e.target.value})} 
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-2">New End Date</label>
                  <input 
                    type="date" 
                    className="w-full bg-slate-800 border border-slate-700 rounded-lg px-4 py-3 text-white outline-none focus:border-primary" 
                    value={renewModal.end_date} 
                    onChange={e => setRenewModal({...renewModal, end_date: e.target.value})} 
                  />
                </div>
                <button 
                  onClick={() => renewMutation.mutate({ contractId: renewModal.contractId, data: renewModal })}
                  disabled={renewMutation.isLoading}
                  className="w-full bg-success hover:bg-green-600 text-white px-4 py-3 rounded-xl font-bold transition-colors mt-4"
                >
                  {renewMutation.isLoading ? 'Renewing...' : 'Confirm Renewal'}
                </button>
              </div>
            </div>
          </div>
        )}

    </div>
  );
};

export default TenantDetails;
