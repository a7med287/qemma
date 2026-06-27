import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/utils/app_text_styles.dart';
import 'teacher_theme_helpers.dart';

class LiveClassCreatedScreen extends StatefulWidget {
  final Map<String, dynamic>? createdRoom;
  final Future<void> Function() onStartLive;
  final VoidCallback onCancelRoom;
  final void Function(String text, String label) onCopyToClipboard;
  final bool isDark;

  const LiveClassCreatedScreen({
    super.key,
    required this.createdRoom,
    required this.onStartLive,
    required this.onCancelRoom,
    required this.onCopyToClipboard,
    this.isDark = false,
  });

  @override
  State<LiveClassCreatedScreen> createState() => _LiveClassCreatedScreenState();
}

class _LiveClassCreatedScreenState extends State<LiveClassCreatedScreen> {
  bool _starting = false;

  Future<void> _handleStartLive() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      await widget.onStartLive();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomCode = (widget.createdRoom?['roomCode'] ??
        widget.createdRoom?['code'] ??
        widget.createdRoom?['id'] ??
        '') as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSuccessCard(context, roomCode),
        SizedBox(height: 16.h),
        _buildDetailsCard(context),
        SizedBox(height: 24.h),
        _buildButtons(context),
      ],
    );
  }

  Widget _buildSuccessCard(BuildContext context, String roomCode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Icon(Icons.check_circle,
                color: Colors.white, size: 36),
          ),
          SizedBox(height: 12.h),
          Text('تم إنشاء الحصة بنجاح!',
              style: TextStyles.bold18.copyWith(color: Colors.white)),
          SizedBox(height: 8.h),
          Text('يمكنك الآن بدء الحصة أو مشاركة الكود مع الطلاب',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: Colors.white70,
              )),
          SizedBox(height: 16.h),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text('كود الحصة: $roomCode',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                )),
          ),
          SizedBox(height: 8.h),
          TextButton.icon(
            onPressed: () =>
                widget.onCopyToClipboard(roomCode, 'كود الحصة'),
            icon:
                const Icon(Icons.copy, color: Colors.white70, size: 16),
            label: Text('نسخ الكود',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: Colors.white70,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الحصة',
              style: TextStyles.semiBold16
                  .copyWith(color: fieldTextColor(context))),
          SizedBox(height: 8.h),
          _detailRow(context, 'العنوان',
              (widget.createdRoom?['title'] ?? '') as String),
          _detailRow(context, 'الحالة', 'بانتظار البدء'),
        ],
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: fieldLabelColor(context),
              )),
          Text(value,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: fieldTextColor(context),
              )),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton.icon(
              onPressed: _starting ? null : _handleStartLive,
              icon: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(_starting ? 'جاري البدء...' : 'بدء الحصة الآن',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: OutlinedButton.icon(
              onPressed: _starting ? null : widget.onCancelRoom,
              icon: const Icon(Icons.close,
                  color: Color(0xFFEF4444)),
              label: Text('إلغاء الحصة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                  )),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
