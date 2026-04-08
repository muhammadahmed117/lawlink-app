import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _adminBg = Color(0xFFF1F3F5);
const _adminCard = Colors.white;

class AdminTransactionScreen extends StatelessWidget {
  const AdminTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('transactions')
        .where('status', isEqualTo: 'pending_admin')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: _adminBg,
      appBar: AppBar(
        title: const Text('Pending Verifications'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load transactions: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? const [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No pending verifications.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final tx = AdminTransactionItem.fromDoc(doc);
              return _TransactionCard(item: tx);
            },
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.item});

  final AdminTransactionItem item;

  @override
  Widget build(BuildContext context) {
    final screenshotUrl = item.paymentScreenshotUrl.isEmpty
        ? 'https://placehold.co/1000x600/png?text=Payment+Screenshot'
        : item.paymentScreenshotUrl;

    return Container(
      decoration: BoxDecoration(
        color: _adminCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (_) => _ZoomImageDialog(imageUrl: screenshotUrl),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  screenshotUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE5E7EB),
                    alignment: Alignment.center,
                    child: const Text('No Screenshot'),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _detail('Client', '${item.clientName} (${item.clientId})'),
          _detail('Target', item.targetLawyerName),
          _detail('Date', item.dateLabel),
          _detail('Time', item.timeLabel),
          _detail('Fee', 'PKR ${item.feeLabel}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await verifyAndForwardTransaction(item.id);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verified and forwarded to lawyer.'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Verify & Forward'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await rejectTransaction(item.id);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request rejected.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ZoomImageDialog extends StatelessWidget {
  const _ZoomImageDialog({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'Could not load screenshot',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminTransactionItem {
  const AdminTransactionItem({
    required this.id,
    required this.paymentScreenshotUrl,
    required this.clientName,
    required this.clientId,
    required this.targetLawyerName,
    required this.dateLabel,
    required this.timeLabel,
    required this.feeLabel,
  });

  final String id;
  final String paymentScreenshotUrl;
  final String clientName;
  final String clientId;
  final String targetLawyerName;
  final String dateLabel;
  final String timeLabel;
  final String feeLabel;

  factory AdminTransactionItem.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final dateValue = _firstNonEmpty([
      data['bookingDate'],
      data['date'],
      data['appointmentDate'],
    ], 'N/A');

    final timeValue = _firstNonEmpty([
      data['bookingTime'],
      data['time'],
      data['appointmentTimeText'],
    ], 'N/A');

    return AdminTransactionItem(
      id: doc.id,
      paymentScreenshotUrl: _firstNonEmpty([
        data['paymentScreenshotUrl'],
        data['screenshotUrl'],
        data['paymentProofUrl'],
      ], ''),
      clientName: _firstNonEmpty([
        data['clientName'],
        data['client_name'],
      ], 'Client'),
      clientId: _firstNonEmpty([
        data['clientId'],
        data['client_id'],
      ], 'N/A'),
      targetLawyerName: _firstNonEmpty([
        data['targetLawyerName'],
        data['lawyerName'],
      ], 'Lawyer'),
      dateLabel: dateValue,
      timeLabel: timeValue,
      feeLabel: _firstNonEmpty([
        data['feeAmount'],
        data['fee'],
        data['totalFee'],
      ], '0'),
    );
  }

  static String _firstNonEmpty(List<Object?> candidates, String fallback) {
    for (final value in candidates) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }
}

Future<void> verifyAndForwardTransaction(String transactionId) async {
  await FirebaseFirestore.instance.collection('transactions').doc(transactionId).set({
    'status': 'pending_lawyer',
    'updatedAt': FieldValue.serverTimestamp(),
    'forwardedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

Future<void> rejectTransaction(String transactionId) async {
  await FirebaseFirestore.instance.collection('transactions').doc(transactionId).set({
    'status': 'rejected_admin',
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
