import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class TeacherAnalyticsTeacherRating extends StatelessWidget {
  final Map<String, dynamic>? rating;

  const TeacherAnalyticsTeacherRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();

    final avgRating = (rating!['averageRating'] as num?) ?? 0;
    final totalRatings = rating!['totalRatings'] as int? ?? 0;
    final reviews = (rating!['reviews'] as List?) ?? [];
    final isDark = context.isDark;

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
          Text('تقييمات الطلاب', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(avgRating.toStringAsFixed(1),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 32.sp, fontWeight: FontWeight.w900, color: context.textPrimary)),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (i) {
                      final filled = i < avgRating.round();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 18.sp,
                        color: filled ? const Color(0xFFFBBF24) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                      );
                    }),
                  ),
                  Text('($totalRatings تقييم)',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.textSecondary)),
                ],
              ),
            ],
          ),
          if (reviews.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Text('آخر التقييمات', style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
            SizedBox(height: 8.h),
            ...reviews.take(5).map((review) {
              final r = review as Map<String, dynamic>;
              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: fieldBorderColor(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${r['studentName'] ?? ''}',
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w700, color: context.textPrimary)),
                        Row(
                          children: List.generate(5, (i) {
                            final filled = i < ((r['rating'] as num?) ?? 0).round();
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              size: 12.sp,
                              color: filled ? const Color(0xFFFBBF24) : (isDark ? const Color(0xFF475569) : const Color(0xFFD1D5DB)),
                            );
                          }),
                        ),
                      ],
                    ),
                    if (r['comment'] != null && (r['comment'] as String).isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text('${r['comment']}',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: context.textSecondary)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
