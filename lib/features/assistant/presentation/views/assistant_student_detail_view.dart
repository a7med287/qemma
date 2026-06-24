import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/models/assistant_models.dart';
import '../../data/repositories/assistant_repository.dart';
import 'widgets/assistant_student_detail_body.dart';

class AssistantStudentDetailView extends StatefulWidget {
  static const routeName = '/assistant-teacher/student-detail';

  final String studentId;
  const AssistantStudentDetailView({super.key, required this.studentId});

  @override
  State<AssistantStudentDetailView> createState() => _AssistantStudentDetailViewState();
}

class _AssistantStudentDetailViewState extends State<AssistantStudentDetailView> {
  StudentDetailResponse? _data;
  bool _loading = true;
  String? _error;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getStudentDetail(widget.studentId);
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل بيانات الطالب'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('تفاصيل الطالب',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 18.sp,
          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            SizedBox(height: 12.h),
            Text(_error!, style: TextStyle(fontFamily: 'Cairo',
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            SizedBox(height: 16.h),
            ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return Center(
        child: Text('تعذّر تحميل بيانات الطالب',
            style: TextStyle(fontFamily: 'Cairo',
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
      );
    }

    final student = data.student;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudentDetailHeader(student: student, isDark: isDark),
          SizedBox(height: 16.h),
          ContactInfoRow(student: student, isDark: isDark),
          SizedBox(height: 20.h),
          Text('📊 ملخص الاختبارات',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
          SizedBox(height: 12.h),
          ExamSummaryGrid(summary: data.examSummary, isDark: isDark),
          SizedBox(height: 20.h),
          if (student.enrollments.isNotEmpty) ...[
            Text('📚 الكورسات المسجل فيها',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
            SizedBox(height: 12.h),
            ...student.enrollments.map((e) => EnrollmentItem(enrollment: e, isDark: isDark)),
            SizedBox(height: 20.h),
          ],
          if (data.recentAttempts.isNotEmpty) ...[
            Text('🎯 آخر الاختبارات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
            SizedBox(height: 12.h),
            ...data.recentAttempts.map((a) => RecentAttemptItem(attempt: a, isDark: isDark)),
          ],
        ],
      ),
    );
  }
}
