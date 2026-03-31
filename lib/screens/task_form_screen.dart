import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final tagController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String status = 'To-Do';
  Priority priority = Priority.medium;
  String? blockedBy;
  List<String> tags = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      titleController.text = widget.task!.title;
      descController.text = widget.task!.description;
      selectedDate = widget.task!.dueDate;
      status = widget.task!.status;
      priority = widget.task!.priority;
      blockedBy = widget.task!.blockedBy;
      tags = List.from(widget.task!.tags);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final t = tagController.text.trim();
    if (t.isNotEmpty && !tags.contains(t)) {
      setState(() => tags.add(t));
    }
    tagController.clear();
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    final provider = Provider.of<TaskProvider>(context, listen: false);

    if (widget.task == null) {
      await provider.addTask(
        title: titleController.text,
        description: descController.text,
        dueDate: selectedDate,
        status: status,
        priority: priority,
        blockedBy: blockedBy,
        tags: tags,
      );
    } else {
      final updated = widget.task!;
      updated.title = titleController.text;
      updated.description = descController.text;
      updated.dueDate = selectedDate;
      updated.status = status;
      updated.priority = priority;
      updated.blockedBy = blockedBy;
      updated.tags = tags;
      await provider.updateTask(updated);
    }

    if (mounted) {
      setState(() => loading = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TaskProvider>(context);
    final theme = Theme.of(context);
    final availableBlockers = provider.tasks.where((t) => t.id != widget.task?.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New Task' : 'Edit Task'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            _SectionLabel('Title'),
            const SizedBox(height: 6),
            TextFormField(
              controller: titleController,
              decoration: _inputDecoration('Enter task title...'),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Title is required' : null,
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20),

            // Description
            _SectionLabel('Description'),
            const SizedBox(height: 6),
            TextFormField(
              controller: descController,
              decoration: _inputDecoration('Describe the task...'),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),

            const SizedBox(height: 20),

            // Due Date
            _SectionLabel('Due Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: const TextStyle(fontSize: 15)),
                    const Spacer(),
                    Icon(Icons.edit_rounded, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Status & Priority row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Status'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: _inputDecoration(''),
                        items: ['To-Do', 'In Progress', 'Done']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => status = val!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel('Priority'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<Priority>(
                        value: priority,
                        decoration: _inputDecoration(''),
                        items: Priority.values
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                            .toList(),
                        onChanged: (val) => setState(() => priority = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Blocked By
            _SectionLabel('Blocked By (optional)'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              value: blockedBy,
              decoration: _inputDecoration(''),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...availableBlockers.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))),
              ],
              onChanged: (val) => setState(() => blockedBy = val),
            ),

            const SizedBox(height: 20),

            // Tags
            _SectionLabel('Tags'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: _inputDecoration('Add a tag...'),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add, size: 20),
                ),
              ],
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags
                      .map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() => tags.remove(tag)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : _saveTask,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(
                        widget.task == null ? 'Create Task' : 'Update Task',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}
