import 'package:flutter/material.dart';
import 'dart:async';
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

final List<_TopAdvocateSectionData> _topAdvocateSections = [
  _TopAdvocateSectionData(
    title: 'Criminal',
    advocates: _buildAdvocates(
      specialization: 'Criminal Law',
      feeStart: 7000,
      names: const [
        'Faraz Malik',
        'Hina Rauf',
        'Omar Javed',
        'Adeel Shafiq',
        'Nida Rameez',
        'Kamil Waqar',
        'Saba Awan',
        'Junaid Tariq',
        'Rabia Zahid',
        'Taha Karim',
      ],
    ),
  ),
  _TopAdvocateSectionData(
    title: 'Property',
    advocates: _buildAdvocates(
      specialization: 'Property Law',
      feeStart: 6500,
      names: const [
        'Ahsan Raza',
        'Mehreen Fatima',
        'Kashif Mehmood',
        'Qasim Rafique',
        'Sara Munir',
        'Ibrahim Ayaz',
        'Hira Basit',
        'Noman Saeed',
        'Ayesha Iqbal',
        'Faisal Haris',
      ],
    ),
  ),
  _TopAdvocateSectionData(
    title: 'Tax',
    advocates: _buildAdvocates(
      specialization: 'Tax Law',
      feeStart: 6000,
      names: const [
        'Saad Qureshi',
        'Nimra Tariq',
        'Bilal Hashmi',
        'Afnan Sohail',
        'Madiha Saleem',
        'Hassan Jamil',
        'Rania Feroz',
        'Talha Nabeel',
        'Zoya Danish',
        'Shayan Rao',
      ],
    ),
  ),
  _TopAdvocateSectionData(
    title: 'Civil',
    advocates: _buildAdvocates(
      specialization: 'Civil Law',
      feeStart: 5500,
      names: const [
        'Rimsha Noor',
        'Danish Sami',
        'Iqra Nadeem',
        'Aamir Khanum',
        'Minal Sabir',
        'Shahzaib Khan',
        'Zarnab Rauf',
        'Rehan Mazhar',
        'Anusha Naveed',
        'Hamid Saleh',
      ],
    ),
  ),
  _TopAdvocateSectionData(
    title: 'Corporate',
    advocates: _buildAdvocates(
      specialization: 'Corporate Law',
      feeStart: 8000,
      names: const [
        'Hamza Irfan',
        'Sahar Ali',
        'Taimoor Aslam',
        'Areej Imran',
        'Rizwan Tahir',
        'Fariha Kamal',
        'Zeeshan Noor',
        'Muneeba Yasir',
        'Adnan Junaid',
        'Laiba Shahid',
      ],
    ),
  ),
  _TopAdvocateSectionData(
    title: 'Family',
    advocates: _buildAdvocates(
      specialization: 'Family Law',
      feeStart: 5000,
      names: const [
        'Areeba Hassan',
        'Usman Khalid',
        'Maham Siddiqui',
        'Hadia Qamar',
        'Yasir Naeem',
        'Saira Akram',
        'Raza Naqvi',
        'Noor Ul Ain',
        'Kamran Arif',
        'Rida Saif',
      ],
    ),
  ),
];

List<_LawyerData> _buildAdvocates({
  required List<String> names,
  required String specialization,
  required int feeStart,
}) {
  return List<_LawyerData>.generate(names.length, (index) {
    final rating = 4.9 - (index * 0.05);
    return _LawyerData(
      name: names[index],
      specialization: specialization,
      years: '${6 + index} years',
      fee: 'PKR ${feeStart + (index * 300)}',
      rating: rating < 4.2 ? 4.2 : rating,
      reviews: 120 + (index * 13),
      initials: _nameInitials(names[index]),
    );
  });
}

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

String _lawyerIdFromName(String name) {
  final String normalized = name.trim().toLowerCase();
  final String id = normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return 'lawyer_$id';
}

