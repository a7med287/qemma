import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/data/services/auth_service.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../student/presentation/widgets/student_async_body.dart';
import '../../../student/presentation/widgets/student_shared_widgets.dart';

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
      headerChild: _user == null ? null : _buildHeaderInfo(context, _user!),
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
                    _buildInfoCard(context, _user!),
                    if (_user!.specialties.isNotEmpty) ...[
                      SizedBox(height: 16.h),
                      _buildSpecialtiesCard(context, _user!),
                    ],
                    if (!_user!.hasPassword) ...[
                      SizedBox(height: 16.h),
                      _buildPasswordCard(context, _user!),
                    ],
                    if (_editing) ...[
                      SizedBox(height: 16.h),
                      _buildActionButtons(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderInfo(BuildContext context, UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 36.r,
              backgroundColor: Colors.white,
              child: Text(
                studentInitials(user.name),
                style: TextStyles.bold20.copyWith(color: AppColors.gradientMid),
              ),
            ),
            Positioned(
              bottom: -2,
              left: -2,
              child: GestureDetector(
                onTap: () => setState(() => _editing = !_editing),
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gradientMid, width: 1.5),
                  ),
                  child: Icon(Icons.edit, size: 14.sp, color: AppColors.gradientMid),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: TextStyles.bold20.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  user.role.label,
                  style: TextStyles.semiBold13.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, UserModel user) {
    return StudentGlassCard(
      title: 'المعلومات الشخصية',
      icon: '📋',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            context,
            label: 'الاسم الكامل',
            icon: Icons.person_outline,
            control: _editing
                ? TextField(
                    controller: _nameCtrl,
                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                  )
                : Text(user.name, style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
          ),
          SizedBox(height: 14.h),
          _field(
            context,
            label: 'اسم المستخدم (مدرس مساعد)',
            control: Text(
              _showUsername ? (user.username ?? '—') : '•' * ((user.username?.length ?? 8).clamp(6, 14)),
              style: TextStyles.semiBold14.copyWith(
                color: const Color(0xFFF59E0B),
                letterSpacing: _showUsername ? 0 : 2,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _copyUsername,
                icon: Icon(Icons.copy_rounded, size: 18.sp, color: context.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: () => setState(() => _showUsername = !_showUsername),
                icon: Icon(
                  _showUsername ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 18.sp,
                  color: const Color(0xFFF59E0B),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
            warning: 'اسم المستخدم محجوز ولا يمكن لأي شخص آخر استخدامه',
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  context,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  control: Text(
                    user.email,
                    style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _field(
                  context,
                  label: 'رقم الهاتف',
                  icon: Icons.phone_outlined,
                  control: _editing
                      ? TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                        )
                      : Text(
                          user.phone?.isNotEmpty == true ? user.phone! : 'غير مسجل',
                          style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                        ),
                ),
              ),
            ],
          ),
          if (user.subject != null && user.subject!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _field(
                    context,
                    label: 'التخصص',
                    icon: Icons.school,
                    control: Text(
                      user.subject!,
                      style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecialtiesCard(BuildContext context, UserModel user) {
    return StudentGlassCard(
      title: 'المواد الدراسية',
      icon: '📚',
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: user.specialties.map((s) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(s,
                style: TextStyles.semiBold13.copyWith(color: Colors.white)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPasswordCard(BuildContext context, UserModel user) {
    return StudentGlassCard(
      title: 'كلمة المرور',
      icon: '🔐',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lock_open, size: 18, color: const Color(0xFFF59E0B)),
              SizedBox(width: 8.w),
              Text('لا توجد كلمة مرور',
                  style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
            ],
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'أدخل كلمة المرور الجديدة',
              hintStyle: TextStyles.regular13.copyWith(color: context.textSecondary),
              border: InputBorder.none,
              filled: true,
              fillColor: context.isDark ? const Color(0xFF1B2140) : const Color(0xFFF8FAFC),
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _passwordLoading ? null : _addPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientMid,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: _passwordLoading
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('إضافة كلمة المرور',
                      style: TextStyles.semiBold14.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : _cancelEdit,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              side: BorderSide(color: context.borderColor),
            ),
            child: Text('إلغاء', style: TextStyles.semiBold14.copyWith(color: context.textPrimary)),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientMid,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: _saving
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('حفظ التغييرات', style: TextStyles.semiBold14.copyWith(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _field(
    BuildContext context, {
    required String label,
    required Widget control,
    IconData? icon,
    List<Widget>? actions,
    String? warning,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyles.regular13.copyWith(color: context.textSecondary)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1B2140) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Expanded(child: control),
              if (actions != null) ...actions,
              if (icon != null) Icon(icon, size: 18.sp, color: context.textSecondary),
            ],
          ),
        ),
        if (warning != null) ...[
          SizedBox(height: 6.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 14.sp, color: const Color(0xFFF59E0B)),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  warning,
                  style: TextStyles.regular13.copyWith(color: const Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}