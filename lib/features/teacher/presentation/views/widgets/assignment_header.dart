import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';

class AssignmentHeader extends StatelessWidget {
  const AssignmentHeader({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  final int currentTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(8.w, 8.h, 16.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style:
                      IconButton.styleFrom(backgroundColor: Colors.white12),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                        color: Colors.white24,
                      ),
                      child: const Icon(Icons.assignment,
                          color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إدارة الواجبات',
                            style: TextStyles.bold20
                                .copyWith(color: Colors.white)),
                        Text('إنشاء واجبات جديدة ومتابعة تسليمات الطلاب',
                            style: TextStyles.regular13
                                .copyWith(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                _tabButton(0, Icons.add_task, 'إنشاء واجب', context),
                _tabButton(1, Icons.visibility, 'عرض الواجبات', context),
              ],
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String label, BuildContext context) {
    final active = currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: active
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: active ? Colors.white : Colors.white70),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: active ? Colors.white : Colors.white70,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
