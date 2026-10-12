import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/group_categories.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/group_setup/choose_group_screen.dart';
import '../../features/group_setup/create_group_screen.dart';
import '../../features/group_setup/join_group_screen.dart';
import '../../features/settings/alerts_screen.dart';
import '../../features/settings/privacy_controls_screen.dart';
import '../../features/settings/view_profile_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final loggedIn = authState.asData?.value != null;

      if (!loggedIn) {
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup') {
          return null;
        }
        return '/login';
      }

      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/choose-group',
        builder: (context, state) => const ChooseGroupScreen(),
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => CreateGroupScreen(
          category: state.uri.queryParameters['category'] ??
              GroupCategories.custom,
        ),
      ),
      GoRoute(
        path: '/join-group',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/view-profile',
        builder: (context, state) => const ViewProfileScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyControlsScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
    ],
  );
});