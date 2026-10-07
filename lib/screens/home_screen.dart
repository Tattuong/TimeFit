import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/task.dart';
import '../providers/shop_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import 'fit_screen.dart';
import 'task_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  TaskLane _lane = TaskLane.open;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(child: _body(tasks)),
            if (_tab == 0) _planBar(),
            const AdBannerSlot(),
            _BottomNav(index: _tab, onSelect: (index) => setState(() => _tab = index)),
          ],
        ),
      ),
    );
  }

  Widget _body(TaskProvider tasks) {
    return switch (_tab) {
      1 => _CalendarTab(tasks: tasks),
      2 => _StatsTab(tasks: tasks),
      3 => const _SettingsTab(),
      _ => _TodayTab(
          tasks: tasks,
          lane: _lane,
          onLane: (lane) => setState(() => _lane = lane),
          onCalendar: () => setState(() => _tab = 1),
          onProfile: () => setState(() => _tab = 3),
          onAdd: () => _openEditor(context),
          onEdit: (task) => _openEditor(context, task: task),
        ),
    };
  }

  Widget _planBar() {
    final primary = AppColors.primaryOf(context);
    final onPrimary = AppColors.onPrimaryOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FitScreen())),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Plan my time  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _openEditor(context),
                child: SizedBox(width: 44, height: 44, child: Icon(Icons.add, color: onPrimary, size: 22)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, {TaskItem? task}) async {
    final shop = context.read<ShopProvider>();
    final board = context.read<TaskProvider>();
    if (task == null && board.openCount >= shop.maxArchive) {
      AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TaskEditorScreen(task: task)));
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({
    required this.tasks,
    required this.lane,
    required this.onLane,
    required this.onCalendar,
    required this.onProfile,
    required this.onAdd,
    required this.onEdit,
  });

  final TaskProvider tasks;
  final TaskLane lane;
  final ValueChanged<TaskLane> onLane;
  final VoidCallback onCalendar;
  final VoidCallback onProfile;
  final VoidCallback onAdd;
  final ValueChanged<TaskItem> onEdit;

  @override
  Widget build(BuildContext context) {
    final items = tasks.lane(lane);
    final date = DateFormat('EEE, MMM d').format(DateTime.now()).toUpperCase();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      children: [
        Row(
          children: [
            Text('TimeFit', style: AppTypography.title(size: 22, context: context)),
            const Spacer(),
            const CoinBalanceChip(variant: CoinChipVariant.header),
            const SizedBox(width: 2),
            IconButton(visualDensity: VisualDensity.compact, onPressed: onCalendar, icon: const Icon(Icons.calendar_today_outlined, size: 22)),
            IconButton(visualDensity: VisualDensity.compact, onPressed: onProfile, icon: const Icon(Icons.person_outline_rounded, size: 24)),
          ],
        ),
        const SizedBox(height: 8),
        Text(date, style: AppTypography.labelBold(size: 12, context: context, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text('Today, at your pace', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 6),
        Text('A calmer, more focused day starts with a few good choices.', style: AppTypography.body(size: 15, context: context)),
        const SizedBox(height: 16),
        Row(
          children: [
            _LaneChip(label: 'Tasks', selected: lane == TaskLane.open, onTap: () => onLane(TaskLane.open)),
            const SizedBox(width: 8),
            _LaneChip(label: 'Done', selected: lane == TaskLane.done, onTap: () => onLane(TaskLane.done)),
            const SizedBox(width: 8),
            _LaneChip(label: 'Later', selected: lane == TaskLane.later, onTap: () => onLane(TaskLane.later)),
            const Spacer(),
            Text('${items.length} ${items.length == 1 ? 'task' : 'tasks'}', style: AppTypography.body(size: 13, context: context)),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Text(
              lane == TaskLane.open ? 'Add a task with a duration and a focus level. Then plan the time you have.' : 'Nothing here yet.',
              style: AppTypography.body(size: 15, context: context),
            ),
          ),
        for (final task in items) _TaskCard(task: task, onEdit: () => onEdit(task)),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderOf(context)),
                  ),
                  child: Icon(Icons.add, size: 18, color: AppColors.inkOf(context)),
                ),
                const SizedBox(width: 12),
                Text('Add a task', style: AppTypography.labelBold(size: 15, context: context)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LaneChip extends StatelessWidget {
  const _LaneChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(label, style: AppTypography.labelBold(size: 14, context: context, color: selected ? AppColors.inkOf(context) : AppColors.mutedInk(context))),
          const SizedBox(height: 4),
          Container(height: 3, width: 36, decoration: BoxDecoration(color: selected ? AppColors.primaryOf(context) : Colors.transparent, borderRadius: BorderRadius.circular(2))),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onEdit});

  final TaskItem task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final board = context.read<TaskProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A1C2118), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => board.setLane(task, task.lane == TaskLane.done ? TaskLane.open : TaskLane.done),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(left: 4, right: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.lane == TaskLane.done ? AppColors.primaryOf(context) : Colors.transparent,
                border: Border.all(color: AppColors.borderOf(context), width: 1.6),
              ),
              child: task.lane == TaskLane.done ? Icon(Icons.check, size: 14, color: AppColors.onPrimaryOf(context)) : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: AppTypography.title(size: 16, context: context)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: task.chipColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(task.focusLabel, style: TextStyle(color: task.chipInk, fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          Text('${task.remaining} min', style: AppTypography.labelBold(size: 14, context: context)),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.more_horiz, color: AppColors.mutedInk(context)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'later') board.setLane(task, TaskLane.later);
              if (value == 'open') board.setLane(task, TaskLane.open);
              if (value == 'delete') board.delete(task.id);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (task.lane != TaskLane.later) const PopupMenuItem(value: 'later', child: Text('Later')),
              if (task.lane != TaskLane.open) const PopupMenuItem(value: 'open', child: Text('Tasks')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({required this.tasks});

  final TaskProvider tasks;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TaskItem>>{};
    for (final task in tasks.tasks) {
      final key = task.due == null ? 'No date' : DateFormat('EEE, MMM d').format(task.due!);
      groups.putIfAbsent(key, () => []).add(task);
    }
    final keys = groups.keys.toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text('Calendar', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 6),
        Text('Tasks grouped by the day they are due.', style: AppTypography.body(size: 15, context: context)),
        const SizedBox(height: 16),
        if (keys.isEmpty) Text('Add a due date when you create a task.', style: AppTypography.body(context: context)),
        for (final key in keys) ...[
          Padding(padding: const EdgeInsets.only(top: 8, bottom: 8), child: Text(key, style: AppTypography.labelBold(context: context))),
          for (final task in groups[key]!)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(task.title),
              subtitle: Text('${task.remaining} min · ${task.focusLabel}'),
            ),
        ],
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  const _StatsTab({required this.tasks});

  final TaskProvider tasks;

  @override
  Widget build(BuildContext context) {
    final done = tasks.tasks.where((task) => task.lane == TaskLane.done).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text('Stats', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 16),
        _Stat(label: 'Minutes finished', value: '${tasks.minutesLogged}'),
        _Stat(label: 'Tasks done', value: '$done'),
        _Stat(label: 'Plans made', value: '${tasks.plansMade}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceOf(context), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.body(size: 15, context: context))),
          Text(value, style: AppTypography.title(size: 22, context: context)),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, Icons.home_rounded, 'Today'),
      (Icons.calendar_today_outlined, Icons.calendar_today, 'Calendar'),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(index == i ? items[i].$2 : items[i].$1, size: 22, color: index == i ? AppColors.inkOf(context) : AppColors.mutedInk(context)),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        style: TextStyle(fontSize: 11, fontWeight: index == i ? FontWeight.w800 : FontWeight.w600, color: index == i ? AppColors.inkOf(context) : AppColors.mutedInk(context)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 3,
                        width: 18,
                        decoration: BoxDecoration(
                          color: index == i ? AppColors.primaryOf(context) : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<ShopProvider>().coins;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        Text('Settings', style: AppTypography.display(size: 30, context: context)),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.toll_outlined),
          title: const Text('Coins'),
          trailing: Text('$coins'),
          onTap: AppTabs.goShop,
        ),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.storefront_outlined), title: Text('Shop'), onTap: AppTabs.goShop),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.tune_outlined), title: Text('Appearance'), onTap: AppTabs.goSettings),
        ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy'), onTap: () => Navigator.of(context).pushNamed('/privacy')),
      ],
    );
  }
}
