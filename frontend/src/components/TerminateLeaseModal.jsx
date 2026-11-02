import React from 'react';
import { AlertTriangle, X } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const TerminateLeaseModal = ({ isOpen, onClose, onConfirm, tenantName, isLoading }) => {
  const { t } = useTranslation();

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4 animate-in fade-in duration-200">
      <div className="bg-slate-900 border border-slate-700 rounded-2xl w-full max-w-md overflow-hidden shadow-2xl shadow-red-900/20">
        <div className="p-6 border-b border-slate-700 flex justify-between items-center bg-red-950/20">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-red-500/20 rounded-lg text-red-400">
              <AlertTriangle size={24} />
            </div>
            <h2 className="text-xl font-bold text-white">
              Terminate Lease
            </h2>
          </div>
          <button
            onClick={onClose}
            className="text-slate-400 hover:text-white transition-colors p-2 hover:bg-slate-800 rounded-lg"
          >
            <X size={20} />
          </button>
        </div>

        <div className="p-6">
          <p className="text-slate-300 mb-4 leading-relaxed">
            Are you sure you want to terminate the lease for <span className="font-bold text-white">{tenantName}</span>?
          </p>

          <div className="bg-red-500/10 border-l-4 border-red-500 p-4 rounded-r-lg mb-6">
            <p className="text-red-400 text-sm leading-relaxed">
              <strong>Warning:</strong> This will terminate the lease, free up the unit, and void any pending unpaid invoices. 
              <br/><br/>
              Paid invoices will be safely kept for financial history.
            </p>
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <button
              onClick={onClose}
              disabled={isLoading}
              className="px-5 py-2.5 rounded-xl bg-slate-800 text-slate-300 hover:bg-slate-700 transition-colors font-medium"
            >
              Cancel
            </button>
            <button
              onClick={onConfirm}
              disabled={isLoading}
              className="px-5 py-2.5 rounded-xl bg-red-600 hover:bg-red-500 text-white transition-all shadow-lg shadow-red-900/30 flex items-center gap-2 font-medium"
            >
              {isLoading ? (
                <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : null}
              {isLoading ? 'Terminating...' : 'Confirm Termination'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TerminateLeaseModal;
