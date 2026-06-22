// lib/features/auth/cubits/auth_cubit.dart
// Flutter equivalent of useAuth.js hook

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';

// ── States ────────────────────────────────────────────────────
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ─────────────────────────────────────────────────────
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  UserModel? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;

  bool get isAuthenticated => state is AuthAuthenticated;

  // ── Check auth on app start ───────────────────────────────────
  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final hasToken = await _authService.isAuthenticated();
      if (!hasToken) { emit(AuthUnauthenticated()); return; }

      await _authService.initToken();
      final user = await _authService.getCurrentUser();
      emit(AuthAuthenticated(user));
    } catch (_) {
      await _authService.clearSession();
      emit(AuthUnauthenticated());
    }
  }

  // ── Local login ───────────────────────────────────────────────
  Future<UserModel> login(String email, String password) async {
    emit(AuthLoading());
    try {
      await _authService.clearSession();
      final user = await _authService.login(email, password);
      emit(AuthAuthenticated(user));
      return user;
    } catch (e) {
      emit(AuthError(_extractError(e)));
      rethrow;
    }
  }

  // ── Local register ────────────────────────────────────────────
  Future<UserModel> register(RegisterRequest req) async {
    emit(AuthLoading());
    try {
      await _authService.clearSession();
      final user = await _authService.register(req);
      emit(AuthAuthenticated(user));
      return user;
    } catch (e) {
      emit(AuthError(_extractError(e)));
      rethrow;
    }
  }

  // ── Clerk auth ────────────────────────────────────────────────
  Future<UserModel> loginWithClerk({
    required String clerkUserId,
    String role             = 'student',
    String? division,
    String? subject,
    String? teacherName,
    String? studentUsername,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authService.loginWithClerk(
        clerkUserId:     clerkUserId,
        role:            role,
        division:        division,
        subject:         subject,
        teacherName:     teacherName,
        studentUsername: studentUsername,
      );
      emit(AuthAuthenticated(user));
      return user;
    } catch (e) {
      await _authService.clearSession();
      emit(AuthError(_extractError(e)));
      rethrow;
    }
  }

  // ── Update profile ────────────────────────────────────────────
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = await _authService.updateProfile(data);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_extractError(e)));
      rethrow;
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.logout();
    emit(AuthUnauthenticated());
  }

  String _extractError(dynamic e) {
    if (e is Exception) return e.toString().replaceAll('Exception: ', '');
    return 'حدث خطأ غير متوقع';
  }
}