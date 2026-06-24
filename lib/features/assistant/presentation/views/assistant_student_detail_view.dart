import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/models/assistant_models.dart';
import '../../data/repositories/assistant_repository.dart';

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
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student Header ──
          Container(
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
                  backgroundImage: student.avatar != null
                      ? NetworkImage(student.avatar!)
                      : null,
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
          ),
          SizedBox(height: 16.h),

          // ── Contact Info ──
          Row(
            children: [
              Expanded(
                child: _contactCard(
                  icon: Icons.email_outlined,
                  iconColor: const Color(0xFF2563EB),
                  label: 'البريد الإلكتروني',
                  value: student.email ?? 'غير محدد',
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _contactCard(
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFF059669),
                  label: 'رقم الهاتف',
                  value: student.phone ?? 'غير محدد',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Exam Summary ──
          Text('📊 ملخص الاختبارات',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
          SizedBox(height: 12.h),
          _buildExamSummary(data.examSummary, isDark),
          SizedBox(height: 20.h),

          // ── Enrolled Courses ──
          if (student.enrollments.isNotEmpty) ...[
            Text('📚 الكورسات المسجل فيها',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
            SizedBox(height: 12.h),
            ...student.enrollments.map((e) => Container(
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
                        Text(e.courseTitle,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, fontFamily: 'Cairo', color: textPrimary)),
                        Text('سُجّل في ${_formatDate(e.enrolledAt)}',
                            style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('${e.progress.round()}%',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, fontFamily: 'Cairo', color: const Color(0xFF2563EB))),
                      SizedBox(height: 4.h),
                      SizedBox(
                        width: 50.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3.r),
                          child: LinearProgressIndicator(
                            value: e.progress / 100,
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
            )),
            SizedBox(height: 20.h),
          ],

          // ── Recent Exam Attempts ──
          if (data.recentAttempts.isNotEmpty) ...[
            Text('🎯 آخر الاختبارات',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15.sp, fontFamily: 'Cairo', color: textPrimary)),
            SizedBox(height: 12.h),
            ...data.recentAttempts.map((a) => Container(
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
                    a.isPassed ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: a.isPassed ? const Color(0xFF059669) : const Color(0xFFEF4444),
                    size: 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.examTitle,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp, fontFamily: 'Cairo', color: textPrimary)),
                        Text('${a.courseTitle} · ${_formatDate(a.submittedAt)}',
                            style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _buildScoreBadge(a.score),
                  SizedBox(width: 8.w),
                  Text('${a.rawScore.round()}/${a.totalMarks.round()}',
                      style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: textSecondary)),
                ],
              ),
            )),
          ],
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

  Widget _contactCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
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

  Widget _buildExamSummary(ExamSummary summary, bool isDark) {
    final items = [
      _ExamStat(label: 'إجمالي المحاولات', value: '${summary.totalAttempts}', color: const Color(0xFF6366F1)),
      _ExamStat(label: 'متوسط الدرجات', value: summary.avgScore != null ? '${summary.avgScore!.round()}%' : '-', color: const Color(0xFF2563EB)),
      _ExamStat(label: 'اختبارات ناجحة', value: '${summary.passedCount}', color: const Color(0xFF059669)),
      _ExamStat(label: 'اختبارات راسبة', value: '${summary.failedCount}', color: const Color(0xFFEF4444)),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, childAspectRatio: 0.8, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildExamStatCard(items[i], isDark),
    );
  }

  Widget _buildExamStatCard(_ExamStat stat, bool isDark) {
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
          Text(stat.value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo', color: stat.color)),
          SizedBox(height: 4.h),
          Text(stat.label,
              textAlign: TextAlign.center,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 8.sp, fontFamily: 'Cairo',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(double? score) {
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
    final color = score >= 75
        ? const Color(0xFF059669)
        : score >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final bg = score >= 75
        ? const Color(0xFFD1FAE5)
        : score >= 50
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4.r)),
      child: Text('${score.round()}%',
          style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: color)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
}

class _ExamStat {
  final String label;
  final String value;
  final Color color;
  const _ExamStat({required this.label, required this.value, required this.color});
}