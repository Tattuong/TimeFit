import 'package:flutter/material.dart';

enum TaskFocus { deep, admin, light }

enum TaskLane { open, done, later }

enum Energy { low, medium, high }

class TaskItem {
  final String id;
  String title;
  String note;
  int minutes;
  int remaining;
  DateTime? due;
  TaskFocus focus;
  TaskLane lane;
  bool rewarded;

  TaskItem({
    required this.id,
    required this.title,
    this.note = '',
    required this.minutes,
    int? remaining,
    this.due,
    required this.focus,
    this.lane = TaskLane.open,
    this.rewarded = false,
  }) : remaining = remaining ?? minutes;

  String get focusLabel => switch (focus) {
        TaskFocus.deep => 'Deep work',
        TaskFocus.admin => 'Admin',
        TaskFocus.light => 'Light focus',
      };

  Color get chipColor => switch (focus) {
        TaskFocus.deep => const Color(0xFFE5F6C8),
        TaskFocus.admin => const Color(0xFFE3F1FB),
        TaskFocus.light => const Color(0xFFF3E6FA),
      };

  Color get chipInk => switch (focus) {
        TaskFocus.deep => const Color(0xFF3E6B16),
        TaskFocus.admin => const Color(0xFF2F6394),
        TaskFocus.light => const Color(0xFF7A4A93),
      };

  Color get cardColor => switch (focus) {
        TaskFocus.deep => const Color(0xFFF3FBE4),
        TaskFocus.admin => const Color(0xFFEEF6FC),
        TaskFocus.light => const Color(0xFFF8F1FB),
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'minutes': minutes,
        'remaining': remaining,
        'due': due?.toIso8601String(),
        'focus': focus.name,
        'lane': lane.name,
        'rewarded': rewarded,
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        note: json['note'] as String? ?? '',
        minutes: json['minutes'] as int? ?? 15,
        remaining: json['remaining'] as int? ?? json['minutes'] as int? ?? 15,
        due: DateTime.tryParse(json['due'] as String? ?? ''),
        focus: TaskFocus.values.byName(json['focus'] as String? ?? 'admin'),
        lane: TaskLane.values.byName(json['lane'] as String? ?? 'open'),
        rewarded: json['rewarded'] as bool? ?? false,
      );
}

class PlanSlot {
  final String id;
  final String? taskId;
  final String title;
  final String note;
  final int minutes;
  final TaskFocus? focus;
  final bool isBreak;
  DateTime start;
  bool done;

  PlanSlot({
    required this.id,
    this.taskId,
    required this.title,
    this.note = '',
    required this.minutes,
    this.focus,
    this.isBreak = false,
    required this.start,
    this.done = false,
  });

  Color get cardColor {
    if (isBreak) return const Color(0xFFF3FBE6);
    return switch (focus) {
      TaskFocus.admin => const Color(0xFFE5F2FC),
      TaskFocus.light => const Color(0xFFF6EEFB),
      _ => const Color(0xFFE7F6C9),
    };
  }

  Color get chipColor {
    if (isBreak) return const Color(0xFFDDF3C4);
    return switch (focus) {
      TaskFocus.admin => const Color(0xFFD5E9F8),
      TaskFocus.light => const Color(0xFFEBD8F6),
      _ => const Color(0xFFD7EFB0),
    };
  }

  Color get chipInk {
    if (isBreak) return const Color(0xFF4E7A1E);
    return switch (focus) {
      TaskFocus.admin => const Color(0xFF2F6394),
      TaskFocus.light => const Color(0xFF7A4A93),
      _ => const Color(0xFF3E6B16),
    };
  }

  String get label => isBreak ? 'Recharge' : (focus == TaskFocus.deep ? 'Deep work' : focus == TaskFocus.admin ? 'Admin' : 'Light focus');

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'title': title,
        'note': note,
        'minutes': minutes,
        'focus': focus?.name,
        'isBreak': isBreak,
        'start': start.toIso8601String(),
        'done': done,
      };

  factory PlanSlot.fromJson(Map<String, dynamic> json) => PlanSlot(
        id: json['id'] as String? ?? '',
        taskId: json['taskId'] as String?,
        title: json['title'] as String? ?? '',
        note: json['note'] as String? ?? '',
        minutes: json['minutes'] as int? ?? 5,
        focus: json['focus'] == null ? null : TaskFocus.values.byName(json['focus'] as String),
        isBreak: json['isBreak'] as bool? ?? false,
        start: DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
        done: json['done'] as bool? ?? false,
      );
}

