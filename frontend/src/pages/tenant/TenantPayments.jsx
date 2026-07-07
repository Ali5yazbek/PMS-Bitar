import { useTranslation } from 'react-i18next';
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../../api/axios';
import { DollarSign, AlertTriangle } from 'lucide-react';

const TenantPayments = () => {
  const { t } = useTranslation();

  const { data: rentHistory, isLoading } = useQuery({ 
    queryKey: ['tenant-rent-history'], 
    queryFn: async () => (await api.get('/tenant-portal/rent-history')).data 
  });

  if (isLoading) return <div className="p-8 text-muted">{t('tenantpayments.loading_your_payment_history', { defaultValue: `Loading your payment history...` })}</div>;

  const totalOutstanding = rentHistory?.reduce((sum, item) => sum + Number(item.outstanding_debt), 0) || 0;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
            <DollarSign className="me-3 text-primary" size={32} />
            {t('tenantpayments.my_payments', { defaultValue: `My Payments` })}
          </h1>
          <p className="text-muted">{t('tenantpayments.review_your_payment_history_an', { defaultValue: `Review your payment history and outstanding balances.` })}</p>
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

        <div className="glass-card overflow-hidden">
          <table className="min-w-full divide-y divide-slate-700/50 text-start">
            <thead>
              <tr className="bg-slate-800/30">
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.invoice', { defaultValue: `Invoice` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.due_date', { defaultValue: `Due Date` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.amount', { defaultValue: `Amount` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.paid', { defaultValue: `Paid` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.balance', { defaultValue: `Balance` })}</th>
                <th className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">{t('tenantpayments.status', { defaultValue: `Status` })}</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/50">
              {rentHistory?.map((invoice, idx) => (
                <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                  <td className="px-6 py-4">
                    <div className="font-medium text-white">{invoice.invoice_number}</div>
                  </td>
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
                </tr>
              ))}
            </tbody>
          </table>
          {(!rentHistory || rentHistory.length === 0) && (
            <div className="p-8 text-center text-muted">{t('tenantpayments.no_rent_history_found', { defaultValue: `No rent history found.` })}</div>
          )}
        </div>
      </div>
    </div>
  );
};

export default TenantPayments;
