import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';

class TeacherCreateCourseMedia extends StatelessWidget {
  const TeacherCreateCourseMedia({
    super.key,
    required this.titleCtrl,
    required this.subject,
    required this.selectedLevel,
    required this.priceCtrl,
    required this.durationCtrl,
    required this.startDate,
  });

  final TextEditingController titleCtrl;
  final String subject;
  final String selectedLevel;
  final TextEditingController priceCtrl;
  final TextEditingController durationCtrl;
  final String startDate;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return _buildCard(context, isDark, [
      Text('ملخص الكورس',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
      SizedBox(height: 16.h),
      _summaryRow('العنوان', titleCtrl.text.isNotEmpty ? titleCtrl.text : '—', isDark),
      _summaryRow('التصنيف', subject.isNotEmpty ? subject : '—', isDark),
      _summaryRow('المستوى', selectedLevel.isNotEmpty ? selectedLevel : '—', isDark),
      _summaryRow('السعر', priceCtrl.text.isNotEmpty ? '${priceCtrl.text} جنيه' : '—', isDark),
      _summaryRow('المدة', durationCtrl.text.isNotEmpty ? '${durationCtrl.text} أسابيع' : '—', isDark),
      _summaryRow('تاريخ البداية', startDate.isNotEmpty ? startDate : '—', isDark),
    ]);
  }

  Widget _buildCard(BuildContext context, bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:',
              style: TextStyle(fontSize: 12.sp, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }
}
