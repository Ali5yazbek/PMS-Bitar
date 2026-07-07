import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { X, Home, Plus, FileText, Image as ImageIcon, DollarSign, Search } from 'lucide-react';
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
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    const dateStr = format(new Date(cost.date), 'dd MMM yyyy').toLowerCase();
    const rawDate = cost.date.toLowerCase();
    const amountStr = cost.amount.toString();
    const supplierStr = cost.supplier_name?.toLowerCase() || '';
    
    return supplierStr.includes(term) || amountStr.includes(term) || dateStr.includes(term) || rawDate.includes(term);
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
    <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-[100] p-4 sm:p-6">
      <div className="bg-slate-900 border border-slate-700 w-full max-w-6xl h-[90vh] rounded-2xl flex flex-col shadow-2xl overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        
        {/* Header */}
        <div className="flex justify-between items-center p-6 border-b border-slate-800 bg-slate-900/50">
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
        <div className="flex flex-1 overflow-hidden">
          {/* Left Panel: Apartments List */}
          <div className="w-1/3 border-r border-slate-800 bg-slate-900/30 overflow-y-auto hide-scrollbar p-4 space-y-3">
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
                  <span className="text-xs text-slate-400">Current Month Cost</span>
                  <span className={`font-semibold ${apt.current_month_cost > 0 ? 'text-danger' : 'text-slate-500'}`}>
                    ${parseFloat(apt.current_month_cost || 0).toLocaleString(undefined, { minimumFractionDigits: 2 })}
                  </span>
                </div>
              </button>
            ))}
          </div>

          {/* Right Panel: Cost Details & Form */}
          <div className="w-2/3 flex flex-col bg-slate-900">
            {!selectedApartment ? (
              <div className="flex-1 flex flex-col items-center justify-center text-slate-500">
                <FileText size={64} className="mb-4 opacity-50" />
                <p className="text-lg">Select an apartment to view or add costs.</p>
              </div>
            ) : (
              <>
                {/* Right Panel Header */}
                <div className="p-6 border-b border-slate-800 flex justify-between items-center shrink-0">
                  <h3 className="text-xl font-bold text-white flex items-center gap-2">
                    <Home className="text-primary" size={24} />
                    Apartment {selectedApartment.code} Costs
                  </h3>
                  {!showAddForm && (
                    <button 
                      onClick={() => setShowAddForm(true)}
                      className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center gap-2 transition-colors shadow-lg shadow-primary/20"
                    >
                      <Plus size={18} />
                      Add Invoice / Cost
                    </button>
                  )}
                </div>

                <div className="flex-1 overflow-y-auto p-6">
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
                      <div className="relative mb-4 shrink-0">
                        <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
                        <input
                          type="text"
                          placeholder="Search by date, price, or supplier..."
                          value={searchTerm}
                          onChange={(e) => setSearchTerm(e.target.value)}
                          className="w-full bg-slate-800/80 border border-slate-700 rounded-lg pl-10 pr-4 py-2.5 text-white focus:ring-2 focus:ring-primary outline-none"
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
                              <p className="text-sm text-slate-400 mb-2">{format(new Date(cost.date), 'dd MMM yyyy')}</p>
                              {cost.notes && (
                                <p className="text-slate-300 text-sm bg-slate-900/50 p-3 rounded-lg border border-slate-800/50">{cost.notes}</p>
                              )}
                            </div>
                            {cost.receipt_image && (
                              <div className="shrink-0 ml-4">
                                <a 
                                  href={`${api.defaults.baseURL.replace('/api', '')}${cost.receipt_image}`}
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
                                      src={`${api.defaults.baseURL.replace('/api', '')}${cost.receipt_image}`} 
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
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default ApartmentCostsModal;
