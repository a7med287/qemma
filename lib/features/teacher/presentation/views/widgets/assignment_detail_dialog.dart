import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_form_fields.dart';
import 'teacher_theme_helpers.dart';

class AssignmentDetailDialog extends StatelessWidget {
  const AssignmentDetailDialog({
    super.key,
    required this.assignment,
    required this.detailLoading,
    required this.onGradeSubmission,
    required this.onClose,
  });

  final Map<String, dynamic>? assignment;
  final bool detailLoading;
  final ValueChanged<Map<String, dynamic>> onGradeSubmission;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = assignment;
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  const Icon(Icons.assignment,
                      color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      a?['title'] ?? 'تفاصيل الواجب',
                      style: TextStyles.semiBold16.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            if (detailLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (a != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    teacherChip(
                        a['courseTitle'] ?? '', const Color(0xFF8B5CF6), isDark),
                    teacherChip(
                        '${(a['submissions'] as List?)?.length ?? 0} تسليم',
                        const Color(0xFF0891B2), isDark),
                    teacherChip('${a['maxScore'] ?? 0} درجة',
                        const Color(0xFF059669), isDark),
                    if (a['dueDate'] != null)
                      teacherChip(
                          (a['dueDate'] as String).substring(0, 10),
                          const Color(0xFFF59E0B), isDark),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(),
              if ((a['submissions'] as List?)?.isEmpty ?? true)
                Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      Icon(Icons.pending_actions,
                          size: 48,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                      SizedBox(height: 12.h),
                      Text('لا توجد تسليمات بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            color: fieldLabelColor(context),
                          )),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(16.w),
                    itemCount:
                        (a['submissions'] as List?)?.length ?? 0,
                    itemBuilder: (_, i) {
                      final s =
                          (a['submissions'] as List)[i] as Map<String, dynamic>;
                      return _buildSubmissionItem(s, isDark, context);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(
      Map<String, dynamic> s, bool isDark, BuildContext ctx) {
    final studentName = (s['studentName'] ?? 'طالب') as String;
    final submittedAt = s['submittedAt'] as String?;
    final fileUrl = s['fileUrl'] as String?;
    final fileName = s['fileName'] as String?;
    final score = s['score'];
    final maxScore = assignment?['maxScore'] ?? 0;
    final notes = s['notes'] as String?;
    final feedback = s['feedback'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(ctx)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Text(
                  studentName.isNotEmpty ? studentName[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      studentName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    if (submittedAt != null)
                      Text(
                        submittedAt.length >= 16
                            ? submittedAt.substring(0, 16)
                            : submittedAt,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: fieldLabelColor(ctx),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              if (score != null)
                Chip(
                  label: Text(
                    '$score/$maxScore',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                      color: (score ?? 0) >= 50
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  backgroundColor: (score ?? 0) >= 50
                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                FilledButton.tonalIcon(
                  onPressed: () => onGradeSubmission(s),
                  icon: const Icon(Icons.grade, size: 14),
                  label: Text(
                    'تصحيح',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 4.h),
                  ),
                ),
            ],
          ),
          if (fileUrl != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Icon(Icons.description,
                      size: 16, color: const Color(0xFF8B5CF6)),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      fileName ?? 'عرض الملف',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: const Color(0xFF8B5CF6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (notes != null && notes.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text('📝 $notes',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.sp,
                    color: fieldLabelColor(ctx),
                  )),
            ),
          if (feedback != null && feedback.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 6.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text('💬 $feedback',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.sp,
                    color: const Color(0xFF059669),
                  )),
            ),
        ],
      ),
    );
  }
}
