import React, { useReducer, useEffect, useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import InteractiveCurrency from '../common/InteractiveCurrency';
import { X, Building2, User, Calendar, CreditCard, QrCode, ArrowLeft, Loader2, DollarSign, Search, PlusCircle, CheckCircle2, Info } from 'lucide-react';
import QRScanner from './QRScanner';
import api from '../../api/axios';

// FSM State Definitions
const STATES = {
  IDENTIFY: 'IDENTIFY',
  SEARCH_BUILDING: 'SEARCH_BUILDING',
  SEARCH_TENANT: 'SEARCH_TENANT',
  REVIEW_TENANT: 'REVIEW_TENANT',
  SELECT_MONTH: 'SELECT_MONTH',
  AUTHORIZE_PAYMENT: 'AUTHORIZE_PAYMENT',
  REVIEW_PAYMENT: 'REVIEW_PAYMENT',
  SELECT_METHOD: 'SELECT_METHOD',
  QR_SCANNING: 'QR_SCANNING',
  MANUAL_ENTRY: 'MANUAL_ENTRY',
  SUBMITTING: 'SUBMITTING'
};

const initialState = {
  currentState: STATES.IDENTIFY,
  collectionType: null,
  building: null,
  tenant: null,
  billingMonths: [],
  identifiedTask: null,
  paymentMethod: null,
  amount: 0,
  error: null
};

function fsmReducer(state, action) {
  switch (action.type) {
    case 'SELECT_TYPE':
      return { ...state, collectionType: action.payload, currentState: STATES.SEARCH_BUILDING };
    case 'SELECT_BUILDING':
      return { ...state, building: action.payload, currentState: STATES.SEARCH_TENANT };
    case 'SELECT_TENANT':
      return { ...state, tenant: action.payload, currentState: STATES.REVIEW_TENANT };
    case 'CONFIRM_TENANT_DETAILS':
      return { ...state, currentState: STATES.SELECT_MONTH };
    case 'PROCEED_TO_AUTHORIZE':
      return { ...state, currentState: STATES.AUTHORIZE_PAYMENT };
    case 'AUTHORIZE_SUCCESS':
      return { ...state, currentState: STATES.SELECT_METHOD };
    case 'SELECT_MONTHS':
      return { ...state, billingMonths: action.payload };
    case 'IDENTIFY_SUCCESS':
      return { 
        ...state, 
        identifiedTask: action.payload.task, 
        collectionType: action.payload.type,
        amount: action.payload.task.remaining || action.payload.task.amount || 0,
        currentState: STATES.REVIEW_PAYMENT 
      };
    case 'CONFIRM_PAYMENT_DETAILS':
      return { ...state, currentState: STATES.SELECT_METHOD };
    case 'SELECT_METHOD':
      return { 
        ...state, 
        paymentMethod: action.payload, 
        currentState: STATES.MANUAL_ENTRY 
      };
    case 'OPEN_QR_SCANNER':
      return { ...state, currentState: STATES.QR_SCANNING, error: null };
    case 'QR_SCAN_ERROR':
      return { ...state, error: action.payload };
    case 'FALLBACK_TO_MANUAL':
      return { ...state, currentState: STATES.IDENTIFY, error: null };
    case 'SET_AMOUNT':
      return { ...state, amount: action.payload };
    case 'SUBMIT':
      return { ...state, currentState: STATES.SUBMITTING };
    case 'GO_BACK':
      switch (state.currentState) {
        case STATES.SEARCH_BUILDING: return { ...state, currentState: STATES.IDENTIFY };
        case STATES.SEARCH_TENANT: return { ...state, currentState: STATES.SEARCH_BUILDING };
        case STATES.REVIEW_TENANT: return { ...state, currentState: STATES.SEARCH_TENANT };
        case STATES.SELECT_MONTH: return { ...state, currentState: STATES.REVIEW_TENANT };
        case STATES.AUTHORIZE_PAYMENT: return { ...state, currentState: STATES.SELECT_MONTH, error: null };
        case STATES.REVIEW_PAYMENT: return { ...state, currentState: STATES.IDENTIFY };
        case STATES.SELECT_METHOD: 
            return state.identifiedTask ? { ...state, currentState: STATES.REVIEW_PAYMENT } : { ...state, currentState: STATES.AUTHORIZE_PAYMENT };
        case STATES.QR_SCANNING: return { ...state, currentState: STATES.IDENTIFY, error: null };
        case STATES.MANUAL_ENTRY: return { ...state, currentState: STATES.SELECT_METHOD };
        default: return state;
      }
    case 'AUTO_FILL':
      return {
        ...initialState,
        collectionType: action.payload.collectionType === 'RENT' ? 'Rent Apartment' : 'Electricity Subscription',
        building: action.payload.buildingName,
        currentState: STATES.SEARCH_TENANT
      };
    case 'RESET':
      return initialState;
    default:
      return state;
  }
}

const AddCollectionModal = ({ isOpen, onClose, onSave, autoFillData }) => {
  const [state, dispatch] = useReducer(fsmReducer, initialState);
  const [tempInput, setTempInput] = useState('');
  const queryClient = useQueryClient();

  useEffect(() => {
    if (isOpen) {
      if (autoFillData) {
        dispatch({ type: 'AUTO_FILL', payload: autoFillData });
      } else {
        dispatch({ type: 'RESET' });
      }
    }
  }, [isOpen, autoFillData]);

  const [manualCode, setManualCode] = useState('');

  // 1. Fetch Rent Tasks
  const { data: rentTasks = {} } = useQuery({
    queryKey: ['agent_rent_tasks'],
    queryFn: async () => (await axios.get('/agent/rent/tasks')).data?.data || {}
  });

  // 2. Fetch Subscription Invoices
  const { data: subTasks = {} } = useQuery({
    queryKey: ['agent_subscription_invoices'],
    queryFn: async () => (await axios.get('/energy/agent/subscription-invoices')).data?.tasks || []
  });

  // 3. Fetch Buildings Dynamically
  const { data: buildingsData = [] } = useQuery({
    queryKey: ['buildings_list'],
    queryFn: async () => (await axios.get('/buildings')).data,
    enabled: isOpen
  });

  // 4. Fetch Tenants Dynamically
  const { data: allTenants = [] } = useQuery({
    queryKey: ['tenants_list'],
    queryFn: async () => (await axios.get('/tenants')).data,
    enabled: isOpen
  });

  // 5. Derive Due Invoices reactively
  const dueInvoices = React.useMemo(() => {
    if (!state.tenant || state.currentState < STATES.REVIEW_TENANT) return [];
    
    try {
      if (state.collectionType === 'Rent Apartment') {
         const bTasks = rentTasks[state.building] || [];
         return bTasks.filter(t => String(t.apartment_number) === String(state.tenant.apartment_code));
      } else if (state.collectionType === 'Electricity Subscription') {
         const bTasks = subTasks || [];
         return bTasks.filter(t => t.building_name === state.building && String(t.apartment_code) === String(state.tenant.apartment_code));
      }
    } catch (e) {
      console.error("Failed deriving tasks:", e);
    }
    return []; 
  }, [state.tenant, state.building, state.collectionType, state.currentState, rentTasks, subTasks]);

  const isDueFetching = false;

  const handleIdentifyCode = (codeToSearch) => {
    const cleanSearch = String(codeToSearch).trim().toUpperCase();

    // Search in Rent Tasks (which is grouped by building)
    let foundTask = null;
    let foundType = null;
    
    for (const building in rentTasks) {
      const task = rentTasks[building].find(t => 
        (t.invoice_number && String(t.invoice_number).trim().toUpperCase() === cleanSearch) || 
        String(t.invoice_id) === cleanSearch ||
        `INV-${t.invoice_id}` === cleanSearch
      );
      if (task) {
        foundTask = task;
        foundType = 'Rent Apartment';
        break;
      }
    }

    if (!foundTask) {
      // Search in Subscriptions (which is a flat array of tasks)
      const sub = Array.isArray(subTasks) ? subTasks.find(t => 
        (t.invoice_number && String(t.invoice_number).trim().toUpperCase() === cleanSearch) ||
        String(t.invoice_id) === cleanSearch ||
        `SUB-${t.invoice_id}` === cleanSearch ||
        `ELEC-${t.invoice_id}` === cleanSearch ||
        `INV-${t.invoice_id}` === cleanSearch
      ) : null;
      if (sub) {
        foundTask = sub;
        foundType = 'Electricity Subscription';
      }
    }

    if (foundTask) {
      dispatch({ type: 'IDENTIFY_SUCCESS', payload: { task: foundTask, type: foundType } });
    } else {
      alert("Invoice/Task not found. Please verify the code.");
    }
  };

  // The FSM reset logic is already handled in the first useEffect when the modal opens/closes, so we don't need this redundant reset.

  const submitMutation = useMutation({
    mutationFn: async () => {
       const task = state.identifiedTask || state.billingMonths[0];

       if (state.collectionType === 'Rent Apartment') {
         return await axios.post('/agent/rent/collect', {
            invoice_id: task?.invoice_id,
            task_id: task?.task_id || null,
            request_id: task?.request_id || null,
            amount: Number(state.amount),
            method: state.paymentMethod,
            notes: 'Agent Wizard'
         });
       } else if (state.collectionType === 'Electricity Subscription') {
         return await axios.post('/energy/agent/subscription-invoices/pay', {
            invoice_id: task?.invoice_id,
            amount_collected: Number(state.amount),
            status: 'collected'
         });
       }
    },
    onSuccess: () => {
      queryClient.invalidateQueries(['agent_collections_daily']);
      queryClient.invalidateQueries(['due_invoices']);
      onSave({}); // triggers refetch in dashboard
      onClose();
    },
    onError: (err) => {
      alert("Failed to submit collection: " + (err.response?.data?.message || err.message));
      dispatch({ type: 'GO_BACK' });
    }
  });

  if (!isOpen) return null;

  const handleQRScanSuccess = (decodedString) => {
    try {
      const payload = JSON.parse(decodedString);
      if (payload.invoiceNumber || payload.invoiceId) {
        handleIdentifyCode(payload.invoiceNumber || payload.invoiceId);
      } else {
        dispatch({ type: 'QR_SCAN_ERROR', payload: "Invalid QR Code: Missing invoice data." });
      }
    } catch (e) {
      dispatch({ type: 'QR_SCAN_ERROR', payload: "Malformed QR Code payload." });
    }
  };

  const handleAuthorizeScan = (decodedString) => {
    try {
      const payload = JSON.parse(decodedString);
      const code = payload.invoiceNumber || payload.invoiceId;
      if (code) {
        handleAuthorizeManual(code);
      } else {
        dispatch({ type: 'QR_SCAN_ERROR', payload: "Invalid QR Code: Missing invoice data." });
      }
    } catch (e) {
      dispatch({ type: 'QR_SCAN_ERROR', payload: "Malformed QR Code payload." });
    }
  };

  const handleAuthorizeManual = (codeToSearch) => {
    const cleanSearch = String(codeToSearch).trim().toUpperCase();
    
    // Check if the code matches ANY of the selected billing months
    const isValid = state.billingMonths.some(t => 
      (t.invoice_number && String(t.invoice_number).trim().toUpperCase() === cleanSearch) || 
      String(t.invoice_id) === cleanSearch ||
      `INV-${t.invoice_id}` === cleanSearch ||
      `SUB-${t.invoice_id}` === cleanSearch ||
      `ELEC-${t.invoice_id}` === cleanSearch
    );

    if (isValid) {
      dispatch({ type: 'AUTHORIZE_SUCCESS' });
    } else {
      dispatch({ type: 'QR_SCAN_ERROR', payload: "Code does not match the selected invoice(s)." });
    }
  };

  const handleSubmit = () => {
    dispatch({ type: 'SUBMIT' });
    submitMutation.mutate();
  };

  const renderStateContent = () => {
    switch (state.currentState) {
      case STATES.IDENTIFY:
        return (
          <div className="space-y-6">
            <div className="text-center">
              <h3 className="text-white font-bold text-xl mb-2">Identify Payment</h3>
              <p className="text-slate-400 text-sm">Scan the tenant's QR code or enter the manual invoice code below.</p>
            </div>
            
            <button 
              onClick={() => dispatch({ type: 'OPEN_QR_SCANNER' })}
              className="w-full p-6 bg-[#0F172A] border border-slate-700 rounded-xl hover:border-primary flex flex-col items-center justify-center transition-colors group"
            >
              <QrCode className="mb-3 text-primary group-hover:scale-110 transition-transform" size={48} />
              <span className="text-white font-bold text-lg">Scan QR Code</span>
            </button>

            <div className="flex items-center gap-4 py-2">
              <div className="h-px bg-slate-700 flex-1"></div>
              <span className="text-slate-500 font-bold text-sm uppercase">OR</span>
              <div className="h-px bg-slate-700 flex-1"></div>
            </div>

            <div className="space-y-3">
              <label className="text-sm font-bold text-slate-400 block">Manual Invoice Code</label>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  placeholder="e.g., INV-202610-18"
                  className="flex-1 bg-[#0F172A] border border-slate-700 rounded-xl px-4 py-3 text-white font-bold outline-none focus:border-primary uppercase"
                  value={manualCode}
                  onChange={(e) => setManualCode(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleIdentifyCode(manualCode)}
                />
                <button 
                  onClick={() => handleIdentifyCode(manualCode)}
                  disabled={!manualCode.trim()}
                  className="bg-primary hover:bg-primary/90 text-white font-bold px-6 py-3 rounded-xl disabled:opacity-50 transition-colors"
                >
                  Find
                </button>
              </div>
            </div>
            <div className="flex items-center gap-4 py-4">
              <div className="h-px bg-slate-700 flex-1"></div>
              <span className="text-slate-500 font-bold text-sm uppercase">OR MANUAL SEARCH</span>
              <div className="h-px bg-slate-700 flex-1"></div>
            </div>

            <div className="space-y-3">
              <h3 className="text-slate-400 font-bold text-sm block mb-2">Select Collection Type</h3>
              {['Rent Apartment', 'Electricity Subscription', 'Insurance'].map(type => (
                <div 
                  key={type}
                  onClick={() => dispatch({ type: 'SELECT_TYPE', payload: type })}
                  className="p-4 bg-[#0F172A] border border-slate-700 rounded-xl cursor-pointer hover:border-primary hover:bg-primary/10 transition-colors"
                >
                  <p className="text-white font-bold">{type}</p>
                </div>
              ))}
            </div>
          </div>
        );

      case STATES.SEARCH_BUILDING:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Search Property Building</h3>
            <div className="relative">
              <Building2 className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <select 
                className="w-full bg-[#0F172A] border border-slate-700 rounded-xl pl-10 pr-4 py-3 text-white outline-none focus:border-primary"
                onChange={(e) => dispatch({ type: 'SELECT_BUILDING', payload: e.target.value })}
                defaultValue=""
              >
                <option value="" disabled>Select a building...</option>
                {buildingsData.map(b => <option key={b.id} value={b.name}>{b.name}</option>)}
              </select>
            </div>
          </div>
        );

      case STATES.SEARCH_TENANT:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Search Tenant / Apartment</h3>
            <p className="text-xs text-slate-400 mb-2">Scoped to: {state.building}</p>
            <div className="relative mb-4">
              <User className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input 
                type="text" 
                placeholder="Search by name or apt #..."
                className="w-full bg-[#0F172A] border border-slate-700 rounded-xl pl-10 pr-4 py-3 text-white outline-none focus:border-primary"
                value={tempInput}
                onChange={(e) => setTempInput(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              {allTenants.filter(t => t.building_name === state.building && (
                  t.full_name?.toLowerCase().includes(tempInput.toLowerCase()) || 
                  String(t.apartment_code).includes(tempInput)
                )).map(t => (
                <div 
                  key={t.id}
                  onClick={() => dispatch({ type: 'SELECT_TENANT', payload: t })}
                  className="p-3 bg-slate-800 rounded-xl cursor-pointer hover:bg-slate-700"
                >
                  <p className="text-white font-bold">{t.full_name}</p>
                  <p className="text-xs text-slate-400">Apt {t.apartment_code}</p>
                </div>
              ))}
            </div>
          </div>
        );

      case STATES.REVIEW_TENANT:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Review Tenant Details</h3>
            <div className="p-4 bg-[#0F172A] border border-slate-700 rounded-xl space-y-2">
              <div className="flex items-center text-info mb-2"><Info size={16} className="mr-2"/> Read-Only Data</div>
              <p className="text-slate-400 text-sm">Name: <span className="text-white font-bold">{state.tenant?.full_name}</span></p>
              <p className="text-slate-400 text-sm">Apartment: <span className="text-white font-bold">{state.tenant?.apartment_code}</span></p>
              <p className="text-slate-400 text-sm">Building: <span className="text-white font-bold">{state.building}</span></p>
              <p className="text-slate-400 text-sm">Lease Status: <span className="text-success font-bold">{state.tenant?.contract_status || 'Active'}</span></p>
            </div>
            <button 
              onClick={() => dispatch({ type: 'CONFIRM_TENANT_DETAILS' })}
              className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-bold rounded-xl"
            >
              Confirm Details
            </button>
          </div>
        );

      case STATES.SELECT_MONTH:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Select Billing Month(s)</h3>
            <div className="space-y-2">
              {isDueFetching && <Loader2 className="animate-spin text-primary mx-auto my-4" />}
              {!isDueFetching && dueInvoices.length === 0 && (
                <p className="text-slate-400 text-sm text-center py-4">No due invoices found for this tenant.</p>
              )}
              {!isDueFetching && dueInvoices.map(task => {
                const isSelected = state.billingMonths.some(m => m.invoice_id === task.invoice_id);
                const amountCFA = Number(task.remaining ?? task.amount ?? 0);
                const taskLabel = task.month ? `${task.month} ${task.year}` : `Invoice #${task.invoice_number || task.invoice_id}`;
                const dueText = (task.due_date && !isNaN(Date.parse(task.due_date))) 
                  ? new Date(task.due_date).toLocaleDateString() 
                  : (task.created_at ? new Date(task.created_at).toLocaleDateString() : 'N/A');
                
                const isExpired = task.due_date && new Date(task.due_date) < new Date(new Date().setHours(0,0,0,0));

                return (
                  <div 
                    key={task.invoice_id}
                    onClick={() => {
                      const newSelection = isSelected 
                        ? state.billingMonths.filter(m => m.invoice_id !== task.invoice_id)
                        : [...state.billingMonths, task];
                      dispatch({ type: 'SELECT_MONTHS', payload: newSelection });
                      if (!isSelected) {
                        dispatch({ type: 'SET_AMOUNT', payload: task.remaining ?? task.amount ?? 0 });
                      }
                    }}
                    className={`p-3 border rounded-xl cursor-pointer flex justify-between items-center ${isSelected ? 'bg-primary/20 border-primary' : 'bg-[#0F172A] border-slate-700'}`}
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <p className={isSelected ? 'text-white font-bold' : 'text-slate-300'}>{taskLabel}</p>
                        {!task.month && <span className="text-slate-500">-</span>}
                        {!task.month && <InteractiveCurrency amountCFA={amountCFA} className={isSelected ? 'text-primary' : 'text-slate-400'} />}
                      </div>
                      <div className="flex items-center gap-2 mt-1">
                        {isExpired ? (
                          <span className="text-xs font-bold text-danger bg-danger/10 px-2 py-0.5 rounded">EXPIRED</span>
                        ) : null}
                        <p className={`text-xs ${isExpired ? 'text-danger/80' : 'text-slate-500'}`}>Due: {dueText}</p>
                      </div>
                    </div>
                    {isSelected && <div className="w-4 h-4 bg-primary rounded-full shrink-0"></div>}
                  </div>
                );
              })}
            </div>
            <button 
              disabled={state.billingMonths.length === 0 && dueInvoices.length > 0}
              onClick={async () => {
                try {
                  const invoiceIds = state.billingMonths.map(m => m.invoice_id);
                  if (invoiceIds.length > 0) {
                    if (state.collectionType === 'Electricity Subscription') {
                      await api.post('/energy/agent/subscription-invoices/request-qr', { invoice_ids: invoiceIds });
                    } else {
                      await api.post('/agent/rent/request-qr', { invoice_ids: invoiceIds });
                    }
                  }
                } catch (e) {
                  console.error("Failed to request QR from tenant", e);
                }
                dispatch({ type: 'PROCEED_TO_AUTHORIZE' });
              }} 
              className="w-full mt-4 py-3 bg-primary text-white font-bold rounded-xl disabled:opacity-50"
            >
              Proceed to Payment
            </button>
          </div>
        );

      case STATES.AUTHORIZE_PAYMENT:
        return (
          <div className="space-y-4">
            <div className="text-center mb-6">
              <h3 className="text-white font-bold text-xl mb-2">Authorize Collection</h3>
              <p className="text-slate-400 text-sm">Please scan the tenant's QR code or manually enter the invoice code to accept and proceed with the payment.</p>
            </div>
            
            {state.error && (
              <div className="p-3 bg-danger/20 border border-danger/40 text-danger text-sm rounded-xl mb-4 font-bold text-center">
                {state.error}
              </div>
            )}

            <div className="bg-black rounded-xl overflow-hidden aspect-square relative border-2 border-primary/30 max-w-sm mx-auto mb-6">
              <QRScanner onScanSuccess={handleAuthorizeScan} />
            </div>
            
            <div className="flex items-center gap-4 py-2">
              <div className="h-px bg-slate-700 flex-1"></div>
              <span className="text-slate-500 font-bold text-sm uppercase">OR</span>
              <div className="h-px bg-slate-700 flex-1"></div>
            </div>

            <div className="space-y-3">
              <label className="text-sm font-bold text-slate-400 block">Manual Invoice Code</label>
              <div className="flex gap-2">
                <input 
                  type="text" 
                  placeholder="e.g., INV-202610-18"
                  className="flex-1 bg-[#0F172A] border border-slate-700 rounded-xl px-4 py-3 text-white font-bold outline-none focus:border-primary uppercase"
                  value={manualCode}
                  onChange={(e) => setManualCode(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleAuthorizeManual(manualCode)}
                />
                <button 
                  onClick={() => handleAuthorizeManual(manualCode)}
                  disabled={!manualCode.trim()}
                  className="bg-primary hover:bg-primary/90 text-white font-bold px-6 py-3 rounded-xl disabled:opacity-50 transition-colors"
                >
                  Verify
                </button>
              </div>
            </div>
          </div>
        );

      case STATES.QR_SCANNING:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Scanning QR Code</h3>
            {state.error && (
              <div className="p-3 bg-danger/20 border border-danger/40 text-danger text-sm rounded-xl mb-4 font-bold">
                {state.error}
              </div>
            )}
            <div className="bg-black rounded-xl overflow-hidden aspect-square relative border-2 border-primary/30">
              <QRScanner onScanSuccess={handleQRScanSuccess} />
            </div>
            <button 
              onClick={() => dispatch({ type: 'FALLBACK_TO_MANUAL' })}
              className="w-full py-3 bg-slate-800 hover:bg-slate-700 text-white font-bold rounded-xl transition-colors"
            >
              Cancel Scan
            </button>
          </div>
        );

      case STATES.REVIEW_PAYMENT:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Review Payment Details</h3>
            <div className="p-5 bg-[#0F172A] border border-slate-700 rounded-xl space-y-3 relative overflow-hidden">
              <div className="absolute top-0 right-0 p-3 bg-primary/20 rounded-bl-xl text-primary font-bold text-xs uppercase">
                {state.collectionType}
              </div>
              <div className="flex items-center text-info mb-2">
                <Info size={16} className="mr-2"/> Verified Record
              </div>
              <div className="grid grid-cols-2 gap-y-3 text-sm">
                <p className="text-slate-400">Tenant:</p>
                <p className="text-white font-bold text-right">{state.identifiedTask?.tenant_name}</p>
                
                <p className="text-slate-400">Property:</p>
                <p className="text-white font-bold text-right">{state.identifiedTask?.building_name}, Apt {state.identifiedTask?.apartment_number || state.identifiedTask?.apartment_code}</p>
                
                <p className="text-slate-400">Invoice:</p>
                <p className="text-white font-bold text-right">{state.identifiedTask?.invoice_number || `INV-${state.identifiedTask?.invoice_id}`}</p>
              </div>
              
              <div className="pt-3 mt-3 border-t border-slate-700 flex justify-between items-center">
                <p className="text-slate-300 font-bold">Amount Due:</p>
                <div className="text-danger font-bold text-xl">
                  <InteractiveCurrency amountCFA={state.identifiedTask?.remaining || state.identifiedTask?.amount || 0} />
                </div>
              </div>
            </div>
            
            <button 
              onClick={() => dispatch({ type: 'CONFIRM_PAYMENT_DETAILS' })}
              className="w-full py-3 bg-primary hover:bg-primary/90 text-white font-bold rounded-xl shadow-lg shadow-primary/20"
            >
              Confirm Details
            </button>
          </div>
        );

      case STATES.SELECT_METHOD:
        return (
          <div className="space-y-4">
            <h3 className="text-white font-bold mb-4">Select Payment Method</h3>
            <div className="grid grid-cols-2 gap-4">
              <button onClick={() => dispatch({ type: 'SELECT_METHOD', payload: 'Cash' })} className="p-6 bg-[#0F172A] border border-slate-700 rounded-xl hover:border-primary transition-colors group">
                <CreditCard className="mx-auto mb-2 text-primary group-hover:scale-110 transition-transform" size={32} />
                <span className="text-white font-bold">Physical Cash</span>
              </button>
              <button onClick={() => dispatch({ type: 'SELECT_METHOD', payload: 'OMT' })} className="p-6 bg-[#0F172A] border border-slate-700 rounded-xl hover:border-primary transition-colors group">
                <CreditCard className="mx-auto mb-2 text-primary group-hover:scale-110 transition-transform" size={32} />
                <span className="text-white font-bold">Digital Transfer</span>
              </button>
            </div>
          </div>
        );

      case STATES.MANUAL_ENTRY:
        return (
          <div className="space-y-6">
            <h3 className="text-white font-bold mb-4">Amount Received</h3>
            <div className="p-4 bg-warning/10 border border-warning/30 rounded-xl">
              <p className="text-warning text-sm">Please explicitly verify the physical cash or transfer before submitting.</p>
            </div>
            <div>
              <label className="block text-sm text-slate-400 mb-2">Fiat Amount ($)</label>
              <input 
                type="number"
                value={state.amount} // Specifically defaults to 0 based on PRD
                onChange={(e) => dispatch({ type: 'SET_AMOUNT', payload: e.target.value })}
                className="w-full bg-[#0F172A] border border-slate-700 rounded-xl px-4 py-4 text-white font-bold text-2xl text-center focus:outline-none focus:border-primary"
              />
            </div>
            <button 
              disabled={Number(state.amount) < 0}
              onClick={handleSubmit}
              className="w-full py-4 bg-success hover:bg-success/90 text-white font-bold rounded-xl disabled:opacity-50 text-lg shadow-lg shadow-success/20"
            >
              Submit Collection
            </button>
          </div>
        );
      
      case STATES.SUBMITTING:
        return (
          <div className="flex flex-col items-center justify-center py-12">
            <Loader2 className="animate-spin text-primary mb-4" size={48} />
            <h3 className="text-white font-bold text-lg">Persisting Transaction...</h3>
          </div>
        );

      default:
        return null;
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/80 backdrop-blur-sm">
      <div className="bg-[#1E293B] rounded-2xl border border-slate-700 w-full max-w-lg shadow-2xl flex flex-col max-h-[90vh]">
        
        {/* Header */}
        <div className="flex justify-between items-center p-5 border-b border-slate-700 bg-[#0F172A]">
          <div className="flex items-center gap-3">
            {state.currentState !== STATES.IDENTIFY && state.currentState !== STATES.SUBMITTING && (
              <button onClick={() => dispatch({ type: 'GO_BACK' })} className="text-slate-400 hover:text-white">
                <ArrowLeft size={20} />
              </button>
            )}
            <h2 className="text-lg font-bold text-white">Add Collection Wizard</h2>
          </div>
          <button onClick={onClose} className="text-slate-400 hover:text-white transition-colors">
            <X size={24} />
          </button>
        </div>

        {/* Content Body */}
        <div className="p-6 flex-1 overflow-y-auto custom-scrollbar">
          {renderStateContent()}
        </div>
      </div>
    </div>
  );
};

export default AddCollectionModal;
