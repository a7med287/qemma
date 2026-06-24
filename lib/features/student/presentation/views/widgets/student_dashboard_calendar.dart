import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/student_models.dart';
import '../../widgets/student_shared_widgets.dart';

class StudentDashboardCalendar extends StatefulWidget {
  const StudentDashboardCalendar({
    super.key,
    required this.data,
  });

  final StudentDashboardData data;

  @override
  State<StudentDashboardCalendar> createState() =>
      _StudentDashboardCalendarState();
}

class _StudentDashboardCalendarState extends State<StudentDashboardCalendar> {
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final year = _currentDate.year;
    final month = _currentDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final today = DateTime.now();

    bool hasEvent(int d) {
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
      return widget.data.calendarEvents.any((e) => e.date == dateStr);
    }

    bool isToday(int d) =>
        d == today.day && month == today.month && year == today.year;

    return StudentGlassCard(
      title: ' التقويم',
      icon: '🗓️',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () =>
                    setState(() => _currentDate = DateTime(year, month + 1)),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('${arabicMonths[month - 1]} $year',
                  style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
              IconButton(
                onPressed: () =>
                    setState(() => _currentDate = DateTime(year, month - 1)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: arabicDays
                .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: TextStyles.regular13
                                .copyWith(color: context.textSecondary)))))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: firstDay + daysInMonth,
            itemBuilder: (_, i) {
              if (i < firstDay) return const SizedBox();
              final d = i - firstDay + 1;
              return Container(
                margin: EdgeInsets.all(2.r),
                decoration: BoxDecoration(
                  gradient: isToday(d) ? AppColors.primaryGradient : null,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$d',
                      style: TextStyles.semiBold13.copyWith(
                        color: isToday(d) ? Colors.white : context.textPrimary,
                      ),
                    ),
                    if (hasEvent(d))
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isToday(d)
                                ? Colors.white
                                : const Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
