// ─── App Router (go_router) ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard_screen.dart';
import '../screens/buildings_screen.dart';
import '../screens/building_details_screen.dart';
import '../screens/tenants_screen.dart';
import '../screens/rent_screen.dart';
import '../screens/warehouse_screen.dart';
import '../screens/pos_screen.dart';
import '../screens/workshop_screen.dart';
import '../screens/workshop_details_screen.dart';
import '../screens/energy_screen.dart';
import '../screens/construction_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/ac_maintenance_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isLoginPage = state.matchedLocation == '/login';

      if (isLoading) return null;
      if (!isAuth && !isLoginPage) return '/login';
      if (isAuth && isLoginPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/buildings', builder: (_, __) => const BuildingsScreen()),
          GoRoute(
            path: '/buildings/:id',
            builder: (context, state) => BuildingDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/tenants', builder: (_, __) => const TenantsScreen()),
          GoRoute(path: '/rent', builder: (_, __) => const RentScreen()),
          GoRoute(path: '/warehouse', builder: (_, __) => const WarehouseScreen()),
          GoRoute(path: '/pos', builder: (_, __) => const POSScreen()),
          GoRoute(path: '/workshop', builder: (_, __) => const WorkshopScreen()),
          GoRoute(
            path: '/workshop/:id',
            builder: (context, state) => WorkshopDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/energy', builder: (_, __) => const EnergyScreen()),
          GoRoute(path: '/construction', builder: (_, __) => const ConstructionScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: '/ac-maintenance', builder: (_, __) => const ACMaintenanceScreen()),
        ],
      ),
    ],
  );
});
