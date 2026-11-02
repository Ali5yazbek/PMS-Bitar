import React, { useState, useRef } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Settings as SettingsIcon, Save, Edit3, X, DollarSign, HardHat, Plus, Trash2, Users as UsersIcon, Bell, Shield, Database, Image as ImageIcon } from 'lucide-react';
import Users from './Users'; // The existing user management component

const Settings = () => {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState('branding');

  const tabs = [
    { id: 'branding', label: 'Company Branding', icon: ImageIcon },
    { id: 'users', label: 'User Management', icon: UsersIcon },
    { id: 'security', label: 'Security', icon: Shield },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'backup', label: 'Backup', icon: Database },
    { id: 'database', label: 'Database', icon: Database },
    { id: 'ai', label: 'AI Settings', icon: SettingsIcon },
    { id: 'pos', label: 'POS Settings', icon: DollarSign },
  ];

  return (
    <div className="flex h-full bg-background overflow-hidden">
      {/* Settings Sidebar */}
      <div className="w-64 bg-slate-900 border-r border-slate-800 flex flex-col h-full shrink-0">
        <div className="p-6">
          <h2 className="text-xl font-bold text-white flex items-center">
            <SettingsIcon className="me-2 text-primary" size={24} />
            Settings
          </h2>
        </div>
        <div className="flex-1 overflow-y-auto hide-scrollbar px-4 pb-4 space-y-2">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`w-full flex items-center px-4 py-3 rounded-xl transition-all ${
                  isActive 
                  ? 'bg-primary text-white shadow-lg shadow-primary/20' 
                  : 'text-muted hover:bg-slate-800 hover:text-white'
                }`}
              >
                <Icon size={18} className="me-3" />
                <span className="font-medium text-sm">{tab.label}</span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col h-full overflow-y-auto hide-scrollbar relative">
        <div className="p-8 max-w-6xl mx-auto w-full">
          {activeTab === 'branding' && <CompanyBrandingTab />}
          {activeTab === 'users' && <div className="-mx-8 -my-8 h-[calc(100vh-80px)]"><Users /></div>}
          {['notifications', 'security', 'backup', 'database', 'ai', 'pos'].includes(activeTab) && (
            <div className="glass-card p-12 text-center text-muted">
              <SettingsIcon size={48} className="mx-auto mb-4 opacity-50" />
              <h3 className="text-xl text-white mb-2">{tabs.find(t => t.id === activeTab)?.label}</h3>
              <p>This section is under construction.</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

const CompanyBrandingTab = () => {
  const queryClient = useQueryClient();
  const fileInputRef = useRef(null);
  const [preview, setPreview] = useState(null);
  const [file, setFile] = useState(null);
  const [isUploading, setIsUploading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  
  const [formData, setFormData] = useState({
      company_name: '', business_address: '', phone: '', email: '', 
      website: '', tax_number: '', registration_number: '', currency: 'CFA', 
      footer_message: '', receipt_header: '', receipt_footer: ''
  });

  const { data: settings } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => (await api.get('/global-settings')).data 
  });
  
  React.useEffect(() => {
      if (settings) {
          setFormData({
              company_name: settings.company_name || '',
              business_address: settings.business_address || '',
              phone: settings.phone || '',
              email: settings.email || '',
              website: settings.website || '',
              tax_number: settings.tax_number || '',
              registration_number: settings.registration_number || '',
              currency: settings.currency || 'CFA',
              footer_message: settings.footer_message || '',
              receipt_header: settings.receipt_header || '',
              receipt_footer: settings.receipt_footer || ''
          });
      }
  }, [settings]);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile) {
      if (!['image/png', 'image/jpeg', 'image/svg+xml'].includes(selectedFile.type)) return alert('Invalid file type.');
      if (selectedFile.size > 5 * 1024 * 1024) return alert('File size exceeds 5MB limit.');
      setFile(selectedFile);
      setPreview(URL.createObjectURL(selectedFile));
    }
  };

  const saveSettings = async () => {
    setIsSaving(true);
    try {
      if (file) {
          const fd = new FormData();
          fd.append('logo', file);
          await api.post('/global-settings/logo', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      }
      await api.post('/global-settings/bulk', formData);
      queryClient.invalidateQueries(['globalSettings']);
      alert('Settings saved successfully!');
    } catch (err) {
      alert('Failed to save settings.');
    } finally {
      setIsSaving(false);
    }
  };

  const currentLogo = settings?.company_logo;

  const handleChange = (e) => {
      setFormData({...formData, [e.target.name]: e.target.value});
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h1 className="text-2xl font-bold text-white mb-2">Company Branding & Settings</h1>
        <p className="text-muted text-sm">These details automatically appear on all generated PDFs, POS receipts, and invoices.</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="lg:col-span-2 space-y-6">
              <div className="glass-card p-6 space-y-4">
                  <h3 className="text-lg font-bold text-white border-b border-slate-700/50 pb-2">Business Information</h3>
                  <div className="grid grid-cols-2 gap-4">
                      <div>
                          <label className="block text-sm text-muted mb-1">Company Name</label>
                          <input type="text" name="company_name" value={formData.company_name} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Currency</label>
                          <input type="text" name="currency" value={formData.currency} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div className="col-span-2">
                          <label className="block text-sm text-muted mb-1">Business Address</label>
                          <input type="text" name="business_address" value={formData.business_address} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Phone</label>
                          <input type="text" name="phone" value={formData.phone} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Email</label>
                          <input type="email" name="email" value={formData.email} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Tax Number</label>
                          <input type="text" name="tax_number" value={formData.tax_number} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Registration Number</label>
                          <input type="text" name="registration_number" value={formData.registration_number} onChange={handleChange} className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white" />
                      </div>
                  </div>
              </div>

              <div className="glass-card p-6 space-y-4">
                  <h3 className="text-lg font-bold text-white border-b border-slate-700/50 pb-2">Document Texts</h3>
                  <div className="space-y-4">
                      <div>
                          <label className="block text-sm text-muted mb-1">Receipt Header Text</label>
                          <textarea name="receipt_header" value={formData.receipt_header} onChange={handleChange} rows="2" className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white"></textarea>
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Receipt Footer Text</label>
                          <textarea name="receipt_footer" value={formData.receipt_footer} onChange={handleChange} rows="2" className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white"></textarea>
                      </div>
                      <div>
                          <label className="block text-sm text-muted mb-1">Default Footer Message (A4 Invoices)</label>
                          <textarea name="footer_message" value={formData.footer_message} onChange={handleChange} rows="2" className="w-full bg-slate-800 border-slate-700 rounded-lg px-3 py-2 text-white"></textarea>
                      </div>
                  </div>
              </div>
          </div>

          <div className="space-y-6">
              <div className="glass-card p-6 text-center">
                  <h3 className="text-lg font-bold text-white mb-4 border-b border-slate-700/50 pb-2 text-start">Company Logo</h3>
                  
                  <div className="w-full aspect-square bg-slate-900 rounded-xl border border-slate-700 flex items-center justify-center p-4 overflow-hidden relative mb-4">
                    {preview ? (
                      <img src={preview} alt="New Logo Preview" className="max-w-full max-h-full object-contain" />
                    ) : currentLogo ? (
                      <img src={`${process.env.REACT_APP_API_URL || ''}${currentLogo}`} alt="Current Logo" className="max-w-full max-h-full object-contain" />
                    ) : (
                      <span className="text-muted text-sm">No logo set</span>
                    )}
                  </div>
                  
                  <div 
                    className="border-2 border-dashed border-slate-600 rounded-xl p-4 text-center cursor-pointer hover:bg-slate-800/50 transition-colors"
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <input type="file" ref={fileInputRef} className="hidden" accept="image/png, image/jpeg, image/svg+xml" onChange={handleFileChange} />
                    <ImageIcon size={24} className="mx-auto mb-2 text-slate-400" />
                    <p className="text-white text-sm font-medium mb-1">Upload New Logo</p>
                    <p className="text-xs text-muted">Max 5MB. PNG, JPG, SVG.</p>
                  </div>
              </div>

              <button 
                  onClick={saveSettings} 
                  disabled={isSaving}
                  className="w-full bg-primary hover:bg-indigo-600 text-white py-3 rounded-xl font-bold transition-all shadow-lg shadow-primary/30 flex justify-center items-center gap-2"
              >
                  <Save size={20} />
                  {isSaving ? 'Saving...' : 'Save All Settings'}
              </button>
          </div>
      </div>
    </div>
  );
};

