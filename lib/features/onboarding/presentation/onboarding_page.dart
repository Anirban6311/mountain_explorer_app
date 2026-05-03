import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/router/routes.dart';
import '../../../core/di/injector.dart';
import '../../../core/storage/app_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/widgets.dart';

class _OnboardingSlide {
  final String image;
  final String title;
  final String description;
  const _OnboardingSlide({
    required this.image,
    required this.title,
    required this.description,
  });
}

const _slides = [
  _OnboardingSlide(
    image: 'assets/Images/841083_688.jpg',
    title: 'Mountains calling',
    description: 'Discover hill stations, weather, and stories from the trail.',
  ),
  _OnboardingSlide(
    image: 'assets/Images/2.jpg',
    title: 'Community of trekkers',
    description: 'Connect with trekkers worldwide and share your journey.',
  ),
  _OnboardingSlide(
    image: 'assets/Images/2151129766.jpg',
    title: 'Plan your next trip',
    description: 'Keep a packing checklist and save your favourite peaks.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isLast) {
      await getIt<AppPrefs>().markOnboardingSeen();
      if (!mounted) return;
      context.go(Routes.login);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(s.image, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          s.description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final active = i == _index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.slate300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  AppButton(
                    label: _isLast ? 'Get started' : 'Next',
                    fullWidth: false,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
