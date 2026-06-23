// lib/features/student/presentation/views/student_profile_view.dart
//
// Student profile page.
// Data comes from AuthService (getCurrentUser / updateProfile), NOT from
// StudentRepository — the profile lives in the auth domain, same as the web
// frontend (authService.getCurrentUser / authService.updateProfile).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_colors.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../core/helpers/build_snack_bar.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/data/services/auth_service.dart';
import '../widgets/student_async_body.dart';
import '../widgets/student_shared_widgets.dart';

class StudentProfileView extends StatefulWidget {
  static const routeName = '/student/profile';
  const StudentProfileView({super.key});

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  UserModel? _user;
  bool _loading = true;
  String? _error;

  bool _editing = false;
  bool _saving = false;
  bool _showUsername = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'فشل تحميل بيانات الملف الشخصي';
        _loading = false;
      });
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
      setState(() {
        _user = updated;
        _editing = false;
        _saving = false;
      });
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

  void _changePasswordComingSoon() {
    buildSnackBar(context, 'ميزة تغيير كلمة المرور ستتوفر قريباً');
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
          child: _buildInfoCard(context, _user!),
        ),
      ),
    );
  }

  // ── Header: avatar + name + role + edit toggle ──────────────────────
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

  // ── Body: personal info card ─────────────────────────────────────────
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
            label: 'اسم المستخدم وكلمة المرور',
            control: Text(
              _showUsername ? (user.username ?? '—') : '•' * ((user.username?.length ?? 8).clamp(6, 14)),
              style: TextStyles.semiBold14.copyWith(
                color: context.textPrimary,
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
            warning: 'اسم المستخدم يُنشأ تلقائيًا ولا يمكن تعديله من هنا',
          ),
          // Align(
          //   alignment: Alignment.centerLeft,
          //   child: TextButton.icon(
          //     onPressed: _changePasswordComingSoon,
          //     icon: Icon(Icons.lock_outline, size: 16.sp, color: AppColors.gradientMid),
          //     label: Text(
          //       'تغيير كلمة المرور',
          //       style: TextStyles.semiBold13.copyWith(color: AppColors.gradientMid),
          //     ),
          //   ),
          // ),
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
                    style: TextStyles.semiBold14.copyWith(color: context.textPrimary),
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
          if (_editing) ...[
            SizedBox(height: 20.h),
            Row(
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
                        : Text('حفظ التعديلات', style: TextStyles.semiBold14.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared field shell (label + boxed value + optional actions/warning) ──
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