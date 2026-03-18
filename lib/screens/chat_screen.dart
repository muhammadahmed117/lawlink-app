import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const _headerColor = Color(0xFF0D1B2A);
const _senderColor = Color(0xFFFF6B35);
const _receiverBorder = Color(0xFFE3E7EE);
const _receiverText = Color(0xFF1F2A44);
const _hintText = Color(0xFF8C94A6);

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.lawyerId,
    required this.clientId,
    required this.lawyerName,
    required this.lawyerSpecialty,
    this.lawyerInitials,
    this.caseId,
  });

  final String lawyerId;
  final String clientId;
  final String lawyerName;
  final String lawyerSpecialty;
  final String? lawyerInitials;

  // Optional case identifier to keep separate chat sessions for each case.
  final String? caseId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  String get _chatSessionId {
    final List<String> participants = [widget.clientId, widget.lawyerId]..sort();
    final String base = participants.join('_');
    if (widget.caseId != null && widget.caseId!.trim().isNotEmpty) {
      return '${widget.caseId}_$base';
    }
    return base;
  }

  String get _lawyerInitials {
    final String custom = widget.lawyerInitials?.trim() ?? '';
    if (custom.isNotEmpty) {
      return custom;
    }
    final List<String> parts = widget.lawyerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'LW';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _messageStream() {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatSessionId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatSessionId)
          .set(
            {
              'clientId': widget.clientId,
              'lawyerId': widget.lawyerId,
              'caseId': widget.caseId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatSessionId)
          .collection('messages')
          .add(
            {
              'senderId': widget.clientId,
              'senderType': 'client',
              'text': text,
              'createdAt': FieldValue.serverTimestamp(),
            },
          );

      _messageController.clear();
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) {
      return '--:--';
    }
    final DateTime dt = timestamp.toDate();
    int hour = dt.hour;
    final int minute = dt.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) {
      hour = 12;
    }
    final String hh = hour.toString().padLeft(2, '0');
    final String mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm $period';
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            color: _headerColor,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white12,
                  child: Text(
                    _lawyerInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lawyerName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.lawyerSpecialty,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD2D9E7),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.call_outlined, color: Colors.white),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _messageStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Unable to load messages. Check Firebase setup and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Start the conversation.',
                        style: TextStyle(
                          color: Color(0xFF8B93A4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final Map<String, dynamic> data = docs[index].data();
                      final String text = (data['text'] ?? '').toString();
                      final String senderId = (data['senderId'] ?? '').toString();
                      final Timestamp? createdAt = data['createdAt'] is Timestamp
                          ? data['createdAt'] as Timestamp
                          : null;

                      final bool isClient = senderId == widget.clientId;
                      final Alignment alignment =
                          isClient ? Alignment.centerRight : Alignment.centerLeft;

                      final BorderRadius bubbleRadius = isClient
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(5),
                            )
                          : const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(5),
                              bottomRight: Radius.circular(16),
                            );

                      final Color bubbleColor = isClient ? _senderColor : Colors.white;
                      final Color textColor = isClient ? Colors.white : _receiverText;

                      return Align(
                        alignment: alignment,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: isClient
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: bubbleRadius,
                                    border: isClient
                                        ? null
                                        : Border.all(color: _receiverBorder),
                                  ),
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(createdAt),
                                  style: const TextStyle(
                                    color: Color(0xFF8F97A9),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.attach_file, color: Color(0xFF7E879C)),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE3E7EE)),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(color: _hintText),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _sendMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _senderColor,
                          shape: const CircleBorder(),
                          padding: EdgeInsets.zero,
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
