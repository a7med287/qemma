import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class SubmitAssignmentView extends StatefulWidget {
  const SubmitAssignmentView({super.key, this.assignmentId});

  final String? assignmentId;

  @override
  State<SubmitAssignmentView> createState() => _SubmitAssignmentViewState();
}

class _SubmitAssignmentViewState extends State<SubmitAssignmentView> {
  List<AssignmentItem> _assignments = [];
  bool _loading = true;
  String? _error;
  String? _selectedId;
  final _notesController = TextEditingController();
  bool _submitted = false;
  String? _filePath;
  int _uploadProgress = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await context.read<StudentRepository>().getStudentAssignments();
      if (!mounted) return;
      final pending = list.where((a) => !a.submitted).toList();
      setState(() {
        _assignments = list;
        _selectedId = widget.assignmentId ?? (pending.isNotEmpty ? pending.first.id : null);
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      // Catch-all so unexpected errors don't leave the view stuck loading.
      if (!mounted) return;
      setState(() {
        _error = 'حدث خطأ غير متوقع، حاول مرة أخرى';
        _loading = false;
      });
    }
  }

  /// Switches the selected assignment and clears any file/notes that were
  /// staged for the previously selected one, so they can't be submitted
  /// against the wrong assignment by mistake.
  void _selectAssignment(String id) {
    if (id == _selectedId) return;
    setState(() {
      _selectedId = id;
      _filePath = null;
      _uploadProgress = 0;
      _notesController.clear();
    });
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return; // user cancelled the picker
      final path = result.files.single.path;
      if (path == null) {
        if (!mounted) return;
        buildSnackBar(context, 'تعذر قراءة الملف المختار، حاول مرة أخرى', isError: true);
        return;
      }
      setState(() => _filePath = path);
    } catch (e) {
      if (!mounted) return;
      buildSnackBar(context, 'حدث خطأ أثناء اختيار الملف', isError: true);
    }
  }

  Future<void> _submit() async {
    if (_selectedId == null || _filePath == null) return;
    setState(() {
      _submitting = true;
      _uploadProgress = 0;
    });
    try {
      await context.read<StudentRepository>().submitAssignment(
        assignmentId: _selectedId!,
        filePath: _filePath!,
        notes: _notesController.text.trim(),
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      if (!mounted) return;
      setState(() {
        _submitted = true;
        _submitting = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      buildSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      buildSnackBar(context, 'حدث خطأ غير متوقع أثناء التسليم، حاول مرة أخرى', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _assignments.where((a) => !a.submitted).toList();
    final selected = _assignments.where((a) => a.id == _selectedId).firstOrNull;

    return StudentPageShell(
      title: '📤 تسليم الواجبات',
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _submitted
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64.sp, color: Colors.green),
              SizedBox(height: 16.h),
              Text('تم تسليم الواجب بنجاح!', style: TextStyles.bold20),
              SizedBox(height: 16.h),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('العودة')),
            ],
          ),
        )
            : ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            Text('الواجبات المعلقة', style: TextStyles.bold18.copyWith(color: context.textPrimary)),
            ...pending.map((a) => Card(
              color: _selectedId == a.id ? Colors.blue.shade50 : null,
              child: ListTile(
                selected: _selectedId == a.id,
                title: Text(a.title),
                subtitle: Text('${a.courseTitle} • 📅 ${a.dueDate}'),
                trailing: Text('${a.maxScore} درجة'),
                onTap: () => _selectAssignment(a.id),
              ),
            )),
            if (selected != null) ...[
              SizedBox(height: 24.h),
              Text(selected.title, style: TextStyles.bold18),
              Text('${selected.courseTitle} • ${selected.maxScore} درجة', style: TextStyles.regular14.copyWith(color: context.textSecondary)),
              SizedBox(height: 16.h),
              InkWell(
                onTap: _pickFile,
                child: Container(
                  height: 120.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload, size: 40.sp, color: context.textSecondary),
                      Text(_filePath?.split(RegExp(r'[/\\]')).last ?? 'اضغط لرفع PDF أو صورة', style: TextStyles.regular14),
                    ],
                  ),
                ),
              ),
              if (_submitting) ...[
                SizedBox(height: 12.h),
                LinearProgressIndicator(value: _uploadProgress / 100),
                Text('$_uploadProgress%'),
              ],
              SizedBox(height: 16.h),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _filePath != null && !_submitting ? _submit : null,
                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48.h)),
                child: Text(_submitting ? 'جاري الرفع...' : 'تسليم الواجب'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}