LawyerProfileData _toLawyerProfile(_LawyerData lawyer) {
  return LawyerProfileData(
    lawyerId: _lawyerIdFromName(lawyer.name),
    clientId: 'client_001',
    initials: lawyer.initials,
    name: lawyer.name,
    specialty: lawyer.specialization,
    rating: lawyer.rating,
    ratingCount: lawyer.reviews,
    location: 'Lahore, Pakistan',
    consultationFee: lawyer.fee,
    experience: lawyer.years,
    about:
        'Advocate ${lawyer.name} is an experienced ${lawyer.specialization.toLowerCase()} practitioner known for practical legal strategy, clear communication, and reliable client support from consultation to final resolution.',
    paymentMethods: const ['Bank Transfer', 'Easypaisa', 'JazzCash'],
    reviews: const [
      LawyerReview(
        initials: 'AR',
        name: 'Adeel Raza',
        rating: 5,
        comment:
            'Very professional and clear in communication. Helped me understand every legal step with confidence.',
        date: '12 Feb 2026',
      ),
      LawyerReview(
        initials: 'SM',
        name: 'Sana Malik',
        rating: 5,
        comment:
            'Handled my case with great detail and responsiveness. The consultation was worth every rupee.',
        date: '03 Feb 2026',
      ),
      LawyerReview(
        initials: 'HK',
        name: 'Hassan Khan',
        rating: 5,
        comment:
            'Excellent advice and a smooth process overall. Strong command over legal details and deadlines.',
        date: '27 Jan 2026',
      ),
    ],
  );
}

enum _AdvocateSortOrder { ascending, descending }

const List<_AppointmentData> _appointments = [
  _AppointmentData(
    name: 'Amir Khan',
    dateTime: '2024-12-15 at 10:00 AM',
    status: 'confirmed',
  ),
  _AppointmentData(
    name: 'Amir Khan',
    dateTime: '2024-12-18 at 11:00 AM',
    status: 'pending',
  ),
];

