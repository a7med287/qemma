import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherCreateExamView extends StatefulWidget {
  static const routeName = '/teacher/create-exam';
  const TeacherCreateExamView({super.key});

  @override
  State<TeacherCreateExamView> createState() => _TeacherCreateExamViewState();
}

class _TeacherCreateExamViewState extends State<TeacherCreateExamView> {
  int _activeStep = 0;
  bool _loading = false;
  bool _loadingCourses = false;
  List<Map<String, dynamic>> _courses = [];

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _courseId = '';
  int _durationMinutes = 60;
  int _totalMarks = 100;
  int _passingMarks = 50;
  String _availableFrom = '';
  String _availableTo = '';
  bool _proctored = false;
  bool _isPublished = true;

  // ✅ FIX 1: controllers for date fields so text displays after picking
  final _availableFromCtrl = TextEditingController();
  final _availableToCtrl = TextEditingController();

  List<_QuestionData> _questions = [];

  static const _steps = ['معلومات الاختبار', 'إضافة الأسئلة', 'المراجعة والنشر'];

  @override
  void initState() {
    super.initState();
    _resetQuestions();
    _fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _availableFromCtrl.dispose();
    _availableToCtrl.dispose();
    for (final q in _questions) {
      q.textCtrl.dispose();
      for (final o in q.optionCtrls) {
        o.dispose();
      }
      q.gradingCtrl.dispose();
    }
    super.dispose();
  }

  void _resetQuestions() {
    _questions = [_QuestionData()];
  }

