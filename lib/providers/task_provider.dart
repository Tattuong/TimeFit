import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../core/services/storage_service.dart';
import 'shop_provider.dart';

class TaskProvider extends ChangeNotifier {
  static const _tasksKey = 'tf_tasks';
  static const _planKey = 'tf_plan';
  static const _statsKey = 'tf_stats';

  final ShopProvider shop;
  final List<TaskItem> tasks = [];
  FitPlan? plan;
  int plansMade = 0;
  int minutesLogged = 0;

  TaskProvider(this.shop);

  List<TaskItem> lane(TaskLane value) => tasks.where((task) => task.lane == value).toList();

  int get openCount => tasks.where((task) => task.lane != TaskLane.done).length;

  int get doneMinutes => tasks.where((task) => task.lane == TaskLane.done).fold(0, (sum, task) => sum + task.minutes);

  Future<void> init() async {
    tasks.clear();
    plan = null;
    final raw = await StorageService.instance.getString(_tasksKey);
    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      tasks.addAll(list.map((item) => TaskItem.fromJson(Map<String, dynamic>.from(item as Map))));
    }
    final rawPlan = await StorageService.instance.getString(_planKey);
    if (rawPlan != null && rawPlan.isNotEmpty) {
      plan = FitPlan.fromJson(Map<String, dynamic>.from(jsonDecode(rawPlan) as Map));
    }
    final rawStats = await StorageService.instance.getString(_statsKey);
    if (rawStats != null && rawStats.isNotEmpty) {
      final map = Map<String, dynamic>.from(jsonDecode(rawStats) as Map);
      plansMade = map['plansMade'] as int? ?? 0;
      minutesLogged = map['minutesLogged'] as int? ?? 0;
    }
    notifyListeners();
  }

  Future<TaskItem?> add(TaskItem task) async {
    if (openCount >= shop.maxArchive) return null;
    tasks.insert(0, task);
    await _saveTasks();
    notifyListeners();
    return task;
  }

  Future<void> update(TaskItem task) async {
    await _saveTasks();
    notifyListeners();
  }

  Future<void> setLane(TaskItem task, TaskLane lane) async {
    task.lane = lane;
    if (lane == TaskLane.done) {
      task.remaining = 0;
      await _reward(task);
    } else if (task.remaining == 0) {
      task.remaining = task.minutes;
    }
    await _saveTasks();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    tasks.removeWhere((task) => task.id == id);
    final current = plan;
    if (current != null) {
      current.slots.removeWhere((slot) => slot.taskId == id);
      final stillWorking = current.slots.any((slot) => !slot.isBreak);
      if (!stillWorking) {
        plan = null;
      } else {
        Planner.retime(current.slots, current.start);
      }
    }
    await _saveTasks();
    await _savePlan();
    notifyListeners();
  }

  Future<void> clearPlan() async {
    plan = null;
    await _savePlan();
    notifyListeners();
  }

  Future<FitPlan?> buildPlan({required int windowMinutes, required Energy energy, required DateTime start}) async {
    final next = Planner.fit(tasks: tasks, windowMinutes: windowMinutes, energy: energy, start: start);
    if (next.slots.isEmpty) return null;
    plan = next;
    plansMade += 1;
    await _saveStats();
    await _savePlan();
    notifyListeners();
    return next;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = plan;
    if (current == null) return;
    if (newIndex > oldIndex) newIndex -= 1;
    final slot = current.slots.removeAt(oldIndex);
    current.slots.insert(newIndex, slot);
    Planner.retime(current.slots, current.start);
    await _savePlan();
    notifyListeners();
  }

  Future<void> replan() async {
    final current = plan;
    if (current == null) return;
    final next = Planner.fit(tasks: tasks, windowMinutes: current.windowMinutes, energy: current.energy, start: current.start);
    plan = next.slots.isEmpty ? null : next;
    await _savePlan();
    notifyListeners();
  }

  Future<void> toggleSlot(PlanSlot slot) async {
    final task = slot.taskId == null ? null : _find(slot.taskId!);
    if (!slot.done) {
      slot.done = true;
      if (!slot.isBreak) minutesLogged += slot.minutes;
      if (task != null) {
        task.remaining = (task.remaining - slot.minutes).clamp(0, task.minutes);
        if (task.remaining == 0) {
          task.lane = TaskLane.done;
          await _reward(task);
        }
      }
    } else {
      slot.done = false;
      if (!slot.isBreak) minutesLogged = (minutesLogged - slot.minutes).clamp(0, 1 << 30);
      if (task != null) {
        task.remaining = (task.remaining + slot.minutes).clamp(0, task.minutes);
        if (task.lane == TaskLane.done) task.lane = TaskLane.open;
      }
    }
    await _saveTasks();
    await _savePlan();
    await _saveStats();
    notifyListeners();
  }

  TaskItem? _find(String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<void> _reward(TaskItem task) async {
    if (task.rewarded) return;
    task.rewarded = true;
    await shop.rewardForTask();
  }

  Future<void> _saveTasks() async {
    await StorageService.instance.saveString(_tasksKey, jsonEncode([for (final task in tasks) task.toJson()]));
  }

  Future<void> _saveStats() async {
    await StorageService.instance.saveString(_statsKey, jsonEncode({'plansMade': plansMade, 'minutesLogged': minutesLogged}));
  }

  Future<void> _savePlan() async {
    if (plan == null) {
      await StorageService.instance.remove(_planKey);
      return;
    }
    await StorageService.instance.saveString(_planKey, jsonEncode(plan!.toJson()));
  }
}

TaskItem newTask({
  required String title,
  required String note,
  required int minutes,
  DateTime? due,
  required TaskFocus focus,
}) {
  return TaskItem(id: const Uuid().v4(), title: title, note: note, minutes: minutes, due: due, focus: focus);
}
