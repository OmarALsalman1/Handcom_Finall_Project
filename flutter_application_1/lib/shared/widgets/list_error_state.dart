import 'package:flutter/material.dart';
import 'package:handcom/core/l10n/app_strings.dart';

/// Shown instead of an empty list when a list fetch failed, with a
/// localized message (via [AppStrings.errorMessage]) and a retry button.
class ListErrorState extends StatelessWidget {
  final String? errorCode;
  final VoidCallback onRetry;
  final Color textColor;

  const ListErrorState({
    super.key,
    required this.errorCode,
    required this.onRetry,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40, color: textColor.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.l10n.errorMessage(errorCode),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}
