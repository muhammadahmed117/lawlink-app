import 'package:flutter/material.dart';

const _screenBackground = Color(0xFFF2F4F8);
const _headerBackground = Color(0xFF0D1B2A);
const _primaryText = Color(0xFF111A3A);
const _secondaryText = Color(0xFF6F7585);
const _cardBackground = Colors.white;

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<_QuickActionItem> _quickActions = [
    _QuickActionItem(
      title: 'Chat Support',
      subtitle: 'Get instant help from our team',
      icon: Icons.chat_bubble_outline_rounded,
      iconColor: Color(0xFF3A86FF),
    ),
    _QuickActionItem(
      title: 'Email Support',
      subtitle: 'Send us your query anytime',
      icon: Icons.email_outlined,
      iconColor: Color(0xFF2BA84A),
    ),
    _QuickActionItem(
      title: 'Call Support',
      subtitle: 'Speak directly with support',
      icon: Icons.call_outlined,
      iconColor: Color(0xFFFF8C42),
    ),
  ];

  static const List<_FaqSection> _faqSections = [
    _FaqSection(
      title: 'GETTING STARTED',
      items: [
        _FaqItem(
          question: 'How do I create a LawLink account?',
          answer:
              'Tap Sign Up, choose your account type, and complete the required details to get started.',
        ),
        _FaqItem(
          question: 'How can I reset my password?',
          answer:
              'On the sign in screen, tap Forgot Password and follow the instructions sent to your email.',
        ),
      ],
    ),
    _FaqSection(
      title: 'BOOKING & APPOINTMENTS',
      items: [
        _FaqItem(
          question: 'How do I book an appointment with a lawyer?',
          answer:
              'Open a lawyer profile, choose an available time slot, and confirm your booking from the appointment screen.',
        ),
        _FaqItem(
          question: 'Can I cancel or reschedule a booking?',
          answer:
              'Yes, go to your appointments and select the booking to cancel or reschedule based on the policy.',
        ),
      ],
    ),
    _FaqSection(
      title: 'AI LEGAL ASSISTANT',
      items: [
        _FaqItem(
          question: 'What can the AI Legal Assistant help with?',
          answer:
              'It can help explain legal terms, provide general guidance, and suggest next steps based on your questions.',
        ),
        _FaqItem(
          question: 'Is AI legal advice a replacement for a lawyer?',
          answer:
              'No. AI responses are informational only and should be verified with a qualified lawyer for legal decisions.',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchQuery.trim().toLowerCase();
    final bool isSearching = query.isNotEmpty;

    final List<_QuickActionItem> filteredQuickActions = isSearching
        ? _quickActions
              .where(
                (action) =>
                    '${action.title} ${action.subtitle}'.toLowerCase().contains(query),
              )
              .toList()
        : _quickActions;

    final List<_FaqSection> filteredFaqSections = _faqSections
        .map((section) {
          final List<_FaqItem> filteredItems = isSearching
              ? section.items
                    .where(
                      (item) =>
                          '${item.question} ${item.answer}'.toLowerCase().contains(query),
                    )
                    .toList()
              : section.items;
          return _FaqSection(title: section.title, items: filteredItems);
        })
        .where((section) => section.items.isNotEmpty)
        .toList();

    final bool hasResults =
        filteredQuickActions.isNotEmpty || filteredFaqSections.isNotEmpty;

    return Scaffold(
      backgroundColor: _screenBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(
                onBackTap: () => Navigator.of(context).maybePop(),
                controller: _searchController,
                hasSearchText: _searchQuery.trim().isNotEmpty,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onClearSearch: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 34),
              if (hasResults) ...[
                if (filteredQuickActions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionLabel('Quick Actions'),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (int i = 0; i < filteredQuickActions.length; i++) ...[
                          _QuickActionCard(
                            title: filteredQuickActions[i].title,
                            subtitle: filteredQuickActions[i].subtitle,
                            icon: filteredQuickActions[i].icon,
                            iconColor: filteredQuickActions[i].iconColor,
                          ),
                          if (i != filteredQuickActions.length - 1)
                            const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                ],
                if (filteredFaqSections.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: _SectionLabel('Frequently Asked Questions'),
                  ),
                  const SizedBox(height: 10),
                  ...filteredFaqSections.asMap().entries.map(
                        (entry) => Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            entry.key == filteredFaqSections.length - 1 ? 0 : 14,
                          ),
                          child: _FaqGroup(
                            title: entry.value.title,
                            items: entry.value.items,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),
                ],
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _NoResultsCard(
                    query: _searchQuery.trim(),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _StillNeedHelpCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionItem {
  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
}

class _FaqSection {
  const _FaqSection({required this.title, required this.items});

  final String title;
  final List<_FaqItem> items;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.onBackTap,
    required this.controller,
    required this.hasSearchText,
    required this.onSearchChanged,
    required this.onClearSearch,
  });

  final VoidCallback onBackTap;
  final TextEditingController controller;
  final bool hasSearchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: _headerBackground,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 62),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBackTap,
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Help Center',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Color(0xFFD0D7E2),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -24,
          child: _SearchBar(
            controller: controller,
            hasText: hasSearchText,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search help articles',
          hintStyle: TextStyle(
            color: Color(0xFF97A0B5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.search, color: Color(0xFF7D879A)),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close, color: Color(0xFF7D879A)),
                )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: _secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: ListTile(
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _primaryText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _secondaryText,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF9DA4B6)),
      ),
    );
  }
}

class _FaqGroup extends StatelessWidget {
  const _FaqGroup({required this.title, required this.items});

  final String title;
  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8A91A4),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _FaqTile(item: item),
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _NoResultsCard extends StatelessWidget {
  const _NoResultsCard({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No results found',
            style: TextStyle(
              color: _primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No help topics matched "$query". Try a different keyword.',
            style: const TextStyle(
              color: _secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7EBF2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            iconColor: const Color(0xFF97A0B5),
            collapsedIconColor: const Color(0xFF97A0B5),
            title: Text(
              item.question,
              style: const TextStyle(
                color: _primaryText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  item.answer,
                  style: const TextStyle(
                    color: _secondaryText,
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StillNeedHelpCard extends StatelessWidget {
  const _StillNeedHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _headerBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Still need help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          _ContactRow(
            icon: Icons.email_outlined,
            text: 'support@lawlink.app',
          ),
          SizedBox(height: 8),
          _ContactRow(
            icon: Icons.call_outlined,
            text: '+1 (800) 123-4567',
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: Color(0xFF38D39F)),
              SizedBox(width: 8),
              Text(
                '24/7 Support',
                style: TextStyle(
                  color: Color(0xFFDFE5F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFC9D2E3)),
        const SizedBox(width: 9),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFDFE5F0),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
