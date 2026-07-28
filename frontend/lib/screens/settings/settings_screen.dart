import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import '../../theme/glass_toast.dart';

enum _SettingsTab { company, system, smsWhatsapp }

/// Settings screen with three panels — Company, System, SMS & WhatsApp —
/// switched by a segmented tab bar. Mobile-first: the tab bar shrinks its
/// own labels via FittedBox instead of breaking layout, and two-column
/// field groups (GST/Contact, P/r/n) stack vertically below ~600px.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsTab _tab = _SettingsTab.company;

  // Company tab — TODO(backend): load via GET /api/company, save via PUT.
  final _companyNameCtrl =
      TextEditingController(text: 'FinCollect Finance Pvt Ltd');
  final _addressCtrl = TextEditingController(
      text: '101, Prestige Towers, MG Road, Bangalore - 560001');
  final _gstCtrl = TextEditingController(text: '29ABCDE1234F1Z5');
  final _contactCtrl = TextEditingController(text: '+91 80 4567 8900');
  bool _hasLogo = false;

  // System tab — TODO(backend): load/save via GET|PUT /api/settings/system.
  double _interestRate = 24;

  // SMS & WhatsApp tab — TODO(backend): GET|PUT /api/settings/notifications.
  bool _smsEnabled = true;
  bool _whatsappEnabled = true;

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _addressCtrl.dispose();
    _gstCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  void _saveSnack(String label) {
    ToastService.show(
      title: label,
      message: 'Connect backend to enable',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return AppShell(
      currentRoute: AppRoutes.settings,
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6),
                    Text(
                      'Configure your organization, system, and communication',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Segmented tab bar — equal-width buttons, labels shrink to fit.
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TabButton(
                    icon: Icons.account_balance_outlined,
                    label: 'Company',
                    selected: _tab == _SettingsTab.company,
                    onTap: () => setState(() => _tab = _SettingsTab.company),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TabButton(
                    icon: Icons.percent_rounded,
                    label: 'System',
                    selected: _tab == _SettingsTab.system,
                    onTap: () => setState(() => _tab = _SettingsTab.system),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TabButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'SMS & WhatsApp',
                    selected: _tab == _SettingsTab.smsWhatsapp,
                    onTap: () =>
                        setState(() => _tab = _SettingsTab.smsWhatsapp),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: _buildPanel(isWide),
          ),

          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.settings_outlined,
                  size: 16, color: AppColors.kTextMuted),
              label: const Text('Back to dashboard',
                  style: TextStyle(color: AppColors.kTextMuted, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(bool isWide) {
    switch (_tab) {
      case _SettingsTab.company:
        return _buildCompanyPanel(isWide);
      case _SettingsTab.system:
        return _buildSystemPanel(isWide);
      case _SettingsTab.smsWhatsapp:
        return _buildSmsPanel();
    }
  }

  // ---------------- Company ----------------
  Widget _buildCompanyPanel(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          icon: Icons.account_balance_outlined,
          title: 'Company Profile',
          subtitle: 'Branding and business details',
        ),
        const SizedBox(height: 18),
        const _FieldLabel('COMPANY LOGO'),
        const SizedBox(height: 8),
        _buildLogoBox(),
        if (_hasLogo)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _hasLogo = false),
              child: const Text('Remove logo',
                  style: TextStyle(color: AppColors.kDanger, fontSize: 12)),
            ),
          ),
        const SizedBox(height: 12),
        const _FieldLabel('COMPANY NAME *'),
        const SizedBox(height: 6),
        TextField(controller: _companyNameCtrl),
        const SizedBox(height: 16),
        const _FieldLabel('ADDRESS'),
        const SizedBox(height: 6),
        TextField(controller: _addressCtrl, maxLines: 3),
        const SizedBox(height: 16),
        _responsiveRow(
          isWide,
          left: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('GST NUMBER'),
              const SizedBox(height: 6),
              TextField(controller: _gstCtrl)
            ],
          ),
          right: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel('CONTACT NUMBER'),
              const SizedBox(height: 6),
              TextField(
                  controller: _contactCtrl, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _saveButton(
            'Save company details', () => _saveSnack('Company details')),
      ],
    );
  }

  Widget _buildLogoBox() {
    return GestureDetector(
      onTap: () => setState(() => _hasLogo = !_hasLogo),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.kBorder),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.kBackground,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_hasLogo ? Icons.image_outlined : Icons.help_outline,
                  color: AppColors.kInfo, size: 20),
              const SizedBox(height: 8),
              Text(_hasLogo ? 'Logo attached' : 'Logo preview',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.kTextMuted)),
              const SizedBox(height: 2),
              const Text('Tap to add / remove',
                  style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- System ----------------
  Widget _buildSystemPanel(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          icon: Icons.percent_rounded,
          title: 'System Configuration',
          subtitle: 'Interest and EMI calculation settings',
        ),
        const SizedBox(height: 18),
        const _FieldLabel('DEFAULT INTEREST RATE (% P.A.)'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.percent, size: 16, color: AppColors.kTextMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _interestRate.truncateToDouble() == _interestRate
                      ? _interestRate.toStringAsFixed(0)
                      : _interestRate.toStringAsFixed(2),
                  style:
                      const TextStyle(fontSize: 15, color: AppColors.kTextDark),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() =>
                        _interestRate = (_interestRate + 1).clamp(0, 100)),
                    child: const Icon(Icons.arrow_drop_up,
                        color: AppColors.kTextMuted),
                  ),
                  InkWell(
                    onTap: () => setState(() =>
                        _interestRate = (_interestRate - 1).clamp(0, 100)),
                    child: const Icon(Icons.arrow_drop_down,
                        color: AppColors.kTextMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text('Applied to new loans when not overridden',
            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
        const SizedBox(height: 18),

        // EMI formula reference card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.kBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.kInfo.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.percent,
                        size: 16, color: AppColors.kInfo),
                  ),
                  const SizedBox(width: 10),
                  const Text('EMI Formula',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'P × r × (1 + r)ⁿ / ((1 + r)ⁿ − 1)',
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kInfo),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _responsiveWrapThree(isWide, const [
                _FormulaTerm(symbol: 'P', meaning: 'Principal loan amount'),
                _FormulaTerm(
                    symbol: 'r', meaning: 'Monthly rate (annual ÷ 12 ÷ 100)'),
                _FormulaTerm(symbol: 'n', meaning: 'Total months (tenure)'),
              ]),
              const SizedBox(height: 12),
              const Text(
                'Note: EMI is computed at origination using this amortization formula. Once a loan is created, '
                'the schedule is fixed and not affected by later global changes.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.kTextMuted, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _saveButton(
            'Save system settings', () => _saveSnack('System settings')),
      ],
    );
  }

  // ---------------- SMS & WhatsApp ----------------
  Widget _buildSmsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PanelHeader(
          icon: Icons.chat_bubble_outline,
          title: 'SMS & WhatsApp',
          subtitle: 'Automated customer communication channels',
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'SMS Notifications',
          description:
              'Send automated EMI reminders, overdue alerts, and payment receipts to customers via SMS.',
          value: _smsEnabled,
          onChanged: (v) => setState(() => _smsEnabled = v),
        ),
        const Divider(height: 28),
        _ToggleRow(
          title: 'WhatsApp Messages',
          description:
              'Deliver receipts and reminders through WhatsApp Business API. Requires verified WhatsApp Business account.',
          value: _whatsappEnabled,
          onChanged: (v) => setState(() => _whatsappEnabled = v),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.kGoldLight.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.kGoldDark.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.chat_bubble_outline,
                  size: 16, color: AppColors.kGoldDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enabling a channel activates templates but messages will only send once your provider credentials are verified in the backend.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextDark.withOpacity(0.85),
                      height: 1.35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _saveButton(
            'Save preferences', () => _saveSnack('Notification preferences')),
      ],
    );
  }

  // ---------------- Shared helpers ----------------
  Widget _responsiveRow(bool isWide,
      {required Widget left, required Widget right}) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right)
        ],
      );
    }
    return Column(children: [left, const SizedBox(height: 16), right]);
  }

  Widget _responsiveWrapThree(bool isWide, List<Widget> items) {
    if (isWide) {
      return Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: items[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          items[i],
        ],
      ],
    );
  }

  Widget _saveButton(String label, VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabButton(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.kGold : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.kTextMuted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.kTextDark,
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

class _PanelHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PanelHeader(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.kInfo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: AppColors.kInfo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.kTextDark)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.kTextMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextMuted,
          letterSpacing: 0.3),
    );
  }
}

class _FormulaTerm extends StatelessWidget {
  final String symbol;
  final String meaning;
  const _FormulaTerm({required this.symbol, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Text(symbol,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.kInfo)),
          const SizedBox(height: 4),
          Text(meaning,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.title,
      required this.description,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark)),
              const SizedBox(height: 4),
              Text(description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMuted, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(
            value: value, activeThumbColor: AppColors.kGold, onChanged: onChanged),
      ],
    );
  }
}
