import 'package:flutter/material.dart';
import '../../../data/models/assignment.dart';

class AssignmentItem extends StatelessWidget {
  final Assignment assignment;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const AssignmentItem({
    super.key,
    required this.assignment,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: assignment.isCompleted
                ? const Color(0xFF00B894).withOpacity(0.3)
                : Colors.grey[200]!,
            width: assignment.isCompleted ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Drag handle
            Icon(
              Icons.drag_indicator,
              color: Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 12),

            // Checkbox
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: assignment.isCompleted,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                activeColor: const Color(0xFF00B894),
                side: BorderSide(
                  color: Colors.grey[400]!,
                  width: 2,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    assignment.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: assignment.isCompleted
                          ? Colors.grey[500]
                          : const Color(0xFF2D3436),
                      decoration: assignment.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Due date
                      Row(
                        children: [
                          Text(
                            assignment.dueDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getDueDateColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: _getDueDateColor(),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),

                      // Subject tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: assignment.type.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: assignment.type.color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              assignment.subject,
                              style: TextStyle(
                                fontSize: 11,
                                color: assignment.type.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              assignment.type.icon,
                              size: 14,
                              color: assignment.type.color,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDueDateColor() {
    if (assignment.isCompleted) {
      return Colors.grey[400]!;
    }
    if (assignment.status == AssignmentStatus.urgent) {
      return const Color(0xFFFF6B6B);
    }
    if (assignment.status == AssignmentStatus.overdue) {
      return const Color(0xFFE74C3C);
    }
    return Colors.grey[600]!;
  }
}