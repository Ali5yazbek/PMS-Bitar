import React from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { X, Loader2 } from 'lucide-react';
import TenantBillingDashboard from './TenantBillingDashboard';

const ApartmentBillingModal = ({ apartmentId, onClose }) => {
  const { t } = useTranslation();

  const { data: electricitySubscription, isLoading: subLoading } = useQuery({
    queryKey: ['electricitySubscription', apartmentId],
    queryFn: async () => {
      try {
        return (await api.get(`/energy/apartments/${apartmentId}/subscriptions`)).data;
      } catch (err) {
        return null;
      }
    }
  });

  const { data: latestReading, isLoading: readingLoading } = useQuery({
    queryKey: ['latestReading', apartmentId],
    queryFn: async () => {
      try {
        return (await api.get(`/energy/apartments/${apartmentId}/meter-readings/latest`)).data;
      } catch (err) {
        return { latest_reading: 0 };
      }
    }
  });

  const { data: electricityInvoices, isLoading: invoicesLoading } = useQuery({
    queryKey: ['electricityInvoices', apartmentId],
    queryFn: async () => {
      try {
        return (await api.get(`/electricity/apartments/${apartmentId}/invoices`)).data;
      } catch (err) {
        return [];
      }
    }
  });

  if (subLoading || readingLoading || invoicesLoading) {
    return (
      <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50">
        <div className="bg-[#0F172A] border border-slate-700 p-8 w-full max-w-4xl rounded-2xl flex flex-col items-center justify-center min-h-[400px]">
           <Loader2 className="animate-spin text-primary mb-4" size={48} />
           <p className="text-slate-400">Loading billing data...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-[100] p-4 overflow-y-auto">
      <div className="bg-[#0F172A] border border-slate-700 w-full max-w-5xl rounded-2xl relative animate-in zoom-in-95 shadow-2xl my-auto">
        <button 
          onClick={onClose}
          className="absolute top-4 right-4 bg-slate-800 hover:bg-slate-700 text-slate-300 p-2 rounded-full transition-colors z-10"
        >
          <X size={24} />
        </button>
        <div className="p-8">
          <TenantBillingDashboard 
            tenant={{ apartment_id: apartmentId }}
            electricitySubscription={electricitySubscription}
            latestReading={latestReading}
            electricityInvoices={electricityInvoices}
            onPayInvoice={null} // Can implement pay invoice later if needed here
          />
        </div>
      </div>
    </div>
  );
};

export default ApartmentBillingModal;
