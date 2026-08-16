import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/app_theme.dart';
import '../utils/session_manager.dart';
import '../models/user.dart';
import '../api/api_service.dart';
import '../utils/custom_notification.dart';
import '../services/language_service.dart';
import '../utils/localization_extension.dart';

class ResidentSettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;
  final VoidCallback? onProfileUpdate;
  const ResidentSettingsScreen({super.key, this.isEmbedded = false, this.onBack, this.onProfileUpdate});

  @override
  State<ResidentSettingsScreen> createState() => _ResidentSettingsScreenState();
}

class _ResidentSettingsScreenState extends State<ResidentSettingsScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  UserData? _user;
  bool _pushNotifications = true;
  bool _isLoading = false;

  final List<String> _puroks = [
    "Purok 1", "Purok 2", "Purok 3", "Purok 4", "Dos Riles", "Sentro",
    "San Isidro", "Paraiso", "Riverside", "Kalaw Street",
    "Home Subdivision", "Tanco Road / Ayala Highway", "Brixton Area"
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    _user = await SessionManager.getUser();
    if (_user != null) {
      _loadSettings();
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadSettings() async {
    try {
      if (_user != null) {
        final response = await _apiService.getUserSettings(_user!.userId, _user!.role);
        if (response.data['success'] == true) {
          final data = response.data['data'];
          if (mounted) {
            setState(() {
              _pushNotifications = data['app_notifications'] ?? true;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> _updatePushNotification(bool value) async {
    setState(() => _pushNotifications = value);
    try {
      if (_user != null) {
        final response = await _apiService.updateUserSettings(
          userId: _user!.userId,
          role: _user!.role,
          appNotifications: value,
        );

        if (response.data['success'] == true) {
          if (mounted) {
            CustomNotification.showTopNotification(
              context, 
              value ? "Push notifications enabled successfully." : "Push notifications disabled successfully.", 
              false
            );
          }
        } else {
          if (mounted) {
            setState(() => _pushNotifications = !value);
            CustomNotification.showTopNotification(context, response.data['message'] ?? "Failed to update notification settings");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pushNotifications = !value);
        CustomNotification.showTopNotification(context, "Connection Error: Unable to sync settings.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F7),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildSectionHeader(context.translate('profile_info')),
                        _buildProfileCard(),
                        
                        const SizedBox(height: 24),
                        _buildSectionHeader(context.translate('notifications')),
                        _buildNotificationCard(),

                        const SizedBox(height: 24),
                        _buildSectionHeader(context.translate('language')),
                        _buildLanguageCard(),
                        
                        const SizedBox(height: 24),
                        _buildSectionHeader(context.translate('account_privacy')),
                        _buildAccountCard(),
                        
                        const SizedBox(height: 24),
                        _buildSectionHeader(context.translate('help_support')),
                        _buildHelpCard(),
                        
                        const SizedBox(height: 24),
                        _buildAppInfoCard(),
                        
                        const SizedBox(height: 32),
                        _buildLogoutButton(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: widget.onBack ?? () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.translate('settings'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              Text(context.translate('manage_preferences'), style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(_getSectionIcon(title), size: 18, color: AppColors.tealText),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
          ],
        ),
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    if (title == context.translate('profile_info')) return Icons.person_rounded;
    if (title == context.translate('notifications')) return Icons.notifications_rounded;
    if (title == context.translate('account_privacy')) return Icons.lock_rounded;
    if (title == context.translate('help_support')) return Icons.help_rounded;
    return Icons.settings;
  }

  Widget _buildProfileCard() {
    return InkWell(
      onTap: _showEditProfileModal,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppDecorations.cardDecoration(),
        child: Column(
          children: [
            _buildProfileRow(context.translate('full_name'), _user?.name ?? "Steve Espaldon"),
            const Divider(height: 32, thickness: 0.5),
            _buildProfileRow(context.translate('email'), _user?.email ?? "steve@gmail.com"),
            const Divider(height: 32, thickness: 0.5),
            _buildProfileRow(context.translate('contact_number'), _user?.phone ?? "09676838820"),
            const Divider(height: 32, thickness: 0.5),
            _buildProfileRow(context.translate('purok'), _user?.purok ?? "Purok 3"),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: AppDecorations.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.translate('push_notifications'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
                Text(context.translate('receive_notifications'), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Switch(
            value: _pushNotifications,
            onChanged: _updatePushNotification,
            activeColor: AppColors.tealText,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard() {
    return Container(
      decoration: AppDecorations.cardDecoration(),
      child: _buildActionRow(Icons.language_rounded, LanguageService().currentLanguage, _showLanguageSelector),
    );
  }

  void _showLanguageSelector() {
    final langService = LanguageService();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Text(context.translate('select_language'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: langService.languages.length,
                  itemBuilder: (context, index) {
                    final l = langService.languages[index];
                    final isSelected = l == langService.currentLanguage;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(l, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500, color: isSelected ? AppColors.tealText : const Color(0xFF4A4A4A))),
                      trailing: isSelected ? const Icon(Icons.check_box_rounded, color: AppColors.tealText) : Icon(Icons.check_box_outline_blank_rounded, color: Colors.grey.shade300),
                      onTap: () {
                        langService.setLanguage(l);
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

  Widget _buildAccountCard() {
    return Container(
      decoration: AppDecorations.cardDecoration(),
      child: Column(
        children: [
          _buildActionRow(Icons.password_rounded, context.translate('change_password'), _showChangePasswordModal),
          const Divider(height: 1, indent: 64),
          _buildActionRow(Icons.storage_rounded, context.translate('data_management'), _showDataManagementModal),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      decoration: AppDecorations.cardDecoration(),
      child: Column(
        children: [
          _buildActionRow(Icons.quiz_rounded, context.translate('faqs'), _showFAQsModal),
          const Divider(height: 1, indent: 64),
          _buildActionRow(Icons.support_agent_rounded, context.translate('contact_support'), _showContactSupportModal),
          const Divider(height: 1, indent: 64),
          _buildActionRow(Icons.info_outline_rounded, context.translate('about'), _showAboutModal),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecorations.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.translate('app_info'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50))),
          const SizedBox(height: 16),
          _buildInfoRow(context.translate('version'), "1.0.0"),
          const SizedBox(height: 12),
          _buildInfoRow(context.translate('last_updated'), "July 2026"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
      ],
    );
  }

  Widget _buildActionRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF3F5F7), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: AppColors.tealText),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2C3E50)))),
            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _showLogoutDialog(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealText,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(context.translate('logout'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
      ),
    );
  }

  // --- LOGIC & MODALS ---

  void _showEditProfileModal() {
    final nameController = TextEditingController(text: _user?.name);
    final emailController = TextEditingController(text: _user?.email);
    final phoneController = TextEditingController(text: _user?.phone);
    final addressController = TextEditingController(text: _user?.completeAddress);
    String selectedPurok = _user?.purok ?? "Sentro";

    _showStyledBottomSheet(
      title: context.translate('edit_profile'),
      children: [
        _buildTextField(context.translate('full_name'), nameController),
        const SizedBox(height: 16),
        _buildTextField(context.translate('email'), emailController, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField(context.translate('phone'), phoneController, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildPurokDropdown(selectedPurok, (val) => selectedPurok = val!),
        const SizedBox(height: 16),
        _buildTextField(context.translate('address'), addressController, maxLines: 2),
        const SizedBox(height: 24),
        _buildSaveButton(() async {
          if (nameController.text.isEmpty || phoneController.text.isEmpty || emailController.text.isEmpty) {
             CustomNotification.showTopNotification(context, context.translate('error'));
             return;
          }
          setState(() => _isLoading = true);
          try {
            final response = await _apiService.updateProfile(
              userId: _user!.userId,
              role: _user!.role,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              phone: phoneController.text.trim(),
              address: addressController.text.trim(),
            );
            
            await _database.ref('residents/${_user!.userId}').update({
              'name': nameController.text.trim(),
              'email': emailController.text.trim(),
              'phone': phoneController.text.trim(),
              'purok': selectedPurok,
              'complete_address': addressController.text.trim(),
            });

            if (response.data['success'] == true) {
               final updatedUser = {..._user!.toJson(), 
                'name': nameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'purok': selectedPurok,
                'complete_address': addressController.text.trim(),
               };
               await SessionManager.saveUser(updatedUser);
               _loadUser();
               if (widget.onProfileUpdate != null) widget.onProfileUpdate!();
               if (mounted) {
                 Navigator.pop(context);
                 CustomNotification.showTopNotification(context, context.translate('success'), false);
               }
            }
          } catch (e) {
             CustomNotification.showTopNotification(context, "${context.translate('error')}: $e");
          } finally {
             if (mounted) setState(() => _isLoading = false);
          }
        }),
      ],
    );
  }

  void _showChangePasswordModal() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    _showStyledBottomSheet(
      title: context.translate('change_password'),
      children: [
        StatefulBuilder(builder: (context, setModalState) {
          return Column(
            children: [
              _buildTextField(context.translate('password'), oldPass, isPassword: true, obscureText: obscureOld, onToggle: () => setModalState(() => obscureOld = !obscureOld)),
              const SizedBox(height: 16),
              _buildTextField(context.translate('new_password'), newPass, isPassword: true, obscureText: obscureNew, onToggle: () => setModalState(() => obscureNew = !obscureNew)),
              const SizedBox(height: 16),
              _buildTextField(context.translate('confirm_password'), confirmPass, isPassword: true, obscureText: obscureConfirm, onToggle: () => setModalState(() => obscureConfirm = !obscureConfirm)),
            ],
          );
        }),
        const SizedBox(height: 24),
        _buildSaveButton(() async {
          if (newPass.text != confirmPass.text) {
             CustomNotification.showTopNotification(context, context.translate('error'));
             return;
          }
          if (newPass.text.length < 6) {
             CustomNotification.showTopNotification(context, context.translate('error'));
             return;
          }
          
          setState(() => _isLoading = true);
          try {
            final res = await _apiService.changePassword(_user!.userId, _user!.role, oldPass.text, newPass.text);
            if (res.data['success'] == true) {
               if (mounted) {
                 Navigator.pop(context);
                 CustomNotification.showTopNotification(context, context.translate('success'), false);
               }
            } else {
               CustomNotification.showTopNotification(context, res.data['message'] ?? context.translate('error'));
            }
          } catch (e) {
            CustomNotification.showTopNotification(context, "Error: $e");
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        }),
      ],
    );
  }

  void _showDataManagementModal() {
    _showStyledBottomSheet(
      title: context.translate('data_mgmt'),
      children: [
        _buildModalActionRow(Icons.visibility_rounded, context.translate('view_my_data'), () => _showMyDataDialog()),
        _buildModalActionRow(Icons.cleaning_services_rounded, context.translate('clear_cache'), () {
           CustomNotification.showTopNotification(context, context.translate('success'), false);
        }),
        _buildModalActionRow(Icons.delete_forever_rounded, context.translate('delete_account'), () => _showDeleteAccountConfirmation(), isDestructive: true),
        const SizedBox(height: 12),
      ],
    );
  }

  void _showMyDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("My Data Summary", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDataText("Name", _user?.name),
              _buildDataText("Email", _user?.email),
              _buildDataText("Purok", _user?.purok),
              _buildDataText("Created At", _user?.createdAt),
              _buildDataText("Account Status", _user?.isArchived == 0 ? "Active" : "Archived"),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditProfileModal();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealText, foregroundColor: Colors.white),
            child: const Text("EDIT INFO"),
          ),
        ],
      ),
    );
  }

  Widget _buildDataText(String label, String? val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(val ?? "N/A", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Permanently Delete Account?", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.red)),
        content: const Text("This action cannot be undone. All your data including complaints and history will be permanently erased."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final res = await _apiService.deleteUser(_user!.userId, _user!.role);
                if (res.data['success'] == true) {
                   await SessionManager.logout();
                   if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              } catch (e) {
                CustomNotification.showTopNotification(context, "Delete failed: $e");
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("DELETE PERMANENTLY", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showFAQsModal() {
    _showStyledBottomSheet(
      title: context.translate('faqs'),
      children: [
        _buildFAQItem(context.translate('faq_q1'), context.translate('faq_a1')),
        _buildFAQItem(context.translate('faq_q2'), context.translate('faq_a2')),
        _buildFAQItem(context.translate('faq_q3'), context.translate('faq_a3')),
        _buildFAQItem(context.translate('faq_q4'), context.translate('faq_a4')),
      ],
    );
  }

  void _showContactSupportModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    context.translate('contact_support'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                context.translate('support_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 32),
              _buildContactDetailRow(Icons.phone_rounded, "+63 912 345 6789"),
              const SizedBox(height: 16),
              _buildContactDetailRow(Icons.email_rounded, "support@garbagetracker.com"),
              const SizedBox(height: 16),
              _buildContactDetailRow(Icons.map_rounded, "Barangay Hall, Purok 2, City Center"),
              const SizedBox(height: 48),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.translate('close'),
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.black87),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  void _showAboutModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 12),
                  Text(
                    context.translate('about'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                context.translate('about_desc1'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF424242), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.translate('about_desc2'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF424242), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              Text(
                "${context.translate('version')} 1.0.0",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                "© 2026 ${context.translate('app_name')} Team",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.translate('close'),
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---

  void _showStyledBottomSheet({required String title, required List<Widget> children}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggle, TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F5F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility), onPressed: onToggle) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPurokDropdown(String selected, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Purok / Area", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selected,
          items: _puroks.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF3F5F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.tealText, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }

  Widget _buildModalActionRow(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : AppColors.tealText),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDestructive ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem(String q, String a) {
    return ExpansionTile(
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(a, style: TextStyle(color: Colors.grey.shade700, height: 1.5)))],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(context.translate('sign_out_q'), style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(context.translate('sign_out_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'), style: const TextStyle(color: Colors.black))),
          TextButton(
            onPressed: () async {
              await SessionManager.logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: Text(context.translate('logout'), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MenuOption {
  final String title; final IconData icon; final VoidCallback onTap;
  _MenuOption(this.title, this.icon, this.onTap);
}
