import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class LiveClassRoomPanel extends StatefulWidget {
  const LiveClassRoomPanel({
    super.key,
    required this.roomName,
    required this.title,
    required this.teacherName,
    required this.courseTitle,
    required this.isActive,
    required this.participants,
    required this.onLeave,
  });

  final String roomName;
  final String title;
  final String teacherName;
  final String courseTitle;
  final bool isActive;
  final int participants;
  final VoidCallback onLeave;

  @override
  State<LiveClassRoomPanel> createState() => _LiveClassRoomPanelState();
}

class _LiveClassRoomPanelState extends State<LiveClassRoomPanel> {
  // WebRTC
  MediaStream? _localStream;
  final _teacherRenderer = RTCVideoRenderer();
  final _screenShareRenderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  final _stunConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // Socket
  io.Socket? _socket;
  bool _connected = false;

  // State
  bool _micOn = true;
  bool _handRaised = false;
  bool _showChat = true;
  bool _showParticipants = false;
  bool _teacherMicOn = true;
  bool _teacherCamOn = false;
  bool _teacherScreenShare = false;
  int _duration = 0;
  Timer? _timer;
  int _videoTrackCount = 0;

  // Chat
  final List<Map<String, dynamic>> _messages = [];
  final _chatController = TextEditingController();
  final _chatScrollController = ScrollController();
  int _chatUnread = 0;

