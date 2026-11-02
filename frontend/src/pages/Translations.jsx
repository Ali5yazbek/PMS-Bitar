import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Languages, Search, Save, Trash2, Plus, Edit2 } from 'lucide-react';
import api from '../api/axios';

const Translations = () => {
  const { t } = useTranslation();
  const [translations, setTranslations] = useState({ en: {}, fr: {}, ar: {} });
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  // For adding/editing
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingKey, setEditingKey] = useState('');
  const [formValues, setFormValues] = useState({ en: '', fr: '', ar: '' });

  useEffect(() => {
    fetchTranslations();
  }, []);

  const fetchTranslations = async () => {
    try {
      setLoading(true);
      const res = await api.get('/translations');
      setTranslations({
        en: res.data.en || {},
        fr: res.data.fr || {},
        ar: res.data.ar || {}
      });
    } catch (error) {
      console.error('Failed to load translations', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e) => {
    e.preventDefault();
    if (!editingKey) return;
    
    try {
      setSaving(true);
      await api.post('/translations', {
        translation_key: editingKey,
        en: formValues.en,
        fr: formValues.fr,
        ar: formValues.ar
      });
      setIsModalOpen(false);
      fetchTranslations();
      // Reload page to apply changes dynamically in i18n (or we could fetch again via i18n.js)
      window.location.reload();
    } catch (error) {
      console.error('Failed to save translation', error);
      alert('Error saving translation');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (key) => {
    if (!window.confirm(`Delete translation key '${key}'?`)) return;
    try {
      await api.delete('/translations', { data: { translation_key: key } });
      fetchTranslations();
    } catch (error) {
      console.error('Failed to delete', error);
    }
  };

  const openEdit = (key) => {
    setEditingKey(key);
    setFormValues({
      en: translations.en[key] || '',
      fr: translations.fr[key] || '',
      ar: translations.ar[key] || ''
    });
    setIsModalOpen(true);
  };

  const openNew = () => {
    setEditingKey('');
    setFormValues({ en: '', fr: '', ar: '' });
    setIsModalOpen(true);
  };

  // Get all unique keys
  const allKeys = Array.from(new Set([
    ...Object.keys(translations.en),
    ...Object.keys(translations.fr),
    ...Object.keys(translations.ar)
  ]));

  const filteredKeys = allKeys.filter(key => 
    key.toLowerCase().includes(search.toLowerCase()) ||
    (translations.en[key] || '').toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-6">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 flex items-center gap-2">
            <Languages className="text-indigo-600" />
            i18n Translation Manager
          </h1>
          <p className="text-sm text-slate-500">Manage application text overrides across multiple languages.</p>
        </div>
        <button 
          onClick={openNew}
          className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg flex items-center gap-2 shadow-sm transition-colors"
        >
          <Plus size={18} /> Add Translation
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex justify-between items-center bg-slate-50">
          <div className="relative w-full max-w-md">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
            <input 
              type="text" 
              placeholder="Search translation keys or english text..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 outline-none text-sm"
            />
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-sm text-left">
            <thead className="bg-slate-50 text-slate-500 border-b border-slate-200 font-medium">
              <tr>
                <th className="px-4 py-3">Translation Key</th>
                <th className="px-4 py-3">English (en)</th>
                <th className="px-4 py-3">Français (fr)</th>
                <th className="px-4 py-3">العربية (ar)</th>
                <th className="px-4 py-3 w-24">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan="5" className="text-center py-8 text-slate-500">Loading translations...</td>
                </tr>
              ) : filteredKeys.length === 0 ? (
                <tr>
                  <td colSpan="5" className="text-center py-8 text-slate-500">No custom translations found.</td>
                </tr>
              ) : (
                filteredKeys.map(key => (
                  <tr key={key} className="hover:bg-slate-50">
                    <td className="px-4 py-3 font-mono text-xs text-indigo-600">{key}</td>
                    <td className="px-4 py-3 text-slate-700">{translations.en[key] || '-'}</td>
                    <td className="px-4 py-3 text-slate-700">{translations.fr[key] || '-'}</td>
                    <td className="px-4 py-3 text-slate-700" dir="rtl">{translations.ar[key] || '-'}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-2">
                        <button onClick={() => openEdit(key)} className="p-1 text-slate-400 hover:text-indigo-600"><Edit2 size={16} /></button>
                        <button onClick={() => handleDelete(key)} className="p-1 text-slate-400 hover:text-red-600"><Trash2 size={16} /></button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {isModalOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg overflow-hidden">
            <div className="p-4 border-b border-slate-200 font-bold text-slate-800">
              {editingKey ? 'Edit Translation' : 'Add New Translation'}
            </div>
            <form onSubmit={handleSave} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Translation Key</label>
                <input 
                  type="text" 
                  value={editingKey}
                  onChange={(e) => setEditingKey(e.target.value)}
                  disabled={Object.keys(translations.en).includes(editingKey) && editingKey !== ''}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 disabled:bg-slate-100 disabled:text-slate-500 font-mono text-sm"
                  placeholder="e.g. sidebar.dashboard"
                  required
                />
                <p className="text-xs text-slate-500 mt-1">Key path to override in i18n (e.g., `common.welcome`)</p>
              </div>
              
              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">English (en)</label>
                <textarea 
                  value={formValues.en}
                  onChange={(e) => setFormValues({...formValues, en: e.target.value})}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm h-20"
                ></textarea>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">Français (fr)</label>
                <textarea 
                  value={formValues.fr}
                  onChange={(e) => setFormValues({...formValues, fr: e.target.value})}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm h-20"
                ></textarea>
              </div>

              <div>
                <label className="block text-sm font-medium text-slate-700 mb-1">العربية (ar)</label>
                <textarea 
                  dir="rtl"
                  value={formValues.ar}
                  onChange={(e) => setFormValues({...formValues, ar: e.target.value})}
                  className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500 text-sm h-20"
                ></textarea>
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button type="button" onClick={() => setIsModalOpen(false)} className="px-4 py-2 text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
                <button type="submit" disabled={saving} className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg flex items-center gap-2">
                  <Save size={16} /> {saving ? 'Saving...' : 'Save'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Translations;
