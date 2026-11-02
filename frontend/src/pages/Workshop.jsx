import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { HardHat, Search, Plus, Map, Layers, DollarSign, PenTool, CheckCircle, Clock, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';

const Workshop = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [newProject, setNewProject] = useState({
    name: '', land_area: '', floors: '', apartments_per_floor: '',
    specifications: {
      bedrooms: '', bathrooms: '', kitchens: '', living_rooms: 0, balconies: 0, 
      windows: '', doors: '', parking_spaces: 0, elevators: 0, roof_area: 0, garden_area: 0
    }
  });

  // We fetch workshop projects from backend. If none exist, we will show some mocks or empty states.
  const { data: projects, isLoading } = useQuery({
    queryKey: ['workshopProjects'],
    queryFn: async () => {
      const res = await axios.get('/workshop');
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (projectData) => axios.post('/workshop', projectData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workshopProjects'] });
      queryClient.invalidateQueries({ queryKey: ['constructions'] });
      setShowAdd(false);
      setNewProject({
        name: '', land_area: '', floors: '', apartments_per_floor: '',
        specifications: {
          bedrooms: '', bathrooms: '', kitchens: '', living_rooms: 0, balconies: 0, 
          windows: '', doors: '', parking_spaces: 0, elevators: 0, roof_area: 0, garden_area: 0
        }
      });
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => axios.delete(`/workshop/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workshopProjects'] });
      queryClient.invalidateQueries({ queryKey: ['constructions'] });
    },
    onError: (err) => {
      alert(err.response?.data?.error || t('workshop.delete_failed', { defaultValue: 'Failed to delete project' }));
    }
  });

  const filteredProjects = projects?.filter(p => p.name?.toLowerCase().includes(searchTerm.toLowerCase()));


  const { data: settings } = useQuery({
    queryKey: ['globalSettings'],
    queryFn: async () => {
      const res = await axios.get('/global-settings');
      return res.data;
    }
  });

  const calculatePreview = () => {
    const fl = parseFloat(newProject.floors) || 0;
    const aptPerFl = parseFloat(newProject.apartments_per_floor) || 0;
    const landArea = parseFloat(newProject.land_area) || 0;
    const sp = newProject.specifications;

    const totalApts = fl * aptPerFl;
    const totalArea = landArea * fl;
    const totalRooms = (parseFloat(sp.bedrooms) || 0) * totalApts;
    const totalBaths = (parseFloat(sp.bathrooms) || 0) * totalApts;
    const totalKitchens = (parseFloat(sp.kitchens) || 0) * totalApts;
    const totalWindows = (parseFloat(sp.windows) || 0) * totalApts;
    const totalDoors = (parseFloat(sp.doors) || 0) * totalApts;

    const baseArea = parseFloat(settings?.workshop_base_area) || 3200;
    const cementBase = parseFloat(settings?.workshop_cement_base) || 10000;
    const sandBase = parseFloat(settings?.workshop_sand_base) || 500;
    const steelBase = parseFloat(settings?.workshop_steel_base) || 50;
    const blocksBase = parseFloat(settings?.workshop_blocks_base) || 150000;
    const costPerSqm = parseFloat(settings?.workshop_cost_per_sqm) || 150000;

    const cement = totalArea > 0 ? (cementBase / baseArea) * totalArea : 0;
    const sand = totalArea > 0 ? (sandBase / baseArea) * totalArea : 0;
    const steel = totalArea > 0 ? (steelBase / baseArea) * totalArea : 0;
    const blocks = totalArea > 0 ? (blocksBase / baseArea) * totalArea : 0;
    const cost = totalArea * costPerSqm;

    return { totalApts, totalArea, totalRooms, totalBaths, totalKitchens, totalWindows, totalDoors, cement, sand, steel, blocks, cost };
  };

  const preview = calculatePreview();

  return (
    <div className="flex h-full w-full overflow-hidden">
      {/* Center Content */}
      <div className="flex-1 overflow-y-auto p-8 hide-scrollbar">
        <div className="flex justify-between items-center mb-8">
          <div>
            <h1 className="text-3xl font-bold text-white">{t('workshop.title')}</h1>
            <p className="text-muted mt-1">{t('workshop.subtitle')}</p>
          </div>
          <div className="flex space-x-4">
            <div className="relative w-64">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={20} />
              <input 
                type="text" 
                placeholder={t('workshop.search')} 
                className="w-full pl-10 pr-4 py-2 bg-cards border border-slate-700 rounded-lg text-white focus:outline-none focus:border-primary transition-colors"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <button 
              onClick={() => setShowAdd(true)}
              className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-lg flex items-center space-x-2 transition-colors shadow-lg shadow-primary/30"
            >
              <Plus size={20} />
              <span>{t('workshop.add_btn')}</span>
            </button>
          </div>
        </div>

        {showAdd && (
          <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4 max-w-4xl mx-auto">
            <h3 className="text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-2">{t('workshop.new_title')}</h3>
            
            <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-6">
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.project_name')}</label>
                <input type="text" value={newProject.name} onChange={e => setNewProject({...newProject, name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.building_size')} (m²)</label>
                <input type="number" value={newProject.land_area} onChange={e => setNewProject({...newProject, land_area: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.floors')}</label>
                <input type="number" value={newProject.floors} onChange={e => setNewProject({...newProject, floors: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">Apartments Per Floor</label>
                <input type="number" value={newProject.apartments_per_floor} onChange={e => setNewProject({...newProject, apartments_per_floor: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.rooms')}</label>
                <input type="number" value={newProject.specifications.bedrooms} onChange={e => setNewProject({...newProject, specifications: {...newProject.specifications, bedrooms: e.target.value}})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.bathrooms')}</label>
                <input type="number" value={newProject.specifications.bathrooms} onChange={e => setNewProject({...newProject, specifications: {...newProject.specifications, bathrooms: e.target.value}})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.kitchens')}</label>
                <input type="number" value={newProject.specifications.kitchens} onChange={e => setNewProject({...newProject, specifications: {...newProject.specifications, kitchens: e.target.value}})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.windows')}</label>
                <input type="number" value={newProject.specifications.windows} onChange={e => setNewProject({...newProject, specifications: {...newProject.specifications, windows: e.target.value}})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
              <div>
                <label className="block text-xs font-medium text-muted mb-1">{t('workshop.doors')}</label>
                <input type="number" value={newProject.specifications.doors} onChange={e => setNewProject({...newProject, specifications: {...newProject.specifications, doors: e.target.value}})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
              </div>
            </div>

            <div className="flex justify-end space-x-3 mt-4 pt-4 border-t border-slate-700/50">
              <button onClick={() => setShowAdd(false)} className="px-6 py-2 bg-slate-700 text-white rounded-lg transition-colors hover:bg-slate-600">{t('workshop.cancel')}</button>
              <button onClick={() => addMutation.mutate(newProject)} disabled={!newProject.name || addMutation.isPending} className="px-6 py-2 bg-success hover:bg-green-600 text-white rounded-lg transition-colors shadow-lg shadow-success/20 font-medium">{t('workshop.generate')}</button>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {isLoading ? (
             Array(3).fill(0).map((_, i) => (
              <div key={i} className="glass-card h-72 animate-pulse bg-slate-800/50"></div>
            ))
          ) : (
            filteredProjects?.length > 0 ? filteredProjects.map(project => (
              <ProjectCard 
                key={project.id} 
                project={project} 
                navigate={navigate} 
                onDelete={(id) => deleteMutation.mutate(id)}
                isDeleting={deleteMutation.isPending}
              />
            )) : (
              <div className="col-span-full flex flex-col items-center justify-center p-12 text-muted glass-card">
                <HardHat size={48} className="mb-4 opacity-20" />
                <p>{t('workshop.no_data')}</p>
              </div>
            )
          )}
        </div>
      </div>

      {/* Right Summary Panel */}
      <div className="hidden lg:flex w-80 glass-panel p-6 flex-col overflow-y-auto hide-scrollbar z-10">
        {showAdd ? (
          <>
            <h2 className="text-xl font-bold text-white mb-6">Live Preview</h2>
            <div className="space-y-4">
              <div className="p-4 glass-card">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🏢 Total Building Area</span>
                  <span className="text-white font-bold">{preview.totalArea.toLocaleString()} m²</span>
                </div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🏠 Total Apartments</span>
                  <span className="text-white font-bold">{preview.totalApts}</span>
                </div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🛏 Total Rooms</span>
                  <span className="text-white font-bold">{preview.totalRooms}</span>
                </div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🚿 Total Bathrooms</span>
                  <span className="text-white font-bold">{preview.totalBaths}</span>
                </div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🍳 Total Kitchens</span>
                  <span className="text-white font-bold">{preview.totalKitchens}</span>
                </div>
                <div className="flex justify-between items-center mb-2">
                  <span className="text-muted text-sm">🪟 Total Windows</span>
                  <span className="text-white font-bold">{preview.totalWindows}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-muted text-sm">🚪 Total Doors</span>
                  <span className="text-white font-bold">{preview.totalDoors}</span>
                </div>
              </div>
              
              <div className="p-4 glass-card border-indigo-500/30">
                <h3 className="text-sm font-medium text-indigo-400 mb-3">🧱 Estimated Materials</h3>
                <div className="space-y-2 text-sm">
                  <div className="flex justify-between"><span className="text-muted">Cement</span><span className="text-white">{Math.round(preview.cement).toLocaleString()} Bags</span></div>
                  <div className="flex justify-between"><span className="text-muted">Sand</span><span className="text-white">{Math.round(preview.sand).toLocaleString()} Tons</span></div>
                  <div className="flex justify-between"><span className="text-muted">Steel</span><span className="text-white">{Math.round(preview.steel).toLocaleString()} Tons</span></div>
                  <div className="flex justify-between"><span className="text-muted">Blocks</span><span className="text-white">{Math.round(preview.blocks).toLocaleString()} Pcs</span></div>
                </div>
              </div>

              <div className="p-4 glass-card border-success/30">
                <h3 className="text-sm font-medium text-success mb-2">💰 Estimated Cost</h3>
                <div className="text-2xl font-bold text-white">CFA {preview.cost.toLocaleString()}</div>
              </div>
            </div>
          </>
        ) : (
          <>
            <h2 className="text-xl font-bold text-white mb-6">{t('workshop.quick_summary')}</h2>
            
            <div className="space-y-6">
              <div className="p-5 glass-card relative overflow-hidden">
                <div className="absolute top-0 right-0 w-24 h-24 bg-blue-500/20 blur-2xl rounded-full"></div>
                <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-2">{t('workshop.total_projects')}</h3>
                <div className="text-3xl font-bold text-white mb-4">{projects?.length || 0}</div>
              </div>
              
              <div className="p-5 glass-card">
                <h3 className="text-muted text-sm font-medium uppercase tracking-wider mb-4">{t('workshop.overall_progress')}</h3>
                <div className="w-full bg-slate-800 rounded-full h-4 mb-2">
                  <div className="bg-primary h-4 rounded-full" style={{ width: '0%' }}></div>
                </div>
                <div className="flex justify-between text-xs text-muted">
                  <span>0% {t('workshop.complete')}</span>
                </div>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
};

const ProjectCard = ({ project, navigate, onDelete, isDeleting }) => {
  const { t } = useTranslation();
  return (
    <div 
      className="glass-card p-0 flex flex-col hover-card overflow-hidden group cursor-pointer relative"
      onClick={() => navigate(`/workshop/${project.id}`)}
    >
      <div className="h-32 bg-slate-800 relative flex items-center justify-center">
        <HardHat size={48} className="text-slate-600 opacity-50 group-hover:scale-105 transition-transform duration-300" />
        
        {/* Delete Button */}
        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            if (window.confirm(t('workshop.delete_confirm', { defaultValue: `Are you sure you want to delete project "${project.name}"? This will permanently remove its estimates and specifications.` }))) {
              onDelete(project.id);
            }
          }}
          disabled={isDeleting}
          className="absolute top-3 left-3 p-2 bg-slate-900/80 hover:bg-rose-500/20 text-slate-400 hover:text-rose-400 rounded-lg backdrop-blur-md transition-all duration-200 shadow hover:scale-105 border border-slate-700/50 hover:border-rose-500/40 z-10"
          title={t('workshop.delete_btn', { defaultValue: 'Delete Project' })}
        >
          <Trash2 size={16} />
        </button>

        {/* Status Badge */}
        <div className="absolute top-3 right-3 bg-slate-900/80 backdrop-blur-md px-3 py-1 rounded-full text-xs font-medium text-white flex items-center border border-slate-700/40 shadow">
          <Clock size={12} className="mr-1 text-primary" /> {t('construction.status_' + (project.status || 'Active').toLowerCase(), { defaultValue: project.status || 'Active' })}
        </div>
      </div>
      <div className="p-6 flex flex-col flex-1">
        <h3 className="font-bold text-xl text-white mb-4 line-clamp-1">{project.name}</h3>
        
        <div className="grid grid-cols-2 gap-4 mb-6">
          <div className="flex items-center text-muted text-sm">
            <Map size={16} className="mr-2 text-slate-500" />
            {project.area || project.land_area || 'N/A'} {t('settings.units.m2', {defaultValue: 'm2'})}
          </div>
          <div className="flex items-center text-muted text-sm">
            <Layers size={16} className="mr-2 text-slate-500" />
            {project.floors || 0} {t('workshop.card_floors')}
          </div>
          <div className="flex items-center text-muted text-sm">
            <DollarSign size={16} className="mr-2 text-slate-500" />
            {t('common.currency')} {Number(project.estimated_cost || project.budget || 0).toLocaleString()}
          </div>
          <div className="flex items-center text-muted text-sm">
            <PenTool size={16} className="mr-2 text-slate-500" />
            {project.materials_required || 0} {t('workshop.card_materials')}
          </div>
        </div>

        <div className="mt-auto">
          <div className="flex justify-between text-xs text-muted mb-2">
            <span>{t('workshop.card_progress')}</span>
            <span className="text-white font-medium">{project.progress || 0}%</span>
          </div>
          <div className="w-full bg-slate-800 rounded-full h-2">
            <div className="bg-primary h-2 rounded-full" style={{ width: `${project.progress || 0}%` }}></div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Workshop;
