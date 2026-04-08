import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'client_notifications.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';
import 'lawyer_profile_view.dart';

const _bgColor = Color(0xFF0D1B2A);
const _surfaceColor = Color(0xFFF2F2F2);
const _cardColor = Colors.white;
const _accentColor = Color(0xFFFF6B35);
const _primaryText = Color(0xFF111A3A);
const _mutedText = Color(0xFF6C6C73);
const _alertColor = Color(0xFFD64545);

const List<_CategoryData> _categories = [
  _CategoryData(label: 'Criminal', icon: Icons.balance),
  _CategoryData(label: 'Family', icon: Icons.group),
  _CategoryData(label: 'Civil', icon: Icons.gavel),
  _CategoryData(label: 'Corporate', icon: Icons.business_center),
  _CategoryData(label: 'Property', icon: Icons.home_work_rounded),
  _CategoryData(label: 'Tax', icon: Icons.attach_money_rounded),
];

String _nameInitials(String fullName) {
  final parts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'NA';
  }
  if (parts.length == 1) {
    final first = parts.first;
    return first.length > 1
        ? first.substring(0, 2).toUpperCase()
        : first.toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

LawyerProfileData _toLawyerProfile(_LawyerData lawyer) {
  return LawyerProfileData(
    lawyerId: lawyer.id,
    clientId: 'client_001',
    initials: lawyer.initials,
    name: lawyer.name,
    specialty: lawyer.specialization,
    rating: lawyer.rating,
    ratingCount: lawyer.reviews,
    location: lawyer.city.isEmpty ? 'Pakistan' : '${lawyer.city}, Pakistan',
    consultationFee: lawyer.fee,
    experience: lawyer.years,
    about: lawyer.bio.isEmpty
      ? 'No bio added by this lawyer yet.'
      : lawyer.bio,
    paymentMethods: lawyer.paymentMethods,
    reviews: const [],
    profileImageBytes: lawyer.profileImageBytes,
  );
}

enum _AdvocateSortOrder { ascending, descending }

const List<_AppointmentData> _appointments = [];

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({
    super.key,
    this.userName = 'Client',
    this.initialNotificationTitle,
    this.initialNotificationMessage,
  });

  final String userName;
  final String? initialNotificationTitle;
  final String? initialNotificationMessage;

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  bool _showWelcomeText = true;
  Timer? _welcomeTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isFetchingVerifiedLawyers = false;
  bool _isLoadingAllVerifiedLawyers = false;
  List<_LawyerData> _allVerifiedLawyers = const [];
  List<_LawyerData> _verifiedLawyerResults = const [];
  int _searchRequestCounter = 0;
  @override
  void initState() {
    super.initState();
    if (widget.initialNotificationTitle != null &&
        widget.initialNotificationMessage != null) {
      _createClientNotification(
        title: widget.initialNotificationTitle!,
        body: widget.initialNotificationMessage!,
        type: 'message',
      );
    }
    _loadVerifiedLawyers();
    _welcomeTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showWelcomeText = false;
      });
    });
  }

  @override
  void dispose() {
    _welcomeTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(String source, String query) {
    return source.toLowerCase().contains(query);
  }

  Future<Uint8List?> _loadLawyerProfileImageBytes(String? docPath) async {
    if (docPath == null || docPath.trim().isEmpty) {
      return null;
    }
    try {
      final snap = await FirebaseFirestore.instance.doc(docPath).get();
      final data = snap.data();
      final base64 = (data?['bytes_base64'] ?? '').toString();
      if (base64.isEmpty) {
        return null;
      }
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  List<_TopAdvocateSectionData> _sectionsFromLawyers(List<_LawyerData> lawyers) {
    final Map<String, List<_LawyerData>> grouped = {};
    for (final lawyer in lawyers) {
      final key = lawyer.specialization.trim().isEmpty
          ? 'General Law'
          : lawyer.specialization;
      grouped.putIfAbsent(key, () => <_LawyerData>[]).add(lawyer);
    }

    final List<_TopAdvocateSectionData> sections = grouped.entries
        .map((entry) => _TopAdvocateSectionData(
              title: entry.key,
              advocates: entry.value,
            ))
        .toList();

    sections.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return sections;
  }

  Future<void> _loadVerifiedLawyers() async {
    if (_isLoadingAllVerifiedLawyers) {
      return;
    }

    setState(() {
      _isLoadingAllVerifiedLawyers = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('lawyers')
          .where('isVerified', isEqualTo: true)
          .limit(120)
          .get();

      final lawyers = await Future.wait(snap.docs.map((doc) async {
        final data = doc.data();
        final profile =
          (data['lawyer'] is Map)
            ? Map<String, dynamic>.from(data['lawyer'] as Map)
            : const <String, dynamic>{};
        final name = (profile['name'] ?? data['name'] ?? 'Lawyer').toString();
        final specialization =
          (profile['category'] ??
              data['category'] ??
              data['specialization'] ??
              'General Law')
                .toString();
        final yearsRaw =
          (profile['experienceYears'] ?? data['experienceYears'] ?? '0')
            .toString();
        final feeRaw =
          (profile['consultationFee'] ?? data['consultationFee'] ?? 'N/A')
            .toString();
        final cityRaw = (profile['city'] ?? data['city'] ?? '').toString().trim();
        final bioRaw = (profile['bio'] ?? data['bio'] ?? '').toString().trim();
        final ratingRaw = data['rating'];
        final reviewsRaw = data['reviewsCount'] ?? data['reviews'] ?? 0;
        final paymentMethodsRaw =
          profile['paymentMethods'] ?? data['paymentMethods'];
        final profilePicDocPath =
            (profile['profilePictureDocPath'] ?? data['profile_pic_doc_path'])
                .toString();
        final profileImageBytes = await _loadLawyerProfileImageBytes(
          profilePicDocPath,
        );

        final rating = ratingRaw is num
            ? ratingRaw.toDouble()
            : double.tryParse((ratingRaw ?? '0').toString()) ?? 0;
        final reviewsCount = reviewsRaw is num
            ? reviewsRaw.toInt()
            : int.tryParse((reviewsRaw ?? '0').toString()) ?? 0;

        final parsedMethods = paymentMethodsRaw is List
            ? paymentMethodsRaw
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList()
            : <String>[];

        return _LawyerData(
          id: doc.id,
          name: name,
          specialization: specialization,
          years: '$yearsRaw years',
          fee: 'PKR $feeRaw',
          rating: rating,
          reviews: reviewsCount,
          initials: _nameInitials(name),
          city: cityRaw,
          bio: bioRaw,
          paymentMethods: parsedMethods.isEmpty
          ? const ['Easypaisa', 'JazzCash']
          : parsedMethods,
          profileImageBytes: profileImageBytes,
        );
      }).toList());

      if (!mounted) {
        return;
      }

      setState(() {
        _allVerifiedLawyers = lawyers;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAllVerifiedLawyers = false;
        });
      }
    }
  }

  Future<void> _searchVerifiedLawyers(String query) async {
    if (_allVerifiedLawyers.isEmpty && !_isLoadingAllVerifiedLawyers) {
      await _loadVerifiedLawyers();
    }

    if (query.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFetchingVerifiedLawyers = false;
        _verifiedLawyerResults = const [];
      });
      return;
    }

    final requestId = ++_searchRequestCounter;
    setState(() {
      _isFetchingVerifiedLawyers = true;
    });

    if (!mounted || requestId != _searchRequestCounter) {
      return;
    }

    final results = _allVerifiedLawyers.where((lawyer) {
      return _matchesQuery(lawyer.name, query) ||
          _matchesQuery(lawyer.specialization, query);
    }).toList();

    setState(() {
      _isFetchingVerifiedLawyers = false;
      _verifiedLawyerResults = results;
    });
  }

  Future<void> _createClientNotification({
    required String title,
    required String body,
    required String type,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    await NotificationService.createNotification(
      uid: uid,
      role: AppNotificationRole.client,
      title: title,
      body: body,
      type: type,
    );
  }

  void _handleAppointmentMessageTap(_AppointmentData appointment) {
    _createClientNotification(
      title: 'New Message Received',
      body: '${appointment.name} sent you a message about ${appointment.dateTime}.',
      type: 'message',
    );
  }

  Stream<int> _clientUnreadCountStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream<int>.value(0);
    }

    return NotificationService.unreadCountStream(
      uid: uid,
      role: AppNotificationRole.client,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchQuery.trim().toLowerCase();
    final bool isSearching = query.isNotEmpty;

    final List<_CategoryData> filteredCategories = isSearching
        ? _categories
              .where((category) => _matchesQuery(category.label, query))
              .toList()
        : _categories;

    final List<_LawyerData> visibleLawyers = isSearching
        ? _verifiedLawyerResults
        : _allVerifiedLawyers;
    final List<_TopAdvocateSectionData> visibleSections =
        _sectionsFromLawyers(visibleLawyers);

    final List<_AppointmentData> filteredAppointments = isSearching
        ? _appointments
              .where(
                (appointment) =>
                    _matchesQuery(appointment.name, query) ||
                    _matchesQuery(appointment.dateTime, query) ||
                    _matchesQuery(appointment.status, query),
              )
              .toList()
        : _appointments;

    final bool showTopLawyers = isSearching
      ? (_isFetchingVerifiedLawyers || visibleSections.isNotEmpty)
      : (_isLoadingAllVerifiedLawyers || visibleSections.isNotEmpty);
    final bool hasResults =
        filteredCategories.isNotEmpty ||
        filteredAppointments.isNotEmpty ||
        showTopLawyers;
    final bool showCategories = filteredCategories.isNotEmpty;
    final bool showAppointments = filteredAppointments.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: FloatingActionButton(
          mini: true,
          backgroundColor: _accentColor,
          shape: const CircleBorder(),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LawLinkAiChatScreen()),
            );
          },
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: ColoredBox(
          color: _surfaceColor,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              StreamBuilder<int>(
                stream: _clientUnreadCountStream(),
                builder: (context, snapshot) {
                  final unreadAlertCount = snapshot.data ?? 0;
                  return _DashboardHeader(
                    userName: widget.userName,
                    showWelcomeText: _showWelcomeText,
                    controller: _searchController,
                    hasSearchText: _searchQuery.trim().isNotEmpty,
                    unreadAlertCount: unreadAlertCount,
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _searchVerifiedLawyers(value.trim().toLowerCase());
                    },
                    onNotificationsTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ClientNotificationsScreen(),
                        ),
                      );
                    },
                    onClearSearch: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    if (hasResults) ...[
                      if (showCategories)
                        _LegalCategoriesSection(
                          categories: filteredCategories,
                          sections: visibleSections,
                        ),
                      if (showCategories &&
                          (showTopLawyers || showAppointments))
                        const SizedBox(height: 22),
                      if (showTopLawyers)
                        (_isFetchingVerifiedLawyers || _isLoadingAllVerifiedLawyers)
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : _TopLawyersSection(
                                sections: visibleSections,
                                isSearching: isSearching,
                              ),
                      if (showTopLawyers && showAppointments)
                        const SizedBox(height: 22),
                      if (showAppointments)
                        _UpcomingAppointmentsSection(
                          appointments: filteredAppointments,
                          onMessageTap: _handleAppointmentMessageTap,
                        ),
                    ] else if (isSearching) ...[
                      _NoDashboardResultsCard(query: _searchQuery.trim()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.userName,
    required this.showWelcomeText,
    required this.controller,
    required this.hasSearchText,
    required this.unreadAlertCount,
    required this.onSearchChanged,
    required this.onNotificationsTap,
    required this.onClearSearch,
  });

  final String userName;
  final bool showWelcomeText;
  final TextEditingController controller;
  final bool hasSearchText;
  final int unreadAlertCount;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onNotificationsTap;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showWelcomeText) ...[
                      const Text(
                        'Welcome',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                      shape: const CircleBorder(),
                    ),
                    onPressed: onNotificationsTap,
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
                  if (unreadAlertCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: _alertColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadAlertCount > 9
                              ? '9+'
                              : unreadAlertCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  shape: const CircleBorder(),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                icon: const Icon(Icons.person_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _SearchBar(
            controller: controller,
            hasText: hasSearchText,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
        ],
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(color: _primaryText),
          decoration: InputDecoration(
            hintText: 'Search for lawyers or legal help...',
            hintStyle: const TextStyle(color: Color(0xFF8C8E99)),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
            suffixIcon: hasText
                ? IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}

class _LegalCategoriesSection extends StatelessWidget {
  const _LegalCategoriesSection({
    required this.categories,
    required this.sections,
  });

  final List<_CategoryData> categories;
  final List<_TopAdvocateSectionData> sections;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Legal Categories',
          style: TextStyle(
            color: _primaryText,
            fontSize: 44 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          itemCount: categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = categories[index];
            final section = sections.firstWhere(
              (entry) => entry.title.toLowerCase().contains(item.label.toLowerCase()),
              orElse: () => _TopAdvocateSectionData(
                title: item.label,
                advocates: const [],
              ),
            );
            return Material(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: section.advocates.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _TopAdvocatesViewAllScreen(
                              allSections: sections,
                              selectedSection: section,
                            ),
                          ),
                        );
                      },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, color: _accentColor, size: 34),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TopLawyersSection extends StatelessWidget {
  const _TopLawyersSection({required this.sections, required this.isSearching});

  final List<_TopAdvocateSectionData> sections;
  final bool isSearching;

  Widget _buildAdvocateCard(BuildContext context, _LawyerData lawyer) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  LawyerProfileView(profile: _toLawyerProfile(lawyer)),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40 / 2,
                backgroundColor: _bgColor,
                backgroundImage: lawyer.profileImageBytes != null
                    ? MemoryImage(lawyer.profileImageBytes!)
                    : null,
                child: lawyer.profileImageBytes == null
                    ? Text(
                        lawyer.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      style: const TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 20 / 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lawyer.specialization,
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lawyer.years,
                          style: const TextStyle(color: _mutedText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 20,
                          color: Color(0xFFF4C107),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lawyer.rating.toStringAsFixed(1)} (${lawyer.reviews})',
                          style: const TextStyle(
                            color: _mutedText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lawyer.fee,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 22 / 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'per session',
                    style: TextStyle(color: _mutedText, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Top Rated Lawyers',
                style: TextStyle(
                  color: _primaryText,
                  fontSize: 40 / 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!isSearching)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _TopAdvocatesViewAllScreen(
                        allSections: sections,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          itemCount: sections.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = sections[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: const TextStyle(
                    color: _primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (section.advocates.isNotEmpty)
                  _buildAdvocateCard(context, section.advocates.first),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TopAdvocatesViewAllScreen extends StatefulWidget {
  const _TopAdvocatesViewAllScreen({
    required this.allSections,
    this.selectedSection,
  });

  final List<_TopAdvocateSectionData> allSections;
  final _TopAdvocateSectionData? selectedSection;

  @override
  State<_TopAdvocatesViewAllScreen> createState() =>
      _TopAdvocatesViewAllScreenState();
}

class _TopAdvocatesViewAllScreenState
    extends State<_TopAdvocatesViewAllScreen> {
  _AdvocateSortOrder _sortOrder = _AdvocateSortOrder.descending;

  List<_LawyerData> _sortedAdvocates(List<_LawyerData> advocates) {
    final sorted = List<_LawyerData>.from(advocates)
      ..sort((a, b) => a.rating.compareTo(b.rating));
    if (_sortOrder == _AdvocateSortOrder.descending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  Widget _buildAdvocateCard(BuildContext context, _LawyerData lawyer) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  LawyerProfileView(profile: _toLawyerProfile(lawyer)),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40 / 2,
                backgroundColor: _bgColor,
                backgroundImage: lawyer.profileImageBytes != null
                    ? MemoryImage(lawyer.profileImageBytes!)
                    : null,
                child: lawyer.profileImageBytes == null
                    ? Text(
                        lawyer.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name,
                      style: const TextStyle(
                        color: _primaryText,
                        fontWeight: FontWeight.w700,
                        fontSize: 20 / 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lawyer.specialization,
                            style: const TextStyle(
                              color: _primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lawyer.years,
                          style: const TextStyle(color: _mutedText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 20,
                          color: Color(0xFFF4C107),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lawyer.rating.toStringAsFixed(1)} (${lawyer.reviews})',
                          style: const TextStyle(
                            color: _mutedText,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lawyer.fee,
                    style: const TextStyle(
                      color: _primaryText,
                      fontSize: 22 / 1,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Text(
                    'per session',
                    style: TextStyle(color: _mutedText, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.selectedSection == null
        ? widget.allSections
        : <_TopAdvocateSectionData>[widget.selectedSection!];

    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        title: Text(
          widget.selectedSection == null
              ? 'All Top Advocates'
              : '${widget.selectedSection!.title} Advocates',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<_AdvocateSortOrder>(
            icon: const Icon(Icons.sort, color: Colors.white),
            initialValue: _sortOrder,
            onSelected: (_AdvocateSortOrder value) {
              setState(() {
                _sortOrder = value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_AdvocateSortOrder>(
                value: _AdvocateSortOrder.ascending,
                child: Text('Rating: Ascending'),
              ),
              PopupMenuItem<_AdvocateSortOrder>(
                value: _AdvocateSortOrder.descending,
                child: Text('Rating: Descending'),
              ),
            ],
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: sections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final section = sections[index];
          final visibleAdvocates = widget.selectedSection == null
              ? _sortedAdvocates(section.advocates).take(3).toList()
              : _sortedAdvocates(section.advocates);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...visibleAdvocates.map(
                (lawyer) => _buildAdvocateCard(context, lawyer),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingAppointmentsSection extends StatelessWidget {
  const _UpcomingAppointmentsSection({
    required this.appointments,
    required this.onMessageTap,
  });

  final List<_AppointmentData> appointments;
  final ValueChanged<_AppointmentData> onMessageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(
            color: _primaryText,
            fontSize: 40 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          itemCount: appointments.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            final isConfirmed = appointment.status == 'confirmed';
            return Card(
              color: _cardColor,
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEE7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.name,
                            style: const TextStyle(
                              color: _primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            appointment.dateTime,
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isConfirmed
                                  ? const Color(0xFFCBF2D8)
                                  : const Color(0xFFF7EDB9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appointment.status,
                              style: TextStyle(
                                color: isConfirmed
                                    ? const Color(0xFF2E8B57)
                                    : const Color(0xFF8A7A12),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      style: IconButton.styleFrom(backgroundColor: _bgColor),
                      onPressed: () => onMessageTap(appointment),
                      icon: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _NoDashboardResultsCard extends StatelessWidget {
  const _NoDashboardResultsCard({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No matching results',
            style: TextStyle(
              color: _primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nothing matched "$query". Try searching by category, lawyer name, or specialization.',
            style: const TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class LawLinkAiChatScreen extends StatelessWidget {
  const LawLinkAiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'LawLink AI Chat',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                'Ask anything about legal guidance.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(color: Color(0xFF1B263B)),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      hintStyle: TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: const BoxDecoration(
                    color: _accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryData {
  const _CategoryData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _LawyerData {
  const _LawyerData({
    required this.id,
    required this.name,
    required this.specialization,
    required this.years,
    required this.fee,
    required this.rating,
    required this.reviews,
    required this.initials,
    required this.city,
    required this.bio,
    required this.paymentMethods,
    this.profileImageBytes,
  });

  final String id;
  final String name;
  final String specialization;
  final String years;
  final String fee;
  final double rating;
  final int reviews;
  final String initials;
  final String city;
  final String bio;
  final List<String> paymentMethods;
  final Uint8List? profileImageBytes;
}

class _TopAdvocateSectionData {
  const _TopAdvocateSectionData({required this.title, required this.advocates});

  final String title;
  final List<_LawyerData> advocates;
}

class _AppointmentData {
  const _AppointmentData({
    required this.name,
    required this.dateTime,
    required this.status,
  });

  final String name;
  final String dateTime;
  final String status;
}
