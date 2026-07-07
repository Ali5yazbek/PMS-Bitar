import React, { useState } from 'react';
import axios from 'axios';
import { Camera, FileText, MapPin, Send, AlertCircle, Building, CheckCircle2 } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';

const AgentDailyReport = () => {
  const { t } = useTranslation();
  const [formData, setFormData] = useState({
    building_id: '',
    apartments_visited: '',
    tasks_completed: '',
    issues_found: '',
    notes: '',
    start_time: '',
    end_time: ''
  });
  const [photos, setPhotos] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);

  const { data: buildings } = useQuery({
    queryKey: ['agent_buildings'],
    queryFn: async () => {
      const res = await axios.get('/buildings');
      return res.data;
    }
  });

  const handlePhotoChange = (e) => {
    if (e.target.files) {
      setPhotos(Array.from(e.target.files));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const userStr = localStorage.getItem('user');
      if (!userStr) throw new Error('Not logged in');
      const user = JSON.parse(userStr);

      const fd = new FormData();
      fd.append('agent_id', user.id);
      fd.append('building_id', formData.building_id);
      fd.append('apartments_visited', formData.apartments_visited);
      fd.append('tasks_completed', formData.tasks_completed);
      fd.append('issues_found', formData.issues_found);
      fd.append('notes', formData.notes);
      fd.append('start_time', formData.start_time);
      fd.append('end_time', formData.end_time);

      photos.forEach(photo => {
        fd.append('photos[]', photo);
      });

      await axios.post('/daily-reports', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });

      setSuccess(true);
      setFormData({
        building_id: '',
        apartments_visited: '',
        tasks_completed: '',
        issues_found: '',
        notes: '',
        start_time: '',
        end_time: ''
      });
      setPhotos([]);
      
      setTimeout(() => setSuccess(false), 5000);
    } catch (err) {
      setError(err.response?.data?.error || err.message || 'Failed to submit report');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="p-4 md:p-8 max-w-3xl mx-auto mb-20 animate-in fade-in zoom-in-95 duration-300">
      <div className="flex items-center gap-4 mb-8">
        <div className="bg-indigo-500/20 p-4 rounded-full text-indigo-400">
          <FileText size={32} />
        </div>
        <div>
          <h1 className="text-3xl font-bold text-white">Daily Report</h1>
          <p className="text-slate-400">Submit your daily activities and photo evidence</p>
        </div>
      </div>

      {success && (
        <div className="bg-success/20 border border-success/30 text-success p-4 rounded-xl mb-6 flex items-center gap-3">
          <CheckCircle2 size={24} />
          <p className="font-medium">Daily report submitted successfully!</p>
        </div>
      )}

      {error && (
        <div className="bg-danger/20 border border-danger/30 text-danger p-4 rounded-xl mb-6 flex items-center gap-3">
          <AlertCircle size={24} />
          <p className="font-medium">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div className="glass-card p-6 border border-slate-700/50">
          <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2 border-b border-slate-700/50 pb-4">
            <Building className="text-indigo-400" /> Location Details
          </h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Building *</label>
              <select 
                required
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all outline-none"
                value={formData.building_id}
                onChange={e => setFormData({...formData, building_id: e.target.value})}
              >
                <option value="">Select a building</option>
                {buildings?.map(b => (
                  <option key={b.id} value={b.id}>{b.name}</option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Apartments Visited</label>
              <input 
                type="text" 
                placeholder="e.g. 101, 102, 205"
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none"
                value={formData.apartments_visited}
                onChange={e => setFormData({...formData, apartments_visited: e.target.value})}
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Start Time</label>
              <input 
                type="time" 
                required
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none"
                value={formData.start_time}
                onChange={e => setFormData({...formData, start_time: e.target.value})}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">End Time</label>
              <input 
                type="time" 
                required
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none"
                value={formData.end_time}
                onChange={e => setFormData({...formData, end_time: e.target.value})}
              />
            </div>
          </div>
        </div>

        <div className="glass-card p-6 border border-slate-700/50">
          <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2 border-b border-slate-700/50 pb-4">
            <FileText className="text-indigo-400" /> Work Summary
          </h2>

          <div className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Number of Tasks Completed *</label>
              <input 
                type="number" 
                min="0"
                required
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none"
                value={formData.tasks_completed}
                onChange={e => setFormData({...formData, tasks_completed: e.target.value})}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Issues Found</label>
              <textarea 
                rows="3"
                placeholder="Describe any maintenance issues, damages, or anomalies found..."
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none resize-none"
                value={formData.issues_found}
                onChange={e => setFormData({...formData, issues_found: e.target.value})}
              ></textarea>
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-400 mb-2">Additional Notes</label>
              <textarea 
                rows="2"
                placeholder="Any other observations..."
                className="w-full bg-slate-800 border border-slate-600 rounded-xl px-4 py-3 text-white focus:border-indigo-500 outline-none resize-none"
                value={formData.notes}
                onChange={e => setFormData({...formData, notes: e.target.value})}
              ></textarea>
            </div>
          </div>
        </div>

        <div className="glass-card p-6 border border-slate-700/50">
          <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2 border-b border-slate-700/50 pb-4">
            <Camera className="text-indigo-400" /> Photo Evidence
          </h2>
          
          <div className="border-2 border-dashed border-slate-600 bg-slate-800/50 rounded-2xl p-8 text-center hover:bg-slate-800 transition-colors cursor-pointer relative">
            <input 
              type="file" 
              multiple 
              accept="image/*,.pdf"
              className="absolute inset-0 w-full h-full opacity-0 cursor-pointer"
              onChange={handlePhotoChange}
            />
            <Camera className="mx-auto text-slate-400 mb-3" size={48} />
            <p className="text-white font-medium text-lg mb-1">Tap to Upload Photos</p>
            <p className="text-slate-400 text-sm">JPG, PNG or PDF</p>
            {photos.length > 0 && (
              <div className="mt-4 inline-block bg-indigo-500/20 text-indigo-300 px-4 py-2 rounded-full font-medium text-sm">
                {photos.length} file(s) selected
              </div>
            )}
          </div>
        </div>

        <button 
          type="submit" 
          disabled={isSubmitting || !formData.building_id || !formData.tasks_completed}
          className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-4 rounded-xl flex items-center justify-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed shadow-lg shadow-indigo-500/30 text-lg"
        >
          {isSubmitting ? (
            'Submitting...'
          ) : (
            <>
              <Send size={20} /> Submit Daily Report
            </>
          )}
        </button>
      </form>
    </div>
  );
};

export default AgentDailyReport;
