/// Canonical route paths and names.
///
/// Using named routes everywhere (via [go]/[goNamed]) keeps navigation
/// refactor-safe: paths can change in one place without touching call sites.
abstract final class RoutePaths {
  const RoutePaths._();

  static const String welcome = '/welcome';
  static const String home = '/home';
}

/// Route names paired 1:1 with [RoutePaths]. Prefer these for navigation.
abstract final class RouteNames {
  const RouteNames._();

  static const String welcome = 'welcome';
  static const String home = 'home';
}
