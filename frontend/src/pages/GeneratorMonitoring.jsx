import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../api/axios';
import { Activity, AlertTriangle, ShieldCheck, Clock, Zap, ArrowRight, CheckCircle2 } from 'lucide-react';

import AIInvestigationReport from '../components/AIInvestigationReport';

const GeneratorMonitoring = () => {
  const { t } = useTranslation();
  const queryClient = useQueryClient();

  const { data: dashboardData, isLoading: dashboardLoading } = useQuery({
    queryKey: ['executiveDashboard'],
    queryFn: async () => {
      const res = await api.get('/energy/executive-dashboard');
      return res.data;
    }
  });

  const { data: alertsData, isLoading: alertsLoading } = useQuery({
    queryKey: ['smartAlerts'],
    queryFn: async () => {
      const res = await api.get('/energy/smart-alerts');
      return res.data;
    }
  });

  const resolveAlertMutation = useMutation({
    mutationFn: (id) => api.put(`/energy/smart-alerts/${id}/resolve`),
    onSuccess: () => {
      queryClient.invalidateQueries(['smartAlerts']);
    }
  });

  if (dashboardLoading || alertsLoading) {
    return (
      <div className="flex-1 p-8 flex items-center justify-center h-full">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  const criticalAlertsCount = alertsData?.filter(a => a.severity === 'Critical' && a.status !== 'Resolved').length || 0;
  const warningAlertsCount = alertsData?.filter(a => a.severity === 'Warning' && a.status !== 'Resolved').length || 0;

  return (
    <div className="flex-1 overflow-y-auto p-8 hide-scrollbar bg-background">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white flex items-center gap-3">
          <Activity className="text-primary" /> Smart Monitoring Engine
        </h1>
        <p className="text-muted mt-2">AI-driven auditing for fuel consumption, leaks, and generator efficiency.</p>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="glass-card p-6 border-l-4 border-success flex items-center gap-4">
          <div className="p-4 bg-success/20 rounded-full">
            <ShieldCheck size={32} className="text-success" />
          </div>
          <div>
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider">System Status</h3>
            <p className="text-2xl font-bold text-white">{criticalAlertsCount > 0 ? 'Action Required' : 'All Clear'}</p>
          </div>
        </div>
        <div className="glass-card p-6 border-l-4 border-warning flex items-center gap-4">
          <div className="p-4 bg-warning/20 rounded-full">
            <AlertTriangle size={32} className="text-warning" />
          </div>
          <div>
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider">Active Warnings</h3>
            <p className="text-2xl font-bold text-white">{warningAlertsCount} Detected</p>
          </div>
        </div>
        <div className="glass-card p-6 border-l-4 border-danger flex items-center gap-4">
          <div className="p-4 bg-danger/20 rounded-full">
            <Activity size={32} className="text-danger" />
          </div>
          <div>
            <h3 className="text-muted text-sm font-medium uppercase tracking-wider">Critical Alerts</h3>
            <p className="text-2xl font-bold text-white">{criticalAlertsCount} Detected</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-6">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <ShieldCheck className="text-primary" size={20} /> Generator Health & Status
          </h2>
          {dashboardData?.generators?.map((item) => (
            <div key={item.id} className="glass-card p-6 hover:bg-slate-800/40 transition-colors">
              <div className="flex justify-between items-start mb-4">
                <div>
                  <h3 className="text-lg font-bold text-white">{item.building_name || 'Unassigned'}</h3>
                  <p className="text-muted">{item.name} {item.model ? `(${item.model})` : ''}</p>
                </div>
                {item.health_score >= 80 && (
                  <span className="px-3 py-1 bg-success/20 text-success rounded-full text-xs font-bold uppercase tracking-wide border border-success/30 flex items-center gap-1">
                    <CheckCircle2 size={14} /> Excellent (Score: {item.health_score})
                  </span>
                )}
                {item.health_score >= 50 && item.health_score < 80 && (
                  <span className="px-3 py-1 bg-warning/20 text-warning rounded-full text-xs font-bold uppercase tracking-wide border border-warning/30 flex items-center gap-1">
                    <AlertTriangle size={14} /> Warning (Score: {item.health_score})
                  </span>
                )}
                {item.health_score < 50 && (
                  <span className="px-3 py-1 bg-danger/20 text-danger rounded-full text-xs font-bold uppercase tracking-wide border border-danger/30 flex items-center gap-1">
                    <AlertTriangle size={14} /> Critical (Score: {item.health_score})
                  </span>
                )}
              </div>
              
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-6 border-t border-slate-700/50 pt-4">
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Efficiency</p>
                  <p className="text-lg font-bold text-white flex items-center gap-1"><Zap size={14} className="text-primary"/> {item.efficiency_score}%</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Reliability</p>
                  <p className="text-lg font-bold text-white">{item.reliability_score}%</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">{t('generator.fuel_accuracy')}</p>
                  <p className="text-lg font-bold text-white">{item.fuel_accuracy_score}%</p>
                </div>
                <div>
                  <p className="text-xs text-muted uppercase tracking-wider">Current Fuel</p>
                  <p className={`text-lg font-bold ${item.current_fuel < (item.min_fuel_level_alert || 50) ? 'text-danger' : 'text-success'}`}>{item.current_fuel} L</p>
                </div>
              </div>
            </div>
          ))}
          {(!dashboardData?.generators || dashboardData.generators.length === 0) && (
            <p className="text-muted italic">No generators found.</p>
          )}
        </div>

        {/* Right Col: Live Alerts */}
        <div className="space-y-6">
          <h2 className="text-xl font-bold text-white flex items-center gap-2">
            <AlertTriangle className="text-danger" size={20} /> Active Alerts
          </h2>
          <div className="space-y-4 max-h-[70vh] overflow-y-auto pr-2 hide-scrollbar">
            {alertsData?.filter(a => a.status !== 'Resolved').map((alert) => (
              <div key={alert.id} className={`glass-card p-5 border-l-4 ${alert.severity === 'Critical' ? 'border-danger' : 'border-warning'}`}>
                <div className="flex justify-between items-start mb-2">
                  <h4 className="font-bold text-white">{alert.alert_type}</h4>
                  <span className="text-xs text-muted">{new Date(alert.created_at).toLocaleDateString()}</span>
                </div>
                <p className="text-sm text-slate-300 mb-3">{alert.message}</p>
                
                {/* AI Investigation Report */}
                {alert.probabilities && <AIInvestigationReport alert={alert} />}

                <div className="flex justify-between items-center mt-4 border-t border-slate-700/50 pt-3">
                  <span className="text-xs font-medium text-muted">{alert.building_name}</span>
                  <button 
                    onClick={() => resolveAlertMutation.mutate(alert.id)}
                    disabled={resolveAlertMutation.isLoading}
                    className="text-xs bg-slate-800 hover:bg-slate-700 text-white px-3 py-1.5 rounded transition-colors border border-slate-700"
                  >
                    Mark Resolved
                  </button>
                </div>
              </div>
            ))}
            {(!alertsData || alertsData.filter(a => a.status !== 'Resolved').length === 0) && (
              <div className="glass-card p-6 text-center">
                <CheckCircle2 size={48} className="text-success/50 mx-auto mb-4" />
                <p className="text-muted">No active alerts. System looks healthy.</p>
              </div>
            )}
          </div>
        </div>

      </div>
    </div>
  );
};

export default GeneratorMonitoring;
