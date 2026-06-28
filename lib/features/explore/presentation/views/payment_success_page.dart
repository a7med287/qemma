import 'package:flutter/material.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../explore_colors.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String itemTitle;
  final double total;
  final String orderId;
  final Color itemColor;

  const PaymentSuccessPage({
    super.key,
    required this.itemTitle,
    required this.total,
    required this.orderId,
    required this.itemColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: ExploreColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 60, color: ExploreColors.success),
              ),
              const SizedBox(height: 24),
              const Text('تم بنجاح!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
              const SizedBox(height: 8),
              Text('تم شراء $itemTitle بنجاح', style: TextStyle(fontSize: 16, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    _detailRow('رقم الطلب', orderId, isDark),
                    const SizedBox(height: 12),
                    _detailRow('المبلغ', '${total.toInt()} جنيه', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/student/home', (route) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: itemColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  child: const Text('العودة للرئيسية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontFamily: 'Cairo', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
      ],
    );
  }
}
