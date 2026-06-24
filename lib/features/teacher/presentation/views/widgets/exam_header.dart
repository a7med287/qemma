import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExamHeader extends StatelessWidget {
  const ExamHeader({
    super.key,
    required this.activeStep,
    required this.stepLabels,
    required this.onBack,
  });

  final int activeStep;
  final List<String> stepLabels;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFFDB2777)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white12),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFDB2777)],
                  ),
                ),
                child:
                const Icon(Icons.assignment, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إنشاء اختبار جديد',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 20.sp,
                        color: Colors.white,
                      )),
                  Text('أنشئ اختبار تقييمي لطلابك',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13.sp,
                        color: Colors.white70,
                      )),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildStepper(context),
        ],
      ),
    );
  }

  Widget _buildStepper(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: List.generate(stepLabels.length, (i) {
          final isActive = i == activeStep;
          final isDone = i < activeStep;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone || isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone || isActive
                            ? Colors.white
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone || isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check,
                            size: 16.sp,
                            color: const Color(0xFF2563EB))
                            : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                            color: isActive
                                ? const Color(0xFF2563EB)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      stepLabels[i],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 10.sp,
                        color: isDone || isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
