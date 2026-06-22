class Teacher {
  final String id;
  final String teacherId;
  final String name;
  final String title;
  final String specialization;
  final double rating;
  final int reviewsCount;
  final int studentsCount;
  final bool verified;
  final int coursesCount;
  final int booksCount;
  final int yearsOfExperience;
  final String bio;
  final List<String> qualifications;
  final List<String> achievements;
  final List<String> subjects;
  final TeacherContact contact;
  final TeacherStats stats;
  final List<TeacherCourse> courses;
  final List<TeacherBook> books;
  final List<TeacherReview> reviews;
  final String? avatar;

  Teacher({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.title,
    required this.specialization,
    required this.rating,
    required this.reviewsCount,
    required this.studentsCount,
    required this.verified,
    required this.coursesCount,
    required this.booksCount,
    required this.yearsOfExperience,
    required this.bio,
    required this.qualifications,
    required this.achievements,
    required this.subjects,
    required this.contact,
    required this.stats,
    required this.courses,
    required this.books,
    required this.reviews,
    this.avatar,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) {
    final coursesList = (json['courses'] as List<dynamic>?)?.map((c) => TeacherCourse(
      id: c['id'].toString(),
      title: c['title'] as String? ?? '',
      price: (c['price'] as num?)?.toDouble() ?? 0,
      students: c['studentsCount'] ?? 0,
      rating: (c['ratingAvg'] as num?)?.toDouble() ?? 0,
      category: c['category'] as String? ?? '',
      level: c['level'] as String? ?? '',
    )).toList() ?? [];

    final booksList = (json['books'] as List<dynamic>?)?.map((b) => TeacherBook(
      id: b['id'].toString(),
      title: b['title'] as String? ?? '',
      price: (b['price'] as num?)?.toDouble() ?? 0,
      downloads: b['purchases'] ?? 0,
      rating: 0,
      subject: b['subject'] as String? ?? '',
    )).toList() ?? [];

    return Teacher(
      id: json['userId'].toString(),
      teacherId: json['id'].toString(),
      name: json['name'] as String? ?? 'مدرس',
      title: (json['specialties'] as List?)?[0] != null ? 'مدرس ${json['specialties'][0]}' : 'مدرس',
      specialization: (json['specialties'] as List?)?.join(' - ') ?? 'عام',
      rating: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      reviewsCount: 0,
      studentsCount: coursesList.fold(0, (sum, c) => sum + c.students),
      verified: json['verified'] as bool? ?? false,
      coursesCount: coursesList.length,
      booksCount: booksList.length,
      yearsOfExperience: 0,
      bio: json['bio'] as String? ?? 'لا توجد سيرة ذاتية',
      qualifications: [],
      achievements: [],
      subjects: (json['specialties'] as List?)?.cast<String>() ?? [],
      contact: TeacherContact(
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        location: '',
      ),
      stats: TeacherStats(
        totalHours: 0,
        completionRate: 0,
        responseTime: '',
        satisfaction: 0,
      ),
      courses: coursesList,
      books: booksList,
      reviews: [],
      avatar: json['avatar'] as String?,
    );
  }
}

class TeacherContact {
  final String email;
  final String phone;
  final String location;
  TeacherContact({required this.email, required this.phone, required this.location});
}

class TeacherStats {
  final int totalHours;
  final int completionRate;
  final String responseTime;
  final int satisfaction;
  TeacherStats({required this.totalHours, required this.completionRate, required this.responseTime, required this.satisfaction});
}

class TeacherCourse {
  final String id;
  final String title;
  final double price;
  final int students;
  final double rating;
  final String category;
  final String level;
  TeacherCourse({required this.id, required this.title, required this.price, required this.students, required this.rating, required this.category, required this.level});
}

class TeacherBook {
  final String id;
  final String title;
  final double price;
  final int downloads;
  final double rating;
  final String subject;
  TeacherBook({required this.id, required this.title, required this.price, required this.downloads, required this.rating, required this.subject});
}

class TeacherReview {
  final String id;
  final String studentName;
  final String date;
  final double rating;
  final String comment;
  TeacherReview({required this.id, required this.studentName, required this.date, required this.rating, required this.comment});
}
