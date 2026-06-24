import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../student/presentation/widgets/student_async_body.dart';
import '../../../student/presentation/widgets/student_shared_widgets.dart';
import 'widgets/assistant_profile_body.dart';

class AssistantProfileView extends StatefulWidget {
  static const routeName = '/assistant-teacher/profile';
  const AssistantProfileView({super.key});

  @override
  State<AssistantProfileView> createState() => _AssistantProfileViewState();
}

class _AssistantProfileViewState extends State<AssistantProfileView> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  bool _editing = false;
  bool _saving = false;
  bool _showUsername = false;

  bool _passwordLoading = false;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _passwordCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await context.read<AuthService>().getCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _nameCtrl.text = user.name;
        _phoneCtrl.text = user.phone ?? '';
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _error = 'فشل تحميل بيانات الملف الشخصي'; _loading = false; });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      buildSnackBar(context, 'الاسم لا يمكن أن يكون فارغاً', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await context.read<AuthService>().updateProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _user = updated; _editing = false; _saving = false; });
      buildSnackBar(context, 'تم تحديث البيانات بنجاح ✅');
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      buildSnackBar(context, 'فشل حفظ التعديلات، حاول مرة أخرى', isError: true);
    }
  }

  void _cancelEdit() {
    setState(() {
      _editing = false;
      _nameCtrl.text = _user?.name ?? '';
      _phoneCtrl.text = _user?.phone ?? '';
    });
  }

  void _copyUsername() {
    final username = _user?.username ?? '';
    if (username.isEmpty) return;
    Clipboard.setData(ClipboardData(text: username));
    buildSnackBar(context, 'تم نسخ اسم المستخدم 📋');
  }

  Future<void> _addPassword() async {
    final password = _passwordCtrl.text.trim();
    if (password.length < 8) {
      buildSnackBar(context, 'يجب أن تتكون كلمة المرور من 8 أحرف على الأقل', isError: true);
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      buildSnackBar(context, 'يجب أن تحتوي كلمة المرور على حرف كبير', isError: true);
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      buildSnackBar(context, 'يجب أن تحتوي كلمة المرور على حرف صغير', isError: true);
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      buildSnackBar(context, 'يجب أن تحتوي كلمة المرور على رقم', isError: true);
      return;
    }
    setState(() => _passwordLoading = true);
    try {
      await context.read<AuthCubit>().addPassword(password);
      if (mounted) {
        _passwordCtrl.clear();
        setState(() => _passwordLoading = false);
        buildSnackBar(context, 'تم إضافة كلمة المرور بنجاح ✅');
        _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordLoading = false);
        buildSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StudentPageShell(
      title: 'الملف الشخصي',
      headerChild: _user == null ? null : ProfileHeaderInfo(
        user: _user!,
        onEditTap: () => setState(() => _editing = !_editing),
      ),
      body: StudentAsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _user == null
            ? const SizedBox.shrink()
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  children: [
                    ProfileInfoCard(
                      user: _user!,
                      editing: _editing,
                      nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl,
                      showUsername: _showUsername,
                      onCopyUsername: _copyUsername,
                      onToggleUsername: () => setState(() => _showUsername = !_showUsername),
                    ),
                    if (_user!.specialties.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      ProfileSpecialtiesCard(user: _user!),
                    ],
                    if (!_user!.hasPassword) ...[
                      SizedBox(height: 16.h),
                      ProfilePasswordCard(
                        user: _user!,
                        passwordCtrl: _passwordCtrl,
                        passwordLoading: _passwordLoading,
                        onAddPassword: _addPassword,
                      ),
                    ],
                    if (_editing) ...[
                      SizedBox(height: 16.h),
                      ProfileActionButtons(
                        saving: _saving,
                        onCancel: _cancelEdit,
                        onSave: _save,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
