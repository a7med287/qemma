import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'live_class_chat_panel.dart';

class LiveClassLiveScreen extends StatelessWidget {
  final int duration;
  final String Function(int) formatDuration;
  final List<Map<String, dynamic>> raiseHands;
  final List<Map<String, dynamic>> participants;
  final Map<String, RTCVideoRenderer> remoteRenderers;
  final RTCVideoRenderer localRenderer;
  final MediaStream? localStream;
  final bool micOn;
  final bool camOn;
  final bool screenShareOn;
  final bool chatOpen;
  final int chatUnread;
  final List<Map<String, dynamic>> messages;
  final TextEditingController chatCtrl;
  final ScrollController scrollCtrl;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCam;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleChat;
  final VoidCallback onShowParticipantsDialog;
  final VoidCallback onShowRaiseHandsDialog;
  final VoidCallback onShowEndConfirmDialog;
  final VoidCallback onCloseChat;

  const LiveClassLiveScreen({
    super.key,
    required this.duration,
    required this.formatDuration,
    required this.raiseHands,
    required this.participants,
    required this.remoteRenderers,
    required this.localRenderer,
    this.localStream,
    required this.micOn,
    required this.camOn,
    required this.screenShareOn,
    required this.chatOpen,
    required this.chatUnread,
    required this.messages,
    required this.chatCtrl,
    required this.scrollCtrl,
    required this.onToggleMic,
    required this.onToggleCam,
    required this.onToggleScreenShare,
    required this.onSendMessage,
    required this.onToggleChat,
    required this.onShowParticipantsDialog,
    required this.onShowRaiseHandsDialog,
    required this.onShowEndConfirmDialog,
    required this.onCloseChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildLiveAppBar(),
            Expanded(child: _buildVideoGrid()),
            _buildControlBar(),
            if (chatOpen)
              Flexible(
                  child: LiveClassChatPanel(
                messages: messages,
                chatCtrl: chatCtrl,
                scrollCtrl: scrollCtrl,
                onSendMessage: onSendMessage,
                onClose: onCloseChat,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveAppBar() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record,
              color: Colors.red, size: 12),
          SizedBox(width: 8.w),
          Text('مباشر',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 12.sp,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(width: 12.w),
          Text(formatDuration(duration),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          if (raiseHands.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: IconButton(
                onPressed: onShowRaiseHandsDialog,
                icon: Badge(
                  label: Text('${raiseHands.length}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white)),
                  child: const Icon(Icons.pan_tool,
                      color: Color(0xFFF59E0B), size: 22),
                ),
              ),
            ),
          IconButton(
            onPressed: onShowEndConfirmDialog,
            icon:
                const Icon(Icons.call_end, color: Colors.red, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    return Stack(
      children: [
        if (remoteRenderers.isNotEmpty)
          GridView.builder(
            padding: EdgeInsets.all(4.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: remoteRenderers.length > 1 ? 2 : 1,
              childAspectRatio: 4 / 3,
            ),
            itemCount: remoteRenderers.length,
            itemBuilder: (_, i) {
              final entry =
                  remoteRenderers.entries.elementAt(i);
              return Container(
                margin: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: RTCVideoView(entry.value,
                      objectFit: RTCVideoViewObjectFit
                          .RTCVideoViewObjectFitCover),
                ),
              );
            },
          ),
        Positioned(
          right: 12.w,
          bottom: 12.h,
          child: GestureDetector(
            onTap: onToggleCam,
            child: Container(
              width: 100.w,
              height: 140.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border:
                    Border.all(color: Colors.white38, width: 2),
                color: Colors.black,
              ),
              child: localStream != null
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(10.r),
                      child: RTCVideoView(localRenderer,
                          objectFit: RTCVideoViewObjectFit
                              .RTCVideoViewObjectFitCover),
                    )
                  : Center(
                      child: Icon(Icons.videocam_off,
                          color: Colors.white38, size: 32.w)),
            ),
          ),
        ),
        if (remoteRenderers.isEmpty)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam,
                    color: Colors.white38, size: 48),
                SizedBox(height: 8),
                Text('بانتظار انضمام الطلاب...',
                    style: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white54,
                        fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlButton(
            icon: micOn ? Icons.mic : Icons.mic_off,
            color: micOn ? Colors.white : Colors.red,
            onTap: onToggleMic,
          ),
          _controlButton(
            icon: camOn ? Icons.videocam : Icons.videocam_off,
            color: camOn ? Colors.white : Colors.red,
            onTap: onToggleCam,
          ),
          _controlButton(
            icon: screenShareOn
                ? Icons.stop_screen_share
                : Icons.screen_share,
            color: screenShareOn
                ? const Color(0xFF10B981)
                : Colors.white,
            onTap: onToggleScreenShare,
          ),
          _controlButton(
            icon: Icons.chat,
            color: chatUnread > 0
                ? const Color(0xFFF59E0B)
                : Colors.white,
            onTap: onToggleChat,
            badge: chatUnread > 0 ? '$chatUnread' : null,
          ),
          _controlButton(
            icon: Icons.people,
            color: Colors.white,
            onTap: onShowParticipantsDialog,
            badge: '${participants.length}',
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Badge(
      isLabelVisible: badge != null,
      label: badge != null
          ? Text(badge,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold))
          : null,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
