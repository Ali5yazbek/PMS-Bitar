import React from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';

const PrintHeader = ({ title, subtitle, fallbackText = "BITAR PMS" }) => {
  const { t } = useTranslation();
  
  const { data: settings } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => {
      try {
        const res = await api.get('/global-settings');
        return res.data;
      } catch(e) {
        return {};
      }
    },
    staleTime: 600000 // 10 mins
  });

  const logoUrl = settings?.company_logo 
    ? `${process.env.REACT_APP_API_URL || ''}${settings.company_logo}`
    : null;

  return (
    <div className="w-full mb-6 border-b-2 border-slate-800 pb-4 flex items-end justify-between">
      <div className="flex items-center gap-4">
        {logoUrl ? (
          <img 
            src={logoUrl} 
            alt="Company Logo" 
            className="h-20 w-auto object-contain print:h-20 print:w-auto"
            style={{ maxHeight: '100px', maxWidth: '250px' }}
          />
        ) : (
          <h1 className="text-3xl font-black uppercase tracking-widest text-slate-800 m-0">
            {settings?.company_name || fallbackText}
          </h1>
        )}
        <div className="flex flex-col ml-4">
            {settings?.company_name && logoUrl && <h2 className="text-xl font-bold text-slate-800 leading-tight mb-1">{settings.company_name}</h2>}
            {settings?.business_address && <span className="text-sm text-slate-600 leading-snug">{settings.business_address}</span>}
            <div className="flex gap-3 text-xs text-slate-500 mt-1">
                {settings?.phone && <span>Tel: {settings.phone}</span>}
                {settings?.email && <span>| Email: {settings.email}</span>}
                {settings?.website && <span>| Web: {settings.website}</span>}
            </div>
            <div className="flex gap-3 text-xs text-slate-500 mt-0.5">
                {settings?.tax_number && <span>Tax: {settings.tax_number}</span>}
                {settings?.registration_number && <span>| Reg: {settings.registration_number}</span>}
            </div>
        </div>
      </div>
      {(title || subtitle) && (
        <div className="text-right">
          {title && <h2 className="text-xl font-bold text-slate-800 m-0">{title}</h2>}
          {subtitle && <p className="text-sm text-slate-600 m-0 mt-1">{subtitle}</p>}
        </div>
      )}
    </div>
  );
};

export default PrintHeader;
