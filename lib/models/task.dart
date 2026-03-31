enum Priority { low, medium, high, urgent }

extension PriorityExtension on Priority {
  String get label {
    switch (this) {
      case Priority.low: return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high: return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  int get sortOrder {
    switch (this) {
      case Priority.urgent: return 0;
      case Priority.high: return 1;
      case Priority.medium: return 2;
      case Priority.low: return 3;
    }
  }
}

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  String status;
  Priority priority;
  String? blockedBy;
  DateTime createdAt;
  DateTime? completedAt;
  List<String> tags;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.priority = Priority.medium,
    this.blockedBy,
    DateTime? createdAt,
    this.completedAt,
    List<String>? tags,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? [];

  bool get isOverdue =>
      status != 'Done' && dueDate.isBefore(DateTime.now().copyWith(hour: 0, minute: 0, second: 0));

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'priority': priority.index,
        'blockedBy': blockedBy,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'tags': tags,
      };

  factory Task.fromMap(Map<dynamic, dynamic> e) => Task(
        id: e['id'],
        title: e['title'],
        description: e['description'],
        dueDate: DateTime.parse(e['dueDate']),
        status: e['status'],
        priority: Priority.values[e['priority'] ?? 2],
        blockedBy: e['blockedBy'],
        createdAt: e['createdAt'] != null ? DateTime.parse(e['createdAt']) : null,
        completedAt: e['completedAt'] != null ? DateTime.parse(e['completedAt']) : null,
        tags: List<String>.from(e['tags'] ?? []),
      );
}
