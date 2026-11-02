import React from 'react';
import { LayoutDashboard, Calendar, Building, FileText, HardHat, ShoppingCart, Zap, Settings } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

const HomeHub = () => {
  const navigate = useNavigate();

  const widgets = [
    {
      title: 'Dashboard',
      icon: LayoutDashboard,
      path: '/dashboard',
      isActive: true,
    },
    {
      title: 'Schedule Center',
      icon: Calendar,
      path: '/schedule',
    },
    {
      title: 'Buildings',
      icon: Building,
      path: '/buildings',
    },
    {
      title: 'Reports',
      icon: FileText,
      path: '/reports',
    },
    {
      title: 'Workshop',
      icon: HardHat,
      path: '/workshop',
    },
    {
      title: 'Sales',
      icon: ShoppingCart,
      path: '/sales',
    },
    {
      title: 'Modules',
      icon: Zap,
      path: '/modules',
    },
    {
      title: 'Admin Tools',
      icon: Settings,
      path: '/global-settings',
    },
  ];

  return (
    <div className="h-full bg-[#131722] text-white flex flex-col font-sans">
      <main className="flex-1 p-8 flex flex-col mx-auto w-full max-w-6xl">
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6 w-full">
          {widgets.map((widget, idx) => {
            const Icon = widget.icon;
            return (
              <div 
                key={idx}
                onClick={() => navigate(widget.path)}
                className={`
                  aspect-square rounded-[24px] flex flex-col items-center justify-center gap-4 cursor-pointer
                  transition-all duration-300 hover:scale-[1.02] active:scale-[0.98]
                  ${widget.isActive 
                    ? 'bg-gradient-to-br from-[#6366f1] to-[#4f46e5] border border-indigo-400/50 shadow-[0_0_40px_-10px_rgba(99,102,241,0.5)]' 
                    : 'bg-[#1e2235] border border-transparent hover:border-white/5 shadow-xl shadow-black/20'
                  }
                `}
              >
                <div className={`
                  transition-colors duration-300
                  ${widget.isActive ? 'text-white' : 'text-slate-400'}
                `}>
                  <Icon size={48} md={64} strokeWidth={1.5} className="w-12 h-12 md:w-16 md:h-16" />
                </div>
                <h3 className={`
                  text-lg md:text-xl font-bold tracking-wide text-center px-2
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

export default HomeHub;
