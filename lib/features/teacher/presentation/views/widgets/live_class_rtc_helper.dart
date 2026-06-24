part of '../teacher_live_class_view.dart';

mixin LiveClassRtcMixin on State<TeacherLiveClassView> {
  MediaStream? _localStream;
  final _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, RTCRtpSender> _screenSenders = {};
  io.Socket? _socket;
  bool _micOn = true;
  bool _camOn = true;
  bool _screenShareOn = false;
  MediaStream? _screenStream;
  final List<Map<String, dynamic>> _participants = [];
  final List<Map<String, dynamic>> _messages = [];
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _chatOpen = false;
  int _chatUnread = 0;
  final List<Map<String, dynamic>> _raiseHands = [];
  int _duration = 0;
  Timer? _timer;
  Map<String, dynamic>? _createdRoom;

  String get _roomName =>
      (_createdRoom?['roomName'] ?? _createdRoom?['name'] ?? '') as String;

  // ── Cleanup ──────────────────────────────────────────────────────
  void _cleanup() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream = null;
    _screenStream?.getTracks().forEach((t) => t.stop());
    _screenStream = null;
    for (final pc in _peers.values) {
      pc.close();
    }
    _peers.clear();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _remoteRenderers.clear();
    _socket?.disconnect();
    _socket = null;
  }

  // ── Request permissions ─────────────────────────────────────────
  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied) {
      buildSnackBar(
          context,
          'يرجى السماح بالكاميرا والميكروفون من إعدادات الجهاز',
          isError: true);
      await openAppSettings();
      return false;
    }

    if (!cameraStatus.isGranted || !micStatus.isGranted) {
      buildSnackBar(context,
          'يرجى السماح بالوصول للكاميرا والميكروفون',
          isError: true);
      return false;
    }

    return true;
  }

  // ── Socket ───────────────────────────────────────────────────────
  void _connectSocket() {
    const baseUrl = 'http://localhost:5000';
    _socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket', 'polling'],
      'autoConnect': true,
    });

    final socket = _socket!;

    socket.onConnect((_) {
      socket.emit('live_class:join', {'roomName': _roomName});
      setState(() {
        _participants.add({
          'userId': 'teacher',
          'name': 'المدرس',
          'role': 'teacher',
          'isLocal': true,
        });
      });
    });

    socket.on('live_class:student_joined', (data) {
      final userId = data['userId'] as String;
      final name = data['name'] as String? ?? 'طالب';
      setState(() {
        _participants.removeWhere((p) => p['userId'] == userId);
        _participants.add({'userId': userId, 'name': name, 'role': 'student'});
      });

      _createPeerConnection(userId, socket).then((pc) {
        _peers[userId] = pc;
        pc.createOffer().then((offer) {
          pc.setLocalDescription(offer);
          socket.emit('webrtc:offer', {
            'roomName': _roomName,
            'targetUserId': userId,
            'offer': offer.toMap(),
          });
        });
      });
    });

    socket.on('live_class:student_left', (data) {
      final userId = data['userId'] as String;
      setState(() => _participants.removeWhere((p) => p['userId'] == userId));
      _peers[userId]?.close();
      _peers.remove(userId);
      _remoteRenderers[userId]?.dispose();
      _remoteRenderers.remove(userId);
    });

    socket.on('webrtc:offer', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final offer = RTCSessionDescription(
        data['offer']['sdp'] as String,
        data['offer']['type'] as String,
      );

      var pc = _peers[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(offer);
        final answer = await pc.createAnswer();
        await pc.setLocalDescription(answer);
        socket.emit('webrtc:answer', {
          'roomName': _roomName,
          'targetUserId': fromUserId,
          'answer': answer.toMap(),
        });
        return;
      }

      pc = await _createPeerConnection(fromUserId, socket);
      _peers[fromUserId] = pc;
      await pc.setRemoteDescription(offer);
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      socket.emit('webrtc:answer', {
        'roomName': _roomName,
        'targetUserId': fromUserId,
        'answer': answer.toMap(),
      });
    });

    socket.on('webrtc:answer', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final answer = RTCSessionDescription(
        data['answer']['sdp'] as String,
        data['answer']['type'] as String,
      );
      final pc = _peers[fromUserId];
      if (pc != null) {
        await pc.setRemoteDescription(answer);
      }
    });

    socket.on('webrtc:ice-candidate', (data) async {
      final fromUserId = data['fromUserId'] as String;
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'] as String,
        data['candidate']['sdpMid'] as String?,
        (data['candidate']['sdpMLineIndex'] as num?)?.toInt() ?? 0,
      );
      final pc = _peers[fromUserId];
      if (pc != null) {
        await pc.addCandidate(candidate);
      }
    });

    socket.on('live_class:chat_message', (data) {
      final senderName = data['senderName'] as String? ?? 'طالب';
      final message = data['message'] as String? ?? '';
      setState(() {
        _messages.add({
          'sender': senderName,
          'message': message,
          'time': _formatTime(DateTime.now()),
          'isTeacher': false,
        });
      });
      if (!_chatOpen) {
        _chatUnread++;
      }
    });

    socket.on('live_class:hand_raised', (data) {
      final userId = data['userId'] as String;
      final name = data['name'] as String? ?? 'طالب';
      setState(() {
        if (!_raiseHands.any((h) => h['userId'] == userId)) {
          _raiseHands.add({'userId': userId, 'name': name});
        }
      });
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted) {
          setState(() => _raiseHands.removeWhere((h) => h['userId'] == userId));
        }
      });
    });

    socket.on('live_class:screen_share_started', (_) {});
    socket.on('live_class:screen_share_stopped', (_) {});
  }

  // ── WebRTC ───────────────────────────────────────────────────────
  Future<RTCPeerConnection> _createPeerConnection(
      String userId, io.Socket socket) async {
    const config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(config);
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    final renderer = RTCVideoRenderer();
    await renderer.initialize();
    _remoteRenderers[userId] = renderer;

    pc.onIceCandidate = (candidate) {
      socket.emit('webrtc:ice-candidate', {
        'roomName': _roomName,
        'targetUserId': userId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    pc.onTrack = (event) {
      if (event.track.kind == 'video') {
        if (mounted) {
          setState(() {
            _remoteRenderers[userId]?.srcObject = event.streams[0];
          });
        }
      }
    };

    pc.onRenegotiationNeeded = () async {
      if (!(_peers.containsKey(userId))) return;
      try {
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        socket.emit('webrtc:offer', {
          'roomName': _roomName,
          'targetUserId': userId,
          'offer': offer.toMap(),
        });
      } catch (e) {
        debugPrint('Renegotiation error for $userId: $e');
      }
    };

    pc.onRemoveTrack = (stream, track) {};

    return pc;
  }

  // ── Controls ─────────────────────────────────────────────────────
  void _toggleMic() {
    _localStream?.getAudioTracks().forEach((t) {
      t.enabled = !t.enabled;
    });
    setState(() => _micOn = !_micOn);
  }

  void _toggleCam() {
    _localStream?.getVideoTracks().forEach((t) {
      t.enabled = !t.enabled;
    });
    setState(() => _camOn = !_camOn);
  }

  Future<void> _toggleScreenShare() async {
    if (_screenShareOn) {
      for (final entry in _peers.entries) {
        try {
          await entry.value.removeTrack(_screenSenders[entry.key]!);
        } catch (_) {}
      }
      _screenSenders.clear();
      _screenStream?.getTracks().forEach((t) => t.stop());
      _screenStream = null;
      setState(() => _screenShareOn = false);
      _socket?.emit('live_class:screen_share_stopped', {
        'roomName': _roomName,
      });
    } else {
      try {
        final screenStream = await navigator.mediaDevices.getDisplayMedia({
          'video': {'cursor': 'always'},
          'audio': false,
        });
        _screenStream = screenStream;
        final screenTrack = screenStream.getVideoTracks()[0];

        setState(() => _screenShareOn = true);

        for (final entry in _peers.entries) {
          final sender = await entry.value.addTrack(screenTrack, screenStream);
          _screenSenders[entry.key] = sender;
        }

        _socket?.emit('live_class:screen_share_started', {
          'roomName': _roomName,
        });
      } catch (e) {
        buildSnackBar(context, 'فشل مشاركة الشاشة', isError: true);
      }
    }
  }

  // ── Timer ────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duration++);
    });
  }

  String _formatDuration(int secs) {
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return h > 0
        ? '${_pad(h)}:${_pad(m)}:${_pad(s)}'
        : '${_pad(m)}:${_pad(s)}';
  }

  String _formatTime(DateTime dt) {
    return '${_pad(dt.hour)}:${_pad(dt.minute)}';
  }
}
