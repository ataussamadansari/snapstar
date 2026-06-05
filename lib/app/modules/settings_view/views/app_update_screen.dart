import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/shorebird_service.dart';

class AppUpdateScreen extends StatelessWidget {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ShorebirdService globally registered hai AppBindings mein
    final shorebird = Get.find<ShorebirdService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Update')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Obx(() {
          final current = shorebird.currentPatchNumber.value;
          final downloaded = shorebird.downloadedPatchNumber.value;
          final isChecking = shorebird.isChecking.value;
          final isDownloading = shorebird.isDownloading.value;
          final status = shorebird.statusMessage.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Version Info Card ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Version',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '1.0.3 (Build 3)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 24),

                    // Current patch
                    _InfoRow(
                      label: 'Active Patch',
                      value: current != null ? '#$current' : 'Base build',
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green,
                    ),

                    // Downloaded patch (pending restart)
                    if (downloaded != null && downloaded != current) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        label: 'Pending Patch',
                        value: '#$downloaded (restart required)',
                        icon: Icons.pending_outlined,
                        iconColor: Colors.orange,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Status Message ──────────────────────────────────────────
              if (status.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _statusIcon(status),
                        size: 16,
                        color: _statusColor(status),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 13,
                            color: _statusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ─── Download Progress ───────────────────────────────────────
              if (isDownloading) ...[
                const Text(
                  'Downloading patch...',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // ─── Check Button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (isChecking || isDownloading)
                      ? null
                      : shorebird.checkForUpdate,
                  icon: isChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.system_update_alt_rounded),
                  label: Text(
                    isChecking
                        ? 'Checking...'
                        : isDownloading
                        ? 'Downloading...'
                        : 'Check for Updates',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ─── Info Note ───────────────────────────────────────────────
              Text(
                'Updates automatically apply when you restart the app.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _statusColor(String status) {
    if (status.contains('failed') || status.contains('error')) {
      return Colors.red;
    }
    if (status.contains('up to date') || status.contains('successfully')) {
      return Colors.green;
    }
    if (status.contains('restart') || status.contains('Pending')) {
      return Colors.orange;
    }
    return Colors.teal;
  }

  IconData _statusIcon(String status) {
    if (status.contains('failed') || status.contains('error')) {
      return Icons.error_outline;
    }
    if (status.contains('up to date') || status.contains('successfully')) {
      return Icons.check_circle_outline;
    }
    if (status.contains('restart')) {
      return Icons.restart_alt;
    }
    if (status.contains('Downloading') || status.contains('available')) {
      return Icons.download_outlined;
    }
    return Icons.info_outline;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
