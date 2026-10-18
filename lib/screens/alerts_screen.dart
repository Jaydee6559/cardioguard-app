import 'package:flutter/material.dart';

import '../data/app_state.dart';
import '../data/mock_data.dart';
import '../models/alert_event.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/event_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/severity_badge.dart';

/// Screen 04 — Alerts & Events (Alerts tab).
///
/// Newest-first list with filter chips. Tap an event for its details.
/// Events are saved on the phone; the emergency flow adds new ones.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  Severity? _filter; // null = All

  List<AlertEvent> _visible(List<AlertEvent> events) =>
      _filter == null ? events : events.where((e) => e.severity == _filter).toList();

  int _count(List<AlertEvent> events, Severity? s) =>
      s == null ? events.length : events.where((e) => e.severity == s).length;

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all events?'),
        content: const Text('This permanently removes the whole Alerts & Events history from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await AppState.clearEvents();
  }

  void _showDetails(AlertEvent e) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SeverityDot(e.severity),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  ),
                  SeverityBadge(e.severity),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow('What happened', e.description),
              _DetailRow('When', '${Formatters.date(e.time)} at ${Formatters.clock(e.time)}'),
              _DetailRow('Wearer', MockData.wearerName),
              _DetailRow('Next step', _nextStep(e.severity)),
            ],
          ),
        ),
      ),
    );
  }

  String _nextStep(Severity s) => switch (s) {
        Severity.emergency => 'Check on the wearer immediately or call their emergency contact.',
        Severity.warning => 'Keep an eye on the wearer and check the Vitals tab.',
        Severity.info => 'No action needed. Kept for your records.',
      };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AlertEvent>>(
      valueListenable: AppState.events,
      builder: (context, events, _) {
        final visible = _visible(events);
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              ScreenHeader(
                kicker: 'History',
                title: 'Alerts & Events',
                trailing: events.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear history',
                        onPressed: _clearHistory,
                        icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textMuted),
                      ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('All', null, events),
                    _chip('Emergency', Severity.emergency, events),
                    _chip('Warning', Severity.warning, events),
                    _chip('Info', Severity.info, events),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.textFaint),
                      SizedBox(height: 10),
                      Text('No events here', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                )
              else
                for (final e in visible) ...[
                  EventCard(e, onTap: () => _showDetails(e)),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _chip(String label, Severity? severity, List<AlertEvent> events) {
    final selected = _filter == severity;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label (${_count(events, severity)})'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = severity),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primary : AppColors.cardBorder),
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.textLabel,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

/// Label + value in the details sheet.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
        ],
      ),
    );
  }
}