const SystemSettingsTab = () => {
  const queryClient = useQueryClient();
  const { data: settings, isLoading } = useQuery({ 
    queryKey: ['globalSettings'], 
    queryFn: async () => (await api.get('/global-settings')).data 
  });

  const updateSettingMutation = useMutation({
    mutationFn: (data) => api.put(`/global-settings/${data.key}`, { value: data.value }),
    onSuccess: () => queryClient.invalidateQueries(['globalSettings'])
  });

  if (isLoading) return <div className="text-muted">Loading...</div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white mb-2">System Settings</h1>
        <p className="text-muted text-sm">Configure global application variables and configurations.</p>
      </div>

      <div className="glass-card p-6 max-w-2xl space-y-4">
        <div>
          <label className="block text-sm font-medium text-muted mb-1">Exchange Rate (USD to CFA)</label>
          <div className="flex gap-2">
            <input 
              type="number" 
              defaultValue={settings?.usd_to_cfa || ''}
              className="flex-1 bg-slate-800 border border-slate-700 rounded-lg px-4 py-2 text-white"
              id="usd_cfa_input"
            />
            <button 
              onClick={() => {
                const val = document.getElementById('usd_cfa_input').value;
                updateSettingMutation.mutate({ key: 'usd_to_cfa', value: val });
              }}
              className="bg-primary px-4 py-2 rounded-lg text-white"
            >
              Save
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

const WorkshopRatesTab = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState(null);
  const [editForm, setEditForm] = useState({ item_name: '', unit: '', default_price: '' });
  const [showAdd, setShowAdd] = useState(false);
  const [addForm, setAddForm] = useState({ category: 'Material', item_name: '', unit: '', default_price: '' });

  const { data: rates, isLoading } = useQuery({ 
    queryKey: ['settingsRates'], 
    queryFn: async () => (await api.get('/settings/rates')).data 
  });

  const updateRateMutation = useMutation({
    mutationFn: (vars) => api.put(`/settings/rates/${vars.id}`, vars.data),
    onSuccess: () => { queryClient.invalidateQueries(['settingsRates']); setEditingId(null); }
  });

  const addRateMutation = useMutation({
    mutationFn: (data) => api.post('/settings/rates', data),
    onSuccess: () => { queryClient.invalidateQueries(['settingsRates']); setShowAdd(false); setAddForm({ category: 'Material', item_name: '', unit: '', default_price: '' }); }
  });

  const deleteRateMutation = useMutation({
    mutationFn: (id) => api.delete(`/settings/rates/${id}`),
    onSuccess: () => queryClient.invalidateQueries(['settingsRates'])
  });

  const categories = ['Material', 'Labor', 'Equipment', 'Other'];

  if (isLoading) return <div className="text-muted">Loading...</div>;

  const groupedRates = rates?.reduce((acc, rate) => {
    acc[rate.category] = acc[rate.category] || [];
    acc[rate.category].push(rate);
    return acc;
  }, {});

  const startEditing = (rate) => {
    setEditingId(rate.id);
    setEditForm({ item_name: rate.item_name, unit: rate.unit, default_price: rate.default_price });
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-2xl font-bold text-white mb-2">Workshop Rates</h1>
          <p className="text-muted text-sm">Manage default pricing for materials, labor, and equipment.</p>
        </div>
        <button onClick={() => setShowAdd(!showAdd)} className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center transition-colors">
          <Plus size={18} className="me-2" /> Add Item
        </button>
      </div>

      {showAdd && (
        <div className="glass-card p-6 animate-in fade-in max-w-4xl">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
            <div>
              <label className="block text-sm text-muted mb-1">Category</label>
              <select value={addForm.category} onChange={e => setAddForm({...addForm, category: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white">
                {categories.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-sm text-muted mb-1">Item Name</label>
              <input type="text" value={addForm.item_name} onChange={e => setAddForm({...addForm, item_name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
            </div>
            <div>
              <label className="block text-sm text-muted mb-1">Unit</label>
              <input type="text" value={addForm.unit} onChange={e => setAddForm({...addForm, unit: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
            </div>
            <div>
              <label className="block text-sm text-muted mb-1">Default Price</label>
              <input type="number" value={addForm.default_price} onChange={e => setAddForm({...addForm, default_price: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white" />
            </div>
          </div>
          <div className="flex justify-end gap-3">
            <button onClick={() => setShowAdd(false)} className="px-4 py-2 bg-slate-700 text-white rounded-lg">Cancel</button>
            <button onClick={() => addRateMutation.mutate(addForm)} className="px-4 py-2 bg-success text-white rounded-lg">Save Item</button>
          </div>
        </div>
      )}

      <div className="space-y-6 max-w-4xl">
        {categories.map(category => {
          if (!groupedRates?.[category]) return null;
          return (
            <div key={category} className="glass-card overflow-hidden">
              <div className="bg-slate-800/50 p-4 border-b border-slate-700/50"><h3 className="font-bold text-white">{category} Rates</h3></div>
              <table className="w-full text-start">
                <thead className="border-b border-slate-700/50">
                  <tr>
                    <th className="px-6 py-3 text-xs text-muted text-start uppercase">Item</th>
                    <th className="px-6 py-3 text-xs text-muted text-start uppercase">Unit</th>
                    <th className="px-6 py-3 text-xs text-muted text-end uppercase">Price</th>
                    <th className="px-6 py-3 text-xs text-muted text-center uppercase">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-700/50">
                  {groupedRates[category].map(rate => (
                    <tr key={rate.id} className="hover:bg-slate-800/30">
                      {editingId === rate.id ? (
                        <>
                          <td className="p-2"><input type="text" className="w-full bg-slate-800 border-slate-600 rounded px-2 py-1 text-white text-sm" value={editForm.item_name} onChange={e => setEditForm({...editForm, item_name: e.target.value})} /></td>
                          <td className="p-2"><input type="text" className="w-full bg-slate-800 border-slate-600 rounded px-2 py-1 text-white text-sm" value={editForm.unit} onChange={e => setEditForm({...editForm, unit: e.target.value})} /></td>
                          <td className="p-2"><input type="number" className="w-full bg-slate-800 border-slate-600 rounded px-2 py-1 text-end text-white text-sm" value={editForm.default_price} onChange={e => setEditForm({...editForm, default_price: e.target.value})} /></td>
                          <td className="p-2 text-center">
                            <button onClick={() => updateRateMutation.mutate({ id: rate.id, data: editForm })} className="text-success p-1"><Save size={16}/></button>
                            <button onClick={() => setEditingId(null)} className="text-slate-400 p-1"><X size={16}/></button>
                          </td>
                        </>
                      ) : (
                        <>
                          <td className="px-6 py-3 text-sm text-slate-300">{rate.item_name}</td>
                          <td className="px-6 py-3 text-sm text-slate-400">{rate.unit}</td>
                          <td className="px-6 py-3 text-sm text-end text-white">${Number(rate.default_price).toLocaleString()}</td>
                          <td className="px-6 py-3 text-center">
                            <button onClick={() => startEditing(rate)} className="text-slate-400 hover:text-primary p-1"><Edit3 size={16}/></button>
                            <button onClick={() => { if(window.confirm('Delete?')) deleteRateMutation.mutate(rate.id); }} className="text-slate-400 hover:text-danger p-1"><Trash2 size={16}/></button>
                          </td>
                        </>
                      )}
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default Settings;
