import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
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
  final _cityController = TextEditingController();
  String? _profilePicFileName;
  Uint8List? _profilePicBytes;

  // Step 2 controllers
  String? _selectedCategory;
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  // Legal categories shown in the signup dropdown.
  final List<String> _categories = [
    'Criminal Law',
    'Civil Law',
    'Corporate',
    'Family Law',
    'Property Law',
    'Tax Law',
  ];

  // Step 3
  final List<String> _paymentMethods = [
    'Easypaisa',
    'JazzCash',
    'Sadapay',
    'Nayapay',
  ];
  final Set<String> _selectedPayments = {};

  // Step 4
  String? _cnicFileName;
  String? _licenseFileName;
  Uint8List? _cnicBytes;
  Uint8List? _licenseBytes;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;

  static const List<String> _allowedDocExtensions = [
    'doc',
    'docx',
    'pdf',
    'png',
    'jpg',
    'jpeg',
  ];

  Future<void> _pickAndCropProfilePicture() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final picked = result.files.single;
    if (picked.bytes == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read selected image. Please try again.')),
      );
      return;
    }

    final cropped = await showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CircularCropperDialog(imageBytes: picked.bytes!),
    );

    if (cropped == null) {
      return;
    }

    setState(() {
      _profilePicFileName = picked.name;
      _profilePicBytes = cropped;
    });
  }

  Future<void> _pickDocument(void Function(String, Uint8List?) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
      allowMultiple: false,
      withData: true,
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

    onPicked(picked.name, picked.bytes);
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
    if (_cnicBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read CNIC file bytes. Please re-upload.')),
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
    if (_licenseBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read license file bytes. Please re-upload.')),
      );
      return false;
    }
    return true;
  }

  String _mimeTypeFromFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    return 'application/octet-stream';
  }

  Future<void> _saveLawyerDocInline({
    required String uid,
    required String docKey,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // Keep each Firestore doc comfortably under the 1 MiB limit after base64 expansion.
    const maxInlineBytes = 550 * 1024;
    if (bytes.length > maxInlineBytes) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'document-too-large',
        message:
            'Selected file is too large for inline upload. Please use a smaller file (under 550 KB).',
      );
    }

    await FirebaseFirestore.instance
        .collection('lawyer_docs')
        .doc(uid)
        .collection('files')
        .doc(docKey)
        .set({
          'file_name': fileName,
          'mime_type': _mimeTypeFromFileName(fileName),
          'bytes_base64': base64Encode(bytes),
          'size_bytes': bytes.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _submitSignUp() async {
    if (!(_formKeys[_currentStep].currentState?.validate() ?? false)) {
      return;
    }
    if (!_validateUploads()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    UserCredential? credential;
    try {
      final email = _emailController.text.trim().toLowerCase();

      credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );

      final first = _firstNameController.text.trim();
      final last = _lastNameController.text.trim();
      await credential.user?.updateDisplayName('$first $last');

      if (credential.user != null) {
        final uid = credential.user!.uid;
        await _saveLawyerDocInline(
          uid: uid,
          docKey: 'profile_picture',
          fileName: _profilePicFileName!,
          bytes: _profilePicBytes!,
        );
        await _saveLawyerDocInline(
          uid: uid,
          docKey: 'cnic',
          fileName: _cnicFileName!,
          bytes: _cnicBytes!,
        );
        await _saveLawyerDocInline(
          uid: uid,
          docKey: 'bar_id',
          fileName: _licenseFileName!,
          bytes: _licenseBytes!,
        );

        await FirebaseFirestore.instance
            .collection('lawyers')
            .doc(uid)
            .set({
              'uid': uid,
              'role': 'lawyer',
              'approvalStatus': 'pending',
              'isVerified': false,
              'verification_status': 'pending',
              'lawyer': {
                'name': '$first $last',
                'email': email,
                'phone': _phoneController.text.trim(),
                'city': _cityController.text.trim(),
                'category': _selectedCategory,
                'experienceYears': _experienceController.text.trim(),
                'consultationFee': _feeController.text.trim(),
                'bio': _bioController.text.trim(),
                'paymentMethods': _selectedPayments.toList(),
                'profilePictureFileName': _profilePicFileName,
                'profilePictureDocPath': 'lawyer_docs/$uid/files/profile_picture',
              },
              'profile_pic_file_name': _profilePicFileName,
              'profile_pic_doc_path': 'lawyer_docs/$uid/files/profile_picture',
              'cnic_file_name': _cnicFileName,
              'bar_id_file_name': _licenseFileName,
              'cnic_url': '',
              'cnic_back_url': '',
              'bar_id_url': '',
              'cnic_doc_path': 'lawyer_docs/$uid/files/cnic',
              'bar_id_doc_path': 'lawyer_docs/$uid/files/bar_id',
              'document_storage_mode': 'firestore_inline',
              'document_upload_status': 'uploaded',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'uid': credential.user!.uid,
              'role': 'lawyer',
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application sent to admin. Please sign in.'),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) {
        return;
      }
      String message = 'Registration failed. Please try again.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered. Please sign in.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak. Use at least 6 characters.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password sign-in is not enabled in Firebase Auth.';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Please check your internet connection.';
      } else if (e.code == 'unknown' || e.code == 'unknown-error') {
        message =
            'Firebase Auth internal error. Check that Email/Password sign-in is enabled in Firebase Console and try a different email.';
      } else if (e.code == 'internal-error') {
        message =
            'Firebase internal error. Please retry in a moment. If it continues, verify Firebase Auth settings.';
      } else if ((e.message ?? '').trim().isNotEmpty) {
        message = '${e.message!.trim()} (code: ${e.code})';
      } else {
        message = 'Registration failed (auth code: ${e.code}).';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on FirebaseException catch (e) {
      try {
        await credential?.user?.delete();
      } catch (_) {}
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      if (!mounted) {
        return;
      }

      String message =
          e.message ?? 'Could not save your profile. Please try again.';
      if (e.code == 'permission-denied') {
        message =
            'Firestore permission denied. Please update Firebase rules for profile collections.';
      } else if (e.code == 'document-too-large') {
        message =
            'Selected document is too large. Please use files under 550 KB (PNG/JPG/PDF).';
      } else if (e.code == 'unavailable') {
        message = 'Firestore is unavailable right now. Please try again.';
      } else if ((e.message ?? '').trim().isNotEmpty) {
        message = '${e.message!.trim()} (code: ${e.code})';
      } else {
        message = 'Could not save your profile (db code: ${e.code}).';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected registration error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
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
                  onPressed: _isSubmitting
                      ? null
                      : (_currentStep == 3 ? _submitSignUp : _nextStep),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
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
            _buildTextField(
              _passwordController,
              'Password',
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
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
            const SizedBox(height: 16),
            _buildTextField(
              _cityController,
              'City',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value.trim())) {
                  return 'Only alphabets and spaces allowed';
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
              (fileName, bytes) => setState(() {
                _cnicFileName = fileName;
                _cnicBytes = bytes;
              }),
            ),
            const SizedBox(height: 24),
            _buildFilePicker(
              'Upload Bar Council License',
              _licenseFileName,
              (fileName, bytes) => setState(() {
                _licenseFileName = fileName;
                _licenseBytes = bytes;
              }),
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
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: _inputDecoration(hint, suffixIcon: suffixIcon),
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
            Stack(
              children: [
                InkWell(
                  onTap: _pickAndCropProfilePicture,
                  borderRadius: BorderRadius.circular(36),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profilePicBytes != null
                        ? MemoryImage(_profilePicBytes!)
                        : null,
                    child: _profilePicFileName == null
                        ? const Icon(Icons.person, size: 36, color: Colors.white)
                        : null,
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _pickAndCropProfilePicture,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap the avatar or pencil to choose and adjust your photo.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (_profilePicFileName != null) ...[
          const SizedBox(height: 8),
          Text(
            _profilePicFileName!,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: const Color(0xFFF5F6FA),
      suffixIcon: suffixIcon,
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
    void Function(String fileName, Uint8List? bytes) onPicked,
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

class _CircularCropperDialog extends StatefulWidget {
  const _CircularCropperDialog({required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<_CircularCropperDialog> createState() => _CircularCropperDialogState();
}

class _CircularCropperDialogState extends State<_CircularCropperDialog> {
  final CropController _cropController = CropController();
  bool _isCropping = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Profile Photo'),
      content: SizedBox(
        width: 320,
        height: 320,
        child: Crop(
          controller: _cropController,
          image: widget.imageBytes,
          withCircleUi: true,
          onCropped: (croppedData) {
            if (!mounted) {
              return;
            }
            Navigator.of(context).pop(croppedData);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCropping
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCropping
              ? null
              : () {
                  setState(() {
                    _isCropping = true;
                  });
                  _cropController.crop();
                },
          child: const Text('Use Photo'),
        ),
      ],
    );
  }
}
