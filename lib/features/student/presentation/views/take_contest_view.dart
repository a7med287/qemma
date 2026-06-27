import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';

class TakeContestView extends StatefulWidget {
  final String contestId;
  const TakeContestView({super.key, required this.contestId});

  @override
  State<TakeContestView> createState() => _TakeContestViewState();
}

class _TakeContestViewState extends State<TakeContestView> with WidgetsBindingObserver {
  StudentRepository get _repo => context.read<StudentRepository>();

  ContestParticipation? _data;
  bool _loading = true;
  String? _error;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _submittingAnswer = false;
  bool _submittingFinal = false;
  bool _success = false;

  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initContest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && !_success && _data != null) {
      _showLeaveDialog();
    }
  }

  Future<void> _initContest() async {
    setState(() { _loading = true; _error = null; });
    try {
      ContestParticipation data;
      try {
        data = await _repo.getParticipation(widget.contestId);
      } on ServerFailure catch (e) {
        if (e.statusCode == 409) {
          if (mounted) {
            buildSnackBar(context, e.message, isError: true);
            Navigator.maybePop(context);
          }
          return;
        }
        if (e.statusCode == 403) {
          if (mounted) {
            buildSnackBar(context, e.message, isError: true);
            Navigator.maybePop(context);
          }
          return;
        }
        data = await _repo.startContest(widget.contestId);
      }
      if (!mounted) return;
      setState(() { _data = data; _loading = false; });
      _computeTimeLeft(data.endTime);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _computeTimeLeft(data.endTime);
      });
    } on ServerFailure catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403 || e.statusCode == 409) {
        buildSnackBar(context, e.message, isError: true);
        Navigator.maybePop(context);
        return;
      }
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'فشل تحميل المسابقة'; _loading = false; });
    }
  }

  void _computeTimeLeft(String endTime) {
    try {
      final end = DateTime.parse(endTime);
      final remaining = end.difference(DateTime.now()).inSeconds;
      if (remaining <= 0 && !_success && !_submittingFinal) {
        _timer?.cancel();
        setState(() => _timeLeft = 0);
        _handleFinalSubmit();
        return;
      }
      if (mounted) setState(() => _timeLeft = remaining);
    } catch (_) {}
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<ContestQuestion> get _questions => _data?.questions ?? [];
  ContestQuestion? get _currentQ => _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  bool get _isAnswered => _data?.answeredQuestionIds.contains(_currentQ?.id) ?? false;

  int get _answeredCount => _data?.answeredQuestionIds.length ?? 0;
  int get _totalCount => _questions.length;

  Future<void> _submitAnswer() async {
    if (_currentQ == null || _selectedOption == null || _submittingAnswer) return;
    setState(() => _submittingAnswer = true);
    try {
      await _repo.submitAnswer(
        contestId: widget.contestId,
        questionId: _currentQ!.id,
        selectedOptionId: _selectedOption!,
      );
      if (mounted) {
        setState(() {
          _data!.answeredQuestionIds.add(_currentQ!.id);
          _submittingAnswer = false;
          _selectedOption = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submittingAnswer = false);
        buildSnackBar(context, 'فشل إرسال الإجابة', isError: true);
      }
    }
  }

  Future<void> _handleFinalSubmit() async {
    if (_submittingFinal) return;

    final unanswered = _totalCount - _answeredCount;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('تقديم المسابقة'),
        content: Text(
          unanswered > 0
              ? 'لم تؤكد إجابة $unanswered سؤال بعد. هل أنت متأكد من تقديم المسابقة؟ لا يمكنك العودة بعد التقديم.'
              : 'هل أنت متأكد من تقديم المسابقة؟ لا يمكنك العودة بعد التقديم.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تقديم'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _submittingFinal = true);
    try {
      await _repo.submitContest(widget.contestId);
      if (mounted) {
        _timer?.cancel();
        setState(() { _success = true; _submittingFinal = false; });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submittingFinal = false);
        buildSnackBar(context, 'فشل تقديم المسابقة', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_success) {
          Navigator.maybePop(context);
          return;
        }
        _showLeaveDialog();
      },
      child: _buildBody(context),
    );
  }

  void _showLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مغادرة المسابقة'),
        content: const Text('هل تريد تقديم المسابقة والمغادرة أم العودة للمتابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('متابعة'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleFinalSubmit();
            },
            child: const Text('تقديم ومغادرة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = context.isDark;

    if (_success && _data != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🎉', style: TextStyle(fontSize: 64.sp)),
                SizedBox(height: 16.h),
                Text('تم تقديم المسابقة بنجاح',
                    style: TextStyles.bold20.copyWith(color: context.textPrimary)),
                SizedBox(height: 8.h),
                Text('ستظهر نتيجتك وترتيبك بعد انتهاء المسابقة واحتساب الدرجات.',
                    style: TextStyles.regular14.copyWith(color: context.textSecondary),
                    textAlign: TextAlign.center),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => Navigator.maybePop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200.w, 44.h),
                  ),
                  child: const Text('العودة لقائمة المسابقات'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFF7C3AED),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red.shade400),
                SizedBox(height: 16.h),
                Text(_error!, style: TextStyles.regular14, textAlign: TextAlign.center),
                SizedBox(height: 16.h),
                ElevatedButton(onPressed: _initContest, child: const Text('إعادة المحاولة')),
              ],
            ),
          ),
        ),
      );
    }

    final data = _data!;
    final timeWarning = _timeLeft <= 300;
    final timeCritical = _timeLeft <= 60;
    final timerColor = timeCritical
        ? Colors.red
        : timeWarning
            ? Colors.orange
            : Colors.white;

    final endDt = DateTime.tryParse(data.endTime);
    final startDt = DateTime.tryParse(data.startTime);
    final totalDuration = (endDt != null && startDt != null)
        ? endDt.difference(startDt).inSeconds
        : 1;
    final timerPct = totalDuration > 0
        ? (_timeLeft / totalDuration).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7C3AED),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _success ? Navigator.maybePop(context) : _showLeaveDialog(),
        ),
        title: Text(data.contestTitle, style: TextStyles.semiBold16.copyWith(color: Colors.white)),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: timerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: timerColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer, color: timerColor, size: 18),
                SizedBox(width: 4.w),
                Text(
                  _formatTime(_timeLeft),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _questions.isEmpty
          ? const Center(child: Text('لا توجد أسئلة'))
          : Column(
              children: [
                ClipRRect(
                  child: LinearProgressIndicator(
                    value: timerPct,
                    minHeight: 4.h,
                    backgroundColor: timerColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      timeCritical ? Colors.red : timeWarning ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Row(
                    children: [
                      Text(
                        '$_answeredCount / $_totalCount تم التأكيد',
                        style: TextStyles.regular13.copyWith(color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                _buildQuestionNav(isDark),
                Expanded(child: _buildQuestion(isDark)),
                _buildBottomBar(isDark),
              ],
            ),
    );
  }

  Widget _buildQuestionNav(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          Text(
            'سؤال ${_currentIndex + 1} من $_totalCount',
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
          ),
          const Spacer(),
          SizedBox(
            height: 32.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: _totalCount,
              separatorBuilder: (_, __) => SizedBox(width: 4.w),
              itemBuilder: (_, i) {
                final answered = _data!.answeredQuestionIds.contains(_questions[i].id);
                final isCurrent = i == _currentIndex;
                return GestureDetector(
                  onTap: _submittingFinal ? null : () => setState(() => _currentIndex = i),
                  child: Container(
                    width: 28.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFDB2777)
                          : answered
                              ? const Color(0xFF059669)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: isCurrent || answered ? Colors.white : context.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(bool isDark) {
    final q = _currentQ;
    if (q == null) return const SizedBox.shrink();

    final answered = _isAnswered;

    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border(
              top: BorderSide(
                color: answered
                    ? const Color(0xFF059669)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      q.questionType == 'true_false' ? 'صح/خطأ' : 'اختيار من متعدد',
                      style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo'),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  SizedBox(width: 8.w),
                  Chip(
                    label: Text('${q.pointValue} نقطة',
                        style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo')),
                    backgroundColor: const Color(0xFFFEF3C7),
                    labelStyle: const TextStyle(color: Color(0xFFF59E0B)),
                    visualDensity: VisualDensity.compact,
                  ),
                  const Spacer(),
                  if (answered)
                    Chip(
                      label: Text('تم الإرسال',
                          style: TextStyle(fontSize: 10.sp, fontFamily: 'Cairo', color: Colors.white)),
                      backgroundColor: const Color(0xFF059669),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                q.text,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15.sp,
                  height: 1.8,
                  color: context.textPrimary,
                ),
              ),
              SizedBox(height: 20.h),
              ...q.options.map((opt) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      onTap: answered || _submittingAnswer
                          ? null
                          : () => setState(() => _selectedOption = opt.id),
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _selectedOption == opt.id
                              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB)),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: _selectedOption == opt.id
                                ? const Color(0xFF7C3AED)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: opt.id,
                              groupValue: answered ? opt.id : _selectedOption,
                              onChanged: answered || _submittingAnswer
                                  ? null
                                  : (val) => setState(() => _selectedOption = val),
                            ),
                            Expanded(
                              child: Text(
                                opt.text,
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13.sp,
                                  color: context.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentIndex > 0)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submittingFinal ? null : () => setState(() => _currentIndex--),
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: Text('السابق', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                ),
              ),
            if (_currentIndex > 0) SizedBox(width: 12.w),
            if (_currentIndex < _totalCount - 1)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submittingFinal ? null : () => setState(() => _currentIndex++),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: Text('التالي', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                ),
              ),
            SizedBox(width: 12.w),
            if (!_isAnswered && _currentQ != null)
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedOption != null && !_submittingAnswer) ? _submitAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                  ),
                  child: _submittingAnswer
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('تأكيد الإجابة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                ),
              ),
            if (_isAnswered)
              Expanded(
                child: ElevatedButton(
                  onPressed: _success || _submittingFinal ? null : _handleFinalSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                  ),
                  child: _submittingFinal
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('تقديم المسابقة', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
