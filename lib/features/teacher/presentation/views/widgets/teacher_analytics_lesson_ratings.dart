import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class TeacherAnalyticsLessonRatings extends StatelessWidget {
  final List<Map<String, dynamic>> ratings;
  final bool isLoading;

  const TeacherAnalyticsLessonRatings({
    super.key,
    required this.ratings,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (ratings.isEmpty && !isLoading) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تقييمات الدروس', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            ...ratings.map((r) => _buildRatingRow(context, r)),
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context, Map<String, dynamic> r) {
    final isDark = context.isDark;
    final avgRating = (r['rating'] as Map<String, dynamic>?)?['averageRating'];
    final totalRatings = (r['rating'] as Map<String, dynamic>?)?['totalRatings'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['title'] ?? ''}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w700, color: context.textPrimary)),
                Text('${r['courseTitle'] ?? ''}',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.textSecondary)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(5, (i) {
                final filled = avgRating != null && i < avgRating.round();
                return Icon(
                  filled ? Icons.star : Icons.star_border,
                  size: 14.sp,
                  color: filled ? const Color(0xFFFBBF24) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                );
              }),
              SizedBox(width: 4.w),
              Text(avgRating != null ? avgRating.toStringAsFixed(1) : '—',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.textSecondary)),
            ],
          ),
          SizedBox(width: 8.w),
          Text('$totalRatings',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.textPrimary)),
        ],
      ),
    );
  }
}
