import 'package:flutter/material.dart';
import 'payment_screen.dart';

const _headerTextColor = Color(0xFF0D1B2A);
const _primaryTextColor = Color(0xFF111A3A);
const _secondaryTextColor = Color(0xFF6F7585);
const _accentColor = Color(0xFFFF6B35);
const _summaryBackgroundColor = Color(0xFFF3F4F7);
const _cardBorderColor = Color(0xFFE2E6EF);

enum BookingMode { contactOnline, inPerson }

class BookingSummaryScreen extends StatefulWidget {
  const BookingSummaryScreen({
    super.key,
    required this.lawyerId,
    required this.lawyerName,
    required this.selectedDate,
    required this.totalFee,
    this.selectedTime = '10:00 AM',
    this.initialMode = BookingMode.contactOnline,
  });

  final String lawyerId;
  final String lawyerName;
  final DateTime selectedDate;
  final String selectedTime;
  final String totalFee;
  final BookingMode initialMode;

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  late BookingMode _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  String get _modeLabel {
    if (_selectedMode == BookingMode.contactOnline) {
      return 'Contact Online';
    }
    return 'In-Person Meeting';
  }

  String _formatDate(DateTime date) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          'Select Mode',
          style: TextStyle(
            color: _headerTextColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 14.0 : 20.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ModeOptionCard(
                      title: 'Contact Online',
                      icon: Icons.chat_bubble_outline_rounded,
                      selected: _selectedMode == BookingMode.contactOnline,
                      onTap: () {
                        setState(() {
                          _selectedMode = BookingMode.contactOnline;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _ModeOptionCard(
                      title: 'In-Person Meeting',
                      icon: Icons.location_on_outlined,
                      selected: _selectedMode == BookingMode.inPerson,
                      onTap: () {
                        setState(() {
                          _selectedMode = BookingMode.inPerson;
                        });
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: _summaryBackgroundColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: _primaryTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _SummaryRow(
                            label: 'Lawyer Name',
                            value: widget.lawyerName,
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(
                            label: 'Date',
                            value: _formatDate(widget.selectedDate),
                          ),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Time', value: widget.selectedTime),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Mode', value: _modeLabel),
                          const SizedBox(height: 10),
                          _SummaryRow(label: 'Total Fee', value: widget.totalFee),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AccountDetailsScreen(
                                lawyerId: widget.lawyerId,
                                lawyerName: widget.lawyerName,
                                date: _formatDate(widget.selectedDate),
                                time: widget.selectedTime,
                                mode: _modeLabel,
                                totalFee: widget.totalFee,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Proceed to Payment',
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
            );
          },
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _accentColor : _cardBorderColor,
            width: selected ? 2.8 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (selected ? _accentColor : _headerTextColor).withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected ? _accentColor : _headerTextColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _primaryTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: selected
                  ? const Icon(
                      Icons.check_circle,
                      color: _accentColor,
                      size: 24,
                    )
                  : const Icon(
                      Icons.radio_button_unchecked,
                      color: Color(0xFFB7BFCE),
                      size: 22,
                    ),
            ),
          ],
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
        const SizedBox(width: 10),
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
