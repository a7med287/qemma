import 'package:flutter/material.dart';

void showEndConfirmDialog(BuildContext context, VoidCallback onEndClass) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('إنهاء الحصة',
          style: TextStyle(fontFamily: 'Cairo')),
      content: const Text('هل أنت متأكد من إنهاء الحصة؟',
          style: TextStyle(fontFamily: 'Cairo')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إلغاء',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            onEndClass();
          },
          child: const Text('إنهاء',
              style: TextStyle(
                  fontFamily: 'Cairo', color: Colors.red)),
        ),
      ],
    ),
  );
}

void showParticipantsDialog(
    BuildContext context, List<Map<String, dynamic>> participants) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('المشتركين (${participants.length})',
          style: const TextStyle(fontFamily: 'Cairo')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          shrinkWrap: true,
          children: participants.map((p) {
            final name = (p['name'] ?? '') as String;
            final role = (p['role'] ?? '') as String;
            final isLocal = p['isLocal'] == true;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: role == 'teacher'
                    ? const Color(0xFF7C3AED)
                    : const Color(0xFF2563EB),
                radius: 18,
                child: Text(
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name,
                  style: const TextStyle(fontFamily: 'Cairo')),
              subtitle: Text(
                isLocal
                    ? '${role == 'teacher' ? 'مدرس' : 'طالب'} (أنت)'
                    : role == 'teacher'
                        ? 'مدرس'
                        : 'طالب',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ),
  );
}

void showRaiseHandsDialog(
    BuildContext context, List<Map<String, dynamic>> raiseHands) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('رفع اليد',
          style: TextStyle(fontFamily: 'Cairo')),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: raiseHands.map((h) {
            final name = (h['name'] ?? '') as String;
            return ListTile(
              leading: const Icon(Icons.pan_tool,
                  color: Color(0xFFF59E0B)),
              title: Text(name,
                  style: const TextStyle(fontFamily: 'Cairo')),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('حسناً',
              style: TextStyle(fontFamily: 'Cairo')),
        ),
      ],
    ),
  );
}
