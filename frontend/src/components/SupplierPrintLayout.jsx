import { useTranslation } from 'react-i18next';
import React from 'react';
import PrintLogo from './PrintLogo';

const SupplierPrintLayout = ({ supplierDetails }) => {
  const { t } = useTranslation();

  if (!supplierDetails) return null;
  const { supplier, summary, transactions, purchases, payments, products, projects, aging } = supplierDetails;

  return (
    <div className="hidden print:block text-black bg-white w-full">
      {/* Header */}
      <div className="flex justify-between items-start border-b-2 border-slate-800 pb-6 mb-6">
        <div>
          <PrintLogo className="h-16 w-auto object-contain mb-2" />
          <h1 className="text-3xl font-bold font-serif text-slate-900 tracking-tight">{t('supplierprintlayout.bitar_enterprises', { defaultValue: `BITAR ENTERPRISES` })}</h1>
          <div className="text-sm text-slate-600 mt-1">
            <p>{t('supplierprintlayout.123_construction_blvd_industry', { defaultValue: `123 Construction Blvd, Industry City` })}</p>
            <p>{t('supplierprintlayout.phone_1_234_567_8900_email_acc', { defaultValue: `Phone: +1 234 567 8900 | Email: accounts@bitar.com` })}</p>
            <p>{t('supplierprintlayout.tin_987654321', { defaultValue: `TIN: 987654321` })}</p>
          </div>
        </div>
        <div className="text-right">
          <h2 className="text-2xl font-bold text-slate-800 uppercase tracking-widest">{t('supplierprintlayout.supplier_statement', { defaultValue: `Supplier Statement` })}</h2>
          <p className="text-sm text-slate-500 mt-1">{t('supplierprintlayout.generated', { defaultValue: `Generated:` })} {new Date().toLocaleDateString()}</p>
        </div>
      </div>

      {/* Supplier Info */}
      <div className="flex justify-between items-end mb-8 bg-slate-50 p-6 rounded-lg border border-slate-200">
        <div>
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">{t('supplierprintlayout.supplier_account', { defaultValue: `Supplier Account` })}</h3>
          <p className="text-xl font-bold text-slate-800">{supplier.name}</p>
          <p className="text-sm text-slate-600">{supplier.contact_info}</p>
          <p className="text-sm text-slate-600">{t('supplierprintlayout.type', { defaultValue: `Type:` })} {supplier.supplier_type}</p>
        </div>
        <div className="text-right">
          <h3 className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-1">{t('supplierprintlayout.account_summary', { defaultValue: `Account Summary` })}</h3>
          <p className="text-3xl font-bold text-slate-900">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(summary.currentBalance).toLocaleString()}</p>
          <p className="text-xs text-slate-500">{t('supplierprintlayout.total_outstanding_balance', { defaultValue: `Total Outstanding Balance` })}</p>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-4 gap-4 mb-8">
        <div className="border border-slate-200 p-4 rounded-lg text-center">
          <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">{t('supplierprintlayout.total_purchases', { defaultValue: `Total Purchases` })}</div>
          <div className="text-lg font-bold text-slate-800">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(summary.totalPurchases).toLocaleString()}</div>
        </div>
        <div className="border border-slate-200 p-4 rounded-lg text-center">
          <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">{t('supplierprintlayout.total_payments', { defaultValue: `Total Payments` })}</div>
          <div className="text-lg font-bold text-slate-800">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(summary.totalPaid).toLocaleString()}</div>
        </div>
        <div className="border border-slate-200 p-4 rounded-lg text-center">
          <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">{t('supplierprintlayout.credit_limit', { defaultValue: `Credit Limit` })}</div>
          <div className="text-lg font-bold text-slate-800">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(supplier.credit_limit || 0).toLocaleString()}</div>
        </div>
        <div className="border border-slate-200 p-4 rounded-lg text-center">
          <div className="text-xs text-slate-500 uppercase tracking-wider mb-1">{t('supplierprintlayout.payment_terms', { defaultValue: `Payment Terms` })}</div>
          <div className="text-lg font-bold text-slate-800">{supplier.payment_terms_days || 30} {t('supplierprintlayout.days', { defaultValue: `Days` })}</div>
        </div>
      </div>

      {/* Aging Report Summary */}
      <div className="mb-8">
         <h3 className="text-lg font-bold text-slate-800 mb-4 border-b border-slate-200 pb-2">{t('supplierprintlayout.aging_summary_overdue', { defaultValue: `Aging Summary (Overdue)` })}</h3>
         <table className="w-full text-sm border-collapse border border-slate-200">
          <thead>
            <tr className="bg-slate-100 text-slate-600">
              <th className="py-2 px-3 text-center border border-slate-200">{t('supplierprintlayout.0_30_days', { defaultValue: `0 - 30 Days` })}</th>
              <th className="py-2 px-3 text-center border border-slate-200">{t('supplierprintlayout.31_60_days', { defaultValue: `31 - 60 Days` })}</th>
              <th className="py-2 px-3 text-center border border-slate-200">{t('supplierprintlayout.61_90_days', { defaultValue: `61 - 90 Days` })}</th>
              <th className="py-2 px-3 text-center border border-slate-200">{t('supplierprintlayout.90_days', { defaultValue: `90+ Days` })}</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className="py-3 px-3 text-center font-medium text-slate-800 border border-slate-200">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(aging['0_30']).toLocaleString()}</td>
              <td className="py-3 px-3 text-center font-medium text-amber-600 border border-slate-200">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(aging['31_60']).toLocaleString()}</td>
              <td className="py-3 px-3 text-center font-medium text-orange-600 border border-slate-200">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(aging['61_90']).toLocaleString()}</td>
              <td className="py-3 px-3 text-center font-medium text-red-600 border border-slate-200">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(aging['90_plus']).toLocaleString()}</td>
            </tr>
          </tbody>
         </table>
      </div>

      {/* Account Statement */}
      <div>
        <h3 className="text-lg font-bold text-slate-800 mb-4 border-b border-slate-200 pb-2">{t('supplierprintlayout.account_statement_ledger', { defaultValue: `Account Statement / Ledger` })}</h3>
        <table className="w-full text-sm border-collapse">
          <thead>
            <tr className="bg-slate-800 text-white">
              <th className="py-2 px-3 text-left">{t('supplierprintlayout.date', { defaultValue: `Date` })}</th>
              <th className="py-2 px-3 text-left">{t('supplierprintlayout.ref', { defaultValue: `Ref` })}</th>
              <th className="py-2 px-3 text-left">{t('supplierprintlayout.type', { defaultValue: `Type` })}</th>
              <th className="py-2 px-3 text-right">{t('supplierprintlayout.debit_purchase', { defaultValue: `Debit (Purchase)` })}</th>
              <th className="py-2 px-3 text-right">{t('supplierprintlayout.credit_payment', { defaultValue: `Credit (Payment)` })}</th>
              <th className="py-2 px-3 text-right bg-slate-900">{t('supplierprintlayout.balance', { defaultValue: `Balance` })}</th>
            </tr>
          </thead>
          <tbody>
            {transactions?.map(tx => {
              const isDebit = ['Purchase', 'Opening Balance'].includes(tx.type) || tx.amount > 0;
              const debitAmt = isDebit ? Math.abs(tx.amount) : 0;
              const creditAmt = !isDebit ? Math.abs(tx.amount) : 0;
              return (
                <tr key={tx.id} className="border-b border-slate-200 text-slate-700">
                  <td className="py-2 px-3">{tx.transaction_date}</td>
                  <td className="py-2 px-3">{tx.reference_id}</td>
                  <td className="py-2 px-3">{tx.type}</td>
                  <td className="py-2 px-3 text-right">{debitAmt > 0 ? `CFA ${Number(debitAmt).toLocaleString()}` : '-'}</td>
                  <td className="py-2 px-3 text-right">{creditAmt > 0 ? `CFA ${Number(creditAmt).toLocaleString()}` : '-'}</td>
                  <td className="py-2 px-3 text-right font-bold text-slate-900">{t('supplierprintlayout.cfa', { defaultValue: `CFA` })} {Number(tx.balance_after).toLocaleString()}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Footer Signatures */}
      <div className="mt-20 pt-8 border-t-2 border-slate-800 flex justify-between">
        <div className="w-64">
          <div className="border-b border-slate-400 mb-2"></div>
          <div className="text-sm font-bold text-slate-800">{t('supplierprintlayout.authorized_signature_company', { defaultValue: `Authorized Signature (Company)` })}</div>
          <div className="text-xs text-slate-500 mt-1">{t('supplierprintlayout.date', { defaultValue: `Date: ____________________` })}</div>
        </div>
        <div className="w-64">
          <div className="border-b border-slate-400 mb-2"></div>
          <div className="text-sm font-bold text-slate-800">{t('supplierprintlayout.supplier_acknowledgment', { defaultValue: `Supplier Acknowledgment` })}</div>
          <div className="text-xs text-slate-500 mt-1">{t('supplierprintlayout.date', { defaultValue: `Date: ____________________` })}</div>
        </div>
      </div>
    </div>
  );
};

export default SupplierPrintLayout;
