import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../../api/axios';
import { Home, Camera, Check, FileText, ChevronRight } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const AgentApartments = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [selectedBuilding, setSelectedBuilding] = useState(null);
  const [selectedApartment, setSelectedApartment] = useState(null);
  
  const [currentReading, setCurrentReading] = useState('');
  const [notes, setNotes] = useState('');
  const [meterPhoto, setMeterPhoto] = useState(null);

  const { data: buildings = [], isLoading: buildingsLoading } = useQuery({
    queryKey: ['buildings'],
    queryFn: async () => (await axios.get('/buildings')).data,
  });

  const { data: apartments = [], isLoading: apartmentsLoading } = useQuery({
    queryKey: ['apartments', selectedBuilding?.id],
    queryFn: async () => {
      const res = await axios.get(`/energy/buildings/${selectedBuilding.id}/subscriptions`);
      // Filter for only Meter Reading types (where amps is 0 or null)
      return res.data.filter(a => !a.amps || a.amps === 0);
    },
    enabled: !!selectedBuilding,
  });

  const submitReadingMutation = useMutation({
    mutationFn: async () => {
      const fd = new FormData();
      fd.append('apartment_id', selectedApartment.apartment_id);
      fd.append('current_reading', currentReading);
      fd.append('notes', notes);
      if (meterPhoto) fd.append('meter_photo', meterPhoto);

      return axios.post('/energy/agent/apartment-reading', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
    },
    onSuccess: () => {
      alert('Electricity reading submitted successfully for Admin review!');
      setCurrentReading('');
      setNotes('');
      setMeterPhoto(null);
      setSelectedApartment(null);
    },
    onError: (err) => {
      alert(err.response?.data?.error || 'Failed to submit reading. Endpoint may not exist yet.');
    }
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!meterPhoto) {
      alert('Electricity Meter Photo is mandatory.');
      return;
    }
    submitReadingMutation.mutate();
  };

  return (
    <div className="p-8 max-w-7xl mx-auto h-full flex flex-col overflow-y-auto custom-scrollbar">
      <div className="mb-8 shrink-0">
        <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
          <Home className="me-3 text-primary" /> Submit Apartment Reading
        </h1>
        <p className="text-muted">Select a building and an apartment to submit the monthly electricity reading.</p>
      </div>

      <div className="flex flex-col lg:flex-row gap-8 flex-1 min-h-0">
        
        {/* Buildings & Apartments Sidebar */}
        <div className="w-full lg:w-1/3 flex flex-col gap-6">
          
          {/* Buildings */}
          <div className="flex flex-col glass-card max-h-[40vh] overflow-hidden">
            <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
              <h2 className="font-bold text-white uppercase text-sm tracking-wider">1. Select Building</h2>
            </div>
            <div className="flex-1 overflow-y-auto p-2 space-y-1">
              {buildingsLoading ? (
                <div className="p-4 text-center text-slate-500">Loading...</div>
              ) : buildings.map(b => (
                <button
                  key={b.id}
                  onClick={() => {
                    setSelectedBuilding(b);
                    setSelectedApartment(null);
                  }}
                  className={`w-full text-left p-4 rounded-xl transition-all flex justify-between items-center ${
                    selectedBuilding?.id === b.id 
                      ? 'bg-primary text-white shadow-lg shadow-primary/20' 
                      : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                  }`}
                >
                  <span className="font-medium">{b.name}</span>
                  <ChevronRight size={16} className={selectedBuilding?.id === b.id ? 'text-white' : 'text-slate-500'} />
                </button>
              ))}
            </div>
          </div>

          {/* Apartments */}
          {selectedBuilding && (
            <div className="flex flex-col glass-card flex-1 overflow-hidden">
              <div className="p-4 border-b border-slate-700/50 bg-slate-800/30">
                <h2 className="font-bold text-white uppercase text-sm tracking-wider">2. Select Apartment</h2>
              </div>
              <div className="flex-1 overflow-y-auto p-2 space-y-1">
                {apartmentsLoading ? (
                  <div className="p-4 text-center text-slate-500">Loading...</div>
                ) : apartments.length === 0 ? (
                  <div className="p-4 text-center text-slate-500">No metered apartments found.</div>
                ) : apartments.map(apt => (
                  <button
                    key={apt.id}
                    onClick={() => setSelectedApartment(apt)}
                    className={`w-full text-left p-4 rounded-xl transition-all flex justify-between items-center ${
                      selectedApartment?.id === apt.id 
                        ? 'bg-indigo-500 text-white shadow-lg shadow-indigo-500/20' 
                        : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                    }`}
                  >
                    <div>
                      <div className="font-medium">Apt {apt.apartment_code}</div>
                      <div className="text-xs opacity-75">{apt.tenant_name || 'Metered'}</div>
                    </div>
                    <ChevronRight size={16} className={selectedApartment?.id === apt.id ? 'text-white' : 'text-slate-500'} />
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Reading Form */}
        <div className="w-full lg:w-2/3 glass-card overflow-y-auto p-6">
          {!selectedApartment ? (
            <div className="h-full flex flex-col items-center justify-center text-slate-500">
              <Home size={48} className="mb-4 text-slate-600 opacity-50" />
              <p>Select an apartment to enter its electricity reading.</p>
            </div>
          ) : (
            <div>
              <div className="mb-6 pb-4 border-b border-slate-700/50 flex justify-between items-center">
                <div>
                  <h2 className="text-2xl font-bold text-white mb-1">Apt {selectedApartment.apartment_code}</h2>
                  <p className="text-muted">Tenant: {selectedApartment.tenant_name || 'N/A'}</p>
                </div>
                <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-warning/10 text-warning border border-warning/20">
                  Monthly Reading Due
                </span>
              </div>

              {/* Previous Reading Info */}
              <div className="bg-slate-800/50 border border-slate-700 rounded-xl p-4 mb-6 flex justify-between items-center">
                <div>
                  <p className="text-sm text-slate-400">Previous Reading</p>
                  <p className="text-xl font-bold text-white">{selectedApartment.last_reading || 0} kWh</p>
                </div>
                <div className="text-right">
                  <p className="text-sm text-slate-400">Last Updated</p>
                  <p className="text-white font-medium">{selectedApartment.last_reading_date || 'N/A'}</p>
                </div>
              </div>

              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-muted mb-1">Current Reading (kWh)</label>
                  <input
                    type="number"
                    required
                    value={currentReading}
                    onChange={e => setCurrentReading(e.target.value)}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-4 text-2xl font-bold text-white focus:outline-none focus:border-primary transition-colors"
                    placeholder="e.g. 4500"
                  />
                  {currentReading && selectedApartment.last_reading && (
                    <p className="mt-2 text-sm text-info">
                      Consumption: <span className="font-bold">{Math.max(0, parseFloat(currentReading) - parseFloat(selectedApartment.last_reading))} kWh</span>
                    </p>
                  )}
                </div>

                <div className="border-t border-slate-700/50 pt-6">
                  <h3 className="text-lg font-bold text-white mb-4">Photographic Proof</h3>
                  
                  <div className="bg-slate-900/50 border border-slate-700 rounded-xl p-6 flex flex-col items-center justify-center text-center max-w-sm">
                    <div className="w-16 h-16 bg-danger/10 text-danger rounded-full flex items-center justify-center mb-4">
                      <Camera size={24} />
                    </div>
                    <h4 className="text-white font-medium mb-1">Electricity Meter Photo <span className="text-danger">*</span></h4>
                    <p className="text-sm text-slate-400 mb-6">Required proof of current kWh reading</p>
                    
                    <input 
                      type="file" 
                      accept="image/*" 
                      capture="environment"
                      className="hidden" 
                      id="apt-photo-upload"
                      onChange={(e) => setMeterPhoto(e.target.files[0])}
                    />
                    <label 
                      htmlFor="apt-photo-upload" 
                      className="btn-primary px-6 py-3 rounded-xl text-md cursor-pointer w-full transition-all hover:shadow-lg hover:shadow-primary/20"
                    >
                      {meterPhoto ? 'Change Photo' : 'Take Photo'}
                    </label>
                    {meterPhoto && <span className="mt-3 text-sm font-medium text-success flex items-center"><Check size={16} className="me-1" /> {meterPhoto.name}</span>}
                  </div>
                </div>

                <div className="border-t border-slate-700/50 pt-6">
                  <label className="block text-sm font-medium text-muted mb-1">Notes / Observations</label>
                  <textarea
                    rows="2"
                    value={notes}
                    onChange={e => setNotes(e.target.value)}
                    className="w-full bg-slate-900/50 border border-slate-700 rounded-xl px-4 py-3 text-white focus:outline-none focus:border-primary transition-colors resize-none"
                    placeholder="Meter condition, anomalies..."
                  ></textarea>
                </div>

                <div className="flex justify-end pt-4">
                  <button 
                    type="submit" 
                    className="bg-indigo-500 hover:bg-indigo-600 text-white px-8 py-3 rounded-xl flex items-center text-lg font-bold shadow-lg shadow-indigo-500/20 transition-all"
                    disabled={submitReadingMutation.isLoading}
                  >
                    {submitReadingMutation.isLoading ? 'Submitting...' : 'Submit Apartment Reading'}
                  </button>
                </div>
              </form>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default AgentApartments;
