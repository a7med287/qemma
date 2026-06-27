import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../features/ai_assistant/presentation/views/ai_assistant_view.dart';
import '../../data/models/assistant_models.dart';
import '../../data/repositories/assistant_repository.dart';
import 'assistant_chat_view.dart';
import 'assistant_grade_exams_view.dart';
import 'assistant_notifications_view.dart';
import 'assistant_student_detail_view.dart';
import 'widgets/assistant_dashboard_header.dart';
import 'widgets/assistant_dashboard_sections.dart';

class AssistantDashboardView extends StatefulWidget {
  static const routeName = '/assistant-teacher/dashboard';
  const AssistantDashboardView({super.key});

  @override
  State<AssistantDashboardView> createState() => _AssistantDashboardViewState();
}

class _AssistantDashboardViewState extends State<AssistantDashboardView> {
  AssistantDashboardData? _data;
  bool _loading = true;
  String? _error;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _repo.getDashboard();
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل لوحة التحكم'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
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
    return _AssistantDashboardContent(data: _data!, onRefresh: _loadDashboard);
  }
}

class _AssistantDashboardContent extends StatefulWidget {
  final AssistantDashboardData data;
  final VoidCallback onRefresh;
  const _AssistantDashboardContent({required this.data, required this.onRefresh});

  @override
  State<_AssistantDashboardContent> createState() => _AssistantDashboardContentState();
}

class _AssistantDashboardContentState extends State<_AssistantDashboardContent> {
  String _searchQuery = '';
  String _filterCourse = 'all';
  EnrichedStudentsResponse? _enriched;
  bool _studentsLoading = false;
  String? _studentsError;
  int _selectedTab = 0;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  Future<void> _loadStudents() async {
    setState(() { _studentsLoading = true; _studentsError = null; });
    try {
      final data = await _repo.getStudentsEnriched();
      if (mounted) setState(() { _enriched = data; _studentsLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _studentsError = 'فشل تحميل الطلاب'; _studentsLoading = false; });
    }
  }

  List<AssistantStudent> get _filteredStudents {
    final students = _enriched?.students ?? [];
    var list = students;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) =>
          s.name.toLowerCase().contains(q) ||
          (s.username?.toLowerCase().contains(q) ?? false) ||
          (s.email?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_filterCourse != 'all') {
      list = list.where((s) =>
          s.enrollments.any((e) => e.courseId == _filterCourse)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
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
          AssistantDashboardHeader(
            teacherName: data.teacherName,
            unreadCount: data.unreadCount,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                DashboardHomeTab(
                  data: data,
                  isDark: isDark,
                  onQuickActionStudents: () {
                    _loadStudents();
                    setState(() => _selectedTab = 1);
                  },
                  onQuickActionChat: () => Navigator.pushNamed(context, AssistantChatView.routeName),
                  onQuickActionGrade: () => Navigator.pushNamed(context, AssistantGradeExamsView.routeName),
                  onQuickActionNotifications: () => Navigator.pushNamed(context, AssistantNotificationsView.routeName),
                ),
                DashboardStudentsTab(
                  isDark: isDark,
                  loading: _studentsLoading,
                  error: _studentsError,
                  onRetry: _loadStudents,
                  enriched: _enriched,
                  searchQuery: _searchQuery,
                  onSearchChanged: (v) => setState(() => _searchQuery = v),
                  filterCourse: _filterCourse,
                  onFilterChanged: (v) => setState(() => _filterCourse = v),
                  courses: _enriched?.courses ?? [],
                  filteredStudents: _filteredStudents,
                  onStudentTap: (student) {
                    Navigator.pushNamed(context, AssistantStudentDetailView.routeName, arguments: student.id);
                  },
                ),
              ],
            ),
          ),
          _buildBottomNav(isDark),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
        selectedFontSize: 11.sp,
        unselectedFontSize: 11.sp,
        selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w500),
        elevation: 0,
        onTap: (i) {
          setState(() {
            _selectedTab = i;
            if (i == 1) _loadStudents();
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'الطلاب'),
        ],
      ),
    );
  }
}
