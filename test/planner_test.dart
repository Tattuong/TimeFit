import 'package:flutter_test/flutter_test.dart';
import 'package:timefit/models/task.dart';

TaskItem _task(String id, int minutes, TaskFocus focus) => TaskItem(id: id, title: id, minutes: minutes, focus: focus);

void main() {
  final start = DateTime(2026, 4, 23, 14);

  test('45 medium fits deep, a break, then admin', () {
    final plan = Planner.fit(
      tasks: [
        _task('deep', 25, TaskFocus.deep),
        _task('admin', 15, TaskFocus.admin),
        _task('light', 20, TaskFocus.light),
      ],
      windowMinutes: 45,
      energy: Energy.medium,
      start: start,
    );
    expect(plan.slots.map((slot) => slot.minutes).toList(), [25, 5, 15]);
    expect(plan.slots[0].focus, TaskFocus.deep);
    expect(plan.slots[1].isBreak, isTrue);
    expect(plan.slots[2].focus, TaskFocus.admin);
    expect(plan.slots[2].start, start.add(const Duration(minutes: 30)));
  });

  test('a task longer than the window is split', () {
    final plan = Planner.fit(
      tasks: [_task('long', 60, TaskFocus.admin)],
      windowMinutes: 45,
      energy: Energy.medium,
      start: start,
    );
    expect(plan.slots, hasLength(1));
    expect(plan.slots.single.minutes, 45);
    expect(plan.slots.single.isBreak, isFalse);
  });

  test('low energy skips deep work', () {
    final plan = Planner.fit(
      tasks: [
        _task('deep', 25, TaskFocus.deep),
        _task('admin', 15, TaskFocus.admin),
      ],
      windowMinutes: 45,
      energy: Energy.low,
      start: start,
    );
    expect(plan.slots.every((slot) => slot.focus != TaskFocus.deep), isTrue);
    expect(plan.slots.first.focus, TaskFocus.admin);
  });

  test('high energy leads with deep work', () {
    final plan = Planner.fit(
      tasks: [
        _task('light', 20, TaskFocus.light),
        _task('deep', 25, TaskFocus.deep),
      ],
      windowMinutes: 45,
      energy: Energy.high,
      start: start,
    );
    expect(plan.slots.first.focus, TaskFocus.deep);
  });
}
