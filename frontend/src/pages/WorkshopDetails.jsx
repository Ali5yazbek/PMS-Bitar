import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Calculator, ClipboardCheck, Printer, CheckCircle, Edit3, Save, X, Trash2 } from 'lucide-react';
import { useTranslation } from 'react-i18next';

const WorkshopDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const queryClient = useQueryClient();
  const [editingId, setEditingId] = useState(null);
  const [editPrice, setEditPrice] = useState('');

  const { data, isLoading } = useQuery({ 
    queryKey: ['workshopProject', id], 
    queryFn: async () => (await api.get(`/workshop/${id}`)).data 
  });

  const reserveMutation = useMutation({
    mutationFn: () => api.post(`/workshop/${id}/reserve`),
    onSuccess: () => {
      queryClient.invalidateQueries(['workshopProject', id]);
      alert('Materials successfully reserved. Any shortages have generated Purchase Requests in Depot.');
    }
  });

  const updatePriceMutation = useMutation({
    mutationFn: (vars) => api.put(`/workshop/estimates/${vars.id}`, { unit_price: vars.price }),
    onSuccess: () => {
      queryClient.invalidateQueries(['workshopProject', id]);
      setEditingId(null);
    }
  });

  const startConstructionMutation = useMutation({
    mutationFn: () => api.post(`/workshop/${id}/start-construction`),
    onSuccess: () => {
      queryClient.invalidateQueries(['workshopProject', id]);
      alert('Construction started successfully! Project blueprint locked.');
      navigate('/constructions');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: () => api.delete(`/workshop/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['workshopProjects'] });
      queryClient.invalidateQueries({ queryKey: ['constructions'] });
      navigate('/workshop');
    },
    onError: (err) => {
      alert(err.response?.data?.error || t('workshop.delete_failed', { defaultValue: 'Failed to delete project' }));
    }
  });

  if (isLoading) return <div>Loading...</div>;
  if (!data || !data.project) return <div>Project not found</div>;

  const { project, estimates } = data;

  const groupedEstimates = estimates.reduce((acc, est) => {
    acc[est.category] = acc[est.category] || [];
    acc[est.category].push(est);
    return acc;
  }, {});

  const totalCost = estimates.reduce((sum, est) => sum + Number(est.total_price), 0);
  
  // Calculate category totals
  const categoryTotals = Object.keys(groupedEstimates).map(cat => ({
    name: cat,
    total: groupedEstimates[cat].reduce((sum, e) => sum + Number(e.total_price), 0)
  }));

  const isReserved = estimates.some(e => e.is_reserved);

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <button onClick={() => navigate('/workshop')} className="flex items-center gap-2 text-orange-600 hover:text-orange-800 font-medium">
          <ArrowLeft size={20} /> Back to Workshop Projects
        </button>
        <button 
          onClick={() => {
            if (window.confirm(t('workshop.delete_confirm', { defaultValue: `Are you sure you want to delete project "${project.name}"? This will permanently remove its estimates and specifications.` }))) {
              deleteMutation.mutate();
            }
          }}
          disabled={deleteMutation.isPending}
          className="flex items-center gap-2 bg-rose-50 text-rose-600 hover:bg-rose-100 hover:text-rose-700 border border-rose-200 px-4 py-2 rounded-lg font-medium transition-colors text-sm shadow-sm"
        >
          <Trash2 size={16} />
          {t('workshop.delete_btn', { defaultValue: 'Delete Project' })}
        </button>
      </div>

      <div className="flex justify-between items-start bg-white p-6 rounded-xl shadow-sm border border-slate-100">
        <div>
          <h1 className="text-3xl font-bold text-slate-800">{project.name}</h1>
          <div className="flex items-center gap-4 mt-2">
            <span className="text-slate-500">Total Apartments: <b>{project.total_apartments}</b></span>
            <span className="text-slate-500">Floors: <b>{project.floors}</b></span>
            <span className="text-slate-500">Land Area: <b>{project.land_area} m²</b></span>
            <span className="px-3 py-1 bg-amber-100 text-amber-800 text-xs font-bold rounded-full uppercase tracking-wider">{project.status}</span>
          </div>
        </div>
        <div className="text-right">
          <p className="text-slate-500 font-medium">Estimated Total Cost</p>
          <h2 className="text-4xl font-black text-slate-800">CFA {totalCost.toLocaleString()}</h2>
          
          {project.status !== 'Construction_Started' ? (
            <button 
              onClick={() => { if(window.confirm('Start construction? This will lock the estimates and create a tracking project.')) startConstructionMutation.mutate(); }}
              className="mt-4 w-full flex items-center justify-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-3 rounded-lg font-bold transition-all shadow-md"
            >
              <CheckCircle size={20} />
              Start Construction
            </button>
          ) : (
            <div className="mt-4 flex flex-col gap-2">
              <div className="w-full flex items-center justify-center gap-2 bg-emerald-100 text-emerald-800 px-4 py-2 rounded-lg font-bold border border-emerald-200">
                <ClipboardCheck size={20} />
                Construction Active
              </div>
              {project.linked_construction_id && (
                <button 
                  onClick={() => navigate(`/constructions/${project.linked_construction_id}`)}
                  className="w-full flex items-center justify-center gap-2 bg-slate-800 hover:bg-slate-700 text-white px-4 py-2 rounded-lg font-bold transition-all shadow-sm text-sm"
                >
                  View Tracking Dashboard
                </button>
              )}
            </div>
          )}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          {/* Categories */}
          {Object.keys(groupedEstimates).map(category => {
            const catTotal = groupedEstimates[category].reduce((sum, e) => sum + Number(e.total_price), 0);
            return (
              <div key={category} className="bg-white rounded-xl shadow-sm border border-slate-100 overflow-hidden">
                <div className="bg-slate-50 p-4 border-b flex justify-between items-center">
                  <h3 className="font-bold text-lg text-slate-800 flex items-center gap-2">
                    <Calculator className="text-orange-500" size={20} /> {category} Cost Breakdown
                  </h3>
                  <span className="font-bold text-lg text-slate-800">CFA {catTotal.toLocaleString()}</span>
                </div>
                <table className="min-w-full divide-y divide-slate-200">
                  <thead className="bg-white">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase">Item</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase">Quantity</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase">Unit Price</th>
                      <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 uppercase">Total</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 bg-white">
                    {groupedEstimates[category].map(est => (
                      <tr key={est.id} className="hover:bg-slate-50 transition-colors">
                        <td className="px-6 py-3 text-sm font-medium text-slate-900">{t(`workshop.items.${est.item_name}`, { defaultValue: est.item_name })}</td>
                        <td className="px-6 py-3 text-sm text-right text-slate-600">{Number(est.quantity).toLocaleString()} {est.unit}</td>
                        <td className="px-6 py-3 text-sm text-right text-slate-600 group">
                          {editingId === est.id ? (
                            <div className="flex items-center justify-end gap-2">
                              <span className="text-slate-400">CFA </span>
                              <input 
                                type="number" 
                                className="border rounded px-2 py-1 w-24 text-right"
                                value={editPrice}
                                onChange={e => setEditPrice(e.target.value)}
                                autoFocus
                              />
                              <button onClick={() => updatePriceMutation.mutate({ id: est.id, price: editPrice })} className="text-green-600 hover:text-green-800"><Save size={16}/></button>
                              <button onClick={() => setEditingId(null)} className="text-red-500 hover:text-red-700"><X size={16}/></button>
                            </div>
                          ) : (
                            <div className="flex items-center justify-end gap-2">
                              <span>CFA {Number(est.unit_price).toLocaleString()}</span>
                              <button 
                                onClick={() => { setEditingId(est.id); setEditPrice(est.unit_price); }}
                                className="text-slate-300 hover:text-blue-500 transition-colors opacity-0 group-hover:opacity-100"
                                title="Edit Price"
                              >
                                <Edit3 size={14} />
                              </button>
                            </div>
                          )}
                        </td>
                        <td className="px-6 py-3 text-sm text-right font-medium text-slate-900">CFA {Number(est.total_price).toLocaleString()}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
          })}
        </div>

        <div className="space-y-6">
          <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
            <h3 className="font-bold text-lg text-slate-800 border-b pb-3 mb-4">Cost Summary</h3>
            <div className="space-y-3">
              {categoryTotals.map(cat => (
                <div key={cat.name} className="flex justify-between items-center">
                  <span className="text-slate-600 font-medium">{cat.name}</span>
                  <span className="font-bold text-slate-800">CFA {cat.total.toLocaleString()}</span>
                </div>
              ))}
              <div className="border-t pt-3 mt-3 flex justify-between items-center">
                <span className="text-lg font-bold text-slate-800">Total</span>
                <span className="text-xl font-black text-orange-600">CFA {totalCost.toLocaleString()}</span>
              </div>
            </div>
          </div>

          <div className="bg-white p-6 rounded-xl shadow-sm border border-slate-100">
            <h3 className="font-bold text-lg text-slate-800 border-b pb-3 mb-4">Actions</h3>
            
            <div className="space-y-3">
              {!isReserved ? (
                <div className="bg-blue-50 border border-blue-200 p-4 rounded-lg">
                  <h4 className="font-bold text-blue-800 flex items-center gap-2 mb-2"><ClipboardCheck size={18} /> Material Reservation</h4>
                  <p className="text-xs text-blue-600 mb-4">Compare required materials against Depot stock. Shortages will auto-create Purchase Requests.</p>
                  <button 
                    onClick={() => reserveMutation.mutate()}
                    className="w-full bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 rounded-lg transition-colors"
                  >
                    Reserve & Check Stock
                  </button>
                </div>
              ) : (
                <div className="bg-green-50 border border-green-200 p-4 rounded-lg flex items-start gap-3">
                  <CheckCircle className="text-green-600 shrink-0" />
                  <div>
                    <h4 className="font-bold text-green-800">Materials Reserved</h4>
                    <p className="text-xs text-green-700 mt-1">Stock has been deducted from the Depot. Please check Depot for any generated Purchase Requests.</p>
                  </div>
                </div>
              )}

              <button className="w-full bg-slate-100 hover:bg-slate-200 text-slate-700 font-medium py-3 rounded-lg transition-colors flex items-center justify-center gap-2" onClick={() => window.print()}>
                <Printer size={18} /> Print Estimates (PDF)
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default WorkshopDetails;
