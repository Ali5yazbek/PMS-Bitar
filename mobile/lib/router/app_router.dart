// ─── App Router (go_router with Role-Aware StatefulShellRoute) ────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/manager_dashboard_screen.dart';
import '../screens/cashier_dashboard_screen.dart';
import '../screens/maintenance_dashboard_screen.dart';
import '../screens/global_search_screen.dart';
import '../screens/buildings_screen.dart';
import '../screens/building_details_screen.dart';
import '../screens/tenants_screen.dart';
import '../screens/tenant_details_screen.dart';
import '../screens/rent_screen.dart';
import '../screens/warehouse_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/workshop_screen.dart';
import '../screens/workshop_details_screen.dart';
import '../screens/energy_screen.dart';
import '../screens/construction_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/ac_maintenance_screen.dart';
import '../screens/maintenance_history_screen.dart';
import '../screens/contracts_screen.dart';
import '../screens/energy_verification_screen.dart';
import '../screens/notifications_screen.dart';

// Admin screens
import '../screens/user_management_screen.dart';
import '../screens/apartments_screen.dart';
import '../screens/subscriptions_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/gen_report_screen.dart';

// Reporting Screens
import '../screens/apartment_cost_report_screen.dart';
import '../screens/financial_building_report_screen.dart';
import '../screens/financial_reports_screen.dart';
import '../screens/insurance_hub_screen.dart';

import '../screens/admin_history_screen.dart';
import '../screens/admin_mobile_monitoring_screen.dart';
import '../screens/agent_purchase_review_screen.dart';

// Agent screens
import '../screens/agent_dashboard_screen.dart';
import '../screens/agent_apartments_screen.dart';
import '../screens/agent_generators_screen.dart';
import '../screens/agent_history_screen.dart';
import '../screens/agent_daily_report_screen.dart';
import '../screens/agent_subscriptions_screen.dart';
import '../screens/agent_rent_collection_screen.dart';
import '../screens/agent_collection_history_screen.dart';

// Admin AI Chat
import '../screens/admin_chat_screen.dart';

// Scanner
import '../screens/qr_scanner_screen.dart';

// Tenant screens
import '../screens/tenant_dashboard_screen.dart';
import '../screens/tenant_contract_screen.dart';
import '../screens/tenant_payments_screen.dart';
import '../screens/tenant_subscriptions_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final Map<String, List<String>> roleAllowedPrefixes = {
  'admin': ['/'], // Admin can access everything
  'manager': [
    '/manager-dashboard',
    '/buildings',
    '/financial-reports',
    '/reports',
    '/workshop',
    '/warehouse',
    '/settings',
    '/global-search',
    '/contracts',
    '/ac-maintenance',
    '/energy',
    '/energy/verification',
    '/gen-report',
    '/notifications',
  ],
  'agent': [
    '/agent-dashboard',
    '/agent-apartments',
    '/agent-generators',
    '/agent-history',
    '/agent-daily-report',
    '/agent-subscriptions',
    '/agent-rent-collection',
    '/agent-collection-history',
    '/global-search',
    '/qr-scanner',
    '/apartment-costs',
    '/settings',
    '/notifications',
  ],
  'tenant': [
    '/tenant-dashboard',
    '/tenant-payments',
    '/tenant-contract',
    '/tenant-subscriptions',
    '/tenant-rent',
    '/settings',
    '/notifications',
  ],
  'cashier': [
    '/cashier-dashboard',
    '/pos',
    '/rent',
    '/global-search',
    '/settings',
    '/notifications',
  ],
  'maintenance': [
    '/maintenance-dashboard',
    '/ac-maintenance',
    '/maintenance-history',
    '/workshop',
    '/settings',
    '/global-search',
    '/notifications',
  ],
};

String getDefaultRouteForRole(String? role) {
  final cleanRole = User.normalizeRole(role);
  switch (cleanRole) {
    case 'manager':
      return '/manager-dashboard';
    case 'agent':
      return '/agent-dashboard';
    case 'tenant':
      return '/tenant-dashboard';
    case 'cashier':
      return '/cashier-dashboard';
    case 'maintenance':
      return '/maintenance-dashboard';
    default:
      return '/'; // Admin
  }
}

