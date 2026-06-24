import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_schedule_event_card.dart';

class TeacherScheduleCalendar extends StatelessWidget {
  const TeacherScheduleCalendar({
    super.key,
    required this.sessions,
    required this.loading,
    this.editingId,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Map<String, dynamic>> sessions;
  final bool loading;
  final String? editingId;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final fieldText = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
    final fieldLabel = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final fieldBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: fieldBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today, size: 48, color: fieldLabel),
            SizedBox(height: 12.h),
            Text('لا توجد حصص مجدولة بعد',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: fieldLabel,
                )),
          ],
        ),
      );
    }

    final grouped = _groupByWeek(sessions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Text('حصصي المجدولة',
              style: TextStyles.semiBold16.copyWith(color: fieldText)),
        ),
        ...grouped.entries.map((entry) => _buildWeekSection(
            context, entry.key, entry.value, isDark, cardBg, fieldText, fieldLabel, fieldBorder)),
      ],
    );
  }

  Widget _buildWeekSection(
    BuildContext context,
    String weekLabel,
    List<Map<String, dynamic>> weekSessions,
    bool isDark,
    Color cardBg,
    Color fieldText,
    Color fieldLabel,
    Color fieldBorder,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(11.r),
                topRight: Radius.circular(11.r),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
                SizedBox(width: 8.w),
                Text(weekLabel,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                      color: fieldText,
                    )),
                const Spacer(),
                Text('${weekSessions.length} حصة',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: fieldLabel,
                    )),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: weekSessions.map((s) {
                final id = (s['id'] ?? s['_id'] ?? '') as String;
                return TeacherScheduleEventCard(
                  session: s,
                  isEditing: editingId == id,
                  onEdit: onEdit,
                  onDelete: onDelete,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByWeek(List<Map<String, dynamic>> sessions) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final s in sessions) {
      final rawDate = s['date'] as String?;
      if (rawDate == null) continue;
      final dt = DateTime.tryParse(rawDate);
      if (dt == null) continue;
      final weekLabel = _weekLabel(dt);
      grouped.putIfAbsent(weekLabel, () => []).add(s);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));
    final sorted = <String, List<Map<String, dynamic>>>{};
    for (final k in sortedKeys.reversed) {
      sorted[k] = grouped[k]!;
    }
    return sorted;
  }

  String _weekLabel(DateTime dt) {
    final weekStart = dt.subtract(Duration(days: dt.weekday % 7));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${weekStart.day} ${months[weekStart.month - 1]} - ${weekEnd.day} ${months[weekEnd.month - 1]} ${weekEnd.year}';
  }
}
