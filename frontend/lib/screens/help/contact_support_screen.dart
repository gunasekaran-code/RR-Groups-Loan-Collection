import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/glass_toast.dart';
import '../../widgets/app_shell.dart';

/// Contact Support screen — quick contact channels plus a message form,
/// themed to match the RR Groups Loan & Collection Suite brand.
///
/// TODO(backend): replace placeholder phone/email/hours below with real
/// values, and wire _sendMessage() to POST /api/support/tickets.
/// TODO: wire the call/email/WhatsApp tiles to url_launcher once the
/// package is added to pubspec.yaml (tel:, mailto:, https://wa.me/…).
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  static const String _supportPhone = '+91 90000 00000';
  static const String _supportEmail = 'support@rrgroupscbe.com';
  static const String _supportWhatsapp = '+91 90000 00000';
  static const String _supportHours = 'Mon–Sat, 9:30 AM – 6:30 PM IST';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _notify(String label) {
    ToastService.show(
      title: label,
      message: 'Connect backend to enable',
      type: ToastType.info,
    );
  }

  void _sendMessage() {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ToastService.show(
        title: 'Missing details',
        message: 'Please fill in both subject and message',
        type: ToastType.error,
      );
      return;
    }
    // TODO(backend): POST { subject, message } to /api/support/tickets
    ToastService.show(
      title: 'Message sent',
      message: 'Our team will get back to you shortly',
      type: ToastType.success,
    );
    _subjectCtrl.clear();
    _messageCtrl.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: AppRoutes.profile,
      title: 'Contact Support',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Brand header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.kGold.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_outlined,
                      color: AppColors.kGold, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RR Groups',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextDark)),
                      Text('Loan & Collection Suite',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.kTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'We\'re here to help',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reach us directly or send a message and our support team '
            'will get back to you.',
            style:
                TextStyle(fontSize: 13, color: AppColors.kTextMuted, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Quick contact channels
          _ContactChannelTile(
            icon: Icons.call_outlined,
            label: 'Call Support',
            value: _supportPhone,
            onTap: () => _notify('Call Support'),
          ),
          const SizedBox(height: 10),
          _ContactChannelTile(
            icon: Icons.chat_bubble_outline,
            label: 'WhatsApp',
            value: _supportWhatsapp,
            onTap: () => _notify('WhatsApp'),
          ),
          const SizedBox(height: 10),
          _ContactChannelTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _supportEmail,
            onTap: () => _notify('Email Support'),
          ),
          const SizedBox(height: 10),
          _ContactChannelTile(
            icon: Icons.schedule_outlined,
            label: 'Support Hours',
            value: _supportHours,
            onTap: null,
          ),

          const SizedBox(height: 22),
          const Text(
            'SEND A MESSAGE',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextMuted,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SUBJECT',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Issue with EMI calculation',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('MESSAGE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted,
                        letterSpacing: 0.3)),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Describe your issue or question…',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_outlined, size: 16),
                    label: const Text('Send Message'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.kGoldLight.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kGoldDark.withOpacity(0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined,
                    size: 16, color: AppColors.kGoldDark),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ISO 27001 · RBI compliant — your data stays protected '
                    'with signed sessions and role-based access.',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.kTextDark.withOpacity(0.85),
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ContactChannelTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ContactChannelTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.kInfo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: AppColors.kInfo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextMuted)),
                      const SizedBox(height: 2),
                      Text(value,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.kTextDark)),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      size: 18, color: AppColors.kTextMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
