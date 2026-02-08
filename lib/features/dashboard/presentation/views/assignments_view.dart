// screens/assignments_page.dart
import 'package:flutter/material.dart';
import 'package:qemma/core/utils/app_colors.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/assignment_item.dart';
import 'package:qemma/features/dashboard/presentation/views/widgets/assignments_section.dart';

import '../../data/models/assignment.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  List<Assignment> assignments = [
    Assignment(
      id: '1',
      title: 'حل تمارين الكتاب صفحة',
      subject: 'رياضيات',
      dueDate: '+11:45 س',
      type: AssignmentType.homework,
      status: AssignmentStatus.urgent,
      isCompleted: false,
    ),
    Assignment(
      id: '2',
      title: 'تقرير تجربة المعايرة',
      subject: 'كيمياء',
      dueDate: '30 يناير',
      type: AssignmentType.report,
      status: AssignmentStatus.pending,
      isCompleted: false,
    ),
    Assignment(
      id: '4',
      title: 'كتابة Essay عن التكنولوجيا',
      subject: 'إنجليزية',
      dueDate: '5 فبراير',
      type: AssignmentType.essay,
      status: AssignmentStatus.pending,
      isCompleted: false,
    ),
  ];

  void _toggleAssignment(String id, bool? value) {
    setState(() {
      final index = assignments.indexWhere((a) => a.id == id);
      if (index != -1) {
        assignments[index] = assignments[index].copyWith(
          isCompleted: value ?? false,
        );
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'المهام والواجبات',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2D3436),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.filter_list,
              color: Color(0xFF2D3436),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0,vertical: 4),
          child: Column(
            children:  [
              ...assignments.map(
                    (assignment) => AssignmentItem(
                  assignment: assignment,
                  onChanged: (value) => _toggleAssignment(assignment.id, value),
                  onTap: () {
                    // Handle tap
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: InkWell(
        onTap: (){},
        child: Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(colors: [AppColors.primaryColor,AppColors.accentColor])
          ),
          child: Icon(Icons.add,color: Colors.white,),
        ),
      )
    );
  }
}