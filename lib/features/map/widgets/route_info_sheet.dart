import 'package:flutter/material.dart';
import 'package:contact_navigator/core/theme/app_theme.dart';
import 'package:contact_navigator/core/utils/map_utils.dart';

class RouteInfoSheet extends StatelessWidget {
  final RouteInfo routeInfo;
  final bool isLoading;
  final VoidCallback onClose;

  const RouteInfoSheet({
    super.key,
    required this.routeInfo,
    required this.isLoading,
    required this.onClose,
  });

  bool get _isWalking => routeInfo.profile == 'walking';

  Color get _accentColor => _isWalking ? Colors.green : AppColors.primaryBlue;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Material(
      elevation: 16,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      shadowColor: Colors.black26,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    routeInfo.profileIcon,
                    color: _accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              routeInfo.formattedDuration,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1C1E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${routeInfo.formattedDistance} • ${routeInfo.profileLabel}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
                IconButton(
                  onPressed: isLoading ? null : onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
