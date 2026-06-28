import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/helpers/build_context_extensions.dart';
import '../../../../core/utils/app_text_styles.dart';
import '../../data/models/student_model_json.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_shared_widgets.dart';
import 'live_class_room_panel.dart';

class LiveClassView extends StatefulWidget {
  const LiveClassView({super.key});

  @override
  State<LiveClassView> createState() => _LiveClassViewState();
}

class _LiveClassViewState extends State<LiveClassView> {
  final _codeController = TextEditingController();
  bool _inRoom = false;
  bool _loading = false;
  String? _error;
  LiveRoomInfo? _room;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinByCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      // Step 1: join by code → get room name
      final joined = await context.read<StudentRepository>().joinLiveByCode(code);
      if (!mounted) return;
      // Step 2: fetch full room data (includes isActive, endedAt, etc.)
      final room = await context.read<StudentRepository>().getLiveRoom(joined.roomName);
      if (!mounted) return;
      _room = room;
      setState(() { _loading = false; });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _enterRoom() {
    setState(() => _inRoom = true);
  }

  void _leaveRoom() {
    setState(() { _inRoom = false; _room = null; });
  }

  @override
  Widget build(BuildContext context) {
    if (_inRoom && _room != null) {
      return LiveClassRoomPanel(
        roomName: _room!.roomName,
        title: _room!.title,
        teacherName: _room!.teacherName,
        courseTitle: _room!.courseTitle,
        isActive: _room!.isActive,
        participants: _room!.participants,
        onLeave: _leaveRoom,
      );
    }

    if (_room != null) {
      return _buildRoomInfo(context);
    }

    return _buildJoinScreen(context);
  }

  // ── Join by Code Screen ────────────────────────────────────────
  Widget _buildJoinScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDB2777), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(top: 48.h, bottom: 32.h),
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
                SizedBox(height: 16.h),
                const Text('🎥 الحصص المباشرة',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')),
                SizedBox(height: 8.h),
                Text('أدخل كود الانضمام للدخول إلى الحصة',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontFamily: 'Cairo')),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64.w, height: 64.w,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(Icons.play_circle_filled_rounded, size: 32.sp, color: Colors.white),
                        ),
                        SizedBox(height: 16.h),
                        Text('الانضمام لحصة مباشرة',
                            style: TextStyles.semiBold18.copyWith(color: context.textPrimary)),
                        SizedBox(height: 4.h),
                        Text('استخدم الكود الذي شاركه معك المدرس',
                            style: TextStyles.regular13.copyWith(color: context.textSecondary)),
                        SizedBox(height: 20.h),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: TextField(
                            controller: _codeController,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              fontFamily: 'Cairo', fontWeight: FontWeight.w700,
                              fontSize: 18.sp, letterSpacing: 6,
                              color: context.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'A1B2C3',
                              hintStyle: TextStyle(color: context.textSecondary.withValues(alpha: 0.5)),
                              labelText: 'كود الانضمام',
                              labelStyle: TextStyle(fontFamily: 'Cairo', color: context.textSecondary),
                              filled: true,
                              fillColor: context.isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                            ),
                            onChanged: (v) => _codeController.value = TextEditingValue(
                              text: v.toUpperCase(),
                              selection: TextSelection.collapsed(offset: v.length),
                            ),
                            onSubmitted: (_) => _joinByCode(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _joinByCode,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: _loading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_filled_rounded, size: 20),
                                      SizedBox(width: 8.w),
                                      Text('انضم',
                                          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp)),
                                    ],
                                  ),
                          ),
                        ),
                        if (_error != null) ...[
                          SizedBox(height: 12.h),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                                SizedBox(width: 8.w),
                                Expanded(child: Text(_error!,
                                    style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.red))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Room Info Screen ──────────────────────────────────────────
  Widget _buildRoomInfo(BuildContext context) {
    final isLive = _room!.isActive;
    return Scaffold(
      backgroundColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLive
                    ? [const Color(0xFF2563EB), const Color(0xFF7C3AED)]
                    : [const Color(0xFF64748B), const Color(0xFF475569)],
              ),
            ),
            padding: EdgeInsets.only(top: 48.h, bottom: 40.h),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      StudentBackButton(
                        onPressed: () => setState(() { _room = null; _error = null; }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: 80.w, height: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_circle_filled_rounded, size: 48.sp, color: Colors.white),
                ),
                SizedBox(height: 16.h),
                Text(_room!.title, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')),
                if (_room!.courseTitle.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text('📚 ${_room!.courseTitle}',
                      style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.9), fontFamily: 'Cairo')),
                ],
                SizedBox(height: 4.h),
                Text('👨‍🏫 ${_room!.teacherName}',
                    style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.8), fontFamily: 'Cairo')),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: SizedBox(
                    width: double.infinity,
                    child: isLive
                        ? ElevatedButton(
                            onPressed: _enterRoom,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_circle_filled_rounded, size: 22),
                                SizedBox(width: 8.w),
                                Text('🚀 انضم الآن',
                                    style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp)),
                              ],
                            ),
                          )
                        : OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                              foregroundColor: Colors.white.withValues(alpha: 0.6),
                            ),
                            child: Text('✅ انتهت الحصة',
                                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp)),
                          ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: context.borderColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📋 معلومات الحصة',
                        style: TextStyles.semiBold16.copyWith(color: context.textPrimary)),
                    SizedBox(height: 12.h),
                    if (_room!.courseTitle.isNotEmpty) ...[
                      _infoRow(Icons.school_rounded, '${_room!.courseTitle}', context),
                      SizedBox(height: 8.h),
                    ],
                    _infoRow(Icons.people_rounded, '${_room!.participants} مشارك', context),
                    SizedBox(height: 8.h),
                    _infoRow(
                      isLive ? Icons.circle : Icons.circle_outlined,
                      isLive ? 'الحصة نشطة الآن' : 'انتهت الحصة',
                      context,
                      valueColor: isLive ? const Color(0xFF059669) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, BuildContext context, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18.sp,
            color: valueColor ?? context.textSecondary),
        SizedBox(width: 8.w),
        Text(text, style: TextStyle(
          fontFamily: 'Cairo', fontSize: 13.sp,
          color: valueColor ?? context.textSecondary,
          fontWeight: valueColor != null ? FontWeight.w600 : null,
        )),
      ],
    );
  }
}
