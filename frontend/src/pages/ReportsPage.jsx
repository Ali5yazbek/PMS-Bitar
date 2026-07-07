import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { FileText, Download } from 'lucide-react';

const ReportsPage = () => {
  const { t } = useTranslation();

  const [reportType, setReportType] = useState('rent-collection');
  const [startDate, setStartDate] = useState(new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);

  const { data: reportData, isLoading } = useQuery({ 
    queryKey: ['report', reportType, startDate, endDate], 
    queryFn: async () => (await api.get(`/reports/${reportType}?start_date=${startDate}&end_date=${endDate}`)).data 
  });

  const reportTypes = [
    { id: 'rent-collection', name: 'Rent Collection Report' },
    { id: 'outstanding-balance', name: 'Outstanding Balance Report' },
    { id: 'insurance', name: 'Insurance Report' },
    { id: 'apartment-expense', name: 'Apartment Expense Report' },
    { id: 'contract-expiration', name: 'Contract Expiration Report' },
    { id: 'renewal', name: 'Renewal Report' },
    { id: 'building-financial', name: 'Building Financial Summary' }
  ];

  return (
    <div className="flex h-full w-full bg-background overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <FileText className="me-3 text-primary" size={32} />
              {t('reportspage.reports', { defaultValue: `Reports` })}
            </h1>
            <p className="text-muted mt-2">{t('reportspage.generate_and_export_various_sy', { defaultValue: `Generate and export various system reports.` })}</p>
          </div>
          <button className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center gap-2 transition-colors">
            <Download size={20} />
            <span>{t('reportspage.export_pdf', { defaultValue: `Export PDF` })}</span>
          </button>
        </div>

        <div className="glass-card p-6 mb-8 flex flex-wrap gap-4 items-end">
          <div>
            <label className="block text-sm font-medium text-muted mb-1">{t('reportspage.report_type', { defaultValue: `Report Type` })}</label>
            <select value={reportType} onChange={e => setReportType(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary w-64">
              {reportTypes.map(rt => <option key={rt.id} value={rt.id}>{rt.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-muted mb-1">{t('reportspage.start_date', { defaultValue: `Start Date` })}</label>
            <input type="date" value={startDate} onChange={e => setStartDate(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" />
          </div>
          <div>
            <label className="block text-sm font-medium text-muted mb-1">{t('reportspage.end_date', { defaultValue: `End Date` })}</label>
            <input type="date" value={endDate} onChange={e => setEndDate(e.target.value)} className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white outline-none focus:border-primary" />
          </div>
        </div>

        <div className="glass-card overflow-hidden p-6">
          {isLoading ? (
            <div className="text-muted">{t('reportspage.loading_report_data', { defaultValue: `Loading report data...` })}</div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-slate-700/50 text-start">
                {/* Dynamically render table headers and rows based on report type */}
                {reportData && reportData.length > 0 ? (
                  <>
                    <thead>
                      <tr className="bg-slate-800/30">
                        {Object.keys(reportData[0]).map(key => (
                          <th key={key} className="px-6 py-4 text-xs font-semibold text-muted uppercase tracking-wider text-start">
                            {key.replace(/_/g, ' ')}
                          </th>
                        ))}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-700/50">
                      {reportData.map((row, idx) => (
                        <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                          {Object.values(row).map((val, vIdx) => (
                            <td key={vIdx} className="px-6 py-4 text-sm text-slate-300">{val}</td>
                          ))}
                        </tr>
                      ))}
                    </tbody>
                  </>
                ) : (
                  <tbody><tr><td className="p-4 text-muted text-center">{t('reportspage.no_data_found_for_the_selected', { defaultValue: `No data found for the selected period.` })}</td></tr></tbody>
                )}
              </table>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ReportsPage;
