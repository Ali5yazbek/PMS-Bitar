import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { X, Home, Plus, FileText, Image as ImageIcon, DollarSign, Search, Printer } from 'lucide-react';
import PrintLogo from './PrintLogo';
import { format } from 'date-fns';

const ApartmentCostsModal = ({ building, onClose }) => {
  const queryClient = useQueryClient();
  const [selectedApartment, setSelectedApartment] = useState(null);
  const [showAddForm, setShowAddForm] = useState(false);
  
  // Form State
  const [supplierName, setSupplierName] = useState('');
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState(format(new Date(), 'yyyy-MM-dd'));
  const [notes, setNotes] = useState('');
  const [receiptImage, setReceiptImage] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStartDate, setFilterStartDate] = useState('');
  const [filterEndDate, setFilterEndDate] = useState('');
  const [reviewCost, setReviewCost] = useState(null);
  const [posInvoice, setPosInvoice] = useState(null);
  const [loadingPos, setLoadingPos] = useState(false);
  const [lightboxImage, setLightboxImage] = useState(null);

  const handleReview = async (cost) => {
    setReviewCost(cost);
    const match = cost.notes?.match(/INV-\d+-\d+/);
    if (match) {
      const ref = match[0];
      setLoadingPos(true);
      try {
        const res = await api.get(`/pos/invoices/by-reference/${ref}`);
        setPosInvoice(res.data);
      } catch (err) {
        console.error("Failed to load POS Invoice", err);
      }
      setLoadingPos(false);
    } else {
      setPosInvoice(null);
    }
  };

  // Fetch apartments for this building
  const { data: apartments, isLoading: loadingApts } = useQuery({
    queryKey: ['buildingApartmentsCosts', building.id],
    queryFn: async () => {
      const res = await api.get(`/buildings/${building.id}/apartment-costs`);
      return res.data;
    },
    enabled: !!building.id
  });

  // Fetch costs history for selected apartment
  const { data: costsHistory, isLoading: loadingHistory } = useQuery({
    queryKey: ['apartmentCostsHistory', selectedApartment?.id],
    queryFn: async () => {
      const res = await api.get(`/apartments/${selectedApartment.id}/costs`);
      return res.data;
    },
    enabled: !!selectedApartment
  });

  const addCostMutation = useMutation({
    mutationFn: async (formData) => {
      const res = await api.post(`/apartments/${selectedApartment.id}/costs`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      return res.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['apartmentCostsHistory', selectedApartment?.id]);
      queryClient.invalidateQueries(['buildingApartmentsCosts', building.id]);
      queryClient.invalidateQueries(['apartmentCostsReport']);
      resetForm();
    }
  });

  const handleImageChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setReceiptImage(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const resetForm = () => {
    setShowAddForm(false);
    setSupplierName('');
    setAmount('');
    setDate(format(new Date(), 'yyyy-MM-dd'));
    setNotes('');
    setReceiptImage(null);
    setPreviewUrl(null);
  };

  const filteredHistory = costsHistory?.filter(cost => {
    let matchesSearch = true;
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      const dateStr = format(new Date(cost.date), 'dd MMM yyyy').toLowerCase();
      const rawDate = cost.date.toLowerCase();
      const amountStr = cost.amount.toString();
      const supplierStr = cost.supplier_name?.toLowerCase() || '';
      matchesSearch = supplierStr.includes(term) || amountStr.includes(term) || dateStr.includes(term) || rawDate.includes(term);
    }
    
    let matchesDate = true;
    if (filterStartDate) {
      matchesDate = matchesDate && cost.date >= filterStartDate;
    }
    if (filterEndDate) {
      matchesDate = matchesDate && cost.date <= filterEndDate;
    }

    return matchesSearch && matchesDate;
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!amount) return alert('Amount is required');
    
    const formData = new FormData();
    formData.append('supplier_name', supplierName);
    formData.append('amount', amount);
    formData.append('date', date);
    formData.append('notes', notes);
    if (receiptImage) {
      formData.append('receipt_image', receiptImage);
    }
    
    addCostMutation.mutate(formData);
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-[100] p-4 print:p-0 print:bg-white print:block">
      <div className="bg-slate-900 border border-slate-700 w-full max-w-6xl h-[90vh] rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 flex flex-col relative print:h-auto print:shadow-none print:border-none print:rounded-none print:overflow-visible print:bg-white print:text-black print:block print:m-0">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-slate-800 bg-slate-900/50 print:hidden">
          <div>
            <h2 className="text-2xl font-bold text-white">Apartment Costs</h2>
            <p className="text-slate-400 mt-1">Building: {building.name}</p>
          </div>
          <button 
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Body */}
        <div className="flex flex-1 overflow-hidden print:overflow-visible print:block">
          {/* Left Panel: Apartments List */}
          <div className="w-1/3 border-r border-slate-800 bg-slate-900/30 overflow-y-auto hide-scrollbar p-4 space-y-3 print:hidden">
            <h3 className="text-slate-400 font-semibold mb-4 text-sm uppercase tracking-wider px-2">Select Apartment</h3>
            {loadingApts ? (
              <div className="animate-pulse space-y-3">
                {[...Array(5)].map((_, i) => (
                  <div key={i} className="h-20 bg-slate-800/50 rounded-xl"></div>
                ))}
              </div>
            ) : apartments?.map(apt => (
              <button
                key={apt.id}
                onClick={() => { setSelectedApartment(apt); resetForm(); }}
                className={`w-full text-left p-4 rounded-xl transition-all border ${
                  selectedApartment?.id === apt.id 
                    ? 'bg-primary/20 border-primary text-white shadow-lg shadow-primary/10' 
                    : 'bg-slate-800/40 border-slate-700/50 text-slate-300 hover:bg-slate-800'
                }`}
              >
                <div className="flex justify-between items-center mb-2">
                  <div className="flex items-center gap-2 font-bold text-lg">
                    <Home size={18} className={selectedApartment?.id === apt.id ? 'text-primary' : 'text-slate-400'} />
                    Apt {apt.code}
                  </div>
                </div>
                <div className="flex justify-between items-end">
                  <span className="text-xs text-slate-400">Total Cost</span>
                  <span className={`font-semibold ${apt.total_cost > 0 ? 'text-danger' : 'text-slate-500'}`}>
                    ${parseFloat(apt.total_cost || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                  </span>
                </div>
              </button>
            ))}
          </div>

          {/* Right Panel: Cost Details & Form */}
          <div className="w-2/3 flex flex-col bg-slate-900 print:w-full print:block print:bg-white">
            {!selectedApartment ? (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
                <FileText size={64} className="mb-4 opacity-50" />
                <p className="text-lg">Select an apartment to view or add costs.</p>
              </div>
            ) : (
              <>
                {/* Right Panel Header */}
                <div className="p-6 border-b border-slate-800 flex justify-between items-center shrink-0 print:hidden">
                  <h3 className="text-xl font-bold text-white flex items-center gap-2">
                    <Home className="text-primary" size={24} />
                    Apartment {selectedApartment.code} Costs
                  </h3>
                  {!showAddForm && (
                    <div className="flex items-center gap-3">
                        <button 
                          onClick={() => setTimeout(() => window.print(), 100)}
                          className="bg-slate-800 border border-slate-700 hover:bg-slate-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors"
                        >
                          <Printer size={18} />
                          Print Report
                        </button>
                        <button 
                          onClick={() => setShowAddForm(true)}
                          className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors shadow-lg shadow-primary/20"
                        >
                          <Plus size={18} />
                          Add Invoice / Cost
                        </button>
                    </div>
                  )}
                </div>

                <div className="flex-1 overflow-y-auto p-6 print:hidden">
                  {showAddForm ? (
                    /* ADD COST FORM */
                    <div className="glass-card p-6 rounded-2xl border border-slate-700/50 max-w-2xl mx-auto">
                      <h4 className="text-lg font-bold text-white mb-6">Create New Invoice</h4>
                      <form onSubmit={handleSubmit} className="space-y-5">
                        <div className="grid grid-cols-2 gap-5">
                          <div>
                            <label className="block text-sm font-medium text-slate-400 mb-1">Source / Supplier</label>
                            <input 
                              type="text" 
                              required
                              value={supplierName}
                              onChange={e => setSupplierName(e.target.value)}
                              placeholder="e.g. Home Depot, Plumber"
                              className="w-full bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                            />
                          </div>
                          <div>
                            <label className="block text-sm font-medium text-slate-400 mb-1">Date</label>
                            <input 
                              type="date" 
                              required
                              value={date}
                              onChange={e => setDate(e.target.value)}
                              className="w-full bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                            />
                          </div>
                        </div>
                        
                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-1">Deployment Cost ($)</label>
                          <div className="relative">
                            <DollarSign className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                            <input 
                              type="number"
                              step="0.01"
                              required
                              value={amount}
                              onChange={e => setAmount(e.target.value)}
                              placeholder="0.00"
                              className="w-full bg-slate-800/80 border border-slate-700 rounded-lg pl-10 pr-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                            />
                          </div>
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-1">Notes</label>
                          <textarea 
                            rows="3"
                            value={notes}
                            onChange={e => setNotes(e.target.value)}
                            placeholder="Add details about this cost..."
                            className="w-full bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none resize-none"
                          />
                        </div>

                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-2">Receipt Image</label>
                          <div className="flex items-start gap-4">
                            <label className="flex flex-col items-center justify-center w-32 h-32 border-2 border-dashed border-slate-600 hover:border-primary rounded-xl cursor-pointer bg-slate-800/50 hover:bg-slate-800 transition-colors">
                              <ImageIcon size={24} className="text-slate-400 mb-2" />
                              <span className="text-xs text-slate-400 text-center px-2">Upload<br/>Receipt</span>
                              <input 
                                type="file" 
                                className="hidden" 
                                accept="image/*,.pdf"
                                onChange={handleImageChange}
                              />
                            </label>
                            {previewUrl && (
                              <div className="relative w-32 h-32 rounded-xl overflow-hidden border border-slate-700">
                                <img src={previewUrl} alt="Preview" className="w-full h-full object-cover" />
                                <button 
                                  type="button"
                                  onClick={() => { setReceiptImage(null); setPreviewUrl(null); }}
                                  className="absolute top-1 right-1 bg-black/60 p-1 rounded-full text-white hover:bg-danger transition-colors"
                                >
                                  <X size={14} />
                                </button>
                              </div>
                            )}
                          </div>
                        </div>

                        <div className="flex gap-3 pt-4 border-t border-slate-700/50">
                          <button 
                            type="button"
                            onClick={resetForm}
                            className="flex-1 px-4 py-2.5 rounded-xl text-white bg-slate-700 hover:bg-slate-600 transition-colors"
                          >
                            Cancel
                          </button>
                          <button 
                            type="submit"
                            disabled={addCostMutation.isLoading}
                            className="flex-1 px-4 py-2.5 rounded-xl text-white bg-success hover:bg-green-600 transition-colors shadow-lg shadow-success/20 disabled:opacity-50"
                          >
                            {addCostMutation.isLoading ? 'Saving...' : 'Save Invoice'}
                          </button>
                        </div>
                      </form>
                    </div>
                  ) : (
                    /* COST HISTORY */
                    <div className="flex flex-col h-full">
                      <div className="flex gap-3 mb-4 shrink-0">
                        <div className="relative flex-1">
                          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                          <input
                            type="text"
                            placeholder="Search by date, price, or supplier..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                            className="w-full bg-slate-800/80 border border-slate-700 rounded-lg pl-10 pr-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                          />
                        </div>
                        <input
                          type="date"
                          value={filterStartDate}
                          onChange={(e) => setFilterStartDate(e.target.value)}
                          className="bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                          title="Start Date"
                        />
                        <input
                          type="date"
                          value={filterEndDate}
                          onChange={(e) => setFilterEndDate(e.target.value)}
                          className="bg-slate-800/80 border border-slate-700 rounded-lg px-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
                          title="End Date"
                        />
                      </div>
                      
                      <div className="space-y-4">
                      {loadingHistory ? (
                        <div className="animate-pulse space-y-4">
                          {[...Array(3)].map((_, i) => (
                            <div key={i} className="h-24 bg-slate-800/50 rounded-xl"></div>
                          ))}
                        </div>
                      ) : filteredHistory?.length === 0 ? (
                        <div className="text-center text-slate-500 py-12">
                          <FileText size={48} className="mx-auto mb-4 opacity-50" />
                          <p>{searchTerm ? 'No costs match your search.' : 'No costs recorded for this apartment yet.'}</p>
                        </div>
                      ) : (
                        filteredHistory?.map(cost => (
                          <div key={cost.id} className="bg-slate-800/40 border border-slate-700/50 rounded-xl p-5 flex items-start gap-4 hover:bg-slate-800/60 transition-colors">
                            <div className="bg-slate-900 p-3 rounded-lg text-slate-400 border border-slate-800 shrink-0">
                              <DollarSign size={24} className="text-danger" />
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className="flex justify-between items-start mb-1">
                                <h4 className="font-bold text-white text-lg truncate">{cost.supplier_name || 'Unknown Source'}</h4>
                                <span className="font-bold text-danger whitespace-nowrap ml-4">
                                  ${parseFloat(cost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                </span>
                              </div>
                              <div className="flex items-center gap-3 mb-2">
                                <p className="text-sm text-slate-400">{format(new Date(cost.date), 'dd MMM yyyy')}</p>
                                <button 
                                  onClick={() => handleReview(cost)} 
                                  className="text-xs bg-indigo-500 hover:bg-indigo-600 text-white px-2 py-1 rounded shadow-md transition-colors"
                                >
                                  Review Details
                                </button>
                              </div>
                              {cost.notes && (
                                <p className="text-slate-300 text-sm bg-slate-900/50 p-3 rounded-lg border border-slate-800/50">{cost.notes}</p>
                              )}
                            </div>
                            {cost.receipt_image && (
                              <div className="shrink-0 ml-4">
                                <a 
                                  href={`${api.defaults.baseURL.replace('/api', '')}/${cost.receipt_image.startsWith('/') ? cost.receipt_image.slice(1) : cost.receipt_image}`}
                                  target="_blank"
                                  rel="noreferrer"
                                  className="block w-20 h-20 rounded-lg overflow-hidden border border-slate-700 relative group"
                                >
                                  {cost.receipt_image.toLowerCase().endsWith('.pdf') ? (
                                    <div className="w-full h-full bg-slate-800 flex items-center justify-center text-indigo-400">
                                      <FileText size={32} />
                                    </div>
                                  ) : (
                                    <img 
                                      src={`${api.defaults.baseURL.replace('/api', '')}/${cost.receipt_image.startsWith('/') ? cost.receipt_image.slice(1) : cost.receipt_image}`} 
                                      alt="Receipt"
                                      className="w-full h-full object-cover transition-transform group-hover:scale-110"
                                    />
                                  )}
                                  <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-bold">
                                    View
                                  </div>
                                </a>
                              </div>
                            )}
                          </div>
                        ))
                      )}
                      </div>
                    </div>
                  )}
                </div>
                
                {/* Print View */}
                <div className="hidden print:block font-mono text-black w-full" dir="ltr">
                    <div className="text-center border-b-2 border-black pb-6 mb-6">
                        <PrintLogo />
                        <h1 className="text-3xl font-bold tracking-widest mt-2 mb-1">APARTMENT COSTS REPORT</h1>
                        <p className="text-lg">Apartment: {selectedApartment.code}</p>
                        <p className="text-sm">Building: {building.name}</p>
                        <p className="text-sm">Generated: {new Date().toLocaleString()}</p>
                    </div>
                    
                    <div className="mb-6 flex justify-between">
                        <div>
                            <p className="text-sm font-bold uppercase mb-1">TOTAL DEPLOYED COSTS</p>
                            <p className="text-2xl font-bold">
                                ${filteredHistory?.reduce((sum, cost) => sum + parseFloat(cost.amount || 0), 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                            </p>
                        </div>
                    </div>

                    <table className="w-full text-left border-collapse border border-gray-300">
                        <thead>
                            <tr className="bg-gray-100 border-b border-gray-300">
                                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Date</th>
                                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Supplier / Source</th>
                                <th className="py-2 px-3 text-sm font-bold border-r border-gray-300 text-black">Notes</th>
                                <th className="py-2 px-3 text-sm font-bold border-gray-300 text-black text-right">Amount</th>
                            </tr>
                        </thead>
                        <tbody>
                            {filteredHistory?.map(cost => (
                                <tr key={cost.id} className="border-b border-gray-300">
                                    <td className="py-2 px-3 border-r border-gray-300 text-sm text-black whitespace-nowrap">{format(new Date(cost.date), 'dd MMM yyyy')}</td>
                                    <td className="py-2 px-3 border-r border-gray-300 text-sm text-black">{cost.supplier_name || 'Unknown'}</td>
                                    <td className="py-2 px-3 border-r border-gray-300 text-sm text-black">{cost.notes}</td>
                                    <td className="py-2 px-3 text-sm font-bold text-right text-black">
                                        ${parseFloat(cost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                                    </td>
                                </tr>
                            ))}
                            {filteredHistory?.length === 0 && (
                                <tr>
                                    <td colSpan="4" className="py-4 text-center text-gray-500">No costs recorded.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
              </>
            )}
          </div>
        </div>
      {reviewCost && (
        <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-[150] p-4">
          <div className="bg-slate-900 border border-slate-700 w-full max-w-2xl rounded-2xl shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200 flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center p-4 border-b border-slate-800 bg-slate-800/50">
              <h3 className="text-xl font-bold text-white flex items-center gap-2">
                <FileText className="text-primary" size={20} />
                Cost Details
              </h3>
              <button onClick={() => setReviewCost(null)} className="p-2 text-slate-400 hover:text-white hover:bg-slate-700 rounded-lg transition-colors">
                <X size={20} />
              </button>
            </div>
            <div className="p-6 overflow-y-auto">
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-6">
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <p className="text-sm text-slate-400 mb-1">Supplier</p>
                  <p className="font-bold text-white">{reviewCost.supplier_name || 'Unknown'}</p>
                </div>
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <p className="text-sm text-slate-400 mb-1">Amount</p>
                  <p className="font-bold text-danger text-xl">${parseFloat(reviewCost.amount).toLocaleString(undefined, { minimumFractionDigits: 2 })}</p>
                </div>
                <div className="bg-slate-800/50 p-4 rounded-xl border border-slate-700/50">
                  <p className="text-sm text-slate-400 mb-1">Date</p>
                  <p className="font-bold text-white">{format(new Date(reviewCost.date), 'dd MMM yyyy')}</p>
                </div>
              </div>

              {reviewCost.notes && (
                <div className="mb-6">
                  <h4 className="text-sm font-medium text-slate-400 mb-2">Notes</h4>
                  <p className="bg-slate-800/80 p-4 rounded-xl text-slate-300 border border-slate-700/50">{reviewCost.notes}</p>
                </div>
              )}

              {loadingPos && (
                <div className="flex justify-center p-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
                </div>
              )}

              {posInvoice && (
                <div className="mt-4 border-t border-slate-700 pt-6">
                  <h4 className="text-lg font-bold text-white mb-4">POS Receipt (Ref: {posInvoice.invoice_number})</h4>
                  <div className="bg-slate-950 p-6 rounded-xl font-mono text-sm border border-slate-800">
                    <div className="text-center mb-4 pb-4 border-b border-slate-800 border-dashed">
                      <p className="font-bold text-lg text-white">WAREHOUSE / POS</p>
                      <p className="text-slate-400">{posInvoice.date}</p>
                    </div>
                    <table className="w-full text-slate-300 mb-4">
                      <thead>
                        <tr className="border-b border-slate-800 border-dashed text-left">
                          <th className="pb-2">Item</th>
                          <th className="pb-2 text-right">Qty</th>
                          <th className="pb-2 text-right">Price</th>
                          <th className="pb-2 text-right">Total</th>
                        </tr>
                      </thead>
                      <tbody>
                        {posInvoice.items?.map(item => (
                          <tr key={item.id}>
                            <td className="py-2">{item.name}</td>
                            <td className="py-2 text-right">{item.quantity}</td>
                            <td className="py-2 text-right">${parseFloat(item.cost_price).toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
                            <td className="py-2 text-right">${parseFloat(item.total_price).toLocaleString(undefined, {minimumFractionDigits: 2})}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                    <div className="border-t border-slate-800 border-dashed pt-4 flex flex-col gap-2">
                      <div className="flex justify-between text-slate-400">
                        <span>Subtotal</span>
                        <span>${parseFloat(posInvoice.subtotal).toLocaleString(undefined, {minimumFractionDigits: 2})}</span>
                      </div>
                      {posInvoice.discount > 0 && (
                        <div className="flex justify-between text-success">
                          <span>Discount</span>
                          <span>-${parseFloat(posInvoice.discount).toLocaleString(undefined, {minimumFractionDigits: 2})}</span>
                        </div>
                      )}
                      <div className="flex justify-between text-white font-bold text-lg mt-2 pt-2 border-t border-slate-800 border-dashed">
                        <span>Total</span>
                        <span>${parseFloat(posInvoice.final_amount).toLocaleString(undefined, {minimumFractionDigits: 2})}</span>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {reviewCost.receipt_image && !posInvoice && (
                <div className="mt-6 border-t border-slate-700 pt-6">
                  <h4 className="text-sm font-medium text-slate-400 mb-4">Attached Receipt</h4>
                  {reviewCost.receipt_image.toLowerCase().endsWith('.pdf') ? (
                    <a href={`${api.defaults.baseURL.replace('/api', '')}/${reviewCost.receipt_image.startsWith('/') ? reviewCost.receipt_image.slice(1) : reviewCost.receipt_image}`} target="_blank" rel="noreferrer" className="flex items-center gap-3 bg-slate-800 p-4 rounded-xl border border-slate-700 hover:bg-slate-700 transition-colors text-white">
                      <FileText className="text-indigo-400" />
                      View PDF Document
                    </a>
                  ) : (
                    <div 
                      onClick={() => setLightboxImage(`${api.defaults.baseURL.replace('/api', '')}/${reviewCost.receipt_image.startsWith('/') ? reviewCost.receipt_image.slice(1) : reviewCost.receipt_image}`)}
                      className="cursor-pointer group relative block w-48 h-48 rounded-xl border border-slate-700 overflow-hidden bg-slate-800"
                    >
                      <img src={`${api.defaults.baseURL.replace('/api', '')}/${reviewCost.receipt_image.startsWith('/') ? reviewCost.receipt_image.slice(1) : reviewCost.receipt_image}`} alt="Receipt Thumbnail" className="w-full h-full object-cover transition-transform group-hover:scale-110" />
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-sm font-bold">
                        Click to expand
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
      
      {lightboxImage && (
        <div className="fixed inset-0 bg-black/95 z-[200] flex flex-col items-center justify-center p-4">
          <button 
            onClick={() => setLightboxImage(null)} 
            className="absolute top-6 right-6 text-white bg-slate-800/50 p-2 rounded-full hover:bg-slate-700 transition-colors"
          >
            <X size={24} />
          </button>
          <img src={lightboxImage} alt="Fullscreen Preview" className="max-w-full max-h-[85vh] object-contain rounded-lg shadow-2xl" />
          <div className="mt-6 flex gap-4">
            <a 
              href={lightboxImage} 
              download
              target="_blank"
              rel="noreferrer"
              className="bg-primary hover:bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-medium shadow-lg shadow-primary/20 flex items-center gap-2 transition-colors"
            >
              Download Image
            </a>
          </div>
        </div>
      )}
      </div>
    </div>
  );
};

export default ApartmentCostsModal;
