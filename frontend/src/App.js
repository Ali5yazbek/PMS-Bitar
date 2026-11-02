import React, { useEffect, Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import Layout from './components/Layout';
import SessionTracker from './components/SessionTracker';
import { CurrencyProvider } from './contexts/CurrencyContext';

// Lazy loaded pages
const Login = lazy(() => import('./pages/Login'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Buildings = lazy(() => import('./pages/Buildings'));
const BuildingDetails = lazy(() => import('./pages/BuildingDetails'));
const Apartments = lazy(() => import('./pages/Apartments'));
const Tenants = lazy(() => import('./pages/Tenants'));
const TenantDetails = lazy(() => import('./pages/TenantDetails'));
const Rent = lazy(() => import('./pages/Rent'));
const Insurance = lazy(() => import('./pages/Insurance'));
const AuditLogs = lazy(() => import('./pages/AuditLogs'));
const Warehouse = lazy(() => import('./pages/Warehouse'));
const MovementTransfer = lazy(() => import('./pages/MovementTransfer'));
const POS = lazy(() => import('./pages/POS'));
const Expenses = lazy(() => import('./pages/Expenses'));
const Reports = lazy(() => import('./pages/Reports'));
const Workshop = lazy(() => import('./pages/Workshop'));
const WorkshopDetails = lazy(() => import('./pages/WorkshopDetails'));
const WorkshopPricing = lazy(() => import('./pages/WorkshopPricing'));
const Settings = lazy(() => import('./pages/Settings'));
const Construction = lazy(() => import('./pages/Construction'));
const ConstructionDetails = lazy(() => import('./pages/ConstructionDetails'));
const Suppliers = lazy(() => import('./pages/Suppliers'));
const PurchaseOrders = lazy(() => import('./pages/PurchaseOrders'));
const SalesHistory = lazy(() => import('./pages/SalesHistory'));
const SalesSummary = lazy(() => import('./pages/SalesSummary'));
const Returns = lazy(() => import('./pages/Returns'));
const CashierSummary = lazy(() => import('./pages/CashierSummary'));
const EnergyManagement = lazy(() => import('./pages/EnergyManagement'));
const GeneratorDashboard = lazy(() => import('./pages/GeneratorDashboard'));
const ApartmentElectricity = lazy(() => import('./pages/ApartmentElectricity'));
const BuildingSubscriptions = lazy(() => import('./pages/BuildingSubscriptions'));
const GeneratorMonitoring = lazy(() => import('./pages/GeneratorMonitoring'));
const FuelReserve = lazy(() => import('./pages/FuelReserve'));
const Users = lazy(() => import('./pages/Users'));
const ReadingsVerification = lazy(() => import('./pages/ReadingsVerification'));

const MaintenanceDashboard = lazy(() => import('./pages/MaintenanceDashboard'));
const MaintenanceAdmin = lazy(() => import('./pages/MaintenanceAdmin'));
const ScheduleCenter = lazy(() => import('./pages/ScheduleCenter'));

// New Admin Pages
const RentManagement = lazy(() => import('./pages/RentManagement'));
const InsuranceDashboard = lazy(() => import('./pages/InsuranceDashboard'));
const RentInsuranceHub = lazy(() => import('./pages/RentInsuranceHub'));
const ReportsPage = lazy(() => import('./pages/ReportsPage'));
const ContractsHub = lazy(() => import('./pages/ContractsHub'));
const PendingContracts = lazy(() => import('./pages/PendingContracts'));
const FinancialBuildingReport = lazy(() => import('./pages/FinancialBuildingReport'));
const GeneratorSubscriptionReport = lazy(() => import('./pages/GeneratorSubscriptionReport'));
const ApartmentCostReport = lazy(() => import('./pages/ApartmentCostReport'));
const AgentPurchaseReview = lazy(() => import('./pages/AgentPurchaseReview'));
const Translations = lazy(() => import('./pages/Translations'));
const TenantArchiveReport = lazy(() => import('./pages/admin/TenantArchiveReport'));

// Enterprise ERP V4 Pages
const EnterpriseOperationsDashboard = lazy(() => import('./pages/EnterpriseOperationsDashboard'));
const UnifiedTaskCenter = lazy(() => import('./pages/UnifiedTaskCenter'));
const SystemJobsMonitor = lazy(() => import('./pages/SystemJobsMonitor'));

// Tenant Portal Pages
const TenantDashboard = lazy(() => import('./pages/tenant/TenantDashboard'));
const TenantContract = lazy(() => import('./pages/tenant/TenantContract'));
const TenantPayments = lazy(() => import('./pages/tenant/TenantPayments'));
const TenantSubscriptions = lazy(() => import('./pages/tenant/TenantSubscriptions'));
const TenantRequests = lazy(() => import('./pages/tenant/TenantRequests'));
const TenantMaintenance = lazy(() => import('./pages/tenant/TenantMaintenance'));
const TenantProfile = lazy(() => import('./pages/tenant/TenantProfile'));

// Agent Portal Pages
const AgentDashboard = lazy(() => import('./pages/agent/AgentDashboard'));
const AgentGenerators = lazy(() => import('./pages/agent/AgentGenerators'));
const AgentApartments = lazy(() => import('./pages/agent/AgentApartments'));
const AgentHistory = lazy(() => import('./pages/agent/AgentHistory'));
const AgentDailyReport = lazy(() => import('./pages/agent/AgentDailyReport'));

const AgentSubscriptions = lazy(() => import('./pages/agent/AgentSubscriptions'));
const AgentApartmentCosts = lazy(() => import('./pages/agent/AgentApartmentCosts'));
const AgentRentCollection = lazy(() => import('./pages/agent/AgentRentCollection'));
const AgentCollectionHistory = lazy(() => import('./pages/agent/AgentCollectionHistory'));
const AgentSubscriptionCollectionHistory = lazy(() => import('./pages/agent/AgentSubscriptionCollectionHistory'));
const AgentCollectionDashboard = lazy(() => import('./pages/agent/AgentCollectionDashboard'));

const GlobalSettings = lazy(() => import('./pages/GlobalSettings'));
const FinancialReports = lazy(() => import('./pages/FinancialReports'));
const AiChat = lazy(() => import('./pages/AiChat'));
const ActionControlReport = lazy(() => import('./pages/ActionControlReport'));
const DataQualityControl = lazy(() => import('./pages/DataQualityControl'));

// Global loading fallback
const PageLoader = () => (
  <div className="flex h-[calc(100vh-80px)] items-center justify-center w-full">
    <div className="flex flex-col items-center">
      <div className="w-12 h-12 border-4 border-primary border-t-transparent rounded-full animate-spin"></div>
      <p className="mt-4 text-muted text-sm font-medium animate-pulse">Loading page...</p>
    </div>
  </div>
);

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
      <CurrencyProvider>
        <BrowserRouter basename={process.env.PUBLIC_URL || '/'}>
          <SessionTracker />
        <Suspense fallback={<PageLoader />}>
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
              <Route path="agent-purchase-review" element={<AgentPurchaseReview />} />
              <Route path="financial-buildings-report" element={<FinancialBuildingReport />} />
              <Route path="generator-subscriptions-report" element={<GeneratorSubscriptionReport />} />
              <Route path="tenant-archive" element={<TenantArchiveReport />} />

              {/* Enterprise ERP Routes */}
              <Route path="enterprise-dashboard" element={<EnterpriseOperationsDashboard />} />
              <Route path="task-center" element={<UnifiedTaskCenter />} />
              <Route path="system-jobs" element={<SystemJobsMonitor />} />

              <Route path="global-settings" element={<GlobalSettings />} />

              <Route path="ai-chat" element={<AiChat />} />
              <Route path="action-control" element={<ActionControlReport />} />
              <Route path="data-quality" element={<DataQualityControl />} />

              <Route path="building-rent" element={<Rent />} />
              <Route path="building-insurance" element={<Insurance />} />

              <Route path="rent-hub" element={<RentInsuranceHub />} />
              <Route path="translations" element={<Translations />} />
              <Route path="rent-management" element={<RentManagement />} />
              <Route path="contracts" element={<ContractsHub />} />
              <Route path="pending-contracts" element={<Navigate to="/contracts" replace />} />
              <Route path="workshop" element={<Workshop />} />
              <Route path="workshop/:id" element={<WorkshopDetails />} />
              <Route path="workshop-pricing" element={<WorkshopPricing />} />
              <Route path="constructions" element={<Construction />} />
              <Route path="constructions/:id" element={<ConstructionDetails />} />
              <Route path="suppliers" element={<Suppliers />} />
              <Route path="purchase-orders" element={<PurchaseOrders />} />
              <Route path="sales" element={<SalesHistory />} />
              <Route path="sales-summary" element={<SalesSummary />} />
              <Route path="returns" element={<Returns />} />
              <Route path="cashier-summary" element={<CashierSummary />} />
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
              <Route path="tenant-requests" element={<TenantRequests />} />
              <Route path="tenant-maintenance" element={<TenantMaintenance />} />
              <Route path="tenant-profile" element={<TenantProfile />} />
              
              {/* Agent Portal */}
              <Route path="agent-dashboard" element={<AgentDashboard />} />
              <Route path="agent-generators" element={<AgentGenerators />} />
              <Route path="agent-apartments" element={<AgentApartments />} />
              <Route path="agent-history" element={<AgentHistory />} />
              <Route path="agent-daily-report" element={<AgentDailyReport />} />
              <Route path="agent-subscriptions" element={<AgentSubscriptions />} />
              <Route path="agent-apartment-costs" element={<AgentApartmentCosts />} />
              <Route path="agent-rent-collection" element={<AgentRentCollection />} />
              <Route path="agent-collection-history" element={<AgentCollectionHistory />} />
              <Route path="agent-collect-subscription" element={<AgentSubscriptionCollectionHistory />} />
              <Route path="agent-collect" element={<AgentCollectionDashboard />} />
            </Route>
          </Routes>
        </Suspense>
        </BrowserRouter>
      </CurrencyProvider>
    </QueryClientProvider>
  );
}

export default App;
