import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_styles.dart';
import 'register_shared_widgets.dart';

class RegisterVerifyAssistantBody extends StatelessWidget {
  const RegisterVerifyAssistantBody({
    super.key,
    required this.teacherUsernameCtrl,
    required this.teacherCodeCtrl,
    required this.teacherInfo,
    required this.teacherCodeSent,
    required this.teacherLookupLoading,
    required this.teacherVerifyLoading,
    required this.teacherError,
    required this.onBack,
    required this.onLookupTeacher,
    required this.onSendCodeToTeacher,
    required this.onVerifyTeacherCode,
    required this.onResendCode,
    required this.onCodeChanged,
  });

  final TextEditingController teacherUsernameCtrl;
  final TextEditingController teacherCodeCtrl;
  final Map<String, dynamic>? teacherInfo;
  final bool teacherCodeSent;
  final bool teacherLookupLoading;
  final bool teacherVerifyLoading;
  final String? teacherError;
  final VoidCallback onBack;
  final VoidCallback onLookupTeacher;
  final VoidCallback onSendCodeToTeacher;
  final VoidCallback onVerifyTeacherCode;
  final VoidCallback onResendCode;
  final ValueChanged<String> onCodeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
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
        Text('الخطوة 1: ابحث عن المدرس بالاسم المميز',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary(context))),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(
            child: AuthTextField(
              label: 'اسم المستخدم',
              controller: teacherUsernameCtrl,
              hint: 'tch_SwiftEagle42',
              textDirection: TextDirection.ltr,
              enabled: !teacherLookupLoading && teacherInfo == null,
              prefixIcon: Icon(Icons.search_rounded, color: AuthColors.textSecondary(context)),
            ),
          ),
          if (teacherInfo == null) ...[
            SizedBox(width: 10.w),
            miniButton(
              label: 'بحث',
              onPressed: onLookupTeacher,
              loading: teacherLookupLoading,
              color: AuthColors.teacherColor,
              context: context,
            ),
          ],
        ]),
        SizedBox(height: 16.h),
        if (teacherInfo != null) ...[
          personCard(
            name: teacherInfo!['name'] ?? '',
            username: teacherInfo!['username'] ?? '',
            label: 'مدرس',
            color: AuthColors.teacherColor,
            icon: Icons.person_rounded,
            context: context,
          ),
          SizedBox(height: 16.h),
        ],
        if (teacherInfo != null && !teacherCodeSent) ...[
          Text('الخطوة 2: أرسل كود التحقق للمدرس',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          infoBox('سيصل للمدرس ${teacherInfo!['name']} كود مكون من 6 أرقام في الوقت الفعلي عبر الإشعارات.', context: context),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'إرسال الكود للمدرس ⚡',
            onPressed: onSendCodeToTeacher,
            isLoading: teacherVerifyLoading,
            gradient: const LinearGradient(
              colors: [AuthColors.teacherColor, AuthColors.gradientStart],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        if (teacherCodeSent) ...[
          Text('الخطوة 3: أدخل الكود الذي أرسله لك المدرس',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          AuthAlert(message: '✅ تم إرسال الكود للمدرس. اطلب منه الكود ثم أدخله هنا.', type: AlertType.success),
          SizedBox(height: 12.h),
          AuthTextField(
            label: 'كود التحقق (6 أرقام)',
            controller: teacherCodeCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            maxLength: 6,
            hint: '000000',
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits != v) teacherCodeCtrl.text = digits;
              onCodeChanged(v);
            },
          ),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'تحقق وأكمل التسجيل ✅',
            onPressed: teacherCodeCtrl.text.length == 6 ? onVerifyTeacherCode : null,
            isLoading: teacherVerifyLoading,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
            ),
          ),
          SizedBox(height: 8.h),
          Center(
            child: TextButton(
              onPressed: onResendCode,
              child: Text('إعادة إرسال الكود',
                  style: TextStyle(fontFamily: 'Cairo', color: AuthColors.textSecondary(context))),
            ),
          ),
        ],
        if (teacherError != null) ...[
          SizedBox(height: 8.h),
          AuthAlert(message: teacherError!, type: AlertType.error),
        ],
      ],
    );
  }
}
