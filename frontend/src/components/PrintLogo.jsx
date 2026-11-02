import React from 'react';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';

const PrintLogo = ({ className = "h-16 w-auto object-contain mx-auto mb-2" }) => {
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
    staleTime: 600000
  });

  if (!settings) return null;

  return (
    <div className="flex flex-col items-center justify-center mb-4 text-center">
      {settings.company_logo && (
          <img 
            src={`${process.env.REACT_APP_API_URL || ''}${settings.company_logo}`} 
            alt="Company Logo" 
            className={className}
            style={{ maxHeight: '100px', maxWidth: '250px' }}
          />
      )}
      {settings.company_name && <h2 className="text-2xl font-black uppercase mt-2">{settings.company_name}</h2>}
      {settings.business_address && <p className="text-sm mt-1">{settings.business_address}</p>}
      
      <div className="text-xs mt-1">
          {settings.phone && <span>Tel: {settings.phone} </span>}
          {settings.tax_number && <span>| Tax: {settings.tax_number}</span>}
      </div>
      
      {settings.receipt_header && (
          <p className="text-sm mt-3 whitespace-pre-wrap italic">{settings.receipt_header}</p>
      )}
    </div>
  );
};

export default PrintLogo;
