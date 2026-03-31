import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final bool isBlocked;
  final String? blockerTitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final Function(String)? onStatusChange;

  const TaskCard({
    super.key,
    required this.task,
    required this.isBlocked,
    this.blockerTitle,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    this.onStatusChange,
  });

  Color _priorityColor() {
    switch (task.priority) {
      case Priority.urgent: return Colors.purple;
      case Priority.high: return Colors.red;
      case Priority.medium: return Colors.amber;
      case Priority.low: return Colors.green;
    }
  }

  IconData _priorityIcon() {
    switch (task.priority) {
      case Priority.urgent: return Icons.bolt_rounded;
      case Priority.high: return Icons.arrow_upward_rounded;
      case Priority.medium: return Icons.remove_rounded;
      case Priority.low: return Icons.arrow_downward_rounded;
    }
  }

  Color _statusColor() {
    switch (task.status) {
      case 'To-Do': return Colors.blue;
      case 'In Progress': return Colors.amber;
      case 'Done': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isBlocked ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: task.isOverdue
              ? BorderSide(color: theme.colorScheme.error.withOpacity(0.4), width: 1.5)
              : BorderSide.none,
        ),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: isBlocked ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == 'Done'
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == 'Done'
                              ? theme.colorScheme.onSurface.withOpacity(0.4)
                              : null,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
                        const PopupMenuItem(value: 'duplicate', child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Duplicate')])),
                        if (task.status != 'Done')
                          const PopupMenuItem(value: 'done', child: Row(children: [Icon(Icons.check_circle, size: 18), SizedBox(width: 8), Text('Mark Done')])),
                        if (task.status != 'To-Do')
                          const PopupMenuItem(value: 'todo', child: Row(children: [Icon(Icons.undo, size: 18), SizedBox(width: 8), Text('Move to To-Do')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                      ],
                      onSelected: (val) {
                        if (val == 'edit') onTap();
                        if (val == 'duplicate') onDuplicate();
                        if (val == 'delete') onDelete();
                        if (val == 'done') onStatusChange?.call('Done');
                        if (val == 'todo') onStatusChange?.call('To-Do');
                      },
                    ),
                  ],
                ),

                // Description
                if (task.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      task.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Badge(task.status, _statusColor(), filled: true),
                    _Badge(task.priority.label, _priorityColor(), icon: _priorityIcon()),
                    ...task.tags.map((tag) => _Badge(tag, theme.colorScheme.secondary)),
                  ],
                ),

                const SizedBox(height: 10),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(task.dueDate),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: task.isOverdue ? FontWeight.w600 : null,
                        color: task.isOverdue ? theme.colorScheme.error : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    if (task.isOverdue) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded, size: 13, color: theme.colorScheme.error),
                    ],
                    if (blockerTitle != null && isBlocked) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.link_rounded, size: 13, color: Colors.amber),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Blocked by: $blockerTitle',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.amber),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  const _Badge(this.label, this.color, {this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.15) : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
