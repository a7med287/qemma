import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_model_json.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView>
    with SingleTickerProviderStateMixin {
  TasksResponse? _tasks;
  bool _loading = true;
  String? _error;
  String _search = '';
  int _tab = 0;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _tab = _tabController.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<StudentRepository>().getTasks();
      if (!mounted) return;
      setState(() {
        _tasks = data;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  List<StudentTask> get _filtered {
    if (_tasks == null) return [];
    return _tasks!.all.where((t) {
      final matchSearch = _search.isEmpty ||
          t.title.contains(_search) ||
          t.courseName.contains(_search);
      final matchTab = switch (_tab) {
        1 => t.type == 'exam',
        2 => t.type == 'assignment',
        3 => t.type == 'lesson',
        _ => true,
      };
      return matchSearch && matchTab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _tasks?.stats ??
        const TaskStats(total: 0, exams: 0, assignments: 0, lessons: 0);

    return StudentPageShell(
      title: '📋 المهام المطلوبة',
      gradient:
      const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
      headerChild: Text('${stats.total} مهمة تنتظرك',
          style: TextStyles.regular14.copyWith(color: Colors.white70)),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _statCard('📋 ${stats.total}', 'إجمالي'),
                _statCard('📝 ${stats.exams}', 'امتحانات'),
                _statCard('📤 ${stats.assignments}', 'واجبات'),
                _statCard('📖 ${stats.lessons}', 'دروس'),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن مهمة...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 12.h),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: 'الكل (${stats.total})'),
                Tab(text: 'امتحانات (${stats.exams})'),
                Tab(text: 'واجبات (${stats.assignments})'),
                Tab(text: 'دروس (${stats.lessons})'),
              ],
            ),
            SizedBox(height: 16.h),
            if (_filtered.isEmpty)
              Center(
                  child: Text('🎉 لا توجد مهام متبقية!',
                      style: TextStyles.bold18
                          .copyWith(color: context.textPrimary)))
            else
              ..._filtered.map((task) => _taskCard(context, task)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Container(
      margin: EdgeInsets.all(4.r),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyles.bold18.copyWith(color: Colors.white)),
          Text(label,
              style: TextStyles.regular13.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _taskCard(BuildContext context, StudentTask task) {
    final config = switch (task.type) {
      'exam' => (Icons.quiz, const Color(0xFFEF4444), 'امتحان'),
      'assignment' => (Icons.assignment, const Color(0xFF8B5CF6), 'واجب'),
      _ => (Icons.menu_book, const Color(0xFF2563EB), 'درس'),
    };

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4.h, color: config.$2),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        backgroundColor: config.$2,
                        child: Icon(config.$1,
                            color: Colors.white, size: 20.sp)),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(task.title,
                              style: TextStyles.semiBold16
                                  .copyWith(color: context.textPrimary)),
                          Chip(
                              label: Text(
                                  '${config.$3} • ${task.courseName}'),
                              visualDensity: VisualDensity.compact),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: () {
                    switch (task.type) {
                      case 'exam':
                        StudentRoutes.pushExamStart(context, task.id);
                      case 'assignment':
                        Navigator.pushNamed(
                            context, StudentRoutes.submitAssignment,
                            arguments: {'assignmentId': task.id});
                      default:
                        StudentRoutes.pushLesson(
                            context, task.courseId, task.id);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: config.$2,
                      foregroundColor: Colors.white),
                  child: Text(switch (task.type) {
                    'exam' => 'ابدأ الامتحان',
                    'assignment' => 'تسليم الواجب',
                    _ => 'مشاهدة الدرس',
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}