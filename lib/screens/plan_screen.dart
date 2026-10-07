import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/app_ui.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    final board = context.watch<TaskProvider>();
    final plan = board.plan;
    if (plan == null || plan.slots.isEmpty) {
      return Scaffold(
        appBar: AppBar(surfaceTintColor: Colors.transparent, centerTitle: true, title: const Text('Your plan')),
        body: const Center(child: Text('This window is empty. Add a task and find a fit again.')),
      );
    }
    final end = plan.slots.last.start.add(Duration(minutes: plan.slots.last.minutes));
    String? activeId;
    if (_started) {
      for (final slot in plan.slots) {
        if (!slot.done && !slot.isBreak) {
          activeId = slot.id;
          break;
        }
      }
    }
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Your plan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) async {
              if (value != 'clear') return;
              await board.clearPlan();
              if (context.mounted) Navigator.of(context).pop();
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'clear', child: Text('Clear this plan'))],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your ${plan.windowMinutes}-minute plan', style: AppTypography.display(size: 30, context: context)),
                const SizedBox(height: 6),
                Text(
                  plan.hasBreak ? 'A focused sequence, with a short break to keep you going.' : 'A short sequence that fits the time you have.',
                  style: AppTypography.body(size: 15, context: context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              buildDefaultDragHandles: true,
              itemCount: plan.slots.length,
              onReorder: board.reorder,
              footer: _CompleteRow(time: DateFormat('HH:mm').format(end)),
              itemBuilder: (context, index) {
                final slot = plan.slots[index];
                return _SlotTile(
                  key: ValueKey(slot.id),
                  slot: slot,
                  active: slot.id == activeId,
                  showLine: true,
                );
              },
            ),
          ),
          if (_started)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text('Tap a block when you finish it. Hold a block to move it.', style: AppTypography.body(size: 13, context: context)),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: board.replan,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: AppColors.surfaceOf(context),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Text('Replan', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _start(board),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Start', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(width: 4),
                        Icon(Icons.play_arrow_rounded, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _start(TaskProvider board) {
    final open = board.plan?.slots.any((slot) => !slot.done && !slot.isBreak) ?? false;
    if (!open) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _started = true);
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({super.key, required this.slot, required this.active, required this.showLine});

  final PlanSlot slot;
  final bool active;
  final bool showLine;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(slot.start);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = slot.done
        ? AppColors.primarySoftOf(context)
        : (dark ? (Color.lerp(AppColors.surfaceOf(context), slot.cardColor, 0.45) ?? slot.cardColor) : slot.cardColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(time, style: AppTypography.labelBold(size: 13, context: context)),
              ),
            ),
            SizedBox(
              width: 22,
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Icon(
                    slot.done ? Icons.check_circle : Icons.circle,
                    size: slot.done ? 16 : 10,
                    color: slot.done ? AppColors.primaryOf(context) : AppColors.inkOf(context),
                  ),
                  if (showLine) Expanded(child: Container(width: 1.5, color: AppColors.inkOf(context).withValues(alpha: 0.35))),
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => context.read<TaskProvider>().toggleSlot(slot),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(16),
                    border: active ? Border.all(color: AppColors.inkOf(context), width: 1.4) : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(slot.title, style: AppTypography.title(size: 16, context: context)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: slot.chipColor, borderRadius: BorderRadius.circular(10)),
                              child: Text(slot.label, style: TextStyle(color: slot.chipInk, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                            if (slot.note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(slot.note, style: AppTypography.body(size: 13, context: context)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${slot.minutes} min', style: AppTypography.labelBold(size: 13, context: context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteRow extends StatelessWidget {
  const _CompleteRow({required this.time});

  final String time;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      child: Row(
        children: [
          SizedBox(width: 52, child: Text(time, style: AppTypography.labelBold(size: 13, context: context))),
          SizedBox(
            width: 22,
            child: Icon(Icons.check_circle, color: AppColors.primaryOf(context), size: 16),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Plan complete', style: AppTypography.labelBold(context: context)),
              Text('Nice work!', style: AppTypography.body(size: 13, context: context)),
            ],
          ),
        ],
      ),
    );
  }
}
