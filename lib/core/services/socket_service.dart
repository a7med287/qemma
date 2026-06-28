import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._();
  factory SocketService() => _instance;
  SocketService._();

  io.Socket? _socket;
  String? _activeChatSessionId;
  String? _token;
  String? _userId;

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<void> _enrollmentController =
      StreamController<void>.broadcast();
  final StreamController<void> _reviewController =
      StreamController<void>.broadcast();
  final StreamController<Map<String, dynamic>> _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatTypingController =
      StreamController<Map<String, dynamic>>.broadcast();

  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<void> get enrollmentStream => _enrollmentController.stream;
  Stream<void> get reviewStream => _reviewController.stream;
  Stream<Map<String, dynamic>> get chatMessageStream =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get chatTypingStream =>
      _chatTypingController.stream;

  bool get isConnected => _socket?.connected ?? false;
  String? get token => _token;
  String? get userId => _userId;

  void connect(String token, String userId) {
    _token = token;
    _userId = userId;
    if (_socket?.connected == true) return;

    final socketUrl = kApiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

    _socket = io.io(socketUrl, {
      'auth': {'token': token},
      'transports': ['websocket', 'polling'],
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket!.onConnect((_) {
      _socket!.emit('joinTeacherRoom', {'teacherId': userId});
      if (_activeChatSessionId != null) {
        _socket!.emit('chat:join_session', {'sessionId': _activeChatSessionId});
      }
    });

    _socket!.on('notification:new', (data) {
      if (data is Map<String, dynamic>) {
        _notificationController.add(data);
        unreadCountNotifier.value = unreadCountNotifier.value + 1;
      }
    });

    _socket!.on('newEnrollment', (_) {
      _enrollmentController.add(null);
    });

    _socket!.on('newReview', (_) {
      _reviewController.add(null);
    });

    _socket!.on('chat:message', (data) {
      if (data is Map<String, dynamic>) {
        _chatMessageController.add(data);
      }
    });

    _socket!.on('chat:typing', (data) {
      if (data is Map<String, dynamic>) {
        _chatTypingController.add(data);
      }
    });

    _socket!.on('chat:stop_typing', (data) {
      if (data is Map<String, dynamic>) {
        _chatTypingController.add(data);
      }
    });
  }

  void disconnect() {
    _activeChatSessionId = null;
    _socket?.disconnect();
    _socket = null;
    unreadCountNotifier.value = 0;
  }

  void joinChatSession(String sessionId) {
    _activeChatSessionId = sessionId;
    _socket?.emit('chat:join_session', {'sessionId': sessionId});
  }

  void leaveChatSession(String sessionId) {
    if (_activeChatSessionId == sessionId) {
      _activeChatSessionId = null;
    }
    _socket?.emit('chat:leave_session', {'sessionId': sessionId});
  }

  void sendChatTyping(String sessionId, String userName) {
    _socket?.emit('chat:typing', {'sessionId': sessionId, 'userName': userName});
  }

  void sendChatStopTyping(String sessionId) {
    _socket?.emit('chat:stop_typing', {'sessionId': sessionId});
  }

  void dispose() {
    disconnect();
    _notificationController.close();
    _enrollmentController.close();
    _reviewController.close();
    _chatMessageController.close();
    _chatTypingController.close();
    unreadCountNotifier.dispose();
  }
}