class FitPlan {
  final int windowMinutes;
  final Energy energy;
  final DateTime start;
  List<PlanSlot> slots;

  FitPlan({
    required this.windowMinutes,
    required this.energy,
    required this.start,
    required this.slots,
  });

  int get scheduledMinutes => slots.fold(0, (sum, slot) => sum + slot.minutes);

  bool get hasBreak => slots.any((slot) => slot.isBreak);

  Map<String, dynamic> toJson() => {
        'windowMinutes': windowMinutes,
        'energy': energy.name,
        'start': start.toIso8601String(),
        'slots': [for (final slot in slots) slot.toJson()],
      };

  factory FitPlan.fromJson(Map<String, dynamic> json) => FitPlan(
        windowMinutes: json['windowMinutes'] as int? ?? 45,
        energy: Energy.values.byName(json['energy'] as String? ?? 'medium'),
        start: DateTime.tryParse(json['start'] as String? ?? '') ?? DateTime.now(),
        slots: [
          for (final item in (json['slots'] as List? ?? const [])) PlanSlot.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
      );
}

class Planner {
  static FitPlan fit({
    required List<TaskItem> tasks,
    required int windowMinutes,
    required Energy energy,
    required DateTime start,
  }) {
    final pool = tasks.where((task) => task.lane == TaskLane.open && task.remaining > 0).toList()
      ..sort((a, b) {
        final due = _dueRank(a).compareTo(_dueRank(b));
        if (due != 0) return due;
        final focus = _focusRank(a.focus, energy).compareTo(_focusRank(b.focus, energy));
        if (focus != 0) return focus;
        return a.remaining.compareTo(b.remaining);
      });

    final slices = <({TaskItem task, int minutes})>[];
    var used = 0;
    for (final task in pool) {
      if (energy == Energy.low && task.focus == TaskFocus.deep) continue;
      final anotherFits = pool.any((other) => other.id != task.id && other.remaining >= 10 && (energy != Energy.low || other.focus != TaskFocus.deep));
      var budget = windowMinutes - used;
      if (slices.isEmpty && anotherFits && windowMinutes >= 40) budget -= 5;
      if (budget < 10) break;
      var take = task.remaining < budget ? task.remaining : budget;
      if (energy == Energy.medium && task.focus == TaskFocus.deep && slices.isEmpty && anotherFits) {
        final cap = windowMinutes - 20;
        if (take > cap) take = cap;
      }
      if (take < 10) continue;
      slices.add((task: task, minutes: take));
      used += take;
      if (windowMinutes - used < 10) break;
    }

    final slots = <PlanSlot>[];
    var cursor = start;
    final withBreak = slices.length >= 2 && used + 5 <= windowMinutes;
    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      slots.add(_work(slice.task, slice.minutes, cursor, i));
      cursor = cursor.add(Duration(minutes: slice.minutes));
      if (withBreak && i == 0) {
        slots.add(PlanSlot(id: 'break', title: 'Break', note: 'Stretch, breathe, and reset.', minutes: 5, isBreak: true, start: cursor));
        cursor = cursor.add(const Duration(minutes: 5));
      }
    }
    return FitPlan(windowMinutes: windowMinutes, energy: energy, start: start, slots: slots);
  }

  static List<PlanSlot> retime(List<PlanSlot> slots, DateTime start) {
    var cursor = start;
    for (final slot in slots) {
      slot.start = cursor;
      cursor = cursor.add(Duration(minutes: slot.minutes));
    }
    return slots;
  }

  static int _dueRank(TaskItem task) {
    if (task.due == null) return 2;
    final today = DateTime.now();
    final due = DateTime(task.due!.year, task.due!.month, task.due!.day);
    final day = DateTime(today.year, today.month, today.day);
    if (!due.isAfter(day)) return 0;
    return 1;
  }

  static int _focusRank(TaskFocus focus, Energy energy) => switch (energy) {
        Energy.high => switch (focus) {
            TaskFocus.deep => 0,
            TaskFocus.admin => 1,
            TaskFocus.light => 2,
          },
        Energy.medium => switch (focus) {
            TaskFocus.deep => 0,
            TaskFocus.admin => 1,
            TaskFocus.light => 2,
          },
        Energy.low => switch (focus) {
            TaskFocus.light => 0,
            TaskFocus.admin => 1,
            TaskFocus.deep => 2,
          },
      };

  static PlanSlot _work(TaskItem task, int minutes, DateTime start, int index) => PlanSlot(
        id: '${task.id}-$index',
        taskId: task.id,
        title: task.title,
        note: task.note,
        minutes: minutes,
        focus: task.focus,
        start: start,
      );
}
