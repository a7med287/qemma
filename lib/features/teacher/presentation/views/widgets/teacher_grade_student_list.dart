import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';
import 'teacher_grade_exam_card.dart';

class TeacherGradeStudentList extends StatelessWidget {
  const TeacherGradeStudentList({
    super.key,
    required this.attempts,
    required this.isPending,
    required this.loading,
    this.onAutoGrade,
    this.onView,
    this.page = 1,
    this.totalPages = 1,
    this.onPreviousPage,
    this.onNextPage,
  });

  final List<Map<String, dynamic>> attempts;
  final bool isPending;
  final bool loading;
  final Function(String attemptId)? onAutoGrade;
  final Function(String attemptId)? onView;
  final int page;
  final int totalPages;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, size: 48, color: fieldLabelColor(context)),
            SizedBox(height: 12.h),
            Text('لا توجد بيانات لعرضها حالياً',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldLabelColor(context))),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: attempts.length,
            separatorBuilder: (_, __) => SizedBox(height: 8.h),
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final attemptId = attempt['id']?.toString() ?? '';
              return TeacherGradeExamCard(
                attempt: attempt,
                isPending: isPending,
                onAutoGrade: onAutoGrade != null ? () => onAutoGrade!(attemptId) : null,
                onView: onView != null ? () => onView!(attemptId) : null,
              );
            },
          ),
        ),
        if (totalPages > 1)
          Container(
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(onPressed: page > 1 ? onPreviousPage : null, icon: const Icon(Icons.chevron_right)),
                Text('$page / $totalPages',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldTextColor(context))),
                IconButton(onPressed: page < totalPages ? onNextPage : null, icon: const Icon(Icons.chevron_left)),
              ],
            ),
          ),
      ],
    );
  }
}
