import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_status.dart';
import '../../app/screens/home_screen.dart';
import '../../app/screens/route_error_screen.dart';
import '../../app/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/clipboard/presentation/screens/clipboard_screen.dart';
import '../../features/transfer/presentation/screens/transfer_screen.dart';
import '../../features/devices/presentation/screens/nearby_devices_screen.dart';
import '../../features/devices/presentation/screens/pair_device_screen.dart';
import '../../features/devices/presentation/screens/registered_devices_screen.dart';
import 'route_paths.dart';

/// Bridges a Riverpod provider to a [Listenable] so GoRouter re-evaluates its
/// `redirect` whenever the watched value changes (here: [authStatusProvider]).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthStatus>(
      authStatusProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<AuthStatus> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// The application router with an auth-aware redirect guard.
///
/// Guard rules:
///   * status `unknown`  → hold on splash while the session restores;
///   * signed out         → allow only [unauthenticatedRoutes], else → welcome;
///   * signed in          → bounce off splash/auth routes → home.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: RouteNames.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: RouteNames.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          token: state.uri.queryParameters['token'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.devices,
        name: RouteNames.devices,
        builder: (context, state) => const RegisteredDevicesScreen(),
        routes: [
          GoRoute(
            path: 'pair',
            name: RouteNames.pairDevice,
            builder: (context, state) => const PairDeviceScreen(),
          ),
          GoRoute(
            path: 'nearby',
            name: RouteNames.nearbyDevices,
            builder: (context, state) => const NearbyDevicesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.clipboard,
        name: RouteNames.clipboard,
        builder: (context, state) => const ClipboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.transfers,
        name: RouteNames.transfers,
        builder: (context, state) => const TransferScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        RouteErrorScreen(error: state.error?.toString()),
    redirect: (context, state) {
      final status = ref.read(authStatusProvider);
      final location = state.matchedLocation;
      final onSplash = location == RoutePaths.splash;

      // Session still resolving: keep the user on splash.
      if (status == AuthStatus.unknown) {
        return onSplash ? null : RoutePaths.splash;
      }

      final loggedIn = status == AuthStatus.authenticated;
      final onAuthRoute = unauthenticatedRoutes.contains(location);

      if (!loggedIn) {
        // Signed out: only auth routes allowed.
        return onAuthRoute ? null : RoutePaths.welcome;
      }

      // Signed in: never sit on splash or an auth route.
      if (onSplash || onAuthRoute) return RoutePaths.home;
      return null;
    },
  );
});
