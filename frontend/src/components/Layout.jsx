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
  AlertCircle, Fuel, Menu, X, FileCheck2, Truck, BarChart2, Sparkles,
  ShieldAlert, RefreshCw, Link, Folder, Receipt, PanelLeftClose, PanelLeft, Globe
} from 'lucide-react';
import ExpiryAlertsModal from './ExpiryAlertsModal';

const ICON_MAP = {
  LayoutDashboard, Building, Home, Users, DollarSign, Shield, HardHat, Archive, ShoppingCart, CreditCard, FileText, Settings, Activity, Zap, Calendar, Fuel, FileCheck2, Truck, BarChart2, Sparkles, ShieldAlert, RefreshCw, Link, Folder, Briefcase
};

const Layout = () => {
  const { t, i18n } = useTranslation();
  const navigate = useNavigate();
  const location = useLocation();
  const queryClient = useQueryClient();

  // ── Mobile sidebar open/close ──────────────────────────────────────────────
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [isDesktopSidebarOpen, setIsDesktopSidebarOpen] = useState(true);

  // Expiry Alerts Modal State
  const [isExpiryModalOpen, setIsExpiryModalOpen] = useState(false);
  const [hasShownExpiryModal, setHasShownExpiryModal] = useState(false);

  // Close mobile sidebar on route change
  useEffect(() => {
    setIsMobileOpen(false);
  }, [location.pathname]);

  const [openFolder, setOpenFolder] = useState(null);

  useEffect(() => {
    // Reset explicitly opened folder on navigation to allow auto-open of active section
    setOpenFolder(null);
  }, [location.pathname]);

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
    enabled: role === 'admin' || role === 'manager' || role === 'agent',
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

  // ── Admin: pending agent purchase count ────────────────────────────────────
  const { data: pendingPurchaseCount = 0 } = useQuery({
    queryKey: ['admin_pending_purchase_count'],
    queryFn: async () => {
      try {
        const res = await axios.get('/energy/agent/apartment-purchases/pending');
        return Array.isArray(res.data) ? res.data.length : 0;
      } catch { return 0; }
    },
    refetchInterval: 30000,
    enabled: role === 'admin' || role === 'manager',
  });

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

  const { data: globalMenus } = useQuery({
    queryKey: ['global-menus'],
    queryFn: async () => {
      try { return (await axios.get('/permissions/global-menus')).data; } catch (e) { return []; }
    }
  });

  const { data: myPerms } = useQuery({
    queryKey: ['my-permissions'],
    queryFn: async () => {
      try { return (await axios.get('/permissions/my-permissions')).data; } catch (e) { return null; }
    }
  });

  const pagePerms = myPerms?.pages || [];
  const menuPerms = myPerms?.menu || [];

  const pageMap = {};
  (pagePerms || []).forEach(p => { pageMap[p.page_key] = p; });
  const menuMap = {};
  (menuPerms || []).forEach(m => { menuMap[m.menu_key] = m; });

  const hasPagePerm = (key) => role === 'admin' || (pageMap[key] && Number(pageMap[key].can_view) === 1);
  const hasMenuPerm = (key) => role === 'admin' || !key || (menuMap[key] && Number(menuMap[key].is_visible) === 1);

  // Build dynamic menu tree
  const menuItems = [];

  if (role === 'tenant') {
    [
      { name: 'My Dashboard',      path: '/tenant-dashboard',      icon: LayoutDashboard, pageKey: 'dashboard' },
      { name: 'My Contract',       path: '/tenant-contract',       icon: FileText,        pageKey: 'contracts' },
      { name: 'My Payments',       path: '/tenant-payments',       icon: DollarSign,      pageKey: 'rent' },
      { name: 'My Subscriptions',  path: '/tenant-subscriptions',  icon: Zap,             pageKey: 'energy' },
      { name: 'Renewal Requests',  path: '/tenant-requests',       icon: Calendar,        pageKey: 'rent' },
      { name: 'Maintenance',       path: '/tenant-maintenance',    icon: HardHat,         pageKey: 'dashboard' },
      { name: 'My Profile & Docs', path: '/tenant-profile',        icon: Users,           pageKey: 'dashboard' },
    ].forEach(item => menuItems.push(item));
  } else if (role === 'agent') {
    [
      { name: 'Agent Dashboard', path: '/agent-dashboard', icon: LayoutDashboard, pageKey: 'dashboard' },
      { name: 'Pending Tasks', path: '/agent-subscriptions', icon: CheckCircle, redDot: agentSubTaskCount > 0, redDotCount: agentSubTaskCount, pageKey: 'energy' },
      { name: 'Sub. Collection History', path: '/agent-collect-subscription', icon: Receipt, pageKey: 'energy' },
      { name: 'Building Generators', path: '/agent-generators', icon: Activity, pageKey: 'generators' },
      { name: 'Apartment Readings', path: '/agent-apartments', icon: Home, pageKey: 'apartments' },
      { name: 'Apartment Cost', path: '/agent-apartment-costs', icon: ShoppingCart, pageKey: 'reports' },
      { name: 'Rent Collection', path: '/agent-rent-collection', icon: DollarSign, pageKey: 'rent' },
      { name: 'Collect', path: '/agent-collect', icon: DollarSign, pageKey: 'rent' },
      { name: 'Collection History', path: '/agent-collection-history', icon: FileText, pageKey: 'rent' },
      { name: 'Reading History', path: '/agent-history', icon: FileText, pageKey: 'reports' },
      { name: 'Submit Daily Report', path: '/agent-daily-report', icon: FileCheck2, pageKey: 'reports' },
    ].forEach(item => menuItems.push(item));
  } else {
    if (globalMenus) {
      const rawMenus = globalMenus.filter(m => {
        if (!hasMenuPerm(m.menu_key)) return false;
        if (m.path !== '#' && !hasPagePerm(m.menu_key)) return false;
        return true;
      }).sort((a, b) => a.sort_order - b.sort_order);

      const rootItems = rawMenus.filter(m => !m.parent_key);

      rootItems.forEach(root => {
        if (root.path === '#') {
          const children = rawMenus.filter(m => m.parent_key === root.menu_key);
          if (children.length > 0) {
            menuItems.push({
              name: root.label,
              icon: ICON_MAP[root.icon] || Folder,
              menuKey: root.menu_key,
              isFolder: true,
              children: children.map(c => ({
                name: c.label,
                path: c.path,
                icon: ICON_MAP[c.icon] || FileText,
                pageKey: c.menu_key,
                menuKey: c.menu_key
              }))
            });
          }
        } else {
          menuItems.push({
            name: root.label,
            path: root.path,
            icon: ICON_MAP[root.icon] || FileText,
            pageKey: root.menu_key,
            menuKey: root.menu_key
          });
        }
      });
      
      // Admin-only Translations tool
      if (role === 'admin') {
         menuItems.push({
            name: 'Translations (i18n)',
            path: '/translations',
            icon: Globe,
            pageKey: 'dashboard',
            menuKey: 'translations'
         });
      }
    }
  }

  // Compute the most specific matching path to avoid multi-highlighting
  const activePath = (() => {
    let bestMatch = '/';
    let maxLen = 0;
    const check = (p) => {
      if (!p || p === '#') return;
      if (p === '/' && location.pathname === '/' && maxLen < 1) {
        bestMatch = '/'; maxLen = 1;
      } else if (p !== '/' && (location.pathname === p || location.pathname.startsWith(p + '/'))) {
        if (p.length > maxLen) { bestMatch = p; maxLen = p.length; }
      }
    };
    menuItems.forEach(item => {
      if (item.isFolder) item.children.forEach(c => check(c.path));
      else check(item.path);
    });
    check('/agent-purchase-review');
    return bestMatch;
  })();

  // ── Render helpers ─────────────────────────────────────────────────────────
  const renderNavItem = (item, isSubItem = false) => {
    const Icon = item.icon;
    const isActive = item.path === '/'
      ? location.pathname === '/'
      : (item.path === activePath || (activePath.startsWith(item.path + '/') && item.path === activePath));

    return (
      <NavLink
        key={item.path}
        to={item.path}
        className={`w-full flex items-center justify-between px-4 py-3 mb-1 rounded-[14px] transition-all duration-200 ${item.redDot && !isActive
            ? 'text-white bg-danger/15 border border-danger/30 hover:bg-danger/25'
            : isActive
              ? 'bg-primary text-white shadow-lg shadow-primary/30'
              : 'text-slate-400 hover:bg-white/5 hover:text-slate-200'
          } ${isSubItem ? 'ps-10 text-sm' : ''}`}
      >
        <div className="flex items-center min-w-0">
          <div className="relative me-4 shrink-0">
            <Icon
              size={20}
              className={item.redDot && !isActive ? 'text-danger' : ''}
              strokeWidth={1.5}
            />
            {/* Pulsing red dot indicator */}
            {item.redDot && (
              <span className="absolute -top-1.5 -right-1.5 flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-danger opacity-75"></span>
                <span className="relative inline-flex rounded-full h-3 w-3 bg-danger"></span>
              </span>
            )}
          </div>
          <span className={`font-medium tracking-wide ${item.redDot && !isActive ? 'text-red-300' : isActive ? 'text-white font-semibold' : ''
            }`}>
            {item.name}
          </span>
        </div>

        <div className="flex items-center shrink-0">
          {/* Numeric count badge */}
          {item.redDot && item.redDotCount > 0 && (
            <span className="bg-danger text-white text-xs font-bold px-2 py-0.5 rounded-full shadow-lg shadow-danger/40">
              {item.redDotCount}
            </span>
          )}
          {!item.redDot && item.badge > 0 && (
            <span className="bg-danger text-white text-xs font-bold px-2 py-0.5 rounded-full animate-pulse">
              {item.badge}
            </span>
          )}
          {/* Right Chevron for sub-menus mock or non-dashboard items */}
          {!isActive && !isSubItem && item.path !== '/' && item.path !== '/schedule' && !item.redDot && !item.badge && (
            <ChevronRight size={16} className="text-slate-500 opacity-50" />
          )}
        </div>
      </NavLink>
    );
  };

  const renderDropdown = ({ key, label, icon: Icon, isOpen, setOpen, items }) => {
    const anyActive = items.some(item =>
      item.path === '/' ? location.pathname === '/' : (item.path === activePath || activePath.startsWith(item.path + '/'))
    );
    return (
      <div key={key} className="pt-1">
        <button
          onClick={() => setOpen(!isOpen)}
          className={`w-full flex items-center justify-between px-4 py-3 mb-1 rounded-[14px] transition-all duration-200 ${isOpen || anyActive ? 'text-white bg-white/5' : 'text-slate-400 hover:bg-white/5 hover:text-slate-200'
            }`}
        >
          <div className="flex items-center">
            <Icon size={20} className="me-4 shrink-0" strokeWidth={1.5} />
            <span className="font-medium tracking-wide">{label}</span>
          </div>
          {isOpen
            ? <ChevronDown size={16} className="shrink-0 text-slate-500 opacity-50" />
            : <ChevronRight size={16} className="shrink-0 text-slate-500 opacity-50" />}
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
          <div className="w-9 h-9 bg-primary rounded-[10px] flex items-center justify-center text-white font-bold text-lg shadow-[0_0_15px_rgba(99,102,241,0.5)] shrink-0">
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
        {menuItems.map(item => {
          if (item.isFolder) {
            const hasActiveChild = item.children.some(c => location.pathname.startsWith(c.path));
            const isOpen = openFolder === item.menuKey || (openFolder === null && hasActiveChild);
            return renderDropdown({
              key: item.menuKey,
              label: item.name,
              icon: item.icon,
              isOpen: isOpen,
              setOpen: (val) => setOpenFolder(val ? item.menuKey : ''),
              items: item.children
            });
          } else {
            return renderNavItem(item);
          }
        })}

        {/* ── Admin: Agent Purchase Review quick-access ─────────────────────── */}
        {(role === 'admin' || role === 'manager') && (
          renderNavItem({
            name: 'Purchase Review',
            path: '/agent-purchase-review',
            icon: ShoppingCart,
            redDot: pendingPurchaseCount > 0,
            redDotCount: pendingPurchaseCount,
          })
        )}
      </nav>

      {/* Footer */}
      <div className="px-5 mt-4 mb-4 pt-5 border-t border-white/5 shrink-0">
        <div className="relative mb-4">
          <select
            value={i18n.language}
            onChange={(e) => changeLanguage(e.target.value)}
            className="w-full bg-[#1e2235] border border-white/5 text-white rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:border-indigo-500/50 appearance-none shadow-xl shadow-black/20"
          >
            <option value="en">{t('common.english')}</option>
            <option value="fr">{t('common.french')}</option>
            <option value="ar">{t('common.arabic')}</option>
          </select>
          <ChevronDown size={14} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
        </div>
        <button
          onClick={handleLogout}
          className="w-full flex items-center px-4 py-2 rounded-[12px] text-[#ff4b4b] hover:bg-white/5 transition-all duration-200"
        >
          <LogOut size={20} className="me-3 shrink-0" strokeWidth={1.5} />
          <span className="font-medium">Logout</span>
        </button>
      </div>
    </>
  );

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div className="flex h-screen print:h-auto bg-background text-darktext overflow-hidden print:overflow-visible font-sans">

      {/* ── Desktop Sidebar (lg+) ─────────────────────────────────────────── */}
      <aside className={`hidden lg:flex ${isDesktopSidebarOpen ? 'w-[260px] border-r border-white/5' : 'w-0 border-transparent'} transition-all duration-300 ease-in-out overflow-hidden bg-[#131722] flex-col py-6 print:hidden z-20 shrink-0 shadow-[4px_0_24px_rgba(0,0,0,0.2)]`}>
        <div className="w-[260px] h-full flex flex-col shrink-0">
          <SidebarContent />
        </div>
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
        className={`fixed top-0 left-0 h-full w-[260px] bg-[#131722] border-r border-white/5 shadow-[4px_0_24px_rgba(0,0,0,0.2)] flex flex-col py-6 z-40 lg:hidden transition-transform duration-300 ease-in-out print:hidden ${isMobileOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
      >
        <SidebarContent />
      </aside>

      {/* ── Main Content ──────────────────────────────────────────────────── */}
      <main className="flex-1 min-w-0 h-full print:h-auto flex flex-col overflow-hidden print:overflow-visible relative bg-background print:bg-white">

        {/* Top Bar */}
        {(role === 'admin' || role === 'manager' || role === 'cashier' || role === 'tenant' || role === 'agent') && (
          <header className="h-14 border-b border-slate-700/50 bg-slate-900/60 backdrop-blur-md flex items-center justify-between px-4 z-10 shrink-0 print:hidden">
            {/* Hamburger (mobile only) */}
            <button
              className="lg:hidden p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors"
              onClick={() => setIsMobileOpen(true)}
              aria-label="Open menu"
            >
              <Menu size={22} />
            </button>

            {/* Desktop Sidebar Toggle */}
            <button
              className="hidden lg:flex p-2 text-slate-400 hover:text-white hover:bg-slate-800 rounded-xl transition-colors group relative"
              onClick={() => setIsDesktopSidebarOpen(!isDesktopSidebarOpen)}
              aria-label="Toggle sidebar"
            >
              {isDesktopSidebarOpen ? <PanelLeftClose size={22} /> : <PanelLeft size={22} />}
              <div className="absolute left-full ml-2 px-2 py-1 bg-slate-200 text-slate-800 font-medium text-xs rounded opacity-0 invisible group-hover:opacity-100 group-hover:visible whitespace-nowrap transition-all z-50 shadow-lg shadow-black/20">
                {isDesktopSidebarOpen ? 'Close sidebar' : 'Open sidebar'}
              </div>
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
              {(role === 'admin' || role === 'manager' || role === 'agent') && (
                <div className="relative group">
                  <button className="relative p-2 text-slate-300 hover:text-white transition-colors rounded-full hover:bg-slate-800">
                    <Bell size={20} />
                    {((role === 'tenant' ? dbUnreadNotifications : notifications)?.length > 0) && (
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
                      {((role === 'tenant' ? dbUnreadNotifications : notifications)?.length > 0) && (
                        <span className="text-xs bg-danger text-white px-2 py-0.5 rounded-full">{(role === 'tenant' ? dbUnreadNotifications : notifications).length}</span>
                      )}
                    </div>
                    <div className="max-h-80 overflow-y-auto hide-scrollbar bg-slate-800">
                      {(role === 'tenant' ? (!Array.isArray(dbUnreadNotifications) || dbUnreadNotifications.length === 0) : (!Array.isArray(notifications) || notifications.length === 0)) ? (
                        <div className="p-6 text-center text-muted text-sm flex flex-col items-center">
                          <CheckCircle size={24} className="text-emerald-500/50 mb-2" />
                          You're all caught up!
                        </div>
                      ) : (
                        <div className="divide-y divide-slate-700/50">
                          {role === 'tenant' ? (
                            dbUnreadNotifications.map((n, i) => (
                              <div
                                key={i}
                                className="p-4 hover:bg-slate-700/30 transition-colors cursor-pointer"
                                onClick={() => {
                                  if (n.type === 'rent_renewal_request') navigate('/tenant-requests');
                                }}
                              >
                                <div className="flex items-start gap-3">
                                  <div className={`p-2 rounded-full mt-0.5 shrink-0 bg-orange-500/10 text-orange-400`}>
                                    <AlertCircle size={16} />
                                  </div>
                                  <div>
                                    <p className="text-sm font-bold text-white mb-1">{n.title}</p>
                                    <p className="text-xs text-slate-200 line-clamp-3">{n.message}</p>
                                  </div>
                                </div>
                              </div>
                            ))
                          ) : (
                            notifications.map((n, i) => (
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
                          ))
                          )}
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
