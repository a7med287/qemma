import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../data/models/parent_models.dart';
import '../../data/repositories/parent_repository.dart';
import '../routes/parent_routes.dart';
import '../widgets/parent_async_body.dart';
import '../widgets/parent_shared_widgets.dart';

class ParentDashboardView extends StatefulWidget {
  static const routeName = ParentRoutes.dashboard;
  const ParentDashboardView({super.key});

  @override
  State<ParentDashboardView> createState() => _ParentDashboardViewState();
}

class _ParentDashboardViewState extends State<ParentDashboardView> {
  ParentDashboardData? _data;
  bool _loading = true;
  String? _error;
  bool _showAddChild = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<ParentRepository>();
      final children = await repo.getChildren();
      int activeCourses = 0;
      int pendingAssignments = 0;
      int alerts = 0;
      final activities = <RecentActivity>[];
      final events = <UpcomingEvent>[];

      for (final child in children) {
        activeCourses += child.totalCourses;
        pendingAssignments += child.pendingAssignments;
        alerts += child.alerts;
      }

      setState(() {
        _data = ParentDashboardData(
          children: children,
          totalChildren: children.length,
          activeCourses: activeCourses,
          pendingAssignments: pendingAssignments,
          alerts: alerts,
          recentActivities: activities,
          upcomingEvents: events,
        );
      });
    } catch (e) {
      setState(() => _error = 'فشل تحميل البيانات');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().currentUser;
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22.r,
                        backgroundColor: Colors.white.withValues(alpha: .2),
                        child: Text(
                          (user?.name ?? '?').isNotEmpty ? (user!.name[0]) : '?',
                          style: TextStyles.bold18.copyWith(color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مرحباً، ${user?.name ?? ''}',
                                style: TextStyles.semiBold16.copyWith(color: Colors.white)),
                            Text('ولي أمر', style: TextStyles.regular13.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushNamed(context, ParentRoutes.notifications),
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (v) {
                          if (v == 'profile') {
                            Navigator.pushNamed(context, ParentRoutes.profile);
                          } else if (v == 'logout') {
                            context.read<AuthCubit>().logout();
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'profile', child: Row(
                            children: [Icon(Icons.person, size: 20), SizedBox(width: 8), Text('الملف الشخصي', style: TextStyle(fontFamily: 'Cairo'))],
                          )),
                          const PopupMenuItem(value: 'logout', child: Row(
                            children: [Icon(Icons.exit_to_app, size: 20, color: Colors.red), SizedBox(width: 8), Text('تسجيل الخروج', style: TextStyle(fontFamily: 'Cairo', color: Colors.red))],
                          )),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),
          Expanded(
            child: ParentAsyncBody(
              loading: _loading,
              error: _error,
              onRetry: _load,
              builder: () => _buildContent(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Expanded(
                  child: Text('نظرة عامة', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
                ),
                if (data.totalChildren > 0)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, ParentRoutes.children),
                    child: const Text('عرض الكل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(child: ParentStatCard(label: 'الأبناء', value: '${data.totalChildren}', icon: Icons.people, color: const Color(0xFF2563EB))),
                Expanded(child: ParentStatCard(label: 'الكورسات النشطة', value: '${data.activeCourses}', icon: Icons.menu_book, color: const Color(0xFF7C3AED))),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                Expanded(child: ParentStatCard(label: 'الواجبات المعلقة', value: '${data.pendingAssignments}', icon: Icons.assignment, color: const Color(0xFFD97706))),
                Expanded(child: ParentStatCard(label: 'التنبيهات', value: '${data.alerts}', icon: Icons.warning_amber, color: const Color(0xFFEF4444))),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          if (data.children.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text('الأبناء', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _showAddChild = !_showAddChild),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة طالب', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
            ),
            ...data.children.map((child) => _buildChildCard(context, child)),
            if (_showAddChild) _buildAddChildModal(context),
          ] else ...[
            Center(
              child: Padding(
                padding: EdgeInsets.all(40.r),
                child: Column(
                  children: [
                    Icon(Icons.family_restroom, size: 80.sp, color: context.textSecondary.withValues(alpha: .3)),
                    SizedBox(height: 16.h),
                    Text('لا يوجد أبناء مسجلين', style: TextStyles.semiBold16.copyWith(color: context.textSecondary)),
                    SizedBox(height: 8.h),
                    Text('أضف ابنك/ابنتك باستخدام اسم المستخدم الخاص بهم', style: TextStyles.regular13.copyWith(color: context.textSecondary), textAlign: TextAlign.center),
                    SizedBox(height: 20.h),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showAddChild = true),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة طالب', style: TextStyle(fontFamily: 'Cairo')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gradientMid,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                    if (_showAddChild) _buildAddChildModal(context),
                  ],
                ),
              ),
            ),
          ],
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, ParentRoutes.children),
                  icon: const Icon(Icons.people, size: 18),
                  label: const Text('الأبناء', style: TextStyle(fontFamily: 'Cairo')),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, ParentRoutes.reports),
                  icon: const Icon(Icons.assessment, size: 18),
                  label: const Text('التقارير', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, ChildSummary child) {
    final avgColor = parentGradeColor(child.averageGrade);
    final progressColor = parentGradeColor(child.overallProgress);
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
                  if (child.behaviorAlert != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text('⚠️ ${child.behaviorAlert!}', style: TextStyles.semiBold13.copyWith(color: Colors.red)),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  _miniStat('المعدل', '${child.averageGrade.toStringAsFixed(1)}%', avgColor),
                  _miniStat('الحضور', '${child.attendanceRate.toStringAsFixed(0)}%', const Color(0xFF2563EB)),
                  _miniStat('الكورسات', '${child.totalCourses}', const Color(0xFF7C3AED)),
                  _miniStat('الواجبات', '${child.pendingAssignments}', const Color(0xFFD97706)),
                ],
              ),
              if (child.overallProgress > 0) ...[
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: child.overallProgress / 100,
                    backgroundColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyles.semiBold14.copyWith(color: color)),
          Text(label, style: TextStyles.regular13.copyWith(color: color.withValues(alpha: .7))),
        ],
      ),
    );
  }

  Widget _buildAddChildModal(BuildContext context) {
    final usernameCtrl = TextEditingController();
    bool lookupLoading = false;
    bool codeSent = false;
    bool verifyLoading = false;
    Map<String, dynamic>? foundStudent;
    String? error;
    final codeCtrl = TextEditingController();
    final repo = context.read<ParentRepository>();
    final authService = context.read<AuthService>();
    final user = context.read<AuthCubit>().currentUser;
    final parentEmail = user?.email ?? '';

    return StatefulBuilder(
      builder: (context, setLocal) => Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('إضافة طالب جديد', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _showAddChild = false),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            if (!codeSent) ...[
              Text('الخطوة 1: ابحث عن الطالب', style: TextStyles.semiBold14.copyWith(color: context.textSecondary)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: usernameCtrl,
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(
                        hintText: 'اسم المستخدم',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: lookupLoading ? null : () async {
                      if (usernameCtrl.text.trim().isEmpty) return;
                      setLocal(() { lookupLoading = true; error = null; foundStudent = null; });
                      try {
                        final info = await authService.lookupStudent(usernameCtrl.text.trim());
                        setLocal(() => foundStudent = info);
                      } catch (e) {
                        setLocal(() => error = 'لم يتم العثور على طالب');
                      } finally {
                        setLocal(() => lookupLoading = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: lookupLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('بحث', style: TextStyle(fontFamily: 'Cairo')),
                  ),
                ],
              ),
              if (foundStudent != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: .5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF7C3AED).withValues(alpha: .15),
                        child: Icon(Icons.school, color: const Color(0xFF7C3AED)),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(foundStudent!['name'] ?? '', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                            Text('@${foundStudent!['username'] ?? ''}', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Color(0xFF059669)),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text('الخطوة 2: أرسل كود التحقق', style: TextStyles.semiBold14.copyWith(color: context.textSecondary)),
                SizedBox(height: 8.h),
                Text('سيصل للطالب كود مكون من 6 أرقام عبر الإشعارات.', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: verifyLoading ? null : () async {
                    setLocal(() { verifyLoading = true; error = null; });
                    try {
                      await authService.sendCodeToStudent(
                        studentUsername: usernameCtrl.text.trim(),
                        parentEmail: parentEmail,
                      );
                      setLocal(() => codeSent = true);
                      buildSnackBar(context, 'تم إرسال الكود للطالب ⚡');
                    } catch (e) {
                      setLocal(() => error = 'فشل إرسال الكود');
                    } finally {
                      setLocal(() => verifyLoading = false);
                    }
                  },
                  icon: verifyLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 18),
                  label: const Text('إرسال الكود للطالب', style: TextStyle(fontFamily: 'Cairo')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
              ],
            ] else ...[
              Text('الخطوة 3: أدخل الكود', style: TextStyles.semiBold14.copyWith(color: context.textSecondary)),
              SizedBox(height: 8.h),
              Text('اطلب من الطالب الكود وأدخله هنا.', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
              SizedBox(height: 12.h),
              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                textDirection: TextDirection.ltr,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: '000000',
                  prefixIcon: const Icon(Icons.pin, size: 20),
                  filled: true,
                  fillColor: context.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                onChanged: (v) {
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits != v) {
                    codeCtrl.value = codeCtrl.value.copyWith(text: digits);
                  }
                },
              ),
              SizedBox(height: 12.h),
              ElevatedButton.icon(
                onPressed: verifyLoading || codeCtrl.text.length != 6 ? null : () async {
                  setLocal(() { verifyLoading = true; error = null; });
                  try {
                    await authService.verifyParentCode(
                      studentUsername: usernameCtrl.text.trim(),
                      code: codeCtrl.text.trim(),
                    );
                    await repo.linkChild(usernameCtrl.text.trim());
                    buildSnackBar(context, '✅ تم ربط الطالب بنجاح');
                    setState(() => _showAddChild = false);
                    _load();
                  } catch (e) {
                    setLocal(() => error = 'الكود غير صحيح أو انتهت صلاحيته');
                  } finally {
                    setLocal(() => verifyLoading = false);
                  }
                },
                icon: verifyLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle, size: 18),
                label: const Text('تأكيد الربط', style: TextStyle(fontFamily: 'Cairo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
            ],
            if (error != null) ...[
              SizedBox(height: 8.h),
              Text(error!, style: TextStyle(color: Colors.red, fontFamily: 'Cairo', fontSize: 12.sp)),
            ],
          ],
        ),
      ),
    );
  }
}
