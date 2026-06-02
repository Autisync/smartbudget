import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smartbudget/core/widgets/page_header.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum LegalDocumentType {
  terms,
  privacy,
  cookies,
  acceptableUse,
  dataRetention,
  securityDisclosure,
  thirdPartyServices,
  disclaimers,
}

class LegalDocumentDefinition {
  final String title;
  final String subtitle;
  final String assetPath;

  const LegalDocumentDefinition({
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

String legalRouteForType(LegalDocumentType type) {
  switch (type) {
    case LegalDocumentType.terms:
      return '/legal/terms';
    case LegalDocumentType.privacy:
      return '/legal/privacy';
    case LegalDocumentType.cookies:
      return '/legal/cookies';
    case LegalDocumentType.acceptableUse:
      return '/legal/acceptable-use';
    case LegalDocumentType.dataRetention:
      return '/legal/data-retention';
    case LegalDocumentType.securityDisclosure:
      return '/legal/security-disclosure';
    case LegalDocumentType.thirdPartyServices:
      return '/legal/third-party-services';
    case LegalDocumentType.disclaimers:
      return '/legal/disclaimers';
  }
}

LegalDocumentDefinition legalDocumentForType(
  LegalDocumentType type,
  AppLocalizations l10n,
) {
  switch (type) {
    case LegalDocumentType.terms:
      return LegalDocumentDefinition(
        title: l10n.legalTermsTitle,
        subtitle: 'Your rights and responsibilities when using SmartSpend.',
        assetPath: 'legal/TERMS_OF_USE.md',
      );
    case LegalDocumentType.privacy:
      return LegalDocumentDefinition(
        title: l10n.legalPrivacyTitle,
        subtitle: 'How personal and financial data is handled in SmartSpend.',
        assetPath: 'legal/PRIVACY_POLICY.md',
      );
    case LegalDocumentType.cookies:
      return LegalDocumentDefinition(
        title: l10n.legalCookiesTitle,
        subtitle: l10n.legalCookiesSubtitle,
        assetPath: 'legal/COOKIES_AND_TRACKING_NOTICE.md',
      );
    case LegalDocumentType.acceptableUse:
      return LegalDocumentDefinition(
        title: l10n.legalAupTitle,
        subtitle: l10n.legalAupSubtitle,
        assetPath: 'legal/ACCEPTABLE_USE_POLICY.md',
      );
    case LegalDocumentType.dataRetention:
      return LegalDocumentDefinition(
        title: l10n.legalDataRetentionTitle,
        subtitle: l10n.legalDataRetentionSubtitle,
        assetPath: 'legal/DATA_RETENTION_POLICY.md',
      );
    case LegalDocumentType.securityDisclosure:
      return LegalDocumentDefinition(
        title: l10n.legalSecurityDisclosureTitle,
        subtitle: l10n.legalSecurityDisclosureSubtitle,
        assetPath: 'legal/SECURITY_DISCLOSURE_POLICY.md',
      );
    case LegalDocumentType.thirdPartyServices:
      return LegalDocumentDefinition(
        title: l10n.legalThirdPartyServicesTitle,
        subtitle: l10n.legalThirdPartyServicesSubtitle,
        assetPath: 'legal/THIRD_PARTY_SERVICES_NOTICE.md',
      );
    case LegalDocumentType.disclaimers:
      return LegalDocumentDefinition(
        title: l10n.legalDisclaimersTitle,
        subtitle: l10n.legalDisclaimersSubtitle,
        assetPath: 'legal/DISCLAIMERS.md',
      );
  }
}

class LegalDocumentScreen extends StatefulWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  bool _isAppBarScrolled = false;
  late Future<String> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = _loadDocument();
  }

  @override
  void didUpdateWidget(covariant LegalDocumentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) {
      setState(() => _documentFuture = _loadDocument());
    }
  }

  Future<String> _loadDocument() async {
    final assetPath = switch (widget.type) {
      LegalDocumentType.terms => 'legal/TERMS_OF_USE.md',
      LegalDocumentType.privacy => 'legal/PRIVACY_POLICY.md',
      LegalDocumentType.cookies => 'legal/COOKIES_AND_TRACKING_NOTICE.md',
      LegalDocumentType.acceptableUse => 'legal/ACCEPTABLE_USE_POLICY.md',
      LegalDocumentType.dataRetention => 'legal/DATA_RETENTION_POLICY.md',
      LegalDocumentType.securityDisclosure =>
        'legal/SECURITY_DISCLOSURE_POLICY.md',
      LegalDocumentType.thirdPartyServices =>
        'legal/THIRD_PARTY_SERVICES_NOTICE.md',
      LegalDocumentType.disclaimers => 'legal/DISCLAIMERS.md',
    };
    return rootBundle.loadString(assetPath);
  }

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
    final document = legalDocumentForType(widget.type, l10n);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: buildFrostedAppBarTitle(
          context: context,
          title: document.title,
          isScrolled: _isAppBarScrolled,
        ),
        backgroundColor: colorScheme.surface.withValues(
          alpha: _isAppBarScrolled ? 0.88 : 0,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: buildFrostedFlexibleSpace(
          context: context,
          isScrolled: _isAppBarScrolled,
          onKey: 'legal-appbar-blur-on',
          offKey: 'legal-appbar-blur-off',
        ),
        actions: buildPageHeaderActions(
          context: context,
          isScrolled: _isAppBarScrolled,
          useProviderNotificationBell: false,
        ),
      ),
      body: FutureBuilder<String>(
        future: _documentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      l10n.legalLoadError,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() => _documentFuture = _loadDocument());
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.legalTryAgain),
                    ),
                  ],
                ),
              ),
            );
          }

          final markdown = snapshot.data ?? '';

          return LayoutBuilder(
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
                    28,
                  ),
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Text(
                        document.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.72),
                            ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: MarkdownBody(
                        data: markdown,
                        selectable: true,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                height: 1.5,
                              ),
                          h1: Theme.of(context).textTheme.headlineSmall,
                          h2: Theme.of(context).textTheme.titleLarge,
                          h3: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
