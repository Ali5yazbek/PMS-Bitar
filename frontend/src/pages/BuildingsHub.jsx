import React from 'react';
import { Building, Home, Users, FileSignature } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const BuildingsHub = () => {
  const navigate = useNavigate();

  const widgets = [
    {
      title: 'Buildings List',
      icon: Building,
      path: '/buildings/list', // Just an example path
      isActive: true,
    },
    {
      title: 'Apartments',
      icon: Home,
      path: '/apartments',
    },
    {
      title: 'Tenants',
      icon: Users,
      path: '/tenants',
    },
    {
      title: 'Contracts',
      icon: FileSignature,
      path: '/contracts',
    },
  ];

  return (
    <div className="h-full bg-[#131722] text-white flex flex-col font-sans">
      {/* Main Content */}
      <main className="flex-1 p-8 flex flex-col mx-auto w-full">
        {/* Breadcrumb */}
        <div className="flex items-center gap-2 text-sm mb-8 px-2">
          <span className="text-slate-400 hover:text-white cursor-pointer transition-colors" onClick={() => navigate('/')}>Home</span>
          <span className="text-slate-600">&gt;</span>
          <span className="text-slate-200">Buildings</span>
        </div>

        {/* CSS Grid with forced 1:1 aspect ratio */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 md:gap-8 w-full max-w-3xl mx-auto">
          {widgets.map((widget, idx) => {
            const Icon = widget.icon;
            return (
              <div 
                key={idx}
                onClick={() => navigate(widget.path)}
                className={`
                  aspect-square rounded-[32px] flex flex-col items-center justify-center gap-6 cursor-pointer
                  transition-all duration-300 hover:scale-[1.02] active:scale-[0.98]
                  ${widget.isActive 
                    ? 'bg-gradient-to-br from-[#2a2d45] to-[#1e2235] border border-indigo-500/50 shadow-[0_0_30px_-5px_rgba(99,102,241,0.3)]' 
                    : 'bg-[#1e2235] border border-transparent hover:border-white/5 shadow-xl shadow-black/20'
                  }
                `}
              >
                <div className={`
                  transition-colors duration-300
                  ${widget.isActive ? 'text-white drop-shadow-[0_0_15px_rgba(255,255,255,0.5)]' : 'text-slate-400'}
                `}>
                  <Icon size={80} strokeWidth={1.5} />
                </div>
                <h3 className={`
                  text-2xl font-bold tracking-wide
                  ${widget.isActive ? 'text-white' : 'text-slate-400'}
                `}>
                  {widget.title}
                </h3>
              </div>
            );
          })}
        </div>
      </main>
    </div>
  );
};

export default BuildingsHub;
