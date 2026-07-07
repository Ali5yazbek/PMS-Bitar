import React, { useState, useEffect } from 'react';
import { X, Printer, DollarSign, FileText, CheckCircle, AlertCircle, Clock } from 'lucide-react';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';

const ApartmentInvoicesModal = ({ apartment, onClose, onPaymentSuccess }) => {
  const { t } = useTranslation();
  const [invoices, setInvoices] = useState([]);
  const [loading, setLoading] = useState(true);

  // Payment prompt state
  const [payingInvoice, setPayingInvoice] = useState(null);
  const [paymentAmount, setPaymentAmount] = useState('');
  const [paymentLoading, setPaymentLoading] = useState(false);

  // Print state
  const [printMode, setPrintMode] = useState(null); // 'statement' | 'receipt'
  const [printInvoice, setPrintInvoice] = useState(null);

  useEffect(() => {
    if (apartment) {
      fetchInvoices();
    }
  }, [apartment]);

  // Handle print lifecycle
  useEffect(() => {
    if (printMode) {
      setTimeout(() => {
        window.print();
        setPrintMode(null);
        setPrintInvoice(null);
      }, 300);
    }
  }, [printMode]);

  const fetchInvoices = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/electricity/apartments/${apartment.id}/invoices`);
      // Since it wants subscriptions, let's just fetch all electricity invoices or specifically subscription ones
      const subRes = await api.get(`/energy/apartments/${apartment.id}/subscription-invoices`);
      setInvoices(subRes.data);
    } catch (error) {
      console.error("Error fetching invoices:", error);
    } finally {
      setLoading(false);
    }
  };

  const handlePayClick = (inv) => {
    setPayingInvoice(inv);
    const remaining = Number(inv.amount) - Number(inv.amount_paid);
    setPaymentAmount(remaining.toString());
  };

  const submitPayment = async () => {
    if (!payingInvoice || !paymentAmount || isNaN(paymentAmount)) return;
    setPaymentLoading(true);
    try {
      await api.put(`/electricity/invoices/${payingInvoice.id}/pay`, {
        amount_paid: parseFloat(paymentAmount)
      });
      // Reset payment state
      setPayingInvoice(null);
      setPaymentAmount('');
      // Refetch
      await fetchInvoices();
      if (onPaymentSuccess) {
        onPaymentSuccess();
      }
    } catch (error) {
      console.error("Payment failed", error);
      alert("Payment failed: " + (error.response?.data?.error || error.message));
    } finally {
      setPaymentLoading(false);
    }
  };

  const formatCurrency = (amount) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount || 0);
  };

  const formatDate = (dateString) => {
    if (!dateString) return '';
    return new Date(dateString).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  };

  const getStatusBadge = (status) => {
    switch (status) {
      case 'Paid':
        return <span className="inline-flex items-center space-x-1 px-2.5 py-1 bg-emerald-100 text-emerald-800 rounded-lg text-xs font-medium"><CheckCircle className="w-3 h-3"/><span>Paid</span></span>;
      case 'Partially Paid':
        return <span className="inline-flex items-center space-x-1 px-2.5 py-1 bg-amber-100 text-amber-800 rounded-lg text-xs font-medium"><Clock className="w-3 h-3"/><span>Partial</span></span>;
      case 'Unpaid':
      default:
        return <span className="inline-flex items-center space-x-1 px-2.5 py-1 bg-rose-100 text-rose-800 rounded-lg text-xs font-medium"><AlertCircle className="w-3 h-3"/><span>Unpaid</span></span>;
    }
  };

  if (!apartment) return null;

  // Print Statement View
  if (printMode === 'statement') {
    return (
      <div className="fixed inset-0 bg-white z-[100] p-8 text-black print:block print:p-0">
        <div className="max-w-4xl mx-auto">
          <div className="flex justify-between items-center border-b-2 border-gray-200 pb-6 mb-6">
            <div>
              <h1 className="text-3xl font-bold text-gray-900 tracking-tight">Statement of Account</h1>
              <p className="text-gray-500 mt-1">Generator Subscriptions</p>
            </div>
            <div className="text-right">
              <div className="w-12 h-12 bg-indigo-600 rounded-xl text-white font-bold text-2xl flex items-center justify-center ml-auto mb-2">P</div>
              <p className="text-sm text-gray-600 font-medium">PMS System</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-8 mb-8">
            <div>
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Billed To</h3>
              <p className="text-lg font-bold text-gray-900">{apartment.tenant_name || 'N/A'}</p>
              <p className="text-gray-600">Building: {apartment.building_name}</p>
              <p className="text-gray-600">Apartment: {apartment.name}</p>
            </div>
            <div className="text-right">
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Statement Date</h3>
              <p className="text-gray-900 font-medium">{formatDate(new Date())}</p>
            </div>
          </div>

          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b-2 border-gray-900 text-sm font-bold text-gray-900 uppercase tracking-wider">
                <th className="py-3">Invoice / Month</th>
                <th className="py-3 text-right">Amount</th>
                <th className="py-3 text-right">Paid</th>
                <th className="py-3 text-right">Remaining</th>
                <th className="py-3 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {invoices.map(inv => {
                const remain = Number(inv.amount) - Number(inv.amount_paid);
                return (
                  <tr key={inv.id} className="text-sm text-gray-800">
                    <td className="py-4">
                      <p className="font-medium">{inv.invoice_number || `INV-${inv.id}`}</p>
                      <p className="text-gray-500 text-xs">Due: {formatDate(inv.due_date)}</p>
                    </td>
                    <td className="py-4 text-right">{formatCurrency(inv.amount)}</td>
                    <td className="py-4 text-right text-emerald-600">{formatCurrency(inv.amount_paid)}</td>
                    <td className="py-4 text-right text-rose-600 font-medium">{formatCurrency(remain)}</td>
                    <td className="py-4 text-right font-medium">{inv.status}</td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          <div className="mt-12 text-center text-sm text-gray-500 border-t border-gray-200 pt-6">
            <p>Thank you for your prompt payment.</p>
            <p>If you have any questions concerning this statement, contact our administration.</p>
          </div>
        </div>
      </div>
    );
  }

  // Print Receipt View
  if (printMode === 'receipt' && printInvoice) {
    const remain = Number(printInvoice.amount) - Number(printInvoice.amount_paid);
    return (
      <div className="fixed inset-0 bg-white z-[100] p-8 text-black print:block print:p-0">
        <div className="max-w-2xl mx-auto border border-gray-200 rounded-2xl p-10 shadow-sm">
          <div className="flex justify-between items-start border-b border-gray-100 pb-8 mb-8">
            <div className="flex items-center space-x-4">
              <div className="w-14 h-14 bg-indigo-600 rounded-2xl text-white font-bold text-3xl flex items-center justify-center">P</div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900 tracking-tight">Payment Receipt</h1>
                <p className="text-gray-500">Generator Subscription</p>
              </div>
            </div>
            <div className="text-right">
              <h2 className="text-xl font-bold text-gray-900">{printInvoice.invoice_number || `INV-${printInvoice.id}`}</h2>
              <p className="text-gray-500 text-sm mt-1">{formatDate(new Date())}</p>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-8 mb-8 border-b border-gray-100 pb-8">
            <div>
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Received From</h3>
              <p className="text-lg font-bold text-gray-900">{apartment.tenant_name || 'N/A'}</p>
              <p className="text-gray-600 mt-1">Building: {apartment.building_name}</p>
              <p className="text-gray-600">Apartment: {apartment.name}</p>
            </div>
            <div className="text-right">
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Invoice Date</h3>
              <p className="text-gray-900 font-medium">{formatDate(printInvoice.due_date)}</p>
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-1 mt-4">Status</h3>
              <p className="text-gray-900 font-bold">{printInvoice.status}</p>
            </div>
          </div>

          <div className="bg-gray-50 rounded-xl p-6 mb-8">
            <div className="flex justify-between items-center mb-3">
              <span className="text-gray-600">Total Amount</span>
              <span className="font-medium text-gray-900">{formatCurrency(printInvoice.amount)}</span>
            </div>
            <div className="flex justify-between items-center mb-3">
              <span className="text-gray-600">Amount Paid</span>
              <span className="font-bold text-emerald-600">{formatCurrency(printInvoice.amount_paid)}</span>
            </div>
            <div className="flex justify-between items-center pt-3 border-t border-gray-200">
              <span className="font-bold text-gray-900">Remaining Balance</span>
              <span className="font-bold text-rose-600 text-xl">{formatCurrency(remain)}</span>
            </div>
          </div>

          <div className="text-center text-sm text-gray-500 mt-12">
            <p>Thank you for your payment!</p>
          </div>
        </div>
      </div>
    );
  }

  // Normal Modal View
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-gray-900/50 backdrop-blur-sm print:hidden animate-fade-in">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-5xl overflow-hidden flex flex-col max-h-[90vh]">
        
        {/* Header */}
        <div className="px-6 py-5 border-b border-gray-100 flex justify-between items-center bg-gray-50/80">
          <div>
            <h2 className="text-2xl font-bold text-gray-800">
              {apartment.building_name} - Apartment {apartment.name}
            </h2>
            <p className="text-sm text-gray-500 mt-1">Tenant: {apartment.tenant_name || 'N/A'}</p>
          </div>
          <div className="flex items-center space-x-3">
            <button 
              onClick={() => setPrintMode('statement')}
              className="flex items-center space-x-2 px-4 py-2 bg-indigo-50 text-indigo-700 hover:bg-indigo-100 rounded-xl transition-colors font-medium text-sm"
            >
              <Printer className="w-4 h-4" />
              <span>Print Statement</span>
            </button>
            <button 
              onClick={onClose}
              className="p-2 text-gray-400 hover:bg-gray-200 hover:text-gray-600 rounded-xl transition-colors"
            >
              <X className="w-6 h-6" />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto flex-1 bg-white">
          {loading ? (
            <div className="flex justify-center items-center py-20">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600"></div>
            </div>
          ) : (
            <div className="border border-gray-100 rounded-2xl overflow-hidden">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                    <th className="px-6 py-4 font-medium">Month (Due Date)</th>
                    <th className="px-6 py-4 font-medium text-right">Amount</th>
                    <th className="px-6 py-4 font-medium text-right">Paid</th>
                    <th className="px-6 py-4 font-medium text-right">Remaining</th>
                    <th className="px-6 py-4 font-medium text-center">Status</th>
                    <th className="px-6 py-4 font-medium text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 text-sm">
                  {invoices.map((inv) => {
                    const remain = Number(inv.amount) - Number(inv.amount_paid);
                    return (
                      <tr key={inv.id} className="hover:bg-gray-50/50 transition-colors">
                        <td className="px-6 py-4 font-medium text-gray-900">
                          {formatDate(inv.due_date)}
                        </td>
                        <td className="px-6 py-4 text-right font-medium">
                          {formatCurrency(inv.amount)}
                        </td>
                        <td className="px-6 py-4 text-right text-emerald-600 font-medium">
                          {formatCurrency(inv.amount_paid)}
                        </td>
                        <td className="px-6 py-4 text-right text-rose-600 font-medium">
                          {formatCurrency(remain)}
                        </td>
                        <td className="px-6 py-4 text-center">
                          {getStatusBadge(inv.status)}
                        </td>
                        <td className="px-6 py-4 text-right space-x-2 flex justify-end">
                          <button 
                            onClick={() => {
                              setPrintInvoice(inv);
                              setPrintMode('receipt');
                            }}
                            className="p-2 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition-colors"
                            title="Print Receipt"
                          >
                            <Printer className="w-4 h-4" />
                          </button>
                          {inv.status !== 'Paid' && (
                            <button 
                              onClick={() => handlePayClick(inv)}
                              className="flex items-center space-x-1 px-3 py-1.5 bg-emerald-50 text-emerald-700 hover:bg-emerald-100 rounded-lg transition-colors font-medium text-xs"
                            >
                              <DollarSign className="w-3.5 h-3.5" />
                              <span>Pay</span>
                            </button>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                  {invoices.length === 0 && (
                    <tr>
                      <td colSpan="6" className="px-6 py-10 text-center text-gray-400">
                        No subscription invoices found for this apartment.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      {/* Payment Prompt Modal */}
      {payingInvoice && (
        <div className="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-gray-900/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-sm overflow-hidden p-6">
            <h3 className="text-xl font-bold text-gray-800 mb-2">Record Payment</h3>
            <p className="text-sm text-gray-500 mb-6">
              Enter the exact amount paid for invoice due on {formatDate(payingInvoice.due_date)}.
            </p>
            
            <div className="mb-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">Amount Paid (USD)</label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <DollarSign className="h-5 w-5 text-gray-400" />
                </div>
                <input
                  type="number"
                  step="0.01"
                  value={paymentAmount}
                  onChange={(e) => setPaymentAmount(e.target.value)}
                  className="pl-10 block w-full rounded-xl border-gray-300 shadow-sm focus:ring-emerald-500 focus:border-emerald-500 sm:text-lg border py-3 px-4 outline-none"
                  placeholder="0.00"
                />
              </div>
            </div>

            <div className="flex space-x-3">
              <button
                onClick={() => setPayingInvoice(null)}
                className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl font-medium transition-colors"
                disabled={paymentLoading}
              >
                Cancel
              </button>
              <button
                onClick={submitPayment}
                disabled={paymentLoading || !paymentAmount || isNaN(paymentAmount)}
                className="flex-1 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 disabled:opacity-50 text-white rounded-xl font-medium transition-colors flex justify-center items-center"
              >
                {paymentLoading ? (
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                ) : (
                  'Record Pay'
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ApartmentInvoicesModal;
