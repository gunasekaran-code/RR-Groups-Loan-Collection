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
  final Color iconColor;
  final List<_FaqEntry> items;
  const _FaqGroup(this.title, this.icon, this.iconColor, this.items);
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  static const List<_FaqGroup> _groups = [
    _FaqGroup('General', Icons.info_outline_rounded, Color(0xFF2196F3), [
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
    _FaqGroup('Loans & EMI', Icons.percent_rounded, AppColors.kGold, [
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
    _FaqGroup('Field Collections', Icons.map_rounded, Color(0xFF4CAF50), [
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
    _FaqGroup('Chit Funds', Icons.groups_rounded, Color(0xFF9C27B0), [
      _FaqEntry(
        'Can I run chit funds on this platform?',
        'Yes. RR Groups supports end-to-end chit fund management — '
            'members, monthly contributions and payout tracking are all '
            'handled in one place.',
      ),
    ]),
    _FaqGroup('Security', Icons.lock_outline_rounded, Color(0xFFFF9800), [
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
              g.iconColor,
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
      showBackButton: true, // Handled by AppShell Top Bar
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: [
          // Header titles inside body
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 2),
            child: Text(
              'RR Groups · Help Center',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 20),
            child: Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextDark,
              ),
            ),
          ),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: AppColors.kSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.kBorder.withOpacity(0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.kTextDark, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Search questions or keywords…',
                hintStyle: TextStyle(
                  color: AppColors.kTextMuted.withOpacity(0.6),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: AppColors.kTextMuted,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            size: 18, color: AppColors.kTextMuted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Results Section
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.kTextMuted.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search_off_rounded,
                      size: 36,
                      color: AppColors.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No questions found matching "$_query"',
                    style: const TextStyle(
                      color: AppColors.kTextMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            for (final group in results) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: group.iconColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(group.icon, size: 16, color: group.iconColor),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      group.title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
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
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < group.items.length; i++) ...[
                        if (i > 0)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                              height: 1,
                              color: AppColors.kBorder.withOpacity(0.5),
                            ),
                          ),
                        _FaqTile(entry: group.items[i]),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

          const SizedBox(height: 8),

          // Support CTA Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.kGold.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.kGold.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Can\'t find what you\'re looking for? Our dedicated support team is ready to assist you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.kTextDark.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ContactSupportScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text(
                      'Contact Support',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
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
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      iconColor: AppColors.kGold,
      collapsedIconColor: AppColors.kTextMuted,
      title: Text(
        entry.question,
        style: const TextStyle(
          fontSize: 14.5,
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
              fontSize: 13.5,
              color: AppColors.kTextMuted,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}