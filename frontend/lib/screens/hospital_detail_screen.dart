import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hospital.dart';
import '../services/api_service.dart';
import 'booking_form_screen.dart';


class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;
  final Position? currentPosition;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
    this.currentPosition,
  });

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late ScrollController _scrollController;
  bool _isHeaderExpanded = true;
  String? _bookingId;
  bool _isBooked = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _headerController.forward();

    _scrollController.addListener(() {
      if (_scrollController.offset > 80 && _isHeaderExpanded) {
        setState(() => _isHeaderExpanded = false);
      } else if (_scrollController.offset <= 80 && !_isHeaderExpanded) {
        setState(() => _isHeaderExpanded = true);
      }
    });

    _checkBookingStatus();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBookingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingId = prefs.getString('booking_${widget.hospital.id}');
      final bookedHospitals = prefs.getStringList('booked_hospitals') ?? [];

      setState(() {
        _bookingId = bookingId;
        _isBooked = bookedHospitals.contains(widget.hospital.id);
      });
    } catch (e) {
      // Error handling silently
    }
  }

  Future<void> _downloadConfirmation() async {
    if (_bookingId == null) return;

    setState(() => _isDownloading = true);

    try {
      await ApiService.downloadConfirmationPDF(_bookingId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation PDF downloaded successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distance =
        widget.currentPosition != null
            ? widget.hospital.distanceFrom(
              widget.currentPosition!.latitude,
              widget.currentPosition!.longitude,
            )
            : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(distance),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isBooked && _bookingId != null) ...[
                    _buildBookedInfoSection(),
                    const SizedBox(height: 20),
                  ],
                  _buildQuickActions(),
                  const SizedBox(height: 20),
                  _buildInfoSection(),
                  const SizedBox(height: 20),
                  _buildContactSection(),
                  const SizedBox(height: 20),
                  _buildBedAvailability(),
                  if (widget.hospital.specialties.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSpecialties(),
                  ],
                  if (widget.hospital.facilities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildFacilities(),
                  ],
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSliverAppBar(double? distance) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2563EB),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {}, // Favorite functionality
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.favorite_border,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title:
            _isHeaderExpanded
                ? null
                : Text(
                  widget.hospital.name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E40AF)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.hospital.name,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.hospital.category,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (distance != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookedInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDEF7EC), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF059669), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You have a booking here',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                    if (_bookingId != null)
                      Text(
                        'Booking ID: ${_bookingId!.substring(0, 12).toUpperCase()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Your booking is confirmed. Please contact the hospital to confirm your arrival time.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadConfirmation,
              icon: const Icon(Icons.download),
              label: Text(
                _isDownloading ? 'Downloading...' : 'Download Confirmation PDF',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 173, 232, 213),
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        if (widget.hospital.telephone.isNotEmpty)
          Expanded(
            child: _buildActionButton(
              icon: Icons.call,
              label: 'Call Hospital',
              color: const Color(0xFF2563EB),
              onTap: () => _makePhoneCall(widget.hospital.telephone),
            ),
          ),
        if (widget.hospital.telephone.isNotEmpty &&
            widget.hospital.emergencyNum.isNotEmpty)
          const SizedBox(width: 12),
        if (widget.hospital.emergencyNum.isNotEmpty)
          Expanded(
            child: _buildActionButton(
              icon: Icons.emergency,
              label: 'Emergency',
              color: const Color(0xFFDC2626),
              onTap: () => _makePhoneCall(widget.hospital.emergencyNum),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hospital Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Address', widget.hospital.address, Icons.location_on),
          _buildInfoRow(
            'Location',
            '${widget.hospital.district}, ${widget.hospital.state}',
            Icons.map,
          ),
          _buildInfoRow(
            'Pincode',
            widget.hospital.pincode,
            Icons.local_post_office,
          ),
          if (widget.hospital.discipline.isNotEmpty)
            _buildInfoRow(
              'Medical System',
              widget.hospital.discipline,
              Icons.medical_services,
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.hospital.telephone.isNotEmpty)
            _buildContactItem(
              'Phone',
              widget.hospital.telephone,
              Icons.phone,
              () => _makePhoneCall(widget.hospital.telephone),
            ),
          if (widget.hospital.emergencyNum.isNotEmpty)
            _buildContactItem(
              'Emergency',
              widget.hospital.emergencyNum,
              Icons.emergency,
              () => _makePhoneCall(widget.hospital.emergencyNum),
            ),
          if (widget.hospital.email.isNotEmpty)
            _buildContactItem(
              'Email',
              widget.hospital.email,
              Icons.email,
              () => _sendEmail(widget.hospital.email),
            ),
          if (widget.hospital.website.isNotEmpty)
            _buildContactItem(
              'Website',
              widget.hospital.website,
              Icons.language,
              () => _openWebsite(widget.hospital.website),
            ),
        ],
      ),
    );
  }

  Widget _buildBedAvailability() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bed Availability',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Beds',
                  widget.hospital.totalBeds.toString(),
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Available',
                  widget.hospital.availableBeds.toString(),
                  widget.hospital.availableBeds > 0
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Private Wards',
                  widget.hospital.privateWards.toString(),
                  const Color(0xFFD97706),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialties() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medical Specialties',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.hospital.specialties.map((specialty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      specialty,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilities() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Facilities',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.hospital.facilities.map((facility) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      facility,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF374151),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2563EB),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: const Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.hospital.availableBeds > 0) ...[
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "booking",
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            BookingFormScreen(hospital: widget.hospital),
                  ),
                ),
            icon: const Icon(Icons.event_available, color: Colors.white),
            label: Text(
              'Book Bed',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF059669),
          ),
        ],
        if (widget.hospital.latitude != 0 &&
            widget.hospital.longitude != 0) ...[
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "navigate",
            onPressed: _openMaps,
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: Text(
              'Navigate',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF2563EB),
          ),
        ],
        if (widget.hospital.emergencyNum.isNotEmpty) ...[
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "emergency",
            onPressed: () => _makePhoneCall(widget.hospital.emergencyNum),
            backgroundColor: const Color(0xFFDC2626),
            child: const Icon(Icons.emergency, color: Colors.white),
          ),
        ],
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      // Phone call error handled silently
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      // Email error handled silently
    }
  }

  Future<void> _openWebsite(String website) async {
    String url = website;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final Uri launchUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Website error handled silently
    }
  }

  Future<void> _openMaps() async {
    final String googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&destination=${widget.hospital.latitude},${widget.hospital.longitude}(${Uri.encodeComponent(widget.hospital.name)})';

    final Uri launchUri = Uri.parse(googleMapsUrl);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Maps error handled silently
    }
  }
}
