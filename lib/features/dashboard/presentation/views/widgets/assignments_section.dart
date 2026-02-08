import 'package:flutter/material.dart';
import 'package:qemma/features/dashboard/presentation/views/assignments_view.dart';
import '../../../data/models/assignment.dart';
import 'assignment_item.dart';

class AssignmentsSection extends StatefulWidget {
  const AssignmentsSection({super.key});

  @override
  State<AssignmentsSection> createState() => _AssignmentsSectionState();
}

class _AssignmentsSectionState extends State<AssignmentsSection> {
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
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'المهام القادمة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF6C5CE7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B894).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Color(0xFF00B894),
                      size: 20,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssignmentsPage()),
                  );
                },
                child: const Text(
                  'عرض الكل',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C5CE7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Assignments List
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
    );
  }
}
