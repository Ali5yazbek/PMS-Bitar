import React, { useState, useEffect } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import axios from '../api/axios';
import { Search, ShoppingCart, Plus, Minus, Trash2, CreditCard, Package, History, X, Edit2, Printer } from 'lucide-react';
import PrintLogo from '../components/PrintLogo';

const POS = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [cart, setCart] = useState([]);
  const [customerType, setCustomerType] = useState('Walk-In');
  const [customerId, setCustomerId] = useState('');
  const [customerName, setCustomerName] = useState('');
  const [selectedBuildingId, setSelectedBuildingId] = useState('');
  const [selectedApartmentId, setSelectedApartmentId] = useState('');
  const [lastInvoice, setLastInvoice] = useState(null);
  const [discount, setDiscount] = useState(0);
  const [showHistory, setShowHistory] = useState(false);
  
  // Edit Mode state
  const [viewingInvoiceId, setViewingInvoiceId] = useState(null);
  const [viewingInvoiceNumber, setViewingInvoiceNumber] = useState('');

  const { data: products, isLoading } = useQuery({
    queryKey: ['products'],
    queryFn: async () => (await axios.get('/warehouse')).data
  });

  const { data: constructions = [] } = useQuery({
    queryKey: ['constructions'],
    queryFn: async () => (await axios.get('/constructions')).data
  });

  const { data: buildings = [] } = useQuery({
    queryKey: ['buildings'],
    queryFn: async () => (await axios.get('/buildings')).data
  });

  const { data: apartments = [] } = useQuery({
    queryKey: ['apartments'],
    queryFn: async () => (await axios.get('/apartments')).data
  });

  const { data: apartmentTotalCosts } = useQuery({
    queryKey: ['apartmentTotalCosts', selectedApartmentId],
    queryFn: async () => (await axios.get(`/apartments/${selectedApartmentId}/costs/total`)).data,
    enabled: !!selectedApartmentId
  });

  const { data: posInvoices = [], refetch: refetchInvoices } = useQuery({
    queryKey: ['posInvoices'],
    queryFn: async () => (await axios.get('/pos/invoices')).data,
    enabled: showHistory || !!viewingInvoiceId
  });

  const filteredProducts = Array.isArray(products) ? products.filter(p => 
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.reference?.toLowerCase().includes(searchTerm.toLowerCase())
  ) : [];

  const addToCart = (product) => {
    const existing = cart.find(item => item.id === product.id);
    if (existing) {
      setCart(cart.map(item => item.id === product.id ? { ...item, quantity: parseInt(item.quantity, 10) + 1 } : item));
    } else {
      setCart([...cart, { ...product, quantity: 1 }]);
    }
  };

  const updateQuantity = (id, delta) => {
    setCart(cart.map(item => {
      if (item.id === id) {
        const newQ = parseInt(item.quantity, 10) + delta;
        if (newQ > 0) {
          return { ...item, quantity: newQ };
        }
        return null;
      }
      return item;
    }).filter(Boolean));
  };

  const updateQuantityDirect = (id, newQ) => {
    if (isNaN(newQ) || newQ < 1) newQ = 1;
    setCart(cart.map(item => item.id === id ? { ...item, quantity: newQ } : item));
  };

  const subtotal = cart.reduce((sum, item) => {
    // In edit mode, items loaded from DB might only have cost_price mapped to selling_price for display
    const price = Number(item.selling_price) || Number(item.cost_price);
    return sum + (price * item.quantity);
  }, 0);
  const total = Math.max(0, subtotal - discount);

  // Sync customer details when selecting dropdowns
  useEffect(() => {
    if (viewingInvoiceId) return; // Don't auto-sync if we are locked in edit mode
    if (customerType === 'Walk-In') {
      setCustomerId('');
      setCustomerName('');
    } else if (customerType === 'Construction') {
      const c = constructions.find(x => x.id == customerId);
      setCustomerName(c ? c.name : '');
    } else if (customerType === 'Building') {
      if (selectedApartmentId) {
        const a = apartments.find(x => x.id == selectedApartmentId);
        const b = buildings.find(x => x.id == selectedBuildingId);
        setCustomerName(a && b ? `Apt CFA ${a.code} (${b.name})` : '');
      } else {
        const b = buildings.find(x => x.id == selectedBuildingId);
        setCustomerName(b ? b.name : '');
      }
    }
  }, [customerType, customerId, selectedBuildingId, selectedApartmentId, constructions, buildings, apartments, viewingInvoiceId]);

  const handleCheckout = async () => {
    if (cart.length === 0) return;
    
    if (!viewingInvoiceId) {
      const hasNegativeStock = cart.some(item => {
        const product = products?.find(p => p.id === item.id);
        return product && (Number(product.quantity) - Number(item.quantity) < 0);
      });
      if (hasNegativeStock) {
        alert(t('pos.negative_stock_error', 'Cannot complete transaction: Some items exceed available stock.'));
        return;
      }
    }

    if (viewingInvoiceId) {
      // Edit existing invoice
      try {
        const { data } = await axios.put(`/pos/invoices/${viewingInvoiceId}`, {
          items: cart.map(i => ({...i, product_id: i.id})), // Ensure product_id is sent
          discount: discount
        });
        
        alert(data.message || 'Invoice updated successfully!');
        cancelEdit();
        queryClient.invalidateQueries(['products']);
        queryClient.invalidateQueries(['posInvoices']);
      } catch (err) {
        alert(err.response?.data?.error || 'Failed to update invoice');
      }
      return;
    }

    // New Checkout
    let finalCustomerType = customerType;
    let finalCustomerId = customerId;

    if (customerType === 'Construction' && !customerId) {
      alert(t('pos.select_project'));
      return;
    }

    if (customerType === 'Building') {
      if (!selectedBuildingId) {
        alert(t('pos.select_building'));
        return;
      }
      if (selectedApartmentId) {
        finalCustomerType = 'Apartment';
        finalCustomerId = selectedApartmentId;
      } else {
        finalCustomerType = 'Building';
        finalCustomerId = selectedBuildingId;
      }
    }

    try {
      const { data } = await axios.post('/pos/checkout', {
        customer_type: finalCustomerType,
        customer_id: finalCustomerId,
        customer_name: customerName,
        items: cart,
        discount: discount
      });
      
      // Setup Invoice for Printing
      setLastInvoice({
        invoice_number: data.invoice_number,
        date: new Date().toLocaleString('en-GB', { timeZone: 'Africa/Douala' }),
        customer_type: finalCustomerType,
        customer_name: customerName || 'Walk-In Customer',
        items: [...cart],
        subtotal: subtotal,
        discount: discount,
        total: total
      });
      
      // Auto trigger print
      setTimeout(() => {
        window.print();
      }, 300);

      setCart([]);
      setCustomerId('');
      setSelectedBuildingId('');
      setSelectedApartmentId('');
      setCustomerName('');
      setDiscount(0);
      
      queryClient.invalidateQueries(['products']);
      queryClient.invalidateQueries(['posInvoices']);
    } catch (err) {
      alert(err.response?.data?.error || 'Checkout failed');
    }
  };

  const getTodayDateString = () => {
    return new Intl.DateTimeFormat('sv-SE', { 
      timeZone: 'Africa/Douala', 
      year: 'numeric', 
      month: '2-digit', 
      day: '2-digit' 
    }).format(new Date());
  };

  const todayInvoices = Array.isArray(posInvoices) ? posInvoices.filter(inv => inv.date && inv.date.startsWith(getTodayDateString())) : [];
  
  // Split history into sections
  const walkInInvoices = todayInvoices.filter(inv => inv.customer_type === 'Walk-In');
  const buildingInvoices = todayInvoices.filter(inv => ['Building', 'Apartment'].includes(inv.customer_type));
  const constructionInvoices = todayInvoices.filter(inv => inv.customer_type === 'Construction');

  const printHistoricalInvoice = (inv) => {
    setLastInvoice({
      invoice_number: inv.invoice_number,
      date: inv.date,
      customer_type: inv.customer_type,
      customer_name: inv.customer_name || 'Walk-In Customer',
      items: inv.items.map(i => ({...i, selling_price: i.cost_price})), // Align mapping
      subtotal: inv.subtotal,
      discount: inv.discount,
      total: inv.final_amount
    });
    setTimeout(() => window.print(), 300);
  };

  const loadInvoiceForEditing = (inv) => {
    setViewingInvoiceId(inv.id);
    setViewingInvoiceNumber(inv.invoice_number);
    
    // Determine Building vs Construction based on type
    let rootType = inv.customer_type;
    if (rootType === 'Apartment') rootType = 'Building';
    
    setCustomerType(rootType);
    setCustomerName(inv.customer_name);
    setDiscount(Number(inv.discount));
    
    // Load Items into Cart
    const mappedItems = inv.items.map(item => ({
      ...item,
      id: item.product_id, // Important: Cart uses `id` to reference products
      quantity: parseInt(item.quantity, 10),
      selling_price: item.cost_price // Backend saved cost_price, frontend subtotal uses selling_price
    }));
    setCart(mappedItems);
    
    setShowHistory(false); // Close Modal
  };

  const cancelEdit = () => {
    setViewingInvoiceId(null);
    setViewingInvoiceNumber('');
    setCart([]);
    setDiscount(0);
    setCustomerType('Walk-In');
    setCustomerName('');
    setCustomerId('');
    setSelectedBuildingId('');
    setSelectedApartmentId('');
  };

  // Helper component for rendering invoice lists in modal
  const InvoiceList = ({ title, list }) => {
    if (list.length === 0) return null;
    return (
      <div className="mb-8">
        <h3 className="text-lg font-bold text-white mb-4 flex items-center border-b border-slate-700/50 pb-2">
          {title} <span className="ml-2 bg-slate-800 text-slate-400 text-xs px-2 py-0.5 rounded-full">{list.length}</span>
        </h3>
        <div className="space-y-4">
          {list.map(inv => (
            <div key={inv.id} className="bg-slate-800/40 border border-slate-700 rounded-xl p-5 hover:border-slate-600 transition-colors">
              <div className="flex justify-between items-start mb-4 border-b border-slate-700/50 pb-4">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <h3 className="font-bold text-white text-lg">{inv.invoice_number}</h3>
                    <span className="bg-primary/20 text-indigo-300 text-xs px-2 py-1 rounded-md font-medium border border-primary/20">
                      {inv.customer_type}
                    </span>
                  </div>
                  <p className="text-slate-400 text-sm">
                    {inv.customer_type === 'Walk-In' 
                      ? (inv.customer_name || 'Walk-In Customer') 
                      : `Entity: CFA ${inv.customer_name || `ID CFA ${inv.customer_id}`}`}
                  </p>
                </div>
                <div className="text-right flex flex-col items-end gap-2">
                  <div>
                    <p className="text-xl font-bold text-success">CFA {Number(inv.final_amount).toLocaleString()}</p>
                    {Number(inv.discount) > 0 && (
                      <p className="text-xs text-warning mt-1">Discount: CFA {Number(inv.discount).toLocaleString()}</p>
                    )}
                    <p className="text-xs text-muted mt-1">{new Date(inv.created_at).toLocaleTimeString()}</p>
                  </div>
                  <div className="flex gap-2">
                    <button onClick={() => printHistoricalInvoice(inv)} className="flex items-center gap-1 text-xs bg-slate-700 hover:bg-slate-600 text-white px-2 py-1 rounded transition-colors">
                      <Printer size={12} /> Print
                    </button>
                    <button onClick={() => loadInvoiceForEditing(inv)} className="flex items-center gap-1 text-xs bg-primary/20 hover:bg-primary text-white px-2 py-1 rounded transition-colors">
                      <Edit2 size={12} /> View/Edit
                    </button>
                  </div>
                </div>
              </div>
              
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {inv.items?.map(item => (
                  <div key={item.id} className="bg-slate-800/60 p-3 rounded-lg border border-slate-700 flex justify-between items-center">
                    <div className="flex-1 min-w-0 pr-3">
                      <p className="text-white text-sm font-medium truncate">{item.name}</p>
                      <p className="text-slate-400 text-xs">CFA {Number(item.cost_price).toLocaleString()} × {item.quantity}</p>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <p className="text-indigo-300 text-sm font-bold">CFA {Number(item.total_price).toLocaleString()}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  return (
    <>
      {/* Invisible Print Template */}
      {lastInvoice && (
        <div className="hidden print:block p-2 font-mono text-black w-[80mm] mx-auto text-sm" dir={document.documentElement.dir}>
          <div className="text-center mb-4 border-b-2 border-black pb-3">
            <PrintLogo />
            <h1 className="text-xl font-bold mt-2 mb-1">{t('invoice.title')}</h1>
          </div>
          <div className="mb-4 flex flex-col gap-1 text-xs">
            <div className="flex justify-between">
              <p><strong>{t('invoice.invoice_no')}</strong> {lastInvoice.invoice_number}</p>
              <p>{lastInvoice.date}</p>
            </div>
            <div className="flex justify-between">
              <p><strong>{t('invoice.target')}</strong> {lastInvoice.customer_type}</p>
              <p>{lastInvoice.customer_name}</p>
            </div>
          </div>
          <table className="w-full text-start border-collapse mb-4 text-xs">
            <thead>
              <tr className="border-b border-black">
                <th className="py-2 text-start">{t('invoice.item_desc')}</th>
                <th className="py-2 text-center">{t('invoice.qty')}</th>
                <th className="py-2 text-end">{t('invoice.unit_price')}</th>
                <th className="py-2 text-end">{t('invoice.total')}</th>
              </tr>
            </thead>
            <tbody>
              {lastInvoice.items.map((item, idx) => (
                <tr key={idx} className="border-b border-gray-300">
                  <td className="py-2 text-start">{item.name}</td>
                  <td className="py-2 text-center">{item.quantity}</td>
                  <td className="py-2 text-end">{t('common.currency')} {(Number(item.selling_price) || Number(item.cost_price)).toLocaleString()}</td>
                  <td className="py-2 text-end">{t('common.currency')} {((Number(item.selling_price) || Number(item.cost_price)) * item.quantity).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <div className="text-end pt-2 space-y-1 text-xs">
            <p className="text-gray-600">{t('invoice.subtotal')} {t('common.currency')} {parseFloat(lastInvoice.subtotal).toLocaleString()}</p>
            <p className="text-gray-600">{t('invoice.discount')} {t('common.currency')} {parseFloat(lastInvoice.discount).toLocaleString()}</p>
          </div>
          <div className="text-end border-t border-black pt-2 mt-2">
            <h2 className="text-base font-bold">{t('invoice.grand_total')} {t('common.currency')} {parseFloat(lastInvoice.total).toLocaleString()}</h2>
          </div>
          <div className="mt-6 text-center text-[10px] text-gray-500">
            <p>{t('invoice.thank_you')}</p>
          </div>
        </div>
      )}

      <div className="flex h-full w-full overflow-hidden print:hidden bg-background">
        {/* Center Content - Products Grid */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar flex flex-col">
        <div className="flex justify-between items-center mb-8 shrink-0">
          <div>
            <h1 className="text-3xl font-bold text-white">{t('pos.title')}</h1>
            <p className="text-muted mt-1">{t('pos.subtitle')}</p>
          </div>
          <div className="flex items-center">
            <div className="relative w-72">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
              <input 
                type="text" 
                placeholder={t('pos.search')}
                className="w-full pl-10 pr-4 py-3 bg-slate-800 border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary transition-colors shadow-lg"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <button 
              onClick={() => { setShowHistory(true); refetchInvoices(); }}
              className="ml-4 bg-slate-800 border border-slate-700 hover:bg-slate-700 text-white px-4 py-3 rounded-lg flex items-center gap-2 transition-colors shadow-lg group"
            >
              <History size={20} className="group-hover:text-primary transition-colors" />
              <span>{t('pos.today_sales')}</span>
            </button>
          </div>
        </div>

        {viewingInvoiceId && (
          <div className="bg-warning/10 border border-warning/50 p-4 rounded-xl mb-6 flex justify-between items-center shrink-0">
            <div>
              <h3 className="font-bold text-warning flex items-center gap-2">
                <Edit2 size={18}/> {t('pos.edit_invoice')} {viewingInvoiceNumber}
              </h3>
              <p className="text-sm text-warning/80 mt-1">
                {t('pos.edit_warning')}
              </p>
            </div>
            <div className="flex gap-3">
              <button onClick={() => {
                const inv = posInvoices.find(i => i.id === viewingInvoiceId);
                if (inv) printHistoricalInvoice(inv);
              }} className="bg-slate-800 text-white px-4 py-2 rounded-lg hover:bg-slate-700 transition-colors flex items-center gap-2">
                <Printer size={16}/> {t('pos.btn_print_orig')}
              </button>
              <button onClick={cancelEdit} className="bg-slate-800 text-white px-4 py-2 rounded-lg hover:bg-slate-700 transition-colors">
                {t('pos.btn_cancel_edit')}
              </button>
            </div>
          </div>
        )}

        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 flex-1 content-start">
          {isLoading ? (
             Array(8).fill(0).map((_, i) => (
              <div key={i} className="glass-card h-40 animate-pulse bg-slate-800/50"></div>
            ))
          ) : (
            filteredProducts?.map(product => (
              <div 
                key={product.id} 
                className="glass-card p-4 flex flex-col hover-card cursor-pointer"
                onClick={() => addToCart(product)}
              >
                <div className="flex justify-between items-start mb-2">
                  <h3 className="font-semibold text-white line-clamp-2 leading-tight">{product.name}</h3>
                </div>
                <div className="text-xs text-muted mb-2">REF: {product.reference}</div>
                <div className="mt-auto flex justify-between items-end">
                  <div className="text-indigo-400 font-bold text-lg">CFA {Number(product.selling_price).toLocaleString()}</div>
                  <div className={`text-sm ${product.quantity > 0 ? 'text-success' : 'text-danger'}`}>
                    Stock: {product.quantity}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Right Summary Panel - Cart & Checkout */}
      <div className="w-[400px] glass-card rounded-none border-t-0 border-r-0 border-b-0 flex flex-col h-full z-10 shrink-0">
        <div className={`p-6 border-b border-slate-700/50 ${viewingInvoiceId ? 'bg-warning/10 border-warning/20' : 'bg-slate-800/30'}`}>
          <h2 className="text-xl font-bold text-white flex items-center">
            {viewingInvoiceId ? <Edit2 className="mr-2 text-warning" size={24} /> : <ShoppingCart className="mr-2 text-primary" size={24} />}
            {viewingInvoiceId ? t('pos.edit_invoice') : t('pos.order_summary')}
          </h2>
        </div>

        <div className="p-6 border-b border-slate-700/50 space-y-4 bg-slate-900/20">
          <div>
            <label className="block text-xs font-semibold text-muted uppercase tracking-wider mb-2">{t('pos.customer_type')}</label>
            <div className="flex gap-2">
              <button 
                onClick={() => setCustomerType('Walk-In')}
                disabled={!!viewingInvoiceId}
                className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors border ${customerType === 'Walk-In' ? 'bg-primary/20 text-primary border-primary/50' : 'bg-slate-800/50 text-slate-400 border-transparent hover:bg-slate-800'} disabled:opacity-50`}
              >
                {t('pos.walk_in')}
              </button>
              <button 
                onClick={() => setCustomerType('Construction')}
                disabled={!!viewingInvoiceId}
                className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors border ${customerType === 'Construction' ? 'bg-indigo-500/20 text-indigo-400 border-indigo-500/50' : 'bg-slate-800/50 text-slate-400 border-transparent hover:bg-slate-800'} disabled:opacity-50`}
              >
                {t('pos.construction')}
              </button>
              <button 
                onClick={() => setCustomerType('Building')}
                disabled={!!viewingInvoiceId}
                className={`flex-1 py-2 rounded-lg text-sm font-medium transition-colors border ${customerType === 'Building' ? 'bg-amber-500/20 text-amber-400 border-amber-500/50' : 'bg-slate-800/50 text-slate-400 border-transparent hover:bg-slate-800'} disabled:opacity-50`}
              >
                {t('pos.building_apt')}
              </button>
            </div>
          </div>

          {customerType === 'Construction' && (
            <select 
              value={customerId} 
              onChange={(e) => setCustomerId(e.target.value)}
              disabled={!!viewingInvoiceId}
              className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-indigo-500 appearance-none disabled:opacity-50"
            >
              <option value="">{t('pos.select_proj_dropdown')}</option>
              {constructions?.map(c => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          )}

          {customerType === 'Building' && (
            <>
              <select 
                value={selectedBuildingId} 
                onChange={(e) => {setSelectedBuildingId(e.target.value); setSelectedApartmentId('');}}
                disabled={!!viewingInvoiceId}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-amber-500 appearance-none disabled:opacity-50"
              >
                <option value="">{t('pos.select_building_dropdown')}</option>
                {buildings?.map(b => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
              <select 
                value={selectedApartmentId} 
                onChange={(e) => setSelectedApartmentId(e.target.value)}
                disabled={!selectedBuildingId || !!viewingInvoiceId}
                className="w-full bg-slate-900/50 border border-slate-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-amber-500 appearance-none disabled:opacity-50 mt-2"
              >
                <option value="">{t('pos.select_apt_dropdown')}</option>
                {apartments?.filter(a => a.building_id == selectedBuildingId).map(a => (
                  <option key={a.id} value={a.id}>Apt {a.code}</option>
                ))}
              </select>
              {selectedApartmentId && (
                <div className="mt-3 p-3 bg-amber-500/10 border border-amber-500/20 rounded-lg flex justify-between items-center">
                  <span className="text-xs text-amber-300 font-medium uppercase tracking-wider">Accumulated Cost</span>
                  <span className="text-sm font-bold text-white">
                    {t('common.currency')} {Number(apartmentTotalCosts?.total_costs || 0).toLocaleString()}
                  </span>
                </div>
              )}
            </>
          )}

          {customerType === 'Walk-In' && (
            <input 
              type="text" 
              className="w-full bg-slate-800 border border-slate-700 text-white rounded-lg p-3 focus:outline-none focus:border-primary disabled:opacity-50"
              placeholder={t('pos.walk_in_name')}
              value={customerName}
              onChange={(e) => setCustomerName(e.target.value)}
              disabled={!!viewingInvoiceId}
            />
          )}
        </div>

        {/* Cart Items */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4 hide-scrollbar">
          {cart.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-muted">
              <Package size={48} className="mb-4 opacity-20" />
              <p>Cart is empty</p>
            </div>
          ) : (
            cart.map(item => {
              const price = Number(item.selling_price) || Number(item.cost_price);
              const product = products?.find(p => p.id === item.id);
              const remainingStock = product ? (Number(product.quantity) - Number(item.quantity)) : 0;
              
              return (
                <div key={item.id} className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 flex justify-between group">
                  <div className="flex-1 min-w-0">
                    <h4 className="font-bold text-white text-sm truncate pr-2">{item.name}</h4>
                    <p className="text-xs text-muted mb-1">{t('common.currency')} {price.toLocaleString()} / {item.unit}</p>
                    <p className={`text-[10px] mb-3 font-semibold ${remainingStock > 0 ? 'text-emerald-400' : remainingStock === 0 ? 'text-warning' : 'text-danger'}`}>
                      {remainingStock > 0 ? `Stock: ${remainingStock}` : remainingStock === 0 ? 'Last item!' : `Stock: ${remainingStock}`}
                    </p>
                    
                    <div className="flex items-center gap-3">
                      <button onClick={() => updateQuantity(item.id, -1)} className="p-1.5 bg-slate-700 hover:bg-slate-600 rounded-lg text-white transition-colors">
                        <Minus size={14} />
                      </button>
                      <div className="flex flex-col items-center">
                        <input 
                          type="number"
                          value={item.quantity}
                          onChange={(e) => updateQuantityDirect(item.id, parseInt(e.target.value))}
                          className="w-12 bg-transparent text-center text-white font-medium focus:outline-none"
                        />
                        <span className="text-[10px] text-muted">{t('pos.qty')}</span>
                      </div>
                      <button onClick={() => updateQuantity(item.id, 1)} className="p-1.5 bg-slate-700 hover:bg-slate-600 rounded-lg text-white transition-colors"><Plus size={14}/></button>
                    </div>
                  </div>
                  <div className="flex flex-col items-end justify-between ml-4">
                    <button onClick={() => updateQuantity(item.id, -item.quantity)} className="text-danger/70 hover:text-danger text-xs flex items-center transition-colors">
                      <Trash2 size={12} className="mr-1" /> {t('pos.remove')}
                    </button>
                    <div className="font-bold text-indigo-400">
                      {t('common.currency')} {(price * item.quantity).toLocaleString()}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Totals & Checkout */}
        <div className="p-6 bg-slate-800/30 border-t border-slate-700/50">
          <div className="space-y-3 mb-6">
            <div className="flex justify-between text-muted text-sm items-center">
              <span>{t('pos.items_total')}</span>
              <span>CFA {subtotal.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
            </div>
            
            <div className="flex justify-between items-center text-muted text-sm mt-3 border-b border-slate-700/50 pb-3">
              <span className="font-medium">{t('pos.discount')} (CFA)</span>
              <input 
                type="number" 
                value={discount} 
                onChange={(e) => setDiscount(Number(e.target.value) || 0)}
                className="w-24 bg-slate-800 border border-slate-600 rounded-lg p-1.5 text-right text-white focus:outline-none focus:border-primary font-medium"
                min="0"
                placeholder="0"
              />
            </div>

            <div className="flex justify-between text-white text-2xl font-bold pt-2">
              <span>{t('pos.total')}</span>
              <span className="text-success">CFA {total.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2})}</span>
            </div>
          </div>
          <button 
            onClick={handleCheckout}
            disabled={cart.length === 0}
            className={`w-full py-4 rounded-xl flex items-center justify-center font-bold text-lg transition-all ${
              cart.length > 0 
                ? (viewingInvoiceId ? 'bg-warning hover:bg-yellow-600 text-black shadow-lg shadow-warning/30' : 'bg-primary hover:bg-indigo-600 text-white shadow-lg shadow-primary/30')
                : 'bg-slate-700/50 text-slate-500 cursor-not-allowed'
            }`}
          >
            {viewingInvoiceId ? (
              <><Edit2 className="mr-2" size={20} /> {t('pos.btn_save_changes')}</>
            ) : (
              <><CreditCard className="mr-2" /> {t('pos.btn_complete_txn')}</>
            )}
          </button>
        </div>
      </div>
    </div>

    {/* Today's Transactions Modal */}
    {showHistory && (
      <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
        <div className="glass-card w-full max-w-5xl h-[85vh] flex flex-col border border-slate-700 animate-in zoom-in-95 duration-200">
          <div className="p-6 border-b border-slate-700/50 flex justify-between items-center bg-slate-800/30">
            <h2 className="text-2xl font-bold text-white flex items-center">
              <History className="mr-3 text-primary" size={28} /> 
              {t('pos.modal_today_txns')}
            </h2>
            <button 
              onClick={() => setShowHistory(false)}
              className="p-2 text-slate-400 hover:text-white bg-slate-800/50 rounded-lg hover:bg-slate-700 transition-colors"
            >
              <X size={24} />
            </button>
          </div>
          
          <div className="flex-1 overflow-y-auto p-6 hide-scrollbar">
            {todayInvoices.length === 0 ? (
              <div className="h-full flex flex-col items-center justify-center text-muted">
                <History size={48} className="mb-4 opacity-20" />
                <p className="text-lg">{t('pos.no_txns_today')}</p>
              </div>
            ) : (
              <div className="flex flex-col gap-4">
                <InvoiceList title={t('pos.list_walk_in')} list={walkInInvoices} />
                <InvoiceList title={t('pos.list_building')} list={buildingInvoices} />
                <InvoiceList title={t('pos.list_construction')} list={constructionInvoices} />
              </div>
            )}
          </div>
        </div>
      </div>
    )}
    </>
  );
};

export default POS;
