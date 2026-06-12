import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showBack)
              IconButton(
                onPressed: onBack ?? () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              )
            else
              const SizedBox(width: 48), // يحافظ على تمركز العنوان

            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}