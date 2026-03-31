import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';

enum SortBy { dueDate, priority, title, createdAt }

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  late Box box;
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  int get totalCount => _tasks.length;
  int get doneCount => _tasks.where((t) => t.status == 'Done').length;
  int get inProgressCount => _tasks.where((t) => t.status == 'In Progress').length;
  int get todoCount => _tasks.where((t) => t.status == 'To-Do').length;
  int get overdueCount => _tasks.where((t) => t.isOverdue).length;
  int get urgentCount => _tasks.where((t) => t.priority == Priority.urgent && t.status != 'Done').length;
  double get completionRate => totalCount == 0 ? 0 : doneCount / totalCount;

  TaskProvider() {
    init();
  }

  Future<void> init() async {
    box = await Hive.openBox('tasksBox');
    loadTasks();
  }

  void loadTasks() {
    final data = box.get('tasks', defaultValue: []);
    _tasks = List<Map>.from(data).map((e) => Task.fromMap(e)).toList();
    notifyListeners();
  }

  void _saveTasks() {
    box.put('tasks', _tasks.map((t) => t.toMap()).toList());
  }

  List<Task> getFilteredTasks({
    String search = '',
    String statusFilter = 'All',
    String priorityFilter = 'All',
    SortBy sortBy = SortBy.dueDate,
  }) {
    var result = _tasks.where((task) {
      final q = search.toLowerCase();
      final matchSearch = task.title.toLowerCase().contains(q) ||
          task.description.toLowerCase().contains(q) ||
          task.tags.any((tag) => tag.toLowerCase().contains(q));
      final matchStatus = statusFilter == 'All' || task.status == statusFilter;
      final matchPriority = priorityFilter == 'All' ||
          task.priority.label == priorityFilter;
      return matchSearch && matchStatus && matchPriority;
    }).toList();

    result.sort((a, b) {
      switch (sortBy) {
        case SortBy.dueDate:
          return a.dueDate.compareTo(b.dueDate);
        case SortBy.priority:
          return a.priority.sortOrder.compareTo(b.priority.sortOrder);
        case SortBy.title:
          return a.title.compareTo(b.title);
        case SortBy.createdAt:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return result;
  }

  Future<void> addTask({
    required String title,
    required String description,
    required DateTime dueDate,
    required String status,
    Priority priority = Priority.medium,
    String? blockedBy,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    notifyListeners();

    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      status: status,
      priority: priority,
      blockedBy: blockedBy,
      tags: tags,
    );

    _tasks.add(newTask);
    _saveTasks();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTask(Task updatedTask) async {
    _isLoading = true;
    notifyListeners();

    int index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      if (updatedTask.status == 'Done' && _tasks[index].status != 'Done') {
        updatedTask.completedAt = DateTime.now();
      }
      _tasks[index] = updatedTask;
      _saveTasks();
    }

    _isLoading = false;
    notifyListeners();
  }

  void moveTask(String id, String newStatus) {
    int index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].status = newStatus;
      if (newStatus == 'Done') {
        _tasks[index].completedAt = DateTime.now();
      } else {
        _tasks[index].completedAt = null;
      }
      _saveTasks();
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    // Also unblock tasks that were blocked by this one
    for (var task in _tasks) {
      if (task.blockedBy == id) {
        task.blockedBy = null;
      }
    }
    _tasks.removeWhere((t) => t.id == id);
    _saveTasks();
    notifyListeners();
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isBlocked(Task task) {
    if (task.blockedBy == null) return false;
    final blocker = getTaskById(task.blockedBy!);
    return blocker != null && blocker.status != 'Done';
  }

  void duplicateTask(String id) {
    final original = getTaskById(id);
    if (original == null) return;

    final copy = Task(
      id: const Uuid().v4(),
      title: '${original.title} (copy)',
      description: original.description,
      dueDate: original.dueDate,
      status: 'To-Do',
      priority: original.priority,
      tags: List.from(original.tags),
    );

    _tasks.add(copy);
    _saveTasks();
    notifyListeners();
  }
}
