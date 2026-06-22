import 'package:flutter/material.dart';

class TeacherDashboardView extends StatelessWidget {
  static const routeName = '/teacher/dashboard';
  const TeacherDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("لوحة تحكم المعلم")),
      body: const Center(child: Text("مرحباً بك يا أستاذنا")),
    );
  }
}