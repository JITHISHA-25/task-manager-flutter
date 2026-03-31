import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);

    final stats = [
      _Stat('Total', provider.totalCount, theme.colorScheme.onSurface, Icons.list_alt_rounded),
      _Stat('To-Do', provider.todoCount, theme.colorScheme.primary, Icons.circle_outlined),
      _Stat('Active', provider.inProgressCount, Colors.amber, Icons.trending_up_rounded),
      _Stat('Done', provider.doneCount, Colors.green, Icons.check_circle_rounded),
      _Stat('Overdue', provider.overdueCount, theme.colorScheme.error, Icons.warning_amber_rounded),
      _Stat('Urgent', provider.urgentCount, Colors.purple, Icons.bolt_rounded),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final s = stats[i];
          return Container(
            width: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: s.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: s.color.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(s.icon, size: 16, color: s.color),
                    const SizedBox(width: 6),
                    Text(
                      '${s.value}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: s.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  s.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  _Stat(this.label, this.value, this.color, this.icon);
}
