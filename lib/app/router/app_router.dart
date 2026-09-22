import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/activation_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/bills/presentation/pages/bills_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/jobs/presentation/pages/jobs_page.dart';
import '../../features/parts/presentation/pages/parts_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../../features/shell/presentation/pages/dashboard_page.dart';
import '../../features/vehicles/presentation/pages/intake_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_history_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_list_page.dart';
import '../../features/vehicles/presentation/pages/vehicle_register_page.dart';
import '../../features/visits/presentation/pages/add_visit_page.dart';
import '../../features/voice/presentation/pages/voice_page.dart';
import '../di/providers.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (previous, next) => refresh.value++);
  ref.listen(activationStateProvider, (previous, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.activate,
    refreshListenable: refresh,
    redirect: (context, state) {
      final activated = ref.read(activationStateProvider);
      final loggedIn = ref.read(authStateProvider) != null;
      final location = state.matchedLocation;
      final onActivate = location == AppRoutes.activate;
      final onLogin = location == AppRoutes.login;

      if (!activated) {
        return onActivate ? null : AppRoutes.activate;
      }

      if (onActivate) {
        return loggedIn ? AppRoutes.home : AppRoutes.login;
      }

      if (!loggedIn) {
        return onLogin ? null : AppRoutes.login;
      }

      if (onLogin) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.activate,
        builder: (context, state) => const ActivationPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.intake,
            builder: (context, state) => const IntakePage(),
          ),
          GoRoute(
            path: AppRoutes.invoices,
            builder: (context, state) => const BillsPage(),
          ),
          GoRoute(
            path: AppRoutes.voice,
            builder: (context, state) {
              final vehicleId = int.tryParse(state.uri.queryParameters['vehicleId'] ?? '');
              return VoicePage(initialVehicleId: vehicleId);
            },
          ),
          GoRoute(
            path: AppRoutes.jobs,
            builder: (context, state) => const JobsPage(),
          ),
          GoRoute(
            path: AppRoutes.vehicles,
            builder: (context, state) => const VehicleListPage(),
          ),
          GoRoute(
            path: AppRoutes.vehicleNew,
            builder: (context, state) => VehicleRegisterPage(
              plateKey: state.uri.queryParameters['plate'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.vehicleHistory,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return VehicleHistoryPage(vehicleId: id);
            },
            routes: [
              GoRoute(
                path: 'visit/new',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return AddVisitPage(vehicleId: id);
                },
              ),
              GoRoute(
                path: 'visit/:visitId/edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  final visitId = int.tryParse(state.pathParameters['visitId'] ?? '') ?? 0;
                  return AddVisitPage(vehicleId: id, visitId: visitId);
                },
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.parts,
            builder: (context, state) => const PartsPage(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (context, state) => const CustomersPage(),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            builder: (context, state) => const SchedulePage(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
