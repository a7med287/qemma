import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'teacher_theme_helpers.dart';

class TeacherUploadLessonFilePicker extends StatelessWidget {
  const TeacherUploadLessonFilePicker({
    super.key,
    required this.videoFile,
    required this.pdfFile,
    required this.loading,
    required this.uploadProgress,
    required this.onPickVideo,
    required this.onPickPdf,
    required this.onRemoveVideo,
    required this.onRemovePdf,
  });

  final PlatformFile? videoFile;
  final PlatformFile? pdfFile;
  final bool loading;
  final double uploadProgress;
  final VoidCallback onPickVideo;
  final VoidCallback onPickPdf;
  final VoidCallback onRemoveVideo;
  final VoidCallback onRemovePdf;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes Bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: fieldBorderColor(context)),
      ),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionTitle(context, 'الملفات'),
          SizedBox(height: 12.h),
          _buildVideoUpload(context),
          SizedBox(height: 12.h),
          _buildPdfUpload(context),
          if (loading) ...[
            SizedBox(height: 20.h),
            _buildProgressBar(context),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final isDark = context.isDark;
    return Text(title,
        style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w900, fontSize: 16.sp,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)));
  }

  Widget _buildVideoUpload(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(
          color: videoFile != null ? const Color(0xFF8B5CF6) : fieldBorderColor(context),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8.r),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: videoFile == null
          ? _buildUploadPlaceholder(context,
              icon: Icons.video_library,
              title: 'رفع فيديو الدرس',
              subtitle: 'الحد الأقصى: 500 ميجابايت — MP4, AVI, MOV, WMV',
              buttonLabel: 'اختيار فيديو',
              buttonColor: const Color(0xFF8B5CF6),
              onPick: onPickVideo,
            )
          : _buildFileCard(context,
              icon: Icons.video_library,
              iconColor: const Color(0xFF8B5CF6),
              name: videoFile!.name,
              size: videoFile!.size,
              onRemove: onRemoveVideo,
            ),
    );
  }

  Widget _buildPdfUpload(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(
          color: pdfFile != null ? const Color(0xFFDC2626) : fieldBorderColor(context),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8.r),
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      ),
      child: pdfFile == null
          ? _buildUploadPlaceholder(context,
              icon: Icons.picture_as_pdf,
              title: 'رفع ملف PDF (اختياري)',
              subtitle: 'ملاحظات، تمارين، أو مواد إضافية (الحد الأقصى: 50 ميجابايت)',
              buttonLabel: 'اختيار PDF',
              buttonColor: const Color(0xFFDC2626),
              onPick: onPickPdf,
            )
          : _buildFileCard(context,
              icon: Icons.picture_as_pdf,
              iconColor: const Color(0xFFDC2626),
              name: pdfFile!.name,
              size: pdfFile!.size,
              onRemove: onRemovePdf,
            ),
    );
  }

  Widget _buildUploadPlaceholder(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onPick,
  }) {
    final isDark = context.isDark;
    return Column(
      children: [
        Icon(icon, size: 48.sp, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
        SizedBox(height: 8.h),
        Text(title,
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 13.sp,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
        SizedBox(height: 4.h),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280))),
        SizedBox(height: 12.h),
        ElevatedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.cloud_upload, size: 18),
          label: Text(buttonLabel, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String name,
    required int size,
    required VoidCallback onRemove,
  }) {
    final isDark = context.isDark;
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                          color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
                  Text(_formatSize(size),
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF))),
                ],
              ),
            ),
            if (!loading)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final isDark = context.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(uploadProgress < 100 ? 'جاري الرفع...' : 'تم الرفع ✅',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
            Text('${uploadProgress.round()}%',
                style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700, fontSize: 12.sp,
                    color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A))),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: uploadProgress / 100,
            minHeight: 8.h,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }
}
