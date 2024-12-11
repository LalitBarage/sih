import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _genderController = TextEditingController();
  final _pincodeController = TextEditingController();

  void _clearFields() {
    _patientNameController.clear();
    _aadhaarController.clear();
    _phoneController.clear();
    _dobController.clear();
    _addressController.clear();
    _genderController.clear();
    _pincodeController.clear();
  }

  void fetchDetails() async {
    final String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar("Please enter a phone number");
      return;
    }

    // Generate and send OTP
    final String otp = _generateOTP();
    final otpSent = await _sendOtp(phone: phone, otp: otp);
    if (!otpSent) {
      _showSnackBar("Failed to send OTP. Please try again.");
      return;
    }

    // Show OTP dialog for verification
    final otpVerified = await _showOtpDialog(otp);
    if (!otpVerified) {
      _showSnackBar("OTP verification failed. Please try again.");
      return;
    }

    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('aadhaar_api')
          .select('id, name, dob, gender, address, adhar_no, pincode')
          .eq('phone_no', phone);

      if (response.isEmpty) {
        _showSnackBar("No details found for this phone number");
      } else if (response.length == 1) {
        final user = response[0];
        setState(() {
          _patientNameController.text = user['name'] ?? '';
          _dobController.text = user['dob'] ?? '';
          _genderController.text = user['gender'] ?? '';
          _addressController.text = user['address'] ?? '';
          _aadhaarController.text = user['adhar_no'] ?? '';
          _pincodeController.text = user['pincode'] ?? '';
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select User'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: response.length,
                itemBuilder: (context, index) {
                  final user = response[index];
                  return ListTile(
                    title: Text(user['name'] ?? 'Unknown'),
                    subtitle: Text('Aadhaar: ${user['adhar_no'] ?? 'N/A'}'),
                    onTap: () {
                      setState(() {
                        _patientNameController.text = user['name'] ?? '';
                        _dobController.text = user['dob'] ?? '';
                        _genderController.text = user['gender'] ?? '';
                        _addressController.text = user['address'] ?? '';
                        _aadhaarController.text = user['adhar_no'] ?? '';
                        _pincodeController.text = user['pincode'] ?? '';
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ),
        );
      }
    } catch (error) {
      _showSnackBar("Error fetching details: $error");
    }
  }

  String _generateOTP() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  Future<bool> _sendOtp({required phone, required otp}) async {
    final fullPhoneNo = '+91$phone';
    // Send SMS using Twilio
    const accountSid =
        'AC3cdaec33a058556db5e2cb6457de79da'; // Replace with your Twilio Account SID
    const authToken =
        'f8e7881f68241ea146b8ee64ffada91c'; // Replace with your Twilio Auth Token
    const fromPhoneNumber =
        '+17754588201'; // Replace with your Twilio phone number

    final twilioUrl =
        'https://api.twilio.com/2010-04-01/Accounts/AC3cdaec33a058556db5e2cb6457de79da/Messages.json';

    // ignore: unused_local_variable
    final twilioResponse = await http.post(
      Uri.parse(twilioUrl),
      headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$accountSid:$authToken'))}',
      },
      body: {
        'To': fullPhoneNo,
        'From': fromPhoneNumber,
        'Body': 'Your otp:$otp \nDon,t share it with any one',
      },
    );
    return Future.delayed(const Duration(seconds: 1), () => true);
  }

  Future<bool> _showOtpDialog(String generatedOtp) async {
    final TextEditingController otpController = TextEditingController();
    bool verified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('OTP Verification'),
        content: TextFormField(
          controller: otpController,
          decoration: const InputDecoration(labelText: 'Enter OTP'),
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (otpController.text == generatedOtp) {
                verified = true;
                Navigator.of(context).pop();
              } else {
                _showSnackBar("Incorrect OTP. Please try again.");
              }
            },
            child: const Text('Verify'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    return verified;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill all required fields.');
      return;
    }

    _showLoadingIndicator();

    try {
      final supabase = Supabase.instance.client;

      await supabase.from('patients').insert([
        {
          'name': _patientNameController.text.trim(),
          'aadhaar_no': _aadhaarController.text.trim(),
          'phone_no': _phoneController.text.trim(),
          'dob': _dobController.text.trim(),
          'address': _addressController.text.trim(),
          'gender': _genderController.text.trim(),
          'pincode': _pincodeController.text.trim(),
        }
      ]);

      _showSnackBar('Patient added successfully!');
      _clearFields();
    } catch (error) {
      _showSnackBar('Error: $error');
    } finally {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 10,
                  keyboardType: TextInputType.phone,
                  validator: (value) => value != null && value.trim().isNotEmpty
                      ? null
                      : 'Phone is required',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: fetchDetails,
                  child: const Text('Fetch Details'),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _patientNameController,
                  label: 'Patient Name',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _aadhaarController,
                  label: 'Aadhaar Number',
                  maxLength: 12,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _dobController,
                  label: 'Date of Birth',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _genderController,
                  label: 'Gender',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _pincodeController,
                  label: 'PIN Code',
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLength = 0,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    IconData? suffixIcon,
    void Function()? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        border: const OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.black,
          ),
        ),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
      style: const TextStyle(color: Colors.black),
      enabled: false,
      maxLength: maxLength > 0 ? maxLength : null,
      maxLines: maxLines,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
    );
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
