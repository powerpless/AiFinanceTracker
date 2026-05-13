import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/token_storage.dart';
import 'data/auth_api.dart';
import 'data/auth_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.username,
    this.errorMessage,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage,
    );
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Counter that the API client increments when a refresh attempt fails.
/// The auth controller listens to it to flip status → unauthenticated.
final forcedLogoutSignalProvider =
    Provider<ValueNotifier<int>>((ref) => ValueNotifier(0));

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final signal = ref.watch(forcedLogoutSignalProvider);
  return ApiClient.create(
    tokenStorage: storage,
    onUnauthorized: () async {
      await storage.clear();
      signal.value = signal.value + 1;
    },
  );
});

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final authApiProvider =
    Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final signal = ref.watch(forcedLogoutSignalProvider);
    signal.addListener(_handleForcedLogout);
    ref.onDispose(() => signal.removeListener(_handleForcedLogout));
    return const AuthState.unknown();
  }

  void _handleForcedLogout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> bootstrap() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(errorMessage: null);
    try {
      final api = ref.read(authApiProvider);
      final storage = ref.read(tokenStorageProvider);
      final tokens = await api.login(
        LoginRequest(username: username, password: password),
      );
      await storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        username: username,
      );
      return true;
    } on DioException catch (e) {
      final apiErr = e.error;
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            apiErr is ApiException ? apiErr.message : 'Failed to log in',
      );
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String confirmPassword,
    required String firstName,
    required String lastName,
  }) async {
    state = state.copyWith(errorMessage: null);
    try {
      final api = ref.read(authApiProvider);
      await api.register(RegisterRequest(
        username: username,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
      ));
      return await login(username, password);
    } on DioException catch (e) {
      final apiErr = e.error;
      state = state.copyWith(
        errorMessage:
            apiErr is ApiException ? apiErr.message : 'Failed to register',
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Stateless logout — ignore network errors
    }
    await ref.read(tokenStorageProvider).clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
