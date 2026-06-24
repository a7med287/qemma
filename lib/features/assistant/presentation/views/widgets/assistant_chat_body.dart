import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/helpers/build_context_extensions.dart';
import '../../../../../core/utils/app_text_styles.dart';

class ChatFilters extends StatelessWidget {
  final bool isDark;
  final Color fieldBorder;
  final Color fieldLabel;
  final Color fieldText;
  final Color cardBg;
  final String selectedCourse;
  final ValueChanged<String> onCourseChanged;
  final List<Map<String, dynamic>> courses;
  final TextEditingController searchController;
  final VoidCallback onSearchChanged;

  const ChatFilters({
    super.key,
    required this.isDark,
    required this.fieldBorder,
    required this.fieldLabel,
    required this.fieldText,
    required this.cardBg,
    required this.selectedCourse,
    required this.onCourseChanged,
    required this.courses,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: fieldBorder)),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r), border: Border.all(color: fieldBorder),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCourse.isNotEmpty ? selectedCourse : null,
                isExpanded: true,
                hint: Text('تصفية بالكورس', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: fieldLabel.withValues(alpha: .5))),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: fieldText),
                items: [
                  DropdownMenuItem(value: '', child: Text('كل الكورسات', style: TextStyle(color: fieldLabel))),
                  ...courses.map((c) {
                    final id = (c['id'] ?? c['_id'] ?? '') as String;
                    final title = (c['title'] ?? '') as String;
                    return DropdownMenuItem(value: id, child: Text(title));
                  }),
                ],
                onChanged: (v) => onCourseChanged(v ?? ''),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: searchController,
            onChanged: (_) => onSearchChanged(),
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: fieldText),
            decoration: InputDecoration(
              hintText: 'ابحث عن طالب بالاسم...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldLabel.withValues(alpha: .5)),
              prefixIcon: Icon(Icons.search, size: 20, color: fieldLabel),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: fieldBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: fieldBorder)),
              contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatStudentList extends StatelessWidget {
  final bool isDark;
  final Color fieldBorder;
  final Color fieldLabel;
  final Color cardBg;
  final List<Map<String, dynamic>> sessions;
  final String selectedCourse;
  final List<Map<String, dynamic>> filteredStudents;
  final void Function(Map<String, dynamic> session) onSessionTap;
  final void Function(Map<String, dynamic> student) onStudentTap;

  const ChatStudentList({
    super.key,
    required this.isDark,
    required this.fieldBorder,
    required this.fieldLabel,
    required this.cardBg,
    required this.sessions,
    required this.selectedCourse,
    required this.filteredStudents,
    required this.onSessionTap,
    required this.onStudentTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasSession = sessions.where((s) {
      final cId = (s['courseId'] ?? '') as String;
      return selectedCourse.isEmpty || cId == selectedCourse;
    }).toList();

    if (hasSession.isNotEmpty) {
      return Column(
        children: [
          _sectionTitle('المحادثات النشطة', isDark),
          SizedBox(height: 8.h),
          ...hasSession.map((s) => _SessionRow(
            session: s, isDark: isDark, fieldBorder: fieldBorder, fieldLabel: fieldLabel, cardBg: cardBg,
            onTap: () => onSessionTap(s),
          )),
          SizedBox(height: 16.h),
        ],
      );
    }

    if (filteredStudents.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد محادثات بعد', style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldLabel)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _sectionTitle('جميع الطلاب', isDark),
        SizedBox(height: 8.h),
        ...filteredStudents.map((s) => _StudentRow(
          student: s, isDark: isDark, fieldBorder: fieldBorder, cardBg: cardBg,
          onTap: () => onStudentTap(s),
        )),
      ],
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(title, style: TextStyles.semiBold14.copyWith(color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final Map<String, dynamic> student;
  final bool isDark;
  final Color fieldBorder;
  final Color cardBg;
  final VoidCallback onTap;

  const _StudentRow({
    required this.student,
    required this.isDark,
    required this.fieldBorder,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = (student['name'] ?? 'طالب') as String;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: fieldBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFF059669),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo',
                        color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text('فتح محادثة',
                    style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: const Color(0xFF059669))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final Map<String, dynamic> session;
  final bool isDark;
  final Color fieldBorder;
  final Color fieldLabel;
  final Color cardBg;
  final VoidCallback onTap;

  const _SessionRow({
    required this.session,
    required this.isDark,
    required this.fieldBorder,
    required this.fieldLabel,
    required this.cardBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final student = (session['student'] as Map<String, dynamic>?) ?? {};
    final name = (student['name'] ?? 'طالب') as String;
    final lastMessage = session['lastMessage'] as Map?;
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12.r), border: Border.all(color: fieldBorder)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFF059669),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp, fontFamily: 'Cairo',
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B))),
                    if (lastMessage != null)
                      Text('${lastMessage['message'] ?? ''}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.sp, fontFamily: 'Cairo', color: fieldLabel)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, size: 20, color: fieldLabel),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatMessageList extends StatelessWidget {
  final bool isDark;
  final Color fieldLabel;
  final ScrollController scrollController;
  final List<Map<String, dynamic>> messages;
  final bool Function(Map<String, dynamic>) isFromTeacher;
  final bool Function(Map<String, dynamic>) isFromAssistant;
  final String Function(Map<String, dynamic>) getSenderLabel;

  const ChatMessageList({
    super.key,
    required this.isDark,
    required this.fieldLabel,
    required this.scrollController,
    required this.messages,
    required this.isFromTeacher,
    required this.isFromAssistant,
    required this.getSenderLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
            SizedBox(height: 12.h),
            Text('لا توجد رسائل بعد، أرسل أول رسالة',
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: fieldLabel)),
          ],
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.all(16.w),
      itemCount: messages.length,
      itemBuilder: (_, i) => _MessageBubble(
        msg: messages[i],
        isDark: isDark,
        isFromTeacher: isFromTeacher(messages[i]),
        isFromAssistant: isFromAssistant(messages[i]),
        getSenderLabel: getSenderLabel(messages[i]),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isDark;
  final bool isFromTeacher;
  final bool isFromAssistant;
  final String getSenderLabel;

  const _MessageBubble({
    required this.msg,
    required this.isDark,
    required this.isFromTeacher,
    required this.isFromAssistant,
    required this.getSenderLabel,
  });

  @override
  Widget build(BuildContext context) {
    final text = (msg['message'] ?? msg['text'] ?? '') as String;
    final isMine = isFromAssistant || msg['isAssistant'] == true;
    final createdAt = msg['createdAt'] as String?;
    final time = createdAt != null && createdAt.length >= 16 ? createdAt.substring(11, 16) : '';
    final senderLabel = getSenderLabel;
    final fieldLabel = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);

    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 0.8.sw),
        decoration: BoxDecoration(
          color: isMine
              ? (context.isDark ? const Color(0xFF059669).withValues(alpha: .3) : const Color(0xFF059669).withValues(alpha: .1))
              : (context.isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10),
            bottomLeft: isMine ? const Radius.circular(4) : const Radius.circular(10),
            bottomRight: isMine ? const Radius.circular(10) : const Radius.circular(4),
          ),
          border: Border.all(color: context.isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFromTeacher || isFromAssistant)
              Padding(
                padding: EdgeInsets.only(bottom: 2.h),
                child: Text(senderLabel,
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo', color: isFromTeacher ? const Color(0xFF7C3AED) : const Color(0xFF059669))),
              ),
            Text(text,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp,
                    color: context.isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937))),
            if (time.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(time, style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp,
                      color: fieldLabel.withValues(alpha: .8), fontWeight: FontWeight.w500)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatInputBar extends StatelessWidget {
  final bool isDark;
  final Color fieldBorder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;

  const ChatInputBar({
    super.key,
    required this.isDark,
    required this.fieldBorder,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(top: BorderSide(color: fieldBorder)),
      ),
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 12.h),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1F2937)),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)).withValues(alpha: .5)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide(color: fieldBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide(color: fieldBorder)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 44.w, height: 44.w,
              decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
              child: IconButton(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? SizedBox(width: 20.w, height: 20.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
