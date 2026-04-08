import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'help_support_screen.dart';
import 'profile_info_screen.dart';
import 'sign_in_screen.dart';
import 'terms_conditions_screen.dart';

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
  String _profileCollection = 'clients';
  ProfileInfoData _profileInfo = const ProfileInfoData(
    fullName: 'Ahsaan Client',
    phone: '03001234567',
    email: 'client@lawlink.com',
  );

  @override
  void initState() {
    super.initState();
    _loadProfileFromFirebase();
  }

  Future<String> _resolveProfileCollection(String uid) async {
    final db = FirebaseFirestore.instance;
    final lawyerDoc = await db.collection('lawyers').doc(uid).get();
    if (lawyerDoc.exists) {
      return 'lawyers';
    }

    final clientDoc = await db.collection('clients').doc(uid).get();
    if (clientDoc.exists) {
      return 'clients';
    }

    // Legacy fallback collection.
    return 'users';
  }

  Future<void> _loadProfileFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      _profileCollection = await _resolveProfileCollection(user.uid);
      final doc = await db.collection(_profileCollection).doc(user.uid).get();

      final data = doc.data();
        final lawyerData =
          (data?['lawyer'] is Map)
            ? Map<String, dynamic>.from(data?['lawyer'] as Map)
            : const <String, dynamic>{};
      if (!mounted) {
        return;
      }

      setState(() {
        _profileInfo = ProfileInfoData(
          fullName:
            (lawyerData['name'] as String?)?.trim().isNotEmpty == true
              ? (lawyerData['name'] as String).trim()
              : (data?['name'] as String?)?.trim().isNotEmpty == true
              ? (data!['name'] as String).trim()
                  : (user.displayName?.trim().isNotEmpty == true
                        ? user.displayName!.trim()
                        : _profileInfo.fullName),
          phone:
            (lawyerData['phone'] as String?)?.trim().isNotEmpty == true
              ? (lawyerData['phone'] as String).trim()
              : (data?['phone'] as String?)?.trim().isNotEmpty == true
              ? (data!['phone'] as String).trim()
                  : _profileInfo.phone,
          email:
            (lawyerData['email'] as String?)?.trim().isNotEmpty == true
              ? (lawyerData['email'] as String).trim()
              : (data?['email'] as String?)?.trim().isNotEmpty == true
              ? (data!['email'] as String).trim()
                  : (user.email?.trim().isNotEmpty == true
                        ? user.email!.trim()
                        : _profileInfo.email),
        );
      });
    } catch (_) {}
  }

  Future<void> _saveProfileToFirebase(ProfileInfoData updated) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user found.',
      );
    }

    _profileCollection = await _resolveProfileCollection(user.uid);

    final updatedEmail = updated.email.trim().toLowerCase();
    final currentEmail = (user.email ?? '').trim().toLowerCase();
    final emailChanged =
        updatedEmail.isNotEmpty &&
        currentEmail.isNotEmpty &&
        updatedEmail != currentEmail;

    var firestoreEmail = updatedEmail;

    if (emailChanged) {
      final currentPassword = await _askCurrentPassword(
        title: 'Confirm Password',
        message: 'Enter your current password to change your email.',
      );

      if (currentPassword == null) {
        throw FirebaseAuthException(
          code: 'email-change-cancelled',
          message: 'Email update cancelled.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      await user.verifyBeforeUpdateEmail(updatedEmail);
      throw FirebaseAuthException(
        code: 'email-verification-required',
        message:
            'Verification email sent to $updatedEmail. Open the link to complete email change.',
      );
    }

    if (_profileCollection == 'lawyers') {
      await FirebaseFirestore.instance.collection('lawyers').doc(user.uid).set({
        'lawyer.name': updated.fullName.trim(),
        'lawyer.phone': updated.phone.trim(),
        'lawyer.email': firestoreEmail,
        // Compatibility mirrors for any legacy readers still using top-level fields.
        'name': updated.fullName.trim(),
        'phone': updated.phone.trim(),
        'email': firestoreEmail,
        'lawyer.updatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': updated.fullName.trim(),
        'email': firestoreEmail,
        'phone': updated.phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      await FirebaseFirestore.instance.collection(_profileCollection).doc(user.uid).set({
        'name': updated.fullName.trim(),
        'phone': updated.phone.trim(),
        'email': firestoreEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': updated.fullName.trim(),
        'email': firestoreEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await user.updateDisplayName(updated.fullName.trim());
  }

  Future<String?> _askCurrentPassword({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    bool obscure = true;

    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscure = !obscure;
                          });
                        },
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return value;
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.email ?? '').trim().isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid signed-in account found.')),
      );
      return;
    }

    _profileCollection = await _resolveProfileCollection(user.uid);
    if (!mounted) {
      return;
    }

    final currentPassword = await _askCurrentPassword(
      title: 'Change Password',
      message: 'Enter your current password first.',
    );
    if (!mounted) {
      return;
    }
    if (currentPassword == null) {
      return;
    }

    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    final newPassword = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Set New Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final np = newPasswordController.text;
                    final cp = confirmPasswordController.text;
                    if (np.length < 6 || np != cp) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(np);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    newPasswordController.dispose();
    confirmPasswordController.dispose();

    if (newPassword == null) {
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      await FirebaseFirestore.instance
          .collection(_profileCollection)
          .doc(user.uid)
          .set({
        'passwordUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      String message = e.message ?? 'Could not update password.';
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Current password is incorrect.';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak (minimum 6 characters).';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

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
                    children: [
                      _NavigationTile(
                        icon: Icons.person_outline,
                        iconColor: _accentColor,
                        title: 'Profile Info',
                        subtitle: _profileInfo.email,
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<ProfileInfoData>(
                                MaterialPageRoute(
                                  builder: (_) => ProfileInfoScreen(
                                    initialData: _profileInfo,
                                  ),
                                ),
                              );

                          if (!context.mounted) {
                            return;
                          }

                          if (updated != null) {
                            try {
                              await _saveProfileToFirebase(updated);
                              if (!context.mounted) {
                                return;
                              }
                              setState(() {
                                _profileInfo = updated;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile details saved successfully.',
                                  ),
                                ),
                              );
                            } on FirebaseAuthException catch (e) {
                              if (!context.mounted) {
                                return;
                              }
                              String message =
                                  e.message ?? 'Could not update your account.';
                              if (e.code == 'invalid-credential' ||
                                  e.code == 'wrong-password') {
                                message =
                                    'Wrong password. Please enter your current password correctly.';
                              } else if (e.code == 'user-mismatch') {
                                message =
                                    'Wrong password. Please enter your current password correctly.';
                              } else if (e.code == 'email-already-in-use') {
                                message =
                                    'This email is already in use by another account.';
                              } else if (e.code == 'email-change-cancelled') {
                                message = 'Email update cancelled.';
                              } else if (e.code == 'requires-recent-login') {
                                message =
                                    'Please sign in again, then retry changing your email.';
                              } else if (e.code == 'email-verification-required') {
                                message =
                                    'We sent a verification link to your new email. Open it first, then sign in again.';
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            } on FirebaseException catch (e) {
                              if (!context.mounted) {
                                return;
                              }
                              final msg =
                                  (e.message ?? '').trim().isNotEmpty
                                      ? e.message!
                                      : 'Could not save profile details.';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg)),
                              );
                            }
                          }
                        },
                      ),
                      const _DividerLine(),
                      _NavigationTile(
                        icon: Icons.lock_outline,
                        iconColor: const Color(0xFF3A86FF),
                        title: 'Change Password',
                        onTap: _changePassword,
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
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsConditionsScreen(),
                            ),
                          );
                        },
                      ),
                      _DividerLine(),
                      _DangerTile(
                        icon: Icons.logout,
                        title: 'Logout',
                        onTap: _logout,
                      ),
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
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
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
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _sectionTitleColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
        activeThumbColor: _accentColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 1),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

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
      onTap: onTap,
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
