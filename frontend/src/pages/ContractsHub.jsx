import { useTranslation } from 'react-i18next';
import React, { useState } from 'react';
import { FileText, FileCheck2, ClipboardList } from 'lucide-react';
import Contracts from './Contracts';
import PendingContracts from './PendingContracts';

const TABS = [
  { id: 'active', label: 'Active Contracts', icon: FileText },
  { id: 'pending', label: 'Pending Actions', icon: FileCheck2 },
];

const ContractsHub = () => {
  const { t } = useTranslation();

  const [activeTab, setActiveTab] = useState('active');

  return (
    <div className="flex h-full w-full bg-background overflow-hidden print:bg-white">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar print:p-0">
        <div className="mb-8 print:hidden">
          <h1 className="text-3xl font-bold text-white flex items-center gap-3">
            <ClipboardList className="text-primary" size={36} /> 
            {t('contractshub.contract_management', { defaultValue: `Contract Management` })}
          </h1>
          <p className="text-muted mt-2">{t('contractshub.manage_all_rental_contracts_dr', { defaultValue: `Manage all rental contracts, drafts, and approval workflows in one place.` })}</p>
        </div>

        <div className="flex gap-1 bg-slate-900/60 p-1 rounded-xl border border-slate-800 mb-8 w-fit print:hidden">
          {TABS.map(tab => {
            const Icon = tab.icon;
            return (
              <button 
                key={tab.id} 
                onClick={() => setActiveTab(tab.id)} 
                className={`flex items-center gap-2 px-5 py-2.5 rounded-lg font-medium text-sm transition-all ${
                  activeTab === tab.id 
                    ? 'bg-primary text-white shadow-lg shadow-primary/30' 
                    : 'text-slate-400 hover:text-white hover:bg-slate-800'
                }`}
              >
                <Icon size={15} /> {tab.label}
              </button>
            );
          })}
        </div>

        {activeTab === 'active' && <Contracts />}
        {activeTab === 'pending' && <PendingContracts />}
      </div>
    </div>
  );
};

export default ContractsHub;
