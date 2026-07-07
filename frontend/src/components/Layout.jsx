import React, { useState, useEffect } from 'react';
import { Outlet, NavLink, useNavigate, useLocation } from 'react-router-dom';
import { useQuery, useQueryClient, useMutation } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import axios from '../api/axios';
import { 
  LayoutDashboard, Building, Home, Users, DollarSign, 
  Shield, HardHat, Archive, ShoppingCart, CreditCard, 
  FileText, Settings, LogOut, ChevronDown, ChevronRight,
  Briefcase, Activity, Zap, Calendar, Bell, CheckCircle,
  AlertCircle, Fuel, Menu, X, FileCheck2, Truck, BarChart2
} from 'lucide-react';
import ExpiryAlertsModal from './ExpiryAlertsModal';

const Layout = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const queryClient = useQueryClient();

  // ── Mobile sidebar open/close ──────────────────────────────────────────────
  const [isMobileOpen, setIsMobileOpen] = useState(false);

  // Expiry Alerts Modal State
  const [isExpiryModalOpen, setIsExpiryModalOpen] = useState(false);
  const [hasShownExpiryModal, setHasShownExpiryModal] = useState(false);

  // Close mobile sidebar on route change
  useEffect(() => {
    setIsMobileOpen(false);
  }, [location.pathname]);

  // ── Dropdown states ────────────────────────────────────────────────────────
  const [isBuildingsOpen, setIsBuildingsOpen] = useState(
    location.pathname.startsWith('/buildings') ||
    location.pathname.startsWith('/apartments') ||
    location.pathname.startsWith('/tenants') ||
    location.pathname.startsWith('/contracts')
  );

  const [isReportsOpen, setIsReportsOpen] = useState(
    location.pathname.startsWith('/apartment-costs') ||
    location.pathname.startsWith('/financial-buildings-report') ||
    location.pathname.startsWith('/rent-hub') ||
    location.pathname.startsWith('/financial-reports')
  );

  const [isWorkshopOpen, setIsWorkshopOpen] = useState(
    location.pathname.startsWith('/constructions') ||
    location.pathname.startsWith('/workshop') ||
    location.pathname.startsWith('/settings')
  );

  const [isCommerceOpen, setIsCommerceOpen] = useState(
    location.pathname.startsWith('/depot') ||
    location.pathname.startsWith('/pos') ||
    location.pathname.startsWith('/sales')
  );

  const [user] = useState(() => {
    try { return JSON.parse(localStorage.getItem('user')); }
    catch (e) { return null; }
  });

  const role = user?.role || 'manager';

  const handleLogout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    navigate('/login');
  };

  const { data: pendingTasks } = useQuery({
    queryKey: ['adminPendingTasks'],
    queryFn: async () => (await axios.get('/maintenance/admin/tasks')).data,
    refetchInterval: 10000,
    enabled: role === 'admin' || role === 'manager',
  });

  const { data: notifications } = useQuery({
    queryKey: ['globalNotifications'],
    queryFn: async () => (await axios.get('/schedule/notifications')).data,
    refetchInterval: 10000,
    enabled: role === 'admin' || role === 'manager',
  });

  const { data: dbUnreadNotifications } = useQuery({
    queryKey: ['dbUnreadNotifications'],
    queryFn: async () => (await axios.get('/notifications/unread')).data,
    refetchInterval: 10000,
    enabled: role === 'admin' || role === 'manager',
  });

  const { data: expiringItems } = useQuery({
    queryKey: ['globalExpiringItems'],
    queryFn: async () => (await axios.get('/dashboard/expiring-items')).data,
    refetchInterval: 60000,
    enabled: role === 'admin' || role === 'manager',
  });

  useEffect(() => {
    if (expiringItems?.length > 0 && !hasShownExpiryModal) {
      setIsExpiryModalOpen(true);
      setHasShownExpiryModal(true);
    }
  }, [expiringItems, hasShownExpiryModal]);

  // ── Agent: subscription tasks expiring soon ────────────────────────────────
  const { data: agentSubTasks } = useQuery({
    queryKey: ['agent_sub_tasks_count'],
    queryFn: async () => {
      try {
        const res = await axios.get('/energy/agent/subscription-tasks');
        const tasks = res.data?.tasks || [];
        // Count only tasks that still need agent action (no pending submission)
        return tasks.filter(t => !t.latest_submission_status || t.latest_submission_status === 'Rejected').length;
      } catch (e) { return 0; }
    },
    refetchInterval: 30000,
    enabled: role === 'agent',
  });
  const agentSubTaskCount = agentSubTasks || 0;

  const markNotifReadMutation = useMutation({
    mutationFn: (id) => axios.post(`/notifications/${id}/read`),
    onSuccess: () => {
      queryClient.invalidateQueries(['dbUnreadNotifications']);
    }
  });

  const handleRemindLater = (notifId) => {
    localStorage.setItem(`hideNotif_${notifId}`, Date.now() + 24 * 60 * 60 * 1000);
    // Force re-render to hide
    queryClient.invalidateQueries(['dbUnreadNotifications']);
  };

  const activeTenantResponses = dbUnreadNotifications?.filter(n => {
    if (n.type !== 'tenant_renewal_response') return false;
    const hideUntil = localStorage.getItem(`hideNotif_${n.id}`);
    if (hideUntil && parseInt(hideUntil) > Date.now()) return false;
    return true;
  }) || [];

  const changeLanguage = (lng) => i18n.changeLanguage(lng);

  // ── Nav data ───────────────────────────────────────────────────────────────
  let mainNavItems = [];
  let buildingSubItems = [];
  let workshopSubItems = [];
  let commerceSubItems = [];
  let reportsSubItems = [];
  let otherNavItems = [];

  if (role === 'cashier') {
    mainNavItems = [{ name: t('sidebar.pos'), path: '/pos', icon: ShoppingCart }];
  } else if (role === 'maintenance') {
    mainNavItems = [{ name: t('sidebar.ac_maintenance'), path: '/maintenance', icon: LayoutDashboard }];
  } else if (role === 'tenant') {
    mainNavItems = [
      { name: 'My Dashboard', path: '/tenant-dashboard', icon: LayoutDashboard },
      { name: 'My Contract', path: '/tenant-contract', icon: FileText },
      { name: 'My Payments', path: '/tenant-payments', icon: DollarSign },
      { name: 'My Subscriptions', path: '/tenant-subscriptions', icon: Zap }
    ];
  } else if (role === 'agent') {
    mainNavItems = [
      { name: 'Agent Dashboard', path: '/agent-dashboard', icon: LayoutDashboard },
      { name: 'Subscription Tasks', path: '/agent-subscriptions', icon: Zap, redDot: agentSubTaskCount > 0, redDotCount: agentSubTaskCount },
      { name: 'Building Generators', path: '/agent-generators', icon: Activity },
      { name: 'Apartment Readings', path: '/agent-apartments', icon: Home },
      { name: 'Reading History', path: '/agent-history', icon: FileText },
      { name: 'Submit Daily Report', path: '/agent-daily-report', icon: FileCheck2 },
    ];

  } else {
    mainNavItems = [
      { name: t('sidebar.dashboard'), path: '/', icon: LayoutDashboard },
      { name: t('sidebar.schedule_center'), path: '/schedule', icon: Calendar },
    ];
    buildingSubItems = [
      { name: t('sidebar.buildings_list'), path: '/buildings', icon: Building },
      { name: t('sidebar.apartments'), path: '/apartments', icon: Home },
      { name: t('sidebar.tenants'), path: '/tenants', icon: Users },
      { name: 'Contracts', path: '/contracts', icon: FileText },
    ];
    reportsSubItems = [
      { name: t('sidebar.apartment_cost_report', 'Apartment Cost Report'), path: '/apartment-costs', icon: DollarSign },
      { name: 'Financial Building Report', path: '/financial-buildings-report', icon: FileText },
      { name: 'Financial Reports', path: '/financial-reports', icon: BarChart2 },
      { name: 'Insurance Hub', path: '/rent-hub', icon: Shield },
    ];
    workshopSubItems = [
      { name: t('sidebar.construction'), path: '/constructions', icon: Briefcase },
      { name: t('sidebar.workshop'), path: '/workshop', icon: HardHat },
      { name: 'Suppliers', path: '/suppliers', icon: Truck },
      { name: 'Purchase Orders', path: '/purchase-orders', icon: FileCheck2 },
      { name: t('sidebar.workshop_pricing'), path: '/settings', icon: Settings },
    ];
    commerceSubItems = [
      { name: t('sidebar.warehouse'), path: '/depot', icon: Archive },
      { name: 'Stock Transfer', path: '/movement-transfer', icon: Truck },
      { name: t('sidebar.pos'), path: '/pos', icon: ShoppingCart },
      { name: t('sidebar.sales_history'), path: '/sales', icon: Activity },
    ];
    otherNavItems = [
      { name: t('sidebar.ac_maintenance'), path: '/maintenance-admin', icon: Shield, badge: pendingTasks?.length || 0 },
      { name: t('sidebar.energy'), path: '/energy', icon: Zap },
      { name: 'Readings Verification', path: '/energy/verification', icon: FileCheck2 },
      { name: 'Gen Sub Report', path: '/generator-subscriptions-report', icon: FileText },
      { name: 'Fuel Reserve', path: '/fuel-reserve', icon: Fuel },
      { name: t('sidebar.expenses'), path: '/expenses', icon: CreditCard },
      { name: t('sidebar.reports'), path: '/reports', icon: FileText },
    ];
    if (role === 'admin') {
      otherNavItems.unshift({ name: t('sidebar.user_management'), path: '/users', icon: Users });
      otherNavItems.push({ name: 'Global Settings', path: '/global-settings', icon: Settings });
    }
  }

  // ── Render helpers ─────────────────────────────────────────────────────────
  const renderNavItem = (item, isSubItem = false) => {
    const Icon = item.icon;
    const isActive = item.path === '/'
      ? location.pathname === '/'
      : location.pathname.startsWith(item.path);

    return (
      <NavLink
        key={item.path}
        to={item.path}
        className={`w-full flex items-center px-4 py-3 rounded-xl transition-all duration-200 ${
          item.redDot && !isActive
            ? 'text-white bg-danger/15 border border-danger/30 hover:bg-danger/25'
            : isActive
            ? 'bg-primary text-white shadow-lg shadow-primary/30'
            : 'text-muted hover:bg-cards hover:text-white'
        } ${isSubItem ? 'ps-10 text-sm' : ''}`}
      >
        <div className="relative me-3 shrink-0">
          <Icon
            size={isSubItem ? 17 : 21}
            className={item.redDot && !isActive ? 'text-danger' : ''}
            strokeWidth={isActive || item.redDot ? 2.5 : 2}
          />
          {/* Pulsing red dot indicator */}
          {item.redDot && (
            <span className="absolute -top-1.5 -right-1.5 flex h-3 w-3">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-danger opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-danger"></span>
            </span>
          )}
        </div>
        <span className={`font-medium flex-1 break-words leading-snug ${
          item.redDot && !isActive ? 'text-red-300' : isActive ? 'text-white' : ''
        }`}>
          {item.name}
        </span>
        {/* Numeric count badge */}
        {item.redDot && item.redDotCount > 0 && (
          <span className="bg-danger text-white text-xs font-bold px-2 py-0.5 rounded-full ms-2 shrink-0 shadow-lg shadow-danger/40">
            {item.redDotCount}
          </span>
        )}
        {!item.redDot && item.badge > 0 && (
          <span className="bg-danger text-white text-xs font-bold px-2 py-0.5 rounded-full ms-2 shrink-0 animate-pulse">
            {item.badge}
          </span>
        )}
      </NavLink>
    );
  };

  const renderDropdown = ({ label, icon: Icon, isOpen, setOpen, items }) => {
    const anyActive = items.some(item =>
      item.path === '/' ? location.pathname === '/' : location.pathname.startsWith(item.path)
    );
    return (
      <div className="pt-1">
        <button
          onClick={() => setOpen(!isOpen)}
          className={`w-full flex items-center justify-between px-4 py-3 rounded-xl transition-all duration-200 ${
            isOpen || anyActive ? 'text-white bg-slate-800/60' : 'text-muted hover:bg-cards hover:text-white'
          }`}
        >
          <div className="flex items-center">
            <Icon size={21} className="me-3 shrink-0" strokeWidth={isOpen || anyActive ? 2.5 : 2} />
            <span className="font-medium">{label}</span>
          </div>
          {isOpen
            ? <ChevronDown size={16} className="shrink-0" />
            : <ChevronRight size={16} className="shrink-0" />}
        </button>
        {isOpen && (
          <div className="mt-1 space-y-0.5 pb-1">
            {items.map(item => renderNavItem(item, true))}
          </div>
        )}
      </div>
    );
  };

  // ── Sidebar inner content (shared between desktop + mobile drawer) ─────────
  const SidebarContent = () => (
    <>
      {/* Logo */}
      <div className="flex items-center justify-between px-5 mb-6 shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center text-white font-bold text-lg shadow-lg shadow-primary/50 shrink-0">
            P
          </div>
          <span className="font-bold text-lg tracking-wide text-white">PMS System</span>
        </div>
        {/* Close button — mobile only */}
        <button
          className="lg:hidden p-1.5 text-slate-400 hover:text-white hover:bg-slate-800 rounded-lg transition-colors"
          onClick={() => setIsMobileOpen(false)}
        >
          <X size={20} />
        </button>
      </div>

      {/* Nav */}
      <nav className="flex-1 w-full px-3 overflow-y-auto hide-scrollbar space-y-0.5">
        {mainNavItems.map(item => renderNavItem(item))}

        {buildingSubItems.length > 0 && renderDropdown({
          label: t('sidebar.buildings'),
          icon: Building,
          isOpen: isBuildingsOpen,
          setOpen: setIsBuildingsOpen,
          items: buildingSubItems,
        })}

        {reportsSubItems.length > 0 && renderDropdown({
          label: 'Reports',
          icon: FileText,
          isOpen: isReportsOpen,
          setOpen: setIsReportsOpen,
          items: reportsSubItems,
        })}

        {workshopSubItems.length > 0 && renderDropdown({
          label: 'Workshop',
          icon: HardHat,
          isOpen: isWorkshopOpen,
          setOpen: setIsWorkshopOpen,
          items: workshopSubItems,
        })}

        {commerceSubItems.length > 0 && renderDropdown({
          label: 'Commerce',
          icon: ShoppingCart,
          isOpen: isCommerceOpen,
          setOpen: setIsCommerceOpen,
          items: commerceSubItems,
        })}

        {otherNavItems.length > 0 && (
          <div className="pt-3">
            <div className="text-xs font-semibold text-slate-600 uppercase tracking-wider mb-2 px-4">
              {t('sidebar.modules')}
            </div>
            {otherNavItems.map(item => renderNavItem(item))}
          </div>
        )}
      </nav>

      {/* Footer */}
      <div className="px-3 mt-3 pt-3 border-t border-slate-700/50 shrink-0">
        <select
          value={i18n.language}
          onChange={(e) => changeLanguage(e.target.value)}
          className="w-full bg-slate-800 border border-slate-700 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary mb-2"
        >
          <option value="en">{t('common.english')}</option>
          <option value="fr">{t('common.french')}</option>
          <option value="ar">{t('common.arabic')}</option>
        </select>
        <button
          onClick={handleLogout}
          className="w-full flex items-center px-4 py-2.5 rounded-xl text-danger hover:bg-danger/10 transition-all duration-200"
        >
          <LogOut size={20} className="me-3 shrink-0" />
          <span className="font-medium">{t('sidebar.logout')}</span>
        </button>
      </div>
    </>
  );

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div className="flex h-screen print:h-auto bg-background text-darktext overflow-hidden print:overflow-visible font-sans">

      {/* ── Desktop Sidebar (lg+) ─────────────────────────────────────────── */}
      <aside className="hidden lg:flex w-64 glass-sidebar flex-col py-5 print:hidden z-20 shrink-0">
        <SidebarContent />
      </aside>

      {/* ── Mobile Sidebar Drawer ─────────────────────────────────────────── */}
      {/* Backdrop */}
      {isMobileOpen && (
        <div
          className="fixed inset-0 bg-black/60 backdrop-blur-sm z-30 lg:hidden"
          onClick={() => setIsMobileOpen(false)}
        />
      )}
      {/* Drawer */}
      <aside
        className={`fixed top-0 left-0 h-full w-72 glass-sidebar flex flex-col py-5 z-40 lg:hidden transition-transform duration-300 ease-in-out print:hidden ${
          isMobileOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        <SidebarContent />
      </aside>

      {/* ── Main Content ──────────────────────────────────────────────────── */}
      <main className="flex-1 min-w-0 h-full print:h-auto flex flex-col overflow-hidden print:overflow-visible relative bg-background print:bg-white">

        {/* Top Bar */}
        {(role === 'admin' || role === 'manager' || role === 'cashier' || role === 'tenant') && (
          <header className="h-14 border-b border-slate-700/50 bg-slate-900/60 backdrop-blur-md flex items-center justify-between px-4 z-10 shrink-0 print:hidden">
            {/* Hamburger (mobile only) */}
            <button
              className="lg:hidden p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors"
              onClick={() => setIsMobileOpen(true)}
              aria-label="Open menu"
            >
              <Menu size={22} />
            </button>

            {/* Mobile logo text */}
            <span className="lg:hidden font-bold text-white text-base ml-2">PMS</span>

            <div className="flex-1 hidden lg:block" />

            <div className="flex items-center space-x-3 sm:space-x-5">
              {/* Expiry Alerts */}
              {(role === 'admin' || role === 'manager') && (
                <button 
                  onClick={() => setIsExpiryModalOpen(true)}
                  className="relative p-2 text-slate-300 hover:text-white transition-colors rounded-full hover:bg-slate-800"
                  title="View Expiry Alerts"
                >
                  <Calendar size={20} />
                  {expiringItems?.length > 0 && (
                    <span className="absolute top-1 right-1 w-4 h-4 bg-orange-500 text-[10px] font-bold text-white flex items-center justify-center rounded-full border-2 border-slate-900">
                      {expiringItems.length}
                    </span>
                  )}
                </button>
              )}

              {/* Notifications */}
              {(role === 'admin' || role === 'manager') && (
                <div className="relative group">
                  <button className="relative p-2 text-slate-300 hover:text-white transition-colors rounded-full hover:bg-slate-800">
                    <Bell size={20} />
                    {notifications?.length > 0 && (
                      <>
                        <span className="absolute top-1 right-1 w-2 h-2 bg-danger rounded-full animate-ping" />
                        <span className="absolute top-1 right-1 w-2 h-2 bg-danger rounded-full border-2 border-slate-900" />
                      </>
                    )}
                  </button>
                  {/* Notification Dropdown */}
                  <div className="absolute right-0 mt-2 w-72 sm:w-80 bg-slate-800 border border-slate-700 rounded-xl shadow-2xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 overflow-hidden">
                    <div className="p-4 border-b border-slate-700/50 bg-slate-800/80 backdrop-blur-sm flex justify-between items-center">
                      <h3 className="font-bold text-white">Notifications</h3>
                      {notifications?.length > 0 && (
                        <span className="text-xs bg-danger text-white px-2 py-0.5 rounded-full">{notifications.length}</span>
                      )}
                    </div>
                    <div className="max-h-80 overflow-y-auto hide-scrollbar bg-slate-800">
                      {(!Array.isArray(notifications) || notifications.length === 0) ? (
                        <div className="p-6 text-center text-muted text-sm flex flex-col items-center">
                          <CheckCircle size={24} className="text-emerald-500/50 mb-2" />
                          You're all caught up!
                        </div>
                      ) : (
                        <div className="divide-y divide-slate-700/50">
                          {notifications.map((n, i) => (
                            <div
                              key={i}
                              className="p-4 hover:bg-slate-700/30 transition-colors cursor-pointer"
                              onClick={() => navigate(n.type?.startsWith('ac') ? '/maintenance-admin' : (n.type?.startsWith('contract') || n.type?.startsWith('generator')) ? '/tenants' : '/rent')}
                            >
                              <div className="flex items-start gap-3">
                                <div className={`p-2 rounded-full mt-0.5 shrink-0 ${n.type?.includes('overdue') ? 'bg-red-500/10 text-red-400' : 'bg-orange-500/10 text-orange-400'}`}>
                                  <AlertCircle size={16} />
                                </div>
                                <p className="text-sm text-slate-200 line-clamp-3">
                                  {t(`schedule.notif_${n.type}`, { building: n.building, apt: n.apartment, days: n.days })}
                                </p>
                              </div>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="p-3 text-center bg-slate-900/50 border-t border-slate-700/50 hover:bg-slate-700/50 transition-colors">
                      <button onClick={() => navigate('/schedule')} className="text-sm font-medium text-indigo-400 w-full">
                        View Schedule Center
                      </button>
                    </div>
                  </div>
                </div>
              )}

              <div className="h-7 border-l border-slate-700/50 hidden sm:block" />

              {/* User avatar */}
              <div className="flex items-center space-x-2">
                <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-500 to-purple-500 flex items-center justify-center text-white font-bold text-sm shadow-lg shrink-0">
                  {user?.name?.charAt(0) || 'U'}
                </div>
                <div className="hidden md:block">
                  <p className="text-sm font-medium text-white leading-tight">{user?.name || 'User'}</p>
                  <p className="text-xs text-slate-400 capitalize">{role}</p>
                </div>
              </div>
            </div>
          </header>
        )}

        {/* Page Content */}
        <div className="flex-1 overflow-auto print:overflow-visible relative print:static">
          <Outlet />
        </div>
      </main>

      {/* Global Modals for Admin Notifications */}
      {activeTenantResponses.length > 0 && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-[100] p-4">
          <div className="glass-card w-full max-w-md p-8 border border-slate-700 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <div className="flex items-start gap-4 mb-6">
              <div className="p-3 bg-indigo-500/20 text-indigo-400 rounded-full shrink-0">
                <Bell size={28} />
              </div>
              <div>
                <h2 className="text-2xl font-bold text-white mb-2">{activeTenantResponses[0].title}</h2>
                <p className="text-slate-300 text-lg">{activeTenantResponses[0].message}</p>
              </div>
            </div>
            
            <div className="flex flex-col sm:flex-row justify-end gap-3 mt-8">
              <button 
                onClick={() => handleRemindLater(activeTenantResponses[0].id)} 
                className="px-4 py-2 rounded-lg text-slate-300 hover:bg-slate-800 transition-colors border border-slate-700"
              >
                Remind me in 24h
              </button>
              <button 
                onClick={() => markNotifReadMutation.mutate(activeTenantResponses[0].id)}
                disabled={markNotifReadMutation.isLoading}
                className="px-6 py-2 bg-primary hover:bg-indigo-600 text-white font-bold rounded-lg shadow-lg shadow-primary/30 transition-colors"
              >
                {markNotifReadMutation.isLoading ? 'Processing...' : 'Acknowledge'}
              </button>
            </div>
          </div>
        </div>
      )}

      <ExpiryAlertsModal 
        isOpen={isExpiryModalOpen} 
        onClose={() => setIsExpiryModalOpen(false)} 
        alerts={expiringItems || []} 
      />
    </div>
  );
};

export default Layout;
