import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../routes/student_routes.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class ExamsView extends StatefulWidget {
  const ExamsView({super.key});

  @override
  State<ExamsView> createState() => _ExamsViewState();
}

class _ExamsViewState extends State<ExamsView>
    with SingleTickerProviderStateMixin {
  List<ExamItem> _exams = [];
  bool _loading = true;
  String? _error;
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
      final list = await context.read<StudentRepository>().getStudentExams();
      if (!mounted) return;
      setState(() {
        _exams = list;
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

  bool _isAvailable(ExamItem e) {
    if (!e.isPublished || e.hasCompleted) return false;
    final now = DateTime.now();
    if (e.availableFrom != null && now.isBefore(e.availableFrom!)) return false;
    if (e.availableTo != null && now.isAfter(e.availableTo!)) return false;
    return true;
  }

  List<ExamItem> get _upcoming =>
      _exams.where((e) => !e.hasCompleted && _isAvailable(e)).toList();
  List<ExamItem> get _future => _exams
      .where((e) => !e.hasCompleted && !_isAvailable(e) && e.isPublished)
      .toList();
  List<ExamItem> get _completed =>
      _exams.where((e) => e.hasCompleted).toList();

  List<ExamItem> get _shown => switch (_tab) {
    1 => _upcoming,
    2 => _future,
    3 => _completed,
    _ => [..._upcoming, ..._future, ..._completed],
  };

  @override
  Widget build(BuildContext context) {
    final avg = _completed.isEmpty
        ? null
        : (_completed.map((e) => e.score ?? 0).reduce((a, b) => a + b) /
        _completed.length)
        .round();

    return StudentPageShell(
      title: '📝 الاختبارات',
      headerChild: Row(
        children: [
          _headerStat('${_upcoming.length + _future.length}', 'قادمة'),
          SizedBox(width: 12.w),
          _headerStat('${_completed.length}', 'مكتملة'),
          if (avg != null) ...[
            SizedBox(width: 12.w),
            _headerStat('$avg%', 'المتوسط'),
          ],
        ],
      ),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'الكل'),
                Tab(text: 'متاحة'),
                Tab(text: 'قادمة'),
                Tab(text: 'مكتملة'),
              ],
            ),
            SizedBox(height: 16.h),
            if (_shown.isEmpty)
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(32.r),
                      child: Text('لا توجد اختبارات',
                          style: TextStyles.regular14)))
            else
              ..._shown.asMap().entries.map((e) => _examCard(context, e.value, e.key)),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8.r)),
        child: Column(
          children: [
            Text(value,
                style: TextStyles.bold18.copyWith(color: Colors.white)),
            Text(label,
                style:
                TextStyles.regular13.copyWith(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _examCard(BuildContext context, ExamItem exam, int index) {
    final color = StudentMockData
        .studentColors[index % StudentMockData.studentColors.length];
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                    backgroundColor: color.withValues(alpha: .15),
                    child: Icon(Icons.quiz, color: color)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exam.title,
                          style: TextStyles.semiBold16
                              .copyWith(color: context.textPrimary)),
                      Text(exam.courseTitle,
                          style: TextStyles.regular13
                              .copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
                if (exam.hasCompleted)
                  Chip(
                    label: Text('${exam.score?.round()}%'),
                    backgroundColor:
                    studentGradeColor(exam.score ?? 0).withValues(alpha: .15),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Text('${exam.durationMinutes} دقيقة • ${exam.totalMarks} درجة',
                style: TextStyles.regular13
                    .copyWith(color: context.textSecondary)),
            SizedBox(height: 12.h),
            if (exam.hasCompleted)
              OutlinedButton.icon(
                onPressed: () =>
                    StudentRoutes.pushExamReview(context, exam.id),
                icon: const Icon(Icons.visibility),
                label: const Text('مراجعة النتيجة'),
              )
            else if (_isAvailable(exam))
              ElevatedButton(
                onPressed: () =>
                    StudentRoutes.pushExamStart(context, exam.id),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 40.h)),
                child: const Text('ابدأ الامتحان'),
              )
            else
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 40.h)),
                child: const Text('غير متاح الآن'),
              ),
          ],
        ),
      ),
    );
  }
}