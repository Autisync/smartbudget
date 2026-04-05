import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartbudget/features/onboarding/presentation/screens/legal_document_screen.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

class LegalCenterScreen extends StatefulWidget {
  const LegalCenterScreen({super.key});

  @override
  State<LegalCenterScreen> createState() => _LegalCenterScreenState();
}

class _LegalCenterScreenState extends State<LegalCenterScreen> {
  bool _isAppBarScrolled = false;

  void _updateAppBarScrollState(double offset) {
    const threshold = 8.0;
    final shouldShowFill = offset > threshold;
    if (shouldShowFill == _isAppBarScrolled) return;
    if (!mounted) return;
    setState(() => _isAppBarScrolled = shouldShowFill);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final legalTypes = <LegalDocumentType>[
      LegalDocumentType.terms,
      LegalDocumentType.privacy,
      LegalDocumentType.cookies,
      LegalDocumentType.acceptableUse,
      LegalDocumentType.dataRetention,
      LegalDocumentType.securityDisclosure,
      LegalDocumentType.thirdPartyServices,
      LegalDocumentType.disclaimers,
    ];

    return Scaffold(
      appBar: AppBar(
        title: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(
              alpha: _isAppBarScrolled ? 0.9 : 0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(l10n.legalCenterTitle),
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isAppBarScrolled
                  ? ClipRect(
                      key: const ValueKey('legal-center-appbar-blur-on'),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          color: colorScheme.surface.withValues(alpha: 0.08),
                        ),
                      ),
                    )
                  : const SizedBox(
                      key: ValueKey('legal-center-appbar-blur-off'),
                    ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width >= 1200
              ? (width - 980) / 2
              : width >= 768
                  ? 24.0
                  : 16.0;

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical) {
                _updateAppBarScrollState(notification.metrics.pixels);
              }
              return false;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                32,
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l10n.legalCenterIntro,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (final type in legalTypes) ...[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: _LegalCenterTile(
                      type: type,
                      onTap: () => context.push(legalRouteForType(type)),
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalCenterTile extends StatelessWidget {
  const _LegalCenterTile({
    required this.type,
    required this.onTap,
  });

  final LegalDocumentType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final document = legalDocumentForType(type, l10n);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      title: Text(document.title),
      subtitle: Text(document.subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
