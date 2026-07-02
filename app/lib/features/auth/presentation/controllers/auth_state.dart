import '../../../../core/session/auth_status.dart';
import '../../domain/entities/auth_user.dart';

/// Immutable UI state for the auth feature.
///
/// [status] is the coarse session state consumed by the router guard;
/// [submitting]/[errorMessage]/[fieldErrors] drive the auth forms.
class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.submitting = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.infoMessage,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool submitting;
  final String? errorMessage;
  final Map<String, List<String>> fieldErrors;

  /// Non-error notice (e.g. "reset link sent").
  final String? infoMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool clearUser = false,
    bool? submitting,
    String? errorMessage,
    bool clearError = false,
    Map<String, List<String>>? fieldErrors,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
