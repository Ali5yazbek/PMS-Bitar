import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Settings, Save, RefreshCw, DollarSign } from 'lucide-react';

const GlobalSettings = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [formData, setFormData] = useState({ usd_to_cfa: '600' });
  const [isSaving, setIsSaving] = useState(false);

  const { data: settings, isLoading } = useQuery({
    queryKey: ['globalSettings'],
    queryFn: async () => {
      const res = await api.get('/global-settings');
      return res.data;
    }
  });

  useEffect(() => {
    if (settings && settings.usd_to_cfa) {
      setFormData(prev => ({ ...prev, usd_to_cfa: settings.usd_to_cfa }));
    }
  }, [settings]);

  const updateMutation = useMutation({
    mutationFn: (data) => api.put(`/global-settings/usd_to_cfa`, { value: data.usd_to_cfa }),
    onSuccess: () => {
      queryClient.invalidateQueries(['globalSettings']);
      setIsSaving(false);
    },
    onError: () => {
      setIsSaving(false);
    }
  });

  const handleSave = () => {
    setIsSaving(true);
    updateMutation.mutate(formData);
  };

  if (isLoading) return <div className="p-8 text-muted">{t('settings.loading', { defaultValue: 'Loading settings...' })}</div>;

  return (
    <div className="flex h-full w-full bg-background overflow-hidden animate-in fade-in duration-300">
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center">
              <Settings className="me-3 text-primary" size={32} />
              {t('settings.global_settings', { defaultValue: 'Global Settings' })}
            </h1>
            <p className="text-muted mt-2">{t('settings.global_settings_desc', { defaultValue: 'Manage system-wide configuration and preferences.' })}</p>
          </div>
        </div>

        <div className="max-w-2xl">
          <div className="glass-card p-8">
            <h2 className="text-xl font-semibold text-white border-b border-slate-700/50 pb-4 mb-6 flex items-center gap-2">
              <DollarSign className="text-success" size={24} />
              {t('settings.currency_conversion', { defaultValue: 'Currency Conversion' })}
            </h2>
            
            <div className="space-y-6">
              <div>
                <label className="block text-sm font-medium text-muted mb-2">
                  {t('settings.usd_to_cfa_rate', { defaultValue: 'USD to CFA Exchange Rate' })}
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <span className="text-slate-400 font-medium">1 $ = </span>
                  </div>
                  <input
                    type="number"
                    min="1"
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl pl-12 pr-12 py-3 text-white text-lg font-bold outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all"
                    value={formData.usd_to_cfa}
                    onChange={(e) => setFormData({ ...formData, usd_to_cfa: e.target.value })}
                  />
                  <div className="absolute inset-y-0 right-0 pr-4 flex items-center pointer-events-none">
                    <span className="text-slate-400 font-medium">CFA</span>
                  </div>
                </div>
                <p className="text-xs text-slate-500 mt-2">
                  {t('settings.usd_to_cfa_help', { defaultValue: 'This rate is used to automatically convert USD input values to CFA across the application.' })}
                </p>
              </div>

              <div className="pt-4 border-t border-slate-700/50 flex justify-end">
                <button
                  onClick={handleSave}
                  disabled={isSaving}
                  className="bg-primary hover:bg-indigo-600 text-white px-6 py-2.5 rounded-xl font-semibold flex items-center gap-2 transition-all shadow-lg shadow-primary/20 disabled:opacity-50"
                >
                  {isSaving ? (
                    <RefreshCw className="animate-spin" size={20} />
                  ) : (
                    <Save size={20} />
                  )}
                  {isSaving ? t('settings.saving', { defaultValue: 'Saving...' }) : t('settings.save_changes', { defaultValue: 'Save Changes' })}
                </button>
              </div>
            </div>
          </div>
        </div>
        
      </div>
    </div>
  );
};

export default GlobalSettings;
