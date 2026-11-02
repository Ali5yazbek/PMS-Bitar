import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Zap, Camera, Check, FileText, AlertCircle, Clock, Droplets, Activity, History } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useLocation } from 'react-router-dom';

const StatusBadge = ({ status }) => {
  const map = {
    'Verified':            'bg-emerald-500/20 text-emerald-400 border-emerald-500/30',
    'Pending Verification':'bg-amber-500/20  text-amber-400  border-amber-500/30',
    'Rejected':            'bg-red-500/20    text-red-400    border-red-500/30',
    'Flagged':             'bg-orange-500/20 text-orange-400 border-orange-500/30',
  };
  const label = status === 'Pending Verification' ? 'Pending' : status;
  return (
    <span className={`px-2 py-0.5 rounded-full text-xs font-bold border ${map[status] || 'bg-slate-700 text-slate-400 border-slate-600'}`}>
      {label}
    </span>
  );
};

const AgentGenerators = () => {
  const { t } = useTranslation();
  const location = useLocation();
  const preselectGeneratorId = location.state?.preselectGeneratorId;
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

  useEffect(() => {
    if (buildings && buildings.length > 0 && !selectedBuilding) {
      if (preselectGeneratorId) {
        const found = buildings.find(b => String(b.generator_id) === String(preselectGeneratorId));
        setSelectedBuilding(found || buildings[0]);
      } else {
        setSelectedBuilding(buildings[0]);
      }
    }
  }, [buildings, selectedBuilding, preselectGeneratorId]);

  const { data: history = [] } = useQuery({
    queryKey: ['agent_generator_history'],
    queryFn: async () => {
      const res = await axios.get('/energy/agent/history/generators');
      return res.data;
    }
  });

  const generatorHistory = selectedBuilding
    ? history
        .filter(h => h.generator_id === selectedBuilding.generator_id)
        .sort((a, b) => new Date(b.date) - new Date(a.date))
    : [];

  const latestReading = generatorHistory[0] || null;

  const today = new Date();
  const localDateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, '0')}-${String(today.getDate()).padStart(2, '0')}`;
  
  const hasReadingToday = latestReading && latestReading.date && latestReading.date.startsWith(localDateStr);
  const isBefore7AM = false; 
  
  const prevReading = generatorHistory.find(h => !h.date.startsWith(localDateStr)) || null;

  const prevCounter = parseFloat(prevReading?.current_meter_hours ?? prevReading?.generator_counter ?? 0);
  const currCounter = parseFloat(formData.generator_counter) || 0;
  const liveHoursWorked = currCounter > 0 && prevCounter > 0
    ? Math.max(0, currCounter - prevCounter).toFixed(2)
    : null;
  
  const isLocked = hasReadingToday && latestReading.status !== 'Rejected';

  const displayReading = generatorHistory[0] || null;
  const hasDisplayCounter = displayReading && (displayReading.current_meter_hours != null || displayReading.generator_counter != null);
  const displayCounter = hasDisplayCounter ? parseFloat(displayReading.current_meter_hours ?? displayReading.generator_counter) : 0;

  const submitReadingMutation = useMutation({
    mutationFn: async (data) => {
      const fd = new FormData();
      Object.keys(data).forEach(key => fd.append(key, data[key]));
      if (meterPhoto) fd.append('meter_photo', meterPhoto);
      if (fuelPhoto) fd.append('fuel_photo', fuelPhoto);
      fd.append('building_id', selectedBuilding.id);

      return axios.post('/energy/agent/generator-reading', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
    },
    onSuccess: () => {
      alert('Reading submitted successfully for Admin review!');
      setFormData({
        generator_counter: '',
        running_hours: '',
        current_kwh: '',
        fuel_added: '',
        remaining_fuel: '',
        spare_fuel: '',
        notes: ''
      });
      setMeterPhoto(null);
      setFuelPhoto(null);
      queryClient.invalidateQueries(['agent_generator_history']);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to submit reading.');
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
        
        <div className="w-full lg:w-1/3 flex flex-col gap-4">
          <div className="glass-card overflow-hidden">
            <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
              <h2 className="font-bold text-white uppercase text-sm tracking-wider">Assigned Buildings</h2>
            </div>
            <div className="p-2 space-y-1">
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

          {selectedBuilding && generatorHistory.length > 0 && (
            <div className="glass-card overflow-hidden">
              <div className="p-4 border-b border-slate-700/50 bg-slate-800/30 flex items-center gap-2">
                <History size={14} className="text-primary" />
                <h2 className="font-bold text-white uppercase text-sm tracking-wider">Recent Submissions</h2>
              </div>
              <div className="p-3 space-y-2 max-h-72 overflow-y-auto custom-scrollbar">
                {generatorHistory.slice(0, 7).map((h, i) => (
                  <div
                    key={h.id || i}
                    className={`rounded-xl p-3 border ${
                      i === 0 && hasReadingToday
                        ? 'bg-primary/5 border-primary/30'
                        : 'bg-slate-900/40 border-slate-700/50'
                    }`}
                  >
                    <div className="flex justify-between items-center mb-2">
                      <span className="text-xs font-bold text-slate-300">{h.date}</span>
                      <StatusBadge status={h.status} />
                    </div>
                    <div className="grid grid-cols-2 gap-x-4 gap-y-1">
                      {(h.current_meter_hours || h.generator_counter) && (
                        <div className="flex items-center gap-1 text-xs">
                          <Clock size={10} className="text-primary shrink-0" />
                          <span className="text-slate-400">Meter:</span>
                          <span className="text-white font-mono font-bold ml-1">{h.current_meter_hours || h.generator_counter}</span>
                        </div>
                      )}
                      {h.running_hours != null && (
                        <div className="flex items-center gap-1 text-xs">
                          <Activity size={10} className="text-amber-400 shrink-0" />
                          <span className="text-slate-400">Worked:</span>
                          <span className="text-amber-400 font-bold ml-1">{parseFloat(h.running_hours).toFixed(1)}h</span>
                        </div>
                      )}
                      {h.fuel_remaining != null && (
                        <div className="flex items-center gap-1 text-xs">
                          <Droplets size={10} className="text-cyan-400 shrink-0" />
                          <span className="text-slate-400">Fuel:</span>
                          <span className="text-cyan-400 font-bold ml-1">{parseFloat(h.fuel_remaining).toFixed(0)}L</span>
                        </div>
                      )}
                      {parseFloat(h.fuel_added) > 0 && (
                        <div className="flex items-center gap-1 text-xs">
                          <span className="text-slate-400">+Added:</span>
                          <span className="text-green-400 font-bold ml-1">{parseFloat(h.fuel_added).toFixed(0)}L</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

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
                {!isLocked && (
                  <span className="bg-warning/20 text-warning px-3 py-1 rounded-full text-xs font-bold border border-warning/30">
                    Daily Reading Due
                  </span>
                )}
              </div>

              {prevReading && !isLocked && (
                <div className="mb-6 rounded-2xl border border-slate-700/60 bg-slate-900/40 p-4">
                  <p className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <FileText size={12} className="text-primary" />
                    Last Submitted Reading — {prevReading.date}
                  </p>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    <div className="bg-slate-800/60 rounded-xl p-3 text-center">
                      <p className="text-xs text-slate-400 mb-1 flex items-center justify-center gap-1">
                        <Clock size={10} /> Meter Counter
                      </p>
                      <p className="text-white font-mono text-lg font-bold">
                        {prevReading.current_meter_hours || prevReading.generator_counter || '—'}
                      </p>
                    </div>
                    <div className="bg-slate-800/60 rounded-xl p-3 text-center">
                      <p className="text-xs text-slate-400 mb-1 flex items-center justify-center gap-1">
                        <Activity size={10} /> Hours Worked
                      </p>
                      <p className="text-amber-400 font-mono text-lg font-bold">
                        {prevReading.running_hours != null
                          ? parseFloat(prevReading.running_hours).toFixed(1) + 'h'
                          : '—'}
                      </p>
                    </div>
                    <div className="bg-slate-800/60 rounded-xl p-3 text-center">
                      <p className="text-xs text-slate-400 mb-1 flex items-center justify-center gap-1">
                        <Droplets size={10} /> Fuel Remaining
                      </p>
                      <p className="text-cyan-400 font-mono text-lg font-bold">
                        {prevReading.fuel_remaining != null
                          ? parseFloat(prevReading.fuel_remaining).toFixed(0) + 'L'
                          : '—'}
                      </p>
                    </div>
                    <div className="bg-slate-800/60 rounded-xl p-3 text-center">
                      <p className="text-xs text-slate-400 mb-1">Status</p>
                      <div className="flex justify-center mt-1">
                        <StatusBadge status={prevReading.status} />
                      </div>
                    </div>
                  </div>

                  {liveHoursWorked !== null && (
                    <div className="mt-3 flex items-center gap-2 bg-primary/10 border border-primary/30 rounded-xl px-4 py-2">
                      <Activity size={14} className="text-primary shrink-0" />
                      <span className="text-sm text-slate-300">Estimated hours today:</span>
                      <span className="text-primary font-mono font-bold text-lg">{liveHoursWorked}h</span>
                      <span className="text-xs text-slate-500 ml-1">({prevCounter} → {currCounter})</span>
                    </div>
                  )}
                </div>
              )}

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

              {isBefore7AM && !hasReadingToday ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-800/30 rounded-xl border border-slate-700/50">
                  <div className="w-20 h-20 bg-warning/20 text-warning rounded-full flex items-center justify-center mb-6">
                    <AlertCircle size={40} />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">Task Locked</h3>
                  <p className="text-slate-400 mb-6 max-w-md">
                    Daily generator tasks are only available to submit after 7:00 AM.
                  </p>
                </div>
              ) : isLocked ? (
                <div className="flex-1 flex flex-col items-center justify-center text-center p-8 bg-slate-800/30 rounded-xl border border-slate-700/50">
                  <div className="w-20 h-20 bg-primary/20 text-primary rounded-full flex items-center justify-center mb-6">
                    <Check size={40} />
                  </div>
                  <h3 className="text-2xl font-bold text-white mb-2">Reading Submitted Successfully</h3>
                  <p className="text-slate-400 mb-6 max-w-md">
                    Your reading for today has been recorded and is currently waiting for administrator approval.
                  </p>
                  
                  <div className="bg-slate-900/50 p-6 rounded-2xl border border-slate-700 w-full max-w-md text-left space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="text-slate-500">Status:</span>
                      <StatusBadge status={latestReading.status} />
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-slate-500">Submitted At:</span>
                      <span className="text-white font-medium">
                        {new Date(latestReading.submitted_at || latestReading.created_at).toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}
                      </span>
                    </div>
                    {(latestReading.current_meter_hours || latestReading.generator_counter) && (
                      <div className="flex justify-between items-center">
                        <span className="text-slate-500">Meter Counter:</span>
                        <span className="text-white font-mono font-bold">{latestReading.current_meter_hours || latestReading.generator_counter}</span>
                      </div>
                    )}
                    {latestReading.running_hours != null && (
                      <div className="flex justify-between items-center">
                        <span className="text-slate-500">Hours Worked:</span>
                        <span className="text-amber-400 font-bold">{parseFloat(latestReading.running_hours).toFixed(1)}h</span>
                      </div>
                    )}
                    {latestReading.fuel_remaining != null && (
                      <div className="flex justify-between items-center">
                        <span className="text-slate-500">Fuel Remaining:</span>
                        <span className="text-cyan-400 font-bold">{parseFloat(latestReading.fuel_remaining).toFixed(0)} L</span>
                      </div>
                    )}
                    {prevReading && latestReading.fuel_remaining != null && prevReading.fuel_remaining != null && (
                      <div className="pt-3 border-t border-slate-700 flex justify-between items-center">
                        <span className="text-slate-500 text-xs">vs Previous ({prevReading.date}):</span>
                        <span className="text-slate-300 text-xs font-mono">
                          {(parseFloat(latestReading.fuel_remaining) - parseFloat(prevReading.fuel_remaining)).toFixed(0)}L fuel change
                        </span>
                      </div>
                    )}
                  </div>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="flex-1 flex flex-col">
                  {hasReadingToday && latestReading?.status === 'Rejected' && (
                    <div className="mb-6 bg-danger/10 border border-danger/50 p-4 rounded-xl flex items-start gap-3 text-danger">
                      <AlertCircle className="shrink-0 mt-0.5" size={20} />
                      <div>
                        <p className="font-bold mb-1">Previous Submission Rejected</p>
                        <p className="text-sm text-danger/80">{latestReading.admin_notes || 'Please correct the submission and try again.'}</p>
                      </div>
                    </div>
                  )}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">
                      Generator Counter
                      {hasDisplayCounter && <span className="text-slate-500 text-xs ml-2">(Last: {displayCounter})</span>}
                    </label>
                    <input
                      type="number"
                      value={formData.generator_counter}
                      onChange={e => setFormData({...formData, generator_counter: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder={hasDisplayCounter ? `Previous: ${displayCounter}` : 'e.g. 15420 (If applicable)'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">
                      Running Hours
                      {displayReading?.running_hours != null && (
                        <span className="text-slate-500 text-xs ml-2">(Last: {parseFloat(displayReading.running_hours).toFixed(1)}h)</span>
                      )}
                    </label>
                    <input
                      type="number"
                      value={formData.running_hours}
                      onChange={e => setFormData({...formData, running_hours: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder={displayReading?.running_hours != null ? `Previous: ${parseFloat(displayReading.running_hours).toFixed(1)}h` : 'e.g. 24 (If applicable)'}
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">
                      Fuel Added (Liters)
                      {parseFloat(displayReading?.fuel_added) >= 0 && (
                        <span className="text-slate-500 text-xs ml-2">(Last: {parseFloat(displayReading.fuel_added).toFixed(0)}L)</span>
                      )}
                    </label>
                    <input
                      type="number"
                      value={formData.fuel_added}
                      onChange={e => setFormData({...formData, fuel_added: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder={parseFloat(displayReading?.fuel_added) >= 0 ? `Previous: ${parseFloat(displayReading.fuel_added).toFixed(0)}L` : 'e.g. 500'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">
                      Remaining Fuel (Liters)
                      {displayReading?.fuel_remaining != null && (
                        <span className="text-slate-500 text-xs ml-2">(Last: {parseFloat(displayReading.fuel_remaining).toFixed(0)}L)</span>
                      )}
                    </label>
                    <input
                      type="number"
                      required
                      value={formData.remaining_fuel}
                      onChange={e => setFormData({...formData, remaining_fuel: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder={displayReading?.fuel_remaining != null ? `Previous: ${parseFloat(displayReading.fuel_remaining).toFixed(0)}L` : 'e.g. 1200'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-muted mb-1">
                      Spare Fuel (Liters)
                      {displayReading?.spare_fuel != null && (
                        <span className="text-slate-500 text-xs ml-2">(Last: {parseFloat(displayReading.spare_fuel).toFixed(0)}L)</span>
                      )}
                    </label>
                    <input
                      type="number"
                      value={formData.spare_fuel}
                      onChange={e => setFormData({...formData, spare_fuel: e.target.value})}
                      className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors"
                      placeholder={displayReading?.spare_fuel != null ? `Previous: ${parseFloat(displayReading.spare_fuel).toFixed(0)}L` : 'e.g. 200'}
                    />
                  </div>
                </div>

                <div className="border-t border-slate-700/50 pt-6 mt-6">
                  <h3 className="text-lg font-bold text-white mb-4">Photographic Proof</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className={`bg-slate-900/50 border rounded-xl p-4 flex flex-col items-center justify-center text-center transition-colors ${meterPhoto ? 'border-success/50' : 'border-slate-700'}`}>
                      <div className={`w-12 h-12 rounded-full flex items-center justify-center mb-3 ${meterPhoto ? 'bg-success/20 text-success' : 'bg-danger/10 text-danger'}`}>
                        {meterPhoto ? <Check size={20} /> : <Camera size={20} />}
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
                        className="btn-primary px-4 py-2 rounded-lg text-sm cursor-pointer w-full text-center"
                      >
                        {meterPhoto ? '✓ Change Photo' : 'Take Photo'}
                      </label>
                      {meterPhoto && <span className="mt-2 text-xs text-success">{meterPhoto.name}</span>}
                    </div>

                    <div className={`bg-slate-900/50 border rounded-xl p-4 flex flex-col items-center justify-center text-center transition-colors ${fuelPhoto ? 'border-success/50' : 'border-slate-700'}`}>
                      <div className={`w-12 h-12 rounded-full flex items-center justify-center mb-3 ${fuelPhoto ? 'bg-success/20 text-success' : 'bg-info/10 text-info'}`}>
                        {fuelPhoto ? <Check size={20} /> : <Camera size={20} />}
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
                        className="bg-slate-700 hover:bg-slate-600 text-white px-4 py-2 rounded-lg text-sm cursor-pointer w-full text-center transition-colors"
                      >
                        {fuelPhoto ? '✓ Change Photo' : 'Take Photo'}
                      </label>
                      {fuelPhoto && <span className="mt-2 text-xs text-success">{fuelPhoto.name}</span>}
                    </div>
                  </div>
                </div>

                <div className="border-t border-slate-700/50 pt-6 mt-6">
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
                    className="btn-primary px-8 py-3 rounded-xl flex items-center gap-2 text-lg shadow-lg shadow-primary/20 hover:shadow-primary/40 transition-all"
                    disabled={submitReadingMutation.isLoading}
                  >
                    {submitReadingMutation.isLoading ? 'Submitting...' : <><Check size={18}/> Submit Reading</>}
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
