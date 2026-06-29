import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ChildProgressView extends StatefulWidget {
  static const routeName = '/parent/children';
  const ChildProgressView({super.key});

  @override
  State<ChildProgressView> createState() => _ChildProgressViewState();
}

class _ChildProgressViewState extends State<ChildProgressView> {
  List<ChildSummary> _children = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final children = await context.read<ParentRepository>().getChildren();
      if (mounted) setState(() => _children = children);
    } catch (e) {
      if (mounted) setState(() => _error = 'فشل تحميل بيانات الأبناء');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ParentGradientHeader(
            leading: const ParentBackButton(),
            title: 'متابعة الأبناء',
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatCards(),
                    SizedBox(height: 20.h),
                    ..._children.map((child) => _buildChildCard(child)),
                    if (_children.isEmpty)
                      _buildEmpty(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final totalAlerts = _children.fold(0, (s, c) => s + c.alerts);
    final avgGrade = _children.isEmpty
        ? 0.0
        : _children.fold(0.0, (s, c) => s + c.averageGrade) / _children.length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard(
              value: '${_children.length}',
              label: 'إجمالي الأبناء',
              color: const Color(0xFF2563EB),
            )),
            SizedBox(width: 12.w),
            Expanded(child: _statCard(
              value: '${avgGrade.round()}%',
              label: 'متوسط الدرجات',
              color: const Color(0xFF059669),
            )),
            SizedBox(width: 12.w),
            Expanded(child: _statCard(
              value: '$totalAlerts',
              label: 'التنبيهات',
              color: totalAlerts > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
            )),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Text(value,
            style: TextStyles.bold25.copyWith(color: color),
          ),
          SizedBox(height: 4.h),
          Text(label,
            style: TextStyles.regular13.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(ChildSummary child) {
    final pendingAssignments = child.tasks
        .where((t) => !t.completed && t.courseTitle != null)
        .length;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/parent/child/${child.id}'),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: context.borderColor.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28.r,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      child.name.isNotEmpty ? child.name.characters.first : '?',
                      style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.w900,
                        fontSize: 20.sp, color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name,
                          style: TextStyles.bold18.copyWith(color: context.textPrimary),
                        ),
                        SizedBox(height: 2.h),
                        Text(child.gradeLevel.isNotEmpty ? child.gradeLevel : 'غير محدد',
                          style: TextStyles.regular13.copyWith(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (child.alerts > 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 14.sp, color: const Color(0xFFDC2626)),
                          SizedBox(width: 4.w),
                          Text('${child.alerts} تنبيه',
                            style: TextStyle(
                              fontFamily: 'Cairo', fontSize: 11.sp,
                              fontWeight: FontWeight.w700, color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _miniStatBox(
                    icon: Icons.school, color: const Color(0xFF7C3AED),
                    value: '${child.totalCourses}', label: 'كورسات',
                  )),
                  SizedBox(width: 8.w),
                  Expanded(child: _miniStatBox(
                    icon: Icons.assignment, color: const Color(0xFFF59E0B),
                    value: '$pendingAssignments', label: 'واجبات',
                  )),
                  SizedBox(width: 8.w),
                  Expanded(child: _miniStatBox(
                    icon: Icons.event_available, color: const Color(0xFF2563EB),
                    value: '${child.pendingAssignments}', label: 'اختبارات',
                  )),
                  SizedBox(width: 8.w),
                  Expanded(child: _miniStatBox(
                    icon: child.averageGrade >= 80 ? Icons.trending_up : Icons.trending_down,
                    color: child.averageGrade >= 80 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    value: '${child.attendanceRate.round()}%', label: 'حضور',
                  )),
                ],
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('متوسط الدرجات',
                    style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
                  ),
                  Text('${child.averageGrade.round()}%',
                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(5.r),
                child: LinearProgressIndicator(
                  value: (child.averageGrade / 100).clamp(0.0, 1.0),
                  minHeight: 10.h,
                  backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  color: child.averageGrade >= 80
                      ? const Color(0xFF059669)
                      : child.averageGrade >= 60
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStatBox({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22.sp, color: color),
          SizedBox(height: 4.h),
          Text(value,
            style: TextStyles.bold18.copyWith(color: context.textPrimary),
          ),
          Text(label,
            style: TextStyle(
              fontFamily: 'Cairo', fontSize: 10.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Icon(Icons.family_restroom, size: 64.sp, color: context.textSecondary.withValues(alpha: .3)),
          SizedBox(height: 16.h),
          Text('لا يوجد أبناء مرتبطون بحسابك',
            style: TextStyles.semiBold16.copyWith(color: context.textSecondary),
          ),
        ],
      ),
    );
  }
}
