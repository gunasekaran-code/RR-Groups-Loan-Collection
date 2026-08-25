import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';
import '../../theme/locale_controller.dart';
import '../../theme/theme_controller.dart';
import '../../l10n/generated/app_localizations.dart';
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
  bool _biometricLogin = false;
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(l10n.selectLanguage,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextDark)),
              ),
              for (final option in LocaleController.supported.entries)
                ListTile(
                  title: Text(option.key,
                      style: const TextStyle(color: AppColors.kTextDark)),
                  trailing: option.value == LocaleController.locale.value
                      ? const Icon(Icons.check, color: AppColors.kGold)
                      : null,
                  onTap: () {
                    LocaleController.locale.value = option.value;
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.kSurface,
        title: Text(l10n.logout, style: TextStyle(color: AppColors.kTextDark)),
        content: Text(
          l10n.confirmLogoutQuestion,
          style: TextStyle(color: AppColors.kTextMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel,
                style: TextStyle(color: AppColors.kTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                Text(l10n.logout, style: TextStyle(color: AppColors.kDanger)),
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
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            icon: Icons.person_outline,
            title: l10n.profile,
            children: [
              _SettingsTile(
                icon: Icons.edit_outlined,
                label: l10n.editProfile,
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.notifications_outlined,
            title: l10n.notifications,
            children: [
              _SwitchTile(
                icon: Icons.payments_outlined,
                label: l10n.paymentReminders,
                value: _paymentReminders,
                onChanged: (v) => setState(() => _paymentReminders = v),
              ),
              _SwitchTile(
                icon: Icons.groups_outlined,
                label: l10n.groupUpdates,
                value: _groupUpdates,
                onChanged: (v) => setState(() => _groupUpdates = v),
              ),
            ],
          ),
          // const SizedBox(height: 14),
          // _Section(
          //   icon: Icons.lock_outline,
          //   title: l10n.security,
          //   children: [
          //     _SettingsTile(
          //       icon: Icons.pin_outlined,
          //       label: l10n.changeMpin,
          //       onTap: () => _notify(l10n.changeMpin, l10n),
          //     ),
          //     // _SwitchTile(
          //     //   icon: Icons.fingerprint,
          //     //   label: l10n.biometricLogin,
          //     //   value: _biometricLogin,
          //     //   onChanged: (v) => setState(() => _biometricLogin = v),
          //     // ),
          //   ],
          // ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.public_outlined,
            title: l10n.preferences,
            children: [
              _SettingsTile(
                icon: Icons.language_outlined,
                label: l10n.language,
                trailingText: LocaleController.labelFor(
                  LocaleController.locale.value,
                ),
                onTap: _openLanguagePicker,
              ),
              _SwitchTile(
                icon: Icons.dark_mode_outlined,
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
          const SizedBox(height: 14),
          _Section(
            icon: Icons.build_outlined,
            title: l10n.help,
            children: [
              _SettingsTile(
                icon: Icons.support_agent_outlined,
                label: l10n.contactSupport,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ContactSupportScreen()),
                ),
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                label: l10n.faq,
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
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.logout_outlined,
                          size: 20, color: AppColors.kDanger),
                      SizedBox(width: 12),
                      Text(
                        l10n.logout,
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
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.kTextDark),
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
