import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../../shared/widgets/widgets.dart';

/// Play Store / App Store policy-compliant disclosure for background location.
///
/// Reachable at `Routes.backgroundLocationConsent`. Future iterations
/// (trek session + SOS) will push this page before requesting
/// `ACCESS_BACKGROUND_LOCATION` on Android or `always` on iOS.
///
/// The page pops with `true` on Allow, `false` on Not now.
class BackgroundLocationDisclosurePage extends StatelessWidget {
  const BackgroundLocationDisclosurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final body = text.bodyLarge?.copyWith(
      color: AppColors.slate700,
      height: 1.5,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop<bool>(false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Icon(
                  Icons.shield_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Why Mountain Explorer needs background location',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To keep you safe on remote treks, Mountain '
                          'Explorer can record a trail of your location '
                          'points (latitude, longitude, accuracy, and '
                          'altitude) while a trek is active, even when the '
                          'app is in the background or your screen is off.',
                          style: body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'When you trigger SOS, those points are sent with '
                          'your current position and battery level to the '
                          'emergency contacts you have added. Delivery '
                          'happens via SMS on your phone and via Firebase, a '
                          'third-party cloud database operated by Google, to '
                          'contacts who also use Mountain Explorer.',
                          style: body,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'You can stop a trek or cancel an SOS at any time '
                          '— background location tracking stops immediately '
                          'when you do. You can also revoke this permission '
                          'anytime from your device Settings.',
                          style: body,
                        ),
                        if (!kIsWeb && Platform.isIOS) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            "iOS will show its own location prompts next: "
                            "choose 'Allow While Using App' on the first "
                            "prompt, then on the second prompt choose "
                            "'Allow Always' so the trail keeps recording in "
                            'the background.',
                            style: body,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Allow background location',
                  onPressed: () => Navigator.of(context).pop<bool>(true),
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Not now',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pop<bool>(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
