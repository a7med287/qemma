import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class TeacherAnalyticsAiSection extends StatelessWidget {
  final Map<String, dynamic> analysis;
  final String courseTitle;
  final bool isLoading;
  final String? error;
  final VoidCallback onDismissError;

  const TeacherAnalyticsAiSection({
    super.key,
    required this.analysis,
    required this.courseTitle,
    this.isLoading = false,
    this.error,
    required this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (error != null) {
      return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        child: _buildErrorBanner(context),
      );
    }

    if (isLoading) {
      return Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: cardBgColor(context),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: fieldBorderColor(context)),
        ),
        child: Column(
          children: [
            SizedBox(
              width: 80.r,
              height: 80.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80.r,
                    height: 80.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  Icon(Icons.auto_awesome, size: 36.r, color: const Color(0xFF7C3AED)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text('جارٍ تحليل بيانات الكورس بالذكاء الاصطناعي...',
                textAlign: TextAlign.center,
                style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            SizedBox(height: 8.h),
            Text('يقوم الذكاء الاصطناعي بتحليل نتائج الاختبارات والواجبات والحضور وأداء الطلاب',
                textAlign: TextAlign.center,
                style: TextStyles.regular13.copyWith(color: context.textSecondary)),
          ],
        ),
      );
    }

    final aiAnalysis = (analysis['analysis'] as Map<String, dynamic>?) ?? {};
    final overall = aiAnalysis['overallAssessment'] as String? ?? '';
    final strengths = (aiAnalysis['strengths'] as List?) ?? [];
    final weaknesses = (aiAnalysis['weaknesses'] as List?) ?? [];
    final strugglingTopics = (aiAnalysis['strugglingTopics'] as List?) ?? [];
    final perfSuggestions = (aiAnalysis['performanceSuggestions'] as List?) ?? [];
    final engagementStrategies = (aiAnalysis['engagementStrategies'] as List?) ?? [];
    final teachingTips = (aiAnalysis['teachingTips'] as List?) ?? [];
    final recommendedActions = (aiAnalysis['recommendedActions'] as List?) ?? [];
    final analyzedAt = analysis['analyzedAt'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOverallCard(context, courseTitle, overall, analyzedAt),
        SizedBox(height: 16.h),
        _buildStrengthsWeaknesses(context, strengths, weaknesses),
        if (strugglingTopics.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildStrugglingTopics(context, strugglingTopics, isDark),
        ],
        if (perfSuggestions.isNotEmpty || engagementStrategies.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildSuggestionsGrid(context, perfSuggestions, engagementStrategies),
        ],
        if (teachingTips.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildTeachingTips(context, teachingTips, isDark),
        ],
        if (recommendedActions.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildRecommendedActions(context, recommendedActions, isDark),
        ],
      ],
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Color(0xFFDC2626), size: 20),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(error ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: const Color(0xFF991B1B))),
          ),
          IconButton(
            onPressed: onDismissError,
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallCard(BuildContext context, String courseTitle, String overall, String analyzedAt) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w, height: 44.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
                ),
                child: const Icon(Icons.insights, color: Colors.white, size: 22),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('التقييم العام', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                      if (analyzedAt.isNotEmpty)
                    Text(courseTitle, style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: context.textSecondary)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(overall, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: context.isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155), height: 1.8)),
        ],
      ),
    );
  }

  Widget _buildStrengthsWeaknesses(BuildContext context, List strengths, List weaknesses) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildListCard(context, 'نقاط القوة', strengths, Icons.check_circle, const Color(0xFF059669), const Color(0xFFECFDF5), const Color(0xFF065F46))),
        SizedBox(width: 12.w),
        Expanded(child: _buildListCard(context, 'نقاط الضعف', weaknesses, Icons.warning_amber, const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFF991B1B))),
      ],
    );
  }

  Widget _buildListCard(BuildContext context, String title, List items, IconData icon, Color iconColor, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              SizedBox(width: 6.w),
              Text(title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 10.h),
          if (items.isEmpty)
            Text('لا توجد بيانات', style: TextStyles.regular13.copyWith(color: context.textSecondary))
          else
            ...items.map((item) => Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text('$item', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: textColor, height: 1.5)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildStrugglingTopics(BuildContext context, List topics, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 24),
              SizedBox(width: 8.w),
              Text('المواضيع التي يعاني منها الطلاب', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 12.h),
          ...topics.map((t) {
            final topic = (t as Map<String, dynamic>);
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF5FF),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: fieldBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📖 ${topic['topic'] ?? ''}',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w900, color: const Color(0xFF7C3AED))),
                  SizedBox(height: 6.h),
                  Text(topic['analysis'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.6)),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text('💡 توصية: ${topic['recommendation'] ?? ''}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6D28D9))),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuggestionsGrid(BuildContext context, List perfSuggestions, List engagementStrategies) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSuggestionCard(context, 'تحسين الأداء', perfSuggestions, Icons.auto_graph, const Color(0xFF2563EB), const Color(0xFFEFF6FF), const Color(0xFF1E40AF))),
        SizedBox(width: 12.w),
        Expanded(child: _buildSuggestionCard(context, 'استراتيجيات التفاعل', engagementStrategies, Icons.lightbulb, const Color(0xFFF59E0B), const Color(0xFFFFFBEB), const Color(0xFF92400E))),
      ],
    );
  }

  Widget _buildSuggestionCard(BuildContext context, String title, List items, IconData icon, Color iconColor, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              SizedBox(width: 6.w),
              Expanded(child: Text(title, style: TextStyles.semiBold14.copyWith(color: context.textPrimary))),
            ],
          ),
          SizedBox(height: 10.h),
          if (items.isEmpty)
            Text('لا توجد بيانات', style: TextStyles.regular13.copyWith(color: context.textSecondary))
          else
            ...items.map((item) => Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: bgColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: iconColor, size: 16),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text('$item', style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: textColor, height: 1.5)),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTeachingTips(BuildContext context, List tips, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote, color: Color(0xFF059669), size: 24),
              SizedBox(width: 8.w),
              Expanded(
                child: Text('نصائح تدريسية من خبير بخبرة 60 عامًا',
                    style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...tips.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value as Map<String, dynamic>;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: fieldBorderColor(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نصيحة #${i + 1}',
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xFF059669))),
                  SizedBox(height: 4.h),
                  Text(t['tip'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF065F46), height: 1.6)),
                  if (t['context'] != null) ...[
                    SizedBox(height: 4.h),
                    Text('— ${t['context']}', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontStyle: FontStyle.italic, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecommendedActions(BuildContext context, List actions, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8.w),
              Text('الإجراءات المقترحة', style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 12.h),
          ...actions.map((a) {
            final action = a as Map<String, dynamic>;
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: cardBgColor(context),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: fieldBorderColor(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('${action['action'] ?? ''}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 11.sp, color: context.textPrimary)),
                  ),
                  SizedBox(width: 8.w),
                  _priorityChip('${action['priority'] ?? ''}'),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: Text('${action['expectedImpact'] ?? ''}',
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: context.textSecondary)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _priorityChip(String priority) {
    Color bgColor;
    Color textColor;
    switch (priority) {
      case 'عالي':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFFDC2626);
        break;
      case 'متوسط':
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFFD97706);
        break;
      default:
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF059669);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Text(priority, style: TextStyle(fontFamily: 'Cairo', fontSize: 9.sp, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}
