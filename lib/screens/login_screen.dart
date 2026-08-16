import 'dart:async';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../utils/session_manager.dart';
import '../utils/app_theme.dart';
import '../utils/system_logger.dart';
import '../utils/login_security_manager.dart';
import '../widgets/legal_agreement_dialog.dart';
import '../widgets/truck_loading_indicator.dart';
import '../services/language_service.dart';
import '../utils/localization_extension.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  final ApiService _apiService = ApiService();
  final LanguageService _lang = LanguageService();

  SecurityStatus? _securityStatus;
  Timer? _lockoutTimer;
  int _secondsRemaining = 0;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockoutCountdown(DateTime lockoutUntil) {
    _lockoutTimer?.cancel();
    void updateTimer() {
      final now = DateTime.now();
      final diff = lockoutUntil.difference(now);
      if (diff.isNegative) {
        setState(() {
          _secondsRemaining = 0;
          _securityStatus = SecurityStatus(attempts: 0, isLocked: false);
        });
        _lockoutTimer?.cancel();
      } else {
        setState(() {
          _secondsRemaining = diff.inSeconds;
        });
      }
    }
    updateTimer();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) => updateTimer());
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_lang.translate('username_hint'))));
      return;
    }

    final status = await LoginSecurityManager.checkStatus(username);
    if (status.isLocked) {
      setState(() => _securityStatus = status);
      _startLockoutCountdown(status.lockoutUntil!);
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final password = _passwordController.text.trim();
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(username, password);
      final data = response.data;
      
      if (data is Map && data['success'] == true) {
        await LoginSecurityManager.resetAttempts(username);
        final user = data['user'];
        if (user == null || user is! Map) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid user data received from server')));
          return;
        }

        if (data['message'].toString().toUpperCase().contains('2FA_REQUIRED')) {
          if (!mounted) return;
          Navigator.pushNamed(context, '/verify_2fa', arguments: user);
          return;
        }

        await SessionManager.saveUser(Map<String, dynamic>.from(user));
        await SystemLogger.logEvent("LOGIN", "Successful login from ${user['name'] ?? 'Admin'}");

        if (!mounted) return;
        String role = user['role'].toString().toLowerCase();
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (role == 'resident') {
          Navigator.pushReplacementNamed(context, '/resident_dashboard');
        } else if (role == 'driver') {
          Navigator.pushReplacementNamed(context, '/driver_dashboard');
        }
      } else {
        final newStatus = await LoginSecurityManager.recordFailedAttempt(username);
        setState(() => _securityStatus = newStatus);
        if (newStatus.isLocked) _startLockoutCountdown(newStatus.lockoutUntil!);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isContainerHovered = false;
  bool _isButtonActive = false;
  bool _isForgotActive = false;
  bool _isTermsActive = false;
  bool _isPrivacyActive = false;
  bool _isCreateAccountActive = false;
  bool _isLangActive = false;
  double _buttonScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppDecorations.loginBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildLanguageSelector(),
                        const Spacer(flex: 6),
                        _buildLoginCard(),
                        const Spacer(flex: 10),
                        _buildFooter(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isLangActive = true),
      onTapUp: (_) => setState(() => _isLangActive = false),
      onTapCancel: () => setState(() => _isLangActive = false),
      onTap: _showLanguageModal,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isLangActive = true),
        onExit: (_) => setState(() => _isLangActive = false),
        child: AnimatedScale(
          scale: _isLangActive ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _lang.currentLanguage,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade600, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.translate('select_language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _lang.languages.length,
                  itemBuilder: (context, index) {
                    final l = _lang.languages[index];
                    final isSelected = l == _lang.currentLanguage;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(
                        l,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                          color: isSelected ? AppColors.tealText : const Color(0xFF4A4A4A),
                        ),
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_box_rounded, color: AppColors.tealText)
                        : Icon(Icons.check_box_outline_blank_rounded, color: Colors.grey.shade300),
                      onTap: () {
                        _lang.setLanguage(l);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isContainerHovered = true),
          onExit: (_) => setState(() => _isContainerHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: _isContainerHovered ? AppColors.tealText.withValues(alpha: 0.39) : Colors.white.withValues(alpha: 0.39),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isContainerHovered ? 0.12 : 0.06),
                  blurRadius: _isContainerHovered ? 40 : 30,
                  offset: Offset(0, _isContainerHovered ? 20 : 15),
                  spreadRadius: _isContainerHovered ? -2 : -5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  child: const Icon(Icons.local_shipping_rounded, size: 54, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(
                  context.translate('app_name'),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.tealText, letterSpacing: -1.5, height: 1.1),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.translate('brgy_title'),
                  style: const TextStyle(fontSize: 15, color: AppColors.textGray, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                _buildRefinedTextField(
                  label: context.translate('username'),
                  hint: context.translate('username_hint'),
                  controller: _usernameController,
                  icon: Icons.person_outline_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? context.translate('username_hint') : null,
                ),
                const SizedBox(height: 24),
                _buildRefinedTextField(
                  label: context.translate('password'),
                  hint: context.translate('password_hint'),
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  icon: Icons.lock_outline_rounded,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) => (v == null || v.isEmpty) ? context.translate('password_hint') : (v.length < 6 ? 'Password must be at least 6 characters' : null),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isForgotActive = true),
                    onTapUp: (_) => setState(() => _isForgotActive = false),
                    onTapCancel: () => setState(() => _isForgotActive = false),
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isForgotActive = true),
                      onExit: (_) => setState(() => _isForgotActive = false),
                      child: AnimatedScale(
                        scale: _isForgotActive ? 1.03 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                          style: TextButton.styleFrom(
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: Colors.transparent,
                          ),
                          child: Text(
                            context.translate('forgot_password'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isForgotActive ? AppColors.loginButtonStart : AppColors.tealLink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_securityStatus != null && _securityStatus!.attempts > 0 && !_securityStatus!.isLocked)
                  _buildWarningCard('Incorrect email or password. You have ${_securityStatus!.remainingAttempts} attempts remaining.', Colors.orange),
                if (_securityStatus?.isLocked == true)
                  _buildLockoutCard(),
                const SizedBox(height: 20),
                _buildAnimatedLoginButton(),
                const SizedBox(height: 32),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(context.translate('dont_have_account'), style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isCreateAccountActive = true),
                      onTapUp: (_) => setState(() => _isCreateAccountActive = false),
                      onTapCancel: () => setState(() => _isCreateAccountActive = false),
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => _isCreateAccountActive = true),
                        onExit: (_) => setState(() => _isCreateAccountActive = false),
                        child: AnimatedScale(
                          scale: _isCreateAccountActive ? 1.03 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            context.translate('create_account'),
                            style: TextStyle(
                              color: _isCreateAccountActive ? AppColors.loginButtonStart : AppColors.tealLink,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarningCard(String msg, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildLockoutCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade200)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: Colors.red.shade900, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Too many failed login attempts.', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 12),
          Text('Login is temporarily disabled for 1 minute.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade900, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Try again in: ${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}', style: TextStyle(color: Colors.red.shade900, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reset your password'),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade900),
          ),
        ],
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
            runSpacing: 8,
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
          const Text(
            '© 2026 Brgy. Balintawak Lipa City',
            style: TextStyle(color: Color(0xFF00796B), fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Text(
            'All rights reserved',
            style: TextStyle(color: Color(0xFF00796B), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedTextField({required String label, required String hint, required TextEditingController controller, IconData? icon, bool isPassword = false, bool obscureText = false, VoidCallback? onTogglePassword, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(label, style: const TextStyle(color: AppColors.inputLabel, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.2))),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          validator: validator,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
          onFieldSubmitted: (_) {
            if (isPassword) _handleLogin();
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w400),
            prefixIcon: icon != null ? Icon(icon, color: AppColors.tealText.withValues(alpha: 0.7), size: 22) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.tealText, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade500, size: 20), onPressed: onTogglePassword) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLoginButton() {
    bool isLocked = _securityStatus?.isLocked == true;
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonActive = true),
      onExit: (_) => setState(() => _isButtonActive = false),
      child: GestureDetector(
        onTapDown: isLocked
            ? null
            : (_) => setState(() {
                  _isButtonActive = true;
                  _buttonScale = 0.97;
                }),
        onTapUp: isLocked
            ? null
            : (_) => setState(() {
                  _isButtonActive = false;
                  _buttonScale = 1.0;
                }),
        onTapCancel: isLocked
            ? null
            : () => setState(() {
                  _isButtonActive = false;
                  _buttonScale = 1.0;
                }),
        onTap: (_isLoading || isLocked) ? null : _handleLogin,
        child: AnimatedScale(
          scale: _buttonScale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 60,
            decoration: isLocked
                ? AppDecorations.loginButton.copyWith(gradient: LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]), boxShadow: [])
                : AppDecorations.loginButton.copyWith(
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.loginButtonEnd.withValues(alpha: _isButtonActive ? 0.47 : 0.31),
                        blurRadius: _isButtonActive ? 20 : 12,
                        offset: Offset(0, _isButtonActive ? 8 : 6),
                      ),
                    ],
                  ),
            alignment: Alignment.center,
            child: _isLoading 
                ? TruckLoadingIndicator(message: context.translate('verifying'), isCompact: true) 
                : Text(isLocked ? 'Locked' : context.translate('login'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}
