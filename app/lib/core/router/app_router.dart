import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/auth_status.dart';
import '../../app/screens/home_screen.dart';
import '../../app/screens/route_error_screen.dart';
import '../../app/screens/welcome_screen.dart';
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

/// The application router.
///
/// A single [GoRouter] configured with a guard that reads [authStatusProvider].
/// The guard is the only place navigation authorization lives, keeping screens
/// free of auth branching.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.welcome,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    routes: [
      GoRoute(
        path: RoutePaths.welcome,
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        RouteErrorScreen(error: state.error?.toString()),
    redirect: (context, state) {
      final status = ref.read(authStatusProvider);
      final onWelcome = state.matchedLocation == RoutePaths.welcome;

      // Still resolving the session — let the current location render.
      if (status == AuthStatus.unknown) return null;

      final loggedIn = status == AuthStatus.authenticated;

      // Not signed in and trying to reach a protected route -> welcome.
      if (!loggedIn && !onWelcome) return RoutePaths.welcome;

      // Signed in but sitting on welcome -> home.
      if (loggedIn && onWelcome) return RoutePaths.home;

      return null;
    },
  );
});
