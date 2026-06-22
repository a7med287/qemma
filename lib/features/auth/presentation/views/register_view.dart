// lib/features/auth/views/register_view.dart
// Mirrors frontend/src/pages/auth/RegisterPage.jsx
// Steps: choice → local → verify-assistant | verify-parent

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/app_background.dart';
import '../../data/models/auth_models.dart';
import '../../data/services/auth_service.dart';
import '../cubits/auth_cubit.dart';
import 'widgets/auth_styles.dart';

const _domain = '@qemma.com';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});
  static const routeName = '/register';

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  // 'local' | 'verify-assistant' | 'verify-parent'
  String _step = 'local';

  // Form fields
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

  // Assistant OTP
  final _teacherUsernameCtrl = TextEditingController();
  final _teacherCodeCtrl     = TextEditingController();
  Map<String, dynamic>? _teacherInfo;
  bool _teacherCodeSent   = false;
  bool _teacherLookupLoading = false;
  bool _teacherVerifyLoading = false;
  String? _teacherError;

  // Parent OTP
  final _studentUsernameCtrl = TextEditingController();
  final _parentCodeCtrl      = TextEditingController();
  Map<String, dynamic>? _studentInfo;
  bool _parentCodeSent    = false;
  bool _parentLookupLoading = false;
  bool _parentVerifyLoading = false;
  String? _parentError;

  static const _subjects = [
    'اللغة العربية', 'اللغة الإنجليزية', 'الفيزياء', 'الكيمياء',
    'الأحياء', 'الرياضيات', 'الجغرافيا', 'التاريخ', 'الإحصاء',
  ];

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
      _emailPrefixCtrl.text.trim().isNotEmpty ? '${_emailPrefixCtrl.text.trim()}$_domain' : '';

  Color _roleColor(UserRole role) => switch (role) {
    UserRole.student          => AuthColors.studentColor,
    UserRole.teacher          => AuthColors.teacherColor,
    UserRole.assistantTeacher => AuthColors.assistantColor,
    UserRole.parent           => AuthColors.parentColor,
  };

  bool _validate() {
    final errors = <String, String?>{};
    final prefix = _emailPrefixCtrl.text.trim();

    if (prefix.isEmpty) {
      errors['email'] = 'البريد الإلكتروني مطلوب';
    } else if (prefix.contains('@')) {
      errors['email'] = 'أدخل الجزء قبل $_domain فقط';
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
    if (phone.isNotEmpty && !RegExp(r'^01[0-2,5]{1}[0-9]{8}$').hasMatch(phone)) {
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
        phone:           _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        division:        _division,
        subject:         _subject,
        teacherName:     teacherName,
        studentUsername: studentUsername,
      );
      final user = await context.read<AuthCubit>().register(req);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, user.dashboardRoute);
    } catch (e) {
      // error shown via cubit / toast
      // يث
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Teacher lookup ────────────────────────────────────────────
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
      _showSnack('تم إرسال الكود للمدرس في الوقت الفعلي! ⚡', AuthColors.success);
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
      _showSnack('تم التحقق بنجاح! ✅', AuthColors.success);
      await _doRegister(teacherName: _teacherUsernameCtrl.text.trim());
    } catch (e) {
      setState(() => _teacherError = 'الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _teacherVerifyLoading = false);
    }
  }

  // ── Student lookup (parent flow) ──────────────────────────────
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
      _showSnack('تم إرسال الكود للطالب في الوقت الفعلي! ⚡', AuthColors.success);
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
      _showSnack('تم التحقق بنجاح! ✅', AuthColors.success);
      await _doRegister(studentUsername: _studentUsernameCtrl.text.trim());
    } catch (e) {
      setState(() => _parentError = 'الكود غير صحيح أو انتهت صلاحيته');
    } finally {
      if (mounted) setState(() => _parentVerifyLoading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Cairo')),
      backgroundColor: color,
    ));
  }

  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: switch (_step) {
              'local'            => _buildLocalForm(),
              'verify-assistant' => _buildVerifyAssistant(),
              'verify-parent'    => _buildVerifyParent(),
              _                  => _buildLocalForm(),
            },
          ),
        ),
      ),
    );
  }

  // ── Choice screen ─────────────────────────────────────────────
  Widget _buildChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Align(
        //   alignment: AlignmentDirectional.topStart,
        //   child: TextButton.icon(
        //     onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        //     icon: Icon(Icons.arrow_back_rounded, color: AuthColors.textSecondary(context), size: 18),
        //     label: Text('العودة للرئيسية',
        //         style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo')),
        //   ),
        // ),
        SizedBox(height: 120.h),
        const BrandTitle(),
        SizedBox(height: 10.h),
        Text('إنشاء حساب جديد',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context))),
        SizedBox(height: 6.h),
        Text('اختر طريقة التسجيل المناسبة لك',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AuthColors.textSecondary(context))),
        SizedBox(height: 36.h),

        OutlinedAuthButton(
          text: 'التسجيل بواسطة Google',
          onPressed: () => _showSnack('التسجيل بجوجل غير متاح في التطبيق حالياً', AuthColors.info),
          icon: _googleIcon(),
        ),
        SizedBox(height: 20.h),

        Row(children: [
          Expanded(child: Divider(color: AuthColors.border(context))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text('أو', style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo')),
          ),
          Expanded(child: Divider(color: AuthColors.border(context))),
        ]),
        SizedBox(height: 20.h),

        GradientButton(
          text: 'التسجيل بالبريد الإلكتروني',
          onPressed: () => setState(() => _step = 'local'),
        ),
        SizedBox(height: 24.h),

        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('لديك حساب بالفعل؟  ',
              style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context), fontSize: 13)),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('سجل الدخول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AuthColors.gradientStart)),
          ),
        ]),
        SizedBox(height: 800,)
      ],
    );
  }

  // ── Local registration form ───────────────────────────────────
  Widget _buildLocalForm() {
    final isTeacher = _role == UserRole.teacher || _role == UserRole.assistantTeacher;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TextButton.icon(
        //   onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        //   icon: Icon(Icons.arrow_back_rounded, color: AuthColors.textSecondary(context), size: 18),
        //   label: Text('العودة للرئيسية', style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo')),
        // ),
        SizedBox(height: 20.h),
        Center(child: Column(children: [
          const BrandTitle(),
          SizedBox(height: 8.h),
          Text('إنشاء حساب جديد',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 4.h),
          Text('أكمل البيانات التالية للتسجيل',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AuthColors.textSecondary(context))),
        ])),
        SizedBox(height: 24.h),

        // ── Role selector ──────────────────────────────────────
        Text('نوع الحساب',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context))),
        SizedBox(height: 12.h),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 2.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _roleCard(UserRole.student,          'طالب',       Icons.school_rounded),
            _roleCard(UserRole.teacher,          'مدرس',       Icons.person_rounded),
            _roleCard(UserRole.assistantTeacher, 'مدرس مساعد', Icons.supervisor_account_rounded),
            _roleCard(UserRole.parent,           'ولي أمر',    Icons.family_restroom_rounded),
          ],
        ),
        SizedBox(height: 16.h),

        // Auto-username info
        _infoBox('🎯 سيتم إنشاء اسم مستخدم فريد لك تلقائياً بعد إنشاء الحساب'),
        SizedBox(height: 16.h),

        // ── Division (student only) ────────────────────────────
        if (_role == UserRole.student) ...[
          _dropdownField(
            label: 'القسم الدراسي *',
            value: _division,
            error: _errors['division'],
            items: const [
              DropdownMenuItem(value: 'science-math', child: Text('علمي رياضة', style: TextStyle(fontFamily: 'Cairo'))),
              DropdownMenuItem(value: 'science-bio',  child: Text('علمي علوم',   style: TextStyle(fontFamily: 'Cairo'))),
              DropdownMenuItem(value: 'arts',         child: Text('أدبي',        style: TextStyle(fontFamily: 'Cairo'))),
            ],
            onChanged: (v) => setState(() { _division = v; _errors.remove('division'); }),
          ),
          SizedBox(height: 12.h),
        ],

        // ── Subject (teacher / assistant) ──────────────────────
        if (isTeacher) ...[
          _dropdownField(
            label: 'المادة الدراسية *',
            value: _subject,
            error: _errors['subject'],
            items: _subjects.map((s) => DropdownMenuItem(value: s,
                child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
            onChanged: (v) => setState(() { _subject = v; _errors.remove('subject'); }),
          ),
          SizedBox(height: 12.h),
        ],

        // OTP notice for assistant / parent
        if (_role == UserRole.assistantTeacher) ...[
          _infoBox('⚡ بعد ملء البيانات ستحتاج للتحقق من هوية المدرس عبر كود OTP'),
          SizedBox(height: 12.h),
        ],
        if (_role == UserRole.parent) ...[
          _infoBox('⚡ بعد ملء البيانات ستحتاج للتحقق عبر الطالب عبر كود OTP'),
          SizedBox(height: 12.h),
        ],

        // ── Form fields ────────────────────────────────────────
        AuthTextField(
          label: 'الاسم الكامل',
          controller: _nameCtrl,
          prefixIcon: Icon(Icons.person_outline_rounded, color: AuthColors.textSecondary(context)),
          errorText: _errors['name'],
          onChanged: (_) => setState(() => _errors.remove('name')),
        ),
        SizedBox(height: 12.h),

        // Email field with @qemma.com suffix
        _emailField(),
        SizedBox(height: 12.h),

        AuthTextField(
          label: 'رقم الهاتف (اختياري)',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          hint: '01012345678',
          prefixIcon: Icon(Icons.phone_outlined, color: AuthColors.textSecondary(context)),
          errorText: _errors['phone'],
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() => _errors.remove('phone')),
        ),
        SizedBox(height: 12.h),

        AuthTextField(
          label: 'كلمة المرور',
          controller: _passwordCtrl,
          obscureText: !_showPassword,
          prefixIcon: Icon(Icons.lock_outline_rounded, color: AuthColors.textSecondary(context)),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _showPassword = !_showPassword),
            icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AuthColors.textSecondary(context)),
          ),
          errorText: _errors['password'],
          onChanged: (_) => setState(() => _errors.remove('password')),
        ),
        SizedBox(height: 12.h),

        AuthTextField(
          label: 'تأكيد كلمة المرور',
          controller: _confirmPasswordCtrl,
          obscureText: !_showConfirmPassword,
          prefixIcon: Icon(Icons.lock_outline_rounded, color: AuthColors.textSecondary(context)),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
            icon: Icon(_showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AuthColors.textSecondary(context)),
          ),
          errorText: _errors['confirmPassword'],
          onChanged: (_) => setState(() => _errors.remove('confirmPassword')),
        ),
        SizedBox(height: 24.h),

        GradientButton(
          text: switch (_role) {
            UserRole.assistantTeacher => 'التالي: التحقق من المدرس →',
            UserRole.parent           => 'التالي: التحقق من الطالب →',
            _                        => 'إنشاء حساب',
          },
          onPressed: _handleSubmit,
          isLoading: _loading,
        ),
        SizedBox(height: 20.h),

        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('لديك حساب بالفعل؟  ',
              style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context), fontSize: 13)),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('سجل الدخول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AuthColors.gradientStart)),
          ),
        ])),
        SizedBox(height: 16.h),
      ],
    );
  }

  // ── Verify assistant OTP ──────────────────────────────────────
  Widget _buildVerifyAssistant() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _step = 'local'),
          icon: Icon(Icons.arrow_back_rounded, color: AuthColors.textSecondary(context), size: 18),
          label: Text('رجوع', style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo')),
        ),
        SizedBox(height: 20.h),
        Center(child: Column(children: [
          Text('ربط حساب المدرس المساعد 🔗',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 6.h),
          Text('أدخل اسم المستخدم الخاص بالمدرس الذي ستساعده',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AuthColors.textSecondary(context))),
        ])),
        SizedBox(height: 28.h),

        // Step 1: lookup
        Text('الخطوة 1: ابحث عن المدرس بالاسم المميز',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context))),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(
            child: AuthTextField(
              label: 'اسم المستخدم',
              controller: _teacherUsernameCtrl,
              hint: 'tch_SwiftEagle42',
              textDirection: TextDirection.ltr,
              enabled: !_teacherLookupLoading && _teacherInfo == null,
              prefixIcon: Icon(Icons.search_rounded, color: AuthColors.textSecondary(context)),
            ),
          ),
          if (_teacherInfo == null) ...[
            SizedBox(width: 10.w),
            _miniButton(
              label: 'بحث',
              onPressed: _lookupTeacher,
              loading: _teacherLookupLoading,
              color: AuthColors.teacherColor,
            ),
          ],
        ]),
        SizedBox(height: 16.h),

        if (_teacherInfo != null) ...[
          _personCard(
            name:  _teacherInfo!['name'] ?? '',
            username: _teacherInfo!['username'] ?? '',
            label: 'مدرس',
            color: AuthColors.teacherColor,
            icon: Icons.person_rounded,
          ),
          SizedBox(height: 16.h),
        ],

        if (_teacherInfo != null && !_teacherCodeSent) ...[
          Text('الخطوة 2: أرسل كود التحقق للمدرس',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          _infoBox('سيصل للمدرس ${_teacherInfo!['name']} كود مكون من 6 أرقام في الوقت الفعلي عبر الإشعارات.'),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'إرسال الكود للمدرس ⚡',
            onPressed: _sendCodeToTeacher,
            isLoading: _teacherVerifyLoading,
            gradient: const LinearGradient(
              colors: [AuthColors.teacherColor, AuthColors.gradientStart],
            ),
          ),
          SizedBox(height: 16.h),
        ],

        if (_teacherCodeSent) ...[
          Text('الخطوة 3: أدخل الكود الذي أرسله لك المدرس',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          AuthAlert(message: '✅ تم إرسال الكود للمدرس. اطلب منه الكود ثم أدخله هنا.', type: AlertType.success),
          SizedBox(height: 12.h),
          AuthTextField(
            label: 'كود التحقق (6 أرقام)',
            controller: _teacherCodeCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            maxLength: 6,
            hint: '000000',
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits != v) _teacherCodeCtrl.text = digits;
              setState(() => _teacherError = null);
            },
          ),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'تحقق وأكمل التسجيل ✅',
            onPressed: _teacherCodeCtrl.text.length == 6 ? _verifyTeacherCode : null,
            isLoading: _teacherVerifyLoading,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: TextButton(
              onPressed: () => setState(() { _teacherCodeSent = false; _teacherCodeCtrl.clear(); }),
              child: Text('إعادة إرسال الكود',
                  style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context))),
            ),
          ),
        ],

        if (_teacherError != null) ...[
          SizedBox(height: 8.h),
          AuthAlert(message: _teacherError!, type: AlertType.error),
        ],
      ],
    );
  }

  // ── Verify parent OTP ─────────────────────────────────────────
  Widget _buildVerifyParent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _step = 'local'),
          icon: Icon(Icons.arrow_back_rounded, color: AuthColors.textSecondary(context), size: 18),
          label: Text('رجوع', style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo')),
        ),
        SizedBox(height: 20.h),
        Center(child: Column(children: [
          Text('ربط حساب ولي الأمر 👨‍👩‍👦',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w900,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 6.h),
          Text('أدخل اسم المستخدم الخاص بابنك/ابنتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AuthColors.textSecondary(context))),
        ])),
        SizedBox(height: 28.h),

        Text('الخطوة 1: ابحث عن الطالب بالاسم المميز',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context))),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(
            child: AuthTextField(
              label: 'اسم المستخدم',
              controller: _studentUsernameCtrl,
              hint: 'std_BraveWolf42',
              textDirection: TextDirection.ltr,
              enabled: !_parentLookupLoading && _studentInfo == null,
              prefixIcon: Icon(Icons.search_rounded, color: AuthColors.textSecondary(context)),
            ),
          ),
          if (_studentInfo == null) ...[
            SizedBox(width: 10.w),
            _miniButton(
              label: 'بحث',
              onPressed: _lookupStudent,
              loading: _parentLookupLoading,
              color: AuthColors.parentColor,
            ),
          ],
        ]),
        SizedBox(height: 16.h),

        if (_studentInfo != null) ...[
          _personCard(
            name:     _studentInfo!['name'] ?? '',
            username: _studentInfo!['username'] ?? '',
            label:    'طالب',
            color:    AuthColors.parentColor,
            icon:     Icons.school_rounded,
          ),
          SizedBox(height: 16.h),
        ],

        if (_studentInfo != null && !_parentCodeSent) ...[
          Text('الخطوة 2: أرسل كود التحقق للطالب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          _infoBox('سيصل للطالب ${_studentInfo!['name']} كود مكون من 6 أرقام في الوقت الفعلي عبر الإشعارات.'),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'إرسال الكود للطالب ⚡',
            onPressed: _sendCodeToStudent,
            isLoading: _parentVerifyLoading,
            gradient: const LinearGradient(
              colors: [AuthColors.parentColor, AuthColors.teacherColor],
            ),
          ),
          SizedBox(height: 16.h),
        ],

        if (_parentCodeSent) ...[
          Text('الخطوة 3: أدخل الكود الذي أرسله لك الطالب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          AuthAlert(message: '✅ تم إرسال الكود للطالب. اطلب منه الكود ثم أدخله هنا.', type: AlertType.success),
          SizedBox(height: 12.h),
          AuthTextField(
            label: 'كود التحقق (6 أرقام)',
            controller: _parentCodeCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            maxLength: 6,
            hint: '000000',
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits != v) _parentCodeCtrl.text = digits;
              setState(() => _parentError = null);
            },
          ),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'تحقق وأكمل التسجيل ✅',
            onPressed: _parentCodeCtrl.text.length == 6 ? _verifyParentCode : null,
            isLoading: _parentVerifyLoading,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: TextButton(
              onPressed: () => setState(() { _parentCodeSent = false; _parentCodeCtrl.clear(); }),
              child: Text('إعادة إرسال الكود',
                  style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context))),
            ),
          ),
        ],

        if (_parentError != null) ...[
          SizedBox(height: 8.h),
          AuthAlert(message: _parentError!, type: AlertType.error),
        ],
      ],
    );
  }

  // ── Small shared widgets ──────────────────────────────────────
  Widget _roleCard(UserRole role, String label, IconData icon) {
    final selected = _role == role;
    final color    = _roleColor(role);
    return GestureDetector(
      onTap: () => setState(() { _role = role; _errors.remove('division'); _errors.remove('subject'); }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: .12) : AuthColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AuthColors.border(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 8.w),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
              fontWeight: FontWeight.w700, color: selected ? color : AuthColors.textSecondary(context))),
        ]),
      ),
    );
  }

  Widget _emailField() {
    return TextField(
      controller: _emailPrefixCtrl,
      textDirection: TextDirection.ltr,
      keyboardType: TextInputType.emailAddress,
      onChanged: (v) {
        // strip @ and everything after
        final cleaned = v.replaceAll(RegExp(r'@.*'), '');
        if (cleaned != v) {
          _emailPrefixCtrl.value = _emailPrefixCtrl.value.copyWith(text: cleaned);
        }
        setState(() => _errors.remove('email'));
      },
      style: TextStyle(color: AuthColors.textPrimary(context), fontFamily: 'Cairo', fontSize: 15),
      decoration: InputDecoration(
        labelText: 'البريد الإلكتروني',
        hintText: 'اسمك',
        errorText: _errors['email'],
        helperText: _emailPrefixCtrl.text.trim().isNotEmpty
            ? 'سيكون بريدك: $_fullEmail'
            : 'يجب أن ينتهي بـ $_domain',
        labelStyle: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo'),
        hintStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo'),
        helperStyle: TextStyle(color: AuthColors.textHint(context), fontFamily: 'Cairo', fontSize: 11),
        errorStyle: const TextStyle(color: AuthColors.error, fontFamily: 'Cairo', fontSize: 11),
        prefixIcon: Icon(Icons.alternate_email_rounded, color: AuthColors.textSecondary(context)),
        suffixIcon: Container(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AuthColors.surfaceLight(context),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(_domain,
              style: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo',
                  fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        filled: true,
        fillColor: AuthColors.surface(context),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuthColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? error,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: AuthColors.surface(context),
      style: TextStyle(color: AuthColors.textPrimary(context), fontFamily: 'Cairo', fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        labelStyle: TextStyle(color: AuthColors.textSecondary(context), fontFamily: 'Cairo'),
        errorStyle: const TextStyle(color: AuthColors.error, fontFamily: 'Cairo', fontSize: 11),
        filled: true,
        fillColor: AuthColors.surface(context),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AuthColors.border(context)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthColors.error),
        ),
      ),
    );
  }

  Widget _personCard({
    required String name,
    required String username,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .5), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: .15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontFamily: 'Cairo', fontSize: 15,
              fontWeight: FontWeight.w700, color: AuthColors.textPrimary(context))),
          Text('@$username', style: TextStyle(fontFamily: 'Cairo', fontSize: 12,
              color: AuthColors.textSecondary(context))),
          SizedBox(height: 4.h),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 11,
                fontWeight: FontWeight.w700, color: color)),
          ),
        ])),
        Icon(Icons.check_circle_rounded, color: AuthColors.success, size: 24),
      ]),
    );
  }

  Widget _miniButton({
    required String label,
    required VoidCallback onPressed,
    required bool loading,
    required Color color,
  }) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: loading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: loading
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(label, style: const TextStyle(fontFamily: 'Cairo',
                    fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AuthColors.gradientStart.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AuthColors.gradientStart.withValues(alpha: .25)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.info_outline_rounded, color: AuthColors.gradientStart, size: 16),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: const TextStyle(color: AuthColors.gradientStart,
              fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final quarters = [
      (-0.5, const Color(0xFFEA4335)),
      (0.5,  const Color(0xFF4285F4)),
      (1.5,  const Color(0xFFFBBC05)),
      (2.5,  const Color(0xFF34A853)),
    ];
    for (final (start, color) in quarters) {
      paint.color = color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: r),
          start * 3.14159, 3.14159, true, paint);
    }
    paint.color = Colors.white;
    canvas.drawCircle(center, r * 0.5, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}