import { useTranslation } from 'react-i18next';
import React, { useState, useRef, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import api from '../api/axios';
import { Home, DollarSign, Shield, ArrowLeft, Building, Users, Printer, Calendar, Filter, ChevronDown, Search, ShoppingCart } from 'lucide-react';
import ApartmentCostsModal from '../components/ApartmentCostsModal';

const BuildingDetails = () => {
  const { t } = useTranslation();

  const { id } = useParams();
  const navigate = useNavigate();
  const [showCostsModal, setShowCostsModal] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['buildingDetails', id],
    queryFn: async () => {
      const res = await api.get(`/buildings/${id}`);
      return res.data;
    }
  });

  if (isLoading) return <div className="p-8 text-white">{t('buildingdetails.loading', { defaultValue: `Loading...` })}</div>;

  const building = data?.building || data;
  const buildingApartments = data?.apartments || [];

  return (
    <div className="flex h-full w-full overflow-hidden bg-background print:bg-white print:text-black">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0 print:overflow-visible">

        <button
          onClick={() => navigate('/buildings')}
          className="flex items-center gap-2 text-indigo-400 hover:text-indigo-300 font-medium mb-6 transition-colors print:hidden"
        >
          <ArrowLeft size={20} />
          {t('buildingdetails.back_to_buildings', { defaultValue: `Back to Buildings` })}
        </button>

        <div className="glass-card p-8 flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 mb-8 print:hidden">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">{building?.name}</h1>
            <p className="text-slate-400">
              {t('buildingdetails.select_option', { defaultValue: `Select an option below to manage this building's resources.` })}
            </p>
          </div>
          <button
            onClick={() => setShowCostsModal(true)}
            className="px-6 py-3 bg-indigo-500/20 hover:bg-indigo-500/30 text-indigo-300 rounded-xl font-bold border border-indigo-500/30 transition-all flex items-center gap-2"
          >
            <ShoppingCart size={20} />
            Review Agent Purchases
          </button>
        </div>

        {/* Management Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-12 print:hidden">
          <div
            onClick={() => navigate(`/apartments?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-blue-400/50 transition-all group"
          >
            <div className="bg-blue-500/10 text-blue-400 p-5 rounded-full mb-4 group-hover:bg-blue-500/20 transition-colors">
              <Home size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.apartments', { defaultValue: `Apartments` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_units_and_statuses', { defaultValue: `Manage units and statuses` })}</p>
          </div>

          <div
            onClick={() => navigate(`/tenants?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-orange-400/50 transition-all group"
          >
            <div className="bg-orange-500/10 text-orange-400 p-5 rounded-full mb-4 group-hover:bg-orange-500/20 transition-colors">
              <Users size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.tenants', { defaultValue: `Tenants` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_building_residents', { defaultValue: `Manage building residents` })}</p>
          </div>

          <div
            onClick={() => navigate(`/building-rent?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-green-400/50 transition-all group"
          >
            <div className="bg-green-500/10 text-green-400 p-5 rounded-full mb-4 group-hover:bg-green-500/20 transition-colors">
              <DollarSign size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.rent_management', { defaultValue: `Rent Management` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.track_payments_and_invoices', { defaultValue: `Track payments and invoices` })}</p>
          </div>

          <div
            onClick={() => navigate(`/building-insurance?building=${id}`)}
            className="glass-card cursor-pointer p-6 flex flex-col items-center justify-center text-center hover:border-purple-400/50 transition-all group"
          >
            <div className="bg-purple-500/10 text-purple-400 p-5 rounded-full mb-4 group-hover:bg-purple-500/20 transition-colors">
              <Shield size={32} />
            </div>
            <h2 className="text-xl font-semibold text-white">{t('buildingdetails.insurance_management', { defaultValue: `Insurance Management` })}</h2>
            <p className="text-muted text-sm mt-2">{t('buildingdetails.manage_deposits_deductions', { defaultValue: `Manage deposits & deductions` })}</p>
          </div>
        </div>



      </div>

      {showCostsModal && (
        <ApartmentCostsModal
          building={building}
          onClose={() => setShowCostsModal(false)}
        />
      )}
    </div>
  );
};

export default BuildingDetails;
