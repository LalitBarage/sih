import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
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
