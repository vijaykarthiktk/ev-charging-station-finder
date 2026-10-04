import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/onboarding_provider.dart';
import '../../widgets/responsive_body.dart';

/// First-launch walkthrough: find → book → track. Shown instead of the
/// tab shell until completed (persisted in Hive).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() =>
      ref.read(onboardingSeenProvider.notifier).complete();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: const [
                    _Page(
                      visual: _CarArt(),
                      title: 'Find charging nearby',
                      subtitle:
                          'Live availability, prices, and distances for every station around you — on a list or a map.',
                    ),
                    _Page(
                      visual: _IconArt(icon: Icons.calendar_month_outlined),
                      title: 'Book your slot',
                      subtitle:
                          'Pick a day, time, and plug. We re-check live availability before confirming.',
                    ),
                    _Page(
                      visual: _IconArt(icon: Icons.bolt_outlined),
                      title: 'Track and charge',
                      subtitle:
                          'Reminders before your slot, live status on every screen, and history that survives restarts.',
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _index == 2
                        ? _finish
                        : () => _pages.nextPage(
                              duration:
                                  const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            ),
                    child:
                        Text(_index == 2 ? 'Get Started' : 'Next'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(
      {required this.visual, required this.title, required this.subtitle});
  final Widget visual;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          visual,
          const SizedBox(height: 32),
          Text(title,
              textAlign: TextAlign.center,
              style: text.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _CarArt extends StatelessWidget {
  const _CarArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: SvgPicture.asset(
        'assets/images/ev_car.svg',
        height: 140,
        semanticsLabel: 'Electric car charging',
      ),
    );
  }
}

class _IconArt extends StatelessWidget {
  const _IconArt({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 188,
      height: 188,
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 84, color: scheme.onPrimaryContainer),
    );
  }
}
