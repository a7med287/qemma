import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../routes/student_routes.dart';
import '../widgets/student_shared_widgets.dart';

class ContestsView extends StatefulWidget {
  const ContestsView({super.key});

  @override
  State<ContestsView> createState() => _ContestsViewState();
}

class _ContestsViewState extends State<ContestsView> {
  int _tab = 0;
  final _contests = StudentMockData.contests;

  List<ContestItem> get _shown => _tab == 0
      ? _contests.where((c) => c.status == 'upcoming').toList()
      : _contests.where((c) => c.status == 'completed').toList();

  Color _difficultyColor(String d) => switch (d) {
        'easy' => Colors.green,
        'hard' => Colors.red,
        _ => Colors.orange,
      };

  String _difficultyLabel(String d) => switch (d) {
        'easy' => 'سهل',
        'hard' => 'صعب',
        _ => 'متوسط',
      };

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: '🏆 المسابقات الذهبية',
      gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      headerChild: Wrap(
        spacing: 8.w,
        children: ['علمي رياضة', 'علمي علوم', 'أدبي']
            .map((s) => Chip(label: Text(s), backgroundColor: Colors.white24, labelStyle: const TextStyle(color: Colors.white)))
            .toList(),
      ),
      body: Column(
        children: [
          TabBar(
            onTap: (i) => setState(() => _tab = i),
            tabs: const [
              Tab(text: 'قادمة'),
              Tab(text: 'سابقة'),
            ],
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16.r),
              itemCount: _shown.length,
              itemBuilder: (_, i) {
                final c = _shown[i];
                final color = _difficultyColor(c.difficulty);
                return Card(
                  margin: EdgeInsets.only(bottom: 12.h),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 6.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, color.withValues(alpha: .7)]),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(c.title, style: TextStyles.semiBold16.copyWith(color: context.textPrimary))),
                                if (c.aiGenerated) Chip(label: const Text('AI'), visualDensity: VisualDensity.compact),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 8.w,
                              children: [
                                Chip(label: Text(_difficultyLabel(c.difficulty)), backgroundColor: color.withValues(alpha: .15)),
                                Chip(label: Text('${c.questionCount} سؤال')),
                                Chip(label: Text('${c.participants} مشارك')),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text('📅 ${c.date} • ⏱ ${c.duration} دقيقة', style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                            SizedBox(height: 12.h),
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, StudentRoutes.contestDashboard),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 40.h),
                              ),
                              child: Text(c.status == 'upcoming' ? 'سجّل الآن' : 'عرض النتائج'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
