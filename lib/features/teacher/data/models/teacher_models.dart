class TeacherDashboardData {
  const TeacherDashboardData({
    required this.totalStudents,
    required this.activeCourses,
    required this.passRate,
    required this.upcomingSchedules,
    required this.subjects,
    required this.teacherName,
    this.unreadCount = 0,
  });

  final int totalStudents;
  final int activeCourses;
  final double? passRate;
  final List<ScheduleItem> upcomingSchedules;
  final List<String> subjects;
  final String teacherName;
  final int unreadCount;
}

class TeacherCourse {
  const TeacherCourse({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.level,
    this.price = 0,
    this.duration,
    this.isPublished = false,
    this.thumbnail,
    this.stats,
  });

  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? level;
  final int price;
  final int? duration;
  final bool isPublished;
  final String? thumbnail;
  final CourseStats? stats;

  factory TeacherCourse.fromJson(Map<String, dynamic> json) {
    final statsJson = json['stats'] as Map<String, dynamic>?;
    return TeacherCourse(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'],
      level: json['level'],
      price: (json['price'] ?? 0) is int ? json['price'] as int : int.tryParse('${json['price'] ?? 0}') ?? 0,
      duration: json['duration'] is int ? json['duration'] as int : int.tryParse('${json['duration'] ?? ''}'),
      isPublished: json['isPublished'] ?? false,
      thumbnail: json['thumbnail'],
      stats: statsJson != null ? CourseStats.fromJson(statsJson) : null,
    );
  }

  TeacherCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? level,
    int? price,
    int? duration,
    bool? isPublished,
    String? thumbnail,
    CourseStats? stats,
  }) {
    return TeacherCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      isPublished: isPublished ?? this.isPublished,
      thumbnail: thumbnail ?? this.thumbnail,
      stats: stats ?? this.stats,
    );
  }
}

class CourseStats {
  const CourseStats({this.enrollments = 0, this.lessons = 0});

  final int enrollments;
  final int lessons;

  factory CourseStats.fromJson(Map<String, dynamic> json) {
    return CourseStats(
      enrollments: json['enrollments'] ?? 0,
      lessons: json['lessons'] ?? 0,
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.title,
    this.content,
    this.summary,
    this.order = 0,
    this.isPublished = false,
    this.videoUrl,
    this.pdfUrl,
  });

  final String id;
  final String courseId;
  final String title;
  final String? content;
  final String? summary;
  final int order;
  final bool isPublished;
  final String? videoUrl;
  final String? pdfUrl;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'],
      summary: json['summary'],
      order: json['order'] ?? 0,
      isPublished: json['isPublished'] ?? false,
      videoUrl: json['videoUrl'],
      pdfUrl: json['pdfUrl'],
    );
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.type,
    this.meetingLink,
  });

  final String id;
  final String title;
  final String date;
  final String startTime;
  final String type;
  final String? meetingLink;

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      type: json['type'] ?? 'online',
      meetingLink: json['meetingLink'],
    );
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    this.body = '',
    this.type = 'general',
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      isRead: json['isRead'] == true || json['read'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class TeacherContestItem {
  final String id;
  final String title;
  final String? description;
  final int duration;
  final int questionCount;
  final String difficulty;
  final String stream;
  final String status;
  final String startTime;
  final bool isTest;
  final bool canManage;
  final int participationCount;

  const TeacherContestItem({
    required this.id,
    required this.title,
    this.description,
    required this.duration,
    required this.questionCount,
    required this.difficulty,
    this.stream = '',
    this.status = 'upcoming',
    this.startTime = '',
    this.isTest = false,
    this.canManage = true,
    this.participationCount = 0,
  });

  factory TeacherContestItem.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] as Map<String, dynamic>?;
    return TeacherContestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      duration: _toInt(json['duration']),
      questionCount: _toInt(json['questionCount'] ?? counts?['questions']),
      difficulty: json['difficulty']?.toString() ?? 'Medium',
      stream: json['stream']?.toString() ?? '',
      status: json['status']?.toString() ?? 'upcoming',
      startTime: json['startTime']?.toString() ?? '',
      isTest: json['isTest'] == true,
      canManage: json['canManage'] != false,
      participationCount: _toInt(json['participationCount'] ?? counts?['participations']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class ContestOption {
  final String id;
  final String text;
  final bool isCorrect;

  const ContestOption({required this.id, required this.text, required this.isCorrect});

  factory ContestOption.fromJson(Map<String, dynamic> json) => ContestOption(
    id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
    isCorrect: json['isCorrect'] == true,
  );
}

class ContestQuestion {
  final String id;
  final String text;
  final String questionType;
  final int pointValue;
  final List<ContestOption> options;
  final bool aiGenerated;
  final String? authorName;
  final bool canDelete;

  const ContestQuestion({
    required this.id,
    required this.text,
    this.questionType = 'mcq',
    this.pointValue = 1,
    this.options = const [],
    this.aiGenerated = false,
    this.authorName,
    this.canDelete = false,
  });

  factory ContestQuestion.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List?)
            ?.map((e) => ContestOption.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ContestQuestion(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      questionType: json['questionType']?.toString() ?? 'mcq',
      pointValue: TeacherContestItem._toInt(json['pointValue']),
      options: opts,
      aiGenerated: json['aiGenerated'] == true,
      authorName: json['authorName']?.toString(),
      canDelete: json['canDelete'] == true,
    );
  }
}

class NotificationsPageData {
  const NotificationsPageData({
    required this.notifications,
    this.unreadCount = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final int page;
  final int totalPages;

  factory NotificationsPageData.fromJson(Map<String, dynamic> json) {
    final notifs = (json['notifications'] as List? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationsPageData(
      notifications: notifs,
      unreadCount: json['unreadCount'] as int? ?? notifs.where((n) => !n.isRead).length,
      page: json['pagination']?['page'] as int? ?? 1,
      totalPages: json['pagination']?['totalPages'] as int? ?? 1,
    );
  }
}
