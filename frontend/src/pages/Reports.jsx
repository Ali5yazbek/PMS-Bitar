import { useTranslation } from 'react-i18next';
import React from 'react';

const Reports = () => {
  const { t } = useTranslation();

  return (
    <div className="flex h-full w-full overflow-hidden">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <h1 className="text-3xl font-bold text-white mb-8">{t('reports.reports', { defaultValue: `Reports` })}</h1>
        <div className="glass-card p-8 flex items-center justify-center text-muted h-64">
          {t('reports.reports_module_coming_soon', { defaultValue: `Reports Module Coming Soon` })}
        </div>
      </div>
    </div>
  );
};

export default Reports;
