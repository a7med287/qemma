import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/utils/app_text_styles.dart';

class StudentAsyncBody extends StatelessWidget {
  const StudentAsyncBody({
    super.key,
    required this.loading,
    this.error,
    this.onRetry,
    required this.child,
  });

  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 48.sp, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(error!, textAlign: TextAlign.center, style: TextStyles.regular14),
              if (onRetry != null) ...[
                SizedBox(height: 16.h),
                ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
              ],
            ],
          ),
        ),
      );
    }
    return child;
  }
}
