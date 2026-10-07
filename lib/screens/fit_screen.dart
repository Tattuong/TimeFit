import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/app_toast.dart';
import '../widgets/app_ui.dart';
import 'plan_screen.dart';

class FitScreen extends StatefulWidget {
  const FitScreen({super.key});

  @override
  State<FitScreen> createState() => _FitScreenState();
}

class _FitScreenState extends State<FitScreen> {
  int _window = 45;
  Energy _energy = Energy.medium;
  late DateTime _start;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    var hour = now.minute == 0 ? now.hour : now.hour + 1;
    if (hour < 8 || hour > 20) hour = 14;
    _start = DateTime(now.year, now.month, now.day, hour);
  }

  @override
  Widget build(BuildContext context) {
    final label = '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}';
    final primary = AppColors.primaryOf(context);
    final onPrimary = AppColors.onPrimaryOf(context);
    final ink = AppColors.inkOf(context);
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: const Text('Find a fit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('What fits now?'),
                  content: const Text('Pick how long you have, how much energy you have, and when you start. TimeFit fills that window with tasks that match, and splits a long task into a shorter session.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                ),
              );
            },
            icon: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ink, width: 1.4)),
              child: const Text('?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        children: [
          Text('What fits now?', style: AppTypography.display(size: 32, context: context)),
          const SizedBox(height: 8),
          Text('Choose how much time you have, and we’ll find the best combination from your tasks.', style: AppTypography.body(size: 15, context: context)),
          const SizedBox(height: 24),
          Center(child: _Dial(minutes: _window, color: primary, track: AppColors.borderOf(context))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final value in const [15, 30, 45, 60])
                GestureDetector(
                  onTap: () => setState(() => _window = value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _window == value ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$value', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _window == value ? onPrimary : ink)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Text('Your current energy level', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 10),
          Row(
            children: [
              _EnergyChip(label: 'Low', icon: Icons.bedtime_outlined, selected: _energy == Energy.low, onTap: () => setState(() => _energy = Energy.low)),
              const SizedBox(width: 8),
              _EnergyChip(label: 'Medium', icon: Icons.wb_sunny_outlined, selected: _energy == Energy.medium, onTap: () => setState(() => _energy = Energy.medium)),
              const SizedBox(width: 8),
              _EnergyChip(label: 'High', icon: Icons.bolt_outlined, selected: _energy == Energy.high, onTap: () => setState(() => _energy = Energy.high)),
            ],
          ),
          const SizedBox(height: 28),
          Text('When do you want to start?', style: AppTypography.labelBold(context: context)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: SizedBox(
              height: 56,
              width: double.infinity,
              child: FilledButton(
                onPressed: _find,
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                child: const Text('Find a fit  →', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (picked == null) return;
    setState(() => _start = DateTime(_start.year, _start.month, _start.day, picked.hour, picked.minute));
  }

  Future<void> _find() async {
    final plan = await context.read<TaskProvider>().buildPlan(windowMinutes: _window, energy: _energy, start: _start);
    if (!mounted) return;
    if (plan == null) {
      AppToast.show(context, title: 'Nothing fits this window', message: 'Add an open task, or pick a longer window.');
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PlanScreen()));
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.minutes, required this.color, required this.track});

  final int minutes;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: CustomPaint(
        painter: _DialPainter(minutes / 60, color, track),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$minutes', style: AppTypography.display(size: 56, context: context)),
            Text('minutes', style: AppTypography.body(size: 16, context: context)),
          ],
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter(this.progress, this.color, this.track);

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 24;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 16;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweep = 6.28318530718 / segments;
    const gap = 0.12;
    final filled = (segments * progress).round().clamp(0, segments);
    for (var i = 0; i < segments; i++) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..color = i < filled ? color : track;
      canvas.drawArc(rect, -1.57079632679 + i * sweep + gap / 2, sweep - gap, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.track != track;
}

class _EnergyChip extends StatelessWidget {
  const _EnergyChip({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryOf(context) : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppColors.onPrimaryOf(context) : AppColors.inkOf(context)),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.onPrimaryOf(context) : AppColors.inkOf(context))),
            ],
          ),
        ),
      ),
    );
  }
}
