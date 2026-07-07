import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Buildings from './pages/Buildings';
import BuildingDetails from './pages/BuildingDetails';
import Apartments from './pages/Apartments';
import Tenants from './pages/Tenants';
import TenantDetails from './pages/TenantDetails';
import Rent from './pages/Rent';
import Insurance from './pages/Insurance';
import AuditLogs from './pages/AuditLogs';
import Warehouse from './pages/Warehouse';
import MovementTransfer from './pages/MovementTransfer';
import POS from './pages/POS';
import Expenses from './pages/Expenses';
import Reports from './pages/Reports';
import Workshop from './pages/Workshop';
import WorkshopDetails from './pages/WorkshopDetails';
import Settings from './pages/Settings';
import Construction from './pages/Construction';
import ConstructionDetails from './pages/ConstructionDetails';
import Suppliers from './pages/Suppliers';
import PurchaseOrders from './pages/PurchaseOrders';
import SalesHistory from './pages/SalesHistory';
import EnergyManagement from './pages/EnergyManagement';
import GeneratorDashboard from './pages/GeneratorDashboard';
import ApartmentElectricity from './pages/ApartmentElectricity';
import BuildingSubscriptions from './pages/BuildingSubscriptions';
import GeneratorMonitoring from './pages/GeneratorMonitoring';
import FuelReserve from './pages/FuelReserve';
import Users from './pages/Users';
import ReadingsVerification from './pages/ReadingsVerification';

import MaintenanceDashboard from './pages/MaintenanceDashboard';
import MaintenanceAdmin from './pages/MaintenanceAdmin';
import ScheduleCenter from './pages/ScheduleCenter';

// New Admin Pages
import RentManagement from './pages/RentManagement';
import InsuranceDashboard from './pages/InsuranceDashboard';
import RentInsuranceHub from './pages/RentInsuranceHub';
import ReportsPage from './pages/ReportsPage';
import ContractsHub from './pages/ContractsHub';
import PendingContracts from './pages/PendingContracts';
import FinancialBuildingReport from './pages/FinancialBuildingReport';
import GeneratorSubscriptionReport from './pages/GeneratorSubscriptionReport';
import ApartmentCostReport from './pages/ApartmentCostReport';

// Tenant Portal Pages
import TenantDashboard from './pages/tenant/TenantDashboard';
import TenantContract from './pages/tenant/TenantContract';
import TenantPayments from './pages/tenant/TenantPayments';
import TenantSubscriptions from './pages/tenant/TenantSubscriptions';

// Agent Portal Pages
import AgentDashboard from './pages/agent/AgentDashboard';
import AgentGenerators from './pages/agent/AgentGenerators';
import AgentApartments from './pages/agent/AgentApartments';
import AgentHistory from './pages/agent/AgentHistory';
import AgentDailyReport from './pages/agent/AgentDailyReport';

import AgentSubscriptions from './pages/agent/AgentSubscriptions';

import DailyReportsDashboard from './pages/DailyReportsDashboard';
import GlobalSettings from './pages/GlobalSettings';
import FinancialReports from './pages/FinancialReports';

const queryClient = new QueryClient();

const ProtectedRoute = ({ children, allowedRoles }) => {
  const token = localStorage.getItem('token');
  if (!token) {
    return <Navigate to="/login" replace />;
  }

  // Strict routing block for agents
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (user?.role === 'agent') {
      const path = window.location.pathname;
      // Allow root so it can redirect via RoleBasedRootRedirect, otherwise strictly require /agent-
      if (path !== '/' && !path.startsWith('/agent-') && !path.startsWith('/Bitar/agent-')) {
         return <Navigate to="/agent-dashboard" replace />;
      }
    }
  } catch(e) {}

  return children;
};

// A simple role-based redirect for the root path
const RoleBasedRootRedirect = () => {
  try {
    const user = JSON.parse(localStorage.getItem('user'));
    if (user?.role === 'maintenance') return <Navigate to="/maintenance" replace />;
    if (user?.role === 'cashier') return <Navigate to="/pos" replace />;
    if (user?.role === 'tenant') return <Navigate to="/tenant-dashboard" replace />;
    if (user?.role === 'agent') return <Navigate to="/agent-dashboard" replace />;
  } catch (e) {}
  return <Dashboard />;
};

