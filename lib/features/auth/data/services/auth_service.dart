// lib/features/auth/services/auth_service.dart
// Mirrors frontend/src/services/auth.service.js

import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/shared_preferences_singleton.dart';
import '../models/auth_models.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;
  static const _tokenKey = kAuthTokenKey;
  static const _userKey = 'user';

  Dio get _dio => _client.dio;

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token']?.toString() ?? '';
    await Prefs.setString(_tokenKey, token);
    await Prefs.setString(_userKey, jsonEncode(data['user']));
    _client.setToken(token);
  }

  Future<void> clearSession() async {
    await Prefs.remove(_tokenKey);
    await Prefs.remove(_userKey);
    _client.clearToken();
  }

  Future<bool> isAuthenticated() async {
    final token = Prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<UserModel?> getCachedUser() async {
    final raw = Prefs.getString(_userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  Future<void> initToken() => _client.initToken();

  Future<UserModel> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data['data'];
    await _saveSession(data);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> register(RegisterRequest req) async {
    final res = await _dio.post('/auth/register', data: req.toJson());
    final data = res.data['data'];
    await _saveSession(data);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> loginWithClerk({
    required String clerkUserId,
    String role = 'student',
    String? division,
    String? subject,
    String? teacherName,
    String? studentUsername,
  }) async {
    final res = await _dio.post('/auth/clerk', data: {
      'clerkUserId': clerkUserId,
      'role': role,
      if (division != null) 'division': division,
      if (subject != null) 'subject': subject,
      if (teacherName != null) 'teacherName': teacherName,
      if (studentUsername != null) 'studentUsername': studentUsername,
    });
    final data = res.data['data'];
    await _saveSession(data);
    return UserModel.fromJson(data['user']);
  }

  Future<UserModel> getCurrentUser() async {
    final res = await _dio.get('/auth/me');
    return UserModel.fromJson(res.data['data']);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.put('/auth/profile', data: data);
    final user = UserModel.fromJson(res.data['data']);
    await Prefs.setString(_userKey, jsonEncode(res.data['data']));
    return user;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await clearSession();
  }

  Future<Map<String, dynamic>> lookupTeacher(String username) async {
    final res = await _dio.get('/auth/assistant/teacher/$username');
    return res.data['data'];
  }

  Future<void> sendCodeToTeacher({
    required String teacherUsername,
    required String assistantEmail,
  }) async {
    await _dio.post('/auth/assistant/send-code', data: {
      'teacherUsername': teacherUsername,
      'assistantEmail': assistantEmail,
    });
  }

  Future<void> verifyTeacherCode({
    required String teacherUsername,
    required String code,
  }) async {
    await _dio.post('/auth/assistant/verify-code', data: {
      'teacherUsername': teacherUsername,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> lookupStudent(String username) async {
    final res = await _dio.get('/auth/parent/student/$username');
    return res.data['data'];
  }

  Future<void> sendCodeToStudent({
    required String studentUsername,
    required String parentEmail,
  }) async {
    await _dio.post('/auth/parent/send-code', data: {
      'studentUsername': studentUsername,
      'parentEmail': parentEmail,
    });
  }

  Future<void> verifyParentCode({
    required String studentUsername,
    required String code,
  }) async {
    await _dio.post('/auth/parent/verify-code', data: {
      'studentUsername': studentUsername,
      'code': code,
    });
  }
}
