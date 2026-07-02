/// Canonical route paths and names.
///
/// Using named routes everywhere (via [go]/[goNamed]/[pushNamed]) keeps
/// navigation refactor-safe: paths change in one place without touching calls.
abstract final class RoutePaths {
  const RoutePaths._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home';
}

abstract final class RouteNames {
  const RouteNames._();

  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String login = 'login';
  static const String signup = 'signup';
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';
  static const String home = 'home';
}

/// Routes reachable while signed OUT. Everything else requires authentication.
const Set<String> unauthenticatedRoutes = {
  RoutePaths.welcome,
  RoutePaths.login,
  RoutePaths.signup,
  RoutePaths.forgotPassword,
  RoutePaths.resetPassword,
};
