import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'sign_in_screen.dart';

class LawyerSignUpScreen extends StatefulWidget {
  const LawyerSignUpScreen({super.key});

  @override
  State<LawyerSignUpScreen> createState() => _LawyerSignUpScreenState();
}

class _LawyerSignUpScreenState extends State<LawyerSignUpScreen> {
  static final RegExp _emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^[0-9]{11}$');

  int _currentStep = 0;
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());

  // Step 1 controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _profilePicFileName;
  Uint8List? _profilePicBytes;

  // Step 2 controllers
  String? _selectedCategory;
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();
  // Hide 'Criminal Law' and 'Other' from dropdown
  final List<String> _categories = [
    'Civil Law',
    'Corporate',
    'Family Law',
    'Tax Law',
  ];

  // Step 3
  final List<String> _paymentMethods = [
    'Bank Transfer',
    'Easypaisa',
    'JazzCash',
    'Sadapay',
    'Nayapay',
  ];
  final Set<String> _selectedPayments = {};

  // Step 4
  String? _cnicFileName;
  String? _licenseFileName;

  static const List<String> _allowedDocExtensions = [
    'doc',
    'docx',
    'pdf',
    'png',
    'jpg',
    'jpeg',
  ];

  Future<void> _pickProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _profilePicFileName = result.files.single.name;
      _profilePicBytes = result.files.single.bytes;
    });
  }

  Future<void> _pickDocument(ValueChanged<String> onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    final extension = (picked.extension ?? '').toLowerCase();
    if (!_allowedDocExtensions.contains(extension)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported document type selected.')),
      );
      return;
    }

    onPicked(picked.name);
  }

  bool _validateUploads() {
    if (_profilePicFileName == null || _profilePicFileName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile picture.')),
      );
      return false;
    }
    if (_cnicFileName == null || _cnicFileName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload your CNIC document.')),
      );
      return false;
    }
    if (_licenseFileName == null || _licenseFileName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Bar Council license.'),
        ),
      );
      return false;
    }
    return true;
  }

  void _submitSignUp() {
    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) {
      return;
    }
    if (!_validateUploads()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Application sent to admin. Please wait.')),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _stepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: 40,
          decoration: BoxDecoration(
            color: index <= _currentStep
                ? const Color(0xFFFF6B35)
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
              return;
            }
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _stepIndicator(),
              const SizedBox(height: 16),
              Text(
                'Step ${_currentStep + 1} of 4',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Form(
                  key: _formKeys[_currentStep],
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _currentStep == 3 ? _submitSignUp : _nextStep,
                  child: Text(
                    _currentStep == 3 ? 'Submit' : 'Continue',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return ListView(
          children: [
            const Text(
              'Personal Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2236),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fill in the required information',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildProfilePicPicker(),
            const SizedBox(height: 16),
            _buildTextField(
              _firstNameController,
              'First Name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
                  return 'Only alphabets and spaces allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _lastNameController,
              'Last Name',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
                  return 'Only alphabets and spaces allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _emailController,
              'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!_emailRegex.hasMatch(value.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Password', obscureText: true),
            const SizedBox(height: 16),
            _buildTextField(
              _phoneController,
              'Phone Number',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!_phoneRegex.hasMatch(value.trim())) {
                  return 'Phone number must be exactly 11 digits';
                }
                return null;
              },
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            const Text(
              'Practice Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2236),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fill in the required information',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Legal Category',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              style: const TextStyle(color: Colors.black),
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Select category'),
              items: _categories
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) =>
                  val == null ? 'Please select a category' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _experienceController,
              'Years of Experience',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _feeController,
              'Consultation Fee (PKR)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            const Text(
              'Brief Bio',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildTextField(_bioController, 'Brief Bio', maxLines: 3),
          ],
        );
      case 2:
        return ListView(
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2236),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Fill in the required information',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ..._paymentMethods.map(
              (method) => CheckboxListTile(
                value: _selectedPayments.contains(method),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedPayments.add(method);
                    } else {
                      _selectedPayments.remove(method);
                    }
                  });
                },
                title: Text(method),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFFFF6B35),
              ),
            ),
          ],
        );
      case 3:
        return ListView(
          children: [
            const Text(
              'Upload Documents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2236),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload required documents for verification',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildFilePicker(
              'Upload CNIC',
              _cnicFileName,
              (fileName) => setState(() => _cnicFileName = fileName),
            ),
            const SizedBox(height: 24),
            _buildFilePicker(
              'Upload Bar Council License',
              _licenseFileName,
              (fileName) => setState(() => _licenseFileName = fileName),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration(hint),
      validator:
          validator ??
          (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }

  // Profile picture picker widget for step 1
  Widget _buildProfilePicPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Picture',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey[300],
              backgroundImage: _profilePicBytes != null
                  ? MemoryImage(_profilePicBytes!)
                  : null,
              child: _profilePicFileName == null
                  ? const Icon(Icons.person, size: 36, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: _pickProfilePicture,
              child: Text(
                _profilePicFileName == null
                    ? 'Upload / Paste'
                    : _profilePicFileName!,
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildFilePicker(
    String label,
    String? fileName,
    ValueChanged<String> onPicked,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            fileName == null ? Icons.upload_rounded : Icons.check_circle,
            size: 48,
            color: fileName == null ? Colors.grey : Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'Allowed: .doc, .pdf, .png, .jpg, etc.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (fileName != null) ...[
            const SizedBox(height: 8),
            Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1B2236),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async => _pickDocument(onPicked),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }
}
