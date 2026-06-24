import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/assistant_repository.dart';
import 'widgets/assistant_grade_exams_body.dart';

class AssistantGradeExamsView extends StatefulWidget {
  static const routeName = '/assistant-teacher/grade-exams';
  const AssistantGradeExamsView({super.key});

  @override
  State<AssistantGradeExamsView> createState() => _AssistantGradeExamsViewState();
}

class _AssistantGradeExamsViewState extends State<AssistantGradeExamsView> {
  bool _loading = true;
  List<Map<String, dynamic>> _attempts = [];
  String? _error;

  AssistantRepository get _repo => context.read<AssistantRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final attempts = await _repo.getPendingAttempts();
      if (mounted) setState(() { _attempts = attempts; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'فشل تحميل المحاولات'; _loading = false; });
    }
  }

  Color _fieldBorder() => context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldLabel() => context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _fieldText() => context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _cardBg() => context.isDark ? const Color(0xFF1E293B) : Colors.white;

  void _openGradingModal(Map<String, dynamic> attempt) async {
    final attemptId = (attempt['id'] ?? attempt['_id'] ?? '') as String;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GradingDialog(repo: _repo, attemptId: attemptId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('تصحيح الاختبارات', style: TextStyles.semiBold16.copyWith(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 12.h),
                      Text(_error!, style: TextStyles.regular14),
                      SizedBox(height: 16.h),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ],
                  ),
                )
              : _attempts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          SizedBox(height: 12.h),
                          Text('لا توجد محاولات بانتظار التصحيح',
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldLabel())),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: _attempts.length,
                      itemBuilder: (_, i) => AttemptCard(
                        attempt: _attempts[i],
                        isDark: isDark,
                        fieldBorder: _fieldBorder(),
                        fieldLabel: _fieldLabel(),
                        fieldText: _fieldText(),
                        cardBg: _cardBg(),
                        onTap: () => _openGradingModal(_attempts[i]),
                      ),
                    ),
    );
  }
}
