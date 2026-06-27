import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../teacher_books_view.dart';
import '../teacher_send_notification_view.dart';
import '../teacher_create_course_view.dart';
import '../teacher_live_class_view.dart';
import '../teacher_create_exam_view.dart';
import '../teacher_analytics_view.dart';
import '../teacher_my_courses_view.dart';
import '../teacher_grade_exams_view.dart';
import '../teacher_assignments_view.dart';
import '../teacher_chat_management_view.dart';
import '../teacher_upload_lesson_view.dart';
import '../teacher_contests_view.dart';

class TeacherDashboardQuickActions extends StatelessWidget {
  const TeacherDashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    final actions = [
      _QuickAction(title: 'إدارة المسابقات الذهبية', desc: 'أضف أسئلة للمسابقات الذهبية - الصف الثالث', icon: Icons.emoji_events, color: const Color(0xFFF59E0B), onTap: () => Navigator.pushNamed(context, TeacherContestsView.routeName)),
      _QuickAction(title: 'مكتبة الكتب', desc: 'إدارة ورفع الكتب الدراسية', icon: Icons.menu_book, color: const Color(0xFF8B5CF6), onTap: () => Navigator.pushNamed(context, TeacherBooksView.routeName)),
      _QuickAction(title: 'إرسال إشعار', desc: 'أرسل إشعارات للطلاب', icon: Icons.campaign, color: const Color(0xFFEF4444), onTap: () => Navigator.pushNamed(context, TeacherSendNotificationView.routeName)),
      _QuickAction(title: 'إنشاء كورس جديد', desc: 'أضف كورس جديد لطلابك', icon: Icons.add, color: const Color(0xFF2563EB), onTap: () => Navigator.pushNamed(context, TeacherCreateCourseView.routeName)),
      _QuickAction(title: 'بدء حصة مباشرة', desc: 'ابدأ حصة أونلاين الآن', icon: Icons.videocam, color: const Color(0xFF7C3AED), onTap: () => Navigator.pushNamed(context, TeacherLiveClassView.routeName)),
      _QuickAction(title: 'إضافة اختبار', desc: 'أنشئ اختبار جديد', icon: Icons.assignment, color: const Color(0xFFDB2777), onTap: () => Navigator.pushNamed(context, TeacherCreateExamView.routeName)),
      _QuickAction(title: 'عرض التقارير', desc: 'تابع أداء الطلاب', icon: Icons.bar_chart, color: const Color(0xFF059669), onTap: () => Navigator.pushNamed(context, TeacherAnalyticsView.routeName)),
      _QuickAction(title: 'كورساتي', desc: 'عرض وإدارة كورساتك', icon: Icons.menu_book, color: const Color(0xFF06B6D4), onTap: () => Navigator.pushNamed(context, TeacherMyCoursesView.routeName)),
      _QuickAction(title: 'تصحيح الاختبارات', desc: 'راجع وصحح اختبارات الطلاب', icon: Icons.assignment_turned_in, color: const Color(0xFF10B981), onTap: () => Navigator.pushNamed(context, TeacherGradeExamsView.routeName)),
      _QuickAction(title: 'إدارة الواجبات', desc: 'أنشئ واجبات وتابع تسليم الطلاب', icon: Icons.assignment, color: const Color(0xFF0891B2), onTap: () => Navigator.pushNamed(context, TeacherAssignmentsView.routeName)),
      _QuickAction(title: 'إدارة المحادثات', desc: 'تواصل مع طلابك والمدرس المساعد', icon: Icons.chat_bubble_outline, color: const Color(0xFF2563EB), onTap: () => Navigator.pushNamed(context, TeacherChatManagementView.routeName)),
      _QuickAction(title: 'رفع درس', desc: 'أضف محتوى تعليمي جديد', icon: Icons.add_circle_outline, color: const Color(0xFFF59E0B), onTap: () => Navigator.pushNamed(context, TeacherUploadLessonView.routeName)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('إجراءات سريعة',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
              fontFamily: 'Cairo',
              color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
            )),
        SizedBox(height: 12.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) => _buildActionCard(context, actions[i], isDark),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickAction action, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: action.onTap,
          child: Padding(
            padding: EdgeInsets.all(10.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(action.icon, color: action.color, size: 20.sp),
                ),
                SizedBox(height: 6.h),
                Text(action.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1A1A2E),
                    )),
                SizedBox(height: 2.h),
                Text(action.desc,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Cairo',
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  const _QuickAction({required this.title, required this.desc, required this.icon, required this.color, this.onTap});
}
