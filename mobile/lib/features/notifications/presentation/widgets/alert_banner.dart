import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medileger/features/notifications/data/providers/notification_providers.dart';
import 'package:medileger/features/notifications/presentation/screens/notifications_screen.dart';

class AlertsBanner extends ConsumerWidget {
  const AlertsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAlerts = ref.watch(recentAlertsProvider);
    final theme = Theme.of(context);

    if (recentAlerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.brightness == Brightness.dark
                ? const Color(0xFFAE1836)
                : const Color(0xFFD01D3F),
            theme.brightness == Brightness.dark
                ? const Color(0xFFB05304)
                : const Color(0xFFE55A00),
          ],
          stops: const [0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.25)
                : Colors.red.shade300.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withOpacity(0.1),
          highlightColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "${recentAlerts.length} ${recentAlerts.length == 1 ? 'Critical Alert' : 'Critical Alerts'} Need Attention",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
