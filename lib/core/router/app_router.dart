import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/home_map/home_map_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../providers/auth_provider.dart';
import '../../features/auth/signup_screen.dart';



final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final loggedIn = authState.asData?.value != null;

      if (!loggedIn) {
        if (state.matchedLocation == '/login' || state.matchedLocation == '/signup') return null;
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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    ],
  );
});