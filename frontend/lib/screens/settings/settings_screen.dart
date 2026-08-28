import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../theme/locale_controller.dart';
import '../../theme/theme_controller.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/session_service.dart';
import '../../screens/help/contact_support_screen.dart';
import '../../screens/help/faq_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _paymentReminders = true;
  bool _groupUpdates = true;
  // bool _biometricLogin = false;
  
  bool get _darkMode => ThemeController.mode.value == ThemeMode.dark;

  void _notify(String label, AppLocalizations l10n) {
    ToastService.show(
      title: label,
      message: l10n.connectBackendToEnable,
      type: ToastType.info,
    );
  }

  void _openLanguagePicker() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.kSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Text(
                      l10n.selectLanguage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark,
                      ),
                    ),
                  ],
                ),
              ),
              for (final option in LocaleController.supported.entries)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: Text(
                    option.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.kTextDark,
                    ),
                  ),
                  trailing: option.value == LocaleController.locale.value
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.kGold.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: AppColors.kGold, size: 20),
                        )
                      : null,
                  onTap: () {
                    // Persists against the signed-in user's id (not just this
                    // device), so it's restored on their next login here.
                    LocaleController.setForUser(
                      SessionService.instance.currentUser?.userId ?? '',
                      option.value,
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.logout,
          style: const TextStyle(
            color: AppColors.kTextDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n.confirmLogoutQuestion,
          style: const TextStyle(color: AppColors.kTextMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.cancel,
              style: const TextStyle(
                color: AppColors.kTextMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kDanger.withOpacity(0.1),
              foregroundColor: AppColors.kDanger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.logout,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO(backend): clear auth/session, then route to login.
      _notify(l10n.loggedOut, l10n);
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return AppShell(
      currentRoute: AppRoutes.settings,
      title: l10n.settings,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // 1. Premium Profile Card
          _buildProfileCard(context, l10n),
          
          const SizedBox(height: 28),
          
          // 2. Notifications Section
          _Section(
            title: l10n.notifications,
            children: [
              _SwitchTile(
                icon: Icons.payments_rounded,
                iconColor: AppColors.kGold,
                label: l10n.paymentReminders,
                value: _paymentReminders,
                onChanged: (v) => setState(() => _paymentReminders = v),
              ),
              _SwitchTile(
                icon: Icons.groups_rounded,
                iconColor: AppColors.kInfo,
                label: l10n.groupUpdates,
                value: _groupUpdates,
                onChanged: (v) => setState(() => _groupUpdates = v),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 3. Preferences Section
          _Section(
            title: l10n.preferences,
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                iconColor: const Color(0xFF9C27B0), // Soft purple for language
                label: l10n.language,
                trailingText: LocaleController.labelFor(
                  LocaleController.locale.value,
                ),
                onTap: _openLanguagePicker,
              ),
              _SwitchTile(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF607D8B), // Blue-grey for theme
                label: l10n.darkMode,
                value: _darkMode,
                onChanged: (v) {
                  ThemeController.mode.value =
                      v ? ThemeMode.dark : ThemeMode.light;
                  setState(() {});
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 4. Help & Support Section
          _Section(
            title: l10n.help,
            children: [
              _SettingsTile(
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF4CAF50), // Green for support
                label: l10n.contactSupport,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFFFF9800), // Orange for FAQ
                label: l10n.faq,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 36),

          // 5. Destructive Logout Button
          InkWell(
            onTap: _confirmLogout,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.kDanger.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.kDanger.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 22, color: AppColors.kDanger),
                  const SizedBox(width: 10),
                  Text(
                    l10n.logout,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kDanger,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// A beautiful, prominent profile card at the top of the settings.
  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.kGold.withOpacity(0.2),
                        AppColors.kGold.withOpacity(0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.kGold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profile,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.editProfile,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kTextMuted.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A modern grouped list section with the title appearing above the card.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextMuted,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.kBorder.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 60, right: 16),
                    child: Divider(
                      height: 1,
                      color: AppColors.kBorder.withOpacity(0.5),
                    ),
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A stylized settings tile with a colored icon background.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
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
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextDark,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.kTextMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.kTextMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A stylized switch tile with a colored icon background.
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  
  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.kTextDark,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.kGold, // Color of the toggle when ON
            activeTrackColor: AppColors.kGold.withOpacity(0.2), // Track color
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}