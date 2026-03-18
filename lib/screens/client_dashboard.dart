import 'package:flutter/material.dart';
import 'dart:async';
import 'settings_screen.dart';

const _bgColor = Color(0xFF0D1B2A);
const _surfaceColor = Color(0xFFF2F2F2);
const _cardColor = Colors.white;
const _accentColor = Color(0xFFFF6B35);
const _primaryText = Color(0xFF111A3A);
const _mutedText = Color(0xFF6C6C73);

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

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key, this.userName = 'Client'});

  final String userName;

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  bool _showWelcomeText = true;
  Timer? _welcomeTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  children: const [
                    _LegalCategoriesSection(),
                    SizedBox(height: 22),
                    _TopLawyersSection(),
                    SizedBox(height: 22),
                    _UpcomingAppointmentsSection(),
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
  });

  final String userName;
  final bool showWelcomeText;

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
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  shape: const CircleBorder(),
                ),
                onPressed: () {},
                icon: const Icon(Icons.notifications_none, color: Colors.white),
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
          const _SearchBar(),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

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
        child: const TextField(
          style: TextStyle(color: _primaryText),
          decoration: InputDecoration(
            hintText: 'Search for lawyers or legal help...',
            hintStyle: TextStyle(color: Color(0xFF8C8E99)),
            prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }
}

class _LegalCategoriesSection extends StatelessWidget {
  const _LegalCategoriesSection();

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
          itemCount: _categories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final item = _categories[index];
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
  const _TopLawyersSection();

  Widget _buildAdvocateCard(_LawyerData lawyer) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
          itemCount: _topAdvocateSections.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final section = _topAdvocateSections[index];
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
                  _buildAdvocateCard(section.advocates.first),
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

  Widget _buildAdvocateCard(_LawyerData lawyer) {
    return Card(
      color: _cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              ...visibleAdvocates.map(_buildAdvocateCard),
            ],
          );
        },
      ),
    );
  }
}

class _UpcomingAppointmentsSection extends StatelessWidget {
  const _UpcomingAppointmentsSection();

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
          itemCount: _appointments.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final appointment = _appointments[index];
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
                      onPressed: () {},
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
