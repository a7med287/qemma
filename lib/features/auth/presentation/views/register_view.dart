import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/app_background.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../cubits/auth_cubit.dart';
import 'widgets/auth_styles.dart';
import 'widgets/register_local_form_body.dart';
import 'widgets/register_verify_assistant_body.dart';
import 'widgets/register_verify_parent_body.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  static const routeName = '/register';

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  String _step = 'local';

  final _nameCtrl            = TextEditingController();
  final _emailPrefixCtrl     = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  UserRole _role     = UserRole.student;
  String? _division;
  String? _subject;
  bool _showPassword        = false;
  bool _showConfirmPassword = false;
  bool _loading             = false;
  Map<String, String?> _errors = {};

  final _teacherUsernameCtrl = TextEditingController();
  final _teacherCodeCtrl     = TextEditingController();
  Map<String, dynamic>? _teacherInfo;
  bool _teacherCodeSent   = false;
  bool _teacherLookupLoading = false;
  bool _teacherVerifyLoading = false;
  String? _teacherError;

  final _studentUsernameCtrl = TextEditingController();
  final _parentCodeCtrl      = TextEditingController();
  Map<String, dynamic>? _studentInfo;
  bool _parentCodeSent    = false;
  bool _parentLookupLoading = false;
  bool _parentVerifyLoading = false;
  String? _parentError;

  AuthService get _authService => context.read<AuthService>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailPrefixCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _teacherUsernameCtrl.dispose();
    _teacherCodeCtrl.dispose();
    _studentUsernameCtrl.dispose();
    _parentCodeCtrl.dispose();
    super.dispose();
  }

  String get _fullEmail =>
      _emailPrefixCtrl.text.trim().isNotEmpty ? '${_emailPrefixCtrl.text.trim()}@qemma.com' : '';

  bool _validate() {
    final errors = <String, String?>{};
    final prefix = _emailPrefixCtrl.text.trim();

    if (prefix.isEmpty) {
      errors['email'] = 'البريد الإلكتروني مطلوب';
    } else if (prefix.contains('@')) {
      errors['email'] = 'أدخل الجزء قبل @qemma.com فقط';
    } else if (prefix.length < 2) {
      errors['email'] = 'اسم البريد قصير جداً';
    }
    if (_passwordCtrl.text.isEmpty) {
      errors['password'] = 'كلمة المرور مطلوبة';
    } else if (_passwordCtrl.text.length < 8) {
      errors['password'] = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    } else if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(_passwordCtrl.text)) {
      errors['password'] = 'يجب أن تحتوي على حرف كبير وصغير ورقم';
    }
    if (_confirmPasswordCtrl.text.isEmpty) {
      errors['confirmPassword'] = 'تأكيد كلمة المرور مطلوب';
    } else if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      errors['confirmPassword'] = 'كلمتا المرور غير متطابقتين';
    }
    if (_nameCtrl.text.trim().length < 2) errors['name'] = 'الاسم يجب أن يكون حرفين على الأقل';

    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      errors['phone'] = 'رقم الهاتف مطلوب';
    } else if (!RegExp(r'^01[0-2,5]{1}[0-9]{8}$').hasMatch(phone)) {
      errors['phone'] = 'رقم الهاتف غير صالح (مثال: 01012345678)';
    }
    if (_role == UserRole.student && (_division == null || _division!.isEmpty)) {
      errors['division'] = 'يرجى اختيار القسم الدراسي';
    }
    if ((_role == UserRole.teacher || _role == UserRole.assistantTeacher) &&
        (_subject == null || _subject!.isEmpty)) {
      errors['subject'] = 'يجب اختيار المادة الدراسية';
    }
    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  void _handleSubmit() {
    if (!_validate()) return;
    if (_role == UserRole.assistantTeacher) { setState(() => _step = 'verify-assistant'); return; }
    if (_role == UserRole.parent)           { setState(() => _step = 'verify-parent');    return; }
    _doRegister();
  }

  Future<void> _doRegister({String? teacherName, String? studentUsername}) async {
    setState(() => _loading = true);
    try {
      final req = RegisterRequest(
        name:            _nameCtrl.text.trim(),
        email:           _fullEmail,
        password:        _passwordCtrl.text,
        role:            _role,
        phone:           _phoneCtrl.text.trim(),
        division:        _division,
        subject:         _subject,
        teacherName:     teacherName,
        studentUsername: studentUsername,
      );
      final user = await context.read<AuthCubit>().register(req);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, user.dashboardRoute);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _lookupTeacher() async {
    if (_teacherUsernameCtrl.text.trim().isEmpty) {
      setState(() => _teacherError = 'يرجى إدخال اسم المستخدم للمدرس');
      return;
    }
    setState(() { _teacherLookupLoading = true; _teacherError = null; _teacherInfo = null; });
    try {
      final info = await _authService.lookupTeacher(_teacherUsernameCtrl.text.trim());
      setState(() => _teacherInfo = info);
    } catch (e) {
      setState(() => _teacherError = 'لم يتم العثور على مدرس بهذا الاسم المميز');
    } finally {
      setState(() => _teacherLookupLoading = false);
    }
  }

  Future<void> _sendCodeToTeacher() async {
    setState(() { _teacherVerifyLoading = true; _teacherError = null; });
    try {
      await _authService.sendCodeToTeacher(
        teacherUsername: _teacherUsernameCtrl.text.trim(),
        assistantEmail:  _fullEmail,
      );
      setState(() => _teacherCodeSent = true);
      buildSnackBar(context, 'تم إرسال الكود للمدرس في الوقت الفعلي! ⚡');
    } catch (e) {
      setState(() => _teacherError = 'فشل إرسال الكود');
    } finally {
      setState(() => _teacherVerifyLoading = false);
    }
  }

  Future<void> _verifyTeacherCode() async {
    if (_teacherCodeCtrl.text.trim().length != 6) {
      setState(() => _teacherError = 'يرجى إدخال الكود المكون من 6 أرقام');
      return;
    }
    setState(() { _teacherVerifyLoading = true; _teacherError = null; });
    try {
      await _authService.verifyTeacherCode(
        teacherUsername: _teacherUsernameCtrl.text.trim(),
        code:            _teacherCodeCtrl.text.trim(),
      );
      buildSnackBar(context, 'تم التحقق بنجاح! ✅');
      await _doRegister(teacherName: _teacherUsernameCtrl.text.trim());
    } catch (e) {
      setState(() => _teacherError = 'الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _teacherVerifyLoading = false);
    }
  }

  Future<void> _lookupStudent() async {
    if (_studentUsernameCtrl.text.trim().isEmpty) {
      setState(() => _parentError = 'يرجى إدخال اسم المستخدم للطالب');
      return;
    }
    setState(() { _parentLookupLoading = true; _parentError = null; _studentInfo = null; });
    try {
      final info = await _authService.lookupStudent(_studentUsernameCtrl.text.trim());
      setState(() => _studentInfo = info);
    } catch (e) {
      setState(() => _parentError = 'لم يتم العثور على طالب بهذا الاسم المميز');
    } finally {
      setState(() => _parentLookupLoading = false);
    }
  }

  Future<void> _sendCodeToStudent() async {
    setState(() { _parentVerifyLoading = true; _parentError = null; });
    try {
      await _authService.sendCodeToStudent(
        studentUsername: _studentUsernameCtrl.text.trim(),
        parentEmail:     _fullEmail,
      );
      setState(() => _parentCodeSent = true);
      buildSnackBar(context, 'تم إرسال الكود للطالب في الوقت الفعلي! ⚡');
    } catch (e) {
      setState(() => _parentError = 'فشل إرسال الكود');
    } finally {
      setState(() => _parentVerifyLoading = false);
    }
  }

  Future<void> _verifyParentCode() async {
    if (_parentCodeCtrl.text.trim().length != 6) {
      setState(() => _parentError = 'يرجى إدخال الكود المكون من 6 أرقام');
      return;
    }
    setState(() { _parentVerifyLoading = true; _parentError = null; });
    try {
      await _authService.verifyParentCode(
        studentUsername: _studentUsernameCtrl.text.trim(),
        code:            _parentCodeCtrl.text.trim(),
      );
      buildSnackBar(context, 'تم التحقق بنجاح! ✅');
      await _doRegister(studentUsername: _studentUsernameCtrl.text.trim());
    } catch (e) {
      setState(() => _parentError = 'الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _parentVerifyLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: switch (_step) {
              'local'            => RegisterLocalFormBody(
                nameCtrl: _nameCtrl,
                emailPrefixCtrl: _emailPrefixCtrl,
                phoneCtrl: _phoneCtrl,
                passwordCtrl: _passwordCtrl,
                confirmPasswordCtrl: _confirmPasswordCtrl,
                role: _role,
                division: _division,
                subject: _subject,
                showPassword: _showPassword,
                showConfirmPassword: _showConfirmPassword,
                errors: _errors,
                isTeacher: _role == UserRole.teacher || _role == UserRole.assistantTeacher,
                onRoleChanged: (r) => setState(() { _role = r; _errors.remove('division'); _errors.remove('subject'); }),
                onDivisionChanged: (v) => setState(() { _division = v; _errors.remove('division'); }),
                onSubjectChanged: (v) => setState(() { _subject = v; _errors.remove('subject'); }),
                onTogglePassword: () => setState(() => _showPassword = !_showPassword),
                onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                onErrorRemove: (k) => setState(() => _errors.remove(k)),
                onSubmit: _handleSubmit,
                loading: _loading,
                onLoginTap: () => Navigator.pushReplacementNamed(context, '/login'),
              ),
              'verify-assistant' => RegisterVerifyAssistantBody(
                teacherUsernameCtrl: _teacherUsernameCtrl,
                teacherCodeCtrl: _teacherCodeCtrl,
                teacherInfo: _teacherInfo,
                teacherCodeSent: _teacherCodeSent,
                teacherLookupLoading: _teacherLookupLoading,
                teacherVerifyLoading: _teacherVerifyLoading,
                teacherError: _teacherError,
                onBack: () => setState(() => _step = 'local'),
                onLookupTeacher: _lookupTeacher,
                onSendCodeToTeacher: _sendCodeToTeacher,
                onVerifyTeacherCode: _verifyTeacherCode,
                onResendCode: () => setState(() { _teacherCodeSent = false; _teacherCodeCtrl.clear(); }),
                onCodeChanged: (_) {},
              ),
              'verify-parent'    => RegisterVerifyParentBody(
                studentUsernameCtrl: _studentUsernameCtrl,
                parentCodeCtrl: _parentCodeCtrl,
                studentInfo: _studentInfo,
                parentCodeSent: _parentCodeSent,
                parentLookupLoading: _parentLookupLoading,
                parentVerifyLoading: _parentVerifyLoading,
                parentError: _parentError,
                onBack: () => setState(() => _step = 'local'),
                onLookupStudent: _lookupStudent,
                onSendCodeToStudent: _sendCodeToStudent,
                onVerifyParentCode: _verifyParentCode,
                onResendCode: () => setState(() { _parentCodeSent = false; _parentCodeCtrl.clear(); }),
                onCodeChanged: (_) {},
              ),
              _                  => const SizedBox(),
            },
          ),
        ),
      ),
    );
  }
}
