import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class TeacherProfileView extends StatefulWidget {
  static const routeName = '/teacher/profile';
  const TeacherProfileView({super.key});

  @override
  State<TeacherProfileView> createState() => _TeacherProfileViewState();
}

class _TeacherProfileViewState extends State<TeacherProfileView> {
  bool _editing = false;
  bool _passwordLoading = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _passwordCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startEditing(UserModel user) {
    _nameCtrl.text = user.name;
    _phoneCtrl.text = user.phone ?? '';
    setState(() => _editing = true);
  }

  Future<void> _saveProfile(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<AuthCubit>().updateProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) setState(() => _editing = false);
    } catch (_) {}
  }

  Future<void> _addPassword() async {
    final password = _passwordCtrl.text.trim();
    if (password.length < 8) {
      _showSnack('يجب أن تتكون كلمة المرور من 8 أحرف على الأقل');
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showSnack('يجب أن تحتوي كلمة المرور على حرف كبير');
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showSnack('يجب أن تحتوي كلمة المرور على حرف صغير');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showSnack('يجب أن تحتوي كلمة المرور على رقم');
      return;
    }
    setState(() => _passwordLoading = true);
    try {
      await context.read<AuthCubit>().addPassword(password);
      if (mounted) {
        _passwordCtrl.clear();
        setState(() => _passwordLoading = false);
        _showSnack('تم إضافة كلمة المرور بنجاح');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordLoading = false);
        _showSnack(e.toString());
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontFamily: 'Cairo'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('الرجاء تسجيل الدخول'));
          }
          final user = state.user;
          return Column(
            children: [
              _buildHeader(isDark, user),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16.r),
                  children: [
                    _buildProfileCard(isDark, user),
                    SizedBox(height: .05.h),
                    _buildInfoSection(isDark, user),
                    if (user.specialties.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      _buildSpecialtiesSection(isDark, user),
                    ],
                    SizedBox(height: 20.h),
                    _buildPasswordSection(isDark, user),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isDark, UserModel user) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 40.h),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.white12),
            ),
            SizedBox(width: 8.w),
            Text('الملف الشخصي',
                style: TextStyles.bold20.copyWith(color: Colors.white)),
            const Spacer(),
            if (!_editing)
              IconButton(
                onPressed: () => _startEditing(user),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              )
            else ...[
              IconButton(
                onPressed: () => _saveProfile(user),
                icon: const Icon(Icons.check, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.green.withValues(alpha: 0.3)),
              ),
              IconButton(
                onPressed: () => setState(() => _editing = false),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.3)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, UserModel user) {
    return Transform.translate(
      offset: Offset(0, -30.h),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          child: Column(
            children: [
              Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(user.name,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                  )),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(user.role.label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
              ),
              if (user.authProvider != null) ...[
                SizedBox(height: 6.h),
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                //   decoration: BoxDecoration(
                //     color: isDark
                //         ? const Color(0xFF334155)
                //         : const Color(0xFFF1F5F9),
                //     borderRadius: BorderRadius.circular(12.r),
                //   ),
                //   child: Text(user.authProvider!,
                //       style: TextStyle(
                //         fontFamily: 'Cairo',
                //         fontSize: 11.sp,
                //         fontWeight: FontWeight.w600,
                //         color: isDark
                //             ? const Color(0xFF94A3B8)
                //             : const Color(0xFF64748B),
                //       )),
                // ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(bool isDark, UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: Text('المعلومات الشخصية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
          ),
          if (_editing)
            Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameCtrl,
                      label: 'الاسم',
                      icon: Icons.person,
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'الحقل مطلوب' : null,
                    ),
                    SizedBox(height: 12.h),
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'رقم الهاتف',
                      icon: Icons.phone,
                      isDark: isDark,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
          if (!_editing) ...[
            _buildInfoTile(
              icon: Icons.person,
              iconColor: const Color(0xFF7C3AED),
              title: 'الاسم',
              value: user.name,
              isDark: isDark,
            ),
            Divider(
                height: 1,
                indent: 60.w,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
          ],
          _buildInfoTile(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF2563EB),
            title: 'البريد الإلكتروني',
            value: user.email,
            isDark: isDark,
          ),
          if (!_editing && user.phone != null && user.phone!.isNotEmpty) ...[
            Divider(
                height: 1,
                indent: 60.w,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
            _buildInfoTile(
              icon: Icons.phone,
              iconColor: const Color(0xFF10B981),
              title: 'رقم الهاتف',
              value: user.phone!,
              isDark: isDark,
            ),
          ],
          if (user.username != null && user.username!.isNotEmpty) ...[
            Divider(
                height: 1,
                indent: 60.w,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
            _buildInfoTile(
              icon: Icons.alternate_email,
              iconColor: const Color(0xFFF59E0B),
              title: 'اسم المستخدم',
              value: user.username!,
              trailing: IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: user.username!));
                  _showSnack('تم نسخ اسم المستخدم');
                },
                icon: Icon(Icons.copy, size: 18,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                splashRadius: 18.r,
              ),
              isDark: isDark,
            ),
          ],
          if (user.subject != null && user.subject!.isNotEmpty) ...[
            Divider(
                height: 1,
                indent: 60.w,
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE5E7EB)),
            _buildInfoTile(
              icon: Icons.school,
              iconColor: const Color(0xFFDB2777),
              title: 'التخصص',
              value: user.subject!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13.sp,
        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 12.sp,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        prefixIcon: Icon(icon,
            size: 18,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
          ),
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Widget? trailing,
    required bool isDark,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 18.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    )),
                SizedBox(height: 2.h),
                Text(value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    )),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildSpecialtiesSection(bool isDark, UserModel user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المواد الدراسية',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
            SizedBox(height: 10.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: user.specialties.map((s) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(s,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection(bool isDark, UserModel user) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('كلمة المرور',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                )),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(user.hasPassword ? Icons.lock : Icons.lock_open,
                    size: 18,
                    color: user.hasPassword
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B)),
                SizedBox(width: 8.w),
                Text(user.hasPassword ? 'كلمة المرور موجودة' : 'لا توجد كلمة مرور',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    )),
              ],
            ),
            if (!user.hasPassword) ...[
              SizedBox(height: 12.h),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13.sp,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'أدخل كلمة المرور الجديدة',
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12.sp,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  prefixIcon: Icon(Icons.lock_outline,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                  filled: true,
                  fillColor:
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _passwordLoading ? null : _addPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: _passwordLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('إضافة كلمة المرور',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          )),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
