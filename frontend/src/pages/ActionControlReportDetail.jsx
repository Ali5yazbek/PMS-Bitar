import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Printer, Shield, Users, Check, X as XIcon, Activity } from 'lucide-react';
import api from '../api/axios';

const EXPECTED_FIELDS = {
  profile: ['Name', 'Email', 'Phone', 'National ID', 'Address'],
  tenants: ['Name', 'Phone', 'National ID', 'Passport', 'Email'],
  contracts: ['Start Date', 'End Date', 'Contract PDF'],
  apartments: ['Owner', 'Building', 'Images'],
  workshops: ['Name', 'License', 'Tools'],
  generators: ['Serial', 'Daily Report'],
  maintenance: ['Task Assignee', 'Parts Used'],
  warehouse: ['Inventory Log', 'Receipts']
};

const MODULE_LABELS = {
  profile: 'Profile',
  tenants: 'Tenant',
  contracts: 'Contracts',
  apartments: 'Apartment',
  workshops: 'Workshop',
  generators: 'Generator',
  maintenance: 'Maintenance',
  warehouse: 'Warehouse'
};

export default function ActionControlReportDetail({
  employee, onBack
}) {
  const [isPrinting, setIsPrinting] = useState(false);

  const { data, isLoading } = useQuery({
    queryKey: ['acr-employee-full', employee.employee_id],
    queryFn: async () => (await api.get(`/action-control/reports/${employee.employee_id}`)).data,
  });

  const handlePrint = () => {
    setIsPrinting(true);
    setTimeout(() => {
      window.print();
      setIsPrinting(false);
    }, 500);
  };

  if (isLoading) return <div className="p-10 text-center text-slate-500 animate-pulse">Loading Audit Profile...</div>;

  const emp = data?.employee || employee;
  const reportsRaw = data?.modules || {};
  
  // Flatten reports
  const allProblems = Object.values(reportsRaw).flat();
  const critical = allProblems.filter(r => r.severity === 'critical').length;
  const warning = allProblems.filter(r => r.severity === 'warning').length;
  const info = allProblems.filter(r => r.severity === 'info').length;
  const total = allProblems.length;

  let healthScore = 100;
  let recommendations = [];

  // Group by module for the audit checklist
  const auditModules = { ...EXPECTED_FIELDS };
  Object.keys(reportsRaw).forEach(mod => {
    if (!auditModules[mod]) auditModules[mod] = []; // ensure module exists if problem exists
  });

  const getProblemsForModule = (mod) => reportsRaw[mod] || [];

  // Calculate Health Score and build Recommendations dynamically
  allProblems.forEach(p => {
    if (p.severity === 'critical') healthScore -= 15;
    else if (p.severity === 'warning') healthScore -= 5;
    else healthScore -= 2;

    const desc = p.description.toLowerCase();
    if (desc.includes('missing') || desc.includes('not uploaded')) {
      recommendations.push(`Upload ${p.field_name.replace(/_/g, ' ')}`);
      if (p.severity === 'critical') healthScore -= 15;
    } else if (desc.includes('expired')) {
      recommendations.push(`Renew ${p.field_name.replace(/_/g, ' ')}`);
      healthScore -= 20;
    } else {
      recommendations.push(`Check ${p.field_name.replace(/_/g, ' ')} in ${p.table_name}`);
    }
  });

  healthScore = Math.max(0, healthScore);

  // De-duplicate recommendations
  recommendations = [...new Set(recommendations)].slice(0, 10);

  const initials = (emp.name || emp.employee_name || '?').split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);

  return (
    <div className={`space-y-6 ${isPrinting ? 'print-mode text-black bg-white' : 'text-slate-200'}`}>

      {/* Screen Header Toolbar (Hidden in Print) */}
      <div className="print:hidden flex items-center justify-between mb-6">
        <button onClick={onBack} className="flex items-center gap-2 text-indigo-400 hover:text-indigo-300 font-bold transition-colors">
           <ArrowLeft size={18} /> Back to Dashboard
        </button>
        <button onClick={handlePrint} className="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white px-5 py-2.5 rounded-xl font-bold shadow-lg shadow-indigo-500/20 transition-all">
           <Printer size={18} /> Print Audit Report
        </button>
      </div>

      {/* Print Header (Visible in Print) */}
      <div className="hidden print:block text-center border-b-2 border-black pb-4 mb-6">
         <h1 className="text-3xl font-black uppercase tracking-widest">Employee Action Control Report</h1>
      </div>

      {/* Hero Profile Block */}
      <div className="bg-slate-900/60 print:bg-white rounded-3xl p-6 border border-slate-700/50 print:border-black print:border-2 shadow-2xl flex flex-col md:flex-row gap-8 items-center md:items-start">
        <div className="w-32 h-32 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 print:bg-gray-200 flex items-center justify-center text-4xl font-black text-white print:text-black shadow-inner shrink-0 border-4 border-slate-800 print:border-black">
          {initials}
        </div>
        <div className="flex-1 text-center md:text-left space-y-2">
          <h2 className="text-4xl font-black print:text-black">{emp.name || emp.employee_name}</h2>
          <div className="flex flex-wrap items-center justify-center md:justify-start gap-4 text-sm font-bold text-slate-400 print:text-gray-700 uppercase tracking-wider">
             <span className="flex items-center gap-1.5 bg-slate-800/50 print:bg-transparent print:border print:border-gray-300 px-3 py-1.5 rounded-lg"><Shield size={16}/> {emp.role || emp.employee_role}</span>
             <span className="flex items-center gap-1.5 bg-slate-800/50 print:bg-transparent print:border print:border-gray-300 px-3 py-1.5 rounded-lg"><Users size={16}/> {emp.department || 'Property'}</span>
             <span className="flex items-center gap-1.5 bg-slate-800/50 print:bg-transparent print:border print:border-gray-300 px-3 py-1.5 rounded-lg text-emerald-400 print:text-green-600"><Activity size={16}/> Online</span>
          </div>
        </div>
        <div className="bg-slate-950/50 print:bg-gray-100 p-6 rounded-2xl border border-slate-700 print:border-black text-center min-w-[160px]">
          <div className="text-xs font-black uppercase tracking-widest text-slate-500 print:text-gray-600 mb-2">Health Score</div>
          <div className={`text-5xl font-black ${healthScore === 100 ? 'text-emerald-400' : healthScore >= 75 ? 'text-orange-400' : 'text-red-500'}`}>
            {healthScore}%
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        {/* Left Column: Summary & Recommendations */}
        <div className="space-y-6">
          <div className="bg-slate-900/60 print:bg-white rounded-2xl p-6 border border-slate-700/50 print:border-black shadow-xl">
             <h3 className="text-xl font-black border-b border-slate-700 print:border-black pb-4 mb-4 flex items-center gap-2">SUMMARY</h3>
             <div className="space-y-4">
                <div className="flex justify-between items-center text-lg font-bold border-b border-slate-700/50 print:border-gray-300 pb-2">
                  <span className="text-slate-400 print:text-black">Problems</span>
                  <span className="text-white print:text-black">{total}</span>
                </div>
                <div className="flex justify-between items-center font-bold">
                  <span className="text-slate-500 print:text-gray-600">Critical</span>
                  <span className="text-red-400 print:text-red-600">{critical}</span>
                </div>
                <div className="flex justify-between items-center font-bold">
                  <span className="text-slate-500 print:text-gray-600">Warnings</span>
                  <span className="text-yellow-400 print:text-yellow-600">{warning}</span>
                </div>
                <div className="flex justify-between items-center font-bold">
                  <span className="text-slate-500 print:text-gray-600">Information</span>
                  <span className="text-blue-400 print:text-blue-600">{info}</span>
                </div>
             </div>
          </div>

          <div className="bg-slate-900/60 print:bg-white rounded-2xl p-6 border border-slate-700/50 print:border-black shadow-xl">
             <h3 className="text-xl font-black border-b border-slate-700 print:border-black pb-4 mb-4">RECOMMENDATIONS</h3>
             {recommendations.length > 0 ? (
               <ol className="space-y-3 font-bold text-slate-300 print:text-black list-decimal list-inside">
                 {recommendations.map((rec, i) => (
                   <li key={i} className="capitalize">{rec}</li>
                 ))}
               </ol>
             ) : (
               <p className="font-bold text-emerald-400 print:text-green-600">No actions required. Employee is fully compliant.</p>
             )}
          </div>
        </div>

        {/* Right Column: Module Audit Tree */}
        <div className="lg:col-span-2 space-y-6">
          <div className="bg-slate-900/60 print:bg-white rounded-2xl p-6 border border-slate-700/50 print:border-black shadow-xl">
             <h3 className="text-xl font-black border-b border-slate-700 print:border-black pb-4 mb-6">MODULE AUDIT</h3>
             
             <div className="space-y-8">
               {Object.entries(auditModules).map(([modKey, expectedFields]) => {
                 const problems = getProblemsForModule(modKey);
                 // We don't want to show empty modules if they are not core, but let's show Tenant, Contracts, Workshop, Generator at least
                 if (problems.length === 0 && !['tenants', 'contracts', 'apartments', 'workshops', 'generators'].includes(modKey)) return null;

                 const problemFields = problems.map(p => p.field_name.toLowerCase().replace(/_/g, ' '));

                 return (
                   <div key={modKey}>
                     <div className="flex items-center justify-between mb-3">
                       <h4 className="text-lg font-black text-indigo-300 print:text-black uppercase tracking-wider">{MODULE_LABELS[modKey] || modKey}</h4>
                       {problems.length > 0 && <span className="text-xs font-bold bg-red-500/20 print:bg-transparent print:text-red-600 text-red-400 px-2 py-1 rounded">{problems.length} Problems</span>}
                     </div>
                     <div className="space-y-2 font-bold text-sm">
                       {/* Render expected fields and check if they have problems */}
                       {expectedFields.map(ef => {
                         const efLower = ef.toLowerCase();
                         const hasProblem = problemFields.some(pf => pf.includes(efLower) || efLower.includes(pf));
                         if (hasProblem) {
                           // Find the actual problem text
                           const specificProblem = problems.find(p => p.field_name.toLowerCase().replace(/_/g, ' ').includes(efLower) || efLower.includes(p.field_name.toLowerCase().replace(/_/g, ' ')));
                           return (
                             <div key={ef} className="flex items-start gap-3 text-red-400 print:text-red-600">
                               <XIcon size={18} className="mt-0.5 shrink-0" />
                               <span>{ef} {specificProblem && `- ${specificProblem.description}`}</span>
                             </div>
                           );
                         } else {
                           return (
                             <div key={ef} className="flex items-center gap-3 text-emerald-400 print:text-green-600">
                               <Check size={18} />
                               <span className="text-slate-300 print:text-black">{ef}</span>
                             </div>
                           );
                         }
                       })}

                       {/* Render any additional unexpected problems in this module */}
                       {problems.filter(p => !expectedFields.some(ef => p.field_name.toLowerCase().replace(/_/g, ' ').includes(ef.toLowerCase()) || ef.toLowerCase().includes(p.field_name.toLowerCase().replace(/_/g, ' ')))).map((p, i) => (
                         <div key={`extra-${i}`} className="flex items-start gap-3 text-red-400 print:text-red-600 capitalize">
                           <XIcon size={18} className="mt-0.5 shrink-0" />
                           <span>{p.field_name.replace(/_/g, ' ')} - {p.description}</span>
                         </div>
                       ))}

                       {problems.length === 0 && (
                         <div className="flex items-center gap-3 text-emerald-400 print:text-green-600 italic">
                           <Check size={18} />
                           <span>Everything Complete</span>
                         </div>
                       )}
                     </div>
                     <div className="my-4 border-b border-slate-700/50 print:border-gray-300 border-dashed" />
                   </div>
                 );
               })}
             </div>
          </div>
        </div>

      </div>
    </div>
  );
}
