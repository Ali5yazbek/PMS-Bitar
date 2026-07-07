import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import axios from '../api/axios';
import { useTranslation } from 'react-i18next';
import { Briefcase, Search, Plus, MapPin, Calendar, CheckCircle, Pause, Trash2, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const Construction = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [newProject, setNewProject] = useState({
    name: '', owner: '', location: '', start_date: '', end_date: '', budget: '', manager: ''
  });

  const { data: projects = [], isLoading } = useQuery({
    queryKey: ['constructions'],
    queryFn: async () => {
      const res = await axios.get('/constructions');
      return res.data;
    }
  });

  const addMutation = useMutation({
    mutationFn: (projectData) => axios.post('/constructions', projectData),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['constructions'] });
      setShowAdd(false);
      setNewProject({ name: '', owner: '', location: '', start_date: '', end_date: '', budget: '', manager: '' });
    }
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ id, status }) => axios.put(`/constructions/${id}`, { ...projects.find(p => p.id === id), status }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['constructions'] })
  });

  const deleteMutation = useMutation({
    mutationFn: (id) => axios.delete(`/constructions/${id}`),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['constructions'] })
  });

  const filteredProjects = projects.filter(p => p.name.toLowerCase().includes(searchTerm.toLowerCase()));

  const getStatusColor = (status) => {
    switch(status) {
      case 'Active': return 'bg-success/20 text-success border-success/30';
      case 'Paused': return 'bg-warning/20 text-warning border-warning/30';
      case 'Completed': return 'bg-blue-500/20 text-blue-400 border-blue-500/30';
      default: return 'bg-slate-500/20 text-slate-400 border-slate-500/30';
    }
  };

  const ProjectCard = ({ project }) => (
    <div className="glass-card p-6 flex flex-col justify-between group hover:border-primary/50 transition-all duration-300">
      <div>
        <div className="flex justify-between items-start mb-4">
          <div>
            <h3 className="text-xl font-bold text-white group-hover:text-primary transition-colors">{project.name}</h3>
            <p className="text-sm text-muted flex items-center mt-1"><MapPin size={14} className="me-1" /> {project.location || t('construction.no_location')}</p>
          </div>
          <span className={`px-3 py-1 rounded-full text-xs font-medium border ${getStatusColor(project.status)}`}>
            {t(`construction.status_${project.status.toLowerCase()}`)}
          </span>
        </div>
        
        <div className="space-y-3 mb-6">
          <div className="flex justify-between text-sm">
            <span className="text-muted">{t('construction.card_owner')}</span>
            <span className="text-white">{project.owner || 'N/A'}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted">{t('construction.card_budget')}</span>
            <span className="text-white font-medium">{t('common.currency')} {parseFloat(project.budget || 0).toLocaleString()}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-muted">{t('construction.card_cost')}</span>
            <span className={parseFloat(project.actual_cost) > parseFloat(project.budget) ? 'text-danger font-bold' : 'text-success font-medium'}>
              CFA {parseFloat(project.actual_cost || 0).toLocaleString()}
            </span>
          </div>
          
          <div className="w-full bg-slate-800 rounded-full h-2 mt-4">
            <div 
              className={`h-2 rounded-full ${parseFloat(project.actual_cost) > parseFloat(project.budget) ? 'bg-danger' : 'bg-primary'}`} 
              style={{ width: `${Math.min((parseFloat(project.actual_cost || 0) / parseFloat(project.budget || 1)) * 100, 100)}%` }}
            ></div>
          </div>
        </div>
      </div>
      
      <div className="flex gap-2 pt-4 border-t border-slate-700/50">
        <button 
          onClick={() => navigate(`/constructions/${project.id}`)}
          className="flex-1 py-2 bg-primary/10 text-primary hover:bg-primary/20 rounded-lg flex items-center justify-center font-medium transition-colors"
        >
          {t('construction.card_ledger')} <ArrowRight size={16} className={`ms-2 ${document.documentElement.dir === 'rtl' ? 'rotate-180' : ''}`} />
        </button>
        <button 
          onClick={() => updateStatusMutation.mutate({ id: project.id, status: project.status === 'Active' ? 'Paused' : 'Active' })}
          className="p-2 bg-slate-800 text-muted hover:text-white rounded-lg transition-colors"
          title={project.status === 'Active' ? t('construction.card_pause') : t('construction.card_activate')}
        >
          {project.status === 'Active' ? <Pause size={18} /> : <CheckCircle size={18} />}
        </button>
        <button 
          onClick={() => {
            if(window.confirm(t('construction.card_delete_confirm'))) deleteMutation.mutate(project.id);
          }}
          className="p-2 bg-slate-800 text-danger hover:bg-danger/10 rounded-lg transition-colors"
        >
          <Trash2 size={18} />
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex flex-col h-full overflow-y-auto p-8 hide-scrollbar">
      <div className="flex justify-between items-end mb-8">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2 flex items-center">
            <Briefcase className="me-3 text-primary" size={32} /> {t('construction.title')}
          </h1>
          <p className="text-muted">{t('construction.subtitle')}</p>
        </div>
        <div className="flex space-x-4">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-muted" size={18} />
            <input 
              type="text" 
              placeholder={t('construction.search')} 
              value={searchTerm}
              onChange={e => setSearchTerm(e.target.value)}
              className="bg-slate-800 border border-slate-700 text-white rounded-xl pl-10 pr-4 py-2 focus:outline-none focus:border-primary transition-colors"
            />
          </div>
          <button 
            onClick={() => setShowAdd(!showAdd)}
            className="bg-primary hover:bg-indigo-600 text-white px-4 py-2 rounded-xl flex items-center font-medium transition-colors shadow-lg shadow-primary/20"
          >
            <Plus size={18} className="me-2" /> {t('construction.add_btn')}
          </button>
        </div>
      </div>

      {showAdd && (
        <div className="glass-card p-6 mb-8 animate-in fade-in slide-in-from-top-4 max-w-4xl mx-auto">
          <h3 className="text-xl font-bold text-white mb-6 border-b border-slate-700/50 pb-2">{t('construction.new_title')}</h3>
          
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-6">
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.name_label')}</label>
              <input type="text" value={newProject.name} onChange={e => setNewProject({...newProject, name: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.owner_label')}</label>
              <input type="text" value={newProject.owner} onChange={e => setNewProject({...newProject, owner: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.location_label')}</label>
              <input type="text" value={newProject.location} onChange={e => setNewProject({...newProject, location: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.budget_label')}</label>
              <input type="number" value={newProject.budget} onChange={e => setNewProject({...newProject, budget: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.manager_label')}</label>
              <input type="text" value={newProject.manager} onChange={e => setNewProject({...newProject, manager: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.start_date')}</label>
              <input type="date" value={newProject.start_date} onChange={e => setNewProject({...newProject, start_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" style={{ colorScheme: 'dark' }} />
            </div>
            <div>
              <label className="block text-xs font-medium text-muted mb-1">{t('construction.end_date')}</label>
              <input type="date" value={newProject.end_date} onChange={e => setNewProject({...newProject, end_date: e.target.value})} className="w-full bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-white text-sm" style={{ colorScheme: 'dark' }} />
            </div>
          </div>

          <div className="flex justify-end space-x-3 mt-4 pt-4 border-t border-slate-700/50">
            <button onClick={() => setShowAdd(false)} className="px-6 py-2 bg-slate-700 text-white rounded-lg transition-colors hover:bg-slate-600">{t('construction.cancel')}</button>
            <button onClick={() => addMutation.mutate({...newProject, status: 'Active'})} disabled={!newProject.name || addMutation.isPending} className="px-6 py-2 bg-success hover:bg-green-600 text-white rounded-lg transition-colors shadow-lg shadow-success/20 font-medium">{t('construction.create')}</button>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {isLoading ? (
          Array(4).fill(0).map((_, i) => (
            <div key={i} className="glass-card h-64 animate-pulse bg-slate-800/50"></div>
          ))
        ) : filteredProjects.length > 0 ? (
          filteredProjects.map(project => <ProjectCard key={project.id} project={project} />)
        ) : (
          <div className="col-span-full flex flex-col items-center justify-center p-12 text-muted glass-card">
            <Briefcase size={48} className="mb-4 opacity-20" />
            <p>{t('construction.no_data')}</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default Construction;
