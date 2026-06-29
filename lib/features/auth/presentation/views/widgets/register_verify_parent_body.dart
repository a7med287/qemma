import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'auth_styles.dart';
import 'register_shared_widgets.dart';

class RegisterVerifyParentBody extends StatelessWidget {
  const RegisterVerifyParentBody({
    super.key,
    required this.studentUsernameCtrl,
    required this.parentCodeCtrl,
    required this.studentInfo,
    required this.parentCodeSent,
    required this.parentLookupLoading,
    required this.parentVerifyLoading,
    required this.parentError,
    required this.onBack,
    required this.onLookupStudent,
    required this.onSendCodeToStudent,
    required this.onVerifyParentCode,
    required this.onResendCode,
    required this.onCodeChanged,
  });

  final TextEditingController studentUsernameCtrl;
  final TextEditingController parentCodeCtrl;
  final Map<String, dynamic>? studentInfo;
  final bool parentCodeSent;
  final bool parentLookupLoading;
  final bool parentVerifyLoading;
  final String? parentError;
  final VoidCallback onBack;
  final VoidCallback onLookupStudent;
  final VoidCallback onSendCodeToStudent;
  final VoidCallback onVerifyParentCode;
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
              controller: studentUsernameCtrl,
              hint: 'std_BraveWolf42',
              textDirection: TextDirection.ltr,
              enabled: !parentLookupLoading && studentInfo == null,
              prefixIcon: Icon(Icons.search_rounded, color: AuthColors.textSecondary(context)),
            ),
          ),
          if (studentInfo == null) ...[
            SizedBox(width: 10.w),
            miniButton(
              label: 'بحث',
              onPressed: onLookupStudent,
              loading: parentLookupLoading,
              color: AuthColors.parentColor,
              context: context,
            ),
          ],
        ]),
        SizedBox(height: 16.h),
        if (studentInfo != null) ...[
          personCard(
            name: studentInfo!['name'] ?? '',
            username: studentInfo!['username'] ?? '',
            label: 'طالب',
            color: AuthColors.parentColor,
            icon: Icons.school_rounded,
            context: context,
          ),
          SizedBox(height: 16.h),
        ],
        if (studentInfo != null && !parentCodeSent) ...[
          Text('الخطوة 2: أرسل كود التحقق للطالب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          infoBox('سيصل للطالب ${studentInfo!['name']} كود مكون من 6 أرقام في الوقت الفعلي عبر الإشعارات.', context: context),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'إرسال الكود للطالب ⚡',
            onPressed: onSendCodeToStudent,
            isLoading: parentVerifyLoading,
            gradient: const LinearGradient(
              colors: [AuthColors.parentColor, AuthColors.teacherColor],
            ),
          ),
          SizedBox(height: 16.h),
        ],
        if (parentCodeSent) ...[
          Text('الخطوة 3: أدخل الكود الذي أرسله لك الطالب',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w700,
                  color: AuthColors.textPrimary(context))),
          SizedBox(height: 10.h),
          AuthAlert(message: '✅ تم إرسال الكود للطالب. اطلب منه الكود ثم أدخله هنا.', type: AlertType.success),
          SizedBox(height: 12.h),
          AuthTextField(
            label: 'كود التحقق (6 أرقام)',
            controller: parentCodeCtrl,
            keyboardType: TextInputType.number,
            textDirection: TextDirection.ltr,
            maxLength: 6,
            hint: '000000',
            onChanged: (v) {
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits != v) parentCodeCtrl.text = digits;
              onCodeChanged(v);
            },
          ),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'تحقق وأكمل التسجيل ✅',
            onPressed: parentCodeCtrl.text.length == 6 ? onVerifyParentCode : null,
            isLoading: parentVerifyLoading,
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
        if (parentError != null) ...[
          SizedBox(height: 8.h),
          AuthAlert(message: parentError!, type: AlertType.error),
        ],
      ],
    );
  }
}
