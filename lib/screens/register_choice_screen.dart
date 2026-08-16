import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/legal_agreement_dialog.dart';
import '../utils/localization_extension.dart';

class RegisterChoiceScreen extends StatefulWidget {
  const RegisterChoiceScreen({super.key});

  @override
  State<RegisterChoiceScreen> createState() => _RegisterChoiceScreenState();
}

class _RegisterChoiceScreenState extends State<RegisterChoiceScreen> {
  bool _isTermsActive = false;
  bool _isPrivacyActive = false;
  String? _hoveredCard; // 'resident' or 'driver'
  String? _activeCard; // For mobile tap feedback

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppDecorations.loginBackground,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.59),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00796B), size: 20),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        // 👤 Logo
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.loginButtonStart, AppColors.loginButtonEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.loginButtonEnd.withValues(alpha: 0.39),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.person_add_rounded, size: 54, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          context.translate('create_account'),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.tealText,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.translate('select_account_type'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Options
                        _buildChoiceCard(
                          id: 'resident',
                          context: context,
                          title: context.translate('resident'),
                          subtitle: context.translate('resident_sub'),
                          icon: Icons.home_rounded,
                          iconColor: const Color(0xFF2196F3),
                          bgColor: const Color(0xFFE3F2FD),
                          route: '/register_resident',
                        ),
                        const SizedBox(height: 20),
                        _buildChoiceCard(
                          id: 'driver',
                          context: context,
                          title: context.translate('driver'),
                          subtitle: context.translate('driver_sub'),
                          icon: Icons.local_shipping_rounded,
                          iconColor: const Color(0xFF4CAF50),
                          bgColor: const Color(0xFFE8F5E9),
                          route: '/register_driver',
                        ),
                        const Spacer(flex: 6),
                        _buildFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String id,
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String route,
  }) {
    bool isActive = (_hoveredCard == id) || (_activeCard == id);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = id),
      onExit: (_) => setState(() => _hoveredCard = null),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _activeCard = id),
        onTapUp: (_) => setState(() => _activeCard = null),
        onTapCancel: () => setState(() => _activeCard = null),
        onTap: () => Navigator.pushNamed(context, route),
        child: AnimatedScale(
          scale: isActive ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive ? AppColors.tealText.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.39),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isActive ? 0.15 : 0.04),
                  blurRadius: isActive ? 30 : 20,
                  offset: Offset(0, isActive ? 15 : 10),
                  spreadRadius: isActive ? 0 : -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: iconColor, size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: isActive ? AppColors.tealText : Colors.grey.shade300, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              GestureDetector(
                onTapDown: (_) => setState(() => _isTermsActive = true),
                onTapUp: (_) => setState(() => _isTermsActive = false),
                onTapCancel: () => setState(() => _isTermsActive = false),
                onTap: () => LegalAgreementDialog.show(context, isTerms: true),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isTermsActive = true),
                  onExit: (_) => setState(() => _isTermsActive = false),
                  child: AnimatedScale(
                    scale: _isTermsActive ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      context.translate('terms'),
                      style: TextStyle(
                        color: _isTermsActive ? AppColors.loginButtonStart : AppColors.tealLink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
              const Text('•', style: TextStyle(color: AppColors.textGray)),
              GestureDetector(
                onTapDown: (_) => setState(() => _isPrivacyActive = true),
                onTapUp: (_) => setState(() => _isPrivacyActive = false),
                onTapCancel: () => setState(() => _isPrivacyActive = false),
                onTap: () => LegalAgreementDialog.show(context, isTerms: false),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isPrivacyActive = true),
                  onExit: (_) => setState(() => _isPrivacyActive = false),
                  child: AnimatedScale(
                    scale: _isPrivacyActive ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      context.translate('privacy'),
                      style: TextStyle(
                        color: _isPrivacyActive ? AppColors.loginButtonStart : AppColors.tealLink,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 ${context.translate('brgy_title')}',
            style: const TextStyle(
              color: Color(0xFF00796B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            context.translate('all_rights_reserved'),
            style: const TextStyle(color: Color(0xFF00796B), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
