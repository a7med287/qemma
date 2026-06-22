import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/mock/student_mock_data.dart';
import '../widgets/student_shared_widgets.dart';

class BookOfficeHourView extends StatefulWidget {
  const BookOfficeHourView({super.key, required this.courseId});

  final String courseId;

  @override
  State<BookOfficeHourView> createState() => _BookOfficeHourViewState();
}

class _BookOfficeHourViewState extends State<BookOfficeHourView> {
  int? _selectedDay;
  int? _selectedTime;
  bool _booked = false;

  // ✅ Fix 1: توليد التواريخ ديناميكياً بدل hardcoded
  late final List<(int, String, String)> _days = List.generate(4, (i) {
    final day = DateTime.now().add(Duration(days: i));
    return (i, _weekdayName(day.weekday), day.day.toString());
  });

  final _times = ['10:00 ص', '12:00 م', '2:00 م', '4:00 م', '6:00 م'];

  String _weekdayName(int weekday) {
    const names = {
      1: 'الإثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعة',
      6: 'السبت',
      7: 'الأحد',
    };
    return names[weekday] ?? '';
  }

  // ✅ Fix 2: البحث بـ firstWhere بدل الـ index المباشر
  (int, String, String) get _selectedDayData =>
      _days.firstWhere((d) => d.$1 == _selectedDay);

  // ✅ Fix 3: dialog تأكيد قبل الحجز
  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تأكيد الحجز'),
        content: Text(
          '${_selectedDayData.$2} ${_selectedDayData.$3} • ${_times[_selectedTime!]}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _booked = true);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = StudentMockData.courseById(widget.courseId);

    if (_booked) {
      return StudentPageShell(
        title: '✅ تم الحجز',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
              SizedBox(height: 16.h),
              Text('تم حجز Office Hour بنجاح!', style: TextStyles.bold20),
              // ✅ Fix 1 + 2: استخدام firstWhere بدل index مباشر
              Text(
                '${_selectedDayData.$2} ${_selectedDayData.$3} • ${_times[_selectedTime!]}',
                style: TextStyles.regular14,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('العودة للكورس'),
              ),
            ],
          ),
        ),
      );
    }

    return StudentPageShell(
      title: '📅 حجز Office Hour',
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          if (course != null)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(course.teacherName),
                subtitle: Text(course.title),
              ),
            ),
          SizedBox(height: 16.h),
          Text('اختر اليوم', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _days.map((d) {
              return ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(d.$2),
                    Text('${d.$3} يون', style: TextStyle(fontSize: 10.sp)),
                  ],
                ),
                selected: _selectedDay == d.$1,
                onSelected: (_) => setState(() => _selectedDay = d.$1),
              );
            }).toList(),
          ),
          SizedBox(height: 16.h),
          Text('اختر الوقت', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _times.asMap().entries.map((e) {
              return ChoiceChip(
                label: Text(e.value),
                selected: _selectedTime == e.key,
                onSelected: (_) => setState(() => _selectedTime = e.key),
              );
            }).toList(),
          ),
          SizedBox(height: 24.h),
          StudentGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ℹ️ معلومات', style: TextStyles.semiBold16),
                const Text('• مدة الجلسة: 30 دقيقة'),
                const Text('• نوع الجلسة: فيديو'),
                const Text('• يمكن الإلغاء قبل 24 ساعة'),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            // ✅ Fix 3: استدعاء _confirmBooking بدل التأكيد المباشر
            onPressed: _selectedDay != null && _selectedTime != null
                ? _confirmBooking
                : null,
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48.h)),
            child: const Text('تأكيد الحجز'),
          ),
        ],
      ),
    );
  }
}