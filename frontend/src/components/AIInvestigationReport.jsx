import { useTranslation } from 'react-i18next';
import React from 'react';
import { AlertTriangle, Info, TrendingDown, Target, HelpCircle } from 'lucide-react';

const AIInvestigationReport = ({ alert }) => {
  const { t } = useTranslation();

  let probabilities = null;
  try {
    if (alert.probabilities) {
      probabilities = JSON.parse(alert.probabilities);
    }
  } catch (e) {}

  if (!probabilities) return null;

  // Render the probability bars
  const total = Object.values(probabilities).reduce((acc, val) => acc + val, 0) || 100;

  return (
    <div className="mt-4 p-4 bg-slate-900 rounded-xl border border-slate-700">
      <h5 className="text-sm font-bold text-indigo-300 flex items-center gap-2 mb-3">
        <Target size={16} /> {t('aiinvestigationreport.ai_investigation_analysis', { defaultValue: `AI Investigation Analysis` })}
      </h5>
      <div className="space-y-3">
        {Object.entries(probabilities).map(([cause, prob]) => {
          const percentage = (prob / total) * 100;
          let colorClass = 'bg-primary';
          if (cause.includes('Theft') || cause.includes('Leakage')) colorClass = 'bg-danger';
          if (cause.includes('Degradation') || cause.includes('Manipulation')) colorClass = 'bg-warning';
          
          return (
            <div key={cause}>
              <div className="flex justify-between text-xs mb-1">
                <span className="text-slate-300 font-medium">{cause.replace(/_/g, ' ')}</span>
                <span className="text-white font-bold">{Math.round(percentage)}%</span>
              </div>
              <div className="w-full bg-slate-800 rounded-full h-1.5">
                <div className={`${colorClass} h-1.5 rounded-full`} style={{ width: `${percentage}%` }}></div>
              </div>
            </div>
          );
        })}
      </div>
      <div className="mt-4 pt-3 border-t border-slate-800 flex gap-2">
        <Info size={14} className="text-muted shrink-0 mt-0.5" />
        <p className="text-xs text-muted leading-relaxed">
          <strong>{t('aiinvestigationreport.recommended_action', { defaultValue: `Recommended Action:` })}</strong> {t('aiinvestigationreport.based_on_the_behavioral_profil', { defaultValue: `Based on the behavioral profile, please inspect the physical tank level immediately and check for signs of` })} {Object.keys(probabilities)[0].toLowerCase().replace(/_/g, ' ')}.
        </p>
      </div>
    </div>
  );
};

export default AIInvestigationReport;