bool isRouteAllowedForRole(String? role, String path) {
  final cleanRole = User.normalizeRole(role);
  if (cleanRole == 'admin') return true;
  final allowed = roleAllowedPrefixes[cleanRole] ?? [];
  for (final prefix in allowed) {
    if (path == prefix || path.startsWith('$prefix/')) {
      return true;
    }
  }
  return false;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      if (state.matchedLocation == '/splash') return null;

      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginPage = state.matchedLocation == '/login';
      final role = User.normalizeRole(authState.user?.role);

      if (isLoading) return null;
      if (!isAuth && !isLoginPage) return '/login';

      if (isAuth && isLoginPage) {
        return getDefaultRouteForRole(role);
      }

      if (isAuth) {
        final location = state.matchedLocation;
        // Non-admins attempting to access root '/' MUST be redirected to their role dashboard
        if (location == '/' && role != 'admin') {
          return getDefaultRouteForRole(role);
        }
        if (!isRouteAllowedForRole(role, location)) {
          return getDefaultRouteForRole(role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/admin-chat',
        builder: (context, state) => const AdminChatScreen(),
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(
        path: '/building-rent/:id',
        builder: (context, state) => RentScreen(
          buildingId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/tenant-rent/:id',
        builder: (context, state) => RentScreen(
          tenantId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/global-search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),

      // Persistent StatefulShellRoute preserving screen states across tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard overview
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
              GoRoute(path: '/manager-dashboard', builder: (_, __) => const ManagerDashboardScreen()),
              GoRoute(path: '/agent-dashboard', builder: (_, __) => const AgentDashboardScreen()),
              GoRoute(path: '/tenant-dashboard', builder: (_, __) => const TenantDashboardScreen()),
              GoRoute(path: '/cashier-dashboard', builder: (_, __) => const CashierDashboardScreen()),
              GoRoute(path: '/maintenance-dashboard', builder: (_, __) => const MaintenanceDashboardScreen()),
            ],
          ),

          // Branch 1: Subscriptions & Tasks
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/agent-subscriptions', builder: (_, __) => const AgentSubscriptionsScreen()),
              GoRoute(path: '/subscriptions', builder: (_, __) => const SubscriptionsScreen()),
              GoRoute(path: '/ac-maintenance', builder: (_, __) => const ACMaintenanceScreen()),
              GoRoute(path: '/energy', builder: (_, __) => const EnergyScreen()),
            ],
          ),

          // Branch 2: Generators & Buildings
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/agent-generators', builder: (_, __) => const AgentGeneratorsScreen()),
              GoRoute(path: '/buildings', builder: (_, __) => const BuildingsScreen()),
              GoRoute(
                path: '/buildings/:id',
                builder: (context, state) => BuildingDetailsScreen(id: state.pathParameters['id']!),
              ),
              GoRoute(path: '/warehouse', builder: (_, __) => const WarehouseScreen()),
              GoRoute(path: '/pos', builder: (_, __) => const POSScreen()),
              GoRoute(path: '/workshop', builder: (_, __) => const WorkshopScreen()),
              GoRoute(
                path: '/workshop/:id',
                builder: (context, state) => WorkshopDetailsScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),

          // Branch 3: Apartments & Readings
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/agent-apartments', builder: (_, __) => const AgentApartmentsScreen()),
              GoRoute(
                path: '/apartments',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return ApartmentsScreen(buildingId: extra?['buildingId']);
                },
              ),
              GoRoute(
                path: '/tenants',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  return TenantsScreen(buildingId: extra?['buildingId']);
                },
              ),
              GoRoute(
                path: '/tenants/:id',
                builder: (context, state) => TenantDetailsScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),

          // Branch 4: Collections & Other Modules
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/agent-rent-collection', builder: (_, __) => const AgentRentCollectionScreen()),
              GoRoute(path: '/tenant-payments', builder: (_, __) => const TenantPaymentsScreen()),
              GoRoute(path: '/tenant-contract', builder: (_, __) => const TenantContractScreen()),
              GoRoute(path: '/tenant-subscriptions', builder: (_, __) => const TenantSubscriptionsScreen()),
              GoRoute(path: '/rent', builder: (_, __) => const RentScreen()),
              GoRoute(path: '/agent-history', builder: (_, __) => const AgentHistoryScreen()),
              GoRoute(path: '/agent-daily-report', builder: (_, __) => const AgentDailyReportScreen()),
              GoRoute(path: '/agent-collection-history', builder: (_, __) => const AgentCollectionHistoryScreen()),
              GoRoute(path: '/apartment-costs', builder: (_, __) => const ApartmentCostReportScreen()),
              GoRoute(path: '/financial-buildings-report', builder: (_, __) => const FinancialBuildingReportScreen()),
              GoRoute(path: '/financial-reports', builder: (_, __) => const FinancialReportsScreen()),
              GoRoute(path: '/insurance-hub', builder: (_, __) => const InsuranceHubScreen()),
              GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
              GoRoute(path: '/gen-report', builder: (_, __) => const GenReportScreen()),
              GoRoute(path: '/construction', builder: (_, __) => const ConstructionScreen()),
              GoRoute(path: '/maintenance-history', builder: (_, __) => const MaintenanceHistoryScreen()),
              GoRoute(path: '/contracts', builder: (_, __) => const ContractsScreen()),
              GoRoute(path: '/energy/verification', builder: (_, __) => const EnergyVerificationScreen()),
              GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
              GoRoute(path: '/user-management', builder: (_, __) => const UserManagementScreen()),
              GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
              GoRoute(path: '/admin-history', builder: (_, __) => const AdminHistoryScreen()),
              GoRoute(path: '/admin-monitoring', builder: (_, __) => const AdminMobileMonitoringScreen()),
              GoRoute(path: '/agent-purchase-review', builder: (_, __) => const AgentPurchaseReviewScreen()),
            ],
          ),
        ],
      ),
    ],
  );
});
