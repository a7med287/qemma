import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LiveClassChatPanel extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final TextEditingController chatCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onSendMessage;
  final VoidCallback onClose;

  const LiveClassChatPanel({
    super.key,
    required this.messages,
    required this.chatCtrl,
    required this.scrollCtrl,
    required this.onSendMessage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.4.sh,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessagesList()),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          const Icon(Icons.chat, color: Color(0xFF94A3B8), size: 18),
          SizedBox(width: 8.w),
          Text('المحادثة',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 13.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close,
                color: Color(0xFF94A3B8), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (messages.isEmpty) {
      return Center(
        child: Text('لا توجد رسائل بعد',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12.sp,
              color: const Color(0xFF64748B),
            )),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      padding: EdgeInsets.all(8.w),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
        final isTeacher = msg['isTeacher'] == true;
        return Align(
          alignment:
              isTeacher ? Alignment.centerLeft : Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.only(bottom: 6.h),
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            constraints: BoxConstraints(maxWidth: 0.7.sw),
            decoration: BoxDecoration(
              color: isTeacher
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${msg['sender']}: ${msg['message']}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12.sp,
                      color: Colors.white,
                    )),
                if (msg['time'] != null)
                  Text(msg['time'],
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 9.sp,
                        color: const Color(0xFF64748B),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatCtrl,
              onSubmitted: (_) => onSendMessage(),
              style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 8.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: onSendMessage,
            icon: const Icon(Icons.send_rounded,
                color: Color(0xFF7C3AED), size: 22),
          ),
        ],
      ),
    );
  }
}
