import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/group_categories.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/error/not_found_screen.dart';
import '../../features/group_setup/choose_group_screen.dart';
import '../../features/group_setup/create_group_screen.dart';
import '../../features/group_setup/invite_screen.dart';
import '../../features/group_setup/join_group_screen.dart';
import '../../features/settings/alert_map_screen.dart';
import '../../features/settings/alerts_screen.dart';
import '../../features/settings/change_email_screen.dart';
import '../../features/settings/change_password_screen.dart';
import '../../features/settings/members_screen.dart';
import '../../features/settings/privacy_controls_screen.dart';
import '../../features/settings/view_profile_screen.dart';
import '../../features/shell/home_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../providers/app_startup_provider.dart';
import '../../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final splashHold = ref.watch(minimumSplashProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading || splashHold.isLoading) return null;

      final loggedIn = authState.asData?.value != null;

      if (!loggedIn) {
        if (state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup' ||
            state.matchedLocation == '/forgot-password') {
          return null;
        }
        return '/login';
      }

      if (state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password' ||
          state.matchedLocation == '/') {
        return '/home';
      }

      if (state.matchedLocation == '/members' &&
          (state.uri.queryParameters['groupId'] ?? '').isEmpty) {
        return '/home';
      }
      return null;
    },
    errorBuilder: (context, state) =>
        NotFoundScreen(location: state.uri.toString()),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeShell()),
      GoRoute(
        path: '/choose-group',
        builder: (context, state) => const ChooseGroupScreen(),
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) => CreateGroupScreen(
          category:
              state.uri.queryParameters['category'] ?? GroupCategories.custom,
        ),
      ),
      GoRoute(
        path: '/join-group',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: '/invite',
        builder: (context, state) => InviteScreen(
          code: state.uri.queryParameters['code'] ?? '',
          name: state.uri.queryParameters['name'] ?? 'Your group',
        ),
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
      GoRoute(
        path: '/alert-map',
        builder: (context, state) => AlertMapScreen(
          latitude: double.tryParse(state.uri.queryParameters['lat'] ?? '') ?? 0,
          longitude:
              double.tryParse(state.uri.queryParameters['lng'] ?? '') ?? 0,
          name: state.uri.queryParameters['name'] ?? '',
        ),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) =>
            MembersScreen(groupId: state.uri.queryParameters['groupId'] ?? ''),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/change-email',
        builder: (context, state) => const ChangeEmailScreen(),
      ),
    ],
  );
});
