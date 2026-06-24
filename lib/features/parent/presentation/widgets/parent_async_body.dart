import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/helpers/build_context_extensions.dart';

class ParentAsyncBody extends StatelessWidget {
  final bool loading;
  final String? error;
  final Widget Function() builder;
  final VoidCallback? onRetry;

  const ParentAsyncBody({
    super.key,
    required this.loading,
    this.error,
    required this.builder,
    this.onRetry,
  });

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
              Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
              SizedBox(height: 16.h),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14.sp,
                  color: context.textSecondary,
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: 16.h),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return builder();
  }
}
