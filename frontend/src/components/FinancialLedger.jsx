import React from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { DollarSign, Search, Calendar, FileText, UserX } from 'lucide-react';
import InteractiveCurrency from './common/InteractiveCurrency';

const FinancialLedger = ({ tenantId = null }) => {
  const { t } = useTranslation();

  const { data: ledger, isLoading } = useQuery({
    queryKey: ['financialLedger', tenantId],
    queryFn: async () => {
      const url = tenantId 
        ? `/financial-reports/tenant-ledger?tenant_id=${tenantId}` 
        : `/financial-reports/tenant-ledger`;
      const response = await api.get(url);
      return response.data;
    }
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center p-8 text-slate-400">
        <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-primary mr-3"></div>
        Loading financial ledger...
      </div>
    );
  }

  return (
    <div className="bg-slate-900/50 rounded-xl border border-slate-700 overflow-hidden">
      <div className="p-6 border-b border-slate-700 flex justify-between items-center bg-slate-800/30">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-primary/20 text-primary rounded-lg">
            <DollarSign size={24} />
          </div>
          <div>
            <h3 className="text-xl font-bold text-white">Financial Ledger</h3>
            <p className="text-slate-400 text-sm">Historical record of all paid invoices</p>
          </div>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="bg-slate-800/50 border-b border-slate-700 text-slate-300 text-sm uppercase tracking-wider">
              <th className="p-4 font-medium">Date</th>
              <th className="p-4 font-medium">Invoice #</th>
              <th className="p-4 font-medium">Tenant</th>
              <th className="p-4 font-medium">Unit</th>
              <th className="p-4 font-medium text-right">Amount Paid</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-700/50">
            {ledger?.length === 0 ? (
              <tr>
                <td colSpan="5" className="p-8 text-center text-slate-400">
                  <FileText className="mx-auto mb-3 opacity-50" size={32} />
                  No historical payments found.
                </td>
              </tr>
            ) : (
              ledger?.map((entry) => (
                <tr key={entry.payment_id} className="hover:bg-slate-800/30 transition-colors group">
                  <td className="p-4 text-slate-300 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      <Calendar size={14} className="text-slate-500" />
                      {entry.payment_date}
                    </div>
                  </td>
                  <td className="p-4 text-slate-200 font-medium">
                    {entry.invoice_number}
                  </td>
                  <td className="p-4">
                    <div className="flex items-center gap-2">
                      <span className="text-white font-medium">{entry.tenant_name}</span>
                      {entry.tenant_status === 'Terminated' && (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-slate-700 text-slate-300 border border-slate-600">
                          <UserX size={12} />
                          Terminated
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="p-4">
                    <span className="text-slate-300">
                      {entry.building_name} - <strong className="text-white">{entry.apartment_code}</strong>
                    </span>
                  </td>
                  <td className="p-4 text-right">
                    <div className="inline-block px-3 py-1 bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 rounded-lg font-bold">
                      <InteractiveCurrency amountCFA={entry.amount_paid} />
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default FinancialLedger;
