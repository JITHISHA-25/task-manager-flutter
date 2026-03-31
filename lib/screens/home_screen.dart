import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/stats_bar.dart';
import '../widgets/task_card.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String search = '';
  String statusFilter = 'All';
  String priorityFilter = 'All';
  SortBy sortBy = SortBy.dueDate;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final filtered = provider.getFilteredTasks(
      search: search,
      statusFilter: statusFilter,
      priorityFilter: priorityFilter,
      sortBy: sortBy,
    );
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Task Manager',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Text(
                          '${provider.totalCount} tasks · ${(provider.completionRate * 100).toInt()}% complete',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(context),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('New'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Stats
            const StatsBar(),

            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search tasks, tags...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => setState(() => search = val),
              ),
            ),

            const SizedBox(height: 10),

            // Filters row
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: statusFilter == 'All' ? 'All Status' : statusFilter,
                    icon: Icons.filter_list_rounded,
                    onTap: () => _showStatusFilter(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: priorityFilter == 'All' ? 'All Priority' : priorityFilter,
                    icon: Icons.flag_rounded,
                    onTap: () => _showPriorityFilter(context),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: _sortLabel(),
                    icon: Icons.sort_rounded,
                    onTap: () => _showSortOptions(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Task list
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.task_alt, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.15)),
                          const SizedBox(height: 12),
                          Text('No tasks found', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          const SizedBox(height: 4),
                          Text('Create a new task to get started', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.3))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final t = filtered[i];
                        final blocked = provider.isBlocked(t);
                        final blockerTitle = t.blockedBy != null
                            ? provider.getTaskById(t.blockedBy!)?.title
                            : null;

                        return TaskCard(
                          task: t,
                          isBlocked: blocked,
                          blockerTitle: blockerTitle,
                          onTap: () => _openForm(context, task: t),
                          onDelete: () => _confirmDelete(context, provider, t.id),
                          onDuplicate: () => provider.duplicateTask(t.id),
                          onStatusChange: (status) => provider.moveTask(t.id, status),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, {Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
  }

  void _confirmDelete(BuildContext context, TaskProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.deleteTask(id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _sortLabel() {
    switch (sortBy) {
      case SortBy.dueDate: return 'Due Date';
      case SortBy.priority: return 'Priority';
      case SortBy.title: return 'Title';
      case SortBy.createdAt: return 'Newest';
    }
  }

  void _showStatusFilter(BuildContext context) {
    _showBottomSheet(context, 'Filter by Status', ['All', 'To-Do', 'In Progress', 'Done'], statusFilter, (val) {
      setState(() => statusFilter = val);
    });
  }

  void _showPriorityFilter(BuildContext context) {
    _showBottomSheet(context, 'Filter by Priority', ['All', 'Low', 'Medium', 'High', 'Urgent'], priorityFilter, (val) {
      setState(() => priorityFilter = val);
    });
  }

  void _showSortOptions(BuildContext context) {
    _showBottomSheet(context, 'Sort by', ['Due Date', 'Priority', 'Title', 'Newest'], _sortLabel(), (val) {
      setState(() {
        sortBy = {
          'Due Date': SortBy.dueDate,
          'Priority': SortBy.priority,
          'Title': SortBy.title,
          'Newest': SortBy.createdAt,
        }[val]!;
      });
    });
  }

  void _showBottomSheet(BuildContext context, String title, List<String> options, String current, Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...options.map((opt) => ListTile(
              title: Text(opt),
              trailing: opt == current ? const Icon(Icons.check, color: Colors.blue) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                onSelect(opt);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}
