class AssistantDashboardData {
  const AssistantDashboardData({
    required this.studentsCount,
    required this.activeChats,
    required this.pendingGrading,
    required this.unreadCount,
    required this.teacherName,
    required this.teacherId,
    this.recentAttempts = const [],
  });

  final int studentsCount;
  final int activeChats;
  final int pendingGrading;
  final int unreadCount;
  final String teacherName;
  final String teacherId;
  final List<Map<String, dynamic>> recentAttempts;

  factory AssistantDashboardData.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>? ?? json;
    final teacher = info['teacher'] as Map<String, dynamic>?;
    return AssistantDashboardData(
      studentsCount: info['studentsCount'] ?? json['studentsCount'] ?? 0,
      activeChats: info['activeChats'] ?? json['activeChats'] ?? 0,
      pendingGrading: info['pendingGrading'] ?? json['pendingGrading'] ?? 0,
      unreadCount: info['unreadCount'] ?? json['unreadCount'] ?? 0,
      teacherName: teacher?['name'] ?? info['teacherName'] ?? '',
      teacherId: teacher?['id'] ?? teacher?['_id'] ?? info['teacherId'] ?? '',
      recentAttempts: (json['recentAttempts'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

class AssistantStudent {
  final String id;
  final String name;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? division;
  final List<String> enrolledCourses;

  const AssistantStudent({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phone,
    this.avatar,
    this.division,
    this.enrolledCourses = const [],
  });

  factory AssistantStudent.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return AssistantStudent(
      id: user['_id'] ?? user['id'] ?? json['_id'] ?? json['id'] ?? '',
      name: user['name'] ?? '',
      username: user['username'],
      email: user['email'],
      phone: user['phone'],
      avatar: user['avatar'],
      division: json['division'] ?? user['division'],
      enrolledCourses: (json['courses'] as List?)
              ?.map((e) => e is Map ? (e['title'] ?? '').toString() : e.toString())
              .toList() ??
          [],
    );
  }
}