function App() {
  const { i18n } = useTranslation();

  useEffect(() => {
    document.documentElement.dir = i18n.language === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = i18n.language;
  }, [i18n.language]);

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter basename={process.env.PUBLIC_URL || '/'}>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route path="/" element={
            <ProtectedRoute>
              <Layout />
            </ProtectedRoute>
          }>
            <Route index element={<RoleBasedRootRedirect />} />
            <Route path="buildings" element={<Buildings />} />
            <Route path="buildings/:id" element={<BuildingDetails />} />
            <Route path="apartments" element={<Apartments />} />
            <Route path="tenants" element={<Tenants />} />
            <Route path="tenants/:id" element={<TenantDetails />} />
            <Route path="users" element={<Users />} />
            <Route path="rent" element={<FinancialReports />} />
            <Route path="insurance" element={<FinancialReports />} />
            <Route path="insurance-dashboard" element={<FinancialReports />} />
            <Route path="financial-reports" element={<FinancialReports />} />
            <Route path="audit" element={<AuditLogs />} />
            <Route path="depot" element={<Warehouse />} />
            <Route path="movement-transfer" element={<MovementTransfer />} />
            <Route path="pos" element={<POS />} />
            <Route path="expenses" element={<Expenses />} />
            <Route path="reports" element={<ReportsPage />} />
            <Route path="apartment-costs" element={<ApartmentCostReport />} />
            <Route path="financial-buildings-report" element={<FinancialBuildingReport />} />
            <Route path="generator-subscriptions-report" element={<GeneratorSubscriptionReport />} />

            <Route path="global-settings" element={<GlobalSettings />} />

            <Route path="building-rent" element={<Rent />} />
            <Route path="building-insurance" element={<Insurance />} />

            <Route path="rent-hub" element={<RentInsuranceHub />} />
            <Route path="rent-management" element={<RentManagement />} />
            <Route path="contracts" element={<ContractsHub />} />
            <Route path="pending-contracts" element={<Navigate to="/contracts" replace />} />
            <Route path="workshop" element={<Workshop />} />
            <Route path="workshop/:id" element={<WorkshopDetails />} />
            <Route path="constructions" element={<Construction />} />
            <Route path="constructions/:id" element={<ConstructionDetails />} />
            <Route path="suppliers" element={<Suppliers />} />
            <Route path="purchase-orders" element={<PurchaseOrders />} />
            <Route path="sales" element={<SalesHistory />} />
            <Route path="energy" element={<EnergyManagement />} />
            <Route path="energy/generator/:id" element={<GeneratorDashboard />} />
            <Route path="energy/monitoring" element={<GeneratorMonitoring />} />
            <Route path="fuel-reserve" element={<FuelReserve />} />
            <Route path="energy/buildings/:id/subscriptions" element={<BuildingSubscriptions />} />
            <Route path="energy/verification" element={<ReadingsVerification />} />
            <Route path="apartments/:id/electricity" element={<ApartmentElectricity />} />
            <Route path="settings" element={<Settings />} />
            
            <Route path="maintenance" element={<MaintenanceDashboard />} />
            <Route path="maintenance-admin" element={<MaintenanceAdmin />} />
            <Route path="schedule" element={<ScheduleCenter />} />
            
            {/* Tenant Portal */}
            <Route path="tenant-dashboard" element={<TenantDashboard />} />
            <Route path="tenant-contract" element={<TenantContract />} />
            <Route path="tenant-payments" element={<TenantPayments />} />
            <Route path="tenant-subscriptions" element={<TenantSubscriptions />} />
            
            {/* Agent Portal */}
            <Route path="agent-dashboard" element={<AgentDashboard />} />
            <Route path="agent-generators" element={<AgentGenerators />} />
            <Route path="agent-apartments" element={<AgentApartments />} />
            <Route path="agent-history" element={<AgentHistory />} />
            <Route path="agent-daily-report" element={<AgentDailyReport />} />
            <Route path="agent-subscriptions" element={<AgentSubscriptions />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