  // Participants
  final List<Map<String, dynamic>> _participants = [];

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _connect();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
  }

  Future<void> _initRenderers() async {
    await _teacherRenderer.initialize();
    await _screenShareRenderer.initialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cleanup();
    _teacherRenderer.dispose();
    _screenShareRenderer.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _cleanup() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _pc?.close();
    _pc = null;
    _socket?.disconnect();
    _socket = null;
  }

  String _formatDuration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _connect() async {
    try {
      // Permissions
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) return;

      // 1. Local audio stream
      final localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      if (!mounted) { localStream.getTracks().forEach((t) => t.stop()); return; }
      _localStream = localStream;

      // 2. Connect socket
      const wsUrl = 'http://localhost:5000';
      final socket = io.io(wsUrl, {
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
      });
      _socket = socket;

      socket.onConnect((_) {
        setState(() => _connected = true);
        socket.emit('live_class:join', {'roomName': widget.roomName});
      });

      // 3. WebRTC offer from teacher
      socket.on('webrtc:offer', (data) async {
        final fromUserId = data['fromUserId'] as String;
        final offer = RTCSessionDescription(
          data['offer']['sdp'] as String,
          data['offer']['type'] as String,
        );

        if (_pc != null) {
          // Renegotiation (e.g., screen share)
          try {
            await _pc!.setRemoteDescription(offer);
            final answer = await _pc!.createAnswer();
            await _pc!.setLocalDescription(answer);
            socket.emit('webrtc:answer', {
              'roomName': widget.roomName,
              'targetUserId': fromUserId,
              'answer': answer.toMap(),
            });
          } catch (_) {}
          return;
        }

        final pc = await createPeerConnection(_stunConfig);
        _pc = pc;
        _videoTrackCount = 0;

        localStream.getTracks().forEach((track) => pc.addTrack(track, localStream));

        pc.onIceCandidate = (candidate) {
          socket.emit('webrtc:ice-candidate', {
            'roomName': widget.roomName,
            'targetUserId': fromUserId,
            'candidate': {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid,
              'sdpMLineIndex': candidate.sdpMLineIndex,
            },
          });
        };

        pc.onTrack = (event) {
          if (event.track.kind == 'video') {
            if (!mounted) return;
            _videoTrackCount++;
            if (_videoTrackCount == 1) {
              _teacherRenderer.srcObject = event.streams[0];
              setState(() => _teacherCamOn = true);
            } else if (_videoTrackCount >= 2) {
              _screenShareRenderer.srcObject = event.streams[0];
              setState(() => _teacherScreenShare = true);
            }
          } else if (event.track.kind == 'audio') {
            final existing = _teacherRenderer.srcObject;
            if (existing != null && existing.getAudioTracks().isEmpty) {
              existing.addTrack(event.track);
            }
          }
          if (event.streams[0].getAudioTracks().isNotEmpty) {
            setState(() => _teacherMicOn = true);
          }
        };

        pc.onIceConnectionState = (state) {
          if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
              state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
            // Teacher may have disconnected
          }
        };

        await pc.setRemoteDescription(offer);
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        socket.emit('webrtc:answer', {
          'roomName': widget.roomName,
          'targetUserId': fromUserId,
          'answer': answer.toMap(),
        });
      });

      // 4. WebRTC answer
      socket.on('webrtc:answer', (data) async {
        try {
          if (_pc != null) {
            final answer = RTCSessionDescription(
              data['answer']['sdp'] as String,
              data['answer']['type'] as String,
            );
            await _pc!.setRemoteDescription(answer);
          }
        } catch (_) {}
      });

      // 5. ICE candidate
      socket.on('webrtc:ice-candidate', (data) async {
        try {
          if (_pc != null) {
            final candidate = RTCIceCandidate(
              data['candidate']['candidate'] as String,
              data['candidate']['sdpMid'] as String?,
              (data['candidate']['sdpMLineIndex'] as num?)?.toInt() ?? 0,
            );
            await _pc!.addCandidate(candidate);
          }
        } catch (_) {}
      });

      // 6. Chat
      socket.on('live_class:chat_message', (data) {
        final senderName = data['senderName'] as String? ?? 'مشارك';
        final message = data['message'] as String? ?? '';
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch,
            'sender': senderName,
            'message': message,
            'time': _formatTime(DateTime.now()),
            'isTeacher': data['senderId'] != null, // simplified
          });
        });
        if (!_showChat) {
          _chatUnread++;
        }
      });

      // 7. Participants
      socket.on('live_class:student_joined', (data) {
        final userId = data['userId'] as String;
        final name = data['name'] as String? ?? 'طالب';
        setState(() {
          _participants.removeWhere((p) => p['userId'] == userId);
          _participants.add({'userId': userId, 'name': name, 'role': 'student'});
        });
      });

      socket.on('live_class:student_left', (data) {
        final userId = data['userId'] as String;
        setState(() => _participants.removeWhere((p) => p['userId'] == userId));
      });

      // 8. Class ended
      socket.on('live_class:ended', (_) {
        _cleanup();
        widget.onLeave();
      });

      // 9. Screen share
      socket.on('live_class:screen_share_started', (_) {
        setState(() => _teacherScreenShare = true);
      });
      socket.on('live_class:screen_share_stopped', (_) {
        setState(() { _teacherScreenShare = false; _videoTrackCount = 1; });
      });

      // 10. Mute/unmute
      socket.on('live_class:muted', (_) {
        _localStream?.getAudioTracks().forEach((t) => t.enabled = false);
        setState(() => _micOn = false);
      });
      socket.on('live_class:unmuted', (_) {
        _localStream?.getAudioTracks().forEach((t) => t.enabled = true);
        setState(() => _micOn = true);
      });

    } catch (e) {
      debugPrint('Failed to connect: $e');
    }
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _socket?.emit('live_class:chat_message', {
      'roomName': widget.roomName,
      'senderName': 'طالب',
      'message': text,
    });
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch,
        'sender': 'أنت',
        'message': text,
        'time': _formatTime(DateTime.now()),
        'isTeacher': false,
        'isMe': true,
      });
    });
    _chatController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleMic() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !t.enabled);
    setState(() => _micOn = !_micOn);
  }

  void _toggleHandRaise() {
    final newState = !_handRaised;
    setState(() => _handRaised = newState);
    if (newState) {
      _socket?.emit('live_class:raise_hand', {
        'roomName': widget.roomName,
        'name': 'طالب',
      });
    }
  }

  void _handleLeave() {
    _socket?.emit('live_class:leave', {'roomName': widget.roomName});
    _cleanup();
    widget.onLeave();
  }

  int get _studentCount => _participants.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────
          _buildHeader(),
          // ── Main content ──────────────────────────────────
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: _buildVideoArea(),
                  ),
                ),
                if (_showChat || _showParticipants)
                  _buildSidePanel(),
              ],
            ),
          ),
          // ── Control Bar ───────────────────────────────────
          _buildControlBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          // LIVE badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
                SizedBox(width: 6.w),
                const Text('مباشر', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Title
          Expanded(
            child: Text(widget.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
          ),
          SizedBox(width: 8.w),
          // Duration
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(_formatDuration(_duration),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontFamily: 'monospace')),
          ),
          SizedBox(width: 8.w),
          // Participants count
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 14, color: Colors.white),
                SizedBox(width: 4.w),
                Text('${_participants.length + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Cairo')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    if (!_connected) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48, height: 48, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF2563EB))),
            SizedBox(height: 12.h),
            const Text('جاري الاتصال بالحصة...',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontFamily: 'Cairo')),
          ],
        ),
      );
    }

    if (_teacherScreenShare) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            RTCVideoView(_screenShareRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain),
            // Screen share badge
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: const Text('مشاركة الشاشة',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
              ),
            ),
            // PIP camera
            if (_teacherCamOn)
              Positioned(
                bottom: 12, left: 12,
                child: Container(
                  width: 150.w, height: 100.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: RTCVideoView(_teacherRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: _teacherCamOn
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Stack(
                children: [
                  RTCVideoView(_teacherRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                  Positioned(
                    bottom: 12, left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8.r)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.teacherName,
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
                          SizedBox(width: 6.w),
                          Icon(
                            _teacherMicOn ? Icons.volume_up_rounded : Icons.mic_off_rounded,
                            size: 14,
                            color: _teacherMicOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _buildTeacherAvatarFallback(),
    );
  }

  Widget _buildTeacherAvatarFallback() {
    final initial = widget.teacherName.isNotEmpty ? widget.teacherName[0] : 'م';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 50.r,
          backgroundColor: const Color(0xFF7C3AED),
          child: Text(initial,
              style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
        ),
        SizedBox(height: 12.h),
        Text(widget.teacherName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Cairo')),
      ],
    );
  }

  Widget _buildSidePanel() {
    return Container(
      width: 280.w,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(left: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Column(
        children: [
          // Tabs
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
            ),
            child: Row(
              children: [
                _tabButton('💬 المحادثة', _showChat, () {
                  setState(() { _showChat = true; _showParticipants = false; _chatUnread = 0; });
                }),
                SizedBox(width: 8.w),
                _tabButton('👥 $_studentCount', _showParticipants, () {
                  setState(() { _showParticipants = true; _showChat = false; });
                }),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => setState(() { _showChat = false; _showParticipants = false; }),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Expanded(child: _showChat ? _buildChatPanel() : _buildParticipantsPanel()),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(label,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Text('لا توجد رسائل بعد',
                      style: TextStyle(color: const Color(0xFF475569), fontSize: 13, fontFamily: 'Cairo')))
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.all(12.w),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    final isMe = msg['isMe'] == true;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: EdgeInsets.only(bottom: 2.h),
                              child: Text(
                                '${msg['sender']}${msg['isTeacher'] == true ? ' (المدرس)' : ''}',
                                style: TextStyle(
                                  fontSize: 11, fontFamily: 'Cairo',
                                  color: msg['isTeacher'] == true ? const Color(0xFFA78BFA) : const Color(0xFF94A3B8),
                                  fontWeight: msg['isTeacher'] == true ? FontWeight.w700 : FontWeight.w600,
                                ),
                              ),
                            ),
                          Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? const Color(0xFF2563EB)
                                  : msg['isTeacher'] == true
                                      ? const Color(0xFF7C3AED)
                                      : const Color(0xFF475569),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(isMe ? 8.r : 2.r),
                                topRight: Radius.circular(isMe ? 2.r : 8.r),
                                bottomLeft: Radius.circular(8.r),
                                bottomRight: Radius.circular(8.r),
                              ),
                            ),
                            child: Text(msg['message'] ?? '',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo')),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 2.h),
                            child: Text(msg['time'] ?? '',
                                style: TextStyle(color: const Color(0xFF64748B), fontSize: 10, fontFamily: 'Cairo')),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Cairo'),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(color: const Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsPanel() {
    return ListView(
      padding: EdgeInsets.all(12.w),
      children: [
        // Teacher section
        Text('المدرس',
            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: const Color(0xFF7C3AED),
                child: Text(widget.teacherName.isNotEmpty ? widget.teacherName[0] : 'م',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontFamily: 'Cairo')),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.teacherName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Cairo')),
                    const Text('المدرس',
                        style: TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontFamily: 'Cairo')),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_teacherMicOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      size: 18, color: _teacherMicOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                  SizedBox(width: 4.w),
                  Icon(_teacherCamOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      size: 18, color: _teacherCamOn ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Students section
        Text('الطلاب ($_studentCount)',
            style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 11, fontFamily: 'Cairo')),
        SizedBox(height: 8.h),
        if (_studentCount == 0)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Text('لا يوجد طلاب بعد',
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF64748B), fontSize: 13, fontFamily: 'Cairo')),
          )
        else
          ..._participants.map((p) => Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text((p['name'] as String? ?? 'ط').substring(0, 1),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo')),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(p['name'] ?? 'طالب',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'Cairo')),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(top: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _controlButton(
            icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            color: _micOn ? const Color(0xFF475569) : const Color(0xFFEF4444),
            tooltip: _micOn ? 'إيقاف الميكروفون' : 'تشغيل الميكروفون',
            onTap: _toggleMic,
          ),
          SizedBox(width: 12.w),
          _controlButton(
            icon: Icons.pan_tool_rounded,
            color: _handRaised ? const Color(0xFFF59E0B) : const Color(0xFF475569),
            tooltip: _handRaised ? 'إنزال اليد' : 'رفع اليد',
            onTap: _toggleHandRaise,
          ),
          SizedBox(width: 12.w),
          _controlButton(
            icon: Icons.chat_rounded,
            color: _showChat ? const Color(0xFF2563EB) : const Color(0xFF475569),
            tooltip: 'المحادثة',
            badge: _chatUnread,
            onTap: () {
              setState(() { _showChat = !_showChat; _showParticipants = false; _chatUnread = 0; });
            },
          ),
          SizedBox(width: 12.w),
          _controlButton(
            icon: Icons.people_rounded,
            color: _showParticipants ? const Color(0xFF2563EB) : const Color(0xFF475569),
            tooltip: 'المشاركون',
            badge: _participants.length + 1,
            onTap: () => setState(() { _showParticipants = !_showParticipants; _showChat = false; }),
          ),
          SizedBox(width: 12.w),
          // Leave button
          GestureDetector(
            onTap: _handleLeave,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6.w),
                  const Text('مغادرة',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Cairo')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.w, height: 48.w,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: badge > 0
            ? Badge(
                label: Text(badge.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                child: Icon(icon, color: Colors.white, size: 22.sp),
              )
            : Icon(icon, color: Colors.white, size: 22.sp),
      ),
    );
  }
}
