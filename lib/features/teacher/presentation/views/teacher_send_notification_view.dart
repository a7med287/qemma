import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherSendNotificationView extends StatefulWidget {
  static const routeName = '/teacher/notifications/send';
  const TeacherSendNotificationView({super.key});

  @override
  State<TeacherSendNotificationView> createState() => _TeacherSendNotificationViewState();
}

class _TeacherSendNotificationViewState extends State<TeacherSendNotificationView> {
  String _type = 'announcement';
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _recipient = 'all';
  String _courseId = '';
  String _studentId = '';
  String _scheduleType = 'now';
  String _scheduledDate = '';
  String _scheduledTime = '';

  bool _loading = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _students = [];
  bool _loadingCourses = false;
  bool _loadingStudents = false;

  final _types = [
    {'value': 'announcement', 'label': 'إعلان عام', 'icon': Icons.campaign, 'color': const Color(0xFF2563EB)},
    {'value': 'exam', 'label': 'إشعار بامتحان', 'icon': Icons.assignment, 'color': const Color(0xFFDC2626)},
    {'value': 'results', 'label': 'ظهور النتائج', 'icon': Icons.bar_chart, 'color': const Color(0xFF059669)},
    {'value': 'quiz', 'label': 'اختبار مفاجئ', 'icon': Icons.bolt, 'color': const Color(0xFFF59E0B)},
    {'value': 'lesson', 'label': 'درس جديد', 'icon': Icons.menu_book, 'color': const Color(0xFF7C3AED)},
    {'value': 'reminder', 'label': 'تذكير بحصة', 'icon': Icons.schedule, 'color': const Color(0xFFDB2777)},
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _fetchCourses() async {
    setState(() => _loadingCourses = true);
    try {
      _courses = await context.read<TeacherRepository>().getNotificationCourses();
    } catch (_) { _showToast('فشل تحميل الكورسات', error: true); }
    if (mounted) setState(() => _loadingCourses = false);
  }

  void _fetchStudents() async {
    setState(() => _loadingStudents = true);
    try {
      _students = await context.read<TeacherRepository>().getNotificationStudents();
    } catch (_) { _showToast('فشل تحميل الطلاب', error: true); }
    if (mounted) setState(() => _loadingStudents = false);
  }

  void _submit() async {
    if (_titleCtrl.text.trim().isEmpty) { _showToast('يرجى إدخال عنوان الإشعار', error: true); return; }
    if (_messageCtrl.text.trim().isEmpty) { _showToast('يرجى إدخال نص الإشعار', error: true); return; }
    if (_recipient == 'course' && _courseId.isEmpty) { _showToast('يرجى اختيار الكورس', error: true); return; }
    if (_recipient == 'student' && _studentId.isEmpty) { _showToast('يرجى اختيار الطالب', error: true); return; }
    if (_scheduleType == 'scheduled' && (_scheduledDate.isEmpty || _scheduledTime.isEmpty)) {
      _showToast('يرجى تحديد تاريخ ووقت الإرسال', error: true); return;
    }

    setState(() => _loading = true);
    try {
      final result = await context.read<TeacherRepository>().sendNotification(
        type: _type, title: _titleCtrl.text, message: _messageCtrl.text,
        recipient: _recipient,
        courseId: _recipient == 'course' ? _courseId : null,
        studentId: _recipient == 'student' ? _studentId : null,
        scheduleType: _scheduleType == 'scheduled' ? 'scheduled' : 'now',
        scheduledDate: _scheduleType == 'scheduled' ? _scheduledDate : null,
        scheduledTime: _scheduleType == 'scheduled' ? _scheduledTime : null,
      );
      if (!mounted) return;
      final sent = result['sent'];
      _showToast(sent != null ? 'تم إرسال الإشعار بنجاح لـ $sent طالب!' : 'تم إرسال الإشعار بنجاح!');
      _titleCtrl.clear(); _messageCtrl.clear();
      setState(() {
        _type = 'announcement'; _recipient = 'all'; _courseId = ''; _studentId = '';
        _scheduleType = 'now'; _scheduledDate = ''; _scheduledTime = '';
      });
      Future.delayed(const Duration(seconds: 1), () { if (mounted) Navigator.pop(context, true); });
    } on Failure catch (e) { _showToast(e.message, error: true); setState(() => _loading = false); }
    catch (_) { _showToast('فشل إرسال الإشعار. حاول مرة أخرى.', error: true); setState(() => _loading = false); }
  }

  void _showToast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
      backgroundColor: error ? const Color(0xFFEF4444) : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(isDark),
              SizedBox(height: 20.h),
              _buildTypeGrid(isDark),
              SizedBox(height: 16.h),
              _buildForm(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Container(
              width: 50.w, height: 50.w,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: const Icon(Icons.notifications, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('إرسال إشعار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 20.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                Text('أرسل إشعارات مهمة لطلابك', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeGrid(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('نوع الإشعار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 12.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
            ),
            itemCount: _types.length,
            itemBuilder: (_, i) {
              final t = _types[i];
              final selected = _type == t['value'];
              final color = t['color'] as Color;
              return GestureDetector(
                onTap: () => setState(() => _type = t['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: .08) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA)),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: selected ? color : Colors.transparent, width: 2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(t['icon'] as IconData, color: selected ? color : (isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)), size: 20),
                      SizedBox(width: 8.w),
                      Flexible(child: Text(t['label'] as String,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w700,
                              color: selected ? color : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))))),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(label: 'عنوان الإشعار', controller: _titleCtrl, required: true, isDark: isDark),
          SizedBox(height: 14.h),
          _field(label: 'نص الإشعار', controller: _messageCtrl, multiline: true, maxLines: 4, hint: 'اكتب تفاصيل الإشعار هنا...', isDark: isDark),
          SizedBox(height: 16.h),

          // Recipients
          Text('المستقبلون', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 8.h),
          ...['all', 'course', 'student'].map((r) => _recipientRadio(r, isDark)),

          if (_recipient == 'course') ...[
            SizedBox(height: 12.h),
            _courseDropdown(isDark),
          ],
          if (_recipient == 'student') ...[
            SizedBox(height: 12.h),
            _studentDropdown(isDark),
          ],

          SizedBox(height: 16.h),

          // Schedule
          Text('موعد الإرسال', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 14.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          SizedBox(height: 8.h),
          _scheduleRadio('now', 'إرسال فوري', isDark),
          _scheduleRadio('scheduled', 'جدولة الإرسال', isDark),

          if (_scheduleType == 'scheduled') ...[
            SizedBox(height: 12.h),
            Row(children: [
              Expanded(child: _dateField('التاريخ', _scheduledDate, isDark)),
              SizedBox(width: 12.w),
              Expanded(child: _timeField('الوقت', _scheduledTime, isDark)),
            ]),
          ],

          // Preview
          if (_titleCtrl.text.isNotEmpty && _messageCtrl.text.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _preview(isDark),
          ],

          SizedBox(height: 20.h),

          // Submit
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              gradient: _loading ? null : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)]),
            ),
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _loading ? (isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)) : Colors.transparent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: _loading
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8.w),
                      const Text('جاري الإرسال...', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14)),
                    ])
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [


                    const Text('إرسال الإشعار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 14)),
                SizedBox(width: 8.w),

                const Icon(Icons.send, size: 18),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipientRadio(String value, bool isDark) {
    final labels = {'all': 'جميع الطلاب', 'course': 'كورس محدد', 'student': 'طالب محدد'};
    final icons = {'all': Icons.people, 'course': Icons.school, 'student': Icons.person};
    return InkWell(
      onTap: () {
        setState(() => _recipient = value);
        if (value == 'course' && _courses.isEmpty) _fetchCourses();
        if (value == 'student' && _students.isEmpty) _fetchStudents();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Icon(icons[value], size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
            SizedBox(width: 8.w),
            Text(labels[value]!, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
            const Spacer(),
            SizedBox(
              width: 20, height: 20,
              child: Radio<String>(
                value: value, groupValue: _recipient,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _recipient = v);
                  if (v == 'course' && _courses.isEmpty) _fetchCourses();
                  if (v == 'student' && _students.isEmpty) _fetchStudents();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scheduleRadio(String value, String label, bool isDark) {
    return InkWell(
      onTap: () => setState(() => _scheduleType = value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
            const Spacer(),
            SizedBox(
              width: 20, height: 20,
              child: Radio<String>(
                value: value, groupValue: _scheduleType,
                onChanged: (v) { if (v != null) setState(() => _scheduleType = v); },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseDropdown(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: _loadingCourses
          ? Padding(padding: EdgeInsets.all(12.r), child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              SizedBox(width: 8.w),
              Text('جاري التحميل...', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            ]))
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _courseId.isNotEmpty && _courses.any((c) => (c['id'] ?? c['_id']) == _courseId) ? _courseId : null,
                isExpanded: true,
                hint: Text('اختر الكورس', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                items: [
                  if (_courses.isEmpty)
                    DropdownMenuItem<String>(
                      enabled: false,
                      value: null,
                      child: Text('لا توجد كورسات', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    )
                  else
                    ..._courses.map((c) {
                      final id = (c['id'] ?? c['_id']) as String;
                      final enrollments = c['_count']?['enrollments'] ?? c['enrollmentCount'];
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Row(children: [
                          Text(c['title'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp)),
                          if (enrollments != null) ...[
                            SizedBox(width: 6.w),
                            Text('($enrollments طالب)', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                          ],
                        ]),
                      );
                    }),
                ],
                onChanged: (v) => setState(() => _courseId = v ?? ''),
              ),
            ),
    );
  }

  Widget _studentDropdown(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: _loadingStudents
          ? Padding(padding: EdgeInsets.all(12.r), child: Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
              SizedBox(width: 8.w),
              Text('جاري التحميل...', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
            ]))
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _studentId.isNotEmpty && _students.any((s) => (s['studentId'] ?? s['id']) == _studentId) ? _studentId : null,
                isExpanded: true,
                hint: Text('اختر الطالب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
                items: [
                  if (_students.isEmpty)
                    DropdownMenuItem<String>(
                      enabled: false,
                      value: null,
                      child: Text('لا يوجد طلاب', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                    )
                  else
                    ..._students.map((s) => DropdownMenuItem<String>(
                      value: (s['studentId'] ?? s['id']) as String,
                      child: Text(s['name'] ?? '', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp)),
                    )),
                ],
                onChanged: (v) => setState(() => _studentId = v ?? ''),
              ),
            ),
    );
  }

  Widget _preview(bool isDark) {
    final selectedType = _types.firstWhere((t) => t['value'] == _type);
    final color = selectedType['color'] as Color;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(selectedType['icon'] as IconData, size: 16, color: color),
            SizedBox(width: 6.w),
            Text('معاينة الإشعار', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 11.sp, color: color)),
          ]),
          SizedBox(height: 6.h),
          Text(_titleCtrl.text, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          Text(_messageCtrl.text, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _field({required String label, required TextEditingController controller, bool multiline = false, int maxLines = 1, String? hint, bool required = false, required bool isDark}) {
    return TextField(
      controller: controller, maxLines: multiline ? maxLines : 1, textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: '$label${required ? ' *' : ''}', hintText: hint, hintTextDirection: TextDirection.rtl,
        labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
        filled: true, fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      ),
    );
  }

  Widget _dateField(String label, String value, bool isDark) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value.isNotEmpty ? DateTime.tryParse(value) ?? DateTime.now() : DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: isDark ? Brightness.dark : Brightness.light),
            ),
            child: child!,
          ),
        );
        if (date != null) {
          setState(() => _scheduledDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  Text(value.isEmpty ? 'اختر تاريخ' : value, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.w600, color: value.isEmpty ? (isDark ? const Color(0xFF475569) : const Color(0xFF9CA3AF)) : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)))),
                ],
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _timeField(String label, String value, bool isDark) {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: value.isNotEmpty
              ? TimeOfDay.fromDateTime(DateTime.parse('2024-01-01 $value'))
              : TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B5CF6), brightness: isDark ? Brightness.dark : Brightness.light),
            ),
            child: child!,
          ),
        );
        if (time != null) {
          setState(() => _scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
                  Text(value.isEmpty ? 'اختر وقت' : value, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.w600, color: value.isEmpty ? (isDark ? const Color(0xFF475569) : const Color(0xFF9CA3AF)) : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B)))),
                ],
              ),
            ),
            Icon(Icons.access_time, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}
