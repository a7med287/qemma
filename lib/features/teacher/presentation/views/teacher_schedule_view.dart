import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/repositories/teacher_repository.dart';

class TeacherScheduleView extends StatefulWidget {
  static const routeName = '/teacher/schedule';
  const TeacherScheduleView({super.key});

  @override
  State<TeacherScheduleView> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleView> {
  // ── Form ───────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();
  final _maxStudentsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCourse = '';
  String _selectedType = 'online';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = _ScheduleHelper.addHour(TimeOfDay.now());

  // ── Data ───────────────────────────────────────────────────────
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _loadingSessions = true;
  bool _submitting = false;
  String? _editingId;

  TeacherRepository get _repo => context.read<TeacherRepository>();

  @override
  void initState() {
    super.initState();
    _endTime = _ScheduleHelper.addHour(_startTime);
    _fetchCourses();
    _fetchSessions();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _meetingLinkCtrl.dispose();
    _maxStudentsCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _timeStr(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Fetch ──────────────────────────────────────────────────────
  Future<void> _fetchCourses() async {
    try {
      final courses = await _repo.getCoursesForSchedule();
      if (mounted) setState(() => _courses = courses);
    } catch (_) {}
  }

  Future<void> _fetchSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final sessions = await _repo.getSessionList();
      if (mounted) setState(() => _sessions = sessions);
    } catch (_) {}
    if (mounted) setState(() => _loadingSessions = false);
  }

  // ── Edit / Cancel ──────────────────────────────────────────────
  void _handleEdit(Map<String, dynamic> session) {
    setState(() {
      _editingId = (session['id'] ?? session['_id'] ?? '') as String;
      _titleCtrl.text = (session['title'] ?? '') as String;
      _selectedCourse = (session['courseId'] ?? '') as String;
      _selectedType = (session['type'] ?? 'online') as String;
      _meetingLinkCtrl.text = (session['meetingLink'] ?? '') as String;
      _maxStudentsCtrl.text = (session['maxStudents']?.toString() ?? '');
      _descCtrl.text = (session['description'] ?? '') as String;
      final rawDate = session['date'] as String?;
      if (rawDate != null) {
        _selectedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      }
      final st = session['startTime'] as String?;
      if (st != null) {
        final parts = st.split(':');
        if (parts.length == 2) {
          _startTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      final et = session['endTime'] as String?;
      if (et != null) {
        final parts = et.split(':');
        if (parts.length == 2) {
          _endTime = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    });
  }

  void _handleCancelEdit() {
    setState(() {
      _editingId = null;
      _resetForm();
    });
  }

  void _resetForm() {
    _titleCtrl.clear();
    _selectedCourse = '';
    _selectedDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = _ScheduleHelper.addHour(TimeOfDay.now());
    _selectedType = 'online';
    _meetingLinkCtrl.clear();
    _maxStudentsCtrl.clear();
    _descCtrl.clear();
  }

  // ── Submit ─────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final data = {
      'title': _titleCtrl.text.trim(),
      'course': _selectedCourse,
      'date': _dateStr(_selectedDate),
      'startTime': _timeStr(_startTime),
      'endTime': _timeStr(_endTime),
      'type': _selectedType,
      'meetingLink': _meetingLinkCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'maxStudents':
          _maxStudentsCtrl.text.trim().isNotEmpty
              ? int.tryParse(_maxStudentsCtrl.text.trim())
              : null,
    };

    try {
      if (_editingId != null) {
        final updated = await _repo.updateSession(_editingId!, data);
        setState(() {
          _sessions = _sessions.map((s) {
            final sid = (s['id'] ?? s['_id'] ?? '') as String;
            return sid == _editingId ? updated : s;
          }).toList();
          _editingId = null;
        });
        buildSnackBar(context, 'تم تعديل الحصة بنجاح!');
      } else {
        final created = await _repo.createSession(data);
        buildSnackBar(context, 'تم إضافة الحصة بنجاح!');
        Navigator.maybePop(context, true);
        return;
      }
      _resetForm();
    } catch (e) {
      buildSnackBar(context, 'حدث خطأ أثناء ${_editingId != null ? 'تعديل' : 'إضافة'} الحصة', isError: true);
    }
    setState(() => _submitting = false);
  }

  // ── Delete ─────────────────────────────────────────────────────
  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف',
            style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل تريد حذف هذه الحصة؟',
            style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء',
                style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(
                    fontFamily: 'Cairo', color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.deleteSession(id);
      setState(() => _sessions.removeWhere(
          (s) => (s['id'] ?? s['_id'] ?? '') == id));
      buildSnackBar(context, 'تم حذف الحصة بنجاح');
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ أثناء الحذف', isError: true);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final d = DateTime.parse(dateStr);
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          if (_endTime.hour < picked.hour ||
              (_endTime.hour == picked.hour &&
                  _endTime.minute <= picked.minute)) {
            _endTime = _ScheduleHelper.addHour(picked);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  // ── Theme ──────────────────────────────────────────────────────
  Color _fieldBorder() =>
      context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
  Color _fieldText() =>
      context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937);
  Color _fieldLabel() =>
      context.isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
  Color _cardBg() =>
      context.isDark ? const Color(0xFF1E293B) : Colors.white;
  Color _bgColor() =>
      context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: _bgColor(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(_editingId != null ? 'تعديل حصة' : 'إضافة حصة جديدة',
            style: TextStyles.semiBold16.copyWith(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildForm(isDark),
            SizedBox(height: 24.h),
            _buildSessionsSection(isDark),
          ],
        ),
      ),
    );
  }

  // ── Form ───────────────────────────────────────────────────────
  Widget _buildForm(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('بيانات الحصة',
                  style: TextStyles.semiBold16.copyWith(color: _fieldText())),
              SizedBox(height: 4.h),
              Text('قم بجدولة حصة جديدة لطلابك',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: _fieldLabel(),
                  )),
              SizedBox(height: 16.h),

              // Title
              _buildTextField(
                controller: _titleCtrl,
                label: 'عنوان الحصة *',
                hint: 'مثال: مراجعة الوحدة الأولى',
                icon: Icons.class_,
                iconColor: const Color(0xFF2563EB),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'الحقل مطلوب' : null,
              ),
              SizedBox(height: 12.h),

              // Course dropdown
              _buildCourseDropdown(isDark),
              SizedBox(height: 12.h),

              // Date + type
              Row(
                children: [
                  Expanded(child: _buildDateField(isDark)),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildTypeDropdown(isDark)),
                ],
              ),
              SizedBox(height: 12.h),

              // Start + End time
              Row(
                children: [
                  Expanded(child: _buildTimeField('وقت البداية *', _startTime,
                      () => _pickTime(isStart: true), isDark)),
                  SizedBox(width: 12.w),
                  Expanded(child: _buildTimeField('وقت النهاية *', _endTime,
                      () => _pickTime(isStart: false), isDark)),
                ],
              ),
              SizedBox(height: 12.h),

              // Meeting link (online only)
              if (_selectedType == 'online') ...[
                _buildTextField(
                  controller: _meetingLinkCtrl,
                  label: 'رابط الحصة (Zoom, Google Meet...)',
                  hint: 'https://zoom.us/j/...',
                  icon: Icons.link,
                  iconColor: const Color(0xFF8B5CF6),
                ),
                SizedBox(height: 12.h),
              ],

              // Max students
              _buildTextField(
                controller: _maxStudentsCtrl,
                label: 'الحد الأقصى للطلاب (اختياري)',
                hint: 'مثال: 30',
                icon: Icons.people,
                iconColor: const Color(0xFF10B981),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 12.h),

              // Description
              _buildDescriptionField(isDark),
              SizedBox(height: 16.h),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _editingId != null
                        ? _handleCancelEdit
                        : () => Navigator.maybePop(context),
                    child: Text(
                      _editingId != null ? 'إلغاء التعديل' : 'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: _fieldLabel(),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)]),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: _submitting ? null : _handleSubmit,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_submitting)
                                SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              else
                                const Icon(Icons.save,
                                    color: Colors.white, size: 18),
                              SizedBox(width: 8.w),
                              Text(
                                _submitting
                                    ? 'جارٍ الحفظ...'
                                    : _editingId != null
                                        ? 'حفظ التعديلات'
                                        : 'حفظ الحصة',
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    required Color iconColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: TextStyle(
          fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: _fieldLabel(),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          color: _fieldLabel().withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(icon, size: 20, color: iconColor),
        filled: true,
        fillColor: context.isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder()),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder()),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildCourseDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCourse.isNotEmpty ? _selectedCourse : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.people, size: 20, color: Color(0xFF7C3AED)),
              SizedBox(width: 8.w),
              Text('اختر الكورس',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13.sp,
                    color: _fieldLabel().withValues(alpha: 0.5),
                  )),
            ],
          ),
          dropdownColor: _cardBg(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: _fieldText(),
          ),
          items: [
            DropdownMenuItem(
                value: '',
                child: Text('بدون كورس محدد',
                    style: TextStyle(color: _fieldLabel()))),
            ..._courses.map((c) {
              final id = (c['id'] ?? c['_id'] ?? '') as String;
              final title = (c['title'] ?? '') as String;
              return DropdownMenuItem(value: id, child: Text(title));
            }),
          ],
          onChanged: (v) => setState(() => _selectedCourse = v ?? ''),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return InkWell(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _fieldBorder()),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                size: 20, color: Color(0xFFDB2777)),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('التاريخ *',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: _fieldLabel(),
                    )),
                Text(_dateStr(_selectedDate),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _fieldText(),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeDropdown(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: _fieldBorder()),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          isExpanded: true,
          dropdownColor: _cardBg(),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13.sp,
            color: _fieldText(),
          ),
          items: const [
            DropdownMenuItem(
                value: 'online', child: Text('حصة أونلاين')),
            DropdownMenuItem(
                value: 'offline', child: Text('حصة حضورية')),
          ],
          onChanged: (v) => setState(() => _selectedType = v ?? 'online'),
        ),
      ),
    );
  }

  Widget _buildTimeField(String label, TimeOfDay time,
      VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _fieldBorder()),
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule,
                size: 20, color: Color(0xFFF59E0B)),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      color: _fieldLabel(),
                    )),
                Text(_timeStr(time),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: _fieldText(),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionField(bool isDark) {
    return TextFormField(
      controller: _descCtrl,
      maxLines: 4,
      style: TextStyle(
          fontFamily: 'Cairo', fontSize: 14.sp, color: _fieldText()),
      decoration: InputDecoration(
        labelText: 'وصف الحصة (اختياري)',
        hintText: 'أضف تفاصيل إضافية عن الحصة...',
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: _fieldLabel(),
        ),
        hintStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          color: _fieldLabel().withValues(alpha: 0.5),
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder()),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: _fieldBorder()),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  // ── Sessions List ──────────────────────────────────────────────
  Widget _buildSessionsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('حصصي المجدولة',
            style:
                TextStyles.semiBold16.copyWith(color: _fieldText())),
        SizedBox(height: 12.h),
        if (_loadingSessions)
          const Center(child: CircularProgressIndicator())
        else if (_sessions.isEmpty)
          _buildEmptyState(isDark)
        else
          ..._sessions.map((s) => _buildSessionCard(s, isDark)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _fieldBorder()),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today,
              size: 48, color: _fieldLabel()),
          SizedBox(height: 12.h),
          Text('لا توجد حصص مجدولة بعد',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: _fieldLabel(),
              )),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isDark) {
    final id = (session['id'] ?? session['_id'] ?? '') as String;
    final title = (session['title'] ?? '') as String;
    final type = (session['type'] ?? 'online') as String;
    final date = session['date'] as String?;
    final startTime = (session['startTime'] ?? '') as String;
    final endTime = (session['endTime'] ?? '') as String;
    final courseTitle = session['courseTitle'] as String?;
    final meetingLink = session['meetingLink'] as String?;
    final isEditing = _editingId == id;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: _cardBg(),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEditing
              ? const Color(0xFF2563EB)
              : _fieldBorder(),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              color: _fieldText(),
                            )),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: type == 'online'
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          type == 'online' ? 'أونلاين' : 'حضوري',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: type == 'online'
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Wrap(
                    spacing: 12.w,
                    runSpacing: 4.h,
                    children: [
                      _infoRow(Icons.calendar_today,
                          _formatDate(date), isDark),
                      _infoRow(Icons.schedule,
                          '$startTime - $endTime', isDark),
                      if (courseTitle != null)
                        _infoRow(
                            Icons.class_, courseTitle, isDark),
                    ],
                  ),
                  if (meetingLink != null && meetingLink.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text('🔗 رابط الحصة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 11.sp,
                            color: const Color(0xFF2563EB),
                          )),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => _handleEdit(session),
                  icon: const Icon(Icons.edit, size: 18),
                  color: const Color(0xFF2563EB),
                  constraints: BoxConstraints(
                      minWidth: 32.w, minHeight: 32.w),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2563EB).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                IconButton(
                  onPressed: () => _handleDelete(id),
                  icon: const Icon(Icons.delete, size: 18),
                  color: const Color(0xFFEF4444),
                  constraints: BoxConstraints(
                      minWidth: 32.w, minHeight: 32.w),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: _fieldLabel()),
        SizedBox(width: 4.w),
        Text(text,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 11.sp,
              color: _fieldLabel(),
            )),
      ],
    );
  }
}

class _ScheduleHelper {
  static TimeOfDay addHour(TimeOfDay t) {
    final m = t.hour * 60 + t.minute + 60;
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }
}
