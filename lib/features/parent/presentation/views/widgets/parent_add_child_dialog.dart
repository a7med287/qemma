import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/helpers/build_snack_bar.dart';
import '../../../../../core/utils/app_colors.dart';
import '../../../../../core/utils/app_text_styles.dart';
import '../../../../auth/data/services/auth_service.dart';
import '../../../data/repositories/parent_repository.dart';

class ParentAddChildDialog extends StatefulWidget {
  final ParentRepository repo;
  final AuthService authService;
  final String parentEmail;

  const ParentAddChildDialog({
    super.key,
    required this.repo,
    required this.authService,
    required this.parentEmail,
  });

  @override
  State<ParentAddChildDialog> createState() => _ParentAddChildDialogState();
}

class _ParentAddChildDialogState extends State<ParentAddChildDialog> {
  final usernameCtrl = TextEditingController();
  final codeCtrl = TextEditingController();

  bool lookupLoading = false;
  bool codeSent = false;
  bool verifyLoading = false;
  bool linkLoading = false;
  Map<String, dynamic>? foundStudent;
  String? error;

  @override
  void dispose() {
    usernameCtrl.dispose();
    codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookupStudent() async {
    if (usernameCtrl.text.trim().isEmpty) return;
    setState(() {
      lookupLoading = true;
      error = null;
      foundStudent = null;
    });
    try {
      final info = await widget.authService.lookupStudent(
        usernameCtrl.text.trim(),
      );
      if (mounted) setState(() => foundStudent = info);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'لم يتم العثور على طالب بهذا الاسم');
      }
    } finally {
      if (mounted) setState(() => lookupLoading = false);
    }
  }

  Future<void> _sendCode() async {
    setState(() {
      verifyLoading = true;
      error = null;
    });
    try {
      await widget.authService.sendCodeToStudent(
        studentUsername: usernameCtrl.text.trim(),
        parentEmail: widget.parentEmail,
      );
      if (!mounted) return;
      setState(() => codeSent = true);
      buildSnackBar(context, 'تم إرسال الكود للطالب ⚡');
    } catch (_) {
      if (mounted) setState(() => error = 'فشل إرسال الكود');
    } finally {
      if (mounted) setState(() => verifyLoading = false);
    }
  }

  Future<void> _verifyAndLink() async {
    setState(() {
      verifyLoading = true;
      error = null;
    });
    try {
      await widget.authService.verifyParentCode(
        studentUsername: usernameCtrl.text.trim(),
        code: codeCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => linkLoading = true);
      await widget.repo.linkChild(usernameCtrl.text.trim());
      if (!mounted) return;
      buildSnackBar(context, '✅ تم ربط الطالب بنجاح 🎉');
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          verifyLoading = false;
          linkLoading = false;
          error = 'الكود غير صحيح أو انتهت صلاحيتها';
        });
      }
    }
  }

  void _resendCode() {
    setState(() {
      codeSent = false;
      codeCtrl.clear();
    });
  }

  void _onCodeChanged(String v) {
    final digits = v.replaceAll(RegExp(r'\D'), '');
    if (digits != v) {
      codeCtrl.value = codeCtrl.value.copyWith(
        text: digits,
        selection: TextSelection.collapsed(offset: digits.length),
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDB2777), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(
                    Icons.family_restroom,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'إضافة طالب جديد',
                    style: TextStyles.bold18.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            if (!codeSent) ..._buildSearchStep() else ..._buildVerifyStep(),

            if (error != null) ...[
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Colors.red,
                          fontFamily: 'Cairo',
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchStep() {
    return [
      Text(
        'الخطوة 1: ابحث عن الطالب بالاسم المميز',
        style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
      ),
      SizedBox(height: 8.h),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: usernameCtrl,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: 'مثال: std_BraveWolf42',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: context.isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              enabled: !lookupLoading && foundStudent == null,
            ),
          ),
          if (foundStudent == null) ...[
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: lookupLoading ? null : _lookupStudent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: lookupLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'بحث',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ],
      ),
      if (foundStudent != null) ...[
        SizedBox(height: 12.h),
        Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF2F8),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFDB2777)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFDF2F8),
                child: const Icon(Icons.school, color: Color(0xFFDB2777)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      foundStudent!['name'] ?? '',
                      style: TextStyles.semiBold16.copyWith(
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      '@${foundStudent!['username'] ?? ''}',
                      style: TextStyles.regular13.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: Color(0xFF059669)),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          'الخطوة 2: أرسل كود التحقق للطالب',
          style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.all(10.r),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'سيصل للطالب ${foundStudent!['name'] ?? ''} كود مكون من 6 أرقام عبر الإشعارات.',
                  style: TextStyles.regular13.copyWith(
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: verifyLoading ? null : _sendCode,
            icon: verifyLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 18),
            label: const Text(
              'إرسال الكود للطالب ⚡',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildVerifyStep() {
    return [
      Text(
        'الخطوة 3: أدخل الكود الذي أرسله لك الطالب',
        style: TextStyles.semiBold14.copyWith(color: context.textSecondary),
      ),
      SizedBox(height: 8.h),
      Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '✅ تم إرسال الكود للطالب ${foundStudent?['name'] ?? ''}. اطلب منه الكود ثم أدخله هنا.',
                style: TextStyles.regular13.copyWith(
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 12.h),
      TextField(
        controller: codeCtrl,
        keyboardType: TextInputType.number,
        textDirection: TextDirection.ltr,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(letterSpacing: 8, fontSize: 24.sp, fontFamily: 'Cairo'),
        decoration: InputDecoration(
          hintText: '000000',
          filled: true,
          fillColor: context.isDark
              ? const Color(0xFF334155)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          counterText: '',
        ),
        onChanged: _onCodeChanged,
      ),
      SizedBox(height: 12.h),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              (verifyLoading || linkLoading || codeCtrl.text.length != 6)
                  ? null
                  : _verifyAndLink,
          icon: (verifyLoading || linkLoading)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check_circle, size: 18),
          label: Text(
            (verifyLoading || linkLoading) ? 'جاري الربط...' : 'تحقق وربط الطالب ✅',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF059669),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
            disabledBackgroundColor: const Color(0xFF059669).withValues(alpha: .5),
          ),
        ),
      ),
      SizedBox(height: 8.h),
      Center(
        child: TextButton(
          onPressed: _resendCode,
          child: const Text(
            'إعادة إرسال الكود',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ];
  }
}
