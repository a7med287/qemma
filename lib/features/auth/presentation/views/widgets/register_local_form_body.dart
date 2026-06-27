import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_styles.dart';
import 'register_shared_widgets.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../data/models/auth_models.dart';

List<DropdownMenuItem<String>> _divisionItems(String year) {
  if (year == 'first') {
    return const [
      DropdownMenuItem(value: 'Science-Maths', child: Text('علمي', style: TextStyle(fontFamily: 'Cairo'))),
      DropdownMenuItem(value: 'Literary', child: Text('أدبي', style: TextStyle(fontFamily: 'Cairo'))),
    ];
  }
  return const [
    DropdownMenuItem(value: 'Literary', child: Text('أدبي', style: TextStyle(fontFamily: 'Cairo'))),
    DropdownMenuItem(value: 'Science-Biology', child: Text('علمي علوم', style: TextStyle(fontFamily: 'Cairo'))),
    DropdownMenuItem(value: 'Science-Maths', child: Text('علمي رياضة', style: TextStyle(fontFamily: 'Cairo'))),
  ];
}

class RegisterLocalFormBody extends StatelessWidget {
  const RegisterLocalFormBody({
    super.key,
    required this.nameCtrl,
    required this.emailPrefixCtrl,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.confirmPasswordCtrl,
    required this.role,
    required this.division,
    required this.year,
    required this.subject,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.errors,
    required this.isTeacher,
    required this.onRoleChanged,
    required this.onDivisionChanged,
    required this.onYearChanged,
    required this.onSubjectChanged,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onErrorRemove,
    required this.onSubmit,
    required this.loading,
    required this.onLoginTap,
  });

  final TextEditingController nameCtrl;
  final TextEditingController emailPrefixCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmPasswordCtrl;
  final UserRole role;
  final String? division;
  final String? year;
  final String? subject;
  final bool showPassword;
  final bool showConfirmPassword;
  final Map<String, String?> errors;
  final bool isTeacher;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<String?> onDivisionChanged;
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<String> onErrorRemove;
  final VoidCallback onSubmit;
  final bool loading;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            roleCard(role: UserRole.student, selectedRole: role, label: 'طالب', icon: Icons.school_rounded, onChanged: onRoleChanged, context: context),
            roleCard(role: UserRole.teacher, selectedRole: role, label: 'مدرس', icon: Icons.person_rounded, onChanged: onRoleChanged, context: context),
            roleCard(role: UserRole.assistantTeacher, selectedRole: role, label: 'مدرس مساعد', icon: Icons.supervisor_account_rounded, onChanged: onRoleChanged, context: context),
            roleCard(role: UserRole.parent, selectedRole: role, label: 'ولي أمر', icon: Icons.family_restroom_rounded, onChanged: onRoleChanged, context: context),
          ],
        ),
        SizedBox(height: 16.h),
        infoBox('🎯 سيتم إنشاء اسم مستخدم فريد لك تلقائياً بعد إنشاء الحساب', context: context),
        SizedBox(height: 16.h),
        if (role == UserRole.student) ...[
          dropdownField(
            label: 'الصف الدراسي *',
            value: year,
            error: errors['year'],
            items: studentYearOptions.map((opt) => DropdownMenuItem(
              value: opt.$1,
              child: Text(opt.$2, style: const TextStyle(fontFamily: 'Cairo')),
            )).toList(),
            onChanged: onYearChanged,
            context: context,
          ),
          SizedBox(height: 12.h),
          dropdownField<String>(
            label: 'القسم الدراسي *',
            value: division,
            error: errors['division'],
            items: year != null ? _divisionItems(year!) : <DropdownMenuItem<String>>[],
            onChanged: year != null ? onDivisionChanged : null,
            context: context,
          ),
          SizedBox(height: 12.h),
        ],
        if (isTeacher) ...[
          dropdownField(
            label: 'المادة الدراسية *',
            value: subject,
            error: errors['subject'],
            items: subjects.map((s) => DropdownMenuItem(value: s,
                child: Text(s, style: const TextStyle(fontFamily: 'Cairo')))).toList(),
            onChanged: onSubjectChanged,
            context: context,
          ),
          SizedBox(height: 12.h),
        ],
        if (role == UserRole.assistantTeacher) ...[
          infoBox('⚡ بعد ملء البيانات ستحتاج للتحقق من هوية المدرس عبر كود OTP', context: context),
          SizedBox(height: 12.h),
        ],
        if (role == UserRole.parent) ...[
          infoBox('⚡ بعد ملء البيانات ستحتاج للتحقق عبر الطالب عبر كود OTP', context: context),
          SizedBox(height: 12.h),
        ],
        AuthTextField(
          label: 'الاسم الكامل',
          controller: nameCtrl,
          prefixIcon: Icon(Icons.person_outline_rounded, color: AuthColors.textSecondary(context)),
          errorText: errors['name'],
          onChanged: (_) => onErrorRemove('name'),
        ),
        SizedBox(height: 12.h),
        emailField(controller: emailPrefixCtrl, errorText: errors['email'], onChanged: (_) => onErrorRemove('email'), context: context),
        SizedBox(height: 12.h),
        AuthTextField(
          label: 'رقم الهاتف *',
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          hint: '01012345678',
          prefixIcon: Icon(Icons.phone_outlined, color: AuthColors.textSecondary(context)),
          errorText: errors['phone'],
          textDirection: TextDirection.ltr,
          onChanged: (_) => onErrorRemove('phone'),
        ),
        SizedBox(height: 12.h),
        AuthTextField(
          label: 'كلمة المرور',
          controller: passwordCtrl,
          obscureText: !showPassword,
          prefixIcon: Icon(Icons.lock_outline_rounded, color: AuthColors.textSecondary(context)),
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AuthColors.textSecondary(context)),
          ),
          errorText: errors['password'],
          onChanged: (_) => onErrorRemove('password'),
        ),
        SizedBox(height: 12.h),
        AuthTextField(
          label: 'تأكيد كلمة المرور',
          controller: confirmPasswordCtrl,
          obscureText: !showConfirmPassword,
          prefixIcon: Icon(Icons.lock_outline_rounded, color: AuthColors.textSecondary(context)),
          suffixIcon: IconButton(
            onPressed: onToggleConfirmPassword,
            icon: Icon(showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AuthColors.textSecondary(context)),
          ),
          errorText: errors['confirmPassword'],
          onChanged: (_) => onErrorRemove('confirmPassword'),
        ),
        SizedBox(height: 24.h),
        GradientButton(
          text: switch (role) {
            UserRole.assistantTeacher => 'التالي: التحقق من المدرس →',
            UserRole.parent           => 'التالي: التحقق من الطالب →',
            _                        => 'إنشاء حساب',
          },
          onPressed: onSubmit,
          isLoading: loading,
        ),
        SizedBox(height: 20.h),
        Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('لديك حساب بالفعل؟  ',
              style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context), fontSize: 13)),
          GestureDetector(
            onTap: onLoginTap,
            child: const Text('سجل الدخول',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13,
                    fontWeight: FontWeight.w700, color: AuthColors.gradientStart)),
          ),
        ])),
        SizedBox(height: 16.h),
      ],
    );
  }
}
