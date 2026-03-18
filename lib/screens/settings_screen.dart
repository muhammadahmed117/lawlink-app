import 'package:flutter/material.dart';
import 'help_support_screen.dart';

const _bgColor = Color(0xFFF2F2F2);
const _headerColor = Color(0xFF0D1B2A);
const _cardColor = Colors.white;
const _accentColor = Color(0xFFFF6B35);
const _sectionTitleColor = Color(0xFF7A7F8C);
const _primaryTextColor = Color(0xFF111A3A);
const _dangerColor = Color(0xFFD64545);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _SettingsHeader(onBackTap: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  const _SectionTitle('ACCOUNT'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: const [
                      _NavigationTile(
                        icon: Icons.person_outline,
                        iconColor: _accentColor,
                        title: 'Profile Info',
                      ),
                      _DividerLine(),
                      _NavigationTile(
                        icon: Icons.lock_outline,
                        iconColor: Color(0xFF3A86FF),
                        title: 'Change Password',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('NOTIFICATIONS'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _ToggleTile(
                        icon: Icons.notifications_none,
                        iconColor: _accentColor,
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      const _DividerLine(),
                      _ToggleTile(
                        icon: Icons.email_outlined,
                        iconColor: Color(0xFF3A86FF),
                        title: 'Email Notifications',
                        value: _emailNotifications,
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('ABOUT'),
                  const SizedBox(height: 10),
                  _SettingsCard(
                    children: [
                      _NavigationTile(
                        icon: Icons.help_outline,
                        iconColor: Color(0xFF4F5D75),
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      _DividerLine(),
                      _NavigationTile(
                        icon: Icons.article_outlined,
                        iconColor: Color(0xFF4F5D75),
                        title: 'Terms & Conditions',
                      ),
                      _DividerLine(),
                      _DangerTile(icon: Icons.logout, title: 'Logout'),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Center(
                    child: Text(
                      'LawLink v1.0.0',
                      style: TextStyle(
                        color: _sectionTitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBackTap,
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              const SizedBox(width: 2),
              const Text(
                'Settings',
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
              'Manage your account preferences',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: _sectionTitleColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _TileIcon(icon: icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          color: _primaryTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF9BA1AF)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _TileIcon(icon: icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          color: _primaryTextColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: _accentColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _TileIcon(icon: icon, color: _dangerColor),
      title: Text(
        title,
        style: const TextStyle(
          color: _dangerColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: _dangerColor),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
    );
  }
}

class _TileIcon extends StatelessWidget {
  const _TileIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, indent: 60, endIndent: 14);
  }
}
