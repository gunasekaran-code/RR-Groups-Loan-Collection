import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_shell.dart';
import 'contact_support_screen.dart';

/// FAQ screen — searchable, grouped questions about RR Groups'
/// Loan & Collection Suite (loans, field collections, chit funds, security).
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqEntry {
  final String question;
  final String answer;
  const _FaqEntry(this.question, this.answer);
}

class _FaqGroup {
  final String title;
  final IconData icon;
  final List<_FaqEntry> items;
  const _FaqGroup(this.title, this.icon, this.items);
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const List<_FaqGroup> _groups = [
    _FaqGroup('General', Icons.info_outline, [
      _FaqEntry(
        'What is RR Groups Loan & Collection Suite?',
        'It\'s a real-time platform that brings loans, repayments, chit funds '
            'and field collections into one place, built for Indian lending '
            'businesses. It covers the full journey from loan origination to '
            'last-mile collection.',
      ),
      _FaqEntry(
        'Do I need to install anything?',
        'No. RR Groups works entirely in the browser on both desktop and '
            'mobile — there\'s nothing to download or install.',
      ),
      _FaqEntry(
        'What roles are supported?',
        'Two core roles: Admin/Owner, who manages the full portfolio, '
            'approves loans, assigns agents and views company-wide reports; '
            'and Collection Agent, who works a daily route, records '
            'collections and issues digital receipts.',
      ),
    ]),
    _FaqGroup('Loans & EMI', Icons.percent_rounded, [
      _FaqEntry(
        'How are EMIs calculated?',
        'EMIs are auto-generated using the standard amortization formula '
            'based on principal, interest rate and tenure. Once a loan is '
            'created, its schedule is fixed and isn\'t affected by later '
            'changes to the default rate.',
      ),
      _FaqEntry(
        'What loan plans are supported?',
        'Monthly, weekly and daily repayment plans, each with automatic '
            'EMI, interest and processing-fee calculation.',
      ),
      _FaqEntry(
        'What happens when a payment is overdue?',
        'Overdue installments are automatically flagged in the repayment '
            'schedule and surfaced in portfolio reports so admins can track '
            'and act on recovery.',
      ),
    ]),
    _FaqGroup('Field Collections', Icons.map_outlined, [
      _FaqEntry(
        'How do field agents record collections?',
        'Agents record payments on the go from their assigned daily route. '
            'Every collection generates an instant digital receipt with '
            'photo proof and the borrower\'s signature.',
      ),
      _FaqEntry(
        'How are agent routes decided?',
        'Each agent gets an optimised daily collection route, so they know '
            'exactly which customers to visit and in what order.',
      ),
      _FaqEntry(
        'Will I be notified about new assignments?',
        'Yes — agents receive real-time push alerts the moment a new '
            'collection or loan is assigned to them.',
      ),
    ]),
    _FaqGroup('Chit Funds', Icons.groups_outlined, [
      _FaqEntry(
        'Can I run chit funds on this platform?',
        'Yes. RR Groups supports end-to-end chit fund management — '
            'members, monthly contributions and payout tracking are all '
            'handled in one place.',
      ),
    ]),
    _FaqGroup('Security', Icons.lock_outline, [
      _FaqEntry(
        'How is my data secured?',
        'Every session uses signed, expiring JWT tokens, and access is '
            'role-based so admins and agents only see what they\'re scoped '
            'to. Sensitive records never leave your server.',
      ),
      _FaqEntry(
        'Where is the data hosted?',
        'RR Groups is self-hosted — it runs on your own MySQL server, so '
            'you retain full control of your data.',
      ),
      _FaqEntry(
        'How do I reset my MPIN?',
        'Go to Settings → Security → Change MPIN. You\'ll be asked to '
            'verify your identity before setting a new one.',
      ),
    ]),
  ];

  List<_FaqGroup> get _filtered {
    if (_query.trim().isEmpty) return _groups;
    final q = _query.toLowerCase();
    return _groups
        .map((g) => _FaqGroup(
              g.title,
              g.icon,
              g.items
                  .where((e) =>
                      e.question.toLowerCase().contains(q) ||
                      e.answer.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((g) => g.items.isNotEmpty)
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return AppShell(
      currentRoute: AppRoutes.profile,
      title: 'FAQ',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'RR Groups · Loan & Collection Suite',
            style: TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 4),
          const Text(
            'Frequently asked questions',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark),
          ),
          const SizedBox(height: 14),

          // Search bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.kBorder),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                hintText: 'Search questions…',
                hintStyle: TextStyle(color: AppColors.kTextMuted),
                prefixIcon:
                    Icon(Icons.search, size: 20, color: AppColors.kTextMuted),
              ),
              style: const TextStyle(color: AppColors.kTextDark),
            ),
          ),
          const SizedBox(height: 18),

          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  const Icon(Icons.search_off,
                      size: 32, color: AppColors.kTextMuted),
                  const SizedBox(height: 10),
                  Text('No results for "$_query"',
                      style:
                          const TextStyle(color: AppColors.kTextMuted)),
                ],
              ),
            )
          else
            for (final group in results) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 6),
                child: Row(
                  children: [
                    Icon(group.icon, size: 16, color: AppColors.kInfo),
                    const SizedBox(width: 8),
                    Text(
                      group.title,
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.kBorder),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < group.items.length; i++) ...[
                        if (i > 0)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(height: 1),
                          ),
                        _FaqTile(entry: group.items[i]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.kGoldLight.withOpacity(0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kGoldDark.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.kTextDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our support team can help with anything not covered here.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.kTextDark.withOpacity(0.85),
                      height: 1.4),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ContactSupportScreen()),
                      );
                    },
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: const Text('Contact Support'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _FaqEntry entry;
  const _FaqTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      iconColor: AppColors.kGold,
      collapsedIconColor: AppColors.kTextMuted,
      title: Text(
        entry.question,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextDark,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            entry.answer,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.kTextMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
