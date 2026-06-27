import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/teacher_models.dart';
import '../../data/repositories/teacher_repository.dart';

class AddContestQuestionsView extends StatefulWidget {
  final String contestId;
  const AddContestQuestionsView({super.key, required this.contestId});

  @override
  State<AddContestQuestionsView> createState() => _AddContestQuestionsViewState();
}

class _AddContestQuestionsViewState extends State<AddContestQuestionsView> {
  TeacherContestItem? _contest;
  List<ContestQuestion> _existingQuestions = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _newQuestions = <_QuestionForm>[];
  final _textControllers = <TextEditingController>[];
  final _optionControllers = <List<TextEditingController>>[];

  static const _pointValueByDifficulty = {'Easy': 1, 'Medium': 2, 'Hard': 4};

  @override
  void initState() {
    super.initState();
    _addNewQuestion();
    _fetchContest();
  }

  @override
  void dispose() {
    for (final c in _textControllers) { c.dispose(); }
    for (final list in _optionControllers) { for (final c in list) { c.dispose(); } }
    super.dispose();
  }

  TeacherRepository get _repo => context.read<TeacherRepository>();

  Future<void> _fetchContest() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await _repo.getContestDetail(widget.contestId);
      if (!mounted) return;
      final c = TeacherContestItem.fromJson(detail);
      final questions = detail['questions'] as List? ?? [];
      setState(() {
        _contest = c;
        _existingQuestions = questions
            .map((e) => ContestQuestion.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading = false;
      });
    } on Failure catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'فشل تحميل المسابقة'; _loading = false; });
    }
  }

  bool get _canEdit {
    if (_contest == null) return false;
    if (_contest!.isTest) return true;
    final now = DateTime.now();
    final start = DateTime.tryParse(_contest!.startTime);
    if (start == null) return false;
    return _contest!.status == 'upcoming' && now.isBefore(start.subtract(const Duration(hours: 1)));
  }

  void _addNewQuestion() {
    _newQuestions.add(_QuestionForm());
    _textControllers.add(TextEditingController());
    _optionControllers.add(List.generate(4, (_) => TextEditingController()));
    if (mounted) setState(() {});
  }

  void _removeNewQuestion(int index) {
    if (_newQuestions.length <= 1) {
      buildSnackBar(context, 'يجب أن يحتوي على سؤال واحد على الأقل', isError: true);
      return;
    }
    _textControllers[index].dispose();
    for (final c in _optionControllers[index]) { c.dispose(); }
    _newQuestions.removeAt(index);
    _textControllers.removeAt(index);
    _optionControllers.removeAt(index);
    setState(() {});
  }

  void _addOption(int qIndex) {
    final q = _newQuestions[qIndex];
    if (q.options.length >= 4) {
      buildSnackBar(context, 'الحد الأقصى 4 خيارات لكل سؤال', isError: true);
      return;
    }
    q.options.add('');
    _optionControllers[qIndex].add(TextEditingController());
    setState(() {});
  }

  void _removeOption(int qIndex, int optIndex) {
    final q = _newQuestions[qIndex];
    if (q.options.length <= 2) {
      buildSnackBar(context, 'يجب أن يكون هناك خيارين على الأقل', isError: true);
      return;
    }
    _optionControllers[qIndex][optIndex].dispose();
    q.options.removeAt(optIndex);
    _optionControllers[qIndex].removeAt(optIndex);
    if (optIndex == q.correctIndex) q.correctIndex = 0;
    else if (optIndex < q.correctIndex) q.correctIndex -= 1;
    setState(() {});
  }

  Future<void> _handleSubmit() async {
    for (int i = 0; i < _newQuestions.length; i++) {
      final q = _newQuestions[i];
      q.text = _textControllers[i].text;
      for (int j = 0; j < q.options.length; j++) {
        q.options[j] = _optionControllers[i][j].text;
      }

      if (q.text.trim().isEmpty) {
        buildSnackBar(context, 'يرجى ملء نص السؤال ${i + 1}', isError: true);
        return;
      }
      if (q.type != 'true_false') {
        if (q.options.length < 2) {
          buildSnackBar(context, 'السؤال ${i + 1} يجب أن يحتوي على خيارين على الأقل', isError: true);
          return;
        }
        if (q.options.length > 4) {
          buildSnackBar(context, 'السؤال ${i + 1} يجب أن يحتوي على 4 خيارات كحد أقصى', isError: true);
          return;
        }
        if (q.options.any((o) => o.trim().isEmpty)) {
          buildSnackBar(context, 'يرجى ملء جميع الخيارات في السؤال ${i + 1}', isError: true);
          return;
        }
      }
    }

    setState(() => _saving = true);
    int added = 0;
    try {
      for (int i = 0; i < _newQuestions.length; i++) {
        final q = _newQuestions[i];
        final payload = q.type == 'true_false'
            ? <String, dynamic>{
                'text': q.text.trim(),
                'questionType': 'true_false',
                'isCorrect': q.tfCorrect,
              }
            : <String, dynamic>{
                'text': q.text.trim(),
                'options': List.generate(q.options.length, (j) => {
                  'text': q.options[j].trim(),
                  'isCorrect': j == q.correctIndex,
                }),
              };
        await _repo.addContestQuestion(widget.contestId, payload);
        added++;
      }
      buildSnackBar(context, 'تم إضافة $added سؤال بنجاح!');
      await _fetchContest();
      // Reset form: dispose all controllers and clear lists
      for (final c in _textControllers) { c.dispose(); }
      for (final list in _optionControllers) { for (final c in list) { c.dispose(); } }
      _textControllers.clear();
      _optionControllers.clear();
      _newQuestions.clear();
      _addNewQuestion();
    } catch (_) {
      buildSnackBar(context, 'فشل إضافة السؤال ($added)', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _handleDeleteExisting(ContestQuestion q) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السؤال'),
        content: Text('هل أنت متأكد من حذف هذا السؤال؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteContestQuestion(widget.contestId, q.id);
      buildSnackBar(context, 'تم حذف السؤال');
      await _fetchContest();
    } catch (_) {
      buildSnackBar(context, 'فشل حذف السؤال', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: context.textSecondary), textAlign: TextAlign.center),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchContest,
                child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
        ),
      );
    }

    final c = _contest!;
    final diffColor = _difficultyColor(c.difficulty);
    final assignedMark = _pointValueByDifficulty[c.difficulty];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c, diffColor, isDark),
            if (!_canEdit)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                color: const Color(0xFFFEF3C7),
                child: Text('⚠️ المسابقة قد بدأت أو تبقى أقل من 60 دقيقة على بدئها — لا يمكن إضافة أو حذف أسئلة بعد الآن.',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: const Color(0xFF92400E))),
              ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.r),
                children: [
                  if (_existingQuestions.isNotEmpty) ...[
                    _buildExistingQuestionsSection(isDark),
                    SizedBox(height: 16.h),
                  ],
                  if (_canEdit) ...[
                    _buildNewQuestionsSection(isDark, assignedMark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TeacherContestItem c, Color diffColor, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .15)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(c.title,
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 18.sp, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: [
              _headerChip(_streamLabel(c.stream), Colors.white24),
              _headerChip(_difficultyLabel(c.difficulty), diffColor),
              _headerChip('${c.duration} دقيقة', Colors.white24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String label, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildExistingQuestionsSection(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأسئلة الحالية (${_existingQuestions.length})',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp, color: context.textPrimary)),
          SizedBox(height: 12.h),
          ..._existingQuestions.map((q) => _buildExistingQuestionCard(q, isDark)),
        ],
      ),
    );
  }

  Widget _buildExistingQuestionCard(ContestQuestion q, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text('${_existingQuestions.indexOf(q) + 1}. ${q.text}',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp, color: context.textPrimary)),
              ),
              if (q.canDelete && _canEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  onPressed: () => _handleDeleteExisting(q),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            children: [
              _questionChip(q.aiGenerated ? 'ذكاء اصطناعي' : (q.authorName ?? 'معلم'),
                  q.aiGenerated ? const Color(0xFF7C3AED) : const Color(0xFF2563EB), isDark),
              if (q.questionType == 'true_false')
                _questionChip('صح/خطأ', const Color(0xFF22C55E), isDark),
              _questionChip('${q.pointValue} درجة', null, isDark, outlined: true),
            ],
          ),
          SizedBox(height: 6.h),
          ...q.options.map((opt) => Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Row(
              children: [
                Text(opt.isCorrect ? '✓' : '•',
                    style: TextStyle(color: opt.isCorrect ? const Color(0xFF22C55E) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        fontWeight: opt.isCorrect ? FontWeight.w700 : FontWeight.w400, fontSize: 11.sp)),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(opt.text,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp,
                          color: opt.isCorrect ? const Color(0xFF22C55E) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          fontWeight: opt.isCorrect ? FontWeight.w700 : FontWeight.w400)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _questionChip(String label, Color? color, bool isDark, {bool outlined = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: outlined
            ? Colors.transparent
            : (isDark ? (color?.withValues(alpha: 0.2) ?? const Color(0xFF334155)) : (color?.withValues(alpha: 0.1) ?? const Color(0xFFF1F5F9))),
        borderRadius: BorderRadius.circular(4.r),
        border: outlined ? Border.all(color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB)) : null,
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700,
              color: outlined ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)) : (color ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))))),
    );
  }

  Widget _buildNewQuestionsSection(bool isDark, int? assignedMark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('إضافة أسئلة جديدة (${_newQuestions.length})',
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14.sp, color: context.textPrimary)),
                    SizedBox(height: 4.h),
                    Text('أضف أسئلة اختيار من متعدد أو صح/خطأ',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ],
                ),
              ),
              SizedBox(
                height: 36.h,
                child: ElevatedButton.icon(
                  onPressed: _addNewQuestion,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text('إضافة سؤال', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          for (int i = 0; i < _newQuestions.length; i++)
            _buildNewQuestionCard(i, isDark, assignedMark),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _handleSubmit,
              icon: _saving ? SizedBox(width: 16.r, height: 16.r, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
              label: Text(_saving ? 'جاري الحفظ...' : 'حفظ الأسئلة (${_newQuestions.length})',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.w900)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewQuestionCard(int index, bool isDark, int? assignedMark) {
    final q = _newQuestions[index];

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text('السؤال ${index + 1}',
                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 10.sp,
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF3730A3))),
              ),
              const Spacer(),
              _typeChip('اختيار من متعدد', q.type == 'mcq', const Color(0xFF7C3AED), () {
                _newQuestions[index].type = 'mcq';
                setState(() {});
              }),
              SizedBox(width: 6.w),
              _typeChip('صح/خطأ', q.type == 'true_false', const Color(0xFF22C55E), () {
                _newQuestions[index].type = 'true_false';
                setState(() {});
              }),
              SizedBox(width: 6.w),
              InkWell(
                onTap: () => _removeNewQuestion(index),
                child: Icon(Icons.delete_outline, color: Colors.red, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (assignedMark != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.r),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الدرجة (تُحدد تلقائياً حسب صعوبة المسابقة)',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  SizedBox(height: 2.h),
                  Text('$assignedMark درجة',
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w800, fontSize: 12.sp, color: context.textPrimary)),
                ],
              ),
            ),
          TextField(
            controller: _textControllers[index],
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'اكتب السؤال هنا...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB))),
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: context.textPrimary),
          ),
          SizedBox(height: 8.h),
          if (q.type == 'mcq') ...[
            Text('الخيارات: (اختر الإجابة الصحيحة)',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.textPrimary)),
            SizedBox(height: 6.h),
            ...List.generate(q.options.length, (optIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Row(
                  children: [
                    Radio<int>(
                      value: optIndex,
                      groupValue: q.correctIndex,
                      onChanged: (v) {
                        _newQuestions[index].correctIndex = v ?? 0;
                        setState(() {});
                      },
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 36.h,
                        child: TextField(
                          controller: _optionControllers[index][optIndex],
                          decoration: InputDecoration(
                            hintText: 'الخيار ${optIndex + 1}',
                            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6.r)),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          ),
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: context.textPrimary),
                        ),
                      ),
                    ),
                    if (q.options.length > 2)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                        onPressed: () => _removeOption(index, optIndex),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 28.r, minHeight: 28.r),
                      ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => _addOption(index),
              icon: const Icon(Icons.add, size: 14),
              label: Text('إضافة خيار', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(foregroundColor: context.textPrimary),
            ),
          ] else ...[
            Text('الإجابة الصحيحة:',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700, color: context.textPrimary)),
            SizedBox(height: 6.h),
            Row(
              children: [
                SizedBox(
                  height: 34.h,
                  child: ElevatedButton(
                    onPressed: () { _newQuestions[index].tfCorrect = true; setState(() {}); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: q.tfCorrect ? const Color(0xFF22C55E) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      foregroundColor: q.tfCorrect ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                      elevation: 0,
                    ),
                    child: Text('صح', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(width: 8.w),
                SizedBox(
                  height: 34.h,
                  child: ElevatedButton(
                    onPressed: () { _newQuestions[index].tfCorrect = false; setState(() {}); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !q.tfCorrect ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                      foregroundColor: !q.tfCorrect ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                      elevation: 0,
                    ),
                    child: Text('خطأ', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: selected ? color : (context.isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB))),
        ),
        child: Text(label,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : (context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)))),
      ),
    );
  }

  String _streamLabel(String s) {
    const labels = {
      'Literary': 'أدبي',
      'Science-Maths': 'علمي رياضة',
      'Science-Biology': 'علمي علوم',
      'general': 'عام',
      'science': 'علوم',
    };
    return labels[s] ?? s;
  }

  String _difficultyLabel(String d) {
    const labels = {'Easy': 'سهل', 'Medium': 'متوسط', 'Hard': 'صعب'};
    return labels[d] ?? d;
  }

  Color _difficultyColor(String d) {
    const colors = {'Easy': Color(0xFF059669), 'Medium': Color(0xFFF59E0B), 'Hard': Color(0xFFDC2626)};
    return colors[d] ?? const Color(0xFFF59E0B);
  }
}

class _QuestionForm {
  String text = '';
  String type = 'mcq';
  List<String> options = ['', '', '', ''];
  int correctIndex = 0;
  bool tfCorrect = true;
}
