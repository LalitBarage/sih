import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnquriScreen extends StatefulWidget {
  const EnquriScreen({super.key});

  @override
  _EnquriScreenState createState() => _EnquriScreenState();
}

class _EnquriScreenState extends State<EnquriScreen> {
  final aadhaarController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();
  final diseaseController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  Future<void> fetchAndFillData() async {
    final aadhaar = aadhaarController.text;
    if (aadhaar.isEmpty || aadhaar.length != 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid Aadhaar number')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('patients')
          .select('name, phone_no, dob, gender')
          .eq('aadhaar_no', aadhaar)
          .maybeSingle();

      if (response == null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Not Found'),
              content: const Text(
                  'Patient not found.\nPlease register patient first!!!!!!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      setState(() {
        nameController.text = response?['name'] ?? '';
        phoneController.text = response?['phone_no'] ?? '';
        dobController.text = response?['dob'] ?? '';
        genderController.text = response?['gender'] ?? '';
      });
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // If validation fails, stop submission.
      return;
    }

    try {
      // Step 1: Fetch the user ID from secure storage.
      final userId = await _secureStorage.read(key: 'userId');
      if (userId == null) {
        throw Exception('User ID not found in secure storage');
      }

      // Step 2: Retrieve `sub_dist`, `dist`, and `state` from the `hospitals` table.
      final hospitalResponse = await Supabase.instance.client
          .from('hospitals')
          .select('sub_dist, dist, state')
          .eq('id', userId)
          .single();

      final subDistrict = hospitalResponse['sub_dist'] ?? '';
      final district = hospitalResponse['dist'] ?? '';
      final state = hospitalResponse['state'] ?? '';

      // Step 3: Insert data into the `diseases` table.
      final response = await Supabase.instance.client.from('diseases').insert({
        'aadhaar_no': aadhaarController.text,
        'name': nameController.text,
        'phone_no': phoneController.text,
        'dob': dobController.text,
        'gender': genderController.text,
        'disease': diseaseController.text,
        'sub_dist': subDistrict,
        'dist': district,
        'state': state,
      });

      if (response is PostgrestException) {
        throw Exception(response.message);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Query added successfully!')),
      );
      _clearFields();
    } catch (e) {
      print('Error submitting form: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting form: $e')),
      );
    }
  }

  void _clearFields() {
    nameController.clear();
    aadhaarController.clear();
    phoneController.clear();
    dobController.clear();
    genderController.clear();
    diseaseController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: aadhaarController,
                  decoration: const InputDecoration(
                    labelText: 'Aadhaar Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter Aadhaar number';
                    } else if (value.length != 12 ||
                        !RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Enter a valid 12-digit Aadhaar number';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: fetchAndFillData,
                  child: const Text('Fetch Details'),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: dobController,
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: genderController,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(),
                    disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                  enabled: false,
                  style: const TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: diseaseController,
                  decoration: const InputDecoration(
                    labelText: 'Disease',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter diseases'
                      : null,
                  onChanged: (value) {
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    aadhaarController.dispose();

    phoneController.dispose();
    dobController.dispose();
    genderController.dispose();
    diseaseController.dispose();
    super.dispose();
  }
}
