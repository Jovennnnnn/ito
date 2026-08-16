import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../utils/localized_legal_content.dart';
import '../utils/localization_extension.dart';
import '../services/language_service.dart';

class LegalAgreementDialog extends StatelessWidget {
  final String title;
  final String content;

  const LegalAgreementDialog({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required bool isTerms}) {
    final lang = LanguageService().currentLanguage;
    showDialog(
      context: context,
      builder: (context) => LegalAgreementDialog(
        title: isTerms ? context.translate('terms_title') : context.translate('privacy_title'),
        content: isTerms ? LocalizedLegalContent.getTerms(lang) : LocalizedLegalContent.getPrivacy(lang),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  title.contains('Terms') ? Icons.gavel_rounded : Icons.privacy_tip_rounded,
                  color: AppColors.tealText,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.tealText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(height: 32),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
