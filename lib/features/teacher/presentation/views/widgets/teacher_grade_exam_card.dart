import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherGradeExamCard extends StatelessWidget {
  const TeacherGradeExamCard({
    super.key,
    required this.attempt,
    required this.isPending,
    this.onAutoGrade,
    this.onView,
  });

  final Map<String, dynamic> attempt;
  final bool isPending;
  final VoidCallback? onAutoGrade;
  final VoidCallback? onView;

  String _getStudentName() => (attempt['student'] as Map?)?['user']?['name'] ?? '—';

  String _getStudentAvatar() {
    final name = _getStudentName();
    return name.isNotEmpty ? name[0] : '؟';
  }

  String _getExamTitle() => (attempt['exam'] as Map?)?['title'] ?? '—';

  String _getScore() {
    final score = attempt['score'];
    final totalMarks = (attempt['exam'] as Map?)?['totalMarks'];
    return score != null ? '$score/$totalMarks' : '—';
  }

  String _getDate() {
    final submittedAt = attempt['submittedAt'] as String?;
    if (submittedAt == null) return '—';
    try {
      if (submittedAt.length >= 16) {
        return submittedAt.substring(0, 16).replaceAll('T', ' ');
      }
      return submittedAt;
    } catch (_) { return '—'; }
  }

  int _getPercentage() {
    final score = (attempt['score'] as num?)?.toDouble() ?? 0;
    final totalMarks = (attempt['exam'] as Map?)?['totalMarks'] as num?;
    if (totalMarks == null || totalMarks == 0) return 0;
    return ((score / totalMarks) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _getPercentage();
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isPending ? const Color(0xFFF59E0B) : const Color(0xFF8B5CF6),
                  child: Text(_getStudentAvatar(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getStudentName(),
                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp, color: fieldTextColor(context))),
                      Text(_getExamTitle(),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: fieldLabelColor(context))),
                    ],
                  ),
                ),
                if (!isPending)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: percentage >= 70 ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(_getScore(),
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12.sp,
                            color: percentage >= 70 ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: fieldLabelColor(context)),
                SizedBox(width: 4.w),
                Text(_getDate(),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: fieldLabelColor(context))),
                const Spacer(),
                if (isPending)
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton.icon(
                      onPressed: onAutoGrade,
                      icon: const Icon(Icons.auto_fix_high, size: 14),
                      label: Text('تصحيح تلقائي', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 32.h,
                    child: ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.visibility, size: 14),
                      label: Text('عرض', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