List<_NotificationData> _buildInitialNotificationsFromAppointments() {
  return [
    for (final appointment in _appointments)
      _NotificationData(
        title: appointment.status == 'confirmed'
            ? 'Appointment Confirmed'
            : 'Appointment Pending',
        message: appointment.status == 'confirmed'
            ? 'Your appointment with ${appointment.name} is confirmed for ${appointment.dateTime}.'
            : 'Your appointment request with ${appointment.name} on ${appointment.dateTime} is still pending.',
        time: appointment.status == 'confirmed' ? '15 min ago' : '45 min ago',
        isAlert: true,
        isRead: false,
      ),
  ];
}

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key, this.userName = 'Client'});

  final String userName;

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  bool _showWelcomeText = true;
  Timer? _welcomeTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<_NotificationData> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _buildInitialNotificationsFromAppointments();
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

  void _markAllNotificationsRead() {
    setState(() {
      _notifications = _notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();
    });
  }

  void _addNotification(_NotificationData notification) {
    setState(() {
      _notifications = [notification, ..._notifications];
    });
  }

  void _handleAppointmentMessageTap(_AppointmentData appointment) {
    _addNotification(
      _NotificationData(
        title: 'New Message Received',
        message:
            '${appointment.name} sent you a message about ${appointment.dateTime}.',
        time: 'Just now',
        isAlert: true,
        isRead: false,
      ),
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

    final List<_TopAdvocateSectionData> filteredTopSections = isSearching
        ? _topAdvocateSections
              .map((section) {
                final List<_LawyerData> matchedAdvocates = section.advocates
                    .where(
                      (lawyer) => _matchesQuery(lawyer.name, query),
                    )
                    .toList();
                return _TopAdvocateSectionData(
                  title: section.title,
                  advocates: matchedAdvocates,
                );
              })
              .where((section) => section.advocates.isNotEmpty)
              .toList()
        : _topAdvocateSections;

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

    final bool showTopLawyers = filteredTopSections.isNotEmpty;
    final bool hasResults =
      filteredCategories.isNotEmpty ||
      filteredAppointments.isNotEmpty ||
      showTopLawyers;
    final int unreadAlertCount = _notifications
      .where((notification) => notification.isAlert && !notification.isRead)
      .length;
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
              _DashboardHeader(
                userName: widget.userName,
                showWelcomeText: _showWelcomeText,
                controller: _searchController,
                hasSearchText: _searchQuery.trim().isNotEmpty,
                unreadAlertCount: unreadAlertCount,
                onSearchChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onNotificationsTap: () {
                  _markAllNotificationsRead();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NotificationsScreen(
                        notifications: _notifications,
                      ),
                    ),
                  );
                },
                onClearSearch: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: [
                    if (hasResults) ...[
                      if (showCategories)
                        _LegalCategoriesSection(categories: filteredCategories),
                      if (showCategories && (showTopLawyers || showAppointments))
                        const SizedBox(height: 22),
                      if (showTopLawyers)
                        _TopLawyersSection(
                          sections: filteredTopSections,
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
  const _LegalCategoriesSection({required this.categories});

  final List<_CategoryData> categories;

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
            final section = _topAdvocateSections.firstWhere(
              (entry) => entry.title == item.label,
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
                            builder: (_) => TopAdvocatesViewAllScreen(
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
  const _TopLawyersSection({
    required this.sections,
    required this.isSearching,
  });

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
              builder: (_) => LawyerProfileView(profile: _toLawyerProfile(lawyer)),
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
                child: Text(
                  lawyer.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
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
                          style: const TextStyle(color: _mutedText, fontSize: 16),
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
                      builder: (_) => const TopAdvocatesViewAllScreen(),
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
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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

class TopAdvocatesViewAllScreen extends StatefulWidget {
  const TopAdvocatesViewAllScreen({super.key, this.selectedSection});

  final _TopAdvocateSectionData? selectedSection;

  @override
  State<TopAdvocatesViewAllScreen> createState() =>
      _TopAdvocatesViewAllScreenState();
}

class _TopAdvocatesViewAllScreenState extends State<TopAdvocatesViewAllScreen> {
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
              builder: (_) => LawyerProfileView(profile: _toLawyerProfile(lawyer)),
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
                child: Text(
                  lawyer.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
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
                          style: const TextStyle(color: _mutedText, fontSize: 16),
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
        ? _topAdvocateSections
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
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              ...visibleAdvocates.map((lawyer) => _buildAdvocateCard(context, lawyer)),
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

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.notifications});

  final List<_NotificationData> notifications;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = notifications[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.isAlert
                    ? const Color(0xFFFFD8CF)
                    : const Color(0xFFE5E8EF),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: item.isAlert
                        ? const Color(0xFFFFEEE9)
                        : const Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.isAlert ? Icons.warning_amber_rounded : Icons.info,
                    color: item.isAlert
                        ? const Color(0xFFE6653C)
                        : const Color(0xFF3A86FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: _primaryText,
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w700,
                              ),
                            ),
                          ),
                          if (item.isAlert)
                            const Text(
                              'ALERT',
                              style: TextStyle(
                                color: _alertColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.time,
                        style: const TextStyle(
                          color: Color(0xFF9098A8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
    required this.name,
    required this.specialization,
    required this.years,
    required this.fee,
    required this.rating,
    required this.reviews,
    required this.initials,
  });

  final String name;
  final String specialization;
  final String years;
  final String fee;
  final double rating;
  final int reviews;
  final String initials;
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

class _NotificationData {
  const _NotificationData({
    required this.title,
    required this.message,
    required this.time,
    required this.isAlert,
    required this.isRead,
  });

  final String title;
  final String message;
  final String time;
  final bool isAlert;
  final bool isRead;

  _NotificationData copyWith({
    String? title,
    String? message,
    String? time,
    bool? isAlert,
    bool? isRead,
  }) {
    return _NotificationData(
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isAlert: isAlert ?? this.isAlert,
      isRead: isRead ?? this.isRead,
    );
  }
}
