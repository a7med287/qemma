import 'package:flutter/material.dart';
import 'package:qemma/features/home/presentation/views/widgets/statistics_card.dart';


class HorizontalStatisticsList extends StatelessWidget {
  const HorizontalStatisticsList({super.key});

  @override
  Widget build(BuildContext context) {

    final metrics = [
      {
        'icon': Icons.access_time,
        'iconColor': Colors.pink,
        'value': '14h',
        'label': 'ساعات الدراسة',
        'change': '4+',
        'changeColor': Colors.green,
      },
      {
        'icon': Icons.star,
        'iconColor': Colors.purple,
        'value': '88',
        'label': 'متوسط الدرجات',
        'change': '2+',
        'changeColor': Colors.green,
      },
      {
        'icon': Icons.videocam,
        'iconColor': Colors.blue,
        'value': '92%',
        'label': 'حضور المحاضرات',
        'change': '3%+',
        'changeColor': Colors.green,
      },
      {
        'icon': Icons.check_circle,
        'iconColor': Colors.teal,
        'value': '85%',
        'label': 'إنجاز الواجبات',
        'change': '5%+',
        'changeColor': Colors.green,
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 180, // Compact height to fit content
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: metrics.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return MetricCard(
              icon: metric['icon'] as IconData,
              iconColor: metric['iconColor'] as Color,
              textPercent: metric['value'] as String,
              textLabel: metric['label'] as String,
              changeText: metric['change'] as String,
              changeColor: metric['changeColor'] as Color,
            );
          },
        ),
      ),
    );
  }
}

