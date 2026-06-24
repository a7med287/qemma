import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';

class TeacherScheduleEventCard extends StatelessWidget {
  const TeacherScheduleEventCard({
    super.key,
    required this.session,
    this.isEditing = false,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> session;
  final bool isEditing;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<String> onDelete;

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = (session['id'] ?? session['_id'] ?? '') as String;
    final title = (session['title'] ?? '') as String;
    final type = (session['type'] ?? 'online') as String;
    final date = session['date'] as String?;
    final startTime = (session['startTime'] ?? '') as String;
    final endTime = (session['endTime'] ?? '') as String;
    final courseTitle = session['courseTitle'] as String?;
    final meetingLink = session['meetingLink'] as String?;
    final isDark = context.isDark;

    final fieldLabel = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final fieldText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEditing ? const Color(0xFF2563EB) : fieldBorder,
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: fieldText,
                            )),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: type == 'online'
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          type == 'online' ? 'أونلاين' : 'حضوري',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: type == 'online'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 4.h,
                    children: [
                      _infoRow(Icons.calendar_today, _formatDate(date), fieldLabel),
                      _infoRow(Icons.schedule, '$startTime - $endTime', fieldLabel),
                      if (courseTitle != null)
                        _infoRow(Icons.class_, courseTitle, fieldLabel),
                    ],
                  ),
                  if (meetingLink != null && meetingLink.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('🔗 رابط الحصة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.sp,
                            color: const Color(0xFF2563EB),
                          )),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => onEdit(session),
                  icon: const Icon(Icons.edit, size: 18),
                  color: const Color(0xFF2563EB),
                  constraints: BoxConstraints(
                      minWidth: 32.w, minHeight: 32.w),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                IconButton(
                  onPressed: () => onDelete(id),
                  icon: const Icon(Icons.delete, size: 18),
                  color: const Color(0xFFEF4444),
                  constraints: BoxConstraints(
                      minWidth: 32.w, minHeight: 32.w),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
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

  Widget _infoRow(IconData icon, String text, Color labelColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: labelColor),
        SizedBox(width: 4.w),
        Text(text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              color: labelColor,
            )),
      ],
    );
  }
}
