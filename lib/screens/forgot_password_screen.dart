import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../api/api_service.dart';
import '../api/api_client.dart';
import '../widgets/legal_agreement_dialog.dart';
import '../widgets/truck_loading_indicator.dart';
import '../utils/localization_extension.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _isButtonActive = false;
  bool _isTermsActive = false;
  bool _isPrivacyActive = false;
  double _buttonScale = 1.0;

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
                        _buildHeader(),
                        const Spacer(flex: 2),
                        _buildLogo(),
                        const SizedBox(height: 32),
                        _buildTitle(),
                        const SizedBox(height: 8),
                        _buildSubtitle(),
                        const SizedBox(height: 48),

                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: _buildMainCard(),
                          ),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.59),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00796B), size: 20),
              onPressed: () {
                if (_currentStep > 1) {
                  setState(() => _currentStep--);
                } else {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStep == 1 ? context.translate('verification') : (_currentStep == 2 ? context.translate('enter_token') : context.translate('new_password')),
                style: const TextStyle(
                  color: AppColors.tealText,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              Text(
                context.translate('account_recovery'),
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    IconData icon = Icons.lock_reset_rounded;
    if (_currentStep == 2) icon = Icons.vibration_rounded;
    if (_currentStep == 3) icon = Icons.security_rounded;

    return Container(
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
      child: Icon(icon, size: 54, color: Colors.white),
    );
  }

  Widget _buildTitle() {
    String title = context.translate('reset_password_btn');
    if (_currentStep == 2) title = context.translate('verify_token_btn');
    if (_currentStep == 3) title = context.translate('new_password');

    return Text(
      title,
      style: const TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        color: AppColors.tealText,
        letterSpacing: -1.5,
      ),
    );
  }

  Widget _buildSubtitle() {
    String sub = context.translate('step_1_of_3');
    if (_currentStep == 2) sub = context.translate('step_2_of_3');
    if (_currentStep == 3) sub = context.translate('step_3_of_3');

    return Text(
      sub,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textGray,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.39), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentStep == 1) _buildStep1Fields(),
            if (_currentStep == 2) _buildStep2Fields(),
            if (_currentStep == 3) _buildStep3Fields(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.translate('email'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel),
          ),
        ),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          decoration: _inputDecoration('Enter your registered email address', Icons.email_outlined),
          validator: (value) {
            if (value == null || value.isEmpty) return 'This field is required and cannot be empty';
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address (e.g., user@example.com)';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStep2Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.translate('verification_token'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel),
          ),
        ),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.tealText, letterSpacing: 8),
          decoration: _inputDecoration(context.translate('otp_hint'), Icons.vpn_key_outlined).copyWith(counterText: ""),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter the 6-digit verification code';
            if (value.length < 6) return 'Please enter all 6 digits of the code';
            return null;
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            "${context.translate('code_sent_to')} ${_emailController.text}",
            style: const TextStyle(fontSize: 12, color: AppColors.textGray, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.translate('new_password'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel),
          ),
        ),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          decoration: _inputDecoration('Enter a highly secure new password', Icons.lock_outline_rounded).copyWith(
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey, size: 20),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a new secure password';
            final passRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$');
            if (!passRegex.hasMatch(value)) return 'Password must be 6+ chars with uppercase, lowercase, numbers, and symbols';
            return null;
          },
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            context.translate('confirm_password'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel),
          ),
        ),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscurePassword,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          decoration: _inputDecoration('Re-enter your new password for verification', Icons.lock_clock_outlined),
          validator: (value) {
            if (value != _passwordController.text) return 'The confirmation password does not match the new password';
            return null;
          },
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, color: AppColors.tealText.withValues(alpha: 0.7), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.tealText, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
    );
  }

  Widget _buildSubmitButton() {
    String text = context.translate('send_verification');
    if (_currentStep == 2) text = context.translate('verify_token_btn');
    if (_currentStep == 3) text = context.translate('reset_password_btn');

    String loadingText = 'Sending Code...';
    if (_currentStep == 2) loadingText = 'Verifying Token...';
    if (_currentStep == 3) loadingText = 'Updating Password...';

    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonActive = true),
      onExit: (_) => setState(() => _isButtonActive = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() { _isButtonActive = true; _buttonScale = 0.97; }),
        onTapUp: (_) => setState(() { _isButtonActive = false; _buttonScale = 1.0; }),
        onTapCancel: () => setState(() { _isButtonActive = false; _buttonScale = 1.0; }),
        onTap: _isLoading ? null : _handleAction,
        child: AnimatedScale(
          scale: _buttonScale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 64,
            decoration: AppDecorations.loginButton.copyWith(
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
                ? TruckLoadingIndicator(
                    message: loadingText,
                    isCompact: true,
                  )
                : Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  void _handleAction() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentStep == 1) _sendEmail();
    else if (_currentStep == 2) _verifyOTP();
    else if (_currentStep == 3) _resetPassword();
  }

  void _sendEmail() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.forgotPassword(_emailController.text.trim());
      if (response.data['success'] == true) {
        _showSuccess(response.data['message'] ?? 'Verification code sent to your email address');
        setState(() => _currentStep = 2);
      } else {
        _showError(response.data['message'] ?? 'This email address was not found in our records');
      }
    } catch (e) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.verifyOTP(_emailController.text.trim(), _otpController.text.trim());
      if (response.data['success'] == true) {
        _showSuccess(response.data['message'] ?? 'Verification successful');
        setState(() => _currentStep = 3);
      } else {
        _showError(response.data['message'] ?? 'The entered verification code is invalid');
      }
    } catch (e) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.resetPassword(
        _emailController.text.trim(),
        _otpController.text.trim(),
        _passwordController.text,
      );
      if (response.data['success'] == true) {
        _showSuccess('Password updated successfully. You may now return to login.');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showError(response.data['message'] ?? 'Security verification failed. Please try again.');
      }
    } catch (e) {
      _showConnectionError();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConnectionError() {
    if (!mounted) return;
    const url = ApiClient.baseUrl;
    _showError('Unable to connect to the server at $url. Please check your network connection.');
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
          Text(
            '© 2026 ${context.translate('brgy_title')}',
            style: const TextStyle(
              color: Color(0xFF00796B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            context.translate('all_rights_reserved'),
            style: const TextStyle(color: Color(0xFF00796B), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
