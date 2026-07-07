const fs = require('fs');
const path = require('path');

const filesToProcess = [
  'c:/xampp/htdocs/Bitar/frontend/src/pages/EnergyManagement.jsx',
  'c:/xampp/htdocs/Bitar/frontend/src/pages/GeneratorDashboard.jsx',
  'c:/xampp/htdocs/Bitar/frontend/src/pages/GeneratorMonitoring.jsx',
  'c:/xampp/htdocs/Bitar/frontend/src/pages/FuelReserve.jsx'
];

// Replaces using exact strings
filesToProcess.forEach(file => {
  if (!fs.existsSync(file)) return;
  let content = fs.readFileSync(file, 'utf8');

  // Check if already using useTranslation
  if (!content.includes('useTranslation')) {
    content = content.replace(/import React(?:, \{[^}]*\})? from 'react';/, match => match + "\nimport { useTranslation } from 'react-i18next';");
  }

  // Inject const { t } = useTranslation();
  if (!content.includes('const { t } = useTranslation();')) {
    // Look for the component definition
    content = content.replace(/(const \w+ = \([^)]*\) => \{\n)/, "$1  const { t } = useTranslation();\n");
  }

  // Replacing common strings for energy and generator
  const replacements = {
    // EnergyManagement
    "AI Generator Management": "{t('energy.title')}",
    "Enterprise fleet tracking, predictive maintenance, and fuel analysis": "{t('energy.subtitle')}",
    "Add Daily Reading": "{t('energy.add_reading')}",
    "Export Excel": "{t('energy.export_excel')}",
    "Print PDF": "{t('energy.print_pdf')}",
    "Total Fuel Consumed": "{t('energy.total_fuel')}",
    "Total Fuel Cost": "{t('energy.total_cost')}",
    "Total Energy Produced": "{t('energy.total_energy')}",
    "Current Fleet Fuel": "{t('energy.current_fleet')}",
    "Last 30 Days": "{t('energy.last_30')}",
    "Estimated (30 Days)": "{t('energy.est_30')}",
    "Fleet Status": "{t('energy.fleet_status')}",
    "Fleet Fuel Consumption (30 Days)": "{t('energy.fleet_fuel_chart')}",
    "Fleet Energy Production (30 Days)": "{t('energy.fleet_energy_chart')}",
    "AI Engine": "{t('energy.ai_engine')}",
    "Live Analysis": "{t('energy.live_analysis')}",
    "Daily Briefing": "{t('energy.daily_briefing')}",
    "Weekly Report": "{t('energy.weekly_report')}",
    "Generating daily summary...": "{t('energy.generating_daily')}",
    "Generating weekly report...": "{t('energy.generating_weekly')}",
    "Select a Generator": "{t('energy.select_generator')}",
    "Smart OCR: Upload Photo of Meter": "{t('energy.smart_ocr')}",
    "Current Engine Hours": "{t('energy.current_hours')}",
    "Current Meter (kWh)": "{t('energy.current_meter')}",
    "Notes / Observations": "{t('energy.notes')}",
    "Submit Reading": "{t('energy.submit')}",
    
    // GeneratorDashboard
    "Dashboard Overview": "{t('generator.dashboard')}",
    "Overview & AI Analytics": "{t('generator.tab_overview')}",
    "Fuel Management (Enterprise)": "{t('generator.tab_fuel')}",
    "Current Estimated Fuel": "{t('generator.current_est')}",
    "Tell Me Actual Remaining Fuel": "{t('generator.tell_actual')}",
    "Latest Reading Verified": "{t('generator.latest_verified')}",
    "Liters": "{t('generator.liters')}",
    "Spare Reserve": "{t('generator.spare')}",
    "kWh Today": "{t('generator.kwh_today')}",
    "Efficiency Score": "{t('generator.efficiency')}",
    "kWh per Liter (Month)": "{t('generator.kwh_per_l')}",
    "Fuel Usage vs Production (Last 14 Days)": "{t('generator.usage_vs_prod')}",
    "Recent Daily Reports": "{t('generator.recent_reports')}",
    "Run Time": "{t('generator.th_run')}",
    "Est. Used (L)": "{t('generator.th_est')}",
    "Actual Used (L)": "{t('generator.th_actual')}",
    "Score (kWh/L)": "{t('generator.th_score')}",
    "View / Edit": "{t('generator.view_edit')}",
    "Fuel Movement Audit": "{t('generator.fuel_audit')}",
    "Record Movement": "{t('generator.record_movement')}",
    "No fuel movements recorded yet.": "{t('generator.no_fuel')}",
    "System Analytics": "{t('generator.system_analytics')}",
    "Enterprise Health": "{t('generator.enterprise_health')}",
    "Health Score": "{t('generator.health_score')}",
    "Fuel Accuracy": "{t('generator.fuel_accuracy')}",
    "Fuel Estimations": "{t('generator.fuel_estimations')}",
    "Avg. Daily Fuel": "{t('generator.avg_daily')}",
    "Est. Remaining Days": "{t('generator.est_days')}",
    "Fuel Needed (Next Mo.)": "{t('generator.fuel_needed')}",
    "System Recommendation": "{t('generator.sys_rec')}",
    "Electricity Projections": "{t('generator.elec_proj')}",
    "Next Week": "{t('generator.next_week')}",
    "Next Month": "{t('generator.next_month')}",
    "AI Report Analysis": "{t('generator.verify_title')}",
    "Review employee reading and verify fuel": "{t('generator.verify_sub')}",
    "Meter Readings": "{t('generator.meter_readings')}",
    "Performance & System": "{t('generator.performance')}",
    "What is the Actual Fuel Liter Remaining in the tank?": "{t('generator.actual_prompt')}",
    "Verify & Update Fuel": "{t('generator.btn_verify')}",
    "No Generator Found": "{t('generator.no_generator')}",
    "Register Enterprise Generator": "{t('generator.register_title')}",
    "Back to Buildings": "{t('generator.back')}"
  };

  for (const [key, val] of Object.entries(replacements)) {
    // Replace text between > and <
    const regex1 = new RegExp('>' + key + '<', 'g');
    content = content.replace(regex1, '>' + val + '<');
    
    // Also replace standalone instances if they are in span or other places carefully
    // For attributes we might need {t('key')} or just t('key')
    // We'll leave attributes manual to avoid breaking code unless explicitly matched.
  }
  
  // Specific complex replaces
  content = content.replace(/generator\?\.name \|\| 'Generator'/g, "generator?.name || t('energy.generator')");
  content = content.replace(/placeholder="e\.g\. Main Diesel Gen"/g, "placeholder={t('generator.name')}");
  content = content.replace(/placeholder="Hours"/g, "placeholder={t('generator.init_hours')}");
  
  // Some standard buttons like Save, Cancel
  content = content.replace(/>Cancel</g, ">{t('generator.cancel')}<");
  content = content.replace(/>Delete Generator</g, ">{t('generator.delete')}<");

  fs.writeFileSync(file, content, 'utf8');
  console.log('Translated: ' + path.basename(file));
});
