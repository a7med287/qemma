// lib/features/auth/models/auth_models.dart
import 'package:qemma/constants.dart';

enum UserRole { student, teacher, assistantTeacher, parent }

extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.student:          return 'student';
      case UserRole.teacher:          return 'teacher';
      case UserRole.assistantTeacher: return 'assistant_teacher';
      case UserRole.parent:           return 'parent';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student:          return 'طالب';
      case UserRole.teacher:          return 'مدرس';
      case UserRole.assistantTeacher: return 'مدرس مساعد';
      case UserRole.parent:           return 'ولي أمر';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'teacher':           return UserRole.teacher;
      case 'assistant_teacher': return UserRole.assistantTeacher;
      case 'parent':            return UserRole.parent;
      default:                  return UserRole.student;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? username;
  final UserRole role;
  final String? division;
  final String? subject;
  final String? phone;
  final String? authProvider;
  final bool hasPassword;
  final String? avatar;
  final List<String> specialties;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.username,
    required this.role,
    this.division,
    this.subject,
    this.phone,
    this.authProvider,
    this.hasPassword = true,
    this.avatar,
    this.specialties = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>?;
    final rawSpecialties = teacher?['specialties'];
    final specialties = (rawSpecialties is List)
        ? rawSpecialties.map((e) => e.toString()).toList()
        : <String>[];
    return UserModel(
      id:           json['_id']          ?? json['id'] ?? '',
      name:         json['name']         ?? '',
      email:        json['email']        ?? '',
      username:     json['username'],
      role:         UserRoleExtension.fromString(json['role'] ?? 'student'),
      division:     json['division'],
      subject:      json['subject'],
      phone:        json['phone'],
      authProvider: json['authProvider'],
      hasPassword:  json['hasPassword']  ?? true,
      avatar:       json['avatar'],
      specialties:  specialties,
    );
  }

  String get dashboardRoute {
    switch (role) {
      case UserRole.student:          return kStudentHomeRoute;
      case UserRole.teacher:          return '/teacher/dashboard';
      case UserRole.assistantTeacher: return '/assistant-teacher/dashboard';
      case UserRole.parent:           return '/parent/dashboard';
    }
  }
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? phone;
  final String? division;
  final String? subject;
  final String? teacherName;
  final String? studentUsername;

  const RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.division,
    this.subject,
    this.teacherName,
    this.studentUsername,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name':     name,
      'email':    email,
      'password': password,
      'role':     role.value,
    };
    if (phone != null && phone!.isNotEmpty) map['phone'] = phone;
    if (role == UserRole.student && division != null) map['division'] = division;
    if ((role == UserRole.teacher || role == UserRole.assistantTeacher) && subject != null) {
      map['subject'] = subject;
    }
    if (role == UserRole.assistantTeacher && teacherName != null) {
      map['teacherName'] = teacherName;
    }
    if (role == UserRole.parent && studentUsername != null) {
      map['studentUsername'] = studentUsername;
    }
    return map;
  }
}