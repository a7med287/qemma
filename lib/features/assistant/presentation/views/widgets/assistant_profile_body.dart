import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../auth/data/models/auth_models.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../student/presentation/widgets/student_shared_widgets.dart';

class ProfileHeaderInfo extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditTap;

  const ProfileHeaderInfo({
    super.key,
    required this.user,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
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
                onTap: onEditTap,
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
}

class ProfileInfoCard extends StatelessWidget {
  final UserModel user;
  final bool editing;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final bool showUsername;
  final VoidCallback onCopyUsername;
  final VoidCallback onToggleUsername;

  const ProfileInfoCard({
    super.key,
    required this.user,
    required this.editing,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.showUsername,
    required this.onCopyUsername,
    required this.onToggleUsername,
  });

  @override
  Widget build(BuildContext context) {
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
            control: editing
                ? TextField(
                    controller: nameCtrl,
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
              showUsername ? (user.username ?? '—') : '•' * ((user.username?.length ?? 8).clamp(6, 14)),
              style: TextStyles.semiBold14.copyWith(
                color: const Color(0xFFF59E0B),
                letterSpacing: showUsername ? 0 : 2,
              ),
            ),
            actions: [
              IconButton(
                onPressed: onCopyUsername,
                icon: Icon(Icons.copy_rounded, size: 18.sp, color: context.textSecondary),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onToggleUsername,
                icon: Icon(
                  showUsername ? Icons.visibility_off_rounded : Icons.visibility_rounded,
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
                  control: editing
                      ? TextField(
                          controller: phoneCtrl,
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

class ProfileSpecialtiesCard extends StatelessWidget {
  final UserModel user;

  const ProfileSpecialtiesCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
}

class ProfilePasswordCard extends StatelessWidget {
  final UserModel user;
  final TextEditingController passwordCtrl;
  final bool passwordLoading;
  final VoidCallback onAddPassword;

  const ProfilePasswordCard({
    super.key,
    required this.user,
    required this.passwordCtrl,
    required this.passwordLoading,
    required this.onAddPassword,
  });

  @override
  Widget build(BuildContext context) {
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
            controller: passwordCtrl,
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
              onPressed: passwordLoading ? null : onAddPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gradientMid,
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              child: passwordLoading
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
}

class ProfileActionButtons extends StatelessWidget {
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileActionButtons({
    super.key,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : onCancel,
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
            onPressed: saving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gradientMid,
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            child: saving
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
}
