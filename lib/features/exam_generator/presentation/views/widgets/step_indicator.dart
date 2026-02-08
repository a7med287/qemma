import 'package:flutter/material.dart';

import '../../../data/step_data.dart';

class StepIndicator extends StatelessWidget {
  final List<StepData> steps;
  final int currentPage;

  const StepIndicator({
    super.key,
    required this.steps,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(
          steps.length,
              (index) => Expanded(
            child: _StepItem(
              step: steps[index],
              isActive: index == currentPage,
              isFirst: index == 0,
              isLast: index == steps.length - 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final StepData step;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  const _StepItem({
    Key? key,
    required this.step,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            if (!isFirst)
              Expanded(
                child: Container(
                  height: 2,
                  color: step.isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[300],
                ),
              ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: step.isCompleted
                    ? const Color(0xFF4CAF50)
                    : isActive
                    ? const Color(0xFFD81B60)
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: step.isCompleted
                    ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
                    : Text(
                  '${step.stepNumber}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  color: Colors.grey[300],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          step.title,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? const Color(0xFFD81B60) : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}