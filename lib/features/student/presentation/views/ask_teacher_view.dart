import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/mock/student_mock_data.dart';
import '../../data/models/student_models.dart';
import '../widgets/student_shared_widgets.dart';

class AskTeacherView extends StatefulWidget {
  const AskTeacherView({super.key, required this.courseId});

  final String courseId;

  @override
  State<AskTeacherView> createState() => _AskTeacherViewState();
}

class _AskTeacherViewState extends State<AskTeacherView> {
  final _questionController = TextEditingController();
  String _category = 'lesson';
  final _questions = List.of(StudentMockData.previousQuestions);

  final _categories = [
    ('lesson', 'درس', Colors.blue),
    ('homework', 'واجب', Colors.purple),
    ('exam', 'امتحان', Colors.red),
    ('other', 'أخرى', Colors.grey),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_questionController.text.trim().isEmpty) return;
    setState(() {
      _questions.insert(
        0,
        PreviousQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          question: _questionController.text,
          date: 'الآن',
        ),
      );
      _questionController.clear();
    });
    buildSnackBar(context, 'تم إرسال السؤال');
  }

  @override
  Widget build(BuildContext context) {
    final course = StudentMockData.courseById(widget.courseId);

    return StudentPageShell(
      title: '❓ اسأل المدرس',
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          if (course != null)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(studentInitials(course.teacherName))),
                title: Text(course.teacherName),
                subtitle: Text(course.title),
              ),
            ),
          SizedBox(height: 16.h),
          StudentGlassCard(
            title: 'سؤال جديد',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('التصنيف', style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  children: _categories.map((c) {
                    return ChoiceChip(
                      label: Text(c.$2),
                      selected: _category == c.$1,
                      selectedColor: c.$3.withValues(alpha: .2),
                      onSelected: (_) => setState(() => _category = c.$1),
                    );
                  }).toList(),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: _questionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك هنا...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                SizedBox(height: 12.h),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.attach_file), label: const Text('إرفاق ملف')),
                SizedBox(height: 12.h),
                ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send),
                  label: const Text('إرسال السؤال'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48.h)),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Text('الأسئلة السابقة', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
          SizedBox(height: 8.h),
          ..._questions.map((q) => Card(
                margin: EdgeInsets.only(bottom: 8.h),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(q.answered ? Icons.check_circle : Icons.hourglass_empty, color: q.answered ? Colors.green : Colors.orange, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(child: Text(q.question, style: TextStyles.semiBold14)),
                        ],
                      ),
                      if (q.answer != null) ...[
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(q.answer!, style: TextStyles.regular14),
                        ),
                      ],
                      SizedBox(height: 4.h),
                      Text(q.date, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
