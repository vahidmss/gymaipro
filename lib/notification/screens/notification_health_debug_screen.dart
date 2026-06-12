import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:gymaipro/notification/services/notification_fallback_sync_service.dart';

class NotificationHealthDebugScreen extends StatefulWidget {
  const NotificationHealthDebugScreen({super.key});

  @override
  State<NotificationHealthDebugScreen> createState() =>
      _NotificationHealthDebugScreenState();
}

class _NotificationHealthDebugScreenState
    extends State<NotificationHealthDebugScreen> {
  final NotificationFallbackSyncService _syncService =
      NotificationFallbackSyncService();
  Timer? _refreshTimer;
  NotificationFallbackHealthSnapshot? _snapshot;
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSnapshot());
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      unawaited(_loadSnapshot());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSnapshot() async {
    final data = await _syncService.getHealthSnapshot();
    if (!mounted) return;
    setState(() {
      _snapshot = data;
      _loading = false;
    });
  }

  Future<void> _runManualSync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await _syncService.syncOnForeground(reason: 'manual_debug');
      await _loadSnapshot();
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _copySnapshot() async {
    final snapshot = _snapshot;
    if (snapshot == null) return;

    final payload = <String, dynamic>{
      'lastSyncAt': snapshot.lastSyncAt?.toIso8601String(),
      'lastLatencyMs': snapshot.lastLatencyMs,
      'lastStatus': snapshot.lastStatus,
      'state': snapshot.state.name,
      'successCount': snapshot.successCount,
      'failureCount': snapshot.failureCount,
      'pushUnavailableCount': snapshot.pushUnavailableCount,
      'unreadNotifications': snapshot.unreadNotifications,
      'unreadChats': snapshot.unreadChats,
    };

    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snapshot copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Health'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _copySnapshot,
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy JSON snapshot',
          ),
          IconButton(
            onPressed: _loading ? null : _loadSnapshot,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh snapshot',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(snapshot),
                const SizedBox(height: 12),
                _buildMetricTile(
                  label: 'Last Sync At',
                  value: snapshot?.lastSyncAt?.toLocal().toString() ?? '-',
                ),
                _buildMetricTile(
                  label: 'Last Latency (ms)',
                  value: '${snapshot?.lastLatencyMs ?? 0}',
                ),
                _buildMetricTile(
                  label: 'Success Count',
                  value: '${snapshot?.successCount ?? 0}',
                ),
                _buildMetricTile(
                  label: 'Failure Count',
                  value: '${snapshot?.failureCount ?? 0}',
                ),
                _buildMetricTile(
                  label: 'Push Unavailable Count',
                  value: '${snapshot?.pushUnavailableCount ?? 0}',
                ),
                _buildMetricTile(
                  label: 'Unread Notifications',
                  value: '${snapshot?.unreadNotifications ?? 0}',
                ),
                _buildMetricTile(
                  label: 'Unread Chats',
                  value: '${snapshot?.unreadChats ?? 0}',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _syncing ? null : _runManualSync,
                  icon: _syncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(_syncing ? 'Running sync...' : 'Run manual sync'),
                ),
              ],
            ),
    );
  }

  Widget _buildStatusCard(NotificationFallbackHealthSnapshot? snapshot) {
    final state = snapshot?.state ?? NotificationFallbackSyncState.unknown;
    final statusText = (snapshot?.lastStatus.isNotEmpty ?? false)
        ? snapshot!.lastStatus
        : 'no_status';
    final color = switch (state) {
      NotificationFallbackSyncState.healthy => AppTheme.successColor,
      NotificationFallbackSyncState.degraded => AppTheme.fatColor,
      NotificationFallbackSyncState.error => AppTheme.errorColor,
      NotificationFallbackSyncState.skipped => Colors.blueGrey,
      NotificationFallbackSyncState.unknown => AppTheme.darkGreySeparator,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.shield_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State: ${state.name}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text('Status: $statusText'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value}) {
    return Card(
      child: ListTile(
        dense: true,
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
