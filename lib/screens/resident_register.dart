import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../api/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/legal_agreement_dialog.dart';
import '../widgets/truck_loading_indicator.dart';
import '../utils/localization_extension.dart';

class ResidentRegisterScreen extends StatefulWidget {
  const ResidentRegisterScreen({super.key});

  @override
  State<ResidentRegisterScreen> createState() => _ResidentRegisterScreenState();
}

class _ResidentRegisterScreenState extends State<ResidentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final Map<String, FocusNode> _focusNodes = {
    'username': FocusNode(),
    'email': FocusNode(),
    'password': FocusNode(),
    'confirmPassword': FocusNode(),
    'fullName': FocusNode(),
    'phone': FocusNode(),
  };

  final Map<String, String?> _fieldErrors = {};
  
  String? _selectedPurok;
  bool _isLoading = false;
  bool _obs1 = true;
  bool _obs2 = true;
  bool _termsAccepted = false;
  bool _isSubmitActive = false;
  bool _isTermsActive = false;
  bool _isPrivacyActive = false;
  double _submitScale = 1.0;

  final List<String> _puroks = ["Purok 2", "Purok 3", "Purok 4", "Dos Riles", "Sentro", "San Isidro", "Paraiso", "Riverside", "Kalaw Street", "Home Subdivision", "Tanco Road / Ayala Highway", "Brixton Area"];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _focusNodes.forEach((key, node) {
      node.addListener(() {
        if (!node.hasFocus) {
          _validateField(key);
        }
      });
    });
  }

  @override
  void dispose() {
    _focusNodes.forEach((_, node) => node.dispose());
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _validateField(String field) async {
    String? error;
    final value = _getControllerForField(field).text.trim();

    if (value.isEmpty) {
      error = "This field is required and cannot be left empty";
    } else {
      switch (field) {
        case 'username':
          error = await _checkUsernameDatabase(value);
          break;
        case 'email':
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            error = "Please enter a valid email address (e.g., user@example.com)";
          } else {
            error = await _checkEmailDatabase(value);
          }
          break;
        case 'password':
          final passRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$');
          if (!passRegex.hasMatch(value)) {
            error = "Password must be at least 6 characters with uppercase, lowercase, numbers, and symbols";
          }
          break;
        case 'confirmPassword':
          if (value != _passwordController.text) {
            error = "The confirmation password does not match the initial password";
          }
          break;
        case 'fullName':
          final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
          if (!nameRegex.hasMatch(value)) {
            error = "Full name must only contain letters and spaces";
          }
          break;
        case 'phone':
          final phoneRegex = RegExp(r'^(09|63)\d{9}$');
          if (!phoneRegex.hasMatch(value)) {
            error = "Please enter a valid Philippine mobile number (11 digits, starting with 09 or 63)";
          } else {
            error = await _checkPhoneDatabase(value);
          }
          break;
      }
    }

    setState(() {
      _fieldErrors[field] = error;
    });
  }

  TextEditingController _getControllerForField(String field) {
    switch (field) {
      case 'username': return _usernameController;
      case 'email': return _emailController;
      case 'password': return _passwordController;
      case 'confirmPassword': return _confirmPasswordController;
      case 'fullName': return _fullNameController;
      case 'phone': return _phoneController;
      default: return TextEditingController();
    }
  }

  Future<String?> _checkUsernameDatabase(String username) async {
    try {
      final response = await _apiService.checkUsername(username);
      if (response.data['success'] == true) {
        return "This username is already in use. Please choose another.";
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _checkEmailDatabase(String email) async {
    try {
      final response = await _apiService.checkEmail(email);
      if (response.data['success'] == true) {
        return "This email address is already registered to another account.";
      }
    } catch (_) {}
    return null;
  }

  Future<String?> _checkPhoneDatabase(String phone) async {
    try {
      final response = await _apiService.checkPhone(phone);
      if (response.data['success'] == true) {
        return "This phone number is already registered. Please use another.";
      }
    } catch (_) {}
    return null;
  }

  void _handleRegister() async {
    // Force validation on all fields
    for (var key in _focusNodes.keys) {
      await _validateField(key);
    }

    if (_fieldErrors.values.any((e) => e != null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct the highlighted errors before submitting'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (_selectedPurok == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your Purok assignment'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must accept the Terms and Conditions to proceed with registration'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final registerData = {
        'username': _usernameController.text.trim(),
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': 'resident',
        'phone': _phoneController.text.trim(),
        'purok': _selectedPurok,
        'complete_address': _addressController.text.trim(),
        'termsAccepted': 1,
        'privacyPolicyAccepted': 1,
        'termsVersion': '1.0',
        'privacyPolicyVersion': '1.0',
        'consentTimestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.register(registerData);

      if (response.data['success'] == true) {
        try {
          await FirebaseDatabase.instance.ref('notifications').push().set({
            'type': 'REGISTRATION',
            'title': 'New Registration',
            'message': '${_fullNameController.text} has registered as a resident.',
            'timestamp': ServerValue.timestamp,
            'isRead': false,
            'relatedId': _usernameController.text
          });
        } catch (_) {}

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Registration successful. Please wait for administrator approval.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Registration failed. Please try again later.'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppDecorations.loginBackground,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          Container(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionHeader(Icons.lock_outline_rounded, 'Account Credentials'),
                                  const SizedBox(height: 8),
                                  _buildInput('username', 'Username', 'Enter your preferred username', icon: Icons.person_outline_rounded),
                                  _buildInput('email', 'Email Address', 'Enter your official email address', icon: Icons.email_outlined),
                                  _buildInput('password', 'Password', 'Create a highly secure password', isPass: true, obs: _obs1, onToggle: () => setState(() => _obs1 = !_obs1), icon: Icons.lock_outline_rounded),
                                  _buildInput('confirmPassword', 'Confirm Password', 'Re-enter your password for verification', isPass: true, obs: _obs2, onToggle: () => setState(() => _obs2 = !_obs2), icon: Icons.lock_clock_outlined),

                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32),
                                    child: Divider(height: 1, color: Color(0x1F000000)),
                                  ),

                                  _buildSectionHeader(Icons.badge_outlined, context.translate('profile_info')),
                                  const SizedBox(height: 8),
                                  _buildInput('fullName', context.translate('full_name'), 'Enter your complete legal name', icon: Icons.face_outlined),
                                  _buildInput('phone', context.translate('phone'), 'Enter your 11-digit mobile number', icon: Icons.phone_android_outlined),
                                  _buildPurokSelector(),
                                  _buildSimpleInput(_addressController, context.translate('address'), 'Enter your detailed residential address', maxLines: 3, action: TextInputAction.done, icon: Icons.home_outlined),

                                  const SizedBox(height: 32),
                                  _buildTermsCheckbox(),
                                  const SizedBox(height: 32),
                                  _buildSubmitButton(),

                                  const SizedBox(height: 16),
                                  Center(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(context.translate('sign_in'), style: const TextStyle(color: AppColors.textGray, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildFooter(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.59), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00796B), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.translate('resident'), style: const TextStyle(color: AppColors.tealText, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1)),
              Text(context.translate('resident_reg'), style: const TextStyle(color: AppColors.textGray, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.tealText.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: const Icon(Icons.home_work_rounded, color: AppColors.tealText, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.tealText, size: 22),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: AppColors.tealText, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ],
    );
  }

  Widget _buildInput(String field, String label, String hint, {IconData? icon, bool isPass = false, bool obs = false, VoidCallback? onToggle}) {
    final ctrl = _getControllerForField(field);
    final focus = _focusNodes[field];
    final error = _fieldErrors[field];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 24, left: 4, bottom: 8), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel, letterSpacing: 0.2))),
        TextFormField(
          controller: ctrl, focusNode: focus, obscureText: obs,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          decoration: _inputDecoration(hint, icon).copyWith(
            suffixIcon: isPass ? IconButton(icon: Icon(obs ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade500, size: 20), onPressed: onToggle) : null,
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(error, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildSimpleInput(TextEditingController ctrl, String label, String hint, {IconData? icon, int maxLines = 1, TextInputAction action = TextInputAction.next}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 24, left: 4, bottom: 8), child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel, letterSpacing: 0.2))),
        TextFormField(
          controller: ctrl, maxLines: maxLines, textInputAction: action,
          cursorColor: Colors.black54,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.inputLabel),
          decoration: _inputDecoration(hint, icon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w400),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.tealText.withValues(alpha: 0.7), size: 20) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), filled: true, fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.tealText, width: 2)),
    );
  }

  Widget _buildPurokSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(top: 24, left: 4, bottom: 8), child: Text('Purok', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.inputLabel))),
        GestureDetector(
          onTap: _showPurokModal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200, width: 1.5)),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xB400796B), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_selectedPurok ?? 'Select your Purok assignment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _selectedPurok == null ? Colors.grey.shade400 : AppColors.inputLabel))),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.tealText, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPurokModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Purok', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.tealText)),
              const Divider(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _puroks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _puroks[index];
                    return ListTile(
                      title: Text(p, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.inputLabel)),
                      onTap: () {
                        setState(() => _selectedPurok = p);
                        Navigator.pop(context);
                      },
                      trailing: _selectedPurok == p ? const Icon(Icons.check_circle, color: AppColors.tealText) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        SizedBox(
          height: 24, width: 24,
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            activeColor: AppColors.tealText,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            children: [
              const Text('I have read and agree to the ', style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
              _buildFooterLink(context.translate('terms'), true),
              const Text(' and ', style: TextStyle(fontSize: 13, color: AppColors.textGray, fontWeight: FontWeight.w500)),
              _buildFooterLink(context.translate('privacy'), false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterLink(String label, bool isTerms) {
    bool active = isTerms ? _isTermsActive : _isPrivacyActive;
    return GestureDetector(
      onTapDown: (_) => setState(() { if(isTerms) _isTermsActive = true; else _isPrivacyActive = true; }),
      onTapUp: (_) => setState(() { if(isTerms) _isTermsActive = false; else _isPrivacyActive = false; }),
      onTapCancel: () => setState(() { if(isTerms) _isTermsActive = false; else _isPrivacyActive = false; }),
      onTap: () => LegalAgreementDialog.show(context, isTerms: isTerms),
      child: MouseRegion(
        onEnter: (_) => setState(() { if(isTerms) _isTermsActive = true; else _isPrivacyActive = true; }),
        onExit: (_) => setState(() { if(isTerms) _isTermsActive = false; else _isPrivacyActive = false; }),
        child: AnimatedScale(
          scale: active ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Text(label, style: TextStyle(color: active ? AppColors.loginButtonStart : AppColors.tealLink, fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildFooterLink(context.translate('terms'), true),
            const Text('•', style: TextStyle(color: AppColors.textGray)),
            _buildFooterLink(context.translate('privacy'), false),
          ],
        ),
        const SizedBox(height: 12),
        Text('© 2026 ${context.translate('brgy_title')}', style: const TextStyle(color: Color(0xFF00796B), fontSize: 13, fontWeight: FontWeight.bold)),
        Text(context.translate('all_rights_reserved'), style: const TextStyle(color: Color(0xFF00796B), fontSize: 11)),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isSubmitActive = true),
      onExit: (_) => setState(() => _isSubmitActive = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() { _isSubmitActive = true; _submitScale = 0.97; }),
        onTapUp: (_) => setState(() { _isSubmitActive = false; _submitScale = 1.0; }),
        onTapCancel: () => setState(() { _isSubmitActive = false; _submitScale = 1.0; }),
        onTap: _isLoading ? null : _handleRegister,
        child: AnimatedScale(
          scale: _submitScale,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity, height: 64,
            decoration: AppDecorations.loginButton.copyWith(
              boxShadow: [
                BoxShadow(
                  color: AppColors.loginButtonEnd.withValues(alpha: _isSubmitActive ? 0.47 : 0.31),
                  blurRadius: _isSubmitActive ? 20 : 12,
                  offset: Offset(0, _isSubmitActive ? 8 : 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: _isLoading ? TruckLoadingIndicator(message: context.translate('verifying'), isCompact: true) : Text(context.translate('register_btn'), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}
