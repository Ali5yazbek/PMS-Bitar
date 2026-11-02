import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import api from '../../api/axios';
import { Archive, Search, FileText, User, Phone, Zap, DollarSign, Wrench, Download, Mail, ChevronRight, Printer, CheckCircle } from 'lucide-react';
import PrintLogo from '../../components/PrintLogo';
import { format } from 'date-fns';

const TenantArchiveReport = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedArchiveId, setSelectedArchiveId] = useState(null);
  
  // Payment state
  const [paymentModal, setPaymentModal] = useState(null);
  const [payAmount, setPayAmount] = useState('');
  const [printInvoice, setPrintInvoice] = useState(null);

  const payMutation = useMutation({
    mutationFn: (data) => api.post('/rent/payment', data),
    onSuccess: () => {
      queryClient.invalidateQueries(['archived_tenants']);
      setPaymentModal(null);
      setPayAmount('');
    }
  });

  const handlePrint = (invoice) => {
    setPrintInvoice(invoice);
    setTimeout(() => {
      window.print();
      setPrintInvoice(null);
    }, 100);
  };

  const { data: archives, isLoading, error } = useQuery({
    queryKey: ['archived_tenants'],
    queryFn: async () => {
      const res = await api.get('/tenants/archived');
      return res.data;
    }
  });

  const filteredArchives = archives?.filter(a => 
    a.full_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.national_id_passport?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    a.past_apartment_number?.toLowerCase().includes(searchTerm.toLowerCase())
  ) || [];

  const selectedArchive = archives?.find(a => a.archive_id === selectedArchiveId) || (filteredArchives.length > 0 ? filteredArchives[0] : null);

  // Helper to parse JSON safely
  const parseJSON = (data) => {
    if (!data) return null;
    if (typeof data === 'string') {
      try { return JSON.parse(data); } catch { return null; }
    }
    return data;
  };

  const renderContacts = (data) => {
    if (!data || Object.keys(data).length === 0) return <p className="text-slate-500 italic text-sm">{t('No contact details saved.')}</p>;
    return (
      <div className="space-y-1 text-sm">
        <p><span className="text-slate-400 font-medium">{t('Phone:')}</span> <span className="text-slate-200">{data.phone || 'N/A'}</span></p>
        <p><span className="text-slate-400 font-medium">{t('Email:')}</span> <span className="text-slate-200">{data.email || 'N/A'}</span></p>
        <p><span className="text-slate-400 font-medium">{t('ID/Passport:')}</span> <span className="text-slate-200">{data.national_id_passport || 'N/A'}</span></p>
      </div>
    );
  };

  const renderRentLedger = (data, aptNumber) => {
    if (!data || data.length === 0) return <div className="text-slate-500 italic text-sm p-4">{t('No rent invoices found.')}</div>;
    return (
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-slate-400 bg-slate-800/50">
            <tr>
              <th className="py-2 px-3 font-semibold rounded-tl-lg">{t('Date')}</th>
              <th className="py-2 px-3 font-semibold">{t('Apartment')}</th>
              <th className="py-2 px-3 font-semibold">{t('Amount')}</th>
              <th className="py-2 px-3 font-semibold">{t('Status')}</th>
              <th className="py-2 px-3 font-semibold rounded-tr-lg text-right">{t('Actions')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-700/50">
            {data.map((inv, idx) => (
              <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                <td className="py-2 px-3 text-slate-300">{inv.due_date ? format(new Date(inv.due_date), 'MMM dd, yyyy') : 'N/A'}</td>
                <td className="py-2 px-3 text-slate-300">{aptNumber || t('N/A')}</td>
                <td className="py-2 px-3 text-slate-200 font-medium">${inv.amount}</td>
                <td className="py-2 px-3">
                  <span className={`px-2 py-1 rounded text-xs font-bold uppercase ${
                    inv.status === 'Paid' ? 'bg-green-500/20 text-green-400' :
                    inv.status === 'Voided' ? 'bg-slate-500/20 text-slate-400' :
                    'bg-red-500/20 text-red-400'
                  }`}>
                    {inv.status}
                  </span>
                </td>
                <td className="py-2 px-3 text-right">
                  <div className="flex items-center justify-end gap-2">
                    {(inv.status === 'Unpaid' || inv.status === 'Partial') && (
                      <button 
                        onClick={() => setPaymentModal(inv)}
                        className="bg-indigo-600 hover:bg-indigo-700 text-white p-1.5 rounded transition-colors"
                        title={t('Pay Rent')}
                      >
                        <DollarSign size={16} />
                      </button>
                    )}
                    <button 
                      onClick={() => handlePrint(inv)}
                      className="bg-slate-700 hover:bg-slate-600 text-white p-1.5 rounded transition-colors"
                      title={t('Print Receipt')}
                    >
                      <Printer size={16} />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  };

  const renderUtilities = (data, aptNumber) => {
    const elec = data?.electricity || [];
    if (!elec || elec.length === 0) return <div className="text-slate-500 italic text-sm p-4">{t('No utility bills found.')}</div>;
    return (
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-slate-400 bg-slate-800/50">
            <tr>
              <th className="py-2 px-3 font-semibold rounded-tl-lg">{t('Type')}</th>
              <th className="py-2 px-3 font-semibold">{t('Apartment')}</th>
              <th className="py-2 px-3 font-semibold">{t('Amount')}</th>
              <th className="py-2 px-3 font-semibold">{t('Due Date')}</th>
              <th className="py-2 px-3 font-semibold rounded-tr-lg">{t('Status')}</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-700/50">
            {elec.map((inv, idx) => (
              <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                <td className="py-2 px-3 text-slate-300">{inv.type}</td>
                <td className="py-2 px-3 text-slate-300">{aptNumber || t('N/A')}</td>
                <td className="py-2 px-3 text-slate-200 font-medium">${inv.amount}</td>
                <td className="py-2 px-3 text-slate-300">{inv.due_date ? format(new Date(inv.due_date), 'MMM dd, yyyy') : 'N/A'}</td>
                <td className="py-2 px-3">
                  <span className={`px-2 py-1 rounded text-xs font-bold uppercase ${
                    inv.status === 'Paid' ? 'bg-green-500/20 text-green-400' :
                    'bg-red-500/20 text-red-400'
                  }`}>
                    {inv.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  };
  
  const renderMaintenance = (data) => {
    if (!data || data.length === 0) return <div className="text-slate-500 italic text-sm p-4">{t('No maintenance requests found.')}</div>;
    return (
      <div className="space-y-3 mt-2">
        {data.map((req, idx) => (
          <div key={idx} className="bg-slate-800/40 p-3 rounded-lg border border-slate-700/50">
            <div className="flex justify-between items-start mb-1">
              <h4 className="text-sm text-slate-200 font-medium">{req.issue_type}</h4>
              <span className={`text-[10px] px-2 py-0.5 rounded font-bold uppercase ${
                req.status === 'Resolved' ? 'bg-green-500/20 text-green-400' : 'bg-slate-700 text-slate-300'
              }`}>
                {req.status}
              </span>
            </div>
            <p className="text-xs text-slate-400">{req.description}</p>
          </div>
        ))}
      </div>
    );
  };

  const calcTotals = (rentData, utilData) => {
    let total = 0, paid = 0, unpaid = 0;
    
    // Rent
    if (rentData && Array.isArray(rentData)) {
      rentData.forEach(inv => {
        const amt = parseFloat(inv.amount) || 0;
        if (inv.status === 'Voided') return;
        total += amt;
        if (inv.status === 'Paid') paid += amt;
        else unpaid += amt;
      });
    }

    // Utilities
    if (utilData && utilData.electricity && Array.isArray(utilData.electricity)) {
      utilData.electricity.forEach(inv => {
        const amt = parseFloat(inv.amount) || 0;
        total += amt;
        if (inv.status === 'Paid') paid += amt;
        else unpaid += amt;
      });
    }
    
    return { total, paid, unpaid };
  };

  const handleEmail = () => {
    if (!selectedArchive) return;
    const contactData = parseJSON(selectedArchive.contact_details) || {};
    const toEmail = contactData.email || '';
    const subject = encodeURIComponent(`Archived Tenant Record: ${selectedArchive.full_name}`);
    const body = encodeURIComponent(`Hello ${selectedArchive.full_name},\n\nPlease find your archived record summary for your stay at ${selectedArchive.past_apartment_number || 'our property'}.\n\nTermination Date: ${selectedArchive.termination_date ? format(new Date(selectedArchive.termination_date), 'MMMM dd, yyyy') : 'N/A'}\n\nBest regards,\nProperty Management`);
    window.location.href = `mailto:${toEmail}?subject=${subject}&body=${body}`;
  };

  if (isLoading) return <div className="p-8 text-center text-slate-400 animate-pulse">{t('Loading archive master records...')}</div>;
  if (error) return <div className="p-8 text-center text-red-400">{t('Failed to load archive data.')}</div>;

  return (
    <div className="p-6 w-full max-w-[1800px] mx-auto h-[calc(100vh-100px)] flex flex-col">
      {/* Header Area */}
      <div className="text-center mb-6">
        <h1 className="text-2xl font-bold text-white uppercase tracking-wider">{t('Archived Tenant Report')}</h1>
        <p className="text-slate-400 text-sm mt-1">{t('View history and records of past terminated tenants')}</p>
      </div>

      {/* Main Layout Card */}
      <div className="bg-slate-900 rounded-xl border border-slate-700 overflow-hidden flex flex-col flex-1 shadow-2xl">
        
        {/* Toolbar */}
        <div className="p-4 border-b border-slate-700 flex flex-col md:flex-row gap-4 items-center bg-slate-800/50 no-print">
          <div className="relative w-full md:w-96">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input
              type="text"
              placeholder="Search by name, ID, or Apt..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full bg-slate-900 border border-slate-600 text-white rounded-md pl-10 pr-4 py-2 text-sm focus:ring-1 focus:ring-primary focus:border-primary outline-none transition-all"
            />
          </div>
          
          <div className="flex items-center gap-2 ml-auto w-full md:w-auto">
            <span className="text-slate-400 text-sm">{t('Filter:')}</span>
            <select className="bg-slate-900 border border-slate-600 text-white rounded-md px-3 py-2 text-sm focus:outline-none">
              <option>{t('Date and past apartment number')}</option>
              <option>Termination Date (Newest)</option>
              <option>Name (A-Z)</option>
            </select>
          </div>
        </div>

        {/* Split View */}
        <div className="flex flex-1 overflow-hidden">
          
          {/* Left Sidebar (List) */}
          <div className="w-80 lg:w-96 shrink-0 border-r border-slate-700 bg-slate-800/20 overflow-y-auto hidden md:block no-print">
            <div className="p-3 text-xs font-bold text-slate-500 uppercase tracking-wider">Result ({filteredArchives.length})</div>
            <div className="space-y-1 p-2">
              {filteredArchives.map(archive => (
                <div 
                  key={archive.archive_id}
                  onClick={() => setSelectedArchiveId(archive.archive_id)}
                  className={`p-3 rounded-lg cursor-pointer transition-colors border ${
                    selectedArchive?.archive_id === archive.archive_id 
                      ? 'bg-primary/10 border-primary/30' 
                      : 'border-transparent hover:bg-slate-800'
                  }`}
                >
                  <h4 className={`font-semibold ${selectedArchive?.archive_id === archive.archive_id ? 'text-primary' : 'text-slate-200'}`}>
                    {archive.full_name}
                  </h4>
                  <p className="text-xs text-slate-400 mt-1 line-clamp-1">
                    {archive.past_apartment_number || 'No Apt Data'}
                  </p>
                </div>
              ))}
              
              {filteredArchives.length === 0 && (
                <div className="p-4 text-center text-slate-500 text-sm">{t('No tenants found')}</div>
              )}
            </div>
          </div>

          {/* Right Content Area */}
          <div className="flex-1 overflow-y-auto bg-slate-900/50 p-6">
            {selectedArchive ? (
              <div className="w-full max-w-6xl mx-auto space-y-6">
                
                {/* Profile Header */}
                <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 p-5 bg-slate-800/40 border border-slate-700 rounded-xl">
                  <div className="flex items-center gap-5">
                    <div className="w-20 h-20 rounded-full bg-slate-700 flex items-center justify-center text-slate-400 text-3xl font-bold border-2 border-slate-600 shrink-0">
                      {selectedArchive.full_name.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <h2 className="text-xl font-bold text-white mb-2">{selectedArchive.full_name}</h2>
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-1 text-sm">
                        <p><span className="text-slate-400">{t('ID/Passport:')}</span> <span className="text-slate-200 font-medium">{selectedArchive.national_id_passport || 'N/A'}</span></p>
                        <p><span className="text-slate-400">{t('Last Apartment:')}</span> <span className="text-slate-200 font-medium">{selectedArchive.past_apartment_number || 'N/A'}</span></p>
                        <p><span className="text-slate-400">{t('Status:')}</span> <span className="text-slate-200 font-medium">{t('Archived / Terminated')}</span></p>
                        <p><span className="text-slate-400">{t('Termination Date:')}</span> <span className="text-slate-200 font-medium">{selectedArchive.termination_date ? format(new Date(selectedArchive.termination_date), 'MMMM dd, yyyy') : 'N/A'}</span></p>
                      </div>
                    </div>
                  </div>
                  <div className="flex flex-col gap-2 w-full md:w-auto no-print">
                    <button onClick={() => window.print()} className="flex items-center justify-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-medium rounded-lg border border-slate-600 transition-colors">
                      <Download size={16} /> {t('Export as PDF')}
                    </button>
                    <button onClick={handleEmail} className="flex items-center justify-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-sm font-medium rounded-lg border border-slate-600 transition-colors">
                      <Mail size={16} /> {t('Email Record')}
                    </button>
                  </div>
                </div>

                {/* Grids */}
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                  
                  {/* Rental History */}
                  <div className="space-y-4">
                    <h3 className="font-bold text-slate-300 uppercase tracking-wide text-sm flex items-center gap-2">
                      <DollarSign size={16} className="text-primary" /> {t('Rental History')}
                    </h3>
                    <div className="bg-slate-800/30 border border-slate-700/50 rounded-xl overflow-hidden max-h-64 overflow-y-auto custom-scrollbar">
                      {renderRentLedger(parseJSON(selectedArchive.rental_ledger), selectedArchive.past_apartment_number)}
                    </div>
                  </div>

                  {/* Insurance / Contacts */}
                  <div className="space-y-6">
                    <div>
                      <h3 className="font-bold text-slate-300 uppercase tracking-wide text-sm flex items-center gap-2 mb-4">
                        <Phone size={16} className="text-primary" /> {t('Contact & Documents')}
                      </h3>
                      <div className="bg-slate-800/30 border border-slate-700/50 rounded-xl p-4">
                         {renderContacts(parseJSON(selectedArchive.contact_details))}
                      </div>
                    </div>
                    
                    <div>
                      <h3 className="font-bold text-slate-300 uppercase tracking-wide text-sm flex items-center gap-2 mb-4">
                        <Wrench size={16} className="text-primary" /> {t('Maintenance')}
                      </h3>
                      <div className="bg-slate-800/30 border border-slate-700/50 rounded-xl p-2 max-h-40 overflow-y-auto custom-scrollbar">
                         {renderMaintenance(parseJSON(selectedArchive.maintenance_history))}
                      </div>
                    </div>
                  </div>

                  {/* Utilities */}
                  <div className="space-y-4">
                    <h3 className="font-bold text-slate-300 uppercase tracking-wide text-sm flex items-center gap-2">
                      <Zap size={16} className="text-primary" /> {t('Utilities')}
                    </h3>
                    <div className="bg-slate-800/30 border border-slate-700/50 rounded-xl overflow-hidden max-h-64 overflow-y-auto custom-scrollbar">
                      {renderUtilities(parseJSON(selectedArchive.utility_ledger), selectedArchive.past_apartment_number)}
                    </div>
                  </div>

                  {/* Totals / Summary block */}
                  <div className="space-y-4">
                    <h3 className="font-bold text-slate-300 uppercase tracking-wide text-sm flex items-center gap-2">
                      <FileText size={16} className="text-primary" /> {t('Financial Summary')}
                    </h3>
                    
                    {(() => {
                      const rentData = parseJSON(selectedArchive.rental_ledger);
                      const utilData = parseJSON(selectedArchive.utility_ledger);
                      const { total, paid, unpaid } = calcTotals(rentData, utilData);
                      
                      const paidPct = total > 0 ? (paid / total) * 100 : 0;
                      const unpaidPct = total > 0 ? (unpaid / total) * 100 : 0;

                      return (
                        <div className="bg-slate-800/30 border border-slate-700/50 rounded-xl p-5 space-y-4">
                          <div className="flex items-center justify-between text-sm">
                            <span className="text-slate-400">{t('Total Billed')}</span>
                            <span className="font-bold text-slate-200">${total.toFixed(2)}</span>
                          </div>
                          
                          <div className="flex items-center gap-4">
                            <span className="text-sm text-slate-400 w-12">{t('Paid')}</span>
                            <div className="flex-1 h-3 bg-slate-700 rounded-full overflow-hidden">
                              <div className="h-full bg-green-500 rounded-full" style={{ width: `${paidPct}%` }}></div>
                            </div>
                            <span className="text-sm font-bold text-green-400 w-20 text-right">${paid.toFixed(2)}</span>
                          </div>

                          <div className="flex items-center gap-4">
                            <span className="text-sm text-slate-400 w-12">{t('Unpaid')}</span>
                            <div className="flex-1 h-3 bg-slate-700 rounded-full overflow-hidden">
                              <div className="h-full bg-red-500 rounded-full" style={{ width: `${unpaidPct}%` }}></div>
                            </div>
                            <span className="text-sm font-bold text-red-400 w-20 text-right">${unpaid.toFixed(2)}</span>
                          </div>
                          
                        </div>
                      );
                    })()}
                  </div>

                </div>
              </div>
            ) : (
              <div className="h-full flex flex-col items-center justify-center text-slate-500">
                <Archive size={48} className="mb-4 opacity-50 text-slate-600" />
                <p className="text-lg">{t('Select a tenant to view their archived record.')}</p>
              </div>
            )}
          </div>
        </div>
      </div>
      {/* Modals & Print */}
      {paymentModal && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex justify-center items-center z-50 p-4 print:hidden">
          <div className="bg-slate-900 border border-slate-700 rounded-2xl p-6 w-full max-w-md shadow-2xl">
            <h3 className="text-xl font-bold text-white mb-2">{t('Pay Rent')}</h3>
            <p className="text-slate-400 text-sm mb-6">
              Invoice #{paymentModal.invoice_number || paymentModal.id} <br/>
              Due: {format(new Date(paymentModal.due_date), 'MMM dd, yyyy')}
            </p>
            <div className="mb-6">
              <label className="block text-sm font-medium text-slate-300 mb-2">{t('Payment Amount')}</label>
              <div className="relative">
                <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                <input
                  type="number"
                  value={payAmount}
                  onChange={(e) => setPayAmount(e.target.value)}
                  placeholder={paymentModal.amount}
                  className="w-full bg-slate-800/80 border border-slate-700 rounded-lg pl-10 pr-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                />
              </div>
            </div>
            <div className="flex gap-3">
              <button onClick={() => setPaymentModal(null)} className="flex-1 bg-slate-800 hover:bg-slate-700 text-white py-2.5 rounded-lg transition-colors">
                {t('Cancel')}
              </button>
              <button 
                disabled={payMutation.isLoading || !payAmount}
                onClick={() => payMutation.mutate({ invoice_id: paymentModal.id, amount: payAmount, notes: 'Archived Tenant Payment' })}
                className="flex-1 bg-success hover:bg-green-600 text-white py-2.5 rounded-lg transition-colors shadow-lg shadow-success/20 disabled:opacity-50"
              >
                {payMutation.isLoading ? t('Processing...') : t('Submit Payment')}
              </button>
            </div>
          </div>
        </div>
      )}

      {printInvoice && (
        <div className="hidden print:block p-8 bg-white text-black font-sans min-h-screen">
          <div className="flex justify-between items-start mb-10 border-b-2 border-slate-200 pb-8">
            <div className="flex items-center gap-4">
              <PrintLogo />
              <div>
                <h1 className="text-3xl font-bold text-slate-800">Rent Receipt</h1>
                <p className="text-slate-500">Invoice #{printInvoice.invoice_number || printInvoice.id}</p>
              </div>
            </div>
            <div className="text-right">
              <p className="text-slate-500">Date: {format(new Date(), 'MMM dd, yyyy')}</p>
              <p className="text-slate-500">Due Date: {format(new Date(printInvoice.due_date), 'MMM dd, yyyy')}</p>
            </div>
          </div>
          <div className="mb-8">
            <h3 className="text-xl font-bold text-slate-800 mb-2">Tenant Details</h3>
            <p className="text-slate-600">{selectedArchive?.full_name}</p>
            <p className="text-slate-600">{selectedArchive?.phone}</p>
          </div>
          <table className="w-full text-left mb-8">
            <thead>
              <tr className="bg-slate-50 text-slate-700 border-y border-slate-200">
                <th className="py-3 px-4 font-semibold">Description</th>
                <th className="py-3 px-4 font-semibold text-right">Amount</th>
              </tr>
            </thead>
            <tbody>
              <tr className="border-b border-slate-100">
                <td className="py-4 px-4 text-slate-800">Rent Payment for {format(new Date(printInvoice.due_date), 'MMMM yyyy')}</td>
                <td className="py-4 px-4 text-right font-bold text-slate-800">${printInvoice.amount}</td>
              </tr>
            </tbody>
          </table>
          <div className="flex justify-end mt-8">
            <div className="w-1/3">
              <div className="flex justify-between items-center text-xl font-bold text-slate-800 bg-slate-50 p-4 rounded-xl border border-slate-200">
                <span>Total Amount:</span>
                <span>${printInvoice.amount}</span>
              </div>
            </div>
          </div>
          <div className="mt-16 text-center text-sm text-slate-400">
            <p>This is a computer generated document. No signature is required.</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default TenantArchiveReport;
