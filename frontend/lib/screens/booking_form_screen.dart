import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hospital.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingFormScreen extends StatefulWidget {
  final Hospital hospital;

  const BookingFormScreen({super.key, required this.hospital});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedGender;
  bool _termsAccepted = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyTypeController = TextEditingController();
  final _medicalConditionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _emergencyTypeController.dispose();
    _medicalConditionController.dispose();
    super.dispose();
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select gender')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create booking
      final bookingResult = await ApiService.submitBooking(
        hospitalId: widget.hospital.id,
        patientName: _nameController.text.trim(),
        patientAge: int.parse(_ageController.text.trim()),
        patientGender: _selectedGender!,
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim(),
        emergencyType: _emergencyTypeController.text.trim(),
        medicalCondition: _medicalConditionController.text.trim(),
      );

      final bookingId = bookingResult['booking']['_id'];

      // Confirm booking
      await ApiService.confirmBooking(bookingId);

      // Save booking information locally
      final prefs = await SharedPreferences.getInstance();
      final bookedHospitals = prefs.getStringList('booked_hospitals') ?? [];
      if (!bookedHospitals.contains(widget.hospital.id)) {
        bookedHospitals.add(widget.hospital.id);
        await prefs.setStringList('booked_hospitals', bookedHospitals);
      }
      await prefs.setString('booking_${widget.hospital.id}', bookingId);
      await prefs.setString(
        'booking_time_${widget.hospital.id}',
        DateTime.now().toIso8601String(),
      );

      if (mounted) {
        // Navigate to confirmation screen without showing snackbar
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (context) => BookingConfirmationScreen(
                  bookingId: bookingId,
                  hospital: widget.hospital,
                  patientName: _nameController.text.trim(),
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E86AB),
        title: Text(
          'Emergency Bed Booking',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Hospital',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.hospital.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.hospital.address,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Beds',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${widget.hospital.availableBeds}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E86AB),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Emergency Contact',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                widget.hospital.emergencyNum.isNotEmpty
                                    ? widget.hospital.emergencyNum
                                    : widget.hospital.telephone,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Title
              Text(
                'Patient Information',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Patient Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name *',
                  hintText: 'Enter patient name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Age and Gender Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: 'Age *',
                        hintText: 'Enter age',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Age is required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 0 || age > 150) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedGender = value);
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Select gender';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact Phone
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Contact Phone *',
                  hintText: 'Enter phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  if (value.length < 10) {
                    return 'Phone number must be at least 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (Optional)
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (Optional)',
                  hintText: 'Enter email address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Invalid email format';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section Title
              Text(
                'Medical Information',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Emergency Type
              TextFormField(
                controller: _emergencyTypeController,
                decoration: InputDecoration(
                  labelText: 'Emergency Type (Optional)',
                  hintText: 'e.g., Cardiac, Trauma, Respiratory',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),

              // Medical Condition
              TextFormField(
                controller: _medicalConditionController,
                decoration: InputDecoration(
                  labelText: 'Medical Condition (Optional)',
                  hintText: 'Describe the medical condition',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Terms and Conditions
              CheckboxListTile(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() => _termsAccepted = value ?? false);
                },
                title: Text(
                  'I confirm the information is accurate and accept the terms',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E86AB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Confirm Booking',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  '📞 A confirmation SMS will be sent to your phone number with booking details.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[900],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Booking Confirmation Screen
class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;
  final Hospital hospital;
  final String patientName;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.hospital,
    required this.patientName,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  bool _isDownloading = false;
  late DateTime _bookingTime;

  @override
  void initState() {
    super.initState();
    _bookingTime = DateTime.now();
  }

  Future<void> _downloadConfirmation() async {
    setState(() => _isDownloading = true);

    try {
      await ApiService.downloadConfirmationPDF(widget.bookingId);

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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2E86AB),
        title: Text(
          'Booking Confirmed',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Success Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF667EEA), width: 2),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF667EEA),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),

            // Success Message
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF667EEA),
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Your emergency bed booking has been successfully confirmed.',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Confirmation Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Booking ID', widget.bookingId),
                    const SizedBox(height: 16),
                    _buildDetailRow('Patient Name', widget.patientName),
                    const SizedBox(height: 16),
                    _buildDetailRow('Hospital', widget.hospital.name),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Emergency Contact',
                      widget.hospital.emergencyNum.isNotEmpty
                          ? widget.hospital.emergencyNum
                          : widget.hospital.telephone,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      'Booking Date & Time',
                      _formatDateTime(_bookingTime),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Status', 'CONFIRMED'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Download PDF Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadConfirmation,
                icon: const Icon(Icons.download),
                label:
                    _isDownloading
                        ? const Text('Downloading...')
                        : const Text('Download Confirmation PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Home Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
            const SizedBox(height: 24),

            // Important Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF667EEA).withValues(alpha: 0.05),
                    const Color(0xFF764BA2).withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Important Information',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF667EEA),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Please contact the hospital to confirm your arrival time.',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Keep your confirmation document for reference.',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Bring valid ID and insurance documents if applicable.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            textAlign: TextAlign.end,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber[900]),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.amber[900]),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
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
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year at $hour:$minute';
  }
}
