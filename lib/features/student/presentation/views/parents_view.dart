import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../../../features/explore/presentation/views/checkout_page.dart';
import '../../data/models/student_models.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_shared_widgets.dart';

class ParentsView extends StatefulWidget {
  const ParentsView({super.key});

  @override
  State<ParentsView> createState() => _ParentsViewState();
}

class _ParentsViewState extends State<ParentsView> {
  List<StudentParentItem> _parents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = context.read<StudentRepository>();
      final list = await repo.getParents();
      if (!mounted) return;
      setState(() { _parents = list; _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDB2777), Color(0xFFBE185D), Color(0xFF9D174D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(top: 48.h, bottom: 20.h),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      StudentBackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Container(
                        width: 56.w, height: 56.w,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.family_restroom_rounded, size: 32.sp, color: Colors.white),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إدارة أولياء الأمور',
                              style: TextStyles.bold20.copyWith(color: Colors.white)),
                          SizedBox(height: 2.h),
                          Text('قم بتفعيل ولي الأمر المرتبط بحسابك',
                              style: TextStyles.regular13.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────────
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 12.h),
            Text('جاري تحميل أولياء الأمور...',
                style: TextStyles.regular14.copyWith(color: context.textSecondary)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8.w),
              Expanded(child: Text(_error!, style: TextStyles.regular13.copyWith(color: Colors.red))),
            ],
          ),
        ),
      );
    }

    if (_parents.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.family_restroom_rounded, size: 80.sp,
                  color: context.isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              SizedBox(height: 16.h),
              Text('لا يوجد أولياء أمور مرتبطون بعد',
                  style: TextStyles.semiBold18.copyWith(color: context.textPrimary),
                  textAlign: TextAlign.center),
              SizedBox(height: 8.h),
              Text(
                'عندما يقوم ولي أمر بالتسجيل وربط حسابه بحسابك، سيظهر هنا لتتمكن من تفعيله',
                style: TextStyles.regular14.copyWith(color: context.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          ..._parents.map((parent) => _buildParentCard(parent)),
          SizedBox(height: 16.h),
          _buildInfoCard(),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildParentCard(StudentParentItem parent) {
    final initial = parent.name.isNotEmpty ? parent.name[0] : 'و';
    final activated = parent.isActivated;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: activated ? const Color(0xFF059669) : context.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              gradient: LinearGradient(
                colors: activated
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 28.r,
                      child: Text(initial,
                          style: TextStyles.bold18.copyWith(color: Colors.white)),
                    ),
                    SizedBox(width: 12.w),
                    // Name + username + status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(parent.name, style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                          if (parent.username != null && parent.username!.isNotEmpty)
                            Text('@${parent.username}',
                                style: TextStyles.regular13.copyWith(color: const Color(0xFFDB2777))),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: activated
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  activated ? Icons.check_circle : Icons.cancel,
                                  size: 14.sp,
                                  color: activated ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  activated ? 'مفعل' : 'غير مفعل',
                                  style: TextStyles.regular13.copyWith(
                                    color: activated ? const Color(0xFF059669) : const Color(0xFFEF4444),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Email + date row
                Row(
                  children: [
                    Icon(Icons.email_outlined, size: 16.sp, color: context.textSecondary),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(parent.email,
                          style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ),
                  ],
                ),
                if (parent.linkedAt != null) ...[
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 16.sp, color: context.textSecondary),
                      SizedBox(width: 6.w),
                      Text(_formatDate(parent.linkedAt),
                          style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                    ],
                  ),
                ],
                SizedBox(height: 12.h),
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: activated
                      ? Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text('✅ مفعل',
                              textAlign: TextAlign.center,
                              style: TextStyles.semiBold14.copyWith(color: const Color(0xFF059669))),
                        )
                      : ElevatedButton(
                          onPressed: () => _handleActivate(parent),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r)),
                            backgroundColor: const Color(0xFFDB2777),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.credit_card, size: 18.sp),
                              SizedBox(width: 6.w),
                              Text('تفعيل - 500 جنيه',
                                  style: TextStyles.semiBold14.copyWith(color: Colors.white)),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleActivate(StudentParentItem parent) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          itemId: parent.id,
          itemType: 'parent_activation',
          itemTitle: 'تفعيل ولي الأمر: ${parent.name}',
          itemPrice: 500,
          itemColor: const Color(0xFFDB2777),
          itemGradient: const [Color(0xFFDB2777), Color(0xFFBE185D), Color(0xFF9D174D)],
        ),
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_rounded, size: 28.sp, color: const Color(0xFFDB2777)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🔒 معلومات التفعيل',
                    style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                SizedBox(height: 8.h),
                Text(
                  '• ولي الأمر لا يملك أي صلاحية لمشاهدة بياناتك حتى يتم تفعيله من قبلك.\n'
                  '• تكلفة التفعيل 500 جنيه مصري تُدفع مرة واحدة لكل ولي أمر.\n'
                  '• الدفع يتم عبر بطاقة ائتمان / خصم فقط (Visa, MasterCard).\n'
                  '• بعد الدفع، يتم تفعيل ولي الأمر فوراً ويحصل على صلاحية متابعة بياناتك.',
                  style: TextStyles.regular13.copyWith(color: context.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