  Future<void> _fetchCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final repo = context.read<TeacherRepository>();
      final courses = await repo.getNotificationCourses();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل تحميل الكورسات')),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  void _handleNext() {
    if (_activeStep == 0) {
      if (_titleCtrl.text.trim().isEmpty || _courseId.isEmpty) {
        _showError('يرجى ملء جميع الحقول المطلوبة');
        return;
      }
    } else if (_activeStep == 1) {
      final hasEmpty = _questions.any((q) => q.textCtrl.text.trim().isEmpty);
      if (hasEmpty) {
        _showError('يرجى ملء جميع الأسئلة');
        return;
      }
      // no need to validate correctAnswerIndex — always has a default (0)
      final emptyOptions = _questions.any(
            (q) =>
        q.type == 'multiple-choice' &&
            q.optionCtrls.any((o) => o.text.trim().isEmpty),
      );
      if (emptyOptions) {
        _showError('يرجى ملء جميع الخيارات في أسئلة الاختيار من متعدد');
        return;
      }
    }
    setState(() => _activeStep++);
  }

  void _handleBack() {
    setState(() => _activeStep--);
  }

  Future<void> _handleSubmit() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<TeacherRepository>();
      await repo.createExam(
        title: _titleCtrl.text.trim(),
        courseId: _courseId,
        durationMinutes: _durationMinutes,
        totalMarks: _totalMarks,
        passingMarks: _passingMarks,
        description: _descCtrl.text.trim(),
        availableFrom: _availableFrom.isNotEmpty ? _availableFrom : null,
        availableTo: _availableTo.isNotEmpty ? _availableTo : null,
        proctored: _proctored,
        isPublished: _isPublished,
        questions: _questions.asMap().entries.map((e) {
          final q = e.value;
          // ✅ FIX 2: resolve correct answer text from index
          final correctAnswerText = (q.type != 'essay' && q.correctAnswerIndex >= 0)
              ? q.optionCtrls[q.correctAnswerIndex].text.trim()
              : null;
          return {
            'type': q.type,
            'questionText': q.textCtrl.text.trim(),
            'marks': q.marks,
            'options': q.type == 'essay'
                ? []
                : q.optionCtrls.map((o) => o.text.trim()).toList(),
            'correctAnswer': q.type == 'essay' ? null : correctAnswerText,
            'gradingCriteria': q.type == 'essay'
                ? (q.gradingCtrl.text.trim().isNotEmpty
                ? q.gradingCtrl.text.trim()
                : null)
                : null,
            'order': e.key + 1,
          };
        }).toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إنشاء الاختبار ونشره بنجاح!')),
        );
        Navigator.maybePop(context);
      }
    } on ServerFailure catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إنشاء الاختبار. حاول مرة أخرى.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _selectedCourseName() {
    final c = _courses.cast<Map<String, dynamic>?>().firstWhere(
          (c) => c?['id'] == _courseId || c?['_id'] == _courseId,
      orElse: () => null,
    );
    return c?['title'] ?? _courseId;
  }

  Color _fieldBorderColor() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

  Color _fieldTextColor() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);

  Color _fieldLabelColor() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

  InputDecoration _inputDecoration(String label,
      {String? hint, bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Cairo',
        color: _fieldLabelColor().withValues(alpha: 0.5),
        fontSize: 13.sp,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Cairo',
        color: _fieldLabelColor(),
        fontSize: 14.sp,
      ),
      filled: true,
      fillColor:
      context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: _fieldBorderColor()),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(color: _fieldBorderColor()),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      contentPadding:
      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(isDark),
            Flexible(child: _buildBody(isDark)),
            _buildActions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFDB2777)],
                  ),
                ),
                child:
                const Icon(Icons.assignment, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إنشاء اختبار جديد',
                      style:
                      TextStyles.bold20.copyWith(color: Colors.white)),
                  Text('أنشئ اختبار تقييمي لطلابك',
                      style: TextStyles.regular13.copyWith(
                        color: Colors.white70,
                      )),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildStepper(isDark),
        ],
      ),
    );
  }

  Widget _buildStepper(bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == _activeStep;
          final isDone = i < _activeStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone || isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone || isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check,
                            size: 16.sp,
                            color: const Color(0xFF2563EB))
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: isActive
                                ? const Color(0xFF2563EB)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _steps[i],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10.sp,
                        color: isDone || isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          if (_activeStep == 0) _buildStep1(isDark),
          if (_activeStep == 1) _buildStep2(isDark),
          if (_activeStep == 2) _buildStep3(isDark),
        ],
      ),
    );
  }

  // ── Step 1: Basic Info ──────────────────────────────────────────
  Widget _buildStep1(bool isDark) {
    return _buildCard(isDark, [
      Text('المعلومات الأساسية',
          style: TextStyles.bold18.copyWith(
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          )),
      SizedBox(height: 16.h),
      _buildCourseDropdown(isDark),
      SizedBox(height: 12.h),
      _buildTextField(
        controller: _titleCtrl,
        label: 'عنوان الاختبار',
        hint: 'مثال: اختبار الفصل الأول - الجبر',
        required: true,
        isDark: isDark,
      ),
      SizedBox(height: 12.h),
      _buildTextField(
        controller: _descCtrl,
        label: 'وصف الاختبار (اختياري)',
        hint: 'اكتب وصفاً مختصراً عن الاختبار...',
        maxLines: 3,
        isDark: isDark,
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _buildNumberField(
              value: _durationMinutes,
              label: 'مدة الاختبار (بالدقائق)',
              onChanged: (v) => setState(() => _durationMinutes = v),
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildNumberField(
              value: _totalMarks,
              label: 'إجمالي الدرجات',
              onChanged: (v) => setState(() => _totalMarks = v),
              isDark: isDark,
            ),
          ),
        ],
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _buildNumberField(
              value: _passingMarks,
              label: 'درجة النجاح',
              onChanged: (v) => setState(() => _passingMarks = v),
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(child: const SizedBox()),
        ],
      ),
      SizedBox(height: 12.h),
      // ✅ FIX 1: pass controller to date fields
      _buildDateTimeField(
        label: 'متاح من (اختياري)',
        value: _availableFrom,
        controller: _availableFromCtrl,
        onChanged: (v) => setState(() => _availableFrom = v),
        isDark: isDark,
      ),
      SizedBox(height: 12.h),
      _buildDateTimeField(
        label: 'متاح حتى (اختياري)',
        value: _availableTo,
        controller: _availableToCtrl,
        onChanged: (v) => setState(() => _availableTo = v),
        isDark: isDark,
      ),
      SizedBox(height: 12.h),
      _buildSwitchRow(
        value: _proctored,
        label: 'اختبار مراقب (Proctored)',
        onChanged: (v) => setState(() => _proctored = v),
        isDark: isDark,
      ),
      SizedBox(height: 4.h),
      _buildSwitchRow(
        value: _isPublished,
        label: 'نشر الاختبار فور الحفظ',
        subtitle: _isPublished
            ? 'سيظهر الاختبار للطلاب المسجلين في الكورس فور الحفظ'
            : 'الاختبار سيُحفظ كمسودة ولن يظهر للطلاب',
        onChanged: (v) => setState(() => _isPublished = v),
        isDark: isDark,
        activeColor: const Color(0xFF22C55E),
      ),
    ]);
  }

  Widget _buildCourseDropdown(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('اختر الكورس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: _fieldLabelColor(),
                )),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        SizedBox(height: 6.h),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: _fieldBorderColor()),
            color:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _courseId.isEmpty ? null : _courseId,
              isExpanded: true,
              hint: Text(
                _loadingCourses ? 'جاري التحميل...' : 'اختر كورس',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: _fieldLabelColor(),
                ),
              ),
              dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
              items: _courses.map<DropdownMenuItem<String>>((c) {
                final id = (c['id'] ?? c['_id'] ?? '') as String;
                final title = (c['title'] ?? '') as String;
                final count =
                ((c['_count'] as Map?) ?? {})['enrollments'];
                return DropdownMenuItem(
                  value: id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: _fieldTextColor(),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (count != null)
                        Text(
                          '($count طالب)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 12.sp,
                            color: _fieldLabelColor(),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _loadingCourses
                  ? null
                  : (v) => setState(() => _courseId = v ?? ''),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Questions ───────────────────────────────────────────
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأسئلة (${_questions.length})',
                      style: TextStyles.bold18.copyWith(
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1F2937),
                      )),
                  Text(
                    'يدعم: اختيار من متعدد · صح أو خطأ · سؤال مقالي',
                    style: TextStyles.regular13.copyWith(
                      color: _fieldLabelColor(),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                setState(() => _questions.add(_QuestionData()));
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('إضافة سؤال',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE0E7FF),
                foregroundColor: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF3730A3),
                padding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...List.generate(_questions.length, (i) {
          return _buildQuestionCard(i, isDark);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(int index, bool isDark) {
    final q = _questions[index];
    final typeColor = _questionTypeColor(q.type);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Text('السؤال ${index + 1}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 12.sp,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF3730A3),
                    )),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _questionTypeLabel(q.type),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              if (q.type == 'essay')
                Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border:
                      Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text('تصحيح يدوي',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.w600,
                          fontSize: 11.sp,
                          color: const Color(0xFFF59E0B),
                        )),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _questions.length > 1
                    ? () =>
                    setState(() => _questions.removeAt(index))
                    : () => _showError(
                    'يجب أن يحتوي الاختبار على سؤال واحد على الأقل'),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Type + marks row
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: q.type,
                  items: const [
                    DropdownMenuItem(
                        value: 'multiple-choice',
                        child: Text('اختيار من متعدد')),
                    DropdownMenuItem(
                        value: 'true-false', child: Text('صح أو خطأ')),
                    DropdownMenuItem(
                        value: 'essay', child: Text('سؤال مقالي')),
                  ],
                  onChanged: (v) {
                    setState(() {
                      q.type = v;
                      // ✅ FIX 2: reset correctAnswerIndex on type change
                      q.correctAnswerIndex = 0;
                      if (v == 'true-false') {
                        q.optionCtrls = [
                          TextEditingController(text: 'صح'),
                          TextEditingController(text: 'خطأ'),
                        ];
                      } else if (v == 'multiple-choice') {
                        for (final c in q.optionCtrls) {
                          c.dispose();
                        }
                        q.optionCtrls = List.generate(
                            4, (_) => TextEditingController());
                      } else {
                        for (final c in q.optionCtrls) {
                          c.dispose();
                        }
                        q.optionCtrls = [];
                      }
                    });
                  },
                  isDark: isDark,
                ),
              ),
              SizedBox(width: 12.w),
              SizedBox(
                width: 100.w,
                child: _buildNumberField(
                  value: q.marks,
                  label: 'الدرجة',
                  onChanged: (v) => setState(() => q.marks = v),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Question text
          _buildTextField(
            controller: q.textCtrl,
            label: 'نص السؤال',
            hint: 'اكتب السؤال هنا...',
            maxLines: 2,
            isDark: isDark,
          ),
          SizedBox(height: 12.h),
          // Essay-specific fields
          if (q.type == 'essay') _buildEssaySection(q, isDark),
          // MCQ / TF options
          if (q.type != 'essay') _buildOptionsSection(q, index, isDark),
        ],
      ),
    );
  }

  Widget _buildEssaySection(_QuestionData q, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFFEFCE8),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF854D0E)
                  : const Color(0xFFFDE68A),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFF59E0B)),
                  SizedBox(width: 6.w),
                  Text('سؤال مقالي — سيتم تصحيحه يدوياً من قِبَل المعلم',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                        color: const Color(0xFFF59E0B),
                      )),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'يمكنك إضافة معايير التصحيح لمساعدتك أثناء المراجعة.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 11.sp,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF78716C),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _buildTextField(
          controller: q.gradingCtrl,
          label: 'معايير التصحيح / الإجابة النموذجية (اختياري)',
          hint:
          'اكتب النقاط الأساسية التي يجب أن تتضمنها إجابة الطالب...',
          maxLines: 4,
          isDark: isDark,
        ),
        Padding(
          padding: EdgeInsets.only(top: 4.h),
          child: Text(
            'هذه المعايير لن تظهر للطالب، فقط للمعلم أثناء التصحيح',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              color: _fieldLabelColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection(_QuestionData q, int qIndex, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الخيارات${q.type == 'true-false' ? ' (اختر الإجابة الصحيحة)' : ''}',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color:
            isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 8.h),
        ...List.generate(q.optionCtrls.length, (optIndex) {
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                // ✅ FIX 2: use index-based Radio instead of text-based
                Radio<int>(
                  value: optIndex,
                  groupValue: q.correctAnswerIndex,
                  onChanged: (v) =>
                      setState(() => q.correctAnswerIndex = v ?? -1),
                  activeColor: const Color(0xFF2563EB),
                ),
                Expanded(
                  child: _buildTextField(
                    controller: q.optionCtrls[optIndex],
                    label: 'الخيار ${optIndex + 1}',
                    isDark: isDark,
                    enabled: q.type != 'true-false',
                  ),
                ),
                if (q.type == 'multiple-choice' &&
                    q.optionCtrls.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        q.optionCtrls[optIndex].dispose();
                        q.optionCtrls.removeAt(optIndex);
                        // ✅ adjust index if deleted option was selected
                        if (q.correctAnswerIndex == optIndex) {
                          q.correctAnswerIndex = -1;
                        } else if (q.correctAnswerIndex > optIndex) {
                          q.correctAnswerIndex--;
                        }
                      });
                    },
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          );
        }),
        if (q.type == 'multiple-choice')
          TextButton.icon(
            onPressed: () {
              setState(() => q.optionCtrls.add(TextEditingController()));
            },
            icon: const Icon(Icons.add, size: 16),
            label: Text('إضافة خيار',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
            style:
            TextButton.styleFrom(foregroundColor: _fieldTextColor()),
          ),
      ],
    );
  }

  // ── Step 3: Review ──────────────────────────────────────────────
  Widget _buildStep3(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('مراجعة الاختبار',
            style: TextStyles.bold18.copyWith(
              color: isDark
                  ? const Color(0xFFF1F5F9)
                  : const Color(0xFF1F2937),
            )),
        SizedBox(height: 12.h),
        // Publish badge
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: _isPublished
                ? (isDark
                ? const Color(0xFF059669).withValues(alpha: 0.15)
                : const Color(0xFFDCFCE7))
                : (isDark
                ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                : const Color(0xFFFEF3C7)),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _isPublished
                  ? const Color(0xFF059669)
                  : const Color(0xFFF59E0B),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isPublished ? Icons.check_circle : Icons.warning,
                size: 18,
                color: _isPublished
                    ? const Color(0xFF059669)
                    : const Color(0xFFF59E0B),
              ),
              SizedBox(width: 8.w),
              Text(
                _isPublished
                    ? 'سيتم نشر الاختبار فور الحفظ وسيظهر للطلاب المسجلين'
                    : 'سيُحفظ الاختبار كمسودة ولن يظهر للطلاب',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  color: _isPublished
                      ? const Color(0xFF059669)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // Type breakdown chips
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            _buildTypeChip(
                'اختيار من متعدد',
                _questions
                    .where((q) => q.type == 'multiple-choice')
                    .length,
                const Color(0xFF2563EB)),
            _buildTypeChip(
                'صح أو خطأ',
                _questions.where((q) => q.type == 'true-false').length,
                const Color(0xFF0891B2)),
            _buildTypeChip(
                'مقالي',
                _questions.where((q) => q.type == 'essay').length,
                const Color(0xFF7C3AED)),
          ],
        ),
        SizedBox(height: 16.h),
        // Exam info
        _buildCard(isDark, [
          Text('معلومات الاختبار:',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              )),
          SizedBox(height: 12.h),
          _infoRow('العنوان', _titleCtrl.text),
          _infoRow('الكورس', _selectedCourseName()),
          _infoRow('المدة', '$_durationMinutes دقيقة'),
          _infoRow('إجمالي الدرجات', '$_totalMarks'),
          _infoRow('درجة النجاح', '$_passingMarks'),
          _infoRow('عدد الأسئلة', '${_questions.length}'),
        ]),
        SizedBox(height: 16.h),
        // Question reviews
        ...List.generate(_questions.length, (i) {
          return _buildQuestionReview(i, isDark);
        }),
      ],
    );
  }

  Widget _buildQuestionReview(int index, bool isDark) {
    final q = _questions[index];
    final typeColor = _questionTypeColor(q.type);
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF020617) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${index + 1}. ${q.textCtrl.text}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1F2937),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  _questionTypeLabel(q.type),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _fieldBorderColor()),
                ),
                child: Text(
                  '${q.marks} درجة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 10.sp,
                    color: _fieldLabelColor(),
                  ),
                ),
              ),
            ],
          ),
          if (q.type != 'essay') ...[
            SizedBox(height: 8.h),
            // ✅ FIX 2: use index to determine correct answer in review
            ...q.optionCtrls.asMap().entries.map((entry) {
              final optIndex = entry.key;
              final opt = entry.value;
              final correct = optIndex == q.correctAnswerIndex;
              return Padding(
                padding: EdgeInsets.only(right: 12.w, top: 4.h),
                child: Row(
                  children: [
                    Icon(
                      correct ? Icons.check : Icons.circle,
                      size: 12,
                      color: correct
                          ? const Color(0xFF22C55E)
                          : _fieldLabelColor(),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      opt.text,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: correct
                            ? const Color(0xFF22C55E)
                            : _fieldLabelColor(),
                        fontWeight: correct
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (q.type == 'essay') ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Text(
                '[سيكتب الطالب إجابته المقالية هنا]',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12.sp,
                  fontStyle: FontStyle.italic,
                  color: _fieldLabelColor(),
                ),
              ),
            ),
            if (q.gradingCtrl.text.trim().isNotEmpty) ...[
              SizedBox(height: 8.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFEFCE8),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF854D0E)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('معايير التصحيح:',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          fontSize: 11.sp,
                          color: const Color(0xFFF59E0B),
                        )),
                    SizedBox(height: 4.h),
                    Text(q.gradingCtrl.text,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 11.sp,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF78716C),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Action buttons ──────────────────────────────────────────────
  Widget _buildActions(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(color: _fieldBorderColor()),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > 0)
            TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text('رجوع',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp)),
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFF1F2937),
              ),
            )
          else
            const SizedBox(),
          if (_activeStep < _steps.length - 1)
            FilledButton(
              onPressed: _handleNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('التالي',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp)),
            )
          else
            FilledButton.icon(
              onPressed: _loading ? null : _handleSubmit,
              icon: _loading
                  ? SizedBox(
                  width: 18.w,
                  height: 18.w,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, size: 18),
              label: Text(
                  _loading ? 'جاري الحفظ...' : 'حفظ ونشر الاختبار',
                  style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                padding: EdgeInsets.symmetric(
                    horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
            ),
        ],
      ),
    );
  }

  // ── Shared components ───────────────────────────────────────────
  Widget _buildCard(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    bool required = false,
    bool enabled = true,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: enabled
            ? _fieldTextColor()
            : _fieldTextColor().withValues(alpha: 0.5),
      ),
      decoration: _inputDecoration(label, hint: hint, required: required),
      textInputAction:
      maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
    );
  }

  Widget _buildNumberField({
    required int value,
    required String label,
    required ValueChanged<int> onChanged,
    required bool isDark,
  }) {
    final ctrl = TextEditingController(text: value.toString());
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: _fieldTextColor(),
      ),
      decoration: _inputDecoration(label),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  // ✅ FIX 1: accept controller parameter so text shows after picking
  Widget _buildDateTimeField({
    required String label,
    required String value,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(label),
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: _fieldTextColor(),
      ),
      readOnly: true,
      onTap: () async {
        if (!mounted) return;
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate:
          DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (!mounted || date == null) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (!mounted || time == null) return;
        final dt = DateTime(date.year, date.month, date.day,
            time.hour, time.minute);
        final formatted = dt.toIso8601String().substring(0, 16);
        // ✅ update both the controller text and the state value
        controller.text = formatted;
        onChanged(formatted);
      },
    );
  }

  Widget _buildSwitchRow({
    required bool value,
    required String label,
    String? subtitle,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    Color activeColor = const Color(0xFF2563EB),
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: activeColor, // ignore: deprecated_member_use
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1F2937),
                    )),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11.sp,
                        color: _fieldLabelColor(),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorderColor()),
        color:
        isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor:
          isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14.sp,
            color: _fieldTextColor(),
          ),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text('$label: $count',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: Colors.white,
          )),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
                fontSize: 13.sp,
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
              )),
        ],
      ),
    );
  }

  Color _questionTypeColor(String type) {
    if (type == 'essay') return const Color(0xFF7C3AED);
    if (type == 'true-false') return const Color(0xFF0891B2);
    return const Color(0xFF2563EB);
  }

  String _questionTypeLabel(String type) {
    if (type == 'essay') return 'مقالي';
    if (type == 'true-false') return 'صح أو خطأ';
    return 'اختيار من متعدد';
  }
}

class _QuestionData {
  String type = 'multiple-choice';
  int marks = 5;

  // ✅ FIX 2: use index instead of text to track correct answer
  // default = 0 so first option is pre-selected
  int correctAnswerIndex = 0;

  final TextEditingController textCtrl;
  final TextEditingController gradingCtrl;
  List<TextEditingController> optionCtrls;

  _QuestionData({
    TextEditingController? textCtrl,
    TextEditingController? gradingCtrl,
    List<TextEditingController>? optionCtrls,
  })  : textCtrl = textCtrl ?? TextEditingController(),
        gradingCtrl = gradingCtrl ?? TextEditingController(),
        optionCtrls = optionCtrls ??
            List.generate(4, (_) => TextEditingController());
}