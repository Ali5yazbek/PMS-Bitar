import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Zap, Camera, Check, FileText, AlertCircle } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const AgentGenerators = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [selectedBuilding, setSelectedBuilding] = useState(null);
  const [meterPhoto, setMeterPhoto] = useState(null);
  const [fuelPhoto, setFuelPhoto] = useState(null);

  const [formData, setFormData] = useState({
    generator_counter: '',
    running_hours: '',
    current_kwh: '',
    fuel_added: '',
    remaining_fuel: '',
    spare_fuel: '',
    notes: ''
  });

  const { data: buildings = [], isLoading } = useQuery({
    queryKey: ['buildings_with_generators'],
    queryFn: async () => {
      const res = await axios.get('/energy/generators');
      return res.data.map(g => ({
        id: g.building_id,
        name: g.building_name,
        generator_name: g.name,
        generator_id: g.id,
      }));
    },
  });

  const { data: history = [] } = useQuery({
    queryKey: ['agent_generator_history'],
    queryFn: async () => {
      const res = await axios.get('/energy/agent/history/generators');
      return res.data;
    }
  });

  const latestReading = selectedBuilding 
    ? history.find(h => h.generator_id === selectedBuilding.generator_id)
    : null;

  const today = new Date();
  const localDateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  
  const hasReadingToday = latestReading && latestReading.date && latestReading.date.startsWith(localDateStr);
  const isLocked = hasReadingToday && latestReading.status !== 'Rejected';

  const submitReadingMutation = useMutation({
    mutationFn: async (data) => {
      // Create FormData to handle file uploads
      const fd = new FormData();
      Object.keys(data).forEach(key => fd.append(key, data[key]));
      if (meterPhoto) fd.append('meter_photo', meterPhoto);
      if (fuelPhoto) fd.append('fuel_photo', fuelPhoto);
      fd.append('building_id', selectedBuilding.id);

      // We send this to a generic endpoint or the existing one
      return axios.post('/energy/agent/generator-reading', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
    },
    onSuccess: () => {
      alert('Reading submitted successfully for Admin review!');
      setFormData({
        generator_counter: '',
        running_hours: '',
        fuel_added: '',
        remaining_fuel: '',
        spare_fuel: '',
        notes: ''
      });
      setMeterPhoto(null);
      setFuelPhoto(null);
      setSelectedBuilding(null);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to submit reading. The API endpoint might need to be implemented.');
    }
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!meterPhoto && !fuelPhoto) {
      alert('Please provide at least one photo (Meter or Fuel Gauge) as proof.');
      return;
    }
    submitReadingMutation.mutate(formData);
  };

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
          <Zap className="me-3 text-warning" /> Submit Generator Reading
        </h1>
        <p className="text-muted">Select a building and enter the daily generator metrics with proof.</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-8 flex-1 min-h-0">
        
        {/* Buildings List */}
        <div className="w-full lg:w-1/3 flex flex-col glass-card overflow-hidden">
          <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
            <h2 className="font-bold text-white uppercase text-sm tracking-wider">Assigned Buildings</h2>
          </div>
          <div className="flex-1 overflow-y-auto p-2 space-y-1">
            {isLoading ? (
              <div className="p-4 text-center text-slate-500">Loading...</div>
            ) : buildings.map(b => (
              <button
                key={b.id}
                onClick={() => setSelectedBuilding(b)}
                className={`w-full text-left p-4 rounded-xl transition-all flex justify-between items-center ${
                  selectedBuilding?.id === b.id 
                    ? 'bg-primary text-white shadow-lg shadow-primary/20' 
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`}
              >
                <span className="font-medium">{b.name} ({b.generator_name})</span>
                <Zap size={16} className={selectedBuilding?.id === b.id ? 'text-white' : 'text-slate-500'} />
              </button>
            ))}
          </div>
        </div>

        {/* Reading Form */}
        <div className="w-full lg:w-2/3 flex flex-col">
          {!selectedBuilding ? (
            <div className="h-full glass-card flex flex-col items-center justify-center text-slate-500">
              <Zap size={48} className="mb-4 text-slate-600 opacity-50" />
              <p>Select a building from the list to enter its generator reading.</p>
            </div>
          ) : (
            <div className="glass-card flex-1 flex flex-col p-8">
              <div className="flex justify-between items-center mb-6">
                <h2 className="text-2xl font-bold text-white">{selectedBuilding.name} - Generator</h2>
                <span className="bg-warning/20 text-warning px-3 py-1 rounded-full text-xs font-bold border border-warning/30">
                  Daily Reading Due
                </span>
              </div>

              {latestReading?.status === 'Rejected' && (
                <div className="mb-6 bg-danger/10 border border-danger text-danger p-4 rounded-xl flex items-start gap-3">
                  <AlertCircle className="shrink-0 mt-0.5" />
                  <div>
                    <h4 className="font-bold">Previous Reading Rejected</h4>
                    <p className="text-sm opacity-90 mt-1">
                      <strong>Admin Note:</strong> {latestReading.admin_notes || 'No specific reason provided.'}
                    </p>
                    <p className="text-sm opacity-90 mt-2">Please submit a corrected reading below.</p>
                  </div>
                </div>
              )}

              {isLocked ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-800/30 rounded-xl border border-slate-700/50">
                  <div className="w-20 h-20 bg-primary/20 text-primary rounded-full flex items-center justify-center mb-6">
                    <Check size={40} />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">Reading Submitted Successfully</h3>
                  <p className="text-slate-400 mb-6 max-w-md">
                    Your reading for today has been recorded and is currently waiting for administrator approval.
                  </p>
                  
                  <div className="bg-slate-900/50 p-6 rounded-xl border border-slate-700 inline-block text-left min-w-[300px]">
                    <div className="flex justify-between items-center mb-3">
                      <span className="text-slate-500">Status:</span>
                      <span className={`px-3 py-1 rounded-full text-xs font-bold ${
                        latestReading.status === 'Verified' ? 'bg-success/20 text-success border border-success/30' : 
                        'bg-warning/20 text-warning border border-warning/30'
                      }`}>
                        {latestReading.status === 'Pending Verification' ? 'Pending Approval' : latestReading.status}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-slate-500">Submitted At:</span>
                      <span className="text-white font-medium">
                        {new Date(latestReading.submitted_at || latestReading.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                      </span>
                    </div>
                  </div>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="flex-1 flex flex-col">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Generator Counter</label>
                    <input
                      type="number"
                      value={formData.generator_counter}
                      onChange={e => setFormData({...formData, generator_counter: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 15420 (If applicable)"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Running Hours</label>
                    <input
                      type="number"
                      value={formData.running_hours}
                      onChange={e => setFormData({...formData, running_hours: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 24 (If applicable)"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Current Meter Reading (kWh)</label>
                    <input
                      type="number"
                      value={formData.current_kwh}
                      onChange={e => setFormData({...formData, current_kwh: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 5040 (If applicable)"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Fuel Added (Liters)</label>
                    <input
                      type="number"
                      value={formData.fuel_added}
                      onChange={e => setFormData({...formData, fuel_added: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Remaining Fuel (Liters)</label>
                    <input
                      type="number"
                      required
                      value={formData.remaining_fuel}
                      onChange={e => setFormData({...formData, remaining_fuel: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 1200"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">Spare Fuel (Liters)</label>
                    <input
                      type="number"
                      value={formData.spare_fuel}
                      onChange={e => setFormData({...formData, spare_fuel: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder="e.g. 200"
                    />
                  </div>
                </div>

                <div className="border-t border-slate-700/50 pt-6">
                  <h3 className="text-lg font-bold text-white mb-4">Photographic Proof</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {/* Meter Photo */}
                    <div className="bg-slate-900/50 border border-slate-700 rounded-xl p-4 flex flex-col items-center justify-center text-center">
                      <div className="w-12 h-12 bg-danger/10 text-danger rounded-full flex items-center justify-center mb-3">
                        <Camera size={20} />
                      </div>
                      <h4 className="text-white font-medium mb-1">Meter Photo</h4>
                      <p className="text-xs text-slate-400 mb-4">Required if the generator has a meter</p>
                      
                      <input 
                        type="file" 
                        accept="image/*" 
                        capture="environment"
                        className="hidden" 
                        id="meter-photo-upload"
                        onChange={(e) => setMeterPhoto(e.target.files[0])}
                      />
                      <label 
                        htmlFor="meter-photo-upload" 
                        className="btn-primary px-4 py-2 rounded-lg text-sm cursor-pointer w-full"
                      >
                        {meterPhoto ? 'Change Photo' : 'Take Photo'}
                      </label>
                      {meterPhoto && <span className="mt-2 text-xs text-success flex items-center"><Check size={12} className="me-1" /> {meterPhoto.name}</span>}
                    </div>

                    {/* Fuel Photo */}
                    <div className="bg-slate-900/50 border border-slate-700 rounded-xl p-4 flex flex-col items-center justify-center text-center">
                      <div className="w-12 h-12 bg-info/10 text-info rounded-full flex items-center justify-center mb-3">
                        <Camera size={20} />
                      </div>
                      <h4 className="text-white font-medium mb-1">Fuel Gauge Photo</h4>
                      <p className="text-xs text-slate-400 mb-4">Recommended proof of fuel level</p>
                      
                      <input 
                        type="file" 
                        accept="image/*" 
                        capture="environment"
                        className="hidden" 
                        id="fuel-photo-upload"
                        onChange={(e) => setFuelPhoto(e.target.files[0])}
                      />
                      <label 
                        htmlFor="fuel-photo-upload" 
                        className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg text-sm cursor-pointer w-full transition-colors"
                      >
                        {fuelPhoto ? 'Change Photo' : 'Take Photo'}
                      </label>
                      {fuelPhoto && <span className="mt-2 text-xs text-success flex items-center"><Check size={12} className="me-1" /> {fuelPhoto.name}</span>}
                    </div>
                  </div>
                </div>

                <div className="border-t border-slate-700/50 pt-6">
                  <label className="block text-sm font-medium text-muted mb-1">Notes / Irregularities</label>
                  <textarea
                    rows="3"
                    value={formData.notes}
                    onChange={e => setFormData({...formData, notes: e.target.value})}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors resize-none"
                    placeholder="Any issues or observations..."
                  ></textarea>
                </div>

                <div className="flex justify-end pt-4">
                  <button 
                    type="submit" 
                    className="btn-primary px-8 py-3 rounded-xl flex items-center text-lg shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all"
                    disabled={submitReadingMutation.isLoading}
                  >
                    {submitReadingMutation.isLoading ? 'Submitting...' : 'Submit Reading'}
                  </button>
                </div>
              </form>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AgentGenerators;
