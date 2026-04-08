import 'package:flutter/material.dart';

const _bgColor = Color(0xFFF2F2F2);
const _headerTextColor = Color(0xFF0D1B2A);
const _cardColor = Colors.white;
const _titleColor = Color(0xFF111A3A);
const _bodyColor = Color(0xFF4F5566);

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: _headerTextColor),
        ),
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: _headerTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LegalSectionCard(
                title: 'Introduction',
                body:
                    'Last updated: 19 Mar 2026\n\nBy using LawLink, you agree to these Terms & Conditions. These terms apply to all clients, lawyers, and visitors who access or use our services.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '1. Acceptance of Terms',
                body:
                    'By creating an account, booking a consultation, or accessing any LawLink feature, you acknowledge that you have read, understood, and accepted these terms.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '2. User Responsibilities',
                body:
                    'Clients must provide accurate booking and profile details. Lawyers must maintain valid professional credentials and provide lawful, ethical guidance. All users must avoid abusive behavior, false claims, and misuse of platform services.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '3. Privacy & Data Protection',
                body:
                    'LawLink handles personal data in accordance with applicable privacy standards. By using the app, you consent to the collection and processing of necessary account and booking information for operational and legal compliance purposes.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '4. Platform Liability',
                body:
                    'LawLink acts as a mediator platform connecting clients and legal professionals. LawLink is not a law firm and does not guarantee legal outcomes, case success, or legal interpretation provided by independent lawyers.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '5. Cancellation & Refunds',
                body:
                    'Appointment cancellations and refunds are subject to timing and verification policies. Refund requests may be declined for missed appointments, policy violations, or unsupported claims. Payment proof may be required for dispute handling.',
              ),
              SizedBox(height: 12),
              _LegalSectionCard(
                title: '6. Changes to Terms',
                body:
                    'LawLink may revise these terms at any time to reflect legal, operational, or security updates. Continued use of the app after updates constitutes acceptance of revised terms.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: _bodyColor,
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
