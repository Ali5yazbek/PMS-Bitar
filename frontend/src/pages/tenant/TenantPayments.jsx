import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../../api/axios';
import { DollarSign, AlertTriangle, QrCode, X, Check, Zap } from 'lucide-react';
import { QRCodeSVG } from 'qrcode.react';

const TenantPayments = () => {
  const { t } = useTranslation();

  const { data: rentHistory, isLoading } = useQuery({ 
    queryKey: ['tenant-rent-history'], 
    queryFn: async () => (await api.get('/tenant-portal/rent-history')).data,
    refetchInterval: 3000 // Poll every 3 seconds for real-time updates from Agent
  });

  const [activeTab, setActiveTab] = useState('rent');
  const [selectedElecApartment, setSelectedElecApartment] = useState('all');

  // Fetch dashboard to get apartment_id for electricity invoices
  const { data: dashboardData } = useQuery({
    queryKey: ['tenant-dashboard'],
    queryFn: async () => (await api.get('/tenant-portal/dashboard')).data
  });
  
  // Get all unique apartment IDs this tenant is associated with
  const apartmentIds = React.useMemo(() => {
    const ids = new Set();
    if (dashboardData?.contracts) {
      dashboardData.contracts.forEach(c => ids.add(c.apartment_id));
    }
    if (rentHistory) {
      rentHistory.forEach(r => ids.add(r.apartment_id));
    }
    return Array.from(ids);
  }, [dashboardData, rentHistory]);

  const apartmentsList = React.useMemo(() => {
    const map = new Map();
    if (dashboardData?.contracts) {
      dashboardData.contracts.forEach(c => map.set(c.apartment_id, {
        id: c.apartment_id,
        code: c.apartment_code,
        building: c.building_name
      }));
    }
    if (rentHistory) {
      rentHistory.forEach(r => map.set(r.apartment_id, {
        id: r.apartment_id,
        code: r.apartment_code,
        building: r.building_name
      }));
    }
    return Array.from(map.values());
  }, [dashboardData, rentHistory]);

  const { data: electricityInvoices, isLoading: isLoadingElectricity } = useQuery({
    queryKey: ['tenant-electricity-invoices', apartmentIds],
    queryFn: async () => {
      if (apartmentIds.length === 0) return [];
      const allInvoices = await Promise.all(
        apartmentIds.map(async (id) => {
          try {
            return (await api.get(`/electricity/apartments/${id}/invoices`)).data;
          } catch (e) {
            return [];
          }
        })
      );
      return allInvoices.flat().sort((a, b) => new Date(b.due_date) - new Date(a.due_date));
    },
    enabled: apartmentIds.length > 0,
    refetchInterval: 3000 // Poll every 3 seconds for real-time updates from Agent
  });

  const displayedElectricityInvoices = React.useMemo(() => {
    if (!electricityInvoices) return [];
    if (selectedElecApartment === 'all') return electricityInvoices;
    return electricityInvoices.filter(inv => String(inv.apartment_id) === String(selectedElecApartment));
  }, [electricityInvoices, selectedElecApartment]);

  const [qrModalInvoice, setQrModalInvoice] = useState(null);
  const [pendingQrRequest, setPendingQrRequest] = useState(null);
  const [acknowledgedRequests, setAcknowledgedRequests] = useState(new Set());

  // Listen for QR requests from the Agent
  React.useEffect(() => {
    const allInvoices = [
      ...(rentHistory || []),
      ...(electricityInvoices || []).map(inv => ({...inv, isElectricity: true}))
    ];

    if (allInvoices.length > 0) {
      const now = new Date();
      // Find the most recently requested invoice within the last 2 minutes that hasn't been acknowledged
      const recentRequest = allInvoices.find(inv => {
        const idKey = inv.isElectricity ? `elec_${inv.id}` : inv.id;
        if (!inv.qr_requested_at || acknowledgedRequests.has(idKey)) return false;
        
        const requestedTime = new Date(inv.qr_requested_at);
        const timeDiffMinutes = (now - requestedTime) / (1000 * 60);
        return timeDiffMinutes <= 2;
      });

      if (recentRequest && !pendingQrRequest && !qrModalInvoice) {
        setPendingQrRequest({
          ...recentRequest,
          requestKey: recentRequest.isElectricity ? `elec_${recentRequest.id}` : recentRequest.id
        });
      }
    }
  }, [rentHistory, electricityInvoices, acknowledgedRequests, pendingQrRequest, qrModalInvoice]);

  const handleAcceptRequest = () => {
    if (pendingQrRequest) {
      setAcknowledgedRequests(prev => new Set([...prev, pendingQrRequest.requestKey]));
      setQrModalInvoice({
        ...pendingQrRequest,
        outstanding_debt: pendingQrRequest.isElectricity 
          ? (pendingQrRequest.status !== 'Paid' ? (Number(pendingQrRequest.amount) - Number(pendingQrRequest.amount_paid)) : 0)
          : pendingQrRequest.outstanding_debt,
        invoice_number: pendingQrRequest.invoice_number || (pendingQrRequest.isElectricity ? `Elec-${pendingQrRequest.id}` : null),
        tenant_id: dashboardData?.contracts?.[0]?.tenant_id
      });
      setPendingQrRequest(null);
    }
  };

  const handleDeclineRequest = () => {
    if (pendingQrRequest) {
      setAcknowledgedRequests(prev => new Set([...prev, pendingQrRequest.requestKey]));
      setPendingQrRequest(null);
    }
  };

  if (isLoading) return <div className="p-8 text-muted">{t('tenantpayments.loading_your_payment_history', { defaultValue: `Loading your payment history...` })}</div>;

  const totalOutstanding = activeTab === 'rent'
    ? rentHistory?.reduce((sum, item) => sum + Number(item.outstanding_debt), 0) || 0
    : electricityInvoices?.reduce((sum, item) => sum + (item.status !== 'Paid' ? (Number(item.amount) - Number(item.amount_paid)) : 0), 0) || 0;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
              <DollarSign className="me-3 text-primary" size={32} />
              {t('tenantpayments.my_payments', { defaultValue: `My Payments` })}
            </h1>
            <p className="text-muted">{t('tenantpayments.review_your_payment_history_an', { defaultValue: `Review your payment history and outstanding balances.` })}</p>
          </div>

          <div className="flex bg-slate-800/50 p-1 rounded-xl">
            <button
              onClick={() => setActiveTab('rent')}
              className={`px-6 py-2.5 rounded-lg text-sm font-bold transition-all ${
                activeTab === 'rent' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white hover:bg-slate-700/50'
              }`}
            >
              Rent Payments
            </button>
            <button
              onClick={() => setActiveTab('electricity')}
              className={`px-6 py-2.5 rounded-lg text-sm font-bold transition-all ${
                activeTab === 'electricity' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-400 hover:text-white hover:bg-slate-700/50'
              }`}
            >
              Electricity Subscriptions
            </button>
          </div>
        </div>

        {totalOutstanding > 0 && (
          <div className="glass-card p-6 border-l-4 border-l-danger bg-danger/5 mb-8 flex items-center gap-4">
            <div className="p-3 bg-danger/20 rounded-full text-danger">
              <AlertTriangle size={32} />
            </div>
            <div>
              <h3 className="text-lg font-bold text-white">{t('tenantpayments.outstanding_balance', { defaultValue: `Outstanding Balance` })}</h3>
              <p className="text-danger font-medium text-2xl">{t('tenantpayments.cfa', { defaultValue: `CFA` })} {totalOutstanding.toFixed(2)}</p>
              <p className="text-sm text-slate-400 mt-1">{t('tenantpayments.please_visit_the_management_of', { defaultValue: `Please visit the management office to settle your dues.` })}</p>
            </div>
          </div>
        )}

        {activeTab === 'rent' && (
          <div className="glass-card overflow-hidden animate-in fade-in slide-in-from-bottom-2">
            <table className="min-w-full divide-y divide-slate-700/50 text-start">
              <thead>
                <tr className="bg-slate-800/30">
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.invoice', { defaultValue: `Invoice` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Building</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Apt</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.due_date', { defaultValue: `Due Date` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.amount', { defaultValue: `Amount` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.paid', { defaultValue: `Paid` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.balance', { defaultValue: `Balance` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.status', { defaultValue: `Status` })}</th>
                  <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-end">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-700/50">
                {rentHistory?.map((invoice, idx) => (
                  <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                    <td className="px-6 py-4">
                      <div className="font-medium text-white">{invoice.invoice_number}</div>
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-300">{invoice.building_name}</td>
                    <td className="px-6 py-4 text-sm text-slate-300 font-bold">{invoice.apartment_code}</td>
                    <td className="px-6 py-4 text-sm text-slate-300">{invoice.due_date}</td>
                    <td className="px-6 py-4 text-sm text-slate-300">{t('tenantpayments.cfa', { defaultValue: `CFA` })} {Number(invoice.amount).toFixed(2)}</td>
                    <td className="px-6 py-4 text-sm text-success">{t('tenantpayments.cfa', { defaultValue: `CFA` })} {Number(invoice.paid_amount).toFixed(2)}</td>
                    <td className="px-6 py-4 text-sm text-danger font-medium">{t('tenantpayments.cfa', { defaultValue: `CFA` })} {Number(invoice.outstanding_debt).toFixed(2)}</td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${
                        invoice.status === 'Paid' ? 'bg-success/20 text-success' : 
                        invoice.status === 'Partial' ? 'bg-warning/20 text-warning' : 
                        'bg-danger/20 text-danger'
                      }`}>
                        {invoice.status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-end">
                      {invoice.status !== 'Paid' && (
                        <button 
                          onClick={() => setQrModalInvoice(invoice)}
                          className="bg-primary/20 hover:bg-primary text-primary hover:text-white px-3 py-1.5 rounded-lg flex items-center justify-center gap-2 text-xs font-bold transition-colors ms-auto"
                        >
                          <QrCode size={14} /> Generate Payment QR
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            {(!rentHistory || rentHistory.length === 0) && (
              <div className="p-8 text-center text-muted">{t('tenantpayments.no_rent_history_found', { defaultValue: `No rent history found.` })}</div>
            )}
          </div>
        )}

        {activeTab === 'electricity' && (
          <div className="glass-card overflow-hidden animate-in fade-in slide-in-from-bottom-2">
            <div className="p-4 border-b border-slate-700/50 flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-slate-800/30">
              <h2 className="text-lg font-bold text-white flex items-center gap-2">
                <Zap className="text-primary" size={20} /> Electricity Invoices
              </h2>
              {apartmentsList.length > 0 && (
                <div className="flex items-center gap-3">
                  <label className="text-sm font-medium text-slate-400">Filter by Apartment:</label>
                  <select
                    value={selectedElecApartment}
                    onChange={(e) => setSelectedElecApartment(e.target.value)}
                    className="bg-slate-900 border border-slate-700 text-white text-sm rounded-lg focus:ring-primary focus:border-primary block p-2 transition-colors cursor-pointer"
                  >
                    <option value="all">All Apartments</option>
                    {apartmentsList.map(apt => (
                      <option key={apt.id} value={apt.id}>
                        {apt.building} - Apt {apt.code}
                      </option>
                    ))}
                  </select>
                </div>
              )}
            </div>

            {isLoadingElectricity ? (
              <div className="p-8 text-center text-muted">Loading electricity invoices...</div>
            ) : (
              <table className="min-w-full divide-y divide-slate-700/50 text-start">
                <thead>
                  <tr className="bg-slate-800/30">
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Invoice / Details</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Building</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Apt</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Type</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Due Date</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Amount</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Paid</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Balance</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">Status</th>
                    <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-end">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {displayedElectricityInvoices?.map((invoice, idx) => {
                    const outstanding = invoice.status !== 'Paid' ? (Number(invoice.amount) - Number(invoice.amount_paid)) : 0;
                    // Find the apartment details to show in the row
                    const aptInfo = apartmentsList.find(a => String(a.id) === String(invoice.apartment_id)) || {};
                    return (
                      <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                        <td className="px-6 py-4">
                          <div className="font-medium text-white">{invoice.invoice_number || `Elec-${invoice.id}`}</div>
                          {invoice.type === 'Meter' && invoice.consumption && (
                            <div className="text-xs text-slate-400 mt-1">
                              {invoice.previous_reading} → {invoice.current_reading} kWh ({invoice.consumption} kWh used)
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {aptInfo.building || 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300 font-bold">
                          {aptInfo.code || 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {invoice.type || 'Subscription'}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">
                          {invoice.due_date ? new Date(invoice.due_date).toLocaleDateString() : 'N/A'}
                        </td>
                        <td className="px-6 py-4 text-sm text-slate-300">CFA {Number(invoice.amount).toFixed(2)}</td>
                        <td className="px-6 py-4 text-sm text-success">CFA {Number(invoice.amount_paid).toFixed(2)}</td>
                        <td className="px-6 py-4 text-sm text-danger font-medium">
                          CFA {outstanding.toFixed(2)}
                        </td>
                        <td className="px-6 py-4">
                          <span className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${
                            invoice.status === 'Paid' ? 'bg-success/20 text-success' : 
                            invoice.status === 'Partially Paid' ? 'bg-warning/20 text-warning' : 
                            'bg-danger/20 text-danger'
                          }`}>
                            {invoice.status || 'Unpaid'}
                          </span>
                        </td>
                        <td className="px-6 py-4 text-end">
                          {invoice.status !== 'Paid' && (
                            <button 
                              onClick={() => setQrModalInvoice({
                                ...invoice,
                                isElectricity: true,
                                outstanding_debt: outstanding,
                                invoice_number: invoice.invoice_number || `Elec-${invoice.id}`,
                                tenant_id: dashboardData?.contracts?.[0]?.tenant_id // Fallback just in case
                              })}
                              className="bg-primary/20 hover:bg-primary text-primary hover:text-white px-3 py-1.5 rounded-lg flex items-center justify-center gap-2 text-xs font-bold transition-colors ms-auto"
                            >
                              <QrCode size={14} /> Generate Payment QR
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
            {(!displayedElectricityInvoices || displayedElectricityInvoices.length === 0) && !isLoadingElectricity && (
              <div className="p-8 text-center text-muted">No electricity subscriptions found for this apartment.</div>
            )}
          </div>
        )}
      </div>

      {/* QR Code Modal */}
      {qrModalInvoice && (() => {
        let liveInvoice = qrModalInvoice;
        if (qrModalInvoice.isElectricity) {
           const updated = electricityInvoices?.find(i => String(i.id) === String(qrModalInvoice.id));
           if (updated) {
             liveInvoice = { 
               ...updated, 
               isElectricity: true,
               invoice_number: updated.invoice_number || `Elec-${updated.id}`,
               outstanding_debt: updated.status !== 'Paid' ? (Number(updated.amount) - Number(updated.amount_paid)) : 0
             };
           }
        } else {
           liveInvoice = rentHistory?.find(i => String(i.id) === String(qrModalInvoice.id)) || qrModalInvoice;
        }
          
        const isPaid = liveInvoice.status === 'Paid';

        return (
          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
            <div className="bg-[#0F172A] border border-slate-700 rounded-2xl w-full max-w-sm overflow-hidden shadow-2xl animate-in zoom-in-95">
              <div className="p-4 border-b border-slate-800 flex justify-between items-center bg-slate-900">
                <h3 className="text-lg font-bold text-white flex items-center gap-2">
                  {isPaid ? <Check className="text-success" size={20} /> : <QrCode className="text-primary" size={20} />} 
                  {isPaid ? 'Payment Successful' : 'Payment Receipt QR'}
                </h3>
                <button onClick={() => setQrModalInvoice(null)} className="text-slate-400 hover:text-white transition-colors">
                  <X size={24} />
                </button>
              </div>
              <div className="p-8 flex flex-col items-center">
                {isPaid ? (
                  <>
                    <div className="bg-success/20 p-6 rounded-full mb-6">
                      <Check className="text-success w-16 h-16" />
                    </div>
                    <h4 className="text-2xl font-bold text-white mb-2">Thank You!</h4>
                    <p className="text-slate-400 text-center mb-6">Your payment for Invoice #{liveInvoice.invoice_number} was successfully processed.</p>
                    <button 
                      onClick={() => setQrModalInvoice(null)}
                      className="w-full py-3 bg-slate-800 hover:bg-slate-700 text-white font-bold rounded-xl transition-colors"
                    >
                      Close Receipt
                    </button>
                  </>
                ) : (
                  <>
                    <div className="bg-white p-4 rounded-xl shadow-lg mb-6 border-4 border-primary/20">
                      <QRCodeSVG 
                        value={JSON.stringify({
                          tenantId: liveInvoice.tenant_id,
                          buildingId: liveInvoice.building_id || liveInvoice.building_name,
                          apartmentId: liveInvoice.apartment_id,
                          paymentType: liveInvoice.isElectricity ? 'Electricity Subscription' : 'Rent Apartment',
                          status: liveInvoice.status,
                          invoiceId: liveInvoice.id,
                          invoiceNumber: liveInvoice.invoice_number,
                          amountOwed: liveInvoice.outstanding_debt
                        })}
                        size={200}
                        level="H"
                      />
                    </div>
                    <p className="text-white font-bold text-lg mb-1">Invoice #{liveInvoice.invoice_number}</p>
                    <p className="text-slate-400 text-sm mb-1 text-center">Present this QR code to the agent for scanning.</p>
                    <p className="text-primary font-bold text-sm mb-4">Or provide code: {liveInvoice.invoice_number}</p>
                    
                    <div className="w-full bg-slate-800 rounded-xl p-4 flex justify-between items-center">
                      <span className="text-slate-400 text-sm">Remaining Due</span>
                      <span className="text-danger font-bold text-xl">CFA {Number(liveInvoice.outstanding_debt).toFixed(2)}</span>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        );
      })()}

      {/* Agent Push Request Modal */}
      {pendingQrRequest && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center bg-black/80 backdrop-blur-sm p-4">
          <div className="bg-[#0F172A] border border-primary/50 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl shadow-primary/20 animate-in zoom-in-95">
            <div className="p-4 border-b border-slate-800 flex justify-between items-center bg-primary/10">
              <h3 className="text-lg font-bold text-white flex items-center gap-2">
                <QrCode className="text-primary" size={20} /> Authorization Required
              </h3>
              <button onClick={handleDeclineRequest} className="text-slate-400 hover:text-white transition-colors">
                <X size={24} />
              </button>
            </div>
            <div className="p-8 text-center space-y-4">
              <div className="mx-auto w-16 h-16 bg-primary/20 rounded-full flex items-center justify-center mb-4">
                <AlertTriangle className="text-primary" size={32} />
              </div>
              <h4 className="text-xl font-bold text-white">Payment Collection Request</h4>
              <p className="text-slate-300">
                An agent is requesting to collect payment for <strong>Invoice #{pendingQrRequest.invoice_number}</strong>.
              </p>
              <p className="text-slate-400 text-sm">
                Do you want to accept this request and display your QR code to the agent for scanning?
              </p>
              
              <div className="flex gap-4 pt-4 mt-6 border-t border-slate-800">
                <button 
                  onClick={handleDeclineRequest}
                  className="flex-1 py-3 bg-slate-800 hover:bg-slate-700 text-white font-bold rounded-xl transition-colors"
                >
                  Decline
                </button>
                <button 
                  onClick={handleAcceptRequest}
                  className="flex-1 py-3 bg-primary hover:bg-primary/90 text-white font-bold rounded-xl shadow-lg shadow-primary/20 transition-colors"
                >
                  Accept & Show QR
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TenantPayments;
