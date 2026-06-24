import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/repositories/teacher_repository.dart';
import 'widgets/teacher_schedule_calendar.dart';
import 'widgets/teacher_schedule_create_dialog.dart';

class TeacherScheduleView extends StatefulWidget {
  static const routeName = '/teacher/schedule';
  const TeacherScheduleView({super.key});

  @override
  State<TeacherScheduleView> createState() => _TeacherScheduleViewState();
}

class _TeacherScheduleViewState extends State<TeacherScheduleView> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _meetingLinkCtrl = TextEditingController();
  final _maxStudentsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCourse = '';
  String _selectedType = 'online';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _sessions = [];
  bool _loadingSessions = true;
  bool _submitting = false;
  String? _editingId;

  TeacherRepository get _repo => context.read<TeacherRepository>();

  @override
  void initState() {
    super.initState();
    _endTime = _addHour(_startTime);
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

  TimeOfDay _addHour(TimeOfDay t) {
    final m = t.hour * 60 + t.minute + 60;
    return TimeOfDay(hour: m ~/ 60, minute: m % 60);
  }

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

  void _showCreateDialog() {
    _resetForm();
    _editingId = null;
    _showDialog();
  }

  void _showEditDialog(Map<String, dynamic> session) {
    setState(() {
      _editingId = (session['id'] ?? session['_id'] ?? '') as String;
      _titleCtrl.text = (session['title'] ?? '') as String;
      _selectedCourse = (session['courseId'] ?? '') as String;
      _selectedType = (session['type'] ?? 'online') as String;
      _meetingLinkCtrl.text = (session['meetingLink'] ?? '') as String;
      _maxStudentsCtrl.text = (session['maxStudents']?.toString() ?? '');
      _descCtrl.text = (session['description'] ?? '') as String;
      final rawDate = session['date'] as String?;
      if (rawDate != null) _selectedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
      final st = session['startTime'] as String?;
      if (st != null) {
        final parts = st.split(':');
        if (parts.length == 2) {
          _startTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
      final et = session['endTime'] as String?;
      if (et != null) {
        final parts = et.split(':');
        if (parts.length == 2) {
          _endTime = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
        }
      }
    });
    _showDialog();
  }

  void _showDialog() {
    showDialog(
      context: context,
      builder: (_) => TeacherScheduleCreateDialog(
        formKey: _formKey,
        titleCtrl: _titleCtrl,
        meetingLinkCtrl: _meetingLinkCtrl,
        maxStudentsCtrl: _maxStudentsCtrl,
        descCtrl: _descCtrl,
        selectedCourse: _selectedCourse,
        selectedType: _selectedType,
        selectedDate: _selectedDate,
        startTime: _startTime,
        endTime: _endTime,
        courses: _courses,
        submitting: _submitting,
        editingId: _editingId,
        onCourseChanged: (v) => setState(() => _selectedCourse = v),
        onTypeChanged: (v) => setState(() => _selectedType = v),
        onDatePicked: _pickDate,
        onStartTimePicked: () => _pickTime(isStart: true),
        onEndTimePicked: () => _pickTime(isStart: false),
        onSubmit: _handleSubmit,
        onCancel: () => Navigator.maybePop(context),
      ),
    );
  }

  void _resetForm() {
    _titleCtrl.clear();
    _selectedCourse = '';
    _selectedDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = _addHour(TimeOfDay.now());
    _selectedType = 'online';
    _meetingLinkCtrl.clear();
    _maxStudentsCtrl.clear();
    _descCtrl.clear();
  }

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
      'maxStudents': _maxStudentsCtrl.text.trim().isNotEmpty
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
        await _repo.createSession(data);
        buildSnackBar(context, 'تم إضافة الحصة بنجاح!');
        Navigator.maybePop(context, true);
        await _fetchSessions();
        return;
      }
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ', isError: true);
    }
    setState(() => _submitting = false);
    Navigator.maybePop(context);
  }

  Future<void> _handleDelete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Cairo')),
        content: const Text('هل تريد حذف هذه الحصة؟', style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repo.deleteSession(id);
      setState(() => _sessions.removeWhere((s) => (s['id'] ?? s['_id'] ?? '') == id));
      buildSnackBar(context, 'تم حذف الحصة بنجاح');
    } catch (_) {
      buildSnackBar(context, 'حدث خطأ أثناء الحذف', isError: true);
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
              (_endTime.hour == picked.hour && _endTime.minute <= picked.minute)) {
            _endTime = _addHour(picked);
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('جدولة الحصص',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: TeacherScheduleCalendar(
          sessions: _sessions,
          loading: _loadingSessions,
          editingId: _editingId,
          onEdit: _showEditDialog,
          onDelete: _handleDelete,
        ),
      ),
    );
  }
}
