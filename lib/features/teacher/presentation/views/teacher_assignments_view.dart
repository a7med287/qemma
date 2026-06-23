import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherAssignmentsView extends StatefulWidget {
  static const routeName = '/teacher/assignments';
  const TeacherAssignmentsView({super.key});

  @override
  State<TeacherAssignmentsView> createState() => _TeacherAssignmentsViewState();
}

class _TeacherAssignmentsViewState extends State<TeacherAssignmentsView> {
  int _tab = 0;

  // Courses & lessons
  List<Map<String, dynamic>> _courses = [];
  bool _coursesLoading = true;
  List<Map<String, dynamic>> _lessons = [];
  bool _lessonsLoading = false;

  // Create form
  String _formCourse = '';
  String _formLesson = '';
  final _formTitleCtrl = TextEditingController();
  final _formDescCtrl = TextEditingController();
  String _formDueDate = '';
  int _formMaxScore = 100;
  bool _formPublished = true;
  bool _submitting = false;

  // Assignments list
  List<Map<String, dynamic>> _assignments = [];
  bool _assignmentsLoading = false;
  String _filterCourse = '';

  // Detail dialog
  Map<String, dynamic>? _selectedAssignment;
  bool _detailLoading = false;

  // Grade dialog
  Map<String, dynamic>? _gradingSubmission;
  final _gradeScoreCtrl = TextEditingController();
  final _gradeFeedbackCtrl = TextEditingController();
  bool _grading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  @override
  void dispose() {
    _formTitleCtrl.dispose();
    _formDescCtrl.dispose();
    _gradeScoreCtrl.dispose();
    _gradeFeedbackCtrl.dispose();
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

  Future<void> _fetchCourses() async {
    setState(() => _coursesLoading = true);
    try {
      final courses = await _repo.getTeacherCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {
      if (mounted) _showError('فشل تحميل الكورسات');
    } finally {
      if (mounted) setState(() => _coursesLoading = false);
    }
  }

  Future<void> _fetchLessons(String courseId) async {
    if (courseId.isEmpty) {
      setState(() => _lessons = []);
      return;
    }
    setState(() => _lessonsLoading = true);
    try {
      final lessons = await _repo.getCourseLessons(courseId);
      if (mounted) setState(() => _lessons = lessons);
    } catch (_) {
      if (mounted) setState(() => _lessons = []);
    } finally {
      if (mounted) setState(() => _lessonsLoading = false);
    }
  }

  Future<void> _fetchAssignments() async {
    setState(() => _assignmentsLoading = true);
    try {
      final assignments = await _repo.getTeacherAssignments(
        courseId: _filterCourse.isNotEmpty ? _filterCourse : null,
      );
      if (mounted) setState(() => _assignments = assignments);
    } catch (_) {
      if (mounted) _showError('فشل تحميل الواجبات');
    } finally {
      if (mounted) setState(() => _assignmentsLoading = false);
    }
  }

  void _onTabChanged(int v) {
    setState(() => _tab = v);
    if (v == 1) _fetchAssignments();
  }

  void _onFilterChanged(String v) {
    setState(() => _filterCourse = v);
    _fetchAssignments();
  }

  void _onCourseChanged(String v) {
    setState(() {
      _formCourse = v;
      _formLesson = '';
    });
    _fetchLessons(v);
  }

  bool _validateForm() {
    if (_formCourse.isEmpty) {
      _showError('اختر الكورس');
      return false;
    }
    if (_formTitleCtrl.text.trim().isEmpty) {
      _showError('عنوان الواجب مطلوب');
      return false;
    }
    if (_formMaxScore < 1) {
      _showError('الدرجة القصوى يجب أن تكون 1 على الأقل');
      return false;
    }
    return true;
  }

  Future<void> _handleCreate() async {
    if (!_validateForm()) return;
    setState(() => _submitting = true);
    try {
      await _repo.createAssignment(
        title: _formTitleCtrl.text.trim(),
        courseId: _formCourse,
        lessonId: _formLesson.isNotEmpty ? _formLesson : null,
        description: _formDescCtrl.text.trim(),
        dueDate: _formDueDate,
        totalMarks: _formMaxScore,
        isPublished: _formPublished,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الواجب بنجاح!')),
        );
        _resetForm();
        _onTabChanged(1);
      }
    } on ServerFailure catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('فشل إنشاء الواجب');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _formCourse = '';
    _formLesson = '';
    _formTitleCtrl.clear();
    _formDescCtrl.clear();
    _formDueDate = '';
    _formMaxScore = 100;
    _formPublished = true;
    _lessons = [];
  }

  Future<void> _viewDetail(String assignmentId) async {
    setState(() => _detailLoading = true);
    try {
      final detail = await _repo.getAssignmentDetail(assignmentId);
      if (mounted) {
        setState(() {
          _selectedAssignment = detail;
          _detailLoading = false;
        });
        _showDetailDialog();
      }
    } catch (_) {
      if (mounted) _showError('فشل تحميل تفاصيل الواجب');
      if (mounted) setState(() => _detailLoading = false);
    }
  }

  void _showDetailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildDetailDialog(ctx),
    );
  }

  void _openGradeDialog(Map<String, dynamic> submission) {
    setState(() {
      _gradingSubmission = submission;
      _gradeScoreCtrl.text = (submission['score'] ?? '').toString();
      _gradeFeedbackCtrl.text = submission['feedback'] ?? '';
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildGradeDialog(ctx),
    );
  }

  Future<void> _handleGrade() async {
    if (_gradingSubmission == null) return;
    setState(() => _grading = true);
    try {
      await _repo.gradeSubmission(
        submissionId: _gradingSubmission!['id'] ?? '',
        score: int.tryParse(_gradeScoreCtrl.text) ?? 0,
        feedback: _gradeFeedbackCtrl.text.isNotEmpty
            ? _gradeFeedbackCtrl.text
            : null,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصحيح الواجب')),
        );
        if (_selectedAssignment != null) {
          _viewDetail(_selectedAssignment!['id'] ?? '');
        }
      }
    } catch (_) {
      if (mounted) _showError('فشل التصحيح');
    } finally {
      if (mounted) setState(() => _grading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Theme helpers ────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldText() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _cardBg() =>
      context.isDark ? const Color(0xFF1E293B) : Colors.white;
  Color _bg() =>
      context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);

  InputDecoration _inp(String label, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(
          fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldLabel()),
      filled: true,
      fillColor: context.isDark
          ? const Color(0xFF1E293B)
          : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder())),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder())),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide:
          const BorderSide(color: Color(0xFF8B5CF6), width: 2)),
      contentPadding:
      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: _bg(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            Expanded(
              child: _tab == 0
                  ? _buildCreateTab(isDark)
                  : _buildViewTab(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style:
                  IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: const BoxDecoration(
                        borderRadius:
                        BorderRadius.all(Radius.circular(10)),
                        color: Colors.white24,
                      ),
                      child: const Icon(Icons.assignment,
                          color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إدارة الواجبات',
                            style: TextStyles.bold20
                                .copyWith(color: Colors.white)),
                        Text('إنشاء واجبات جديدة ومتابعة تسليمات الطلاب',
                            style: TextStyles.regular13
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                _tabButton(0, Icons.add_task, 'إنشاء واجب', isDark),
                _tabButton(1, Icons.visibility, 'عرض الواجبات', isDark),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label, bool isDark) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: active ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : Colors.white70),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: active ? Colors.white : Colors.white70,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Create Tab ──────────────────────────────────────────────────
  Widget _buildCreateTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إنشاء واجب جديد',
              style: TextStyles.bold18.copyWith(
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              )),
          SizedBox(height: 16.h),
          _buildFormSection(isDark),
          SizedBox(height: 16.h),
          _buildTipsCard(isDark),
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course
          _buildDropdown(
            label: 'الكورس',
            value: _formCourse,
            loading: _coursesLoading,
            placeholder: 'اختر الكورس',
            items: _courses.map((c) {
              final id = (c['id'] ?? c['_id'] ?? '') as String;
              final title = (c['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }).toList(),
            onChanged: _onCourseChanged,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          // Lesson
          _buildDropdown(
            label: 'الدرس (اختياري)',
            value: _formLesson,
            loading: _lessonsLoading,
            placeholder: 'بدون درس محدد',
            enabled: _formCourse.isNotEmpty,
            items: [
              const DropdownMenuItem(
                  value: '', child: Text('بدون درس محدد')),
              ..._lessons.map((l) {
                final id = (l['id'] ?? l['_id'] ?? '') as String;
                final title = (l['title'] ?? '') as String;
                final order = l['order'] ?? 0;
                return DropdownMenuItem(
                    value: id,
                    child: Text('$order - $title'));
              }),
            ],
            onChanged: (v) => setState(() => _formLesson = v),
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          // Title
          TextField(
            controller: _formTitleCtrl,
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
            decoration: _inp('عنوان الواجب', required: true),
          ),
          SizedBox(height: 12.h),
          // Description
          TextField(
            controller: _formDescCtrl,
            maxLines: 3,
            style: TextStyle(
                fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
            decoration: _inp('وصف الواجب'),
          ),
          SizedBox(height: 12.h),
          // Due date
          _buildDateField(isDark),
          SizedBox(height: 12.h),
          // Max score
          Row(
            children: [
              Expanded(
                child: _buildScoreField(isDark),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Published toggle
          _buildPublishToggle(isDark),
          SizedBox(height: 24.h),
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                  _submitting ? null : () => Navigator.maybePop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: _fieldBorder()),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text('إلغاء',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      )),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed:
                  (_submitting || _coursesLoading) ? null : _handleCreate,
                  icon: _submitting
                      ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 18),
                  label: Text(
                      _submitting ? 'جاري الإنشاء...' : 'إنشاء الواجب',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      )),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (mounted && date != null) {
          setState(() {
            _formDueDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          });
        }
      },
      child: InputDecorator(
        decoration: _inp('تاريخ التسليم'),
        child: Text(
          _formDueDate.isEmpty ? 'اختر تاريخ' : _formDueDate,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: _formDueDate.isEmpty
                ? _fieldLabel().withValues(alpha: 0.5)
                : _fieldText(),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreField(bool isDark) {
    final ctrl = TextEditingController(text: _formMaxScore.toString());
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
          fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
      decoration: _inp('الدرجة القصوى'),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) _formMaxScore = parsed;
      },
    );
  }

  Widget _buildPublishToggle(bool isDark) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('نشر الواجب فوراً للطلاب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1F2937),
                )),
          ),
          Switch(
            value: _formPublished,
            onChanged: (v) => setState(() => _formPublished = v),
            activeThumbColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(bool isDark) {
    final tips = [
      'اختر كورساً محدداً للواجب',
      'اربط الواجب بدرس معين إن أمكن',
      'حدد تاريخ تسليم واضح',
      'اكتب وصفاً مفصلاً للمطلوب',
      'يمكنك النشر فوراً أو لاحقاً',
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نصائح',
              style: TextStyles.semiBold16.copyWith(
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              )),
          SizedBox(height: 12.h),
          ...tips.map((t) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: Color(0xFF059669)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(t,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: _fieldLabel(),
                      )),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── View Tab ────────────────────────────────────────────────────
  Widget _buildViewTab(bool isDark) {
    return Column(
      children: [
        _buildFilterBar(isDark),
        Expanded(child: _buildAssignmentList(isDark)),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Row(
        children: [
          Icon(Icons.school, size: 20, color: _fieldLabel()),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildDropdown(
              label: '',
              value: _filterCourse,
              placeholder: 'جميع الكورسات',
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('جميع الكورسات')),
                ..._courses.map((c) {
                  final id = (c['id'] ?? c['_id'] ?? '') as String;
                  final title = (c['title'] ?? '') as String;
                  return DropdownMenuItem(
                      value: id, child: Text(title));
                }),
              ],
              onChanged: _onFilterChanged,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 8.w),
          FilledButton.icon(
            onPressed: () => _onTabChanged(0),
            icon: const Icon(Icons.add, size: 16),
            label: Text('جديد',
                style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp)),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentList(bool isDark) {
    if (_assignmentsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_assignments.isEmpty) {
      return _buildEmptyState(isDark);
    }
    return RefreshIndicator(
      onRefresh: _fetchAssignments,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _assignments.length,
        itemBuilder: (_, i) => _buildAssignmentCard(_assignments[i], isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: _cardBg(),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _fieldBorder()),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment,
                size: 64, color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1)),
            SizedBox(height: 16.h),
            Text('لا توجد واجبات بعد',
                style: TextStyles.bold18.copyWith(
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
            SizedBox(height: 8.h),
            Text('أنشئ أول واجب الآن',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: _fieldLabel(),
                )),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: () => _onTabChanged(0),
              icon: const Icon(Icons.add, size: 18),
              label: Text('إنشاء واجب',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> a, bool isDark) {
    final id = (a['id'] ?? a['_id'] ?? '') as String;
    final title = (a['title'] ?? '') as String;
    final courseTitle = (a['courseTitle'] ?? '') as String;
    final lessonTitle = a['lessonTitle'] as String?;
    final description = a['description'] as String?;
    final maxScore = a['maxScore'] ?? 0;
    final submissionsCount = a['submissionsCount'] ?? 0;
    final dueDate = a['dueDate'] as String?;
    final graded = a['gradedCount'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        children: [
          // Purple top bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(12)),
              gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.assignment,
                        size: 22, color: const Color(0xFF8B5CF6)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyles.semiBold14.copyWith(
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                              )),
                          SizedBox(height: 4.h),
                          Wrap(
                            spacing: 4.w,
                            children: [
                              _chip(courseTitle,
                                  const Color(0xFF8B5CF6), isDark),
                              if (lessonTitle != null)
                                _chip(lessonTitle,
                                    const Color(0xFF6366F1), isDark),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _chip('$maxScore درجات',
                        const Color(0xFF059669), isDark),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                          color: _fieldLabel(),
                        )),
                  ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions,
                          size: 18, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 6.w),
                      Text('التسليمات: $submissionsCount',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.sp,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          )),
                      SizedBox(width: 16.w),
                      Text('تم التصحيح: $graded',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: const Color(0xFF059669),
                          )),
                      const Spacer(),
                      Icon(Icons.calendar_today,
                          size: 14, color: _fieldLabel()),
                      SizedBox(width: 4.w),
                      Text(
                        dueDate != null
                            ? dueDate.length >= 10
                            ? dueDate.substring(0, 10)
                            : dueDate
                            : '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: _fieldLabel(),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetail(id),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: Text('عرض التسليمات',
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B5CF6),
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
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

  Widget _chip(String label, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w600,
            fontSize: 10.sp,
            color: color,
          )),
    );
  }

  // ── Detail Dialog ───────────────────────────────────────────────
  Widget _buildDetailDialog(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final assignment = _selectedAssignment;
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  const Icon(Icons.assignment,
                      color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      assignment?['title'] ?? 'تفاصيل الواجب',
                      style: TextStyles.semiBold16.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            if (_detailLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (assignment != null) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    _chip(
                        assignment['courseTitle'] ?? '', const Color(0xFF8B5CF6), isDark),
                    _chip(
                        '${(assignment['submissions'] as List?)?.length ?? 0} تسليم',
                        const Color(0xFF0891B2), isDark),
                    _chip('${assignment['maxScore'] ?? 0} درجة',
                        const Color(0xFF059669), isDark),
                    if (assignment['dueDate'] != null)
                      _chip(
                          (assignment['dueDate'] as String).substring(0, 10),
                          const Color(0xFFF59E0B), isDark),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              const Divider(),
              // Submissions
              if ((assignment['submissions'] as List?)?.isEmpty ?? true)
                Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      Icon(Icons.pending_actions,
                          size: 48,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                      SizedBox(height: 12.h),
                      Text('لا توجد تسليمات بعد',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            color: _fieldLabel(),
                          )),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(16.w),
                    itemCount:
                    (assignment['submissions'] as List?)?.length ?? 0,
                    itemBuilder: (_, i) {
                      final s =
                      (assignment['submissions'] as List)[i] as Map<String, dynamic>;
                      return _buildSubmissionItem(s, isDark, ctx);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionItem(
      Map<String, dynamic> s, bool isDark, BuildContext ctx) {
    final studentName = (s['studentName'] ?? 'طالب') as String;
    final submittedAt = s['submittedAt'] as String?;
    final fileUrl = s['fileUrl'] as String?;
    final fileName = s['fileName'] as String?;
    final score = s['score'];
    final maxScore = _selectedAssignment?['maxScore'] ?? 0;
    final notes = s['notes'] as String?;
    final feedback = s['feedback'] as String?;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF8B5CF6),
                child: Text(
                  studentName.isNotEmpty ? studentName[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
              ),
              SizedBox(width: 8.w),
              // FIX: Expanded + Column with crossAxisAlignment.start
              // and explicit overflow on Text widgets prevents the overflow.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      studentName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    if (submittedAt != null)
                      Text(
                        submittedAt.length >= 16
                            ? submittedAt.substring(0, 16)
                            : submittedAt,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: _fieldLabel(),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Score chip or grade button — no longer inside an unconstrained Row
              if (score != null)
                Chip(
                  label: Text(
                    '$score/$maxScore',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                      color: (score ?? 0) >= 50
                          ? const Color(0xFF059669)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  backgroundColor: (score ?? 0) >= 50
                      ? const Color(0xFF059669).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )
              else
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openGradeDialog(s);
                  },
                  icon: const Icon(Icons.grade, size: 14),
                  label: Text(
                    'تصحيح',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  ),
                ),
            ],
          ),
          if (fileUrl != null)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  Icon(Icons.description,
                      size: 16, color: const Color(0xFF8B5CF6)),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      fileName ?? 'عرض الملف',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        color: const Color(0xFF8B5CF6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (notes != null && notes.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text('📝 $notes',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.sp,
                    color: _fieldLabel(),
                  )),
            ),
          if (feedback != null && feedback.isNotEmpty)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 6.h),
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text('💬 $feedback',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11.sp,
                    color: const Color(0xFF059669),
                  )),
            ),
        ],
      ),
    );
  }

  // ── Grade Dialog ────────────────────────────────────────────────
  Widget _buildGradeDialog(BuildContext ctx) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final submission = _gradingSubmission;
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  const Icon(Icons.grade,
                      color: Color(0xFF8B5CF6), size: 24),
                  SizedBox(width: 8.w),
                  Text('تصحيح الواجب',
                      style: TextStyles.semiBold16.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      )),
                ],
              ),
            ),
            if (submission != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الطالب: ${submission['studentName'] ?? ''}',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                    if (submission['fileUrl'] != null)
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description,
                                size: 18,
                                color: const Color(0xFF8B5CF6)),
                            SizedBox(width: 6.w),
                            Text('عرض ملف الطالب',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                  color: const Color(0xFF8B5CF6),
                                )),
                          ],
                        ),
                      ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _gradeScoreCtrl,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'الدرجة',
                        labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: _fieldLabel()),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _fieldBorder())),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    TextField(
                      controller: _gradeFeedbackCtrl,
                      maxLines: 3,
                      style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 14.sp,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1F2937)),
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        labelStyle: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: _fieldLabel()),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide(color: _fieldBorder())),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('إلغاء',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                  ),
                  SizedBox(width: 8.w),
                  FilledButton.icon(
                    onPressed: _grading ? null : _handleGrade,
                    icon: _grading
                        ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.grade, size: 18),
                    label: Text('حفظ التصحيح',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        )),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared dropdown ─────────────────────────────────────────────
  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
    bool loading = false,
    String placeholder = '',
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isNotEmpty ? value : null,
          isExpanded: true,
          hint: Text(loading ? 'جاري التحميل...' : placeholder,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: _fieldLabel().withValues(alpha: 0.5),
              )),
          dropdownColor:
          isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: _fieldText(),
          ),
          items: items,
          onChanged: enabled && !loading ? (v) {
            if (v != null) onChanged(v);
          } : null,
        ),
      ),
    );
  }
}