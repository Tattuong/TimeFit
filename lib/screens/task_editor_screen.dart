import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.task});

  final TaskItem? task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late int _minutes;
  late TaskFocus _focus;
  DateTime? _due;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _note = TextEditingController(text: task?.note ?? '');
    _minutes = task?.minutes ?? 25;
    _focus = task?.focus ?? TaskFocus.deep;
    _due = task?.due;
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryOf(context);
    final onPrimary = AppColors.onPrimaryOf(context);
    final ink = AppColors.inkOf(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(widget.task == null ? 'Add a task' : 'Edit task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title', filled: true),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text('Estimated time', style: AppTypography.labelBold(context: context)),
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _minutes = (_minutes - 5).clamp(5, 240)), icon: const Icon(Icons.remove_circle_outline)),
              Text('$_minutes min', style: AppTypography.title(size: 18, context: context)),
              IconButton(onPressed: () => setState(() => _minutes = (_minutes + 5).clamp(5, 240)), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Focus', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final focus in TaskFocus.values)
                ChoiceChip(
                  label: Text(
                    focus == TaskFocus.deep ? 'Deep work' : focus == TaskFocus.admin ? 'Admin' : 'Light focus',
                    style: TextStyle(fontWeight: FontWeight.w700, color: _focus == focus ? onPrimary : ink),
                  ),
                  selected: _focus == focus,
                  showCheckmark: false,
                  selectedColor: primary,
                  backgroundColor: AppColors.surfaceOf(context),
                  onSelected: (_) => setState(() => _focus = focus),
                ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due date'),
            subtitle: Text(_due == null ? 'Optional' : DateFormat('EEE, MMM d').format(_due!)),
            trailing: _due == null
                ? const Icon(Icons.event_outlined)
                : IconButton(onPressed: () => setState(() => _due = null), icon: const Icon(Icons.close)),
            onTap: _pickDue,
          ),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note', filled: true),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(context: context, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: _due ?? DateTime.now());
    if (picked == null) return;
    setState(() => _due = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      AppToast.show(context, title: 'Add a title first');
      return;
    }
    final board = context.read<TaskProvider>();
    final existing = widget.task;
    if (existing == null) {
      final created = await board.add(newTask(title: title, note: _note.text.trim(), minutes: _minutes, due: _due, focus: _focus));
      if (!mounted) return;
      if (created == null) {
        AppToast.show(context, title: 'Unlock TimeFit Pro to keep more tasks.');
        return;
      }
    } else {
      final delta = _minutes - existing.minutes;
      existing.title = title;
      existing.note = _note.text.trim();
      existing.minutes = _minutes;
      existing.remaining = (existing.remaining + delta).clamp(0, _minutes);
      existing.due = _due;
      existing.focus = _focus;
      await board.update(existing);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
