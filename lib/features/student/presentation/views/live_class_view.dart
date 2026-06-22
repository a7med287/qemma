import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/errors/failures.dart';
import '../../data/models/student_model_json.dart';
import '../../data/repositories/student_repository.dart';
import '../widgets/student_shared_widgets.dart';

class LiveClassView extends StatefulWidget {
  const LiveClassView({super.key});

  @override
  State<LiveClassView> createState() => _LiveClassViewState();
}

class _LiveClassViewState extends State<LiveClassView> {
  final _codeController = TextEditingController();
  bool _inRoom = false;
  bool _chatOpen = false;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final room = await context.read<StudentRepository>().joinLiveByCode(code);
      if (!mounted) return;
      setState(() {
        _room = room;
        _inRoom = true;
        _loading = false;
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_inRoom && _room != null) return _buildRoom(context, _room!);

    return StudentPageShell(
      title: '🎥 الحصص المباشرة',
      body: ListView(
        padding: EdgeInsets.all(16.r),
        children: [
          StudentGlassCard(
            title: 'انضم بكود الحصة',
            child: Column(
              children: [
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    hintText: 'أدخل كود الحصة (6 أحرف)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                ),
                if (_error != null) ...[
                  SizedBox(height: 8.h),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                SizedBox(height: 12.h),
                ElevatedButton(
                  onPressed: _loading ? null : _joinByCode,
                  style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48.h)),
                  child: _loading ? const CircularProgressIndicator() : const Text('انضم الآن'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoom(BuildContext context, LiveRoomInfo room) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(room.title, style: const TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => setState(() {
            _inRoom = false;
            _room = null;
          }),
        ),
        actions: [
          if (room.isActive) const Chip(label: Text('مباشر', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.grey.shade900,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam, size: 64.sp, color: Colors.white54),
                  Text(room.teacherName, style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                  Text(room.courseTitle, style: TextStyle(color: Colors.white54, fontSize: 12.sp)),
                ],
              ),
            ),
          ),
          if (_chatOpen)
            Expanded(
              flex: 2,
              child: Container(
                color: Colors.grey.shade900,
                child: const Center(child: Text('المحادثة', style: TextStyle(color: Colors.white70))),
              ),
            ),
          Container(
            color: Colors.black87,
            padding: EdgeInsets.all(12.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _control(Icons.mic, 'مايك'),
                _control(Icons.pan_tool, 'رفع يد'),
                _control(Icons.chat, 'محادثة', onTap: () => setState(() => _chatOpen = !_chatOpen)),
                _control(Icons.people, '${room.participants}'),
                _control(Icons.call_end, 'مغادرة', color: Colors.red, onTap: () => setState(() {
                      _inRoom = false;
                      _room = null;
                    })),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(IconData icon, String label, {Color? color, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: (color ?? Colors.white).withValues(alpha: .2),
            child: Icon(icon, color: color ?? Colors.white, size: 20.sp),
          ),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 10.sp)),
        ],
      ),
    );
  }
}
