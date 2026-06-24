import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../data/models/parent_models.dart';
import '../../widgets/parent_shared_widgets.dart';
import 'parent_dashboard_sections.dart';

class ChildMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Widget? trailing;

  const ChildMiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(value, style: TextStyles.semiBold14.copyWith(color: color)),
              if (trailing != null) ...[SizedBox(width: 2.w), trailing!],
            ],
          ),
        ],
      ),
    );
  }
}

class ChildCard extends StatelessWidget {
  final ChildSummary child;

  const ChildCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final avgColor = parentGradeColor(child.averageGrade);
    final progressColor = parentGradeColor(child.overallProgress);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/parent/child/${child.id}'),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: context.borderColor.withValues(alpha: .5),
            ),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor:
                        AppColors.gradientMid.withValues(alpha: .12),
                    child: Text(
                      child.name.isNotEmpty ? child.name[0] : '?',
                      style: TextStyles.bold18.copyWith(
                        color: AppColors.gradientMid,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.name,
                          style: TextStyles.semiBold16.copyWith(
                            color: context.textPrimary,
                          ),
                        ),
                        Text(
                          child.gradeLevel,
                          style: TextStyles.regular13.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (child.behaviorAlert != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        '⚠️ ${child.behaviorAlert!}',
                        style: TextStyles.semiBold13.copyWith(color: Colors.red),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  ChildMiniStat(
                    label: 'المعدل',
                    value: '${child.averageGrade.toStringAsFixed(1)}%',
                    color: avgColor,
                    trailing: Icon(
                      child.averageGrade >= 80
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16.sp,
                      color: child.averageGrade >= 80
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  ChildMiniStat(
                    label: 'الحضور',
                    value: '${child.attendanceRate.toStringAsFixed(0)}%',
                    color: const Color(0xFF2563EB),
                  ),
                  ChildMiniStat(
                    label: 'الكورسات',
                    value: '${child.totalCourses}',
                    color: const Color(0xFF7C3AED),
                  ),
                  ChildMiniStat(
                    label: 'الواجبات',
                    value: '${child.pendingAssignments}',
                    color: child.pendingAssignments > 0
                        ? const Color(0xFFD97706)
                        : context.textPrimary,
                  ),
                ],
              ),
              if (child.overallProgress > 0) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      'التقدم الكلي',
                      style: TextStyles.regular13.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${child.overallProgress.toStringAsFixed(0)}%',
                      style: TextStyles.semiBold13.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: child.overallProgress / 100,
                    backgroundColor: context.isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    color: progressColor,
                    minHeight: 6.h,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ParentDashboardChildren extends StatelessWidget {
  final List<ChildSummary> children;
  final VoidCallback? onAddChild;

  const ParentDashboardChildren({
    super.key,
    required this.children,
    this.onAddChild,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40.r),
          child: Column(
            children: [
              Icon(
                Icons.family_restroom,
                size: 80.sp,
                color: context.textSecondary.withValues(alpha: .3),
              ),
              SizedBox(height: 16.h),
              Text(
                'لا يوجد أبناء مسجلين',
                style: TextStyles.semiBold16.copyWith(
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'أضف ابنك/ابنتك باستخدام اسم المستخدم الخاص بهم',
                style: TextStyles.regular13.copyWith(
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              ElevatedButton.icon(
                onPressed: onAddChild,
                icon: const Icon(Icons.add),
                label: const Text(
                  'إضافة طالب',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gradientMid,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DashboardSectionHeader(
          'نظرة عامة على الأبناء',
          Icons.family_restroom,
          showViewAll: true,
        ),
        ...children.map((child) => ChildCard(child: child)),
      ],
    );
  }
}
