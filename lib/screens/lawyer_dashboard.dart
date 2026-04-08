import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import 'lawyer_notifications.dart';
import 'settings_screen.dart';

const _headerColor = Color(0xFF0D1B2A);
const _pageColor = Color(0xFFF4F5F7);
const _cardColor = Colors.white;
const _textPrimary = Color(0xFF121826);
const _textSecondary = Color(0xFF6B7280);

class LawyerDashboardScreen extends StatefulWidget {
  const LawyerDashboardScreen({super.key});

  @override
  State<LawyerDashboardScreen> createState() => _LawyerDashboardScreenState();
}

class _LawyerDashboardScreenState extends State<LawyerDashboardScreen> {
  static const List<String> _paymentMethodOptions = <String>[
    'Easypaisa',
    'JazzCash',
    'Bank Transfer',
    'Cash',
  ];

  Stream<int> _lawyerUnreadCountStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<int>.value(0);
    }

    return NotificationService.unreadCountStream(
      uid: uid,
      role: AppNotificationRole.lawyer,
    );
  }

  static String _readFirstNonEmpty(List<Object?> candidates, String fallback) {
    for (final value in candidates) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  static double _toDouble(Object? value, [double fallback = 0]) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  static int _toInt(Object? value, [int fallback = 0]) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static String _initialsFromName(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'LL';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static String _formatCompactCurrency(Object? value) {
    final amount = _toDouble(value, 0);
    if (amount <= 0) {
      return '0';
    }
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1);
  }

  static bool _isAppointmentNotification(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toLowerCase();
    final title = (data['title'] ?? '').toString().toLowerCase();
    final body = (data['body'] ?? '').toString().toLowerCase();
    return type.contains('appointment') ||
        type.contains('booking') ||
        title.contains('appointment') ||
        title.contains('booking') ||
        title.contains('consultation') ||
        body.contains('appointment') ||
        body.contains('booking') ||
        body.contains('consultation');
  }

  static String _readStatus(Map<String, dynamic> data) {
    return _readFirstNonEmpty([
      data['status'],
      data['appointmentStatus'],
      data['requestStatus'],
    ], '').toLowerCase();
  }

  static bool _isOnline(Map<String, dynamic> data) {
    final raw = _readFirstNonEmpty([
      data['mode'],
      data['appointmentMode'],
      data['meetingType'],
    ], '').toLowerCase();
    if (raw.isNotEmpty) {
      return raw.contains('online') || raw.contains('virtual');
    }
    return ((data['isOnline'] as bool?) ?? true);
  }

  static String _clientNameFromNotification(Map<String, dynamic> data) {
    return _readFirstNonEmpty([
      data['clientName'],
      data['client_name'],
      data['senderName'],
      data['sender_name'],
      data['fromName'],
      data['name'],
    ], 'Client');
  }

  static DateTime _scheduledAt(Map<String, dynamic> data) {
    final candidates = [
      data['appointmentTime'],
      data['scheduledAt'],
      data['dateTime'],
      data['timestamp'],
      data['createdAt'],
    ];
    for (final value in candidates) {
      if (value == null) {
        continue;
      }
      return NotificationService.parseTimestamp(value);
    }
    return DateTime.now();
  }

  static String _dateLabel(DateTime value) {
    final now = DateTime.now();
    final local = value.toLocal();
    final day = DateUtils.dateOnly(local);
    final today = DateUtils.dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));

    final time = _formatTime(local);
    if (day == today) {
      return 'Today, $time';
    }
    if (day == tomorrow) {
      return 'Tomorrow, $time';
    }
    return '${_weekdayLabel(local.weekday)}, ${local.day}/${local.month} $time';
  }

  static String _weekdayLabel(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = weekday - 1;
    if (index < 0 || index >= names.length) {
      return 'Day';
    }
    return names[index];
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour12:$minute $period';
  }

  Stream<_DashboardAppointmentsData> _appointmentsStream(String uid) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('lawyer_id', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final pending = <_PendingRequest>[];
      final upcoming = <_UpcomingAppointment>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final targetLawyerId = _readFirstNonEmpty([
          data['targetLawyerId'],
          data['lawyerId'],
          data['lawyer_id'],
          data['receiverId'],
          data['receiver_id'],
        ], '');
        if (targetLawyerId != uid) {
          continue;
        }

        final scheduledAt = _scheduledAt(data);
        final status = _readStatus(data);
        final clientName = _clientNameFromNotification(data);
        final dateTime = _dateLabel(scheduledAt);

        if (status == 'pending_lawyer') {
          pending.add(
            _PendingRequest(
              id: doc.id,
              clientName: clientName,
              dateTime: dateTime,
              isOnline: _isOnline(data),
              scheduledAt: scheduledAt,
            ),
          );
        } else if (
            status == 'confirmed' ||
            status == 'accepted' ||
            status == 'approved' ||
            status == 'scheduled') {
          upcoming.add(
            _UpcomingAppointment(
              id: doc.id,
              clientName: clientName,
              dateTime: dateTime,
              status: 'Confirmed',
              scheduledAt: scheduledAt,
            ),
          );
        }
      }

      pending.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      upcoming.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return _DashboardAppointmentsData(pending: pending, upcoming: upcoming);
    });
  }

  Future<void> _updateRequestStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('transactions').doc(id).set({
      'status': status,
      'appointmentStatus': status,
      'requestStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _updateLawyerQuickSettings({
    required String uid,
    String? consultationFee,
    List<String>? paymentMethods,
  }) async {
    final payload = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      'lawyer.updatedAt': FieldValue.serverTimestamp(),
    };

    if (consultationFee != null) {
      payload['lawyer.consultationFee'] = consultationFee;
      payload['consultationFee'] = consultationFee;
    }
    if (paymentMethods != null) {
      payload['lawyer.paymentMethods'] = paymentMethods;
      payload['paymentMethods'] = paymentMethods;
    }

    await FirebaseFirestore.instance
        .collection('lawyers')
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }

  Future<void> _showConsultationFeeDialog({
    required String uid,
    required String currentFee,
  }) async {
    final controller = TextEditingController(text: currentFee);
    final newFee = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Consultation Fee'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Fee (PKR)',
              hintText: 'Enter fee amount',
            ),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newFee == null || newFee.trim().isEmpty) {
      return;
    }

    await _updateLawyerQuickSettings(uid: uid, consultationFee: newFee.trim());
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Consultation fee updated.')),
    );
  }

  Future<void> _showPaymentMethodsDialog({
    required String uid,
    required List<String> currentMethods,
  }) async {
    final selected = {...currentMethods};
    final updated = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Payment Methods'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _paymentMethodOptions.map((method) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selected.contains(method),
                        onChanged: (checked) {
                          setDialogState(() {
                            if (checked == true) {
                              selected.add(method);
                            } else {
                              selected.remove(method);
                            }
                          });
                        },
                        title: Text(method),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final list = selected.toList()..sort();
                    Navigator.of(dialogContext).pop(list);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated == null) {
      return;
    }

    await _updateLawyerQuickSettings(uid: uid, paymentMethods: updated);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment methods updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    final lawyerDocStream = uid == null
        ? const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty()
        : FirebaseFirestore.instance
            .collection('lawyers')
            .doc(uid)
            .snapshots();

    return Scaffold(
      backgroundColor: _pageColor,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: lawyerDocStream,
          builder: (context, snapshot) {
            final docData = snapshot.data?.data() ?? const <String, dynamic>{};
            final lawyerData = (docData['lawyer'] is Map)
                ? Map<String, dynamic>.from(docData['lawyer'] as Map)
                : const <String, dynamic>{};

            final displayName = _readFirstNonEmpty([
              lawyerData['name'],
              docData['name'],
              user?.displayName,
            ], 'Lawyer');
            final specialty = _readFirstNonEmpty([
              lawyerData['category'],
              docData['category'],
              docData['specialization'],
            ], 'General Lawyer');
            final rating = _toDouble(docData['rating']);
            final earnings = _formatCompactCurrency(
              docData['totalEarnings'] ??
                  docData['earnings'] ??
                  docData['monthlyEarnings'],
            );
            final initials = _initialsFromName(displayName);

            if (uid == null) {
              return const SizedBox.shrink();
            }

            return StreamBuilder<_DashboardAppointmentsData>(
              stream: _appointmentsStream(uid),
              builder: (context, appointmentSnapshot) {
                final appointmentData = appointmentSnapshot.data ??
                    const _DashboardAppointmentsData(
                      pending: <_PendingRequest>[],
                      upcoming: <_UpcomingAppointment>[],
                    );
                final pendingRequests = appointmentData.pending;
                final upcomingAppointments = appointmentData.upcoming;
                final upcomingCount = _toInt(
                  docData['upcomingCount'] ?? docData['appointmentsCount'],
                  upcomingAppointments.length,
                );
                final consultationFee = _readFirstNonEmpty([
                  lawyerData['consultationFee'],
                  docData['consultationFee'],
                ], '');
                final paymentMethodsRaw =
                    lawyerData['paymentMethods'] ?? docData['paymentMethods'];
                final paymentMethods = paymentMethodsRaw is List
                    ? paymentMethodsRaw
                        .map((e) => e.toString().trim())
                        .where((e) => e.isNotEmpty)
                        .toList()
                    : <String>[];

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
                    decoration: const BoxDecoration(
                      color: _headerColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(26),
                        bottomRight: Radius.circular(26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    specialty,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _RoundIconButton(
                              child: StreamBuilder<int>(
                                stream: _lawyerUnreadCountStream(),
                                builder: (context, snapshot) {
                                  final unread = snapshot.data ?? 0;
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      const Icon(
                                        Icons.notifications_none_rounded,
                                        color: Colors.white,
                                      ),
                                      if (unread > 0)
                                        Positioned(
                                          right: -2,
                                          top: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 2,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFE53935),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              unread > 9
                                                  ? '9+'
                                                  : unread.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const LawyerNotificationsScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            _RoundIconButton(
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFF4B400),
                                title: 'Rating',
                                value: rating.toStringAsFixed(1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.calendar_today_rounded,
                                iconColor: const Color(0xFF34A853),
                                title: 'Upcoming',
                                value: upcomingCount.toString(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.attach_money_rounded,
                                iconColor: Color(0xFF4285F4),
                                title: 'Earnings',
                                value: earnings,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionTitle('Pending Requests'),
                            const SizedBox(height: 10),
                            if (pendingRequests.isEmpty)
                              const _InfoTile(message: 'No pending requests yet.')
                            else
                              ListView.builder(
                                itemCount: pendingRequests.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final item = pendingRequests[index];
                                  return _PendingRequestCard(
                                    data: item,
                                    onAccept: () {
                                      _updateRequestStatus(item.id, 'confirmed');
                                    },
                                    onReject: () {
                                      _updateRequestStatus(item.id, 'rejected');
                                    },
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            const _SectionTitle('Upcoming Schedule'),
                            const SizedBox(height: 10),
                            if (upcomingAppointments.isEmpty)
                              const _InfoTile(
                                message: 'No upcoming appointments yet.',
                              )
                            else
                              ListView.builder(
                                itemCount: upcomingAppointments.length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final item = upcomingAppointments[index];
                                  return _UpcomingCard(data: item);
                                },
                              ),
                            const SizedBox(height: 16),
                            const _SectionTitle('Quick Settings'),
                            const SizedBox(height: 10),
                            _QuickSettingTile(
                              title: 'Consultation Fee',
                              actionLabel: 'Update',
                              subtitle: consultationFee.isEmpty
                                  ? null
                                  : 'PKR $consultationFee',
                              onTap: () {
                                _showConsultationFeeDialog(
                                  uid: uid,
                                  currentFee: consultationFee,
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            _QuickSettingTile(
                              title: 'Payment Methods',
                              actionLabel: 'Manage',
                              subtitle: paymentMethods.isEmpty
                                  ? null
                                  : paymentMethods.join(', '),
                              onTap: () {
                                _showPaymentMethodsDialog(
                                  uid: uid,
                                  currentMethods: paymentMethods,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
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
    return Text(
      title,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: _textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.data,
    required this.onAccept,
    required this.onReject,
  });

  final _PendingRequest data;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.clientName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.dateTime,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.isOnline
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    data.isOnline ? 'online' : 'offline',
                    style: TextStyle(
                      color: data.isOnline
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              SizedBox(
                width: 76,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 76,
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.data});

  final _UpcomingAppointment data;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.clientName,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.dateTime,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              data.status,
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF4285F4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickSettingTile extends StatelessWidget {
  const _QuickSettingTile({
    required this.title,
    required this.actionLabel,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String actionLabel;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((subtitle ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _PendingRequest {
  const _PendingRequest({
    required this.id,
    required this.clientName,
    required this.dateTime,
    required this.isOnline,
    required this.scheduledAt,
  });

  final String id;
  final String clientName;
  final String dateTime;
  final bool isOnline;
  final DateTime scheduledAt;
}

class _UpcomingAppointment {
  const _UpcomingAppointment({
    required this.id,
    required this.clientName,
    required this.dateTime,
    required this.status,
    required this.scheduledAt,
  });

  final String id;
  final String clientName;
  final String dateTime;
  final String status;
  final DateTime scheduledAt;
}

class _DashboardAppointmentsData {
  const _DashboardAppointmentsData({
    required this.pending,
    required this.upcoming,
  });

  final List<_PendingRequest> pending;
  final List<_UpcomingAppointment> upcoming;
}
