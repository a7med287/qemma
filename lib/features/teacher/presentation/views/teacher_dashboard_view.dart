import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../features/ai_assistant/presentation/views/ai_assistant_view.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_dashboard_header.dart';
import 'widgets/teacher_dashboard_stats.dart';
import 'widgets/teacher_dashboard_quick_actions.dart';

class TeacherDashboardView extends StatefulWidget {
  static const routeName = '/teacher/dashboard';
  const TeacherDashboardView({super.key});

  @override
  State<TeacherDashboardView> createState() => _TeacherDashboardViewState();
}

class _TeacherDashboardViewState extends State<TeacherDashboardView> {
  TeacherDashboardData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await context.read<TeacherRepository>().getDashboard();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل لوحة التحكم'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.isDark ? AppColors.darkBackground : const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
                SizedBox(height: 12.h),
                Text(_error!, textAlign: TextAlign.center, style: TextStyles.regular14),
                SizedBox(height: 16.h),
                ElevatedButton(onPressed: _loadDashboard, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }
    return _DashboardBody(data: _data!, onRefresh: _loadDashboard);
  }
}

class _DashboardBody extends StatelessWidget {
  final TeacherDashboardData data;
  final VoidCallback onRefresh;
  const _DashboardBody({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => Navigator.pushNamed(context, AiAssistantView.routeName),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientMid.withValues(alpha: .4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
        ),
      ),
      body: Column(
        children: [
          TeacherDashboardHeader(data: data),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.all(16.r),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildContestCard(context, isDark),
                      if (data.subjects.isNotEmpty) ...[
                        SizedBox(height: 16.h),
                        _buildSubjectsCard(context, data, isDark),
                      ],
                      SizedBox(height: 16.h),
                      TeacherDashboardStats(data: data),
                      SizedBox(height: 24.h),
                      TeacherDashboardQuickActions(),
                      SizedBox(height: 69.h),

                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestCard(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 6.h, decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
          )),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56.w, height: 56.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                      ),
                      child: const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🏆 إدارة المسابقات الذهبية',
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo',
                                  color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                          SizedBox(height: 4.h),
                          Text('أضف أسئلة للمسابقات المخصصة لك وتابع مسابقاتك السابقة',
                              style: TextStyle(fontSize: 13.sp, fontFamily: 'Cairo',
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          SizedBox(height: 8.h),
                          Wrap(
                            spacing: 6.w, runSpacing: 4.h,
                            children: [
                              _contestChip('الصف الثالث الثانوي', const Color(0xFFF59E0B), isDark),
                              _contestChip('علمي رياضة', const Color(0xFFD97706), isDark),
                              _contestChip('علمي علوم', const Color(0xFFD97706), isDark),
                              _contestChip('أدبي', const Color(0xFFD97706), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () => Navigator.pushNamed(context, '/teacher/contests'),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                              SizedBox(width: 8.w),
                              Text('إدارة المسابقات',
                                  style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contestChip(String label, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: .2) : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11.sp, fontWeight: FontWeight.w800, fontFamily: 'Cairo')),
    );
  }

  Widget _buildSubjectsCard(BuildContext context, TeacherDashboardData data, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.w, height: 44.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                  ),
                  child: const Icon(Icons.school, color: Colors.white, size: 22),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المواد الدراسية', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                      Text('المواد المخصصة لك', maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.sp, fontFamily: 'Cairo',
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF7C3AED).withValues(alpha: .1) : const Color(0xFFF5F3FF),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: isDark ? const Color(0xFF7C3AED).withValues(alpha: .3) : const Color(0xFFE9D5FF)),
              ),
              child: Wrap(
                spacing: 8.w, runSpacing: 8.h,
                children: data.subjects.map((subject) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                    ),
                    child: Text(subject,
                        style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

