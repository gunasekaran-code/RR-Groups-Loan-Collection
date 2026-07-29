import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../theme/theme_controller.dart';
import '../../screens/help/contact_support_screen.dart';
import '../../screens/help/faq_screen.dart';


/// Settings screen — simple grouped menu (Profile, Notifications, Security,
/// Preferences, Help, Logout). Replaces the old 3-tab (Company/System/SMS)
/// settings layout with a single scrollable list of sections.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Notifications — TODO(backend): load/save via GET|PUT /api/settings/notifications.
  bool _paymentReminders = true;
  bool _groupUpdates = true;

  // Security — TODO(backend): load/save via GET|PUT /api/settings/security.
  bool _biometricLogin = false;

  // Preferences — TODO(backend): load/save via GET|PUT /api/settings/preferences.
  bool get _darkMode => ThemeController.mode.value == ThemeMode.dark;
  String _language = 'English';

  void _notify(String label) {
    ToastService.show(
      title: label,
      message: 'Connect backend to enable',
      type: ToastType.info,
    );
  }

  void _openLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        const options = ['English', 'हिन्दी', 'தமிழ்', 'తెలుగు'];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Select language',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
              ),
              for (final opt in options)
                ListTile(
                  title: Text(opt,
                      style: const TextStyle(color: AppColors.kTextDark)),
                  trailing: opt == _language
                      ? const Icon(Icons.check, color: AppColors.kGold)
                      : null,
                  onTap: () {
                    setState(() => _language = opt);
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        title: const Text('Log out',
            style: TextStyle(color: AppColors.kTextDark)),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: AppColors.kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.kDanger)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO(backend): clear auth/session, then route to login.
      _notify('Logged out');
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.settings,
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            icon: Icons.person_outline,
            title: 'Profile',
            children: [
              _SettingsTile(
                icon: Icons.edit_outlined,
                label: 'Edit Profile',
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            children: [
              _SwitchTile(
                icon: Icons.payments_outlined,
                label: 'Payment Reminders',
                value: _paymentReminders,
                onChanged: (v) => setState(() => _paymentReminders = v),
              ),
              _SwitchTile(
                icon: Icons.groups_outlined,
                label: 'Group Updates',
                value: _groupUpdates,
                onChanged: (v) => setState(() => _groupUpdates = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.lock_outline,
            title: 'Security',
            children: [
              _SettingsTile(
                icon: Icons.pin_outlined,
                label: 'Change MPIN',
                onTap: () => _notify('Change MPIN'),
              ),
              _SwitchTile(
                icon: Icons.fingerprint,
                label: 'Biometric Login',
                value: _biometricLogin,
                onChanged: (v) => setState(() => _biometricLogin = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.public_outlined,
            title: 'Preferences',
            children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                label: 'Language',
                trailingText: _language,
                onTap: _openLanguagePicker,
              ),
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
                label: 'Dark Mode',
                value: _darkMode,
                onChanged: (v) {
                  ThemeController.mode.value = v ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.build_outlined,
            title: 'Help',
            children: [
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                label: 'Contact Support',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                label: 'FAQ',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Logout — standalone, styled as a destructive action.
          Container(
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _confirmLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.logout_outlined,
                          size: 20, color: AppColors.kDanger),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kDanger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// A titled card grouping related settings tiles, e.g. "Notifications".
class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const _Section(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.kInfo),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
            children[i],
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// A tappable row with an icon, label, and chevron (optionally a trailing
/// value like the current language).
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.kTextMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.kTextDark),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextMuted),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.kTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with an icon, label, and a Switch (e.g. Dark Mode, Biometric Login).
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.kTextMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.kTextDark),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.kGold,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
