import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
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
      setState(() => _children = children);
    } catch (e) {
      setState(() => _error = 'فشل تحميل بيانات الأبناء');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ParentAsyncBody(
      loading: _loading,
      error: _error,
      onRetry: _load,
      builder: () => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final totalAvg = _children.isEmpty
        ? 0.0
        : _children.fold(0.0, (sum, c) => sum + c.averageGrade) / _children.length;
    final totalAlerts = _children.fold(0, (sum, c) => sum + c.alerts);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 16.h, bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(child: ParentStatCard(label: 'عدد الأبناء', value: '${_children.length}', icon: Icons.people, color: const Color(0xFF2563EB))),
                Expanded(child: ParentStatCard(label: 'متوسط الدرجات', value: '${totalAvg.toStringAsFixed(1)}%', icon: Icons.grade, color: const Color(0xFF059669))),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(child: ParentStatCard(label: 'التنبيهات', value: '$totalAlerts', icon: Icons.warning_amber, color: const Color(0xFFEF4444))),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text('جميع الأبناء', style: TextStyles.bold20.copyWith(color: context.textPrimary)),
          ),
          SizedBox(height: 8.h),
          ..._children.map((child) => _buildChildCard(context, child)),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummary child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/parent/child/${child.id}'),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.borderColor.withValues(alpha: .5)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22.r,
                    backgroundColor: AppColors.gradientMid.withValues(alpha: .12),
                    child: Text(
                      child.name.isNotEmpty ? child.name[0] : '?',
                      style: TextStyles.bold18.copyWith(color: AppColors.gradientMid),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.name, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                        Text(child.gradeLevel, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left, color: context.textSecondary),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _stat('المعدل', '${child.averageGrade.toStringAsFixed(1)}%', parentGradeColor(child.averageGrade)),
                  _stat('الحضور', '${child.attendanceRate.toStringAsFixed(0)}%', const Color(0xFF2563EB)),
                  _stat('الكورسات', '${child.totalCourses}', const Color(0xFF7C3AED)),
                  _stat('الواجبات', '${child.pendingAssignments}', const Color(0xFFD97706)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyles.semiBold16.copyWith(color: color)),
          Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
        ],
      ),
    );
  }
}
