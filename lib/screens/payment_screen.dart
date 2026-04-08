import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'client_dashboard.dart';

const _headerTextColor = Color(0xFF0D1B2A);
const _primaryTextColor = Color(0xFF111A3A);
const _secondaryTextColor = Color(0xFF6F7585);
const _accentColor = Color(0xFFFF6B35);
const _successColor = Color(0xFF2BA84A);

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
    required this.date,
    required this.time,
    required this.mode,
    required this.totalFee,
  });

  final String lawyerId;
  final String lawyerName;
  final String date;
  final String time;
  final String mode;
  final String totalFee;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  String? _uploadedScreenshot;
  List<int>? _uploadedScreenshotBytes;
  bool _isSubmitting = false;

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    setState(() {
      _uploadedScreenshot = result.files.single.name;
      _uploadedScreenshotBytes = result.files.single.bytes;
    });
  }

  Future<void> _submitProof() async {
    if (_uploadedScreenshot == null || _uploadedScreenshotBytes == null || _isSubmitting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload the payment screenshot first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Please sign in again before submitting payment proof.');
      }

      final clientDoc = await FirebaseFirestore.instance
          .collection('clients')
          .doc(currentUser.uid)
          .get();
      final clientName =
          (clientDoc.data()?['name'] ?? currentUser.displayName ?? 'Client')
              .toString();

      final txRef = FirebaseFirestore.instance.collection('transactions').doc();
      final proofDocPath = 'payment_docs/${txRef.id}/files/proof';
      final feeNumber = widget.totalFee.replaceAll(RegExp(r'[^0-9.]'), '');

      await FirebaseFirestore.instance.doc(proofDocPath).set({
        'file_name': _uploadedScreenshot,
        'mime_type': 'image/*',
        'bytes_base64': base64Encode(_uploadedScreenshotBytes!),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await txRef.set({
        'clientId': currentUser.uid,
        'client_id': currentUser.uid,
        'clientName': clientName,
        'client_name': clientName,
        'lawyerId': widget.lawyerId,
        'lawyer_id': widget.lawyerId,
        'lawyerName': widget.lawyerName,
        'targetLawyerName': widget.lawyerName,
        'feeAmount': feeNumber,
        'fee': feeNumber,
        'totalFee': widget.totalFee,
        'paymentProofDocPath': proofDocPath,
        'paymentProofFileName': _uploadedScreenshot,
        'status': 'pending_admin',
        'appointmentDate': widget.date,
        'appointmentTime': widget.time,
        'appointmentMode': widget.mode,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment proof submitted successfully.')),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ClientDashboard(
          initialNotificationTitle: 'Payment Proof Submitted',
          initialNotificationMessage:
              'Your payment proof for ${widget.lawyerName} has been submitted and is under review.',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: _headerTextColor),
        ),
        title: const Text(
          'Account Details',
          style: TextStyle(
            color: _headerTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        title: 'Booking Summary',
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Lawyer',
                              value: widget.lawyerName,
                            ),
                            const SizedBox(height: 10),
                            _SummaryRow(label: 'Date', value: widget.date),
                            const SizedBox(height: 10),
                            _SummaryRow(label: 'Time', value: widget.time),
                            const SizedBox(height: 10),
                            _SummaryRow(label: 'Mode', value: widget.mode),
                            const SizedBox(height: 10),
                            _SummaryRow(
                              label: 'Total Fee',
                              value: widget.totalFee,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _SectionCard(
                        title: 'Transfer To',
                        child: Column(
                          children: [
                            _SummaryRow(label: 'Bank', value: 'HBL'),
                            SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Account Title',
                              value: 'LawLink Services',
                            ),
                            SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Account Number',
                              value: '0479-1234567-1',
                            ),
                            SizedBox(height: 8),
                            _SummaryRow(
                              label: 'IBAN',
                              value: 'PK36HABB000479123456701',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Upload Payment Screenshot',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickScreenshot,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FD),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E6)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _uploadedScreenshot == null
                                    ? Icons.upload_file_outlined
                                    : Icons.check_circle,
                                color: _uploadedScreenshot == null
                                    ? _primaryTextColor
                                    : _successColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _uploadedScreenshot == null
                                      ? 'Tap to choose screenshot'
                                      : 'Selected: $_uploadedScreenshot',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _primaryTextColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: _secondaryTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload a clear receipt image to verify your payment quickly.',
                        style: TextStyle(
                          color: _secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _uploadedScreenshot == null || _isSubmitting
                      ? null
                      : _submitProof,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
