import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../data/models/assistant_models.dart';

class StudentDetailHeader extends StatelessWidget {
  final AssistantStudent student;
  final bool isDark;

  const StudentDetailHeader({
    super.key,
    required this.student,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: const LinearGradient(
          colors: [Color(0x266366F1), Color(0x1A7C3AED)],
        ),
        border: Border.all(color: const Color(0x336366F1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundImage: student.avatar != null ? NetworkImage(student.avatar!) : null,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(student.name.isNotEmpty ? student.name[0] : 'ط',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.sp, fontFamily: 'Cairo', color: textPrimary)),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 4.w,
                  runSpacing: 4.h,
                  children: [
                    if (student.username != null)
                      _chip('@${student.username}', const Color(0xFF6366F1),
                          isDark ? const Color(0x336366F1) : const Color(0xFFEDE9FE)),
                    if (student.gradeLevel != null && student.gradeLevel!.isNotEmpty)
                      _chip(student.gradeLevel!, const Color(0xFF059669),
                          isDark ? const Color(0x33059669) : const Color(0xFFD1FAE5)),
                    if (student.stream != null && student.stream!.isNotEmpty)
                      _chip(student.stream!, const Color(0xFF2563EB),
                          isDark ? const Color(0x332563EB) : const Color(0xFFDBEAFE)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text('${student.coins}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22.sp, fontFamily: 'Cairo', color: const Color(0xFFF59E0B))),
              Text('عملات',
                  style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color textColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: textColor)),
    );
  }
}

class ContactInfoRow extends StatelessWidget {
  final AssistantStudent student;
  final bool isDark;

  const ContactInfoRow({
    super.key,
    required this.student,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ContactCard(
          icon: Icons.email_outlined,
          iconColor: const Color(0xFF2563EB),
          label: 'البريد الإلكتروني',
          value: student.email ?? 'غير محدد',
          isDark: isDark,
        )),
        SizedBox(width: 8.w),
        Expanded(child: _ContactCard(
          icon: Icons.phone_outlined,
          iconColor: const Color(0xFF059669),
          label: 'رقم الهاتف',
          value: student.phone ?? 'غير محدد',
          isDark: isDark,
        )),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isDark;

  const _ContactCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ExamSummaryGrid extends StatelessWidget {
  final ExamSummary summary;
  final bool isDark;

  const ExamSummaryGrid({
    super.key,
    required this.summary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _ExamStatData(label: 'إجمالي المحاولات', value: '${summary.totalAttempts}', color: const Color(0xFF6366F1)),
      _ExamStatData(label: 'متوسط الدرجات', value: summary.avgScore != null ? '${summary.avgScore!.round()}%' : '-', color: const Color(0xFF2563EB)),
      _ExamStatData(label: 'اختبارات ناجحة', value: '${summary.passedCount}', color: const Color(0xFF059669)),
      _ExamStatData(label: 'اختبارات راسبة', value: '${summary.failedCount}', color: const Color(0xFFEF4444)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 0.8, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _ExamStatCard(item: items[i], isDark: isDark),
    );
  }
}

class _ExamStatData {
  final String label;
  final String value;
  final Color color;
  const _ExamStatData({required this.label, required this.value, required this.color});
}

class _ExamStatCard extends StatelessWidget {
  final _ExamStatData item;
  final bool isDark;
  const _ExamStatCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: item.color)),
          SizedBox(height: 4.h),
          Text(item.label,
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class EnrollmentItem extends StatelessWidget {
  final Enrollment enrollment;
  final bool isDark;

  const EnrollmentItem({
    super.key,
    required this.enrollment,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.school, color: const Color(0xFF6366F1), size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(enrollment.courseTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, fontFamily: 'Cairo', color: textPrimary)),
                Text('سُجّل في ${_formatDate(enrollment.enrolledAt)}',
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${enrollment.progress.round()}%',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, fontFamily: 'Cairo', color: const Color(0xFF2563EB))),
              SizedBox(height: 4.h),
              SizedBox(
                width: 50.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.r),
                  child: LinearProgressIndicator(
                    value: enrollment.progress / 100,
                    minHeight: 5.h,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

class RecentAttemptItem extends StatelessWidget {
  final RecentAttempt attempt;
  final bool isDark;

  const RecentAttemptItem({
    super.key,
    required this.attempt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final score = attempt.score;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(
            attempt.isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: attempt.isPassed ? const Color(0xFF059669) : const Color(0xFFEF4444),
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attempt.examTitle,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, fontFamily: 'Cairo', color: textPrimary)),
                Text('${attempt.courseTitle} · ${_formatDate(attempt.submittedAt)}',
                    style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _ScoreBadge(score: score),
          SizedBox(width: 8.w),
          Text('${attempt.rawScore.round()}/${attempt.totalMarks.round()}',
              style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

class _ScoreBadge extends StatelessWidget {
  final double? score;

  const _ScoreBadge({this.score});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Text('لا يوجد',
            style: TextStyle(fontSize: 9.sp, fontFamily: 'Cairo', color: const Color(0xFF94A3B8))),
      );
    }
    final color = score! >= 75
        ? const Color(0xFF059669)
        : score! >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final bg = score! >= 75
        ? const Color(0xFFD1FAE5)
        : score! >= 50
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4.r)),
      child: Text('${score!.round()}%',
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: color)),
    );
  }
}
