import React from 'react';
import { useTranslation } from 'react-i18next';
import { RefreshCw, FileText } from 'lucide-react';
import { Link } from 'react-router-dom';

const Returns = () => {
  const { t } = useTranslation();

  return (
    <div className="p-6 h-full overflow-auto hide-scrollbar">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
            <RefreshCw className="me-3 text-primary" size={28} />
            Returns Center
          </h1>
          <p className="text-muted text-sm">Manage product returns, refunds, and exchanges.</p>
        </div>
      </div>

      <div className="glass-card p-12 flex flex-col items-center justify-center text-center">
        <RefreshCw size={64} className="text-slate-500 mb-6" />
        <h2 className="text-2xl font-bold text-white mb-4">Start a Return</h2>
        <p className="text-slate-400 mb-8 max-w-md">
          To initiate a return, please locate the original invoice in the Sales History and select the "Return Items" option.
        </p>
        <Link 
          to="/sales" 
          className="bg-primary hover:bg-indigo-600 text-white px-6 py-3 rounded-xl font-bold flex items-center transition-all shadow-lg shadow-primary/30"
        >
          <FileText size={20} className="me-2" />
          Go to Sales History
        </Link>
      </div>
    </div>
  );
};

export default Returns;
