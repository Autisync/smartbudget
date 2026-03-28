import 'package:flutter/material.dart';
import 'package:smartbudget/l10n/app_localizations.dart';

enum LegalDocumentType { terms, privacy }

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final document = _documentFor(type, l10n);

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            document.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            document.subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 24),
          for (final section in document.sections) ...[
            Text(
              section.heading,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              section.body,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  _LegalDocument _documentFor(LegalDocumentType type, AppLocalizations l10n) {
    switch (type) {
      case LegalDocumentType.terms:
        return _LegalDocument(
          title: l10n.legalTermsTitle,
          subtitle: l10n.legalTermsSubtitle,
          sections: [
            _LegalSection(
              heading: l10n.legalTermsUseHeading,
              body: l10n.legalTermsUseBody,
            ),
            _LegalSection(
              heading: l10n.legalTermsGuidanceHeading,
              body: l10n.legalTermsGuidanceBody,
            ),
            _LegalSection(
              heading: l10n.legalTermsSecurityHeading,
              body: l10n.legalTermsSecurityBody,
            ),
            _LegalSection(
              heading: l10n.legalTermsChangesHeading,
              body: l10n.legalTermsChangesBody,
            ),
          ],
        );
      case LegalDocumentType.privacy:
        return _LegalDocument(
          title: l10n.legalPrivacyTitle,
          subtitle: l10n.legalPrivacySubtitle,
          sections: [
            _LegalSection(
              heading: l10n.legalPrivacyDataHeading,
              body: l10n.legalPrivacyDataBody,
            ),
            _LegalSection(
              heading: l10n.legalPrivacyStorageHeading,
              body: l10n.legalPrivacyStorageBody,
            ),
            _LegalSection(
              heading: l10n.legalPrivacyBiometricHeading,
              body: l10n.legalPrivacyBiometricBody,
            ),
            _LegalSection(
              heading: l10n.legalPrivacyControlHeading,
              body: l10n.legalPrivacyControlBody,
            ),
          ],
        );
    }
  }
}

class _LegalDocument {
  final String title;
  final String subtitle;
  final List<_LegalSection> sections;

  const _LegalDocument({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection({
    required this.heading,
    required this.body,
  });
}
