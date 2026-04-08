import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'client_dashboard.dart';
import 'lawyer_dashboard.dart';
import 'onboarding_screen.dart';
import 'pending_verification_screen.dart';
import 'admin_transaction_screen.dart';

class _AuthDecision {
  const _AuthDecision({
    required this.role,
    required this.isVerified,
    required this.isSuspended,
  });

  final String role;
  final bool isVerified;
  final bool isSuspended;
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<_AuthDecision> _resolveDecision(String uid) async {
    final db = FirebaseFirestore.instance;

    final lawyerDoc = await db.collection('lawyers').doc(uid).get();
    if (lawyerDoc.exists) {
      final data = lawyerDoc.data();
      final isVerified = (data?['isVerified'] as bool?) ?? false;
      final isSuspended = (data?['isSuspended'] as bool?) ?? false;
      return _AuthDecision(
        role: 'lawyer',
        isVerified: isVerified,
        isSuspended: isSuspended,
      );
    }

    final clientDoc = await db.collection('clients').doc(uid).get();
    if (clientDoc.exists) {
      final data = clientDoc.data();
      final isSuspended = (data?['isSuspended'] as bool?) ?? false;
      return _AuthDecision(
        role: 'client',
        isVerified: true,
        isSuspended: isSuspended,
      );
    }

    // Legacy fallback for records created before collection split.
    final userDoc = await db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final data = userDoc.data();
      final savedRole = (data?['role'] as String?)?.trim().toLowerCase();
      if (savedRole == 'admin') {
        return const _AuthDecision(
          role: 'admin',
          isVerified: true,
          isSuspended: false,
        );
      }
      if (savedRole == 'lawyer') {
        final verified = (data?['isVerified'] as bool?) ?? false;
        final isSuspended = (data?['isSuspended'] as bool?) ?? false;
        return _AuthDecision(
          role: 'lawyer',
          isVerified: verified,
          isSuspended: isSuspended,
        );
      }
    }

    return const _AuthDecision(
      role: 'client',
      isVerified: true,
      isSuspended: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const OnboardingScreen();
        }

        return FutureBuilder<_AuthDecision>(
          future: _resolveDecision(user.uid),
          builder: (context, decisionSnapshot) {
            if (decisionSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            final decision = decisionSnapshot.data ??
                const _AuthDecision(
                  role: 'client',
                  isVerified: true,
                  isSuspended: false,
                );

            if (decision.isSuspended) {
              return const _SuspendedAccountScreen();
            }

            if (decision.role == 'lawyer' && !decision.isVerified) {
              return const PendingVerificationScreen();
            }

            if (decision.role == 'lawyer') {
              return const LawyerDashboardScreen();
            }

            if (decision.role == 'admin') {
              return const AdminTransactionScreen();
            }

            return ClientDashboard(userName: user.displayName ?? 'Client');
          },
        );
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0D1B2A),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
    );
  }
}

class _SuspendedAccountScreen extends StatelessWidget {
  const _SuspendedAccountScreen();

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFDC2626),
                  size: 46,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Account Suspended',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B2A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your account is suspended. Please email the administrator to reactivate your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87, fontSize: 15),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
