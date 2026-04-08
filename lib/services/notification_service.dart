import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum AppNotificationRole { client, lawyer }

class AppNotificationData {
  const AppNotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  final bool isRead;

  factory AppNotificationData.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return AppNotificationData(
      id: doc.id,
      title: (data['title'] ?? 'Notification').toString(),
      body: (data['body'] ?? '').toString(),
      timestamp: NotificationService.parseTimestamp(data['timestamp']),
      type: (data['type'] ?? 'general').toString(),
      isRead: (data['isRead'] as bool?) ?? false,
    );
  }
}

class NotificationService {
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('notifications');

  static Query<Map<String, dynamic>> _receiverQuery(String uid) {
    return _collection.where('receiverId', isEqualTo: uid);
  }

  static String _roleValue(AppNotificationRole role) {
    return role == AppNotificationRole.client ? 'client' : 'lawyer';
  }

  static Future<bool> hasProfile({
    required String uid,
    required AppNotificationRole role,
  }) async {
    final collection = role == AppNotificationRole.client ? 'clients' : 'lawyers';
    final snap = await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .get();
    return snap.exists;
  }

  static bool isForRole({
    required Map<String, dynamic> data,
    required String uid,
    required AppNotificationRole role,
  }) {
    final candidates = [
      data['receiverId'],
      data['receiver_id'],
      data['user_id'],
      data['userId'],
      data['uid'],
    ].map((v) => (v ?? '').toString()).where((v) => v.isNotEmpty).toSet();

    if (!candidates.contains(uid)) {
      return false;
    }

    final receiverRole =
        (data['receiverRole'] ?? data['targetRole'] ?? '').toString();
    if (receiverRole.isEmpty) {
      return true;
    }

    return receiverRole.toLowerCase() == _roleValue(role);
  }

  static Stream<int> unreadCountStream({
    required String uid,
    required AppNotificationRole role,
  }) {
    return _receiverQuery(uid).snapshots().map((snapshot) {
      var count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (isForRole(data: data, uid: uid, role: role) &&
            (data['isRead'] as bool?) != true) {
          count += 1;
        }
      }
      return count;
    });
  }

  static List<AppNotificationData> forRole({
    required Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String uid,
    required AppNotificationRole role,
  }) {
    final notifications = docs
        .where((doc) => isForRole(data: doc.data(), uid: uid, role: role))
        .map(AppNotificationData.fromFirestore)
        .toList(growable: false)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return notifications;
  }

  static Future<void> markAsRead(String id) async {
    await _collection.doc(id).update({'isRead': true});
  }

  static Future<void> markAllAsRead(
    Iterable<AppNotificationData> notifications,
  ) async {
    final unread = notifications.where((item) => !item.isRead).toList();
    if (unread.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    for (final item in unread) {
      batch.update(_collection.doc(item.id), {'isRead': true});
    }
    await batch.commit();
  }

  static Future<void> createNotification({
    required String uid,
    required AppNotificationRole role,
    required String title,
    required String body,
    required String type,
    String? status,
    DateTime? appointmentTime,
    String? clientName,
    Map<String, dynamic>? extra,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    final normalizedStatus = (status ?? 'pending').trim().toLowerCase();
    final isAppointmentLike =
        normalizedType.contains('appointment') ||
        normalizedType.contains('booking') ||
        normalizedType.contains('consultation');

    final payload = <String, dynamic>{
      'receiverId': uid,
      'receiverRole': _roleValue(role),
      'title': title,
      'body': body,
      'type': normalizedType,
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      // Backward compatibility keys already used in existing records.
      'user_id': uid,
      'userId': uid,
    };

    if (isAppointmentLike) {
      payload['status'] = normalizedStatus;
      payload['appointmentStatus'] = normalizedStatus;
      payload['requestStatus'] = normalizedStatus;
      payload['appointmentTime'] =
          appointmentTime == null ? null : Timestamp.fromDate(appointmentTime);
    }

    final trimmedClientName = (clientName ?? '').trim();
    if (trimmedClientName.isNotEmpty) {
      payload['clientName'] = trimmedClientName;
    }

    if (extra != null && extra.isNotEmpty) {
      payload.addAll(extra);
    }

    await _collection.add(payload);
  }

  static DateTime parseTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp is Timestamp) {
      return rawTimestamp.toDate();
    }
    if (rawTimestamp is DateTime) {
      return rawTimestamp;
    }
    if (rawTimestamp is String) {
      return DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 10) {
      return 'Just now';
    }
    if (diff.inMinutes < 1) {
      return Intl.plural(
        diff.inSeconds,
        one: '1 second ago',
        other: '${diff.inSeconds} seconds ago',
      );
    }
    if (diff.inHours < 1) {
      return Intl.plural(
        diff.inMinutes,
        one: '1 minute ago',
        other: '${diff.inMinutes} minutes ago',
      );
    }
    if (diff.inDays < 1) {
      return Intl.plural(
        diff.inHours,
        one: '1 hour ago',
        other: '${diff.inHours} hours ago',
      );
    }
    if (diff.inDays < 7) {
      return Intl.plural(
        diff.inDays,
        one: '1 day ago',
        other: '${diff.inDays} days ago',
      );
    }

    return DateFormat('d MMM yyyy').format(timestamp);
  }
}